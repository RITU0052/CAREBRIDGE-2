from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional
import datetime

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user, get_current_admin

router = APIRouter()

@router.get("", response_model=List[schemas.DoctorOut])
def get_doctors(
    search: Optional[str] = None,
    specialty: Optional[str] = None,
    location: Optional[str] = None,
    consultation_type: Optional[str] = Query(None, description="In-person, Virtual, Both"),
    min_rating: Optional[float] = None,
    include_pending: bool = False,
    sort_by: Optional[str] = Query(None, description="rating, experience, fee"),
    db: Session = Depends(get_db)
):
    query = db.query(models.Doctor)

    # Only verified doctors visible to standard users unless include_pending is explicitly requested by admin
    if not include_pending:
        query = query.filter(models.Doctor.status == "verified", models.Doctor.is_verified == True)

    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            (models.Doctor.name.ilike(search_pattern)) |
            (models.Doctor.specialty.ilike(search_pattern)) |
            (models.Doctor.location.ilike(search_pattern))
        )
    if specialty and specialty.lower() != "all":
        query = query.filter(models.Doctor.specialty.ilike(f"%{specialty}%"))
    if location and location.lower() != "all":
        query = query.filter(models.Doctor.location.ilike(f"%{location}%"))
    if consultation_type and consultation_type.lower() != "all":
        ctype = consultation_type.lower()
        if ctype == "in-person":
            query = query.filter(models.Doctor.consultation_type.in_(["In-person", "Both"]))
        elif ctype == "virtual":
            query = query.filter(models.Doctor.consultation_type.in_(["Virtual", "Both"]))
        else:
            query = query.filter(models.Doctor.consultation_type.ilike(f"%{consultation_type}%"))

    if min_rating:
        query = query.filter(models.Doctor.rating >= min_rating)

    if sort_by == "rating":
        query = query.order_by(models.Doctor.rating.desc())
    elif sort_by == "experience":
        query = query.order_by(models.Doctor.experience_years.desc())
    elif sort_by == "fee":
        query = query.order_by(models.Doctor.consultation_fee.asc())
    else:
        query = query.order_by(models.Doctor.rating.desc())

    return query.all()

