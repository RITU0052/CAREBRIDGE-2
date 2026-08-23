from pydantic import BaseModel, EmailStr
from typing import Optional, List
from uuid import UUID
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: Optional[str] = None
    role: str = "parent" # "parent", "child", "doctor", "admin"
    child_email: Optional[EmailStr] = None # Used by parent to link to child
    # Doctor specific fields (optional during user creation)
    specialty: Optional[str] = None
    qualifications: Optional[str] = None
    experience_years: Optional[int] = 5
    languages: Optional[str] = "English"
    consultation_fee: Optional[float] = 50.0
    location: Optional[str] = "CareBridge Clinic"
    available_days: Optional[str] = "Mon,Tue,Wed,Thu,Fri"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserAdminCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    phone: Optional[str] = None
    role: str = "parent" # "parent", "child", "doctor", "admin"

class UserAdminChangePassword(BaseModel):
    new_password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    bio: Optional[str] = None

class UserOut(BaseModel):
    id: str
    name: str
    email: EmailStr
    phone: Optional[str] = None
    role: str
    linked_user_id: Optional[str] = None
    family_code: Optional[str] = None
    bio: Optional[str] = None
    is_active: bool = True
    is_email_verified: bool = False

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: Optional[UserOut] = None

class TokenData(BaseModel):
    user_id: Optional[str] = None

# --- Family Pairing & Email Linking ---

class FamilyCodeOut(BaseModel):
    family_code: str
    parent_id: str
    parent_name: str

class FamilyConnectRequest(BaseModel):
    family_code: str

class EmailLinkInviteRequest(BaseModel):
    recipient_email: EmailStr

class EmailLinkAcceptRequest(BaseModel):
    invitation_code: str

class EmailVerificationRequest(BaseModel):
    email: EmailStr
    code: str

class EmailInvitationOut(BaseModel):
    id: str
    sender_id: str
    sender_name: Optional[str] = None
    recipient_email: str
    invitation_code: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


# --- Emergency Contacts ---

class EmergencyContactCreate(BaseModel):
    name: str
    phone: str
    relationship: Optional[str] = "Family"
    email: Optional[str] = None
    is_primary: bool = False

class EmergencyContactOut(EmergencyContactCreate):
    id: str
    parent_id: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- Doctor Contact (Patient Saved Doctor) ---

class DoctorContactCreate(BaseModel):
    doctor_name: str
    doctor_phone: str
    doctor_email: Optional[str] = None

class DoctorContactOut(DoctorContactCreate):
    id: str
    parent_id: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- Emergency AI Assistant ---

class EmergencyAIAssistantRequest(BaseModel):
    prompt: str # Prompt in English, Hindi, or Hinglish
    language: Optional[str] = "hi" # 'hi', 'en', 'hinglish', 'auto'

class EmergencyAIAssistantResponse(BaseModel):
    suggested_message: str
    severity: str # 'high', 'moderate', 'low'
    advice: str

# --- Specialty & Service ---

