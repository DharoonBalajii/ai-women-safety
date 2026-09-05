import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/emergency_incident.dart';
import '../models/threat_type.dart';
import '../providers/emergency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/incident_timeline.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EmergencyProvider>().loadHistory());
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.active:
        return AppColors.alarmRed;
      case IncidentStatus.resolved:
        return AppColors.signalTeal;
      case IncidentStatus.cancelled:
        return AppColors.paperMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<EmergencyProvider>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Incident history')),
      body: history.isEmpty
          ? Center(
              child: Text('No past incidents.', style: AppText.textTheme.bodyMedium),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final incident = history[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: _statusColor(incident.status), shape: BoxShape.circle),
                    ),
                    title: Text(incident.threatType.label, style: AppText.textTheme.bodyLarge),
                    subtitle: Text(
                      DateFormat('MMM d, HH:mm').format(incident.startTime.toLocal()),
                      style: AppText.textTheme.bodyMedium,
                    ),
                    trailing: Text(incident.status.name.toUpperCase(), style: AppText.mono(fontSize: 11)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => IncidentDetailScreen(incident: incident)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class IncidentDetailScreen extends StatelessWidget {
  final EmergencyIncident incident;
  const IncidentDetailScreen({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(incident.threatType.label)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(incident.aiSummary, style: AppText.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('TIMELINE', style: AppText.textTheme.labelMedium),
          const SizedBox(height: 8),
          IncidentTimeline(updates: incident.updates),
        ],
      ),
    );
  }
}
