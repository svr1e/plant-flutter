class PlantCare {
  final String id;
  final String plantId;
  final String plantName;
  final int wateringFrequencyDays;
  final int fertilizingFrequencyDays;
  final int pruningFrequencyDays;
  final int repottingFrequencyDays;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final DateTime? lastPruned;
  final DateTime? lastRepotted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Calculated fields
  final DateTime? nextWatering;
  final DateTime? nextFertilizing;
  final DateTime? nextPruning;
  final DateTime? nextRepotting;
  final int? daysUntilWatering;
  final int? daysUntilFertilizing;
  final int? daysUntilPruning;
  final int? daysUntilRepotting;
  final bool isWateringDue;
  final bool isFertilizingDue;
  final bool isPruningDue;
  final bool isRepottingDue;

  PlantCare({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.wateringFrequencyDays,
    required this.fertilizingFrequencyDays,
    required this.pruningFrequencyDays,
    required this.repottingFrequencyDays,
    this.lastWatered,
    this.lastFertilized,
    this.lastPruned,
    this.lastRepotted,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.nextWatering,
    this.nextFertilizing,
    this.nextPruning,
    this.nextRepotting,
    this.daysUntilWatering,
    this.daysUntilFertilizing,
    this.daysUntilPruning,
    this.daysUntilRepotting,
    this.isWateringDue = false,
    this.isFertilizingDue = false,
    this.isPruningDue = false,
    this.isRepottingDue = false,
  });

  factory PlantCare.fromJson(Map<String, dynamic> json) {
    return PlantCare(
      id: json['id'] ?? '',
      plantId: json['plant_id'] ?? '',
      plantName: json['plant_name'] ?? '',
      wateringFrequencyDays: json['watering_frequency_days'] ?? 7,
      fertilizingFrequencyDays: json['fertilizing_frequency_days'] ?? 30,
      pruningFrequencyDays: json['pruning_frequency_days'] ?? 90,
      repottingFrequencyDays: json['repotting_frequency_days'] ?? 365,
      lastWatered: json['last_watered'] != null 
          ? DateTime.parse(json['last_watered']) 
          : null,
      lastFertilized: json['last_fertilized'] != null 
          ? DateTime.parse(json['last_fertilized']) 
          : null,
      lastPruned: json['last_pruned'] != null 
          ? DateTime.parse(json['last_pruned']) 
          : null,
      lastRepotted: json['last_repotted'] != null 
          ? DateTime.parse(json['last_repotted']) 
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      nextWatering: json['next_watering'] != null 
          ? DateTime.parse(json['next_watering']) 
          : null,
      nextFertilizing: json['next_fertilizing'] != null 
          ? DateTime.parse(json['next_fertilizing']) 
          : null,
      nextPruning: json['next_pruning'] != null 
          ? DateTime.parse(json['next_pruning']) 
          : null,
      nextRepotting: json['next_repotting'] != null 
          ? DateTime.parse(json['next_repotting']) 
          : null,
      daysUntilWatering: json['days_until_watering'],
      daysUntilFertilizing: json['days_until_fertilizing'],
      daysUntilPruning: json['days_until_pruning'],
      daysUntilRepotting: json['days_until_repotting'],
      isWateringDue: json['is_watering_due'] ?? false,
      isFertilizingDue: json['is_fertilizing_due'] ?? false,
      isPruningDue: json['is_pruning_due'] ?? false,
      isRepottingDue: json['is_repotting_due'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_id': plantId,
      'plant_name': plantName,
      'watering_frequency_days': wateringFrequencyDays,
      'fertilizing_frequency_days': fertilizingFrequencyDays,
      'pruning_frequency_days': pruningFrequencyDays,
      'repotting_frequency_days': repottingFrequencyDays,
      'last_watered': lastWatered?.toIso8601String(),
      'last_fertilized': lastFertilized?.toIso8601String(),
      'last_pruned': lastPruned?.toIso8601String(),
      'last_repotted': lastRepotted?.toIso8601String(),
      'notes': notes,
    };
  }

  // Helper methods
  bool get hasAnyTaskDue {
    return isWateringDue || isFertilizingDue || isPruningDue || isRepottingDue;
  }

  List<String> get dueTasks {
    final tasks = <String>[];
    if (isWateringDue) tasks.add('Watering');
    if (isFertilizingDue) tasks.add('Fertilizing');
    if (isPruningDue) tasks.add('Pruning');
    if (isRepottingDue) tasks.add('Repotting');
    return tasks;
  }

  String get nextTask {
    if (hasAnyTaskDue) {
      return dueTasks.first;
    }
    
    // Find the soonest task
    final tasks = [
      if (daysUntilWatering != null) {'task': 'Watering', 'days': daysUntilWatering!},
      if (daysUntilFertilizing != null) {'task': 'Fertilizing', 'days': daysUntilFertilizing!},
      if (daysUntilPruning != null) {'task': 'Pruning', 'days': daysUntilPruning!},
      if (daysUntilRepotting != null) {'task': 'Repotting', 'days': daysUntilRepotting!},
    ];
    
    if (tasks.isEmpty) return 'No tasks scheduled';
    
    tasks.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    final nextTask = tasks.first;
    
    if (nextTask['days'] as int <= 0) {
      return '${nextTask['task']} - Due now';
    } else if (nextTask['days'] as int == 1) {
      return '${nextTask['task']} - Tomorrow';
    } else {
      return '${nextTask['task']} - In ${nextTask['days']} days';
    }
  }
}

class TodayTasksResponse {
  final List<PlantCare> tasks;
  final int totalDue;
  final String message;

  TodayTasksResponse({
    required this.tasks,
    required this.totalDue,
    required this.message,
  });

  factory TodayTasksResponse.fromJson(Map<String, dynamic> json) {
    return TodayTasksResponse(
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((task) => PlantCare.fromJson(task))
              .toList() ?? [],
      totalDue: json['total_due'] ?? 0,
      message: json['message'] ?? '',
    );
  }
}

class PlantCareListResponse {
  final List<PlantCare> plants;
  final int total;

  PlantCareListResponse({
    required this.plants,
    required this.total,
  });

  factory PlantCareListResponse.fromJson(Map<String, dynamic> json) {
    return PlantCareListResponse(
      plants: (json['plants'] as List<dynamic>?)
              ?.map((plant) => PlantCare.fromJson(plant))
              .toList() ?? [],
      total: json['total'] ?? 0,
    );
  }
}

class PlantCareCreate {
  final String plantId;
  final String plantName;
  final int wateringFrequencyDays;
  final int fertilizingFrequencyDays;
  final int pruningFrequencyDays;
  final int repottingFrequencyDays;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final DateTime? lastPruned;
  final DateTime? lastRepotted;
  final String? notes;

  PlantCareCreate({
    required this.plantId,
    required this.plantName,
    this.wateringFrequencyDays = 7,
    this.fertilizingFrequencyDays = 30,
    this.pruningFrequencyDays = 90,
    this.repottingFrequencyDays = 365,
    this.lastWatered,
    this.lastFertilized,
    this.lastPruned,
    this.lastRepotted,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'plant_id': plantId,
      'plant_name': plantName,
      'watering_frequency_days': wateringFrequencyDays,
      'fertilizing_frequency_days': fertilizingFrequencyDays,
      'pruning_frequency_days': pruningFrequencyDays,
      'repotting_frequency_days': repottingFrequencyDays,
      'last_watered': lastWatered?.toIso8601String(),
      'last_fertilized': lastFertilized?.toIso8601String(),
      'last_pruned': lastPruned?.toIso8601String(),
      'last_repotted': lastRepotted?.toIso8601String(),
      'notes': notes,
    };
  }
}

class ActionRequest {
  final String actionType;
  final DateTime completedDate;

  ActionRequest({
    required this.actionType,
    DateTime? completedDate,
  }) : completedDate = completedDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'action_type': actionType,
      'completed_date': completedDate.toIso8601String().split('T')[0],
    };
  }
}

