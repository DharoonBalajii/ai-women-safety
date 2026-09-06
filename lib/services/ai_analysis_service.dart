import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../models/ambient_threat_assessment.dart';
import '../models/threat_level.dart';
import '../models/threat_type.dart';
import '../models/voice_analysis_result.dart';

/// Calls this app's own backend for every voice/text/ambient analysis —
/// the backend holds the Sarvam key (admin-provisioned, never shipped in
/// the app) and proxies to Sarvam on the app's behalf. Every method stays
/// honest about failure the same way the backend does: a request that
/// didn't get a real classification returns `analyzed: false` with a
/// plain-language reason, never a guess.
class AiAnalysisService {
  static const _timeout = Duration(seconds: 25);

  Future<VoiceAnalysisResult> analyzeVoiceClip(File? audioFile) async {
    if (audioFile == null) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: 'No audio was captured for this update.',
        analyzed: false,
      );
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$backendBaseUrl/ai/voice'))
        ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      final response = await http.Response.fromStream(await request.send().timeout(_timeout));
      return _parseVoiceResponse(response);
    } catch (_) {
      return const VoiceAnalysisResult(
        transcript: '',
        summary: "Couldn't reach the server to analyze this recording.",
        analyzed: false,
      );
    }
  }

  Future<VoiceAnalysisResult> analyzeTextMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const VoiceAnalysisResult(transcript: '', summary: 'No message was entered.', analyzed: false);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$backendBaseUrl/ai/text'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': trimmed}),
          )
          .timeout(_timeout);
      return _parseVoiceResponse(response, fallbackTranscript: trimmed);
    } catch (_) {
      return VoiceAnalysisResult(
        transcript: trimmed,
        summary: 'Reported: "$trimmed" — could not reach the server to analyze it.',
        analyzed: false,
      );
    }
  }

  Future<AmbientThreatAssessment> assessAmbientAudio(File? audioFile) async {
    final now = DateTime.now();
    if (audioFile == null) {
      return AmbientThreatAssessment(reason: 'No audio was captured this cycle.', timestamp: now, analyzed: false);
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$backendBaseUrl/ai/ambient'))
        ..files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
      final response = await http.Response.fromStream(await request.send().timeout(_timeout));
      if (response.statusCode != 200) {
        return AmbientThreatAssessment(
          reason: 'Ambient audio analysis failed for this cycle.',
          timestamp: now,
          analyzed: false,
        );
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return AmbientThreatAssessment(
        analyzed: body['analyzed'] as bool? ?? false,
        transcript: body['transcript'] as String? ?? '',
        level: ThreatLevelX.fromNameOrNull(body['level'] as String?),
        reason: body['reason'] as String? ?? 'Ambient audio assessed.',
        timestamp: now,
      );
    } catch (_) {
      return AmbientThreatAssessment(
        reason: 'Ambient monitoring needs a Sarvam AI key — add one in Profile.',
        timestamp: now,
        analyzed: false,
      );
    }
  }

  VoiceAnalysisResult _parseVoiceResponse(http.Response response, {String fallbackTranscript = ''}) {
    if (response.statusCode != 200) {
      return VoiceAnalysisResult(
        transcript: fallbackTranscript,
        summary: 'Analysis failed (server returned ${response.statusCode}).',
        analyzed: false,
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return VoiceAnalysisResult(
      analyzed: body['analyzed'] as bool? ?? false,
      transcript: body['transcript'] as String? ?? fallbackTranscript,
      detectedLanguage: body['detectedLanguage'] as String?,
      threatType: ThreatTypeX.fromNameOrNull(body['threatType'] as String?),
      summary: body['summary'] as String? ?? '',
    );
  }
}

final aiAnalysisService = AiAnalysisService();
