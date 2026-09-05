import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/ambient_threat_assessment.dart';
import '../models/threat_level.dart';
import '../models/threat_type.dart';
import '../models/voice_analysis_result.dart';

/// Wraps Sarvam AI's speech-to-text + chat-completion APIs to turn a raw
/// voice clip into structured emergency context.
///
/// Runs in "mock mode" whenever no API key is configured yet, so the app
/// is fully demoable before real credentials are wired in. Swap in a real
/// key via [SettingsService] and every call below becomes a live request.
class SarvamAIService {
  static const _sttUrl = 'https://api.sarvam.ai/speech-to-text';
  static const _chatUrl = 'https://api.sarvam.ai/v1/chat/completions';

  final String? apiKey;

  SarvamAIService({this.apiKey});

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  static const _systemPrompt = '''
You are an emergency triage assistant for a women's safety app. Given a
short transcript spoken by someone in a possible emergency, respond with
ONLY a compact JSON object, no prose, in this exact shape:
{"threat_type": "following|threatened|medical|accident|harassment|unknown",
 "summary": "one short sentence describing what is happening, in English"}
''';

  static const _ambientSystemPrompt = '''
You are a covert threat-detection assistant. A phone belonging to a
person who may be in danger is silently recording ambient audio nearby.
Given a short transcript of what it overheard — someone else's speech,
not the phone owner's — judge whether it indicates the phone owner is
being threatened, restrained, silenced, or coerced by someone present.

Respond with ONLY a compact JSON object, no prose, in this exact shape:
{"level": "none|caution|danger", "reason": "one short sentence, in English"}

Guidance:
- "danger": clear signs of restraint, coercion, threats, silencing, or
  forced movement directed at the phone owner or someone with them —
  e.g. "make her quiet", "tie her up", "get in the car", "don't scream",
  "shut up", "don't move".
- "caution": tense, aggressive, or ambiguous language that could precede
  danger but is not explicit yet.
- "none": ordinary conversation — food, work, errands, small talk,
  directions — with nothing indicating threat or coercion. Most everyday
  conversation is "none"; do not over-flag it.

Judge the meaning of the whole transcript, not isolated words.
''';

  /// Sends a recorded clip to Sarvam speech-to-text, then to Sarvam chat
  /// completion to extract structured emergency context. Falls back to a
  /// deterministic local mock when [isConfigured] is false or a request
  /// fails, so the SOS flow never blocks on network/API issues.
  Future<VoiceAnalysisResult> analyzeVoiceClip(File? audioFile) async {
    if (audioFile == null) {
      return _mockAnalysis(seed: DateTime.now().toIso8601String());
    }
    if (!isConfigured) {
      return _mockAnalysis(seed: audioFile.path);
    }

    try {
      final transcriptResult = await _transcribe(audioFile);
      final transcript = transcriptResult.$1;
      final language = transcriptResult.$2;

      if (transcript.trim().isEmpty) {
        return _mockAnalysis(seed: audioFile.path, transcript: transcript, language: language);
      }

      final context = await _extractContext(transcript);
      return VoiceAnalysisResult(
        transcript: transcript,
        detectedLanguage: language,
        threatType: context.$1,
        summary: context.$2,
      );
    } catch (_) {
      return _mockAnalysis(seed: audioFile.path);
    }
  }

