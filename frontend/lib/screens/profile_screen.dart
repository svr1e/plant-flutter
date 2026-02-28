import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/plant_provider.dart';
import '../widgets/glossy_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final plantProvider = context.watch<PlantProvider>();
    final user = authProvider.user;
    final stats = plantProvider.stats;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Profile',
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  GlossyCard(
                    fillOpacity: 0.08,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F3D2B).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1F3D2B).withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                user?.fullName?[0].toUpperCase() ?? user?.username[0].toUpperCase() ?? 'G',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F3D2B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? user?.username ?? 'Gardener',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F3D2B),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'No email set',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
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
                  
                  // Gardening Stats Header
                  Text(
                    'Gardening Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F3D2B),
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatItem(
                        context,
                        'Total Diagnoses',
                        stats?['total_diagnoses']?.toString() ?? '0',
                        Icons.analytics_rounded,
                        const Color(0xFF1F3D2B),
                      ),
                      _buildStatItem(
                        context,
                        'Healthy Plants',
                        stats?['healthy_plants']?.toString() ?? '0',
                        Icons.check_circle_rounded,
                        const Color(0xFF8FBC8F),
                      ),
                      _buildStatItem(
                        context,
                        'Diseased Plants',
                        stats?['diseased_plants']?.toString() ?? '0',
                        Icons.coronavirus_rounded,
                        const Color(0xFFFF5252),
                      ),
                      _buildStatItem(
                        context,
                        'Days Active',
                        '30+', // Mock data for now
                        Icons.calendar_today_rounded,
                        const Color(0xFFF4C430),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Account Actions
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F3D2B),
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildAccountAction(
                    context,
                    'Edit Profile',
                    Icons.person_outline_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile coming soon!')),
                      );
                    },
                  ),
                  _buildAccountAction(
                    context,
                    'Notifications',
                    Icons.notifications_none_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification settings coming soon!')),
                      );
                    },
                  ),
                  _buildAccountAction(
                    context,
                    'Security',
                    Icons.security_rounded,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Security settings coming soon!')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutConfirm(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade100),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return GlossyCard(
      fillOpacity: 0.05,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F3D2B),
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountAction(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F3D2B).withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF1F3D2B), size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F3D2B),
                    ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pop(dialogContext);
            },
            child: const Text('LOGOUT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
