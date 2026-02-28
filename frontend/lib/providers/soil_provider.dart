import 'dart:io';
import 'package:flutter/material.dart';
import '../models/soil_prediction.dart';
import '../services/api_service.dart';

class SoilProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  SoilPredictionResponse? _lastPrediction;
  bool _isLoading = false;
  String? _error;

  SoilPredictionResponse? get lastPrediction => _lastPrediction;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool value) {
    _isLoading = value;
    if (value) _error = null;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> predictImage(File imageFile, {double? latitude, double? longitude}) async {
    setLoading(true);
    try {
      _lastPrediction = await _apiService.predictSoil(imageFile, latitude: latitude, longitude: longitude);
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}