@router.get("/me", response_model=schemas.DoctorOut)
def get_doctor_profile_me(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctor accounts can access doctor profile")

    doctor = db.query(models.Doctor).filter(models.Doctor.user_id == current_user.id).first()
    if not doctor:
        doctor = models.Doctor(
            user_id=current_user.id,
            name=current_user.name,
            specialty="General Physician",
            qualifications="MBBS, MD",
            profession="Physician",
            phone=current_user.phone or "+1-800-DOCTOR",
            email=current_user.email,
            status="verified",
            is_verified=True
        )
        db.add(doctor)
        db.commit()
        db.refresh(doctor)

    return doctor

@router.put("/me", response_model=schemas.DoctorOut)
def update_doctor_profile_me(
    doc_in: schemas.DoctorCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "doctor":
        raise HTTPException(status_code=403, detail="Only doctor accounts can update doctor profile")

    doctor = db.query(models.Doctor).filter(models.Doctor.user_id == current_user.id).first()
    if not doctor:
        doctor = models.Doctor(user_id=current_user.id, name=current_user.name, specialty=doc_in.specialty)
        db.add(doctor)

    doctor.name = doc_in.name
    doctor.specialty = doc_in.specialty
    if doc_in.profession:
        doctor.profession = doc_in.profession
    if doc_in.phone:
        doctor.phone = doc_in.phone
    if doc_in.email:
        doctor.email = doc_in.email
    doctor.experience_years = doc_in.experience_years
    doctor.qualifications = doc_in.qualifications
    doctor.languages = doc_in.languages
    doctor.consultation_fee = doc_in.consultation_fee
    doctor.location = doc_in.location
    doctor.bio = doc_in.bio
    if doc_in.profile_image:
        doctor.profile_image = doc_in.profile_image
    if doc_in.available_days:
        doctor.available_days = doc_in.available_days

    db.commit()
    db.refresh(doctor)
    return doctor

@router.get("/me/appointments", response_model=List[schemas.AppointmentOut])
def get_doctor_my_appointments(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    doctor = db.query(models.Doctor).filter(models.Doctor.user_id == current_user.id).first()
    if not doctor:
        return []

    appointments = db.query(models.Appointment).filter(
        models.Appointment.doctor_id == doctor.id
    ).order_by(models.Appointment.appointment_date.asc(), models.Appointment.created_at.desc()).all()

    results = []
    for app in appointments:
        results.append({
            "id": app.id,
            "parent_id": app.parent_id,
            "doctor_id": app.doctor_id,
            "service_id": app.service_id,
            "appointment_date": app.appointment_date,
            "time_slot": app.time_slot,
            "appointment_type": app.appointment_type or "In-person",
            "patient_name": app.patient_name,
            "patient_phone": app.patient_phone,
            "patient_notes": app.patient_notes,
            "previous_date_time": app.previous_date_time,
            "reschedule_reason": app.reschedule_reason,
            "reminder_time_minutes": app.reminder_time_minutes,
            "virtual_link": app.virtual_link,
            "status": app.status,
            "fee": app.fee,
            "created_at": app.created_at,
            "doctor_name": doctor.name,
            "doctor_specialty": doctor.specialty,
            "doctor_image": doctor.profile_image
        })
    return results

@router.get("/specialties", response_model=List[schemas.SpecialtyOut])
def get_specialties(db: Session = Depends(get_db)):
    specialties = db.query(models.Specialty).filter(models.Specialty.is_active == True).all()
    if not specialties:
        default_specialties = [
            {"id": "1", "name": "General Physician", "description": "Primary healthcare and consultations", "icon": "stethoscope"},
            {"id": "2", "name": "Cardiology", "description": "Heart & vascular health specialists", "icon": "heart"},
            {"id": "3", "name": "Neurology", "description": "Brain and nervous system specialists", "icon": "brain"},
            {"id": "4", "name": "Orthopedics", "description": "Bone, joint, and muscle care", "icon": "bone"},
            {"id": "5", "name": "Pediatrics", "description": "Child health and development", "icon": "baby"},
            {"id": "6", "name": "Dermatology", "description": "Skin, hair, and nail specialists", "icon": "sparkles"},
        ]
        return default_specialties
    return specialties

@router.get("/{doctor_id}", response_model=schemas.DoctorOut)
def get_doctor_detail(doctor_id: str, db: Session = Depends(get_db)):
    doctor = db.query(models.Doctor).filter(models.Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor

@router.get("/{doctor_id}/slots", response_model=schemas.DynamicSlotResponse)
def get_available_slots(doctor_id: str, date: str, db: Session = Depends(get_db)):
    doctor = db.query(models.Doctor).filter(models.Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")

    all_possible_slots = [
        "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
        "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM", "04:00 PM", "04:30 PM"
    ]

    booked_appointments = db.query(models.Appointment).filter(
        models.Appointment.doctor_id == doctor_id,
        models.Appointment.appointment_date == date,
        models.Appointment.status != "cancelled"
    ).all()

    booked_slots = {app.time_slot for app in booked_appointments}
    available_slots = [slot for slot in all_possible_slots if slot not in booked_slots]

    return {
        "date": date,
        "doctor_id": doctor_id,
        "available_slots": available_slots
    }

@router.get("/{doctor_id}/reviews", response_model=List[schemas.ReviewOut])
def get_doctor_reviews(doctor_id: str, db: Session = Depends(get_db)):
    reviews = db.query(models.Review).filter(models.Review.doctor_id == doctor_id).order_by(models.Review.created_at.desc()).all()
    results = []
    for r in reviews:
        user_name = r.user.name if r.user else "Anonymous"
        results.append({
            "id": r.id,
            "doctor_id": r.doctor_id,
            "user_id": r.user_id,
            "rating": r.rating,
            "comment": r.comment,
            "created_at": r.created_at,
            "user_name": user_name
        })
    return results

@router.post("", response_model=schemas.DoctorOut)
def create_doctor(
    doctor_in: schemas.DoctorCreate,
    admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    new_doctor = models.Doctor(
        name=doctor_in.name,
        specialty=doctor_in.specialty,
        profession=doctor_in.profession or "Physician",
        phone=doctor_in.phone,
        email=doctor_in.email,
        experience_years=doctor_in.experience_years,
        qualifications=doctor_in.qualifications,
        languages=doctor_in.languages,
        consultation_fee=doctor_in.consultation_fee,
        location=doctor_in.location,
        bio=doctor_in.bio,
        consultation_type=doctor_in.consultation_type or "Both",
        status="verified",
        is_verified=True,
        profile_image=doctor_in.profile_image
    )
    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)
    return new_doctor
