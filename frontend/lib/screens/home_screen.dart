import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'history_screen.dart';
import 'care_scheduler_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _touchedIndex = -1;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<PlantProvider>().fetchStats();
      // Using default location for demo purposes, could use location service
      context.read<PlantProvider>().fetchWeatherAlerts(12.9716, 77.5946);
    });
  }

  Widget _buildWeatherAlerts(Map<String, dynamic>? weatherData) {
    if (weatherData == null || !weatherData['success']) return const SizedBox.shrink();

    final alerts = weatherData['alerts'] as List<dynamic>? ?? [];
    final recommendations = weatherData['recommendations'] as List<dynamic>? ?? [];
    final weather = weatherData['weather'];

    if (alerts.isEmpty && recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather Insights',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        const SizedBox(height: 12),
        GlossyCard(
          fillOpacity: 0.08,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (weather != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        weather['location'] ?? 'Current Location',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F3D2B).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${weather['temp']}°C • ${weather['description']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F3D2B),
                              ),
                        ),
                      ),
                    ],
                  ),
                if (weather != null) const Divider(height: 24),
                if (alerts.isNotEmpty)
                  ...alerts.map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (alert['severity'] == 'high' ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (alert['severity'] == 'high' ? Colors.red : Colors.orange).withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                alert['type'] == 'frost'
                                    ? Icons.ac_unit
                                    : alert['type'] == 'heat'
                                        ? Icons.wb_sunny
                                        : alert['type'] == 'rain'
                                            ? Icons.umbrella
                                            : Icons.warning_amber_rounded,
                                color: alert['severity'] == 'high' ? Colors.red : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert['title'],
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: alert['severity'] == 'high' ? Colors.red : Colors.orange,
                                          ),
                                    ),
                                    Text(
                                      alert['message'],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: (alert['severity'] == 'high' ? Colors.red : Colors.orange).withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                if (recommendations.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F3D2B).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF1F3D2B)),
                            const SizedBox(width: 8),
                            Text(
                              'Gardening Tip',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F3D2B),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...recommendations.map((rec) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      rec,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          centerTitle: false,
          title: Text(
            'PlantAI Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        backgroundColor: Colors.transparent,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Background
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
          Consumer<PlantProvider>(
            builder: (context, provider, child) {
              final stats = provider.stats;
              final error = provider.error;

              if (error != null && stats == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(error, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      GlossyButton(
                        onPressed: () => provider.fetchStats(),
                        label: const Text('Retry'),
                        color: Colors.red,
                      ),
                    ],
                  ),
                );
              }

              if (stats == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final total = stats['total_diagnoses'] ?? 0;
              final healthy = stats['healthy_plants'] ?? 0;
              final diseased = stats['diseased_plants'] ?? 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.fullName?.split(' ').first ?? user?.username ?? 'Gardener'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F3D2B),
                          ),
                    ),
                    Text(
                      'Check your plant health stats today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _buildWeatherAlerts(provider.weatherAlerts),
                    const SizedBox(height: 24),
                    _buildQuickActions(context),
                    const SizedBox(height: 24),
                    _buildSummaryCards(total, healthy, diseased),
                    const SizedBox(height: 32),
                    Text(
                      'Health Distribution',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F3D2B),
                          ),
                    ),
                    const SizedBox(height: 16),
                    GlossyCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _buildPieChart(healthy, diseased),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Recent Diagnoses',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F3D2B),
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDiseaseList(stats['disease_distribution'] ?? []),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _QuickActionCard(
          color: const Color(0xFFF4C430),
          icon: Icons.calendar_month_rounded,
          title: 'Care Scheduler',
          subtitle: 'Reminders & alerts',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CareSchedulerScreen()));
          },
        ),
        _QuickActionCard(
          color: const Color(0xFF8FBC8F),
          icon: Icons.history_rounded,
          title: 'History',
          subtitle: 'View past reports',
          onTap: () {
            if (widget.onTabChange != null) {
              widget.onTabChange!(2); // Switch to History tab (index 2)
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }
          },
        ),
        _QuickActionCard(
          color: const Color(0xFF8B5E3C),
          icon: Icons.shopping_bag_rounded,
          title: 'Shop',
          subtitle: 'Plant products',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
          },
        ),
        _QuickActionCard(
          color: const Color(0xFF1F3D2B),
          icon: Icons.groups_rounded,
          title: 'Community',
          subtitle: 'Garden talk',
          onTap: () {
            if (widget.onTabChange != null) {
              widget.onTabChange!(1); // Switch to Community tab (index 1)
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Community feature available in navigation')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int total, int healthy, int diseased) {
    return Row(
      children: [
        _buildStatCard('Total', total.toString(), const Color(0xFF1F3D2B), Icons.grid_view_rounded),
        const SizedBox(width: 12),
        _buildStatCard('Healthy', healthy.toString(), const Color(0xFF8FBC8F), Icons.check_circle_outline_rounded),
        const SizedBox(width: 12),
        _buildStatCard('Diseased', diseased.toString(), const Color(0xFFFF5252), Icons.error_outline_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: GlossyCard(
        fillOpacity: 0.05,
        borderOpacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(int healthy, int diseased) {
    if (healthy == 0 && diseased == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data yet', style: TextStyle(color: Colors.grey))),
      );
    }

    final total = (healthy + diseased).toDouble();
    final healthyPct = total > 0 ? (healthy / total) * 100 : 0.0;
    final diseasedPct = total > 0 ? (diseased / total) * 100 : 0.0;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 8,
              centerSpaceRadius: 48,
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!mounted) return;
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sections: [
                PieChartSectionData(
                  value: healthy.toDouble(),
                  color: const Color(0xFF8FBC8F),
                  radius: _touchedIndex == 0 ? 70 : 60,
                  title: _touchedIndex == 0 ? '${healthyPct.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  borderSide: const BorderSide(color: Color(0xFFF8FAF5), width: 2),
                ),
                PieChartSectionData(
                  value: diseased.toDouble(),
                  color: const Color(0xFFFF5252),
                  radius: _touchedIndex == 1 ? 70 : 60,
                  title: _touchedIndex == 1 ? '${diseasedPct.toStringAsFixed(0)}%' : '',
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  borderSide: const BorderSide(color: Color(0xFFF8FAF5), width: 2),
                ),
              ],
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendDot(const Color(0xFF8FBC8F), 'Healthy ${healthyPct.toStringAsFixed(0)}%'),
            const SizedBox(width: 16),
            _buildLegendDot(const Color(0xFFFF5252), 'Diseased ${diseasedPct.toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildDiseaseList(List<dynamic> diseases) {
    if (diseases.isEmpty) {
      return GlossyCard(
        child: const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('No data recorded yet', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    return Column(
      children: diseases.map((item) {
        final disease = item['disease'] ?? 'Unknown';
        final count = item['count'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlossyCard(
            fillOpacity: 0.05,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bug_report_outlined, color: Color(0xFFFF5252), size: 22),
              ),
              title: Text(
                disease,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F3D2B),
                    ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F3D2B),
                      ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlossyCard(
          fillOpacity: 0.06,
          borderOpacity: 0.08,
          useBlur: false,
          gradientColors: [
            widget.color.withValues(alpha: 0.06),
            Colors.white70,
          ],
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F3D2B),
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                                height: 1.1,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
