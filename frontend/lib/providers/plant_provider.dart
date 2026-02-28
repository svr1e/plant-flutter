import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/prediction.dart';
import '../models/history.dart';
import '../services/api_service.dart';

class PlantProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger();
  PredictionResponse? _lastPrediction;
  List<HistoryItem> _history = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  Map<String, dynamic>? _weatherAlerts;

  PredictionResponse? get lastPrediction => _lastPrediction;
  List<HistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get stats => _stats;
  Map<String, dynamic>? get weatherAlerts => _weatherAlerts;

  void setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> fetchWeatherAlerts(double lat, double lon) async {
    try {
      _weatherAlerts = await _apiService.getWeatherAlerts(lat, lon);
      notifyListeners();
    } catch (e) {
      _logger.e('Failed to fetch weather alerts: $e');
    }
  }

  Future<void> predictImage(File imageFile) async {
    setLoading(true);
    try {
      _lastPrediction = await _apiService.predictImage(imageFile);
      // Automatically save to history
      await _apiService.saveHistory(_lastPrediction!);
      // Update history and stats
      await fetchHistory();
      await fetchStats();
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> fetchHistory() async {
    _error = null;
    try {
      final response = await _apiService.getHistory();
      _history = response.history;
      notifyListeners();
    } catch (e) {
      _logger.e('Fetch history error: $e');
      _error = 'Failed to load history. Please check your connection.';
      notifyListeners();
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    try {
      final success = await _apiService.deleteHistoryItem(id);
      if (success) {
        _history.removeWhere((item) => item.id == id);
        notifyListeners();
        await fetchStats();
      }
    } catch (e) {
      _logger.e('Delete history error: $e');
      rethrow;
    }
  }

  Future<void> fetchStats() async {
    _error = null;
    try {
      final data = await _apiService.getDashboardStats();
      if (data['success']) {
        _stats = data['stats'];
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Fetch stats error: $e');
      _error = 'Failed to load dashboard data.';
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getTreatmentGuide(String disease, {String? plant}) async {
    try {
      return await _apiService.getTreatmentGuide(disease, plant: plant);
    } catch (e) {
      rethrow;
    }
  }
}
