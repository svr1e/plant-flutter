import 'prediction.dart';

class HistoryItem {
  final String id;
  final PredictionResponse predictionResult;
  final String createdAt;

  HistoryItem({
    required this.id,
    required this.predictionResult,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['_id'] ?? '',
      predictionResult: PredictionResponse.fromJson(json),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class HistoryResponse {
  final bool success;
  final List<HistoryItem> history;
  final int total;
  final int limit;
  final int skip;

  HistoryResponse({
    required this.success,
    required this.history,
    required this.total,
    required this.limit,
    required this.skip,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    return HistoryResponse(
      success: json['success'] ?? false,
      history: (json['history'] as List)
          .map((i) => HistoryItem.fromJson(i))
          .toList(),
      total: json['total'] ?? 0,
      limit: json['limit'] ?? 50,
      skip: json['skip'] ?? 0,
    );
  }
}