  /// (transcript, languageCode)
  Future<(String, String?)> _transcribe(File audioFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_sttUrl))
      ..headers['api-subscription-key'] = apiKey!
      ..fields['language_code'] = 'unknown'
      ..fields['model'] = 'saaras:v3'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Sarvam STT failed: ${response.statusCode} ${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['transcript'] as String? ?? '', body['language_code'] as String?);
  }

  /// (threatType, summary)
  Future<(ThreatType, String)> _extractContext(String transcript) async {
    final response = await http
        .post(
          Uri.parse(_chatUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'api-subscription-key': apiKey!,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'sarvam-105b-conversations',
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': transcript},
            ],
            'temperature': 0.1,
            'max_tokens': 150,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Sarvam chat failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    final parsed = jsonDecode(content.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

    return (
      ThreatTypeX.fromName(parsed['threat_type'] as String?),
      parsed['summary'] as String? ?? transcript,
    );
  }

  /// Listens to a short window of ambient audio (not a deliberate report)
  /// and judges whether it indicates the phone owner is in danger from
  /// someone present — the "make her quiet" / "tie her up" vs. ordinary
  /// chatter distinction. Silent by design: never speaks, never prompts,
  /// just watches and escalates. Falls back to a phrase-based heuristic
  /// offline so the concept still demos without a live connection.
  Future<AmbientThreatAssessment> assessAmbientAudio(File? audioFile) async {
    final now = DateTime.now();
    if (audioFile == null) {
      return AmbientThreatAssessment(
        level: ThreatLevel.none,
        reason: 'No audio captured this cycle.',
        transcript: '',
        timestamp: now,
        wasMocked: true,
      );
    }

    String transcript = '';
    try {
      if (isConfigured) {
        final result = await _transcribe(audioFile);
        transcript = result.$1;
      }
    } catch (_) {
      // Falls through to the heuristic below with an empty transcript.
    }

    if (!isConfigured || transcript.trim().isEmpty) {
      return _heuristicThreatLevel(transcript, timestamp: now);
    }

    try {
      final assessment = await _classifyThreatLevel(transcript);
      return AmbientThreatAssessment(
        level: assessment.$1,
        reason: assessment.$2,
        transcript: transcript,
        timestamp: now,
      );
    } catch (_) {
      return _heuristicThreatLevel(transcript, timestamp: now);
    }
  }

  /// (level, reason)
  Future<(ThreatLevel, String)> _classifyThreatLevel(String transcript) async {
    final response = await http
        .post(
          Uri.parse(_chatUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'api-subscription-key': apiKey!,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'sarvam-105b-conversations',
            'messages': [
              {'role': 'system', 'content': _ambientSystemPrompt},
              {'role': 'user', 'content': transcript},
            ],
            'temperature': 0.1,
            'max_tokens': 100,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Sarvam chat failed: ${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices'][0]['message']['content'] as String;
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    final parsed = jsonDecode(content.substring(jsonStart, jsonEnd + 1)) as Map<String, dynamic>;

    return (
      ThreatLevelX.fromName(parsed['level'] as String?),
      parsed['reason'] as String? ?? 'Ambient audio assessed.',
    );
  }

  /// Offline stand-in for [_classifyThreatLevel]: a curated phrase list
  /// covering the restraint/silencing/coercion language this feature
  /// exists to catch. Deliberately biased toward "none" — everyday
  /// conversation about food, work, or errands must not false-positive.
  static const _dangerPhrases = [
    'make her quiet', 'make him quiet', 'keep her quiet', 'keep him quiet',
    'shut her up', 'shut him up', 'shut up', 'stay quiet', "don't scream",
    'do not scream', "don't shout", "don't move", 'tie her up', 'tie him up',
    'tie her hands', 'get in the car', 'grab her', 'grab him', 'hold her down',
    "don't make a sound", 'stop struggling', 'give me your phone',
  ];
  static const _cautionPhrases = [
    "hurry up", "someone's coming", 'watch her', 'watch him', 'not here',
    'follow her', 'follow him', 'wait till she', 'wait till he',
  ];

  /// Without a live transcript (no key configured, or the mic/network
  /// failed this cycle) there's nothing real to judge — same problem
  /// [_mockAnalysis] solves for voice reports: rotate through plausible
  /// overheard snippets so the none/caution/danger distinction is still
  /// demonstrable end to end, mundane chatter included on purpose.
  static const _ambientSampleTranscripts = [
    'Did you remember to pick up vegetables for dinner tonight?',
    "Let's finish the homework before it gets too late.",
    'The meeting got pushed to three o\'clock tomorrow.',
    'Traffic is bad, we might be ten minutes late.',
    'Make her quiet, someone will hear us.',
    'Tie her up and get in the car, hurry.',
    "Don't scream or this gets worse for you.",
  ];

  AmbientThreatAssessment _heuristicThreatLevel(String transcript, {required DateTime timestamp}) {
    final isSimulated = transcript.trim().isEmpty;
    final effective = isSimulated
        ? _ambientSampleTranscripts[Random(timestamp.millisecondsSinceEpoch).nextInt(_ambientSampleTranscripts.length)]
        : transcript;

    final lower = effective.toLowerCase();
    ThreatLevel level = ThreatLevel.none;
    String reason = 'Ordinary conversation overheard: "$effective"';

    for (final phrase in _dangerPhrases) {
      if (lower.contains(phrase)) {
        level = ThreatLevel.danger;
        reason = 'Overheard language suggesting restraint or coercion: "$effective"';
        break;
      }
    }
    if (level == ThreatLevel.none) {
      for (final phrase in _cautionPhrases) {
        if (lower.contains(phrase)) {
          level = ThreatLevel.caution;
          reason = 'Tense or ambiguous language overheard: "$effective"';
          break;
        }
      }
    }

    return AmbientThreatAssessment(
      level: level,
      reason: isSimulated ? '[Demo mode] $reason' : reason,
      transcript: effective,
      timestamp: timestamp,
      wasMocked: true,
    );
  }

  /// Text-input counterpart to [analyzeVoiceClip], for when speaking aloud
  /// isn't safe or possible. Skips speech-to-text and sends the typed
  /// message straight to Sarvam chat completion for threat extraction —
  /// same mock-mode fallback, same structured result either way.
  Future<VoiceAnalysisResult> analyzeTextMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return _mockAnalysis(seed: DateTime.now().toIso8601String());
    }
    if (!isConfigured) {
      return _mockAnalysis(seed: trimmed, transcript: trimmed, language: 'en-IN', sourceLabel: 'text input');
    }

    try {
      final context = await _extractContext(trimmed);
      return VoiceAnalysisResult(
        transcript: trimmed,
        detectedLanguage: null,
        threatType: context.$1,
        summary: context.$2,
      );
    } catch (_) {
      return _mockAnalysis(seed: trimmed, transcript: trimmed, sourceLabel: 'text input');
    }
  }

  VoiceAnalysisResult _mockAnalysis({
    required String seed,
    String? transcript,
    String? language,
    String sourceLabel = 'voice input',
  }) {
    const sampleTranscripts = [
      'Someone has been following me since I left the station.',
      'A stranger is threatening me near the parking lot.',
      'I feel dizzy and I think I need medical help.',
      'There has been an accident, please send help.',
    ];
    final rng = Random(seed.hashCode);
    final pickedTranscript = transcript?.isNotEmpty == true
        ? transcript!
        : sampleTranscripts[rng.nextInt(sampleTranscripts.length)];

    ThreatType type;
    if (pickedTranscript.toLowerCase().contains('follow')) {
      type = ThreatType.following;
    } else if (pickedTranscript.toLowerCase().contains('threat')) {
      type = ThreatType.threatened;
    } else if (pickedTranscript.toLowerCase().contains('dizzy') ||
        pickedTranscript.toLowerCase().contains('medical')) {
      type = ThreatType.medical;
    } else if (pickedTranscript.toLowerCase().contains('accident')) {
      type = ThreatType.accident;
    } else {
      type = ThreatType.unknown;
    }

    return VoiceAnalysisResult(
      transcript: pickedTranscript,
      detectedLanguage: language ?? 'en-IN',
      threatType: type,
      summary: '[Demo mode] ${type.label} detected from $sourceLabel.',
      wasMocked: true,
    );
  }
}
