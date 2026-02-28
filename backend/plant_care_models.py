from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional, List
from bson import ObjectId

class PlantCare(BaseModel):
    """Plant care schedule model"""
    plant_id: str
    plant_name: str
    watering_frequency_days: int = Field(default=7, ge=1, le=365)
    fertilizing_frequency_days: int = Field(default=30, ge=1, le=365)
    pruning_frequency_days: int = Field(default=90, ge=1, le=365)
    repotting_frequency_days: int = Field(default=365, ge=1, le=1460)
    
    # Last action dates
    last_watered: Optional[date] = None
    last_fertilized: Optional[date] = None
    last_pruned: Optional[date] = None
    last_repotted: Optional[date] = None
    
    # Additional info
    notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class PlantCareResponse(PlantCare):
    """Response model with calculated next dates"""
    id: str
    next_watering: Optional[date] = None
    next_fertilizing: Optional[date] = None
    next_pruning: Optional[date] = None
    next_repotting: Optional[date] = None
    days_until_watering: Optional[int] = None
    days_until_fertilizing: Optional[int] = None
    days_until_pruning: Optional[int] = None
    days_until_repotting: Optional[int] = None
    is_watering_due: bool = False
    is_fertilizing_due: bool = False
    is_pruning_due: bool = False
    is_repotting_due: bool = False

class PlantCareCreate(BaseModel):
    """Create plant care schedule"""
    plant_id: str
    plant_name: str
    watering_frequency_days: int = Field(default=7, ge=1, le=365)
    fertilizing_frequency_days: int = Field(default=30, ge=1, le=365)
    pruning_frequency_days: int = Field(default=90, ge=1, le=365)
    repotting_frequency_days: int = Field(default=365, ge=1, le=1460)
    last_watered: Optional[date] = None
    last_fertilized: Optional[date] = None
    last_pruned: Optional[date] = None
    last_repotted: Optional[date] = None
    notes: Optional[str] = None

class PlantCareUpdate(BaseModel):
    """Update plant care schedule"""
    plant_name: Optional[str] = None
    watering_frequency_days: Optional[int] = Field(None, ge=1, le=365)
    fertilizing_frequency_days: Optional[int] = Field(None, ge=1, le=365)
    pruning_frequency_days: Optional[int] = Field(None, ge=1, le=365)
    repotting_frequency_days: Optional[int] = Field(None, ge=1, le=1460)
    last_watered: Optional[date] = None
    last_fertilized: Optional[date] = None
    last_pruned: Optional[date] = None
    last_repotted: Optional[date] = None
    notes: Optional[str] = None

class ActionRequest(BaseModel):
    """Request to mark an action as completed"""
    action_type: str = Field(..., pattern="^(watering|fertilizing|pruning|repotting)$")
    completed_date: Optional[date] = Field(default_factory=date.today)

class TodayTasksResponse(BaseModel):
    """Today's care tasks"""
    tasks: List[PlantCareResponse]
    total_due: int
    message: str

class PlantCareListResponse(BaseModel):
    """List of all plant care schedules"""
    plants: List[PlantCareResponse]
    total: int