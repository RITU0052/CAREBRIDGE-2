from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user, get_current_admin
from app.email_service import (
    send_appointment_confirmation,
    send_appointment_rescheduled_notification,
    send_appointment_cancelled_notification,
    send_doctor_notification
)

router = APIRouter()

@router.post("", response_model=schemas.AppointmentOut)
def create_appointment(
    app_in: schemas.AppointmentCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    doctor = db.query(models.Doctor).filter(models.Doctor.id == app_in.doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")

    existing = db.query(models.Appointment).filter(
        models.Appointment.doctor_id == app_in.doctor_id,
        models.Appointment.appointment_date == app_in.appointment_date,
        models.Appointment.time_slot == app_in.time_slot,
        models.Appointment.status != "cancelled"
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"The time slot '{app_in.time_slot}' on {app_in.appointment_date} is already booked for Dr. {doctor.name}. Please select another slot."
        )

    parent_id = current_user.id
    if current_user.role == "child" and current_user.linked_user_id:
        parent_id = current_user.linked_user_id

    app_type = app_in.appointment_type or "In-person"
    virtual_url = None
    if app_type.lower() == "virtual":
        virtual_url = f"https://meet.jit.si/carebridge-{str(uuid.uuid4())[:8]}"

    new_app = models.Appointment(
        parent_id=parent_id,
        doctor_id=app_in.doctor_id,
        service_id=app_in.service_id,
        appointment_date=app_in.appointment_date,
        time_slot=app_in.time_slot,
        appointment_type=app_type,
        patient_name=app_in.patient_name,
        patient_phone=app_in.patient_phone,
        patient_notes=app_in.patient_notes,
        virtual_link=virtual_url,
        status="scheduled",
        fee=doctor.consultation_fee
    )

    try:
        db.add(new_app)
        db.commit()
        db.refresh(new_app)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Could not book appointment due to slot collision")

    # Notify doctor if user_id exists
    try:
        if doctor.user_id:
            notif = models.AppNotification(
                user_id=doctor.user_id,
                title="📅 New Appointment Booked",
                body=f"New {app_type} appointment with {app_in.patient_name} scheduled for {app_in.appointment_date} at {app_in.time_slot}.",
                type="appointment"
            )
            db.add(notif)
            db.commit()

            doc_user = db.query(models.User).filter(models.User.id == doctor.user_id).first()
            if doc_user and doc_user.email:
                send_doctor_notification(
                    to_email=doc_user.email,
                    doctor_name=doctor.name,
                    patient_name=app_in.patient_name,
                    appt_date=app_in.appointment_date,
                    time_slot=app_in.time_slot,
                    appt_type=app_type,
                    user_id=doc_user.id,
                    related_id=new_app.id
                )

        # Notify patient/parent email
        if current_user.email:
            send_appointment_confirmation(
                to_email=current_user.email,
                recipient_name=current_user.name,
                role=current_user.role,
                doctor_name=doctor.name,
                patient_name=app_in.patient_name,
                date_str=app_in.appointment_date,
                time_slot=app_in.time_slot,
                appt_type=app_type,
                virtual_link=virtual_url,
                user_id=current_user.id,
                related_id=new_app.id
            )
    except Exception as e:
        print(f"Appointment booking email warning: {e}")

    return {
        "id": new_app.id,
        "parent_id": new_app.parent_id,
        "doctor_id": new_app.doctor_id,
        "service_id": new_app.service_id,
        "appointment_date": new_app.appointment_date,
        "time_slot": new_app.time_slot,
        "appointment_type": new_app.appointment_type,
        "patient_name": new_app.patient_name,
        "patient_phone": new_app.patient_phone,
        "patient_notes": new_app.patient_notes,
        "previous_date_time": new_app.previous_date_time,
        "reschedule_reason": new_app.reschedule_reason,
        "reminder_time_minutes": new_app.reminder_time_minutes,
        "virtual_link": new_app.virtual_link,
        "status": new_app.status,
        "fee": new_app.fee,
        "created_at": new_app.created_at,
        "doctor_name": doctor.name,
        "doctor_specialty": doctor.specialty,
        "doctor_image": doctor.profile_image
    }

@router.put("/{appointment_id}/reschedule", response_model=schemas.AppointmentOut)
def reschedule_appointment(
    appointment_id: str,
    reschedule_in: schemas.AppointmentReschedule,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Appointment not found")

    doctor = db.query(models.Doctor).filter(models.Doctor.id == app.doctor_id).first()

    # Check conflict on new date & time slot
    existing = db.query(models.Appointment).filter(
        models.Appointment.doctor_id == app.doctor_id,
        models.Appointment.appointment_date == reschedule_in.new_date,
        models.Appointment.time_slot == reschedule_in.new_time_slot,
        models.Appointment.id != appointment_id,
        models.Appointment.status != "cancelled"
    ).first()

    if existing:
        raise HTTPException(
            status_code=400,
            detail=f"Slot '{reschedule_in.new_time_slot}' on {reschedule_in.new_date} is already booked for Dr. {doctor.name if doctor else ''}. Please pick another time."
        )

    prev_info = f"{app.appointment_date} at {app.time_slot}"
    app.previous_date_time = prev_info
    app.appointment_date = reschedule_in.new_date
    app.time_slot = reschedule_in.new_time_slot
    app.reschedule_reason = reschedule_in.reason
    app.status = "rescheduled"

    db.commit()
    db.refresh(app)

    # Notify doctor
    try:
        if doctor and doctor.user_id:
            notif_msg = f"Appointment rescheduled. Patient {app.patient_name} has requested/rescheduled the appointment to {app.appointment_date} at {app.time_slot}."
            if app.appointment_type == "Virtual":
                notif_msg = f"Virtual appointment rescheduled. Patient {app.patient_name} rescheduled from {prev_info} to {app.appointment_date} at {app.time_slot}."
            notif = models.AppNotification(
                user_id=doctor.user_id,
                title="🗓️ Appointment Rescheduled",
                body=notif_msg,
                type="appointment"
            )
            db.add(notif)
            db.commit()

            doc_user = db.query(models.User).filter(models.User.id == doctor.user_id).first()
            if doc_user and doc_user.email:
                send_appointment_rescheduled_notification(
                    to_email=doc_user.email,
                    recipient_name=doctor.name,
                    doctor_name=doctor.name,
                    patient_name=app.patient_name,
                    old_date_time=prev_info,
                    new_date_time=f"{app.appointment_date} at {app.time_slot}",
                    user_id=doc_user.id,
                    related_id=app.id
                )

        # Notify patient
        patient_notif = models.AppNotification(
            user_id=app.parent_id,
            title="✓ Appointment Rescheduled",
            body=f"Your appointment with Dr. {doctor.name if doctor else ''} is confirmed for {app.appointment_date} at {app.time_slot}.",
            type="appointment"
        )
        db.add(patient_notif)
        db.commit()

        if current_user.email:
            send_appointment_rescheduled_notification(
                to_email=current_user.email,
                recipient_name=current_user.name,
                doctor_name=doctor.name if doctor else "Doctor",
                patient_name=app.patient_name,
                old_date_time=prev_info,
                new_date_time=f"{app.appointment_date} at {app.time_slot}",
                user_id=current_user.id,
                related_id=app.id
            )
    except Exception as e:
        print(f"Reschedule email warning: {e}")

    return {
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
        "doctor_name": doctor.name if doctor else "Doctor",
        "doctor_specialty": doctor.specialty if doctor else "General",
        "doctor_image": doctor.profile_image if doctor else None
    }

@router.post("/{appointment_id}/reminder")
def set_appointment_reminder(
    appointment_id: str,
    rem_in: schemas.AppointmentReminder,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Appointment not found")

    app.reminder_time_minutes = rem_in.reminder_time_minutes
    db.commit()

    notif = models.AppNotification(
        user_id=current_user.id,
        title="⏰ Appointment Reminder Set",
        body=f"Reminder set for {rem_in.reminder_time_minutes} minutes before your appointment on {app.appointment_date} at {app.time_slot}.",
        type="appointment"
    )
    db.add(notif)
    db.commit()

    return {
        "message": f"Reminder set for {rem_in.reminder_time_minutes} minutes before appointment",
        "appointment_id": appointment_id,
        "reminder_time_minutes": rem_in.reminder_time_minutes
    }

@router.get("/my", response_model=List[schemas.AppointmentOut])
def get_my_appointments(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    target_user_ids = [current_user.id]
    if current_user.role == "child" and current_user.linked_user_id:
        target_user_ids.append(current_user.linked_user_id)

    appointments = db.query(models.Appointment).filter(
        models.Appointment.parent_id.in_(target_user_ids)
    ).order_by(models.Appointment.appointment_date.desc(), models.Appointment.created_at.desc()).all()

    results = []
    for app in appointments:
        doc = app.doctor
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
            "doctor_name": doc.name if doc else "Doctor",
            "doctor_specialty": doc.specialty if doc else "General",
            "doctor_image": doc.profile_image if doc else None
        })
    return results

@router.put("/{appointment_id}/cancel", response_model=schemas.AppointmentOut)
def cancel_appointment(
    appointment_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    app = db.query(models.Appointment).filter(models.Appointment.id == appointment_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if current_user.role != "admin" and app.parent_id != current_user.id and current_user.linked_user_id != app.parent_id:
        raise HTTPException(status_code=403, detail="Not authorized to cancel this appointment")

    app.status = "cancelled"
    db.commit()
    db.refresh(app)

    doc = app.doctor
    try:
        if current_user.email:
            send_appointment_cancelled_notification(
                to_email=current_user.email,
                recipient_name=current_user.name,
                doctor_name=doc.name if doc else "Doctor",
                patient_name=app.patient_name,
                appt_date=app.appointment_date,
                appt_time=app.time_slot,
                cancelled_by=current_user.name,
                user_id=current_user.id,
                related_id=app.id
            )
        if doc and doc.user_id:
            doc_user = db.query(models.User).filter(models.User.id == doc.user_id).first()
            if doc_user and doc_user.email:
                send_appointment_cancelled_notification(
                    to_email=doc_user.email,
                    recipient_name=doc.name,
                    doctor_name=doc.name,
                    patient_name=app.patient_name,
                    appt_date=app.appointment_date,
                    appt_time=app.time_slot,
                    cancelled_by=current_user.name,
                    user_id=doc_user.id,
                    related_id=app.id
                )
    except Exception as e:
        print(f"Cancel appointment email warning: {e}")
    return {
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
        "doctor_name": doc.name if doc else "Doctor",
        "doctor_specialty": doc.specialty if doc else "General",
        "doctor_image": doc.profile_image if doc else None
    }

@router.get("/admin", response_model=List[schemas.AppointmentOut])
def get_admin_appointments(
    status_filter: Optional[str] = None,
    admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    query = db.query(models.Appointment)
    if status_filter and status_filter.lower() != "all":
        query = query.filter(models.Appointment.status == status_filter.lower())

    appointments = query.order_by(models.Appointment.created_at.desc()).all()
    results = []
    for app in appointments:
        doc = app.doctor
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
            "doctor_name": doc.name if doc else "Doctor",
            "doctor_specialty": doc.specialty if doc else "General",
            "doctor_image": doc.profile_image if doc else None
        })
    return results
