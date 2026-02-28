import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'detail_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<PlantProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Diagnosis History'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          Consumer<PlantProvider>(
            builder: (context, provider, child) {
              final history = provider.history;
              final error = provider.error;

              if (error != null && history.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(error, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        GlossyButton(
                          onPressed: () => provider.fetchHistory(),
                          label: const Text('Retry'),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (history.isEmpty && !provider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No history records yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchHistory(),
                displacement: 120,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final prediction = item.predictionResult;
                    final info = prediction.diseaseInfo;
                    final date = DateTime.parse(item.createdAt);
                    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);
                    final isHealthy = info.isHealthy;
                    final statusColor = isHealthy ? const Color(0xFF8FBC8F) : const Color(0xFFFF5252);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GlossyCard(
                        fillOpacity: 0.05,
                        useBlur: false,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailScreen(prediction: prediction),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'history_img_${item.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.memory(
                                      base64Decode(prediction.imageData),
                                      cacheWidth: 160,
                                      cacheHeight: 160,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info.disease,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        info.plant,
                                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isHealthy ? 'Healthy' : 'Diseased',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  onPressed: () => _showItemOptions(context, provider, item.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showItemOptions(BuildContext context, PlantProvider provider, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlossyCard(
        borderRadius: 24,
        fillOpacity: 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Diagnosis', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider, id);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlantProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Record?'),
        content: const Text('This action cannot be undone. Are you sure you want to remove this diagnosis?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteHistoryItem(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
