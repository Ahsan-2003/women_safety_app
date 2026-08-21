import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:women_safety_app/providers/fcm_provider.dart';
import 'package:women_safety_app/providers/offline_manager_provider.dart';
import 'package:women_safety_app/providers/sos_provider.dart';
import 'package:women_safety_app/screens/checkin_timer_screen.dart';
import 'package:women_safety_app/screens/companion_dashboard_screen.dart';
import 'package:women_safety_app/screens/fake_call_screen.dart';
import 'package:women_safety_app/screens/route_monitoring_screen.dart';
import 'package:women_safety_app/screens/session_history_screen.dart';
import 'package:women_safety_app/screens/sos_screen.dart';
import 'package:women_safety_app/screens/start_session_screen.dart';
import 'package:women_safety_app/widgets/offline_status_widget.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM and Offline Manager when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FCMProvider>(context, listen: false).initialize();
      Provider.of<OfflineManagerProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shield,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'SafeWalk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          // Sign Out Button in App Bar
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () => _showSignOutDialog(context, authProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline Status Banner
          const OfflineStatusWidget(),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh data if needed
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // Welcome Header
                    _buildWelcomeHeader(context, authProvider),

                    const SizedBox(height: 20),

                    // Quick Actions Section
                    _buildSectionTitle(context, 'Quick Actions'),
                    const SizedBox(height: 10),

                    // Emergency SOS Card (Prominent)
                    _buildSOSCard(context),

                    const SizedBox(height: 16),

                    // Main Features Grid
                    _buildFeaturesGrid(context),

                    const SizedBox(height: 20),

                    // Session History
                    _buildSectionTitle(context, 'Safety Tools'),
                    const SizedBox(height: 10),

                    // Additional Tools
                    _buildAdditionalTools(context),

                    const SizedBox(height: 20),

                    // Version Info
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Welcome Header
  Widget _buildWelcomeHeader(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.user?.phoneNumber ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.greenAccent, size: 24),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // SOS Card (Prominent)
  Widget _buildSOSCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SOSScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade600, Colors.red.shade400],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS EMERGENCY',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap for immediate help',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // Features Grid (2x2)
  Widget _buildFeaturesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildFeatureCard(
          context,
          icon: Icons.directions_walk,
          title: 'Walk With Me',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StartSessionScreen()),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.timer,
          title: 'Check-in Timer',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckinTimerScreen()),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.phone_in_talk,
          title: 'Fake Call',
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FakeCallScreen()),
            );
          },
        ),
        _buildFeatureCard(
          context,
          icon: Icons.route,
          title: 'Route Monitor',
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RouteMonitoringScreen()),
            );
          },
        ),
      ],
    );
  }

  // Feature Card
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Additional Tools List
  Widget _buildAdditionalTools(BuildContext context) {
    return Column(
      children: [
        _buildListTile(
          context,
          icon: Icons.people,
          title: 'Trusted Contacts',
          subtitle: 'Manage emergency contacts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactsScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildListTile(
          context,
          icon: Icons.history,
          title: 'Session History',
          subtitle: 'View your past walks',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
            );
          },
        ),

        const SizedBox(height: 10),

        _buildListTile(
          context,
          icon: Icons.people,
          title: 'Companion Mode',
          subtitle: 'Monitor friends and family',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompanionDashboardScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  // List Tile
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  // Sign Out Dialog
  Future<void> _showSignOutDialog(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
