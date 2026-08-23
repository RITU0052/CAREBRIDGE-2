import os
import smtplib
import datetime
import threading
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

from app.database import SessionLocal
from app import models
from app import email_templates

load_dotenv()

def _log_email_status(recipient_email: str, notification_type: str, subject: str, status: str, error_message: str = None, user_id: str = None, related_id: str = None):
    """
    Logs email delivery status to the email_logs database table.
    """
    try:
        db = SessionLocal()
        try:
            log_entry = models.EmailLog(
                recipient_email=recipient_email,
                notification_type=notification_type or "general",
                subject=subject,
                status=status,
                error_message=error_message[:500] if error_message else None,
                user_id=user_id,
                related_id=related_id
            )
            db.add(log_entry)
            db.commit()
        finally:
            db.close()
    except Exception as log_err:
        print(f"[EMAIL LOGGING ERROR] {log_err}")


def send_email(
    to_email: str,
    subject: str,
    body_html: str,
    body_text: str,
    notification_type: str = "general",
    user_id: str = None,
    related_id: str = None,
    sync: bool = False
):
    """
    Sends an email using configured SMTP credentials and records the outcome.
    By default runs asynchronously in a daemon background thread so main API requests remain fast.
    """
    def _dispatch():
        smtp_server = os.getenv("SMTP_SERVER", os.getenv("SMTP_HOST", "")).strip()
        smtp_port = int(os.getenv("SMTP_PORT", "587").strip())
        smtp_user = os.getenv("SMTP_USER", "").strip()
        smtp_password = os.getenv("SMTP_PASSWORD", "").strip()
        if "gmail" in smtp_server.lower():
            smtp_password = smtp_password.replace(" ", "")
        sender_email = os.getenv("SENDER_EMAIL", os.getenv("SMTP_FROM", "noreply@carebridge.com")).strip()

        print(f"\n======== [EMAIL DISPATCH TO: {to_email}] ========")
        print(f"Subject: {subject}")
        print(f"Type: {notification_type}")
        print("===================================================\n")

        if smtp_server and smtp_user and smtp_password:
            try:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject
                msg["From"] = sender_email
                msg["To"] = to_email

                part1 = MIMEText(body_text, "plain", "utf-8")
                part2 = MIMEText(body_html, "html", "utf-8")
                msg.attach(part1)
                msg.attach(part2)

                if smtp_port == 465:
                    with smtplib.SMTP_SSL(smtp_server, smtp_port, timeout=10) as server:
                        server.login(smtp_user, smtp_password)
                        server.sendmail(sender_email, to_email, msg.as_string())
                else:
                    with smtplib.SMTP(smtp_server, smtp_port, timeout=10) as server:
                        server.starttls()
                        server.login(smtp_user, smtp_password)
                        server.sendmail(sender_email, to_email, msg.as_string())

                print(f"SUCCESS: Email sent via SMTP to {to_email}")
                _log_email_status(to_email, notification_type, subject, "sent", user_id=user_id, related_id=related_id)
            except Exception as e:
                err_msg = str(e)
                print(f"WARNING: Failed to send email via SMTP ({smtp_server}): {err_msg}")
                _log_email_status(to_email, notification_type, subject, "failed", error_message=err_msg, user_id=user_id, related_id=related_id)
        else:
            print(f"[NOTICE] SMTP credentials missing in .env. Email body logged to console.")
            _log_email_status(to_email, notification_type, subject, "sent_console_mock", user_id=user_id, related_id=related_id)

    if sync:
        _dispatch()
    else:
        thread = threading.Thread(target=_dispatch, daemon=True)
        thread.start()


# Helper wrapper functions for specific module events

def send_registration_confirmation(to_email: str, user_name: str, role: str, verification_code: str = None, user_id: str = None):
    subject, html, text = email_templates.get_welcome_email_template(user_name, role, verification_code)
    send_email(to_email, subject, html, text, notification_type="welcome", user_id=user_id)

