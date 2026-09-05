import 'threat_level.dart';

/// One cycle's result from listening to a short window of ambient audio:
/// what was overheard, and the AI's judgment of whether it indicates the
/// phone's owner is in danger from someone present.
class AmbientThreatAssessment {
  final ThreatLevel level;
  final String reason;
  final String transcript;
  final DateTime timestamp;
  final bool wasMocked;

  const AmbientThreatAssessment({
    required this.level,
    required this.reason,
    required this.transcript,
    required this.timestamp,
    this.wasMocked = false,
  });
}
