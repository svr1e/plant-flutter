import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/plant_care.dart';
import '../providers/plant_care_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'add_plant_care_screen.dart';
import 'plant_detail_screen.dart';

class CareSchedulerScreen extends StatefulWidget {
  const CareSchedulerScreen({super.key});

  @override
  State<CareSchedulerScreen> createState() => _CareSchedulerScreenState();
}

class _CareSchedulerScreenState extends State<CareSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlantCareProvider>(context, listen: false);
      provider.refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Plant Care Scheduler',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
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
          Consumer<PlantCareProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.plants.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1F3D2B)),
                );
              }

              if (provider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! ${provider.error}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF1F3D2B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GlossyButton(
                        onPressed: () => provider.refreshData(),
                        label: const Text('Retry'),
                        color: const Color(0xFF1F3D2B),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.refreshData(),
                color: const Color(0xFF1F3D2B),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // Padding for AppBar
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    
                    // Welcome Message
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plant Care Dashboard',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F3D2B),
                                  ),
                            ),
                            Text(
                              'Keep your urban garden healthy',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Today's Tasks Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _buildTodayTasksSection(provider),
                      ),
                    ),

                    // Plants List Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          'Your Plants',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F3D2B),
                              ),
                        ),
                      ),
                    ),

                    // Plant Cards Grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plant = provider.plants[index];
                            return _buildPlantCard(plant, provider);
                          },
                          childCount: provider.plants.length,
                        ),
                      ),
                    ),

                    // Add some bottom padding
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 120),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlantDialog(context),
        backgroundColor: const Color(0xFF1F3D2B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Plant'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTodayTasksSection(PlantCareProvider provider) {
    final todayTasks = provider.todayTasks;
    
    return GlossyCard(
      fillOpacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1F3D2B),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (todayTasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3D2B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${todayTasks.length} Due',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1F3D2B),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (todayTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All plants are happy and healthy today!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...todayTasks.take(3).map((plant) => _buildTodayTaskItem(plant)),
              
            if (todayTasks.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'and ${todayTasks.length - 3} more tasks to do...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTaskItem(PlantCare plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3D2B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_florist_rounded,
              color: const Color(0xFF1F3D2B).withValues(alpha: 0.8),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plant.plantName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F3D2B),
                      ),
                ),
                Text(
                  plant.dueTasks.join(', '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _completeFirstTask(plant),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.done_rounded, color: Colors.green, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(PlantCare plant, PlantCareProvider provider) {
    return GestureDetector(
      onTap: () => _navigateToPlantDetail(plant),
      child: GlossyCard(
        fillOpacity: 0.08,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plant Icon and Name
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      color: const Color(0xFF1F3D2B).withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      plant.plantName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F3D2B),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Care Items with Progress Indicators
              _buildProgressItem('💧', plant.daysUntilWatering, plant.wateringFrequencyDays, plant.isWateringDue, Colors.blue),
              const SizedBox(height: 12),
              _buildProgressItem('🌱', plant.daysUntilFertilizing, plant.fertilizingFrequencyDays, plant.isFertilizingDue, Colors.orange),
              const SizedBox(height: 12),
              _buildProgressItem('✂️', plant.daysUntilPruning, plant.pruningFrequencyDays, plant.isPruningDue, Colors.green),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: plant.hasAnyTaskDue 
                      ? () => _completeFirstTask(plant)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plant.hasAnyTaskDue ? const Color(0xFF1F3D2B) : Colors.white,
                    foregroundColor: plant.hasAnyTaskDue ? Colors.white : const Color(0xFF1F3D2B).withValues(alpha: 0.4),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    plant.hasAnyTaskDue ? 'Mark Done' : 'Healthy ✨',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String emoji, int? daysUntil, int frequency, bool isDue, Color color) {
    if (daysUntil == null) return const SizedBox.shrink();
    
    // Calculate progress (0.0 to 1.0)
    // If daysUntil is 0 or less, progress is 1.0
    // Otherwise, progress is (frequency - daysUntil) / frequency
    double progress = isDue ? 1.0 : (frequency - daysUntil).clamp(0, frequency) / frequency;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            Text(
              isDue ? 'DUE' : (daysUntil == 1 ? 'Tomorrow' : '$daysUntil d'),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDue ? Colors.red.shade700 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              isDue ? Colors.red.shade400 : color.withValues(alpha: 0.7),
            ),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  void _showAddPlantDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPlantCareScreen(),
      ),
    );
  }

  void _navigateToPlantDetail(PlantCare plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlantDetailScreen(plant: plant),
      ),
    );
  }

  void _completeFirstTask(PlantCare plant) async {
    final provider = Provider.of<PlantCareProvider>(context, listen: false);
    
    if (plant.dueTasks.isEmpty) return;
    
    final actionType = plant.dueTasks.first.toLowerCase();
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    final success = await provider.markActionCompleted(plant.id, actionType);
    
    if (success && mounted) {
      // Haptic feedback for success
      HapticFeedback.lightImpact();
      
      // Show success animation/snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Great job! ${plant.plantName} is hydrated and happy. 🌿',
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