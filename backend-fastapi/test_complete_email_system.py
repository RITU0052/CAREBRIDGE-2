import sys
import os
import datetime
import time

sys.path.append(os.path.abspath("c:/Users/neera/Downloads/carebridge-ai-mvp 2/backend-fastapi"))

from app.database import SessionLocal, engine
from app import models, email_service

models.Base.metadata.create_all(bind=engine)

def run_tests():
    print("===============================================================")
    print("CAREBRIDGE COMPLETE EMAIL & NOTIFICATION SYSTEM VERIFICATION")
    print("===============================================================\n")

    test_email = "carebridge.notifications@gmail.com"
    test_user_id = "test-user-123"

    print("1. Testing Registration Confirmation Email...")
    email_service.send_registration_confirmation(test_email, "Neeraj (Test User)", "parent", "654321", user_id=test_user_id)
    print("   [OK] Registration Email Triggered")

    print("\n2. Testing OTP Verification Email...")
    email_service.send_otp_email(test_email, "Neeraj", "987654", action_name="Identity Verification", user_id=test_user_id)
    print("   [OK] OTP Email Triggered")

    print("\n3. Testing Forgot Password Reset Email...")
    email_service.send_password_reset_email(test_email, "Neeraj", "123456", user_id=test_user_id)
    print("   [OK] Password Reset Email Triggered")

    print("\n4. Testing Password Changed Security Alert Email...")
    email_service.send_account_security_notification(test_email, "Neeraj", user_id=test_user_id)
    print("   [OK] Password Changed Security Alert Triggered")

    print("\n5. Testing User Login Notification Email...")
    email_service.send_login_notification(test_email, "Neeraj", "parent", device_info="Chrome on Windows 11", user_id=test_user_id)
    print("   [OK] User Login Notification Triggered")

    print("\n6. Testing Doctor Login Notification Email...")
    email_service.send_doctor_login_notification(test_email, "Dr. Sarah Smith", device_info="CareBridge Doctor Portal", user_id=test_user_id)
    print("   [OK] Doctor Login Notification Triggered")

    print("\n7. Testing Parent -> Child Medicine Taken Email...")
    email_service.send_medicine_taken_notification(
        to_email=test_email,
        patient_name="Grandpa Ramesh",
        medicine_name="Metformin",
        dose="500 mg",
        time_of_day="Morning 08:00 AM",
        confirmed_by_name="Caregiver Neeraj",
        disease_condition="Diabetes",
        user_id=test_user_id
    )
    print("   [OK] Medicine Taken Email Triggered")

    print("\n8. Testing Medicine Schedule Reminder Email...")
    email_service.send_medicine_reminder(
        to_email=test_email,
        patient_name="Ramesh",
        medicine_name="Amlodipine",
        dose="5 mg",
        time_of_day="Evening 08:00 PM",
        food_instruction="After Food",
        disease_condition="Blood Pressure",
        user_id=test_user_id
    )
    print("   [OK] Medicine Reminder Triggered")

    print("\n9. Testing Missed Medicine Alert Email...")
    email_service.send_missed_medicine_notification(
        to_email=test_email,
        patient_name="Ramesh",
        medicine_name="Aspirin",
        dose="75 mg",
        scheduled_time="Morning 09:00 AM",
        current_status="Unconfirmed",
        user_id=test_user_id
    )
    print("   [OK] Missed Medicine Alert Triggered")

    print("\n10. Testing Appointment Booked Email...")
    email_service.send_appointment_confirmation(
        to_email=test_email,
        recipient_name="Neeraj",
        role="parent",
        doctor_name="Dr. Mehta",
        patient_name="Ramesh",
        date_str="2026-09-01",
        time_slot="10:30 AM",
        appt_type="Virtual",
        virtual_link="https://meet.jit.si/carebridge-demo",
        user_id=test_user_id
    )
    print("    [OK] Appointment Booked Email Triggered")

    print("\n11. Testing Appointment Rescheduled Email...")
    email_service.send_appointment_rescheduled_notification(
        to_email=test_email,
        recipient_name="Neeraj",
        doctor_name="Dr. Mehta",
        patient_name="Ramesh",
        old_date_time="2026-09-01 at 10:30 AM",
        new_date_time="2026-09-02 at 11:30 AM",
        user_id=test_user_id
    )
    print("    [OK] Appointment Rescheduled Email Triggered")

    print("\n12. Testing Appointment Cancelled Email...")
    email_service.send_appointment_cancelled_notification(
        to_email=test_email,
        recipient_name="Neeraj",
        doctor_name="Dr. Mehta",
        patient_name="Ramesh",
        appt_date="2026-09-02",
        appt_time="11:30 AM",
        cancelled_by="Patient",
        user_id=test_user_id
    )
    print("    [OK] Appointment Cancelled Email Triggered")

    print("\n13. Testing Report Uploaded Email...")
    email_service.send_report_uploaded_notification(
        to_email=test_email,
        recipient_name="Neeraj",
        patient_name="Ramesh",
        report_title="Annual Blood Panel CBC",
        report_type="Hematology Lab Test",
        upload_date_str="2026-08-22 21:00 UTC",
        uploaded_by="Neeraj",
        user_id=test_user_id
    )
    print("    [OK] Report Uploaded Email Triggered")

    print("\n14. Testing AI Report Summary Completion Email...")
    email_service.send_report_summary_notification(
        to_email=test_email,
        recipient_name="Neeraj",
        patient_name="Ramesh",
        report_title="Annual Blood Panel CBC",
        overall_summary="Hemoglobin and platelet levels are within normal reference bounds. Glucose markers reflect stable glycemic control.",
        user_id=test_user_id
    )
    print("    [OK] AI Report Summary Email Triggered")

    print("\n15. Testing Doctor Status Verification Email...")
    email_service.send_doctor_status_notification(
        to_email=test_email,
        doctor_name="Dr. Mehta",
        is_approved=True,
        user_id=test_user_id
    )
    print("    [OK] Doctor Approval Email Triggered")

    print("\n16. Testing Admin System Alert Email...")
    email_service.send_admin_notification(
        to_email=test_email,
        admin_name="CareBridge System Admin",
        alert_title="New Doctor Pending Approval",
        alert_details="Dr. Mehta (MBBS, MD Cardiology) registered and requires credential verification.",
        user_id=test_user_id
    )
    print("    [OK] Admin Alert Email Triggered")

    print("\nWaiting for async threads to finalize delivery & DB logging...")
    time.sleep(4.0)

    # Audit email_logs database table
    db = SessionLocal()
    try:
        logs = db.query(models.EmailLog).order_by(models.EmailLog.created_at.desc()).limit(20).all()
        print(f"\n===============================================================")
        print(f"DATABASE AUDIT: {len(logs)} Recent Email Log Entries Recorded")
        print(f"===============================================================")
        for log in logs[:16]:
            print(f"[{log.status.upper()}] Type: {log.notification_type:<26} | To: {log.recipient_email} | Subject: {log.subject[:38]}")
    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
