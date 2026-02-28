class SoilPredictionResponse {
  final bool success;
  final Prediction prediction;
  final List<TopPrediction> topPredictions;
  final String m;
  final WeatherSummary? weatherSummary;
  final List<Recommendation> recommendations;
  final String filename;
  final String imageData;
  final String timestamp;

  SoilPredictionResponse({
    required this.success,
    required this.prediction,
    required this.topPredictions,
    required this.m,
    required this.weatherSummary,
    required this.recommendations,
    required this.filename,
    required this.imageData,
    required this.timestamp,
  });

  factory SoilPredictionResponse.fromJson(Map<String, dynamic> json) {
    return SoilPredictionResponse(
      success: json['success'] ?? false,
      prediction: Prediction.fromJson(json['prediction']),
      topPredictions: (json['top_predictions'] as List)
          .map((i) => TopPrediction.fromJson(i))
          .toList(),
      m: json['m'] ?? (json['prediction']?['class_name'] ?? ''),
      weatherSummary: json['weather_summary'] != null ? WeatherSummary.fromJson(json['weather_summary']) : null,
      recommendations: (json['recommendations'] as List?)
              ?.map((i) => Recommendation.fromJson(i))
              .toList() ??
          const [],
      filename: json['filename'] ?? '',
      imageData: json['image_data'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
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
}

class WeatherSummary {
  final double avgTemperatureC;
  final double totalPrecipitationMm;
  final String aridity;
  final int periodDays;

  WeatherSummary({
    required this.avgTemperatureC,
    required this.totalPrecipitationMm,
    required this.aridity,
    required this.periodDays,
  });

  factory WeatherSummary.fromJson(Map<String, dynamic> json) {
    return WeatherSummary(
      avgTemperatureC: (json['avg_temperature_c'] ?? 0.0).toDouble(),
      totalPrecipitationMm: (json['total_precipitation_mm'] ?? 0.0).toDouble(),
      aridity: json['aridity'] ?? '',
      periodDays: json['period_days'] ?? 0,
    );
  }
}

class Recommendation {
  final String crop;
  final String reason;

  Recommendation({required this.crop, required this.reason});

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      crop: json['crop'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}
