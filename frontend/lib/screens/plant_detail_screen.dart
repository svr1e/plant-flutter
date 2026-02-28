import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/plant_care.dart';
import '../providers/plant_care_provider.dart';
import '../widgets/glossy_widgets.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantCare plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late PlantCare _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _plant.plantName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Background to match HomeScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 110),
                
                // Plant Info Card
                GlossyCard(
                  fillOpacity: 0.08,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: const Color(0xFF1F3D2B).withValues(alpha: 0.8),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _plant.plantName,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1F3D2B),
                                        ),
                                  ),
                                  if (_plant.notes != null)
                                    Text(
                                      _plant.notes!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _plant.hasAnyTaskDue
                                ? Colors.orange.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _plant.hasAnyTaskDue
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _plant.hasAnyTaskDue
                                    ? Icons.error_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: _plant.hasAnyTaskDue
                                    ? Colors.orange.shade800
                                    : Colors.green.shade800,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _plant.hasAnyTaskDue
                                      ? 'Some tasks need your attention'
                                      : 'Your plant is doing great!',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _plant.hasAnyTaskDue
                                            ? Colors.orange.shade900
                                            : Colors.green.shade900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Care Tasks Section Header
                Text(
                  'Care Schedule',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F3D2B),
                      ),
                ),
                const SizedBox(height: 16),
                
                // Watering
                _buildCareTaskCard(
                  'Watering',
                  '💧',
                  _plant.lastWatered,
                  _plant.nextWatering,
                  _plant.daysUntilWatering,
                  _plant.isWateringDue,
                  Colors.blue,
                  () => _markActionCompleted('watering'),
                ),
                
                const SizedBox(height: 16),
                
                // Fertilizing
                _buildCareTaskCard(
                  'Fertilizing',
                  '🌱',
                  _plant.lastFertilized,
                  _plant.nextFertilizing,
                  _plant.daysUntilFertilizing,
                  _plant.isFertilizingDue,
                  Colors.orange,
                  () => _markActionCompleted('fertilizing'),
                ),
                
                const SizedBox(height: 16),
                
                // Pruning
                _buildCareTaskCard(
                  'Pruning',
                  '✂️',
                  _plant.lastPruned,
                  _plant.nextPruning,
                  _plant.daysUntilPruning,
                  _plant.isPruningDue,
                  Colors.green,
                  () => _markActionCompleted('pruning'),
                ),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTaskCard(
    String title,
    String emoji,
    DateTime? lastDate,
    DateTime? nextDate,
    int? daysUntil,
    bool isDue,
    Color accentColor,
    VoidCallback onMarkComplete,
  ) {
    return GlossyCard(
      fillOpacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F3D2B),
                      ),
                ),
                const Spacer(),
                if (isDue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'DUE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateInfo('Last Action', lastDate),
                ),
                Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildDateInfo('Next Action', nextDate),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mark Complete Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isDue ? onMarkComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDue ? const Color(0xFF1F3D2B) : Colors.white.withValues(alpha: 0.5),
                  foregroundColor: isDue ? Colors.white : const Color(0xFF1F3D2B).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isDue ? 2 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isDue ? Icons.check_circle_rounded : Icons.lock_clock_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      isDue ? 'Mark as Completed' : 'Not Due Yet',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime? date) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          date != null 
              ? '${date.day}/${date.month}/${date.year}' 
              : 'Never',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
      ],
    );
  }

  void _markActionCompleted(String actionType) async {
    final provider = Provider.of<PlantCareProvider>(context, listen: false);
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    final success = await provider.markActionCompleted(_plant.id, actionType);
    
    if (success && mounted) {
      // Haptic feedback for success
      HapticFeedback.lightImpact();
      
      // Refresh plant data
      final updatedPlant = await provider.fetchPlantCare(_plant.id);
      if (updatedPlant != null && mounted) {
        setState(() {
          _plant = updatedPlant;
        });
      }
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great job! ${_plant.plantName} is hydrated and happy. 🌿',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plant Care'),
        content: Text('Are you sure you want to delete care schedule for "${_plant.plantName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final provider = Provider.of<PlantCareProvider>(context, listen: false);
              
              navigator.pop(); // Close dialog
              
              final success = await provider.deletePlantCare(_plant.id);
              
              if (success) {
                navigator.pop(); // Go back to list
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('🌿 ${_plant.plantName} care schedule deleted'),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}