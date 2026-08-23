"""
CareBridge AI - Centralized HTML Email Templates Builder
Provides responsive, branded HTML email templates for all application events.
"""

def _base_email_layout(title: str, subtitle: str, body_html: str, action_button_html: str = "") -> str:
    """
    Renders the master CareBridge branded HTML wrapper.
    """
    return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title}</title>
    <style>
        body {{
            font-family: 'Segoe UI', Helvetica, Arial, sans-serif;
            background-color: #F8F9FD;
            margin: 0;
            padding: 0;
            color: #0F172A;
            -webkit-text-size-adjust: 100%;
        }}
        .container {{
            max-width: 600px;
            margin: 30px auto;
            background-color: #FFFFFF;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 10px 30px rgba(108, 92, 231, 0.08);
            border: 1px solid #E2E8F0;
        }}
        .header {{
            background: linear-gradient(135deg, #7C3AED 0%, #6366F1 100%);
            padding: 36px 32px;
            text-align: center;
            color: #FFFFFF;
        }}
        .logo-badge {{
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 8px 18px;
            border-radius: 24px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            margin-bottom: 12px;
        }}
        .header h1 {{
            margin: 0;
            font-size: 24px;
            font-weight: 700;
        }}
        .header p {{
            margin: 8px 0 0 0;
            font-size: 14px;
            opacity: 0.9;
        }}
        .content {{
            padding: 32px;
            line-height: 1.6;
            font-size: 15px;
        }}
        .info-card {{
            background-color: #F1F4FF;
            border-left: 4px solid #6C5CE7;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 20px 0;
        }}
        .alert-card {{
            background-color: #FEF2F2;
            border-left: 4px solid #EF4444;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 20px 0;
            color: #991B1B;
        }}
        .btn {{
            display: inline-block;
            background: linear-gradient(135deg, #7C3AED 0%, #6366F1 100%);
            color: #FFFFFF !important;
            text-decoration: none;
            padding: 14px 28px;
            border-radius: 12px;
            font-weight: 600;
            font-size: 15px;
            margin: 20px 0;
            text-align: center;
        }}
        .footer {{
            background-color: #F8FAFC;
            padding: 24px;
            text-align: center;
            font-size: 12px;
            color: #94A3B8;
            border-top: 1px solid #F1F5F9;
        }}
        .footer a {{
            color: #6C5CE7;
            text-decoration: none;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo-badge">CareBridge AI</div>
            <h1>{title}</h1>
            <p>{subtitle}</p>
        </div>
        <div class="content">
            {body_html}
            {action_button_html}
        </div>
        <div class="footer">
            <p>© CareBridge – Healthcare Management Platform</p>
            <p>Empowering families and healthcare providers with intelligent care monitoring.</p>
        </div>
    </div>
</body>
</html>"""


def get_welcome_email_template(user_name: str, role: str, verification_code: str = None) -> tuple[str, str]:
    subject = "Welcome to CareBridge AI - Account Registered!"
    code_box = ""
    if verification_code:
        code_box = f"""
        <div class="info-card" style="text-align: center;">
            <p style="margin: 0; font-size: 13px; color: #475569;">Your Email Verification OTP Code:</p>
            <h2 style="margin: 8px 0; font-size: 32px; letter-spacing: 6px; color: #7C3AED;">{verification_code}</h2>
            <p style="margin: 0; font-size: 12px; color: #94A3B8;">This code is valid for 15 minutes.</p>
        </div>"""

    html = _base_email_layout(
        title="Welcome to CareBridge AI!",
        subtitle="Your smart healthcare companion",
        body_html=f"""
        <p>Hello <strong>{user_name}</strong>,</p>
        <p>Thank you for creating your CareBridge AI account as a <strong>{role.capitalize()}</strong>.</p>
        <p>CareBridge connects patients, caregivers, and doctors in real time for effortless medication tracking, vital sign monitoring, AI report analysis, and emergency alerts.</p>
        {code_box}
        <p><strong>Next Steps:</strong></p>
        <ul>
            <li>Complete your profile setup.</li>
            <li>Link your family members or caregivers.</li>
            <li>Schedule medications and health reminders.</li>
        </ul>
        """
    )
    text = f"Welcome to CareBridge AI, {user_name}! Role: {role}. {f'OTP: {verification_code}' if verification_code else ''}"
    return subject, html, text


def get_otp_email_template(user_name: str, otp_code: str, action_name: str = "Verification") -> tuple[str, str, str]:
    subject = f"CareBridge AI - {action_name} Security Code: {otp_code}"
    html = _base_email_layout(
        title=f"Security Code ({action_name})",
        subtitle="Requested security authentication code",
        body_html=f"""
        <p>Hello <strong>{user_name}</strong>,</p>
        <p>You requested a security code for <strong>{action_name}</strong> on CareBridge AI.</p>
        <div class="info-card" style="text-align: center;">
            <p style="margin: 0; font-size: 13px; color: #475569;">Your Security OTP:</p>
            <h2 style="margin: 8px 0; font-size: 36px; letter-spacing: 8px; color: #7C3AED;">{otp_code}</h2>
            <p style="margin: 0; font-size: 12px; color: #94A3B8;">Expires in 15 minutes. Never share this code with anyone.</p>
        </div>
        <p>If you did not request this code, please ignore this email or secure your account.</p>
        """
    )
    text = f"Hello {user_name}, your CareBridge AI {action_name} security code is {otp_code}. Valid for 15 minutes."
    return subject, html, text


def get_forgot_password_email_template(user_name: str, otp_code: str) -> tuple[str, str, str]:
    subject = "CareBridge AI - Password Reset Code"
    html = _base_email_layout(
        title="Password Reset Request",
        subtitle="Secure account recovery code",
        body_html=f"""
        <p>Hello <strong>{user_name}</strong>,</p>
        <p>We received a request to reset the password for your CareBridge AI account.</p>
        <div class="info-card" style="text-align: center;">
            <p style="margin: 0; font-size: 13px; color: #475569;">Your Password Reset Code:</p>
            <h2 style="margin: 8px 0; font-size: 36px; letter-spacing: 8px; color: #7C3AED;">{otp_code}</h2>
            <p style="margin: 0; font-size: 12px; color: #94A3B8;">This single-use code expires in 15 minutes.</p>
        </div>
        <p>Enter this code in the CareBridge app to choose a new secure password.</p>
        <p style="color: #94A3B8; font-size: 13px;">If you did not request a password reset, your account is safe and no action is required.</p>
        """
    )
    text = f"Hello {user_name}, your CareBridge password reset code is {otp_code}. Valid for 15 minutes."
    return subject, html, text


def get_password_changed_email_template(user_name: str, change_time_str: str) -> tuple[str, str, str]:
    subject = "CareBridge AI - Security Alert: Password Changed"
    html = _base_email_layout(
        title="Password Updated Successfully",
        subtitle="Security Notice",
        body_html=f"""
        <p>Hello <strong>{user_name}</strong>,</p>
        <p>This email confirms that your password for CareBridge AI was successfully changed on <strong>{change_time_str}</strong>.</p>
        <div class="info-card">
            <p style="margin: 0;"><strong>Security Note:</strong> Your old password has been invalidated and all active sessions are secured.</p>
        </div>
        <div class="alert-card">
            <p style="margin: 0;">If you did <strong>NOT</strong> perform this password change, please contact support or reset your password immediately.</p>
        </div>
        """
    )
    text = f"Hello {user_name}, your CareBridge password was changed on {change_time_str}. If this wasn't you, reset your password immediately."
    return subject, html, text


def get_login_notification_email_template(user_name: str, role: str, login_time_str: str, device_info: str = "Web / Mobile Client", is_doctor: str = False, extra_summary: str = None) -> tuple[str, str, str]:
    subject = f"CareBridge AI - New Account Sign-In ({role.capitalize()})"
    doctor_banner = "<p><strong>Role:</strong> Doctor Access Authorized</p>" if is_doctor else f"<p><strong>Role:</strong> {role.capitalize()}</p>"
    summary_section = f'<div class="info-card"><p style="margin: 0;">{extra_summary}</p></div>' if extra_summary else ""

    html = _base_email_layout(
        title="Security Alert: New Sign-In",
        subtitle="Account activity notification",
        body_html=f"""
        <p>Hello <strong>{user_name}</strong>,</p>
        <p>Your CareBridge AI account was signed into successfully.</p>
        <div class="info-card">
            {doctor_banner}
            <p style="margin: 4px 0;"><strong>Time:</strong> {login_time_str}</p>
            <p style="margin: 4px 0;"><strong>Device/Client:</strong> {device_info}</p>
        </div>
        {summary_section}
        <p style="font-size: 13px; color: #64748B;">If this was you, you can safely disregard this email. If you did not sign in, please reset your password to protect your account.</p>
        """
    )
    text = f"Hello {user_name}, new sign-in detected on {login_time_str} ({device_info}). If this wasn't you, please reset your password."
    return subject, html, text


def get_medicine_taken_email_template(patient_name: str, medicine_name: str, dose: str, time_of_day: str, confirmed_by_name: str, taken_time_str: str, disease_condition: str = None) -> tuple[str, str, str]:
    subject = f"Medicine Taken Confirmation – CareBridge ({medicine_name})"
    condition_str = f"<p><strong>Condition/Purpose:</strong> {disease_condition}</p>" if disease_condition else ""

    html = _base_email_layout(
        title="Medicine Confirmed Taken ✓",
        subtitle="Caregiver activity alert",
        body_html=f"""
        <p>Hello,</p>
        <p>Your parent/caregiver <strong>{confirmed_by_name}</strong> has confirmed that a scheduled medication dose was taken for <strong>{patient_name}</strong>.</p>
        <div class="info-card">
            <h3 style="margin: 0 0 8px 0; color: #7C3AED;">💊 {medicine_name}</h3>
            <p style="margin: 4px 0;"><strong>Dose:</strong> {dose}</p>
            <p style="margin: 4px 0;"><strong>Scheduled Time:</strong> {time_of_day}</p>
            <p style="margin: 4px 0;"><strong>Confirmed Time:</strong> {taken_time_str}</p>
            <p style="margin: 4px 0;"><strong>Confirmed By:</strong> {confirmed_by_name}</p>
            {condition_str}
        </div>
        <p style="font-size: 13px; color: #64748B;">CareBridge automatically synchronizes health monitoring between patients and family caregivers.</p>
        """
    )
    text = f"Medicine Taken: {confirmed_by_name} confirmed {medicine_name} ({dose}) was taken for {patient_name} at {taken_time_str}."
    return subject, html, text


def get_medicine_reminder_email_template(patient_name: str, medicine_name: str, dose: str, time_of_day: str, food_instruction: str = "After Food", disease_condition: str = None) -> tuple[str, str, str]:
    subject = f"Medicine Reminder: Time to take {medicine_name} ({dose})"
    condition_str = f"<p><strong>Condition:</strong> {disease_condition}</p>" if disease_condition else ""

    html = _base_email_layout(
        title="Medication Schedule Reminder",
        subtitle="Scheduled prescription alert",
        body_html=f"""
        <p>Hello <strong>{patient_name}</strong>,</p>
        <p>This is a reminder to take your scheduled medication:</p>
        <div class="info-card">
            <h3 style="margin: 0 0 8px 0; color: #7C3AED;">💊 {medicine_name}</h3>
            <p style="margin: 4px 0;"><strong>Dose:</strong> {dose}</p>
            <p style="margin: 4px 0;"><strong>Schedule:</strong> {time_of_day}</p>
            <p style="margin: 4px 0;"><strong>Instructions:</strong> {food_instruction}</p>
            {condition_str}
        </div>
        <p>Please open CareBridge AI to mark this dose as taken once completed.</p>
        """
    )
    text = f"Reminder for {patient_name}: Time to take {medicine_name} ({dose}) - {food_instruction}."
    return subject, html, text


def get_missed_medicine_email_template(patient_name: str, medicine_name: str, dose: str, scheduled_time: str, current_status: str = "Unconfirmed") -> tuple[str, str, str]:
    subject = f"Medicine Missed Alert – CareBridge ({patient_name})"
    html = _base_email_layout(
        title="⚠️ Missed Medication Alert",
        subtitle="Caregiver Attention Required",
        body_html=f"""
        <p>Hello,</p>
        <div class="alert-card">
            <h3 style="margin: 0 0 8px 0; color: #DC2626;">Missed Dose Flagged</h3>
            <p style="margin: 4px 0;"><strong>Patient:</strong> {patient_name}</p>
            <p style="margin: 4px 0;"><strong>Medicine:</strong> {medicine_name} ({dose})</p>
            <p style="margin: 4px 0;"><strong>Scheduled Window:</strong> {scheduled_time}</p>
            <p style="margin: 4px 0;"><strong>Status:</strong> {current_status}</p>
        </div>
        <p>Please check in with {patient_name} to verify if the medicine was taken or if assistance is needed.</p>
        """
    )
    text = f"ALERT: Missed medication for {patient_name}: {medicine_name} ({dose}) scheduled for {scheduled_time} was not marked taken."
    return subject, html, text


def get_appointment_confirmation_email_template(recipient_name: str, role: str, doctor_name: str, patient_name: str, date_str: str, time_slot: str, appt_type: str = "In-person", virtual_link: str = None) -> tuple[str, str, str]:
    subject = f"Appointment Booked – CareBridge ({date_str} at {time_slot})"
    link_html = f'<p><strong>Virtual Consultation Link:</strong> <a href="{virtual_link}">{virtual_link}</a></p>' if virtual_link else ""

    html = _base_email_layout(
        title="Appointment Booking Confirmed",
        subtitle="Medical consultation details",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <p>Your appointment with <strong>Dr. {doctor_name}</strong> has been successfully registered.</p>
        <div class="info-card">
            <p style="margin: 4px 0;"><strong>Patient Name:</strong> {patient_name}</p>
            <p style="margin: 4px 0;"><strong>Doctor:</strong> Dr. {doctor_name}</p>
            <p style="margin: 4px 0;"><strong>Date:</strong> {date_str}</p>
            <p style="margin: 4px 0;"><strong>Time Slot:</strong> {time_slot}</p>
            <p style="margin: 4px 0;"><strong>Type:</strong> {appt_type}</p>
            {link_html}
        </div>
        <p style="font-size: 13px; color: #64748B;">You can manage or reschedule this appointment directly in CareBridge AI.</p>
        """
    )
    text = f"Appointment Confirmed: {patient_name} with Dr. {doctor_name} on {date_str} at {time_slot} ({appt_type})."
    return subject, html, text


def get_appointment_rescheduled_email_template(recipient_name: str, doctor_name: str, patient_name: str, old_date_time: str, new_date_time: str, status_str: str = "Rescheduled") -> tuple[str, str, str]:
    subject = f"Appointment Rescheduled – Dr. {doctor_name}"
    html = _base_email_layout(
        title="Appointment Rescheduled",
        subtitle="Updated consultation schedule",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <p>The appointment for <strong>{patient_name}</strong> with <strong>Dr. {doctor_name}</strong> has been rescheduled.</p>
        <div class="info-card">
            <p style="margin: 4px 0; color: #DC2626;"><strong>Previous Time:</strong> <del>{old_date_time}</del></p>
            <p style="margin: 4px 0; color: #16A34A;"><strong>New Scheduled Time:</strong> {new_date_time}</p>
            <p style="margin: 4px 0;"><strong>Status:</strong> {status_str}</p>
        </div>
        """
    )
    text = f"Appointment Rescheduled for {patient_name} with Dr. {doctor_name}: Previous ({old_date_time}) -> New ({new_date_time})."
    return subject, html, text


def get_appointment_cancelled_email_template(recipient_name: str, doctor_name: str, patient_name: str, appt_date: str, appt_time: str, cancelled_by: str = "User") -> tuple[str, str, str]:
    subject = f"Appointment Cancelled – Dr. {doctor_name}"
    html = _base_email_layout(
        title="Appointment Cancelled",
        subtitle="Cancellation Notice",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <div class="alert-card">
            <p style="margin: 0;">The appointment for <strong>{patient_name}</strong> with <strong>Dr. {doctor_name}</strong> scheduled for <strong>{appt_date} at {appt_time}</strong> has been cancelled by {cancelled_by}.</p>
        </div>
        <p>You can schedule a new appointment anytime through CareBridge AI.</p>
        """
    )
    text = f"Appointment Cancelled: {patient_name} with Dr. {doctor_name} on {appt_date} at {appt_time} was cancelled by {cancelled_by}."
    return subject, html, text


def get_appointment_reminder_email_template(recipient_name: str, doctor_name: str, patient_name: str, appt_date: str, appt_time: str, appt_type: str = "In-person", virtual_link: str = None) -> tuple[str, str, str]:
    subject = f"Upcoming Appointment Reminder – Dr. {doctor_name} ({appt_time})"
    link_html = f'<p><strong>Join Virtual Meeting:</strong> <a href="{virtual_link}">{virtual_link}</a></p>' if virtual_link else ""

    html = _base_email_layout(
        title="Upcoming Appointment Reminder",
        subtitle="Reminder notice",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <p>This is a reminder for your upcoming medical consultation:</p>
        <div class="info-card">
            <p style="margin: 4px 0;"><strong>Doctor:</strong> Dr. {doctor_name}</p>
            <p style="margin: 4px 0;"><strong>Patient:</strong> {patient_name}</p>
            <p style="margin: 4px 0;"><strong>Date:</strong> {appt_date}</p>
            <p style="margin: 4px 0;"><strong>Time:</strong> {appt_time}</p>
            <p style="margin: 4px 0;"><strong>Type:</strong> {appt_type}</p>
            {link_html}
        </div>
        """
    )
    text = f"Reminder: Upcoming appointment for {patient_name} with Dr. {doctor_name} on {appt_date} at {appt_time}."
    return subject, html, text


def get_report_uploaded_email_template(recipient_name: str, patient_name: str, report_title: str, report_type: str, upload_date_str: str, uploaded_by: str) -> tuple[str, str, str]:
    subject = f"Medical Report Uploaded – CareBridge ({report_title})"
    html = _base_email_layout(
        title="New Medical Report Uploaded",
        subtitle="Diagnostic record logged",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <p>A new medical report has been uploaded to CareBridge AI.</p>
        <div class="info-card">
            <p style="margin: 4px 0;"><strong>Patient:</strong> {patient_name}</p>
            <p style="margin: 4px 0;"><strong>Report Title:</strong> {report_title}</p>
            <p style="margin: 4px 0;"><strong>Type:</strong> {report_type}</p>
            <p style="margin: 4px 0;"><strong>Uploaded By:</strong> {uploaded_by}</p>
            <p style="margin: 4px 0;"><strong>Date:</strong> {upload_date_str}</p>
        </div>
        <p>Log in to CareBridge AI to view full report documents and AI insights.</p>
        """
    )
    text = f"New Report Uploaded: {report_title} ({report_type}) uploaded for {patient_name} by {uploaded_by}."
    return subject, html, text


def get_report_summary_email_template(recipient_name: str, patient_name: str, report_title: str, overall_summary: str) -> tuple[str, str, str]:
    subject = f"AI Medical Report Summary Ready – CareBridge ({report_title})"
    html = _base_email_layout(
        title="AI Report Summary Ready 🤖",
        subtitle="Intelligent medical document analysis",
        body_html=f"""
        <p>Hello <strong>{recipient_name}</strong>,</p>
        <p>CareBridge AI has processed the medical report: <strong>{report_title}</strong> for {patient_name}.</p>
        <div class="info-card">
            <h4 style="margin: 0 0 6px 0; color: #7C3AED;">Executive Summary Overview:</h4>
            <p style="margin: 0; font-size: 14px;">{overall_summary}</p>
        </div>
        <div class="alert-card" style="background-color: #FFFBEB; border-left-color: #F59E0B; color: #92400E;">
            <p style="margin: 0; font-size: 12px; font-weight: bold;">Medical Disclaimer:</p>
            <p style="margin: 4px 0 0 0; font-size: 12px;">This AI summary is provided for informational guidance only and is not a medical diagnosis. Please review these results with your attending physician.</p>
        </div>
        """
    )
    text = f"AI Summary Ready for {report_title} ({patient_name}): {overall_summary}"
    return subject, html, text


def get_doctor_appointment_request_email_template(doctor_name: str, patient_name: str, appt_date: str, time_slot: str, appt_type: str = "In-person") -> tuple[str, str, str]:
    subject = f"New Patient Appointment Request – {patient_name}"
    html = _base_email_layout(
        title="New Appointment Request",
        subtitle="Doctor Dashboard Notification",
        body_html=f"""
        <p>Hello <strong>Dr. {doctor_name}</strong>,</p>
        <p>A new patient consultation has been requested on CareBridge AI.</p>
        <div class="info-card">
            <p style="margin: 4px 0;"><strong>Patient:</strong> {patient_name}</p>
            <p style="margin: 4px 0;"><strong>Date:</strong> {appt_date}</p>
            <p style="margin: 4px 0;"><strong>Time Slot:</strong> {time_slot}</p>
            <p style="margin: 4px 0;"><strong>Type:</strong> {appt_type}</p>
        </div>
        <p>Please log in to your Doctor Portal to accept or manage this appointment.</p>
        """
    )
    text = f"New Appointment Request for Dr. {doctor_name}: Patient {patient_name} on {appt_date} at {time_slot}."
    return subject, html, text


def get_doctor_approval_email_template(doctor_name: str, is_approved: bool = True, reason: str = None) -> tuple[str, str, str]:
    if is_approved:
        subject = "Congratulations! Your Doctor Account is Verified – CareBridge AI"
        html = _base_email_layout(
            title="Doctor Account Approved ✓",
            subtitle="Verification Status Notice",
            body_html=f"""
            <p>Hello <strong>Dr. {doctor_name}</strong>,</p>
            <p>We are pleased to inform you that your doctor credentials have been verified and approved by the CareBridge Administration Team.</p>
            <div class="info-card">
                <p style="margin: 0; color: #16A34A; font-weight: bold;">Status: Active & Verified</p>
            </div>
            <p>You can now log in, receive patient consultation requests, and set your consultation availability.</p>
            """
        )
        text = f"Dr. {doctor_name}, your CareBridge Doctor Account is verified and approved!"
    else:
        subject = "CareBridge AI - Doctor Registration Update"
        reason_str = f"<p><strong>Reason:</strong> {reason}</p>" if reason else ""
        html = _base_email_layout(
            title="Doctor Application Status",
            subtitle="Verification Status Notice",
            body_html=f"""
            <p>Hello <strong>Dr. {doctor_name}</strong>,</p>
            <p>Thank you for submitting your doctor application to CareBridge AI.</p>
            <div class="alert-card">
                <p style="margin: 0;"><strong>Status:</strong> Application Not Approved</p>
                {reason_str}
            </div>
            <p>If you believe this is an error or wish to update your credentials, please contact support.</p>
            """
        )
        text = f"Dr. {doctor_name}, your CareBridge Doctor Application was not approved."
    return subject, html, text


def get_admin_alert_email_template(admin_name: str, alert_title: str, alert_details: str, event_time_str: str) -> tuple[str, str, str]:
    subject = f"CareBridge Admin Alert: {alert_title}"
    html = _base_email_layout(
        title=f"Admin Alert: {alert_title}",
        subtitle="System Event Audit Log",
        body_html=f"""
        <p>Hello <strong>{admin_name}</strong>,</p>
        <div class="info-card">
            <p style="margin: 4px 0;"><strong>Event:</strong> {alert_title}</p>
            <p style="margin: 4px 0;"><strong>Timestamp:</strong> {event_time_str}</p>
            <p style="margin: 8px 0 0 0;"><strong>Details:</strong> {alert_details}</p>
        </div>
        """
    )
    text = f"Admin Alert ({alert_title}) at {event_time_str}: {alert_details}"
    return subject, html, text
