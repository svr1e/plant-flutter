from datetime import date, timedelta
from typing import List, Optional
from plant_care_models import PlantCare, PlantCareResponse, PlantCareCreate, PlantCareUpdate

class PlantCareService:
    """Service for plant care scheduling and calculations"""
    
    @staticmethod
    def calculate_next_date(last_date: Optional[date], frequency_days: int) -> Optional[date]:
        """Calculate next care date based on last date and frequency"""
        if not last_date:
            return None
        return last_date + timedelta(days=frequency_days)
    
    @staticmethod
    def calculate_days_until(target_date: Optional[date]) -> Optional[int]:
        """Calculate days until target date from today"""
        if not target_date:
            return None
        today = date.today()
        delta = target_date - today
        return delta.days
    
    @staticmethod
    def is_due(days_until: Optional[int]) -> bool:
        """Check if care is due (days_until <= 0)"""
        return days_until is not None and days_until <= 0
    
    @staticmethod
    def create_response(plant_care: dict) -> PlantCareResponse:
        """Create response with calculated dates and status"""
        # Convert dict to PlantCare model
        care_data = PlantCare(**plant_care)
        
        # Calculate next dates
        next_watering = PlantCareService.calculate_next_date(
            care_data.last_watered, care_data.watering_frequency_days
        )
        next_fertilizing = PlantCareService.calculate_next_date(
            care_data.last_fertilized, care_data.fertilizing_frequency_days
        )
        next_pruning = PlantCareService.calculate_next_date(
            care_data.last_pruned, care_data.pruning_frequency_days
        )
        next_repotting = PlantCareService.calculate_next_date(
            care_data.last_repotted, care_data.repotting_frequency_days
        )
        
        # Calculate days until
        days_until_watering = PlantCareService.calculate_days_until(next_watering)
        days_until_fertilizing = PlantCareService.calculate_days_until(next_fertilizing)
        days_until_pruning = PlantCareService.calculate_days_until(next_pruning)
        days_until_repotting = PlantCareService.calculate_days_until(next_repotting)
        
        # Create response
        response = PlantCareResponse(
            id=str(plant_care['_id']),
            plant_id=care_data.plant_id,
            plant_name=care_data.plant_name,
            watering_frequency_days=care_data.watering_frequency_days,
            fertilizing_frequency_days=care_data.fertilizing_frequency_days,
            pruning_frequency_days=care_data.pruning_frequency_days,
            repotting_frequency_days=care_data.repotting_frequency_days,
            last_watered=care_data.last_watered,
            last_fertilized=care_data.last_fertilized,
            last_pruned=care_data.last_pruned,
            last_repotted=care_data.last_repotted,
            notes=care_data.notes,
            created_at=care_data.created_at,
            updated_at=care_data.updated_at,
            # Calculated fields
            next_watering=next_watering,
            next_fertilizing=next_fertilizing,
            next_pruning=next_pruning,
            next_repotting=next_repotting,
            days_until_watering=days_until_watering,
            days_until_fertilizing=days_until_fertilizing,
            days_until_pruning=days_until_pruning,
            days_until_repotting=days_until_repotting,
            is_watering_due=PlantCareService.is_due(days_until_watering),
            is_fertilizing_due=PlantCareService.is_due(days_until_fertilizing),
            is_pruning_due=PlantCareService.is_due(days_until_pruning),
            is_repotting_due=PlantCareService.is_due(days_until_repotting),
        )
        
        return response
    
    @staticmethod
    def get_today_tasks(plant_cares: List[dict]) -> List[PlantCareResponse]:
        """Get all plants with due tasks for today"""
        today_tasks = []
        
        for plant_care in plant_cares:
            response = PlantCareService.create_response(plant_care)
            
            # Check if any tasks are due today
            if (response.is_watering_due or 
                response.is_fertilizing_due or 
                response.is_pruning_due or 
                response.is_repotting_due):
                today_tasks.append(response)
        
        return today_tasks
    
    @staticmethod
    def mark_action_completed(plant_care: dict, action_type: str, completed_date: date) -> PlantCareResponse:
        """Mark a care action as completed"""
        # Update the appropriate last action date
        if action_type == "watering":
            plant_care['last_watered'] = completed_date
        elif action_type == "fertilizing":
            plant_care['last_fertilized'] = completed_date
        elif action_type == "pruning":
            plant_care['last_pruned'] = completed_date
        elif action_type == "repotting":
            plant_care['last_repotted'] = completed_date
        
        # Update timestamp
        plant_care['updated_at'] = datetime.utcnow()
        
        return PlantCareService.create_response(plant_care)