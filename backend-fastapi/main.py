from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
import os

from app.database import engine, SessionLocal
from app import models, auth
from app.routers import auth as auth_router, health, sos, reports, doctors, appointments, services_router, admin_router, medicines, notifications, family as family_router, hospitals

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="CareBridge AI MVP", version="2.0.0")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router.router, prefix="/api/auth", tags=["auth"])
app.include_router(health.router, prefix="/api/health", tags=["health"])
app.include_router(family_router.router, prefix="/api/family", tags=["family"])
app.include_router(sos.router, prefix="/api/sos", tags=["sos"])
app.include_router(reports.router, prefix="/api/reports", tags=["reports"])
app.include_router(doctors.router, prefix="/api/doctors", tags=["doctors"])
app.include_router(appointments.router, prefix="/api/appointments", tags=["appointments"])
app.include_router(services_router.router, prefix="/api/services", tags=["services"])
app.include_router(admin_router.router, prefix="/api/admin", tags=["admin"])
app.include_router(medicines.router, prefix="/api/medicines", tags=["medicines"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(hospitals.router, prefix="/api/hospitals", tags=["hospitals"])

os.makedirs("static/reports", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")
from sqlalchemy import text

def auto_migrate():
    db: Session = SessionLocal()
    try:
        # Users
        u_cols = [r[1] for r in db.execute(text("PRAGMA table_info(users)")).fetchall()]
        if u_cols and "family_code" not in u_cols:
            db.execute(text("ALTER TABLE users ADD COLUMN family_code VARCHAR(10)"))
        if u_cols and "is_active" not in u_cols:
            db.execute(text("ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT 1"))
        if u_cols and "is_email_verified" not in u_cols:
            db.execute(text("ALTER TABLE users ADD COLUMN is_email_verified BOOLEAN DEFAULT 0"))
        if u_cols and "email_verification_code" not in u_cols:
            db.execute(text("ALTER TABLE users ADD COLUMN email_verification_code VARCHAR(6)"))


        # Emergency Contacts
        ec_cols = [r[1] for r in db.execute(text("PRAGMA table_info(emergency_contacts)")).fetchall()]
        if ec_cols and "email" not in ec_cols:
            db.execute(text("ALTER TABLE emergency_contacts ADD COLUMN email VARCHAR"))

        # Doctors
        d_cols = [r[1] for r in db.execute(text("PRAGMA table_info(doctors)")).fetchall()]
        if d_cols and "status" not in d_cols:
            db.execute(text("ALTER TABLE doctors ADD COLUMN status VARCHAR DEFAULT 'verified'"))
        if d_cols and "profession" not in d_cols:
            db.execute(text("ALTER TABLE doctors ADD COLUMN profession VARCHAR DEFAULT 'Physician'"))
        if d_cols and "phone" not in d_cols:
            db.execute(text("ALTER TABLE doctors ADD COLUMN phone VARCHAR"))
        if d_cols and "email" not in d_cols:
            db.execute(text("ALTER TABLE doctors ADD COLUMN email VARCHAR"))
        if d_cols and "consultation_type" not in d_cols:
            db.execute(text("ALTER TABLE doctors ADD COLUMN consultation_type VARCHAR DEFAULT 'Both'"))

        # Medicines
        m_cols = [r[1] for r in db.execute(text("PRAGMA table_info(medicines)")).fetchall()]
        if m_cols and "frequency" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN frequency VARCHAR DEFAULT 'Daily'"))
        if m_cols and "duration" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN duration VARCHAR DEFAULT '30 Days'"))
        if m_cols and "start_date" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN start_date VARCHAR"))
        if m_cols and "end_date" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN end_date VARCHAR"))
        if m_cols and "instructions" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN instructions TEXT"))
        if m_cols and "notes" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN notes TEXT"))
        if m_cols and "dose_unit" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN dose_unit VARCHAR DEFAULT 'tablet'"))
        if m_cols and "food_instruction" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN food_instruction VARCHAR DEFAULT 'After Food'"))
        if m_cols and "disease_condition" not in m_cols:
            db.execute(text("ALTER TABLE medicines ADD COLUMN disease_condition VARCHAR"))

        # Appointments
        ap_cols = [r[1] for r in db.execute(text("PRAGMA table_info(appointments)")).fetchall()]
        if ap_cols and "appointment_type" not in ap_cols:
            db.execute(text("ALTER TABLE appointments ADD COLUMN appointment_type VARCHAR DEFAULT 'In-person'"))
        if ap_cols and "previous_date_time" not in ap_cols:
            db.execute(text("ALTER TABLE appointments ADD COLUMN previous_date_time VARCHAR"))
        if ap_cols and "reschedule_reason" not in ap_cols:
            db.execute(text("ALTER TABLE appointments ADD COLUMN reschedule_reason VARCHAR"))
        if ap_cols and "reminder_time_minutes" not in ap_cols:
            db.execute(text("ALTER TABLE appointments ADD COLUMN reminder_time_minutes INTEGER"))
        if ap_cols and "virtual_link" not in ap_cols:
            db.execute(text("ALTER TABLE appointments ADD COLUMN virtual_link VARCHAR"))

        # Health Metrics
        hm_cols = [r[1] for r in db.execute(text("PRAGMA table_info(health_metrics)")).fetchall()]
        if hm_cols and "water_intake_l" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN water_intake_l FLOAT"))
        if hm_cols and "water_target_l" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN water_target_l FLOAT DEFAULT 2.5"))
        if hm_cols and "steps_target" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN steps_target INTEGER DEFAULT 8000"))
        if hm_cols and "steps_actual" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN steps_actual INTEGER"))
        if hm_cols and "heart_rate_target" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN heart_rate_target VARCHAR DEFAULT '60-100 BPM'"))
        if hm_cols and "data_source" not in hm_cols:
            db.execute(text("ALTER TABLE health_metrics ADD COLUMN data_source VARCHAR DEFAULT 'not_connected'"))

        # Medical Reports
        r_cols = [r[1] for r in db.execute(text("PRAGMA table_info(medical_reports)")).fetchall()]
        if r_cols and "report_type" not in r_cols:
            db.execute(text("ALTER TABLE medical_reports ADD COLUMN report_type VARCHAR DEFAULT 'General'"))
        if r_cols and "report_date" not in r_cols:
            db.execute(text("ALTER TABLE medical_reports ADD COLUMN report_date VARCHAR"))
        if r_cols and "notes" not in r_cols:
            db.execute(text("ALTER TABLE medical_reports ADD COLUMN notes TEXT"))
        if r_cols and "ai_summary_json" not in r_cols:
            db.execute(text("ALTER TABLE medical_reports ADD COLUMN ai_summary_json TEXT"))

        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Auto-migrate warning: {e}")
    finally:
        db.close()

auto_migrate()

def seed_initial_data():
    db: Session = SessionLocal()
    try:
        # 1. Seed / Update Admin User
        admin_user = db.query(models.User).filter(models.User.email == "admin@carebridge.com").first()
        hashed = auth.get_password_hash("Admin@123")
        if not admin_user:
            admin_user = models.User(
                name="CareBridge Admin",
                email="admin@carebridge.com",
                phone="+18005550199",
                password_hash=hashed,
                role="admin",
                bio="Head of Platform Operations"
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
        else:
            admin_user.password_hash = hashed
            db.commit()
    except Exception as e:
        db.rollback()
        print(f"Admin seed warning: {e}")


    try:
        # 2. Seed Specialties
        if db.query(models.Specialty).count() == 0:
            specialties = [
                models.Specialty(id="spec-1", name="General Physician", description="Primary healthcare & diagnosis", icon="stethoscope"),
                models.Specialty(id="spec-2", name="Cardiology", description="Heart & vascular care", icon="heart"),
                models.Specialty(id="spec-3", name="Neurology", description="Brain and nervous system", icon="brain"),
                models.Specialty(id="spec-4", name="Orthopedics", description="Bone, joint, and muscle care", icon="bone"),
                models.Specialty(id="spec-5", name="Pediatrics", description="Child health and development", icon="baby"),
                models.Specialty(id="spec-6", name="Dermatology", description="Skin care & treatment", icon="sparkles"),
            ]
            db.add_all(specialties)
            db.commit()
    except Exception as e:
        db.rollback()
        print(f"Specialty seed warning: {e}")

    try:
        # 3. Seed Services
        if db.query(models.Service).count() == 0:
            services = [
                models.Service(id="srv-1", name="Doctor Consultation", description="In-person or virtual video consultation with experienced physicians.", category="General", icon="stethoscope"),
                models.Service(id="srv-2", name="Appointment Booking", description="Instant online booking with flexible slot choices and reminder notifications.", category="Booking", icon="calendar"),
                models.Service(id="srv-3", name="Telemedicine", description="Remote virtual video and chat consultations from home.", category="Virtual", icon="video"),
                models.Service(id="srv-4", name="Health Records", description="Secure storage and management of medical reports, lab tests, and histories.", category="Records", icon="file-text"),
                models.Service(id="srv-5", name="Medication Management", description="Daily medicine schedules, dosage tracking, and family alert sync.", category="Medicine", icon="pill"),
                models.Service(id="srv-6", name="Emergency Support", description="One-touch SOS button sending instant GPS location alerts to caregivers.", category="Emergency", icon="shield-alert"),
            ]
            db.add_all(services)
            db.commit()
    except Exception as e:
        db.rollback()
        print(f"Service seed warning: {e}")

    try:
        # 4. Seed Doctors
        if db.query(models.Doctor).count() == 0:
            doctors_data = [
                models.Doctor(
                    id="doc-1",
                    name="Dr. Sarah Jenkins",
                    specialty="Cardiology",
                    experience_years=14,
                    qualifications="MD, FACC, Harvard Medical School",
                    languages="English, Spanish",
                    consultation_fee=75.0,
                    location="Metro Heart Center, Suite 400",
                    bio="Dr. Sarah Jenkins is a board-certified cardiologist specializing in preventive cardiology, heart failure management, and geriatric cardiac wellness.",
                    is_verified=True,
                    rating=4.9,
                    review_count=38,
                    profile_image="https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=400"
                ),
                models.Doctor(
                    id="doc-2",
                    name="Dr. Marcus Thorne",
                    specialty="General Physician",
                    experience_years=10,
                    qualifications="MBBS, MD (Internal Medicine)",
                    languages="English, French",
                    consultation_fee=50.0,
                    location="CareBridge Primary Clinic",
                    bio="Dr. Marcus Thorne provides comprehensive family health management, chronic disease monitoring, and routine wellness checkups.",
                    is_verified=True,
                    rating=4.8,
                    review_count=45,
                    profile_image="https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400"
                ),
                models.Doctor(
                    id="doc-3",
                    name="Dr. Elena Rostova",
                    specialty="Neurology",
                    experience_years=12,
                    qualifications="MD, PhD (Neuroscience)",
                    languages="English, German, Russian",
                    consultation_fee=90.0,
                    location="Neurology & Spine Institute",
                    bio="Dr. Elena Rostova specializes in memory care, neuro-rehabilitation, stroke recovery, and tremor monitoring for senior patients.",
                    is_verified=True,
                    rating=5.0,
                    review_count=29,
                    profile_image="https://images.unsplash.com/photo-1594824813566-88855ce78947?auto=format&fit=crop&q=80&w=400"
                ),
                models.Doctor(
                    id="doc-4",
                    name="Dr. David Chen",
                    specialty="Orthopedics",
                    experience_years=16,
                    qualifications="MD, MS (Orthopedics)",
                    languages="English, Mandarin",
                    consultation_fee=85.0,
                    location="City Orthopedic & Joint Care",
                    bio="Dr. David Chen is an orthopedic surgeon expert in joint replacement, mobility rehabilitation, and arthritis treatment.",
                    is_verified=True,
                    rating=4.7,
                    review_count=52,
                    profile_image="https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=400"
                )
            ]
            db.add_all(doctors_data)
            db.commit()

            admin_user = db.query(models.User).filter(models.User.email == "admin@carebridge.com").first()
            if admin_user:
                rev1 = models.Review(
                    doctor_id="doc-1",
                    user_id=admin_user.id,
                    rating=5.0,
                    comment="Dr. Sarah was exceptionally patient with my mother's blood pressure assessment. Very clear instructions and warm demeanor!"
                )
                db.add(rev1)
                db.commit()
    except Exception as e:
        db.rollback()
        print(f"Doctor seed warning: {e}")
    finally:
        db.close()

seed_initial_data()

@app.get("/")
def root():
    return {"message": "Welcome to CareBridge AI API v2.0"}

@app.get("/api/health")
def health_check():
    return {"status": "healthy", "service": "CareBridge AI Backend"}
