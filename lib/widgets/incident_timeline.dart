import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident_update.dart';
import '../theme/app_theme.dart';
import '../theme/home_theme.dart';

/// A real chronological log of what's been reported so far — ordering
/// here carries actual meaning, unlike a decorative numbered list.
///
/// Used on both the dark live-emergency screen and the light history
/// screen, so every color/text style is passed in rather than hardcoded —
/// [light] selects a sensible default set for whichever screen didn't
/// pass its own.
class IncidentTimeline extends StatelessWidget {
  final List<IncidentUpdate> updates;
  final bool light;

  const IncidentTimeline({super.key, required this.updates, this.light = false});

  Color _dotColor(UpdateSource source) {
    if (light) {
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
    switch (source) {
      case UpdateSource.voice:
      case UpdateSource.textInput:
        return AppColors.beaconAmber;
      case UpdateSource.silentOption:
      case UpdateSource.ambient:
        return AppColors.alarmRed;
      case UpdateSource.system:
        return AppColors.paperMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = light ? HomeText.body(color: HomeColors.textPrimary) : AppText.textTheme.bodyLarge;
    final captionStyle = light ? HomeText.caption() : AppText.mono(fontSize: 11);
    final emptyStyle = light ? HomeText.body() : AppText.textTheme.bodyMedium;

    if (updates.isEmpty) {
      if (light) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomeColors.cardBorder),
          ),
          child: Text('No updates yet.', style: emptyStyle),
        );
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('No updates yet.', style: emptyStyle),
        ),
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
                    Text(update.text, style: textStyle),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm:ss').format(update.timestamp.toLocal()),
                      style: captionStyle,
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
