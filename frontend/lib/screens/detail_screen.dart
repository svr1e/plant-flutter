import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/prediction.dart';
import '../widgets/glossy_widgets.dart';

class DetailScreen extends StatefulWidget {
  final PredictionResponse prediction;

  const DetailScreen({super.key, required this.prediction});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final Uint8List _imageBytes;

  @override
  void initState() {
    super.initState();
    _imageBytes = base64Decode(widget.prediction.imageData);
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.prediction.diseaseInfo;
    final isHealthy = info.isHealthy;
    final aiSummary = widget.prediction.aiSummary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Diagnosis Result'),
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
                  (isHealthy ? const Color(0xFF8FBC8F) : const Color(0xFFFF5252)).withValues(alpha: 0.12),
                  const Color(0xFFF8FAF5),
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
                _buildImageCard(),
                const SizedBox(height: 24),
                _buildDiagnosisCard(info, widget.prediction.prediction.confidencePercentage, isHealthy),
                const SizedBox(height: 24),
                if (aiSummary != null) _buildAiSummaryCard(aiSummary),
                const SizedBox(height: 24),
                if (aiSummary != null && aiSummary['product_search_keywords'] != null)
                  _buildMedicineLinksCard(List<String>.from(aiSummary['product_search_keywords'])),
                const SizedBox(height: 24),
                _buildDetailsCard(info),
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

  Widget _buildImageCard() {
    return GlossyCard(
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
    );
  }

  Widget _buildDiagnosisCard(DiseaseInfo info, double confidence, bool isHealthy) {
    final statusColor = isHealthy ? const Color(0xFF8FBC8F) : const Color(0xFFFF5252);
    
    return GlossyCard(
      fillOpacity: 0.1,
      gradientColors: [
        statusColor.withValues(alpha: 0.15),
        statusColor.withValues(alpha: 0.05),
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
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isHealthy ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.disease,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: statusColor.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        info.plant,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
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
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: confidence / 100,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                color: statusColor,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryCard(Map<String, dynamic> aiSummary) {
    final diagnosis = aiSummary['diagnosis_summary']?['text'] ?? '';
    final risk = aiSummary['risk_assessment'] ?? {};
    final treatment = aiSummary['chemical_treatment']?['summary'] ?? '';
    final organic = aiSummary['organic_remedies']?['summary'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFC6A75E), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Analysis Report',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC6A75E)),
              ),
            ],
          ),
        ),
        GlossyCard(
          fillOpacity: 0.05,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (diagnosis.isNotEmpty) ...[
                  _buildAiSection('Summary', diagnosis),
                ],
                if (risk.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Risk Severity: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(risk['severity_level']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          risk['severity_level'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getSeverityColor(risk['severity_level']),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (treatment.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAiSection('Chemical Action', treatment),
                ],
                if (organic.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAiSection('Organic Remedy', organic),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Colors.black87, height: 1.4)),
      ],
    );
  }

  Widget _buildMedicineLinksCard(List<String> keywords) {
    if (keywords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: Color(0xFF8B5E3C), size: 20),
              SizedBox(width: 8),
              Text(
                'Medicine & Treatment Links',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
              ),
            ],
          ),
        ),
        GlossyCard(
          fillOpacity: 0.05,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find recommended products on:',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: keywords.expand((keyword) => [
                    _buildLinkChip(
                      label: 'Amazon: $keyword',
                      icon: Icons.shopping_bag_outlined,
                      url: 'https://www.amazon.com/s?k=${Uri.encodeComponent("$keyword plant treatment")}',
                      color: const Color(0xFFFF9900),
                    ),
                    _buildLinkChip(
                      label: 'Google: $keyword',
                      icon: Icons.search_rounded,
                      url: 'https://www.google.com/search?q=${Uri.encodeComponent("$keyword plant treatment")}',
                      color: const Color(0xFF4285F4),
                    ),
                  ]).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkChip({
    required String label,
    required IconData icon,
    required String url,
    required Color color,
  }) {
    return ActionChip(
      onPressed: () => _launchURL(url),
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildDetailsCard(DiseaseInfo info) {
    return Column(
      children: [
        _buildInfoSection('Visible Symptoms', info.symptoms, Icons.visibility_outlined),
        const SizedBox(height: 16),
        _buildInfoSection('Standard Treatment', info.treatment, Icons.medication_outlined),
        const SizedBox(height: 16),
        _buildInfoSection('Prevention Tips', info.prevention, Icons.shield_outlined),
      ],
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return GlossyCard(
      fillOpacity: 0.02,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, color: const Color(0xFF1F3D2B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
        ],
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
              'Alternative Diagnoses',
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
                            p.className.split('___').last.replaceAll('_', ' '),
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
                          color: Colors.orange.withValues(alpha: 0.6),
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

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