def send_otp_email(to_email: str, user_name: str, otp_code: str, action_name: str = "Verification", user_id: str = None):
    subject, html, text = email_templates.get_otp_email_template(user_name, otp_code, action_name)
    send_email(to_email, subject, html, text, notification_type="otp", user_id=user_id)

def send_password_reset_email(to_email: str, user_name: str, otp_code: str, user_id: str = None):
    subject, html, text = email_templates.get_forgot_password_email_template(user_name, otp_code)
    send_email(to_email, subject, html, text, notification_type="forgot_password", user_id=user_id)

def send_account_security_notification(to_email: str, user_name: str, change_time_str: str = None, user_id: str = None):
    if not change_time_str:
        change_time_str = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    subject, html, text = email_templates.get_password_changed_email_template(user_name, change_time_str)
    send_email(to_email, subject, html, text, notification_type="password_changed", user_id=user_id)

def send_login_notification(to_email: str, user_name: str, role: str, device_info: str = "Web Client", user_id: str = None):
    login_time_str = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    subject, html, text = email_templates.get_login_notification_email_template(user_name, role, login_time_str, device_info, is_doctor=False)
    send_email(to_email, subject, html, text, notification_type="login_alert", user_id=user_id)

def send_doctor_login_notification(to_email: str, doctor_name: str, device_info: str = "Doctor Portal", user_id: str = None, extra_summary: str = None):
    login_time_str = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    subject, html, text = email_templates.get_login_notification_email_template(doctor_name, "Doctor", login_time_str, device_info, is_doctor=True, extra_summary=extra_summary)
    send_email(to_email, subject, html, text, notification_type="doctor_login_alert", user_id=user_id)

def send_medicine_taken_notification(to_email: str, patient_name: str, medicine_name: str, dose: str, time_of_day: str, confirmed_by_name: str, disease_condition: str = None, user_id: str = None, related_id: str = None):
    taken_time_str = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    subject, html, text = email_templates.get_medicine_taken_email_template(patient_name, medicine_name, dose, time_of_day, confirmed_by_name, taken_time_str, disease_condition)
    send_email(to_email, subject, html, text, notification_type="medicine_taken", user_id=user_id, related_id=related_id)

