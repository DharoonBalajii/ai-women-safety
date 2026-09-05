import 'threat_type.dart';

/// Structured emergency context produced from a voice clip:
/// raw transcript (Sarvam speech-to-text) + AI-extracted meaning
/// (Sarvam chat completion), e.g. "Someone has been following me"
/// -> ThreatType.following + a short situational summary.
class VoiceAnalysisResult {
  final String transcript;
  final String? detectedLanguage;
  final ThreatType threatType;
  final String summary;
  final bool wasMocked;

  const VoiceAnalysisResult({
    required this.transcript,
    required this.threatType,
    required this.summary,
    this.detectedLanguage,
    this.wasMocked = false,
  });
}
