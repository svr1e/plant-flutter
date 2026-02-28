import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/soil_prediction.dart';
import '../widgets/glossy_widgets.dart';

class SoilDetailScreen extends StatefulWidget {
  final SoilPredictionResponse prediction;

  const SoilDetailScreen({super.key, required this.prediction});

  @override
  State<SoilDetailScreen> createState() => _SoilDetailScreenState();
}

class _SoilDetailScreenState extends State<SoilDetailScreen> {
  late final Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = base64Decode(widget.prediction.imageData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Soil Result'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8D6E63).withValues(alpha: 0.1),
                  Colors.white,
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlossyCard(
                  borderRadius: 24,
                  useBlur: false,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      _imageBytes,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSummary(widget.prediction),
                const SizedBox(height: 24),
                if (widget.prediction.topPredictions.length > 1) _buildTopPredictions(widget.prediction.topPredictions),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(SoilPredictionResponse response) {
    final c = response.prediction.confidencePercentage;
    final name = response.m.isNotEmpty ? response.m : response.prediction.className;
    final color = const Color(0xFF8D6E63);
    return GlossyCard(
      fillOpacity: 0.1,
      gradientColors: [
        color.withValues(alpha: 0.15),
        color.withValues(alpha: 0.05),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.landscape_rounded, color: Color(0xFF8D6E63), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color.withValues(alpha: 0.9),
                        ),
                      ),
                      const Text('Predicted Soil Type', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('Confidence Score:', style: TextStyle(color: Colors.black54)),
                const Spacer(),
                Text(
                  '${c.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: c / 100,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
                minHeight: 8,
              ),
            ),
            if (response.weatherSummary != null) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 18, color: Colors.black45),
                  const SizedBox(width: 8),
                  Text(
                    'Last ${response.weatherSummary!.periodDays} days: '
                    '${response.weatherSummary!.avgTemperatureC.toStringAsFixed(1)}°C, '
                    '${response.weatherSummary!.totalPrecipitationMm.toStringAsFixed(0)}mm, '
                    '${response.weatherSummary!.aridity}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            if (response.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              const Text('Recommended Crops', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...response.recommendations.take(6).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF8D6E63)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 14),
                            children: [
                              TextSpan(text: r.crop, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (r.reason.isNotEmpty) const TextSpan(text: ' – '),
                              if (r.reason.isNotEmpty) TextSpan(text: r.reason, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopPredictions(List<TopPrediction> topPredictions) {
    return GlossyCard(
      fillOpacity: 0.05,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternatives',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...topPredictions.skip(1).map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.className,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text('${(p.confidence * 100).toStringAsFixed(1)}%'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: p.confidence,
                          backgroundColor: Colors.grey.shade100,
                          color: const Color(0xFF8D6E63).withValues(alpha: 0.6),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
