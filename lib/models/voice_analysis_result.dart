import 'threat_type.dart';

/// Structured emergency context produced from a voice clip or typed report.
///
/// [analyzed] is the load-bearing field: it's true only when Sarvam actually
/// classified real input. Whenever real analysis wasn't possible — no audio,
/// no key configured, empty transcript, a failed request — [analyzed] is
/// false, [threatType] is left null, and [summary] says plainly what
/// happened instead of inventing a classification. Callers must never treat
/// an unanalyzed result as a threat verdict of any kind, "none" included.
class VoiceAnalysisResult {
  final String transcript;
  final String? detectedLanguage;
  final ThreatType? threatType;
  final String summary;
  final bool analyzed;

  const VoiceAnalysisResult({
    required this.transcript,
    required this.summary,
    required this.analyzed,
    this.threatType,
    this.detectedLanguage,
  });
}
