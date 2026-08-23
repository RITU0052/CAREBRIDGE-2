from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user

router = APIRouter()

@router.post("/metrics", response_model=schemas.HealthMetricOut)
def add_health_metric(
    metric_in: schemas.HealthMetricCreate, 
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    parent_id = current_user.id
    if current_user.role == "child" and current_user.linked_user_id:
        parent_id = current_user.linked_user_id

    new_metric = models.HealthMetric(
        parent_id=parent_id,
        blood_pressure_sys=metric_in.blood_pressure_sys,
        blood_pressure_dia=metric_in.blood_pressure_dia,
        heart_rate=metric_in.heart_rate,
        water_intake_l=metric_in.water_intake_l,
        water_target_l=metric_in.water_target_l or 2.5,
        steps_target=metric_in.steps_target or 8000,
        steps_actual=metric_in.steps_actual,
        heart_rate_target=metric_in.heart_rate_target or "60-100 BPM",
        data_source=metric_in.data_source or "manual",
        notes=metric_in.notes
    )
    
    db.add(new_metric)
    db.commit()
    db.refresh(new_metric)
    return new_metric

@router.get("/metrics/{parent_id}", response_model=List[schemas.HealthMetricOut])
def get_health_metrics(
    parent_id: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    metrics = db.query(models.HealthMetric).filter(
        models.HealthMetric.parent_id == parent_id
    ).order_by(models.HealthMetric.date.desc()).limit(30).all()
    
    return metrics
