import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/plant_care.dart';
import '../services/api_service.dart';

class PlantCareProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<PlantCare> _plants = [];
  List<PlantCare> _todayTasks = [];
  bool _isLoading = false;
  String? _error;

  List<PlantCare> get plants => _plants;
  List<PlantCare> get todayTasks => _todayTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get all plant care schedules
  Future<void> fetchPlantCares() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/plant-care');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final plantCareList = PlantCareListResponse.fromJson(data);
        _plants = plantCareList.plants;
        _error = null;
      } else {
        _error = data['detail'] ?? 'Failed to fetch plant cares';
      }
    } catch (e) {
      _error = 'Failed to fetch plant cares: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get today's tasks
  Future<void> fetchTodayTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/plant-care/today');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final todayTasksResponse = TodayTasksResponse.fromJson(data);
        _todayTasks = todayTasksResponse.tasks;
        _error = null;
      } else {
        _error = data['detail'] ?? 'Failed to fetch today tasks';
      }
    } catch (e) {
      _error = 'Failed to fetch today tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new plant care schedule
  Future<bool> createPlantCare(PlantCareCreate plantCare) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/plant-care',
        body: json.encode(plantCare.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newPlantCare = PlantCare.fromJson(data);
        _plants.add(newPlantCare);
        _error = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['detail'] ?? 'Failed to create plant care';
        return false;
      }
    } catch (e) {
      _error = 'Failed to create plant care: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update plant care schedule
  Future<bool> updatePlantCare(String plantCareId, PlantCareUpdate plantCare) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        '/plant-care/$plantCareId',
        body: json.encode(plantCare.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedPlantCare = PlantCare.fromJson(data);
        
        // Update in local list
        final index = _plants.indexWhere((p) => p.id == plantCareId);
        if (index != -1) {
          _plants[index] = updatedPlantCare;
        }
        
        _error = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['detail'] ?? 'Failed to update plant care';
        return false;
      }
    } catch (e) {
      _error = 'Failed to update plant care: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark care action as completed
  Future<bool> markActionCompleted(String plantCareId, String actionType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final actionRequest = ActionRequest(actionType: actionType);
      final response = await _apiService.post(
        '/plant-care/$plantCareId/mark-action',
        body: json.encode(actionRequest.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedPlantCare = PlantCare.fromJson(data);
        
        // Update in local lists
        final plantIndex = _plants.indexWhere((p) => p.id == plantCareId);
        if (plantIndex != -1) {
          _plants[plantIndex] = updatedPlantCare;
        }
        
        final taskIndex = _todayTasks.indexWhere((p) => p.id == plantCareId);
        if (taskIndex != -1) {
          _todayTasks[taskIndex] = updatedPlantCare;
          // Remove from today tasks if no longer due
          if (!updatedPlantCare.hasAnyTaskDue) {
            _todayTasks.removeAt(taskIndex);
          }
        }
        
        _error = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['detail'] ?? 'Failed to mark action completed';
        return false;
      }
    } catch (e) {
      _error = 'Failed to mark action completed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete plant care schedule
  Future<bool> deletePlantCare(String plantCareId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.delete('/plant-care/$plantCareId');
      
      if (response.statusCode == 200) {
        _plants.removeWhere((p) => p.id == plantCareId);
        _todayTasks.removeWhere((p) => p.id == plantCareId);
        _error = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['detail'] ?? 'Failed to delete plant care';
        return false;
      }
    } catch (e) {
      _error = 'Failed to delete plant care: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    await Future.wait([
      fetchPlantCares(),
      fetchTodayTasks(),
    ]);
  }

  // Fetch single plant care
  Future<PlantCare?> fetchPlantCare(String plantCareId) async {
    try {
      final response = await _apiService.get('/plant-care/$plantCareId');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlantCare.fromJson(data);
      }
      return null;
    } catch (e) {
      _error = 'Failed to fetch plant care: $e';
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}