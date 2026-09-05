import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_incident.dart';
import '../models/incident_update.dart';
import '../models/location_point.dart';
import '../models/safe_place.dart';
import '../models/threat_type.dart';
import '../models/trusted_contact.dart';
import '../models/voice_analysis_result.dart';
import '../services/alert_service.dart';
import '../services/incident_store.dart';
import '../services/location_service.dart';
import '../services/safe_zone_service.dart';
import '../services/sarvam_ai_service.dart';
import '../services/settings_service.dart';
import '../services/voice_capture_service.dart';

/// Orchestrates a live emergency session: location capture, voice ->
/// Sarvam AI analysis, the live incident timeline, simulated responder
/// dispatch, and persistence of resolved/cancelled incidents to history.
class EmergencyProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final VoiceCaptureService _voiceCaptureService = VoiceCaptureService();
  final SafeZoneService _safeZoneService = SafeZoneService();
  final SettingsService _settingsService = SettingsService();
  final IncidentStore _incidentStore = IncidentStore();
  final AlertService alertService = AlertService();
  final _uuid = const Uuid();

  EmergencyIncident? _activeIncident;
  List<SafePlace> _safePlaces = [];
  bool _isRecordingVoice = false;
  bool _isAnalyzingVoice = false;
  bool _isAnalyzingText = false;
  List<EmergencyIncident> _history = [];

  StreamSubscription<LocationPoint>? _locationSub;
  Timer? _responderTimer;

  bool _safePlacesLookupFailed = false;

  EmergencyIncident? get activeIncident => _activeIncident;
  bool get hasActiveIncident => _activeIncident != null;
  List<SafePlace> get safePlaces => List.unmodifiable(_safePlaces);
  bool get safePlacesLookupFailed => _safePlacesLookupFailed;
  bool get isRecordingVoice => _isRecordingVoice;
  bool get isAnalyzingVoice => _isAnalyzingVoice;
  bool get isAnalyzingText => _isAnalyzingText;
  List<EmergencyIncident> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    _history = await _incidentStore.load();
    notifyListeners();
  }

  Future<EmergencyIncident> triggerSilentSOS(ThreatType type) async {
    final incident = await _startIncident(type: type);
    incident.updates.add(IncidentUpdate(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      text: '${type.label} reported (silent mode).',
      source: UpdateSource.silentOption,
      location: incident.latestLocation,
    ));
    incident.aiSummary = '${type.label} reported via silent SOS.';
    await _persist();
    notifyListeners();
    return incident;
  }

  Future<EmergencyIncident> triggerVoiceSOS() async {
    return _startIncident(type: ThreatType.unknown);
  }

  Future<EmergencyIncident> _startIncident({required ThreatType type}) async {
    final location = await _locationService.getCurrentLocation();
    final incident = EmergencyIncident(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      threatType: type,
      locationTrail: location != null ? [location] : [],
    );
    _activeIncident = incident;
    _watchLocation();
    _simulateResponderProgress();
    unawaited(refreshSafePlaces());
    notifyListeners();
    return incident;
  }

  void _watchLocation() {
    _locationSub?.cancel();
    _locationSub = _locationService.watchLocation().listen((point) {
      _activeIncident?.locationTrail.add(point);
      notifyListeners();
    });
  }

  void _simulateResponderProgress() {
    _responderTimer?.cancel();
    final stages = [
      ResponderStage.detecting,
      ResponderStage.patrolIdentified,
      ResponderStage.controlRoomNotified,
      ResponderStage.responderAccepted,
      ResponderStage.dispatched,
      ResponderStage.respondedArrived,
    ];
    var stageIndex = 0;
    _responderTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      final incident = _activeIncident;
      if (incident == null || incident.status != IncidentStatus.active) {
        timer.cancel();
        return;
      }
      stageIndex++;
      if (stageIndex >= stages.length) {
        timer.cancel();
        return;
      }
      incident.responderStage = stages[stageIndex];
      incident.updates.add(IncidentUpdate(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        text: '[Simulated] ${stages[stageIndex].label}',
        source: UpdateSource.responder,
      ));
      notifyListeners();
    });
  }

  Future<void> refreshSafePlaces() async {
    final location = _activeIncident?.latestLocation ?? await _locationService.getCurrentLocation();
    if (location == null) {
      _safePlacesLookupFailed = true;
      notifyListeners();
      return;
    }
    _safePlacesLookupFailed = false;
    _safePlaces = await _safeZoneService.findNearbySafePlaces(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    notifyListeners();
  }

  Future<void> startVoiceRecording() async {
    _isRecordingVoice = true;
    notifyListeners();
    await _voiceCaptureService.startRecording();
  }

  Future<void> stopVoiceRecordingAndAnalyze() async {
    _isRecordingVoice = false;
    _isAnalyzingVoice = true;
    notifyListeners();

    final file = await _voiceCaptureService.stopRecording();
    final apiKey = await _settingsService.getSarvamApiKey();
    final sarvamService = SarvamAIService(apiKey: apiKey);

    final incident = _activeIncident ?? await _startIncident(type: ThreatType.unknown);

    final result = await sarvamService.analyzeVoiceClip(file);
    _applyAnalysisResult(incident, result, source: UpdateSource.voice);

    _isAnalyzingVoice = false;
    await _persist();
    notifyListeners();
  }

  /// Text-input counterpart to [stopVoiceRecordingAndAnalyze] — same Sarvam
  /// threat-extraction pipeline, used when speaking aloud isn't safe or
  /// possible. Either channel can start the incident if none is active yet.
  Future<void> sendTextUpdate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _isAnalyzingText = true;
    notifyListeners();

    final apiKey = await _settingsService.getSarvamApiKey();
    final sarvamService = SarvamAIService(apiKey: apiKey);
    final incident = _activeIncident ?? await _startIncident(type: ThreatType.unknown);

    final result = await sarvamService.analyzeTextMessage(trimmed);
    _applyAnalysisResult(incident, result, source: UpdateSource.textInput);

    _isAnalyzingText = false;
    await _persist();
    notifyListeners();
  }

  void _applyAnalysisResult(
    EmergencyIncident incident,
    VoiceAnalysisResult result, {
    required UpdateSource source,
  }) {
    incident.threatType = result.threatType;
    incident.aiSummary = result.summary;
    incident.updates.add(IncidentUpdate(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      text: result.summary,
      source: source,
      location: incident.latestLocation,
      rawTranscript: result.transcript,
      detectedLanguage: result.detectedLanguage,
    ));
  }

  Future<void> addManualUpdate(String text) async {
    final incident = _activeIncident;
    if (incident == null || text.trim().isEmpty) return;
    incident.updates.add(IncidentUpdate(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      text: text.trim(),
      source: UpdateSource.system,
      location: incident.latestLocation,
    ));
    await _persist();
    notifyListeners();
  }

  Future<void> notifyAllContacts(List<TrustedContact> contacts) async {
    final incident = _activeIncident;
    if (incident == null) return;
    for (final contact in contacts) {
      await alertService.notifyContact(contact, incident);
    }
  }

  Future<void> resolveIncident() async {
    final incident = _activeIncident;
    if (incident == null) return;
    incident.status = IncidentStatus.resolved;
    incident.endTime = DateTime.now();
    incident.updates.add(IncidentUpdate(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      text: 'Reached a safe place. Incident resolved.',
      source: UpdateSource.system,
    ));
    await _endIncident(incident);
  }

  Future<void> cancelIncident() async {
    final incident = _activeIncident;
    if (incident == null) return;
    incident.status = IncidentStatus.cancelled;
    incident.endTime = DateTime.now();
    await _endIncident(incident);
  }

  Future<void> _endIncident(EmergencyIncident incident) async {
    _locationSub?.cancel();
    _responderTimer?.cancel();
    await _incidentStore.upsert(incident);
    _activeIncident = null;
    await loadHistory();
    notifyListeners();
  }

  Future<void> _persist() async {
    final incident = _activeIncident;
    if (incident == null) return;
    await _incidentStore.upsert(incident);
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _responderTimer?.cancel();
    _voiceCaptureService.dispose();
    super.dispose();
  }
}