class SpecialtyOut(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    icon: Optional[str] = "stethoscope"
    is_active: bool = True

    class Config:
        from_attributes = True

class ServiceCreate(BaseModel):
    name: str
    description: Optional[str] = None
    category: Optional[str] = "General"
    icon: Optional[str] = "activity"

class ServiceOut(ServiceCreate):
    id: str
    is_active: bool = True

    class Config:
        from_attributes = True

# --- Doctor & Availability ---

class AvailabilityOut(BaseModel):
    id: str
    doctor_id: str
    day_of_week: str
    start_time: str
    end_time: str
    slot_duration_minutes: int

    class Config:
        from_attributes = True

class DoctorCreate(BaseModel):
    name: str
    specialty: str
    profession: Optional[str] = "Physician"
    phone: Optional[str] = None
    email: Optional[str] = None
    experience_years: int = 5
    qualifications: Optional[str] = "MBBS, MD"
    languages: Optional[str] = "English"
    consultation_fee: float = 50.0
    location: Optional[str] = "CareBridge Clinic"
    bio: Optional[str] = None
    consultation_type: Optional[str] = "Both" # 'In-person', 'Virtual', 'Both'
    profile_image: Optional[str] = None
    available_days: Optional[str] = "Mon,Tue,Wed,Thu,Fri"

class DoctorOut(DoctorCreate):
    id: str
    user_id: Optional[str] = None
    status: str = "pending"
    is_verified: bool = False
    rating: float = 4.9
    review_count: int = 12
    available_days: Optional[str] = "Mon,Tue,Wed,Thu,Fri"

    class Config:
        from_attributes = True

class DoctorVerifyRequest(BaseModel):
    status: str # 'verified', 'rejected', 'suspended'

class DynamicSlotResponse(BaseModel):
    date: str
    doctor_id: str
    available_slots: List[str]

# --- Reviews ---

class ReviewCreate(BaseModel):
    doctor_id: str
    rating: float
    comment: str

class ReviewOut(ReviewCreate):
    id: str
    user_id: str
    created_at: datetime
    user_name: Optional[str] = "Anonymous"

    class Config:
        from_attributes = True

# --- Appointments ---

class AppointmentCreate(BaseModel):
    doctor_id: str
    service_id: Optional[str] = None
    appointment_date: str # YYYY-MM-DD
    time_slot: str        # e.g., "10:00 AM"
    appointment_type: Optional[str] = "In-person" # 'In-person' or 'Virtual'
    patient_name: str
    patient_phone: Optional[str] = None
    patient_notes: Optional[str] = None

class AppointmentReschedule(BaseModel):
    new_date: str # YYYY-MM-DD
    new_time_slot: str # e.g. "04:00 PM"
    reason: Optional[str] = None

class AppointmentReminder(BaseModel):
    reminder_time_minutes: int # e.g. 30, 60, 120

class AppointmentOut(AppointmentCreate):
    id: str
    parent_id: str
    status: str
    previous_date_time: Optional[str] = None
    reschedule_reason: Optional[str] = None
    reminder_time_minutes: Optional[int] = None
    virtual_link: Optional[str] = None
    fee: float
    created_at: datetime
    doctor_name: Optional[str] = None
    doctor_specialty: Optional[str] = None
    doctor_image: Optional[str] = None

    class Config:
        from_attributes = True

# --- Medicines ---

class MedicineCreate(BaseModel):
    parent_id: Optional[str] = None
    medicine_name: str
    dose: Optional[str] = "1"
    dose_unit: Optional[str] = "tablet" # mg, ml, tablet, capsule, drops, other
    time_of_day: Optional[str] = "Morning"
    food_instruction: Optional[str] = "After Food" # Before Food, After Food, With Food, Empty Stomach, Not Specified, Before breakfast, etc.
    disease_condition: Optional[str] = None # Diabetes, Blood pressure, Fever, Infection, Heart condition, Other
    frequency: Optional[str] = "Once a day" # Once a day, Twice a day, Three times a day, Custom
    duration: Optional[str] = "30 Days"
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    instructions: Optional[str] = None
    notes: Optional[str] = None

class MedicineUpdate(BaseModel):
    medicine_name: Optional[str] = None
    dose: Optional[str] = None
    dose_unit: Optional[str] = None
    time_of_day: Optional[str] = None
    food_instruction: Optional[str] = None
    disease_condition: Optional[str] = None
    frequency: Optional[str] = None
    duration: Optional[str] = None
    instructions: Optional[str] = None
    notes: Optional[str] = None

class MedicineStatusUpdate(BaseModel):
    medicine_id: str
    status: str # 'taken', 'skipped', 'snoozed', 'pending'
    log_date: Optional[str] = None

class MedicineOut(MedicineCreate):
    id: str
    parent_id: str
    created_at: datetime
    today_status: Optional[str] = "pending"

    class Config:
        from_attributes = True

class AppNotificationOut(BaseModel):
    id: str
    user_id: str
    title: str
    body: str
    type: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# --- Health Metrics & SOS & Reports ---

class HealthMetricCreate(BaseModel):
    blood_pressure_sys: Optional[str] = None
    blood_pressure_dia: Optional[str] = None
    heart_rate: Optional[str] = None
    water_intake_l: Optional[float] = None
    water_target_l: Optional[float] = 2.5
    steps_target: Optional[int] = 8000
    steps_actual: Optional[int] = None
    heart_rate_target: Optional[str] = "60-100 BPM"
    data_source: Optional[str] = "manual"
    notes: Optional[str] = None

class HealthMetricOut(HealthMetricCreate):
    id: str
    parent_id: str
    date: datetime

    class Config:
        from_attributes = True

class SOSTrigger(BaseModel):
    location_lat: Optional[str] = None
    location_lng: Optional[str] = None

class SOSAlertOut(SOSTrigger):
    id: str
    parent_id: str
    status: str
    timestamp: datetime
    parent_name: Optional[str] = None

    class Config:
        from_attributes = True

class MedicalReportOut(BaseModel):
    id: str
    parent_id: str
    title: str
    report_type: Optional[str] = "General"
    report_date: Optional[str] = None
    file_path: str
    file_type: str
    notes: Optional[str] = None
    ai_summary_json: Optional[str] = None
    upload_date: datetime

    class Config:
        from_attributes = True

class AISummaryOut(BaseModel):
    report_id: str
    overall_summary: str
    important_values: List[str]
    values_reference_status: List[str]
    noteworthy_findings: List[str]
    suggested_questions: List[str]
    recommended_next_steps: str
    disclaimer: str

# --- Auth & Email Verification & Password Reset ---

class VerifyEmailRequest(BaseModel):
    email: EmailStr
    code: str

class ResendVerificationRequest(BaseModel):
    email: EmailStr

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str

# --- Family Email Linking ---

class FamilyInviteEmailRequest(BaseModel):
    recipient_email: EmailStr

class FamilyAcceptEmailInviteRequest(BaseModel):
    invitation_code: str

class FamilyInvitationOut(BaseModel):
    id: str
    sender_id: str
    recipient_email: str
    invitation_code: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


# --- Admin ---

class ChartDataPoint(BaseModel):
    label: str
    value: float

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class EmailLogOut(BaseModel):
    id: str
    recipient_email: str
    notification_type: str
    subject: str
    status: str
    error_message: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class AdminStatsOut(BaseModel):
    total_users: int
    total_parents: int
    total_children: int
    total_doctors: int
    pending_doctors: int
    total_appointments: int
    total_reports: int
    active_sos: int
    patient_trend: Optional[List[ChartDataPoint]] = None
    medicine_stock: Optional[List[ChartDataPoint]] = None


