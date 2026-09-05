import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

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
