class PredictionResponse {
  final bool success;
  final Prediction prediction;
  final DiseaseInfo diseaseInfo;
  final List<TopPrediction> topPredictions;
  final String? aiInsights;
  final Map<String, dynamic>? aiSummary;
  final String filename;
  final String imageData;
  final String timestamp;

  PredictionResponse({
    required this.success,
    required this.prediction,
    required this.diseaseInfo,
    required this.topPredictions,
    this.aiInsights,
    this.aiSummary,
    required this.filename,
    required this.imageData,
    required this.timestamp,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      success: json['success'] ?? false,
      prediction: Prediction.fromJson(json['prediction']),
      diseaseInfo: DiseaseInfo.fromJson(json['disease_info']),
      topPredictions: (json['top_predictions'] as List)
          .map((i) => TopPrediction.fromJson(i))
          .toList(),
      aiInsights: json['ai_insights'],
      aiSummary: json['ai_summary'],
      filename: json['filename'] ?? '',
      imageData: json['image_data'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'prediction': prediction.toJson(),
      'disease_info': diseaseInfo.toJson(),
      'top_predictions': topPredictions.map((i) => i.toJson()).toList(),
      'ai_insights': aiInsights,
      'ai_summary': aiSummary,
      'filename': filename,
      'image_data': imageData,
      'timestamp': timestamp,
    };
  }
}

class Prediction {
  final int classIndex;
  final String className;
  final double confidence;
  final double confidencePercentage;

  Prediction({
    required this.classIndex,
    required this.className,
    required this.confidence,
    required this.confidencePercentage,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      classIndex: json['class_index'] ?? 0,
      className: json['class_name'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      confidencePercentage: (json['confidence_percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class_index': classIndex,
      'class_name': className,
      'confidence': confidence,
      'confidence_percentage': confidencePercentage,
    };
  }
}

class DiseaseInfo {
  final String plant;
  final String disease;
  final bool isHealthy;
  final String symptoms;
  final String treatment;
  final String prevention;

  DiseaseInfo({
    required this.plant,
    required this.disease,
    required this.isHealthy,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      plant: json['plant'] ?? '',
      disease: json['disease'] ?? '',
      isHealthy: json['is_healthy'] ?? false,
      symptoms: json['symptoms'] ?? '',
      treatment: json['treatment'] ?? '',
      prevention: json['prevention'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant': plant,
      'disease': disease,
      'is_healthy': isHealthy,
      'symptoms': symptoms,
      'treatment': treatment,
      'prevention': prevention,
    };
  }
}

class TopPrediction {
  final String className;
  final double confidence;

  TopPrediction({
    required this.className,
    required this.confidence,
  });

  factory TopPrediction.fromJson(Map<String, dynamic> json) {
    return TopPrediction(
      className: json['class'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'class': className,
      'confidence': confidence,
    };
  }
}
