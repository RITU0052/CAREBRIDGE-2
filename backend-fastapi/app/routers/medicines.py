from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
import datetime

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user
from app.email_service import send_medicine_taken_notification, send_missed_medicine_notification, send_medicine_reminder

router = APIRouter()

@router.get("/missed-check")
def check_missed_medicines(
    db: Session = Depends(get_db)
):
    today_str = datetime.date.today().isoformat()
    pending_logs = db.query(models.Medicine).all()
    notifications_sent = 0

    for med in pending_logs:
        log = db.query(models.MedicineLog).filter(
            models.MedicineLog.medicine_id == med.id,
            models.MedicineLog.log_date == today_str
        ).first()

        if not log or log.status == "pending":
            parent = db.query(models.User).filter(models.User.id == med.parent_id).first()
            if parent and parent.linked_user_id:
                notif = models.AppNotification(
                    user_id=parent.linked_user_id,
                    title="⚠️ Medicine Reminder",
                    body=f"{parent.name} has not marked {med.medicine_name} ({med.dose} {med.dose_unit or ''}) as taken.",
                    type="medicine"
                )
                db.add(notif)
                notifications_sent += 1

    db.commit()
    return {"message": "Missed medicine check completed", "notifications_sent": notifications_sent}

@router.get("/{parent_id}", response_model=List[schemas.MedicineOut])
def get_medicines(
    parent_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today_str = datetime.date.today().isoformat()
    medicines = db.query(models.Medicine).filter(models.Medicine.parent_id == parent_id).all()

    results = []
    for med in medicines:
        log = db.query(models.MedicineLog).filter(
            models.MedicineLog.medicine_id == med.id,
            models.MedicineLog.log_date == today_str
        ).first()
        status_today = log.status if log else "pending"

        results.append({
            "id": med.id,
            "parent_id": med.parent_id,
            "medicine_name": med.medicine_name,
            "dose": med.dose or "1",
            "dose_unit": med.dose_unit or "tablet",
            "time_of_day": med.time_of_day or "Morning",
            "food_instruction": med.food_instruction or "After Food",
            "disease_condition": med.disease_condition or "",
            "frequency": getattr(med, "frequency", "Once a day") or "Once a day",
            "duration": getattr(med, "duration", "30 Days") or "30 Days",
            "start_date": med.start_date,
            "end_date": med.end_date,
            "instructions": med.instructions,
            "notes": med.notes,
            "created_at": med.created_at,
            "today_status": status_today
        })
    return results

@router.post("", response_model=schemas.MedicineOut)
def add_medicine(
    med_in: schemas.MedicineCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    parent_id = med_in.parent_id or current_user.id
    if current_user.role == "child" and current_user.linked_user_id and not med_in.parent_id:
        parent_id = current_user.linked_user_id

    new_med = models.Medicine(
        parent_id=parent_id,
        medicine_name=med_in.medicine_name,
        dose=med_in.dose or "1",
        dose_unit=med_in.dose_unit or "tablet",
        time_of_day=med_in.time_of_day or "Morning",
        food_instruction=med_in.food_instruction or "After Food",
        disease_condition=med_in.disease_condition,
        frequency=med_in.frequency or "Once a day",
        duration=med_in.duration or "30 Days",
        start_date=med_in.start_date or datetime.date.today().isoformat(),
        end_date=med_in.end_date,
        instructions=med_in.instructions,
        notes=med_in.notes
    )
    db.add(new_med)
    db.commit()
    db.refresh(new_med)

    return {
        "id": new_med.id,
        "parent_id": new_med.parent_id,
        "medicine_name": new_med.medicine_name,
        "dose": new_med.dose,
        "dose_unit": new_med.dose_unit,
        "time_of_day": new_med.time_of_day,
        "food_instruction": new_med.food_instruction,
        "disease_condition": new_med.disease_condition,
        "frequency": new_med.frequency,
        "duration": new_med.duration,
        "start_date": new_med.start_date,
        "end_date": new_med.end_date,
        "instructions": new_med.instructions,
        "notes": new_med.notes,
        "created_at": new_med.created_at,
        "today_status": "pending"
    }

@router.put("/status")
def update_medicine_status(
    status_in: schemas.MedicineStatusUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    med = db.query(models.Medicine).filter(models.Medicine.id == status_in.medicine_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medicine not found")

    today_str = status_in.log_date or datetime.date.today().isoformat()
    log = db.query(models.MedicineLog).filter(
        models.MedicineLog.medicine_id == med.id,
        models.MedicineLog.log_date == today_str
    ).first()

    if log:
        log.status = status_in.status
        log.updated_at = datetime.datetime.utcnow()
    else:
        log = models.MedicineLog(
            medicine_id=med.id,
            status=status_in.status,
            log_date=today_str
        )
        db.add(log)

    db.commit()

    parent = db.query(models.User).filter(models.User.id == med.parent_id).first()

    if status_in.status == "taken":
        # Dispatches email notification to authorized linked family member / child or parent
        try:
            dose_str = f"{med.dose or '1'} {med.dose_unit or ''}".strip()
            if parent:
                # If current user is parent, send notification to linked child/family member
                if parent.linked_user_id:
                    child_user = db.query(models.User).filter(models.User.id == parent.linked_user_id).first()
                    if child_user and child_user.email:
                        send_medicine_taken_notification(
                            to_email=child_user.email,
                            patient_name=parent.name,
                            medicine_name=med.medicine_name,
                            dose=dose_str,
                            time_of_day=med.time_of_day or "Scheduled Dose",
                            confirmed_by_name=current_user.name,
                            disease_condition=med.disease_condition,
                            user_id=child_user.id,
                            related_id=med.id
                        )
                # Also notify parent email if child took the medicine
                elif current_user.id != parent.id and parent.email:
                    send_medicine_taken_notification(
                        to_email=parent.email,
                        patient_name=parent.name,
                        medicine_name=med.medicine_name,
                        dose=dose_str,
                        time_of_day=med.time_of_day or "Scheduled Dose",
                        confirmed_by_name=current_user.name,
                        disease_condition=med.disease_condition,
                        user_id=parent.id,
                        related_id=med.id
                    )
        except Exception as e:
            print(f"Medicine taken email notification warning: {e}")

    elif status_in.status in ["skipped", "snoozed", "missed"]:
        try:
            if parent:
                action_text = status_in.status
                if parent.linked_user_id:
                    child_user = db.query(models.User).filter(models.User.id == parent.linked_user_id).first()
                    if child_user and child_user.email:
                        send_missed_medicine_notification(
                            to_email=child_user.email,
                            patient_name=parent.name,
                            medicine_name=med.medicine_name,
                            dose=f"{med.dose or '1'} {med.dose_unit or ''}".strip(),
                            scheduled_time=med.time_of_day or "Today",
                            current_status=action_text.capitalize(),
                            user_id=child_user.id,
                            related_id=med.id
                        )

                notif = models.AppNotification(
                    user_id=parent.id if current_user.id != parent.id else (parent.linked_user_id or parent.id),
                    title=f"⚠️ Medicine {action_text.capitalize()}",
                    body=f"{current_user.name} {action_text} dose of {med.medicine_name}.",
                    type="medicine"
                )
                db.add(notif)
                db.commit()
        except Exception as e:
            print(f"Missed medicine email warning: {e}")

    return {"message": "Medicine status updated successfully", "status": status_in.status}

@router.put("/{medicine_id}", response_model=schemas.MedicineOut)
def update_medicine(
    medicine_id: str,
    med_in: schemas.MedicineUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    med = db.query(models.Medicine).filter(models.Medicine.id == medicine_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medicine not found")

    if med_in.medicine_name:
        med.medicine_name = med_in.medicine_name
    if med_in.dose:
        med.dose = med_in.dose
    if med_in.dose_unit:
        med.dose_unit = med_in.dose_unit
    if med_in.time_of_day:
        med.time_of_day = med_in.time_of_day
    if med_in.food_instruction:
        med.food_instruction = med_in.food_instruction
    if med_in.disease_condition is not None:
        med.disease_condition = med_in.disease_condition
    if med_in.frequency:
        med.frequency = med_in.frequency
    if med_in.duration:
        med.duration = med_in.duration
    if med_in.instructions:
        med.instructions = med_in.instructions
    if med_in.notes:
        med.notes = med_in.notes

    db.commit()
    db.refresh(med)

    today_str = datetime.date.today().isoformat()
    log = db.query(models.MedicineLog).filter(
        models.MedicineLog.medicine_id == med.id,
        models.MedicineLog.log_date == today_str
    ).first()

    return {
        "id": med.id,
        "parent_id": med.parent_id,
        "medicine_name": med.medicine_name,
        "dose": med.dose,
        "dose_unit": med.dose_unit,
        "time_of_day": med.time_of_day,
        "food_instruction": med.food_instruction,
        "disease_condition": med.disease_condition,
        "frequency": med.frequency or "Once a day",
        "duration": med.duration or "30 Days",
        "start_date": med.start_date,
        "end_date": med.end_date,
        "instructions": med.instructions,
        "notes": med.notes,
        "created_at": med.created_at,
        "today_status": log.status if log else "pending"
    }

@router.delete("/{medicine_id}")
def delete_medicine(
    medicine_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    med = db.query(models.Medicine).filter(models.Medicine.id == medicine_id).first()
    if not med:
        raise HTTPException(status_code=404, detail="Medicine not found")

    db.delete(med)
    db.commit()
    return {"message": "Medicine deleted successfully"}

@router.post("/{medicine_id}/taken")
def mark_medicine_taken(
    medicine_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return update_medicine_status(
        schemas.MedicineStatusUpdate(medicine_id=medicine_id, status="taken"),
        current_user=current_user,
        db=db
    )

@router.post("/{medicine_id}/skip")
def mark_medicine_skip(
    medicine_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return update_medicine_status(
        schemas.MedicineStatusUpdate(medicine_id=medicine_id, status="skipped"),
        current_user=current_user,
        db=db
    )

@router.post("/{medicine_id}/snooze")
def mark_medicine_snooze(
    medicine_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    return update_medicine_status(
        schemas.MedicineStatusUpdate(medicine_id=medicine_id, status="snoozed"),
        current_user=current_user,
        db=db
    )
