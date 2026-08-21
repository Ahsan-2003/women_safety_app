import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/session_history_model.dart';
import '../providers/session_history_provider.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionHistoryProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Sessions')),
              const PopupMenuItem(value: 'today', child: Text('Today')),
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
            ],
            onSelected: (value) {
              Provider.of<SessionHistoryProvider>(
                context,
                listen: false,
              ).setFilter(value);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearConfirmation,
          ),
        ],
      ),
      body: Consumer<SessionHistoryProvider>(
        builder: (context, provider, child) {
          // Stats Card
          return Column(
            children: [
              _buildStatsCard(provider),
              Expanded(
                child: provider.sessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.sessions.length,
                        itemBuilder: (context, index) {
                          final session = provider.sessions[index];
                          return _buildSessionCard(session);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Stats card
  Widget _buildStatsCard(SessionHistoryProvider provider) {
    final stats = provider.getStats();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            'Sessions',
            '${stats['totalSessions']}',
            Icons.directions_walk,
          ),
          _buildStat(
            'Distance',
            '${stats['totalDistance'].toStringAsFixed(1)}km',
            Icons.route,
          ),
          _buildStat('Safe', '${stats['safeSessions']}', Icons.check_circle),
          _buildStat('Alerts', '${stats['totalAlerts']}', Icons.warning),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  // Session card
  Widget _buildSessionCard(SessionHistoryModel session) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: session.completedSafely
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            session.completedSafely ? Icons.check : Icons.warning,
            color: session.completedSafely ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          session.destinationAddress.isNotEmpty
              ? session.destinationAddress
              : 'Walk Session',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${dateFormat.format(session.startTime)} at ${timeFormat.format(session.startTime)}',
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${session.durationMinutes} min | Distance: ${session.totalDistanceKm.toStringAsFixed(2)} km',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (session.alertsTriggered > 0) ...[
              const SizedBox(height: 4),
              Text(
                '⚠️ ${session.alertsTriggered} alert(s) triggered',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => _confirmDeleteSession(session),
        ),
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No sessions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your walk history will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Clear confirmation
  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'Are you sure you want to delete all session history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SessionHistoryProvider>(
                context,
                listen: false,
              ).clearAllSessions();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Delete confirmation
  void _confirmDeleteSession(SessionHistoryModel session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text('Delete session from ${session.startTime.toString()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SessionHistoryProvider>(
                context,
                listen: false,
              ).deleteSession(session.sessionId);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