def send_medicine_reminder(to_email: str, patient_name: str, medicine_name: str, dose: str, time_of_day: str, food_instruction: str = "After Food", disease_condition: str = None, user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_medicine_reminder_email_template(patient_name, medicine_name, dose, time_of_day, food_instruction, disease_condition)
    send_email(to_email, subject, html, text, notification_type="medicine_reminder", user_id=user_id, related_id=related_id)

def send_missed_medicine_notification(to_email: str, patient_name: str, medicine_name: str, dose: str, scheduled_time: str, current_status: str = "Unconfirmed", user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_missed_medicine_email_template(patient_name, medicine_name, dose, scheduled_time, current_status)
    send_email(to_email, subject, html, text, notification_type="missed_medicine", user_id=user_id, related_id=related_id)

def send_appointment_confirmation(to_email: str, recipient_name: str, role: str, doctor_name: str, patient_name: str, date_str: str, time_slot: str, appt_type: str = "In-person", virtual_link: str = None, user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_appointment_confirmation_email_template(recipient_name, role, doctor_name, patient_name, date_str, time_slot, appt_type, virtual_link)
    send_email(to_email, subject, html, text, notification_type="appointment_booked", user_id=user_id, related_id=related_id)

def send_appointment_rescheduled_notification(to_email: str, recipient_name: str, doctor_name: str, patient_name: str, old_date_time: str, new_date_time: str, status_str: str = "Rescheduled", user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_appointment_rescheduled_email_template(recipient_name, doctor_name, patient_name, old_date_time, new_date_time, status_str)
    send_email(to_email, subject, html, text, notification_type="appointment_rescheduled", user_id=user_id, related_id=related_id)

def send_appointment_cancelled_notification(to_email: str, recipient_name: str, doctor_name: str, patient_name: str, appt_date: str, appt_time: str, cancelled_by: str = "User", user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_appointment_cancelled_email_template(recipient_name, doctor_name, patient_name, appt_date, appt_time, cancelled_by)
    send_email(to_email, subject, html, text, notification_type="appointment_cancelled", user_id=user_id, related_id=related_id)

def send_appointment_reminder(to_email: str, recipient_name: str, doctor_name: str, patient_name: str, appt_date: str, appt_time: str, appt_type: str = "In-person", virtual_link: str = None, user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_appointment_reminder_email_template(recipient_name, doctor_name, patient_name, appt_date, appt_time, appt_type, virtual_link)
    send_email(to_email, subject, html, text, notification_type="appointment_reminder", user_id=user_id, related_id=related_id)

def send_report_uploaded_notification(to_email: str, recipient_name: str, patient_name: str, report_title: str, report_type: str, upload_date_str: str, uploaded_by: str, user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_report_uploaded_email_template(recipient_name, patient_name, report_title, report_type, upload_date_str, uploaded_by)
    send_email(to_email, subject, html, text, notification_type="report_uploaded", user_id=user_id, related_id=related_id)

def send_report_summary_notification(to_email: str, recipient_name: str, patient_name: str, report_title: str, overall_summary: str, user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_report_summary_email_template(recipient_name, patient_name, report_title, overall_summary)
    send_email(to_email, subject, html, text, notification_type="report_summary", user_id=user_id, related_id=related_id)

def send_doctor_notification(to_email: str, doctor_name: str, patient_name: str, appt_date: str, time_slot: str, appt_type: str = "In-person", user_id: str = None, related_id: str = None):
    subject, html, text = email_templates.get_doctor_appointment_request_email_template(doctor_name, patient_name, appt_date, time_slot, appt_type)
    send_email(to_email, subject, html, text, notification_type="doctor_appointment_request", user_id=user_id, related_id=related_id)

def send_doctor_status_notification(to_email: str, doctor_name: str, is_approved: bool = True, reason: str = None, user_id: str = None):
    subject, html, text = email_templates.get_doctor_approval_email_template(doctor_name, is_approved, reason)
    send_email(to_email, subject, html, text, notification_type="doctor_verification_status", user_id=user_id)

def send_admin_notification(to_email: str, admin_name: str, alert_title: str, alert_details: str, user_id: str = None):
    event_time_str = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    subject, html, text = email_templates.get_admin_alert_email_template(admin_name, alert_title, alert_details, event_time_str)
    send_email(to_email, subject, html, text, notification_type="admin_alert", user_id=user_id)

def send_family_invitation_email(to_email: str, sender_name: str, sender_role: str, invitation_code: str):
    subject = f"CareBridge AI - {sender_name} invited you to link your family account!"
    body_text = f"Hello,\n\n{sender_name} ({sender_role.capitalize()}) has invited you to link accounts on CareBridge AI.\nYour Invitation Code: {invitation_code}\n\nEnter code: {invitation_code} in CareBridge AI to accept.\n"
    body_html = f"<h3>CareBridge AI Family Invitation</h3><p><strong>{sender_name}</strong> invited you to link family accounts.</p><p>Invitation Code: <strong style='font-size: 20px; color: #7C3AED;'>{invitation_code}</strong></p>"
    send_email(to_email, subject, body_html, body_text, notification_type="family_invitation")

def send_link_confirmation_email(to_email: str, user_name: str, linked_partner_name: str):
    subject = "CareBridge AI - Family Accounts Linked Successfully!"
    body_text = f"Hello {user_name},\n\nYour account has been linked with {linked_partner_name} on CareBridge AI.\n"
    body_html = f"<h3>Family Accounts Linked</h3><p>Hello {user_name}, your account is now linked with <strong>{linked_partner_name}</strong>.</p>"
    send_email(to_email, subject, body_html, body_text, notification_type="family_linked")
