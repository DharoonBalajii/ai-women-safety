import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Thin wrapper around the `record` plugin for capturing a short voice
/// clip to hand to [SarvamAIService]. Every call is defensive: a denied
/// mic permission or an unsupported platform (e.g. this app's own web
/// preview, where `dart:io.File` isn't available) should fall back to "no
/// clip captured" rather than crash an active emergency session.
class VoiceCaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  Future<void> startRecording() async {
    if (kIsWeb) return;
    try {
      if (!await hasPermission()) return;
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/sos_clip_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
    } catch (_) {
      // No-op: the analysis step reports "no audio captured" when no clip exists.
    }
  }

  /// Stops recording and returns the recorded file, or null if nothing
  /// was captured (e.g. on web/unsupported platforms or denied mic access).
  Future<File?> stopRecording() async {
    if (kIsWeb) return null;
    try {
      final path = await _recorder.stop();
      if (path == null) return null;
      final file = File(path);
      return file.existsSync() ? file : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() => _recorder.dispose();
}
