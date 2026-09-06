import 'package:flutter/material.dart';

import '../theme/home_theme.dart';

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
        return HomeColors.statusGreen;
      case ThreatLevel.caution:
        return HomeColors.caution;
      case ThreatLevel.danger:
        return HomeColors.sosCrimson;
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

  /// Unlike [fromName], never defaults to "none" — a missing/unrecognized
  /// name means no real judgment was made, which callers must treat as
  /// unanalyzed, not as a confirmed-safe verdict.
  static ThreatLevel? fromNameOrNull(String? name) {
    if (name == null) return null;
    for (final level in ThreatLevel.values) {
      if (level.name == name) return level;
    }
    return null;
  }
}
