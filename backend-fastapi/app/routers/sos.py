from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import re
import os

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user

router = APIRouter()

def validate_phone(phone_str: str):
    cleaned = re.sub(r'[\s\-\(\)\+]', '', phone_str or '')
    if not cleaned.isdigit() or len(cleaned) < 7 or len(cleaned) > 15:
        raise HTTPException(status_code=400, detail="Invalid phone number format. Please provide a valid 7 to 15 digit phone number.")

@router.get("/contacts", response_model=List[schemas.EmergencyContactOut])
def get_emergency_contacts(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    parent_id = current_user.id
    if current_user.role == "child" and current_user.linked_user_id:
        parent_id = current_user.linked_user_id

    contacts = db.query(models.EmergencyContact).filter(models.EmergencyContact.parent_id == parent_id).all()
    return contacts

@router.post("/contacts", response_model=schemas.EmergencyContactOut)
def add_emergency_contact(
    contact_in: schemas.EmergencyContactCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role != "parent" and current_user.role != "child":
        raise HTTPException(status_code=403, detail="Not authorized to manage emergency contacts")

    validate_phone(contact_in.phone)

    parent_id = current_user.id
    if current_user.role == "child":
        if not current_user.linked_user_id:
            raise HTTPException(status_code=400, detail="Child is not linked to a parent account")
        parent_id = current_user.linked_user_id

    count = db.query(models.EmergencyContact).filter(models.EmergencyContact.parent_id == parent_id).count()
    if count >= 5:
        raise HTTPException(status_code=400, detail="Maximum limit of 5 emergency contacts reached. Please remove or edit an existing contact.")

    new_contact = models.EmergencyContact(
        parent_id=parent_id,
        name=contact_in.name,
        phone=contact_in.phone,
        relationship=contact_in.relationship or "Family",
        email=contact_in.email,
        is_primary=contact_in.is_primary
    )
    db.add(new_contact)
    db.commit()
    db.refresh(new_contact)
    return new_contact

@router.put("/contacts/{contact_id}", response_model=schemas.EmergencyContactOut)
def update_emergency_contact(
    contact_id: str,
    contact_in: schemas.EmergencyContactCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(models.EmergencyContact).filter(models.EmergencyContact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")

    validate_phone(contact_in.phone)
    contact.name = contact_in.name
    contact.phone = contact_in.phone
    contact.relationship = contact_in.relationship or contact.relationship
    contact.email = contact_in.email
    contact.is_primary = contact_in.is_primary

    db.commit()
    db.refresh(contact)
    return contact

@router.delete("/contacts/{contact_id}")
def delete_emergency_contact(
    contact_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(models.EmergencyContact).filter(models.EmergencyContact.id == contact_id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Emergency contact not found")

    db.delete(contact)
    db.commit()
    return {"message": "Emergency contact deleted successfully"}

# --- Doctor Contact Endpoints ---

@router.get("/doctor-contact", response_model=List[schemas.DoctorContactOut])
def get_doctor_contacts(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    parent_id = current_user.id
    if current_user.role == "child" and current_user.linked_user_id:
        parent_id = current_user.linked_user_id

    return db.query(models.DoctorContact).filter(models.DoctorContact.parent_id == parent_id).all()

@router.post("/doctor-contact", response_model=schemas.DoctorContactOut)
def add_doctor_contact(
    dc_in: schemas.DoctorContactCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    validate_phone(dc_in.doctor_phone)
    parent_id = current_user.id
    if current_user.role == "child" and current_user.linked_user_id:
        parent_id = current_user.linked_user_id

    new_dc = models.DoctorContact(
        parent_id=parent_id,
        doctor_name=dc_in.doctor_name,
        doctor_phone=dc_in.doctor_phone,
        doctor_email=dc_in.doctor_email
    )
    db.add(new_dc)
    db.commit()
    db.refresh(new_dc)
    return new_dc

@router.put("/doctor-contact/{id}", response_model=schemas.DoctorContactOut)
def update_doctor_contact(
    id: str,
    dc_in: schemas.DoctorContactCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    dc = db.query(models.DoctorContact).filter(models.DoctorContact.id == id).first()
    if not dc:
        raise HTTPException(status_code=404, detail="Doctor contact not found")

    validate_phone(dc_in.doctor_phone)
    dc.doctor_name = dc_in.doctor_name
    dc.doctor_phone = dc_in.doctor_phone
    dc.doctor_email = dc_in.doctor_email

    db.commit()
    db.refresh(dc)
    return dc

@router.delete("/doctor-contact/{id}")
def delete_doctor_contact(
    id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    dc = db.query(models.DoctorContact).filter(models.DoctorContact.id == id).first()
    if not dc:
        raise HTTPException(status_code=404, detail="Doctor contact not found")

    db.delete(dc)
    db.commit()
    return {"message": "Doctor contact deleted"}

# --- Emergency Message AI Assistant ---

@router.post("/ai-assistant", response_model=schemas.EmergencyAIAssistantResponse)
def emergency_ai_assistant(
    req: schemas.EmergencyAIAssistantRequest,
    current_user: models.User = Depends(get_current_user)
):
    prompt_text = req.prompt.strip()
    prompt_lower = prompt_text.lower()
    lang = (req.language or "hi").lower()

    # Check for severe symptoms
    severe_keywords = ["chest pain", "breathing", "heart attack", "unconscious", "stroke", "bleeding", "dizzy", "chakkar", "saans", "seene me dard", "faint", "dard", "bukhar", "chot"]
    is_severe = any(k in prompt_lower for k in severe_keywords)

    is_hindi_req = (lang in ["hi", "hindi", "hinglish"]) or any('\u0900' <= char <= '\u097f' for char in prompt_text) or any(k in prompt_lower for k in ["chakkar", "saans", "dard", "mujhe", "hai", "raha", "madad", "bache", "doctor", "karo", "bukhar"])

    gemini_key = os.environ.get("GEMINI_API_KEY", "")
    if gemini_key:
        try:
            import google.generativeai as genai
            genai.configure(api_key=gemini_key)
            model = genai.GenerativeModel("gemini-1.5-flash")
            
            target_lang_instruction = "IMPORTANT: Respond in simple, reassuring HINDI (Devanagari script) so elderly parents who cannot speak English can easily read it." if is_hindi_req else "Respond in clear English."

            ai_prompt = f"""
            You are an Emergency Assistant for an elderly health application called CareBridge.
            The user (an elderly parent or relative) sent this emergency query:
            "{prompt_text}"

            {target_lang_instruction}

            Tasks:
            1. Formulate a clear, urgent SMS/WhatsApp message to send to emergency contacts or doctors (suggested_message).
            2. Assess symptom severity: 'high', 'moderate', or 'low' (severity).
            3. Provide immediate, simple safety advice for elderly parents (advice).

            Respond ONLY in valid JSON format:
            {{
                "suggested_message": "string",
                "severity": "high/moderate/low",
                "advice": "string"
            }}
            """
            res = model.generate_content(ai_prompt)
            clean_json = res.text.strip()
            if "```json" in clean_json:
                clean_json = clean_json.split("```json")[1].split("```")[0].strip()
            import json
            parsed = json.loads(clean_json)
            return schemas.EmergencyAIAssistantResponse(
                suggested_message=parsed.get("suggested_message", f"आपातकालीन सहायता (Emergency): {prompt_text}"),
                severity=parsed.get("severity", "high" if is_severe else "moderate"),
                advice=parsed.get("advice", "तुरंत 108 / 102 पर कॉल करें या लाल SOS बटन दबाएं। (Call 108/102 immediately or press Red SOS Button).")
            )
        except Exception as e:
            print(f"Gemini Emergency AI Assistant error: {e}")

    # Fallback multilingual AI rules engine (Hindi / Hinglish / English)
    if is_hindi_req:
        if "chakkar" in prompt_lower or "dizzy" in prompt_lower or "चक्कर" in prompt_text:
            msg = "आपातकालीन संदेश: मुझे बहुत तेज़ चक्कर आ रहे हैं और घबराहट हो रही है। कृपया मुझसे तुरंत संपर्क करें या सहायता भेजें।"
            adv = "सुरक्षित स्थान पर आराम से बैठ जाएं या लेट जाएं। शांत रहें, थोड़ा पानी पिएं। यदि चक्कर आना बंद न हो, तो तुरंत एम्बुलेंस 108 पर कॉल करें।"
        elif "chest" in prompt_lower or "dard" in prompt_lower or "pain" in prompt_lower or "दर्द" in prompt_text or "सीने" in prompt_text:
            msg = "🚨 अति-आपातकालीन संदेश: मेरे सीने में दर्द/असुविधा हो रही है। कृपया तुरंत चिकित्सा सहायता भेजें।"
            adv = "⚠️ सीने में दर्द की चेतावनी: कृपया बिना देर किए आपातकालीन एम्बुलेंस (108 / 102) को कॉल करें और शांत बैठें।"
        elif "saans" in prompt_lower or "breath" in prompt_lower or "सांस" in prompt_text:
            msg = "🚨 आपातकालीन संदेश: मुझे सांस लेने में तकलीफ हो रही है। कृपया तुरंत डॉक्टर या सहायता भेजें।"
            adv = "⚠️ हवादार जगह पर सीधे बैठ जाएं और कपड़े ढीले करें। तुरंत 108 आपातकालीन सेवा को कॉल करें।"
        elif "doctor" in prompt_lower or "hospital" in prompt_lower or "अस्पताल" in prompt_text:
            msg = "आपातकालीन सूचना: मुझे निकटतम डॉक्टर या अस्पताल से तत्काल परामर्श की आवश्यकता है।"
            adv = "ऐप में दिए गए पास के अस्पताल अनुभाग देखें या अपने डॉक्टर संपर्क को डायरेक्ट कॉल करें।"
        else:
            msg = f"आपातकालीन संदेश: मुझे तुरंत चिकित्सा सहायता की आवश्यकता है। विवरण: {prompt_text}"
            adv = "यदि आप अस्वस्थ या असुरक्षित महसूस कर रहे हैं, तो तुरंत लाल SOS बटन दबाएं या आपातकालीन नंबर 108 पर कॉल करें।"
    else:
        if "chakkar" in prompt_lower or "dizzy" in prompt_lower:
            msg = "Emergency Alert: I am feeling very dizzy and lightheaded. Please contact me or send assistance immediately."
            adv = "Sit down safely to avoid falling. If dizziness persists or is accompanied by chest pain, seek immediate emergency care (Call 108/102)."
        elif "chest" in prompt_lower or "dard" in prompt_lower or "pain" in prompt_lower:
            msg = "URGENT EMERGENCY: I am experiencing chest discomfort. Please call me or send medical help right away."
            adv = "⚠️ Severe Symptom Warning: Please contact local emergency medical services immediately (108 / 102 / 911)."
        elif "saans" in prompt_lower or "breath" in prompt_lower:
            msg = "URGENT: I am having difficulty breathing. Please send medical support immediately."
            adv = "⚠️ Severe Symptom Warning: Sit upright in an airy place and contact emergency medical services right away."
        elif "doctor" in prompt_lower or "hospital" in prompt_lower:
            msg = "Emergency Notice: I need urgent consultation with my doctor or nearest hospital. Please assist me in connecting."
            adv = "Use the Nearby Hospitals section or call your saved Doctor Contact directly."
        else:
            msg = f"EMERGENCY: I need urgent medical assistance. Requesting immediate contact. Detail: {prompt_text}"
            adv = "If you feel unsafe or in distress, please press the Red SOS Button to alert all emergency contacts immediately."

    return schemas.EmergencyAIAssistantResponse(
        suggested_message=msg,
        severity="high" if is_severe else "moderate",
        advice=adv
    )

# --- SOS Triggers & Active Alerts ---

@router.post("/trigger", response_model=schemas.SOSAlertOut)
def trigger_sos(
    sos_in: schemas.SOSTrigger, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    if current_user.role != "parent":
        raise HTTPException(status_code=403, detail="Only parents can trigger SOS")
        
    new_alert = models.SOSAlert(
        parent_id=current_user.id,
        location_lat=sos_in.location_lat or "37.7749",
        location_lng=sos_in.location_lng or "-122.4194",
        status="active"
    )
    
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    
    if current_user.linked_user_id:
        notif = models.AppNotification(
            user_id=current_user.linked_user_id,
            title="🚨 EMERGENCY SOS ALERT!",
            body=f"{current_user.name} has triggered an emergency SOS alert at {new_alert.timestamp.strftime('%I:%M %p')}.",
            type="emergency"
        )
        db.add(notif)
        db.commit()

    return {
        "id": new_alert.id,
        "parent_id": new_alert.parent_id,
        "location_lat": new_alert.location_lat,
        "location_lng": new_alert.location_lng,
        "status": new_alert.status,
        "timestamp": new_alert.timestamp,
        "parent_name": current_user.name
    }

@router.get("/active", response_model=List[schemas.SOSAlertOut])
def get_active_sos(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    results = []
    if current_user.role == "parent":
        alerts = db.query(models.SOSAlert).filter(
            models.SOSAlert.parent_id == current_user.id,
            models.SOSAlert.status == "active"
        ).all()
        for a in alerts:
            results.append({
                "id": a.id,
                "parent_id": a.parent_id,
                "location_lat": a.location_lat,
                "location_lng": a.location_lng,
                "status": a.status,
                "timestamp": a.timestamp,
                "parent_name": current_user.name
            })
        return results
    elif current_user.role == "child":
        parents = db.query(models.User).filter(
            models.User.linked_user_id == current_user.id,
            models.User.role == "parent"
        ).all()
        
        for p in parents:
            alerts = db.query(models.SOSAlert).filter(
                models.SOSAlert.parent_id == p.id,
                models.SOSAlert.status == "active"
            ).all()
            for a in alerts:
                results.append({
                    "id": a.id,
                    "parent_id": a.parent_id,
                    "location_lat": a.location_lat,
                    "location_lng": a.location_lng,
                    "status": a.status,
                    "timestamp": a.timestamp,
                    "parent_name": p.name
                })
        return results
    elif current_user.role == "admin":
        alerts = db.query(models.SOSAlert).filter(models.SOSAlert.status == "active").all()
        for a in alerts:
            parent = db.query(models.User).filter(models.User.id == a.parent_id).first()
            results.append({
                "id": a.id,
                "parent_id": a.parent_id,
                "location_lat": a.location_lat,
                "location_lng": a.location_lng,
                "status": a.status,
                "timestamp": a.timestamp,
                "parent_name": parent.name if parent else "Parent"
            })
        return results
    return []

@router.put("/{alert_id}/resolve")
def resolve_sos(
    alert_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    alert = db.query(models.SOSAlert).filter(models.SOSAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="SOS alert not found")
        
    alert.status = "resolved"
    db.commit()
    return {"message": "SOS alert resolved successfully", "alert_id": alert_id}
