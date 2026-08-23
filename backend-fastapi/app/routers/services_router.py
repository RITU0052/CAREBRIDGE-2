from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.database import get_db
from app.deps import get_current_admin

router = APIRouter()

@router.get("", response_model=List[schemas.ServiceOut])
def get_services(db: Session = Depends(get_db)):
    services = db.query(models.Service).filter(models.Service.is_active == True).all()
    if not services:
        default_services = [
            {"id": "s1", "name": "Doctor Consultation", "description": "In-person or virtual video consultation with experienced physicians.", "category": "General", "icon": "stethoscope", "is_active": True},
            {"id": "s2", "name": "Appointment Booking", "description": "Instant online booking with flexible slot choices and reminder notifications.", "category": "Booking", "icon": "calendar", "is_active": True},
            {"id": "s3", "name": "Telemedicine", "description": "Remote virtual video and chat consultations from home.", "category": "Virtual", "icon": "video", "is_active": True},
            {"id": "s4", "name": "Health Records", "description": "Secure storage and management of medical reports, lab tests, and histories.", "category": "Records", "icon": "file-text", "is_active": True},
            {"id": "s5", "name": "Medication Management", "description": "Daily medicine schedules, dosage tracking, and family alert sync.", "category": "Medicine", "icon": "pill", "is_active": True},
            {"id": "s6", "name": "Emergency Support", "description": "One-touch SOS button sending instant GPS location alerts to caregivers.", "category": "Emergency", "icon": "shield-alert", "is_active": True},
        ]
        return default_services
    return services

@router.post("", response_model=schemas.ServiceOut)
def create_service(
    service_in: schemas.ServiceCreate,
    admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    new_service = models.Service(
        name=service_in.name,
        description=service_in.description,
        category=service_in.category,
        icon=service_in.icon,
        is_active=True
    )
    db.add(new_service)
    db.commit()
    db.refresh(new_service)
    return new_service

@router.delete("/{service_id}")
def delete_service(
    service_id: str,
    admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    service = db.query(models.Service).filter(models.Service.id == service_id).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
    service.is_active = False
    db.commit()
    return {"message": "Service deactivated successfully"}
