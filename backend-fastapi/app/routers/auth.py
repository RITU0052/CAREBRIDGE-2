from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import timedelta
from typing import Any
import random
import datetime

from app import models, schemas, auth
from app.database import get_db
from app.deps import get_current_user
from app.email_service import (
    send_registration_confirmation,
    send_password_reset_email,
    send_otp_email,
    send_login_notification,
    send_doctor_login_notification,
    send_account_security_notification,
    send_admin_notification
)

router = APIRouter()

def generate_family_code():
    return f"CB-{random.randint(100000, 999999)}"

@router.post("/register", response_model=schemas.UserOut)
def register(user_in: schemas.UserCreate, db: Session = Depends(get_db)):
    clean_email = user_in.email.strip().lower()
    clean_phone = user_in.phone.strip() if user_in.phone else None

    db_user = db.query(models.User).filter(
        (func.lower(models.User.email) == clean_email) | 
        (models.User.phone == clean_phone if clean_phone else False)
    ).first()
    
    if db_user:
        raise HTTPException(status_code=400, detail="Email or phone already registered")
        
    hashed_password = auth.get_password_hash(user_in.password)
    verification_code = f"{random.randint(100000, 999999)}"
    
    new_user = models.User(
        name=user_in.name.strip(),
        email=clean_email,
        phone=clean_phone,
        password_hash=hashed_password,
        role=user_in.role,
        is_email_verified=False,
        email_verification_code=verification_code
    )
    
    if user_in.role == "parent":
        new_user.family_code = generate_family_code()
        if user_in.child_email:
            child_user = db.query(models.User).filter(
                func.lower(models.User.email) == user_in.child_email.strip().lower(),
                models.User.role == "child"
            ).first()
            if child_user:
                new_user.linked_user_id = child_user.id

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    if user_in.role == "doctor":
        doctor_profile = models.Doctor(
            user_id=new_user.id,
            name=new_user.name,
            specialty=user_in.specialty or "General Physician",
            qualifications=user_in.qualifications or "MBBS, MD",
            experience_years=user_in.experience_years or 5,
            languages=user_in.languages or "English",
            consultation_fee=user_in.consultation_fee or 50.0,
            location=user_in.location or "CareBridge Health Clinic",
            available_days=user_in.available_days or "Mon,Tue,Wed,Thu,Fri",
            status="pending",
            is_verified=False
        )
        db.add(doctor_profile)
        db.commit()

    # Dispatch registration confirmation email with verification code
    try:
        send_registration_confirmation(new_user.email, new_user.name, new_user.role, verification_code, user_id=new_user.id)
        if new_user.role == "doctor":
            send_admin_notification(
                "carebridge.notifications@gmail.com",
                "Admin",
                f"New Doctor Registration: Dr. {new_user.name}",
                f"Doctor Dr. {new_user.name} ({new_user.email}) registered and is awaiting admin verification.",
                user_id=new_user.id
            )
    except Exception as e:
        print(f"Registration email warning: {e}")

    return new_user


@router.post("/login", response_model=schemas.Token)
async def login(request: Request, db: Session = Depends(get_db)):
    email = None
    password = None

    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        try:
            data = await request.json()
            email = data.get("email")
            password = data.get("password")
        except Exception:
            pass

    if not email:
        try:
            form = await request.form()
            email = form.get("username") or form.get("email")
            password = form.get("password")
        except Exception:
            pass

    if not email or not password:
        raise HTTPException(status_code=400, detail="Invalid email or password format")

    clean_email = email.strip().lower()

    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()
    if not user:
        raise HTTPException(status_code=401, detail="Invalid email or password. Please check your credentials or register.")

    if not auth.verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": str(user.id), "role": user.role}, expires_delta=access_token_expires
    )

    # Trigger login notification email safely in background
    try:
        user_agent = request.headers.get("user-agent", "Mobile/Web App Client")
        if user.role == "doctor":
            send_doctor_login_notification(user.email, user.name, device_info=user_agent, user_id=user.id)
        else:
            send_login_notification(user.email, user.name, user.role, device_info=user_agent, user_id=user.id)
    except Exception as e:
        print(f"Login notification email warning: {e}")

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }

