import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ambient_threat_assessment.dart';
import '../models/threat_level.dart';
import '../models/threat_type.dart';
import '../models/voice_analysis_result.dart';

/// Wraps Sarvam AI's speech-to-text + chat-completion APIs to turn a raw
/// voice clip, typed report, or window of ambient audio into structured
/// emergency context.
///
/// Every method here is honest about uncertainty: if a real Sarvam key
/// isn't configured, or a request fails, or there's no clear audio to work
/// with, the result says so plainly (`analyzed: false`) instead of
/// inventing a transcript or a threat judgment. This app makes real safety
/// claims, so it never guesses and never fabricates evidence of an
/// emergency — or of safety — that wasn't actually observed.
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
  /// completion to extract structured emergency context. Returns an
  /// unanalyzed result — never a guess — if there's no clip, no key
  /// configured, no clear speech, or the request fails.
  Future<VoiceAnalysisResult> analyzeVoiceClip(File? audioFile) async {
    if (audioFile == null) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: 'No audio was captured for this update.',
        analyzed: false,
      );
    }
    if (!isConfigured) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: "Voice analysis isn't configured — add a Sarvam AI key in Profile to enable it.",
        analyzed: false,
      );
    }

    String transcript = '';
    String? language;
    try {
      final result = await _transcribe(audioFile);
      transcript = result.$1;
      language = result.$2;
    } catch (_) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: 'Voice analysis failed for this recording.',
        analyzed: false,
      );
    }

    if (transcript.trim().isEmpty) {
      return VoiceAnalysisResult(
        transcript: '',
        detectedLanguage: language,
        summary: 'No clear speech was captured in this recording.',
        analyzed: false,
      );
    }

    try {
      final context = await _extractContext(transcript);
      return VoiceAnalysisResult(
        transcript: transcript,
        detectedLanguage: language,
        threatType: context.$1,
        summary: context.$2,
        analyzed: true,
      );
    } catch (_) {
      return VoiceAnalysisResult(
        transcript: transcript,
        detectedLanguage: language,
        summary: 'Recorded: "$transcript" — AI analysis failed.',
        analyzed: false,
      );
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
  /// someone present. Returns an unanalyzed result — level left null,
  /// never defaulted to "safe" — whenever there's nothing real to judge.
  Future<AmbientThreatAssessment> assessAmbientAudio(File? audioFile) async {
    final now = DateTime.now();
    if (audioFile == null) {
      return AmbientThreatAssessment(
        reason: 'No audio was captured this cycle.',
        timestamp: now,
        analyzed: false,
      );
    }
    if (!isConfigured) {
      return AmbientThreatAssessment(
        reason: 'Ambient monitoring needs a Sarvam AI key — add one in Profile.',
        timestamp: now,
        analyzed: false,
      );
    }

    String transcript = '';
    try {
      final result = await _transcribe(audioFile);
      transcript = result.$1;
    } catch (_) {
      return AmbientThreatAssessment(
        reason: 'Ambient audio analysis failed for this cycle.',
        timestamp: now,
        analyzed: false,
      );
    }

    if (transcript.trim().isEmpty) {
      return AmbientThreatAssessment(
        reason: 'No clear audio was captured this cycle.',
        timestamp: now,
        analyzed: false,
      );
    }

    try {
      final assessment = await _classifyThreatLevel(transcript);
      return AmbientThreatAssessment(
        level: assessment.$1,
        reason: assessment.$2,
        transcript: transcript,
        timestamp: now,
        analyzed: true,
      );
    } catch (_) {
      return AmbientThreatAssessment(
        reason: 'Ambient audio analysis failed for this cycle.',
        transcript: transcript,
        timestamp: now,
        analyzed: false,
      );
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

  /// Text-input counterpart to [analyzeVoiceClip], for when speaking aloud
  /// isn't safe or possible. The typed message is real regardless of
  /// whether AI classification succeeds, so it's always reported verbatim;
  /// only [analyzed] and [threatType] reflect whether Sarvam actually
  /// classified it.
  Future<VoiceAnalysisResult> analyzeTextMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: 'No message was entered.',
        analyzed: false,
      );
    }
    if (!isConfigured) {
      return VoiceAnalysisResult(
        transcript: trimmed,
        summary: 'Reported: "$trimmed"',
        analyzed: false,
      );
    }

    try {
      final context = await _extractContext(trimmed);
      return VoiceAnalysisResult(
        transcript: trimmed,
        threatType: context.$1,
        summary: context.$2,
        analyzed: true,
      );
    } catch (_) {
      return VoiceAnalysisResult(
        transcript: trimmed,
        summary: 'Reported: "$trimmed" — AI analysis failed.',
        analyzed: false,
      );
    }
  }
}
