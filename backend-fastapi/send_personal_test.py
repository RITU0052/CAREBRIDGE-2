import sys
import os

sys.path.append(os.path.abspath("c:/Users/neera/Downloads/carebridge-ai-mvp 2/backend-fastapi"))

import app.database
from app import email_service

personal_emails = ["neerajyash1001@gmail.com", "hpandat081@gmail.com", "ritu133081@gmail.com"]

print("=========================================================")
print("SENDING DIRECT TEST EMAILS TO YOUR PERSONAL GMAIL INBOXES")
print("=========================================================\n")

for email in personal_emails:
    print(f"Sending email directly to personal inbox: {email} ...")
    email_service.send_email(
        to_email=email,
        subject="CareBridge AI - Personal Inbox Notification Test",
        body_html=f"""
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
            <h2 style="color: #6C5CE7;">CareBridge AI Personal Delivery Confirmation</h2>
            <p>Hello,</p>
            <p>This email was dispatched directly to your personal email inbox: <strong>{email}</strong>!</p>
            <p>Your CareBridge notifications, medicine reminders, password reset codes, and appointment updates will arrive at this email address.</p>
            <hr style="border: 0; border-top: 1px solid #eee;" />
            <p style="color: #777; font-size: 12px;">© CareBridge AI Healthcare Platform</p>
        </div>
        """,
        body_text=f"CareBridge AI Personal Delivery Confirmation for {email}",
        notification_type="general",
        sync=True
    )
    print(f"   [OK] Dispatched via SMTP to {email}\n")

print("All personal test emails dispatched successfully!")