@router.get("/me", response_model=schemas.UserOut)
def get_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.put("/me", response_model=schemas.UserOut)
def update_me(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if user_update.name:
        current_user.name = user_update.name
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    if user_update.bio is not None:
        current_user.bio = user_update.bio

    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/forgot-password")
def forgot_password(req: schemas.ForgotPasswordRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    
    if not clean_email or "@" not in clean_email or "." not in clean_email:
        raise HTTPException(status_code=400, detail="Please enter a valid email address.")

    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()

    if user:
        code = f"{random.randint(100000, 999999)}"
        token_str = f"reset-{random.randint(100000, 999999)}"
        expires_at = datetime.datetime.utcnow() + datetime.timedelta(minutes=15)

        reset_token = models.PasswordResetToken(
            user_id=user.id,
            token=token_str,
            code=code,
            expires_at=expires_at,
            is_used=False
        )
        db.add(reset_token)
        db.commit()

        # Dispatch reset email strictly to registered user's email address
        try:
            send_password_reset_email(to_email=user.email, user_name=user.name, otp_code=code, user_id=user.id)
        except Exception as e:
            print(f"[SMTP ERROR] Failed to dispatch password reset email to {user.email}: {e}")

    # Return safe generic response to prevent account enumeration and hide reset code from network payloads
    return {
        "message": "If an account exists with this email address, a password reset code has been sent.",
        "email": clean_email
    }

@router.post("/reset-password")
def reset_password(req: schemas.ResetPasswordRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Account not found. Please verify your email address.")

    reset_record = db.query(models.PasswordResetToken).filter(
        models.PasswordResetToken.user_id == user.id,
        models.PasswordResetToken.code == req.code.strip(),
        models.PasswordResetToken.is_used == False
    ).order_by(models.PasswordResetToken.created_at.desc()).first()

    if not reset_record:
        raise HTTPException(status_code=400, detail="Invalid verification code. Please check your email.")

    if reset_record.expires_at < datetime.datetime.utcnow():
        raise HTTPException(status_code=400, detail="Verification code has expired. Please request a new code.")

    # Update password and invalidate reset token
    user.password_hash = auth.get_password_hash(req.new_password.strip())
    reset_record.is_used = True
    db.commit()

    # Send security notification email to user's registered email
    try:
        send_account_security_notification(to_email=user.email, user_name=user.name, user_id=user.id)
    except Exception as e:
        print(f"[SMTP WARNING] Password reset security notice error: {e}")

    return {"message": "Password has been successfully reset. You can now log in with your new password."}

@router.post("/change-password")
def change_password(
    req: schemas.ChangePasswordRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if not auth.verify_password(req.old_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect.")

    current_user.password_hash = auth.get_password_hash(req.new_password.strip())
    db.commit()

    try:
        send_account_security_notification(current_user.email, current_user.name, user_id=current_user.id)
    except Exception as e:
        print(f"Password change email warning: {e}")

    return {"message": "Your password has been changed successfully."}

@router.post("/verify-email")
def verify_email(req: schemas.VerifyEmailRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Account with this email address not found.")

    if user.is_email_verified:
        return {"message": "Email address is already verified.", "is_verified": True}

    if not user.email_verification_code or user.email_verification_code != req.code.strip():
        raise HTTPException(status_code=400, detail="Invalid verification code. Please check your email inbox.")

    user.is_email_verified = True
    user.email_verification_code = None
    db.commit()

    return {"message": "Email address verified successfully! Your account is active.", "is_verified": True}

@router.post("/resend-verification")
def resend_verification(req: schemas.ResendVerificationRequest, db: Session = Depends(get_db)):
    clean_email = req.email.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == clean_email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Account with this email address not found.")

    code = f"{random.randint(100000, 999999)}"
    user.email_verification_code = code
    db.commit()

    try:
        send_otp_email(user.email, user.name, code, action_name="Email Verification", user_id=user.id)
    except Exception as e:
        print(f"Resend email warning: {e}")

    return {
        "message": f"Verification code has been resent to {user.email}.",
        "email": user.email,
        "verification_code": code
    }

@router.post("/logout")
def logout():
    return {"message": "Logged out successfully"}



