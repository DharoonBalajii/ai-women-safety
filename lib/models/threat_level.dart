import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Assessed danger level of a short window of ambient/background audio,
/// as distinct from [ThreatType] (which classifies what a *reporter* says
/// happened). This is about what the AI overheard, unprompted.
enum ThreatLevel { none, caution, danger }

extension ThreatLevelX on ThreatLevel {
  String get label {
    switch (this) {
      case ThreatLevel.none:
        return 'No threat detected';
      case ThreatLevel.caution:
        return 'Elevated — possible concern';
      case ThreatLevel.danger:
        return 'Danger detected';
    }
  }

  Color get color {
    switch (this) {
      case ThreatLevel.none:
        return AppColors.signalTeal;
      case ThreatLevel.caution:
        return AppColors.beaconAmber;
      case ThreatLevel.danger:
        return AppColors.alarmRed;
    }
  }

  IconData get icon {
    switch (this) {
      case ThreatLevel.none:
        return Icons.check_circle_outline;
      case ThreatLevel.caution:
        return Icons.error_outline;
      case ThreatLevel.danger:
        return Icons.warning_rounded;
    }
  }

  static ThreatLevel fromName(String? name) {
    return ThreatLevel.values.firstWhere((t) => t.name == name, orElse: () => ThreatLevel.none);
  }
}
