import uuid
import enum
import datetime
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, ForeignKey, Text, UniqueConstraint
from sqlalchemy.orm import relationship as orm_relationship

from app.database import Base

class RoleEnum(str, enum.Enum):
    parent = "parent"
    child = "child"
    doctor = "doctor"
    admin = "admin"

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    phone = Column(String, nullable=True)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False, default="parent") # 'parent', 'child', 'doctor', 'admin'
    is_email_verified = Column(Boolean, default=False)
    email_verification_code = Column(String(6), nullable=True)
    
    # Self-referential link for Parent <-> Child
    linked_user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    family_code = Column(String(10), unique=True, index=True, nullable=True) # 6-digit family pairing code for parent
    bio = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    email_notifications_enabled = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    
    # Relationships
    linked_user = orm_relationship("User", remote_side=[id], backref="linked_by")
    health_metrics = orm_relationship("HealthMetric", back_populates="parent", cascade="all, delete-orphan")
    sos_alerts = orm_relationship("SOSAlert", back_populates="parent", cascade="all, delete-orphan")
    reports = orm_relationship("MedicalReport", back_populates="parent", cascade="all, delete-orphan")
    doctor_profile = orm_relationship("Doctor", back_populates="user", uselist=False, cascade="all, delete-orphan")
    appointments = orm_relationship("Appointment", foreign_keys="Appointment.parent_id", back_populates="parent", cascade="all, delete-orphan")
    medicines = orm_relationship("Medicine", back_populates="parent", cascade="all, delete-orphan")
    emergency_contacts = orm_relationship("EmergencyContact", back_populates="parent", cascade="all, delete-orphan")

class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    relationship = Column(String, nullable=True, default="Family")
    email = Column(String, nullable=True)
    is_primary = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    parent = orm_relationship("User", back_populates="emergency_contacts")

class DoctorContact(Base):
    __tablename__ = "doctor_contacts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    doctor_name = Column(String, nullable=False)
    doctor_phone = Column(String, nullable=False)
    doctor_email = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    parent = orm_relationship("User")

class Specialty(Base):
    __tablename__ = "specialties"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    name = Column(String, nullable=False, unique=True)
    description = Column(Text, nullable=True)
    icon = Column(String, nullable=True, default="stethoscope")
    is_active = Column(Boolean, default=True)

class Service(Base):
    __tablename__ = "services"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    name = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=True, default="General")
    icon = Column(String, nullable=True, default="activity")
    is_active = Column(Boolean, default=True)

class Doctor(Base):
    __tablename__ = "doctors"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    name = Column(String, nullable=False)
    specialty = Column(String, nullable=False)
    profession = Column(String, nullable=True, default="Physician")
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    experience_years = Column(Integer, default=5)
    qualifications = Column(String, nullable=True)
    languages = Column(String, nullable=True, default="English")
    consultation_fee = Column(Float, default=50.0)
    location = Column(String, nullable=True, default="Main Clinic")
    bio = Column(Text, nullable=True)
    consultation_type = Column(String, nullable=True, default="Both") # 'In-person', 'Virtual', 'Both'
    status = Column(String, default="pending") # 'pending', 'verified', 'rejected', 'suspended'
    is_verified = Column(Boolean, default=False)
    rating = Column(Float, default=4.9)
    review_count = Column(Integer, default=12)
    profile_image = Column(String, nullable=True)
    available_days = Column(String, nullable=True, default="Mon,Tue,Wed,Thu,Fri")

    user = orm_relationship("User", back_populates="doctor_profile")
    availabilities = orm_relationship("DoctorAvailability", back_populates="doctor", cascade="all, delete-orphan")
    appointments = orm_relationship("Appointment", back_populates="doctor", cascade="all, delete-orphan")
    reviews = orm_relationship("Review", back_populates="doctor", cascade="all, delete-orphan")

class DoctorAvailability(Base):
    __tablename__ = "doctor_availabilities"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    doctor_id = Column(String(36), ForeignKey("doctors.id"), nullable=False)
    day_of_week = Column(String, nullable=False) # e.g., 'Monday', 'Tuesday'
    start_time = Column(String, nullable=False, default="09:00") # e.g. "09:00"
    end_time = Column(String, nullable=False, default="17:00") # e.g. "17:00"
    slot_duration_minutes = Column(Integer, default=30)

    doctor = orm_relationship("Doctor", back_populates="availabilities")

class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    doctor_id = Column(String(36), ForeignKey("doctors.id"), nullable=False)
    service_id = Column(String(36), ForeignKey("services.id"), nullable=True)
    
    appointment_date = Column(String, nullable=False) # YYYY-MM-DD
    time_slot = Column(String, nullable=False)        # e.g., "10:00 AM"
    appointment_type = Column(String, default="In-person") # 'In-person', 'Virtual'
    
    patient_name = Column(String, nullable=False)
    patient_phone = Column(String, nullable=True)
    patient_notes = Column(Text, nullable=True)
    status = Column(String, default="scheduled") # 'scheduled', 'completed', 'cancelled', 'rescheduled'
    previous_date_time = Column(String, nullable=True)
    reschedule_reason = Column(String, nullable=True)
    reminder_time_minutes = Column(Integer, nullable=True) # e.g. 30, 60, 120
    virtual_link = Column(String, nullable=True)
    fee = Column(Float, default=50.0)

    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    parent = orm_relationship("User", back_populates="appointments")
    doctor = orm_relationship("Doctor", back_populates="appointments")
    service = orm_relationship("Service")

    # Anti-double-booking constraint helper in application layer + index
    __table_args__ = (
        UniqueConstraint('doctor_id', 'appointment_date', 'time_slot', name='_doctor_date_slot_uc'),
    )

