import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prediction.dart';
import '../models/soil_prediction.dart' as soil;
import '../models/history.dart';
import '../models/user.dart';

class ApiService {
  final Logger _logger = Logger();
  
  // Set this to true for production deployment
  static const bool _isProduction = true;
  
  // Replace with your deployed backend URL (e.g., https://your-app.onrender.com)
  static const String _prodUrl = 'https://plant-flutter.onrender.com';
  
  static const String _hostIp = 'localhost';
  
  static String get baseUrl {
    if (_isProduction) {
      return _prodUrl;
    }
    
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return _hostIp == 'localhost' ? 'http://10.0.2.2:8000' : 'http://$_hostIp:8000';
    } else {
      return 'http://$_hostIp:8000';
    }
  }
  
  static const Duration timeoutDuration = Duration(seconds: 60);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    final Map<String, String> headers = {};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Auth Endpoints
  Future<User> signup(String username, String email, String password, {String? fullName}) async {
    final url = Uri.parse('$baseUrl/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Failed to signup';
        throw Exception(error);
      }
    } catch (e) {
      _logger.e('Signup error: $e');
      rethrow;
    }
  }

  Future<AuthToken> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/token');
    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return AuthToken.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body)['detail'] ?? 'Incorrect username or password';
        throw Exception(error);
      }
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  Future<User> getMe() async {
    final url = Uri.parse('$baseUrl/users/me');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get user profile');
      }
    } catch (e) {
      _logger.e('Get user profile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWeatherAlerts(double lat, double lon) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/weather/alerts?lat=$lat&lon=$lon');
      
      _logger.i('Fetching weather alerts for: $lat, $lon');
      
      final response = await http.get(url, headers: headers).timeout(timeoutDuration);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ?? 'Failed to fetch weather alerts');
      }
    } catch (e) {
      _logger.e('Weather alerts error: $e');
      rethrow;
    }
  }

  Future<PredictionResponse> predictImage(File imageFile) async {
    final url = Uri.parse('$baseUrl/predict');
    try {
      final request = http.MultipartRequest('POST', url);
      final headers = await _getHeaders(isMultipart: true);
      request.headers.addAll(headers);
      
      // Get mime type of the file
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Predict error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to predict: ${response.statusCode}');
      }
    } on TimeoutException {
      _logger.e('Predict timeout');
      throw Exception('Connection timed out. Please check if the backend is running.');
    } catch (e) {
      _logger.e('Predict exception: $e');
      rethrow;
    }
  }

  Future<soil.SoilPredictionResponse> predictSoil(File imageFile, {double? latitude, double? longitude}) async {
    final url = Uri.parse('$baseUrl/soil/predict');
    try {
      final request = http.MultipartRequest('POST', url);
      final headers = await _getHeaders(isMultipart: true);
      request.headers.addAll(headers);

      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeTypeParts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );
      if (latitude != null) {
        request.fields['lat'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['lon'] = longitude.toString();
      }

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return soil.SoilPredictionResponse.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Soil predict error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to predict soil: ${response.statusCode}');
      }
    } on TimeoutException {
      _logger.e('Soil predict timeout');
      throw Exception('Connection timed out. Please check if the backend is running.');
    } catch (e) {
      _logger.e('Soil predict exception: $e');
      rethrow;
    }
  }

  Future<HistoryResponse> getHistory({int limit = 50, int skip = 0}) async {
    final url = Uri.parse('$baseUrl/history?limit=$limit&skip=$skip');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return HistoryResponse.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Get history error: ${response.statusCode}');
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out while fetching history.');
    } catch (e) {
      _logger.e('Get history exception: $e');
      rethrow;
    }
  }

  Future<bool> saveHistory(PredictionResponse prediction) async {
    final url = Uri.parse('$baseUrl/history');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(prediction.toJson()),
      ).timeout(timeoutDuration);

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Save history exception: $e');
      return false;
    }
  }

  Future<bool> deleteHistoryItem(String id) async {
    final url = Uri.parse('$baseUrl/history/$id');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(timeoutDuration);
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Delete history exception: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final url = Uri.parse('$baseUrl/dashboard/stats');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Get stats error: ${response.statusCode}');
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out while fetching dashboard stats.');
    } catch (e) {
      _logger.e('Get stats exception: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTreatmentGuide(String disease, {String? plant}) async {
    var urlString = '$baseUrl/treatment-guide?disease=$disease';
    if (plant != null) {
      urlString += '&plant=$plant';
    }
    final url = Uri.parse(urlString);
    try {
      final response = await http.get(url).timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger.e('Get treatment guide error: ${response.statusCode}');
        throw Exception('Failed to get treatment guide: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Connection timed out while fetching treatment guide.');
    } catch (e) {
      _logger.e('Get treatment guide exception: $e');
      rethrow;
    }
  }

  // Generic HTTP methods for plant care endpoints
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(timeoutDuration);
      return response;
    } catch (e) {
      _logger.e('GET request exception: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, {String? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(timeoutDuration);
      return response;
    } catch (e) {
      _logger.e('POST request exception: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, {String? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        url,
        headers: headers,
        body: body,
      ).timeout(timeoutDuration);
      return response;
    } catch (e) {
      _logger.e('PUT request exception: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers).timeout(timeoutDuration);
      return response;
    } catch (e) {
      _logger.e('DELETE request exception: $e');
      rethrow;
    }
  }
}
