from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Any
import random

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user

from app.email_service import send_family_invitation_email, send_link_confirmation_email

router = APIRouter()

def generate_family_code():
    return f"CB-{random.randint(100000, 999999)}"

@router.get("/code", response_model=schemas.FamilyCodeOut)
def get_family_code(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parent accounts can access family code")

    if not current_user.family_code:
        current_user.family_code = generate_family_code()
        db.commit()
        db.refresh(current_user)

    return {
        "family_code": current_user.family_code,
        "parent_id": current_user.id,
        "parent_name": current_user.name
    }

@router.post("/connect", response_model=schemas.UserOut)
def connect_family_by_code(
    request_in: schemas.FamilyConnectRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "child":
        raise HTTPException(status_code=400, detail="Only child accounts can connect to a parent using family code")

    code = request_in.family_code.strip().upper()
    parent_user = db.query(models.User).filter(
        models.User.family_code == code,
        models.User.role == "parent"
    ).first()

    if not parent_user:
        raise HTTPException(status_code=404, detail="Invalid family code. No parent account found with this code.")

    # Link parent to child
    parent_user.linked_user_id = current_user.id
    db.commit()
    db.refresh(parent_user)

    try:
        send_link_confirmation_email(current_user.email, current_user.name, parent_user.name, parent_user.role)
        send_link_confirmation_email(parent_user.email, parent_user.name, current_user.name, current_user.role)
    except Exception as e:
        print(f"Link confirmation email warning: {e}")

    return parent_user

@router.post("/invite-email")
def invite_family_by_email(
    invite_in: schemas.FamilyInviteEmailRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    recipient_email = invite_in.recipient_email.strip().lower()

    if recipient_email == current_user.email.lower():
        raise HTTPException(status_code=400, detail="You cannot send a family linking invitation to your own email address.")

    invitation_code = generate_family_code()

    invitation = models.FamilyInvitation(
        sender_id=current_user.id,
        recipient_email=recipient_email,
        invitation_code=invitation_code,
        status="pending"
    )
    db.add(invitation)
    db.commit()
    db.refresh(invitation)

    try:
        send_family_invitation_email(
            to_email=recipient_email,
            sender_name=current_user.name,
            sender_role=current_user.role,
            invitation_code=invitation_code
        )
    except Exception as e:
        print(f"Family invitation email warning: {e}")

    return {
        "message": f"Invitation email sent successfully to {recipient_email}!",
        "invitation_code": invitation_code,
        "recipient_email": recipient_email
    }

@router.post("/accept-email-invite")
def accept_email_invite(
    accept_in: schemas.FamilyAcceptEmailInviteRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    code = accept_in.invitation_code.strip().upper()

    # 1. Try finding in FamilyInvitations
    invitation = db.query(models.FamilyInvitation).filter(
        models.FamilyInvitation.invitation_code == code,
        models.FamilyInvitation.status == "pending"
    ).first()

    sender_user = None
    if invitation:
        sender_user = db.query(models.User).filter(models.User.id == invitation.sender_id).first()

    # 2. Fallback: try matching a parent's family code directly
    if not sender_user:
        sender_user = db.query(models.User).filter(
            models.User.family_code == code
        ).first()

    if not sender_user:
        raise HTTPException(status_code=404, detail="Invalid or expired family invitation code. Please check your email.")

    if sender_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot link an account to yourself.")

    # Link accounts based on roles
    if current_user.role == "child" and sender_user.role == "parent":
        sender_user.linked_user_id = current_user.id
    elif current_user.role == "parent" and sender_user.role == "child":
        current_user.linked_user_id = sender_user.id
    elif current_user.role == "child" and sender_user.role == "child":
        # Allow child to monitor parent if sender has linked parent
        pass
    else:
        # Default link parent -> child
        if sender_user.role == "parent":
            sender_user.linked_user_id = current_user.id
        elif current_user.role == "parent":
            current_user.linked_user_id = sender_user.id

    if invitation:
        invitation.status = "accepted"

    db.commit()
    db.refresh(current_user)

    # Dispatch email notifications to both
    try:
        send_link_confirmation_email(current_user.email, current_user.name, sender_user.name, sender_user.role)
        send_link_confirmation_email(sender_user.email, sender_user.name, current_user.name, current_user.role)
    except Exception as e:
        print(f"Link confirmation email warning: {e}")

    return {
        "message": f"Successfully linked account with {sender_user.name} ({sender_user.role.capitalize()})!",
        "linked_user": {
            "id": sender_user.id,
            "name": sender_user.name,
            "email": sender_user.email,
            "role": sender_user.role
        }
    }

@router.get("/invitations")
def list_pending_invitations(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    invites_sent = db.query(models.FamilyInvitation).filter(
        models.FamilyInvitation.sender_id == current_user.id
    ).order_by(models.FamilyInvitation.created_at.desc()).all()

    invites_received = db.query(models.FamilyInvitation).filter(
        models.FamilyInvitation.recipient_email == current_user.email.lower()
    ).order_by(models.FamilyInvitation.created_at.desc()).all()

    return {
        "sent": [
            {
                "id": inv.id,
                "recipient_email": inv.recipient_email,
                "invitation_code": inv.invitation_code,
                "status": inv.status,
                "created_at": inv.created_at
            } for inv in invites_sent
        ],
        "received": [
            {
                "id": inv.id,
                "sender_id": inv.sender_id,
                "invitation_code": inv.invitation_code,
                "status": inv.status,
                "created_at": inv.created_at
            } for inv in invites_received
        ]
    }

@router.get("/members")
def get_family_members(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role == "child":
        # Find linked parents
        parents = db.query(models.User).filter(
            models.User.linked_user_id == current_user.id,
            models.User.role == "parent"
        ).all()
        return {
            "role": "child",
            "parents": [
                {
                    "id": p.id,
                    "name": p.name,
                    "email": p.email,
                    "phone": p.phone,
                    "bio": p.bio,
                    "family_code": p.family_code
                } for p in parents
            ]
        }
    elif current_user.role == "parent":
        linked_child = None
        if current_user.linked_user_id:
            linked_child = db.query(models.User).filter(models.User.id == current_user.linked_user_id).first()
        return {
            "role": "parent",
            "family_code": current_user.family_code,
            "child": {
                "id": linked_child.id,
                "name": linked_child.name,
                "email": linked_child.email,
                "phone": linked_child.phone
            } if linked_child else None
        }
    else:
        return {"role": current_user.role, "members": []}