class Review(Base):
    __tablename__ = "reviews"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    doctor_id = Column(String(36), ForeignKey("doctors.id"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    rating = Column(Float, default=5.0)
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    doctor = orm_relationship("Doctor", back_populates="reviews")
    user = orm_relationship("User")

class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    medicine_name = Column(String, nullable=False)
    dose = Column(String, nullable=True, default="1")
    dose_unit = Column(String, nullable=True, default="tablet") # mg, ml, tablet, capsule, drops, other
    time_of_day = Column(String, nullable=True, default="Morning") # Morning, Afternoon, Night, 08:00 AM, 08:00 PM
    food_instruction = Column(String, nullable=True, default="After Food") # Before Food, After Food, With Food, Empty Stomach, Not Specified, Before breakfast, After breakfast, etc.
    disease_condition = Column(String, nullable=True) # Diabetes, Blood pressure, Fever, Infection, Heart condition, Other
    frequency = Column(String, nullable=True, default="Once a day") # Once a day, Twice a day, Three times a day, Custom
    duration = Column(String, nullable=True, default="30 Days")
    start_date = Column(String, nullable=True)
    end_date = Column(String, nullable=True)
    instructions = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    parent = orm_relationship("User", back_populates="medicines")
    logs = orm_relationship("MedicineLog", back_populates="medicine", cascade="all, delete-orphan")

class MedicineLog(Base):
    __tablename__ = "medicine_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    medicine_id = Column(String(36), ForeignKey("medicines.id"), nullable=False)
    status = Column(String, default="pending") # 'pending', 'taken', 'skipped', 'snoozed'
    log_date = Column(String, nullable=False) # YYYY-MM-DD
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    medicine = orm_relationship("Medicine", back_populates="logs")

class AppNotification(Base):
    __tablename__ = "notifications"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    body = Column(String, nullable=False)
    type = Column(String, nullable=False, default="info") # 'medicine', 'health', 'appointment', 'emergency', 'report'
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = orm_relationship("User")

class HealthMetric(Base):
    __tablename__ = "health_metrics"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    date = Column(DateTime, default=datetime.datetime.utcnow)
    
    blood_pressure_sys = Column(String, nullable=True) # e.g. '120'
    blood_pressure_dia = Column(String, nullable=True) # e.g. '80'
    heart_rate = Column(String, nullable=True)         # e.g. '75'
    water_intake_l = Column(Float, nullable=True)     # Actual water intake in Liters
    water_target_l = Column(Float, nullable=True, default=2.5) # Daily water target in Liters
    steps_target = Column(Integer, nullable=True, default=8000) # Daily steps target
    steps_actual = Column(Integer, nullable=True)      # Actual steps if connected
    heart_rate_target = Column(String, nullable=True, default="60-100 BPM") # Target range
    data_source = Column(String, nullable=True, default="not_connected") # 'manual', 'device', 'not_connected'
    notes = Column(String, nullable=True)
    
    parent = orm_relationship("User", back_populates="health_metrics")

class SOSAlert(Base):
    __tablename__ = "sos_alerts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    status = Column(String, default="active") # 'active' or 'resolved'
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    
    location_lat = Column(String, nullable=True)
    location_lng = Column(String, nullable=True)
    
    parent = orm_relationship("User", back_populates="sos_alerts")

class MedicalReport(Base):
    __tablename__ = "medical_reports"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    parent_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    report_type = Column(String, nullable=True, default="General")
    report_date = Column(String, nullable=True)
    file_path = Column(String, nullable=False)
    file_type = Column(String, nullable=False)
    notes = Column(Text, nullable=True)
    ai_summary_json = Column(Text, nullable=True) # Stored JSON of AI summary
    upload_date = Column(DateTime, default=datetime.datetime.utcnow)

    parent = orm_relationship("User", back_populates="reports")

class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    token = Column(String, nullable=False, index=True)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = orm_relationship("User")

class FamilyInvitation(Base):
    __tablename__ = "family_invitations"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    sender_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    recipient_email = Column(String, nullable=False, index=True)
    invitation_code = Column(String(10), nullable=False, index=True)
    status = Column(String, default="pending") # 'pending', 'accepted', 'rejected'
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    sender = orm_relationship("User", foreign_keys=[sender_id])

class EmailLog(Base):
    __tablename__ = "email_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    recipient_email = Column(String, nullable=False, index=True)
    notification_type = Column(String, nullable=False, index=True)
    subject = Column(String, nullable=False)
    status = Column(String, nullable=False, default="sent") # 'sent', 'failed'
    error_message = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    related_id = Column(String(36), nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = orm_relationship("User")


