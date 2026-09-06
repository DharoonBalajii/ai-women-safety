import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/emergency_incident.dart';
import '../models/threat_type.dart';
import '../providers/emergency_provider.dart';
import '../theme/home_theme.dart';
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
        return HomeColors.sosCrimson;
      case IncidentStatus.resolved:
        return HomeColors.statusGreen;
      case IncidentStatus.cancelled:
        return HomeColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<EmergencyProvider>().history;

    return Scaffold(
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text('Activity', style: HomeText.title()),
      ),
      body: history.isEmpty
          ? Center(
              child: Text('No past incidents yet.', style: HomeText.body()),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final incident = history[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => IncidentDetailScreen(incident: incident)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: HomeColors.cardBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: _statusColor(incident.status), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(incident.threatType.label, style: HomeText.cardTitle()),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM d, HH:mm').format(incident.startTime.toLocal()),
                                style: HomeText.caption(),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          incident.status.name.toUpperCase(),
                          style: HomeText.caption(color: _statusColor(incident.status)).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
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
      backgroundColor: HomeColors.appBg,
      appBar: AppBar(
        backgroundColor: HomeColors.appBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HomeColors.textPrimary),
        title: Text(incident.threatType.label, style: HomeText.title()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HomeColors.cardBorder),
            ),
            child: Text(
              incident.aiSummary.isNotEmpty ? incident.aiSummary : 'No AI summary for this incident.',
              style: HomeText.body(color: HomeColors.textPrimary),
            ),
          ),
          const SizedBox(height: 20),
          Text('TIMELINE', style: HomeText.eyebrow()),
          const SizedBox(height: 10),
          IncidentTimeline(updates: incident.updates, light: true),
        ],
      ),
    );
  }
}