class PlantCareUpdate {
  final String? plantName;
  final int? wateringFrequencyDays;
  final int? fertilizingFrequencyDays;
  final int? pruningFrequencyDays;
  final int? repottingFrequencyDays;
  final DateTime? lastWatered;
  final DateTime? lastFertilized;
  final DateTime? lastPruned;
  final DateTime? lastRepotted;
  final String? notes;

  PlantCareUpdate({
    this.plantName,
    this.wateringFrequencyDays,
    this.fertilizingFrequencyDays,
    this.pruningFrequencyDays,
    this.repottingFrequencyDays,
    this.lastWatered,
    this.lastFertilized,
    this.lastPruned,
    this.lastRepotted,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (plantName != null) data['plant_name'] = plantName;
    if (wateringFrequencyDays != null) data['watering_frequency_days'] = wateringFrequencyDays;
    if (fertilizingFrequencyDays != null) data['fertilizing_frequency_days'] = fertilizingFrequencyDays;
    if (pruningFrequencyDays != null) data['pruning_frequency_days'] = pruningFrequencyDays;
    if (repottingFrequencyDays != null) data['repotting_frequency_days'] = repottingFrequencyDays;
    if (lastWatered != null) data['last_watered'] = lastWatered!.toIso8601String().split('T')[0];
    if (lastFertilized != null) data['last_fertilized'] = lastFertilized!.toIso8601String().split('T')[0];
    if (lastPruned != null) data['last_pruned'] = lastPruned!.toIso8601String().split('T')[0];
    if (lastRepotted != null) data['last_repotted'] = lastRepotted!.toIso8601String().split('T')[0];
    if (notes != null) data['notes'] = notes;
    
    return data;
  }
}