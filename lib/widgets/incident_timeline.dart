import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident_update.dart';
import '../theme/home_theme.dart';

/// A real chronological log of what's been reported so far — ordering
/// here carries actual meaning, unlike a decorative numbered list.
class IncidentTimeline extends StatelessWidget {
  final List<IncidentUpdate> updates;

  const IncidentTimeline({super.key, required this.updates});

  Color _dotColor(UpdateSource source) {
    switch (source) {
      case UpdateSource.voice:
      case UpdateSource.textInput:
        return HomeColors.brandTeal;
      case UpdateSource.silentOption:
      case UpdateSource.ambient:
        return HomeColors.sosCrimson;
      case UpdateSource.system:
        return HomeColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HomeColors.cardBorder),
        ),
        child: Text('No updates yet.', style: HomeText.body()),
      );
    }

    final ordered = updates.reversed.toList();
    return Column(
      children: ordered.map((update) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _dotColor(update.source), shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(update.text, style: HomeText.body(color: HomeColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm:ss').format(update.timestamp.toLocal()),
                      style: HomeText.caption(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
