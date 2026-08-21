import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/companion_provider.dart';
import '../models/companion_session_model.dart';

class CompanionDashboardScreen extends StatefulWidget {
  const CompanionDashboardScreen({super.key});

  @override
  State<CompanionDashboardScreen> createState() =>
      _CompanionDashboardScreenState();
}

class _CompanionDashboardScreenState extends State<CompanionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CompanionProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanionProvider>(
      builder: (context, provider, child) {
        if (!provider.isCompanion) {
          return _buildRegistrationScreen(context, provider);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Companion Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => provider.initialize(),
              ),
            ],
          ),
          body: Column(
            children: [
              // SOS Alerts Banner
              if (provider.sosAlerts.isNotEmpty)
                _buildSOSAlertBanner(provider.sosAlerts.length),

              // Stats
              _buildStatsBar(provider),

              // Active Sessions
              Expanded(
                child: provider.activeSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.activeSessions.length,
                        itemBuilder: (context, index) {
                          return _buildSessionCard(
                            provider.activeSessions[index],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Registration screen for new companions
  Widget _buildRegistrationScreen(
    BuildContext context,
    CompanionProvider provider,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Companion Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.people,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Become a Companion',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Monitor your friends and family safety sessions in real-time.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Your Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final success = await provider.registerAsCompanion(
                    displayName: nameController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                  );
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Registered as Companion!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Register as Companion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SOS Alert Banner
  Widget _buildSOSAlertBanner(int alertCount) {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$alertCount ACTIVE SOS ALERT${alertCount > 1 ? 'S' : ''}!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Stats Bar
  Widget _buildStatsBar(CompanionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Watching', '${provider.monitoringUserIds.length}'),
          _buildStat('Active Sessions', '${provider.activeSessions.length}'),
          _buildStat('SOS Alerts', '${provider.sosAlerts.length}'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Session Card
  Widget _buildSessionCard(CompanionSessionModel session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: session.isSOS ? Colors.red : Colors.green,
          child: Icon(
            session.isSOS ? Icons.warning : Icons.directions_walk,
            color: Colors.white,
          ),
        ),
        title: Text(
          session.primaryUserName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.destinationAddress.isNotEmpty
                  ? 'To: ${session.destinationAddress}'
                  : 'Walking',
            ),
            Text(
              'Started: ${session.startTime.toString().substring(11, 16)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: session.isSOS
            ? const Icon(Icons.warning, color: Colors.red, size: 30)
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No active sessions',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'You will see sessions here when people you monitor start walking',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
