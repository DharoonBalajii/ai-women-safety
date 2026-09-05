import 'threat_level.dart';

/// One cycle's result from listening to a short window of ambient audio.
///
/// [analyzed] mirrors [VoiceAnalysisResult.analyzed]: true only when Sarvam
/// actually judged real, transcribed audio. When it's false — no audio, no
/// key configured, silence, a failed request — [level] stays null. A null
/// level must never be treated as "no threat"; it means no judgment was
/// made, and the UI and provider must show and act on that distinction,
/// not paper over it with an assumed-safe default.
class AmbientThreatAssessment {
  final ThreatLevel? level;
  final String reason;
  final String transcript;
  final DateTime timestamp;
  final bool analyzed;

  const AmbientThreatAssessment({
    required this.reason,
    required this.timestamp,
    required this.analyzed,
    this.level,
    this.transcript = '',
  });
}
