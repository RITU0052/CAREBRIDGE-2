from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import datetime

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user

router = APIRouter()

@router.get("", response_model=List[schemas.AppNotificationOut])
def get_notifications(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notifications = db.query(models.AppNotification).filter(
        models.AppNotification.user_id == current_user.id
    ).order_by(models.AppNotification.created_at.desc()).all()

    if not notifications:
        # Seed dynamic role-based notification feed if empty
        now = datetime.datetime.utcnow()
        sample_items = []
        if current_user.role == "parent":
            sample_items = [
                models.AppNotification(
                    user_id=current_user.id,
                    title="💊 Medicine Reminder",
                    body="Time for your morning Amlodipine 5mg dose.",
                    type="medicine",
                    created_at=now - datetime.timedelta(minutes=15)
                ),
                models.AppNotification(
                    user_id=current_user.id,
                    title="📄 Report Uploaded",
                    body="Your caregiver uploaded a new Blood Report PDF.",
                    type="report",
                    created_at=now - datetime.timedelta(hours=2)
                ),
                models.AppNotification(
                    user_id=current_user.id,
                    title="❤️ Daily Reminder",
                    body="Remember to check your blood pressure reading today.",
                    type="health",
                    created_at=now - datetime.timedelta(hours=5)
                )
            ]
        else: # child or other
            sample_items = [
                models.AppNotification(
                    user_id=current_user.id,
                    title="💊 Papa Missed Medicine",
                    body="Papa hasn't marked his 8:00 AM medicine as taken.",
                    type="medicine",
                    created_at=now - datetime.timedelta(minutes=30)
                ),
                models.AppNotification(
                    user_id=current_user.id,
                    title="📄 New Medical Report Uploaded",
                    body="New Lab Test Report has been uploaded for Papa.",
                    type="report",
                    created_at=now - datetime.timedelta(hours=1)
                ),
                models.AppNotification(
                    user_id=current_user.id,
                    title="🚨 Emergency Alert",
                    body="Papa triggered an emergency SOS alert at 10:15 AM.",
                    type="emergency",
                    created_at=now - datetime.timedelta(hours=3)
                ),
                models.AppNotification(
                    user_id=current_user.id,
                    title="📅 Upcoming Appointment",
                    body="Doctor consultation with Dr. Sarah Jenkins tomorrow at 10:00 AM.",
                    type="appointment",
                    created_at=now - datetime.timedelta(hours=6)
                )
            ]
        db.add_all(sample_items)
        db.commit()
        for n in sample_items:
            db.refresh(n)
        return sample_items

    return notifications
