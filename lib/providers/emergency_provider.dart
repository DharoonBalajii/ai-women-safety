import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/ambient_threat_assessment.dart';
import '../models/emergency_incident.dart';
import '../models/incident_update.dart';
import '../models/location_point.dart';
import '../models/safe_place.dart';
import '../models/threat_level.dart';
import '../models/threat_type.dart';
import '../models/trusted_contact.dart';
import '../models/voice_analysis_result.dart';
import '../services/ai_analysis_service.dart';
import '../services/alert_service.dart';
import '../services/contacts_store.dart';
import '../services/incident_store.dart';
import '../services/location_service.dart';
import '../services/safe_zone_service.dart';
import '../services/voice_capture_service.dart';

/// Orchestrates a live emergency session: location capture, voice/text/
/// ambient Sarvam AI analysis, the live incident timeline, and persistence
/// of resolved/cancelled incidents to history. This app has no connection
/// to real emergency responders or a telecom SMS gateway — every action
/// here is something the app can actually do (locate, analyze, and reach
/// trusted contacts via the device's own SMS composer), nothing simulated.
class EmergencyProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final VoiceCaptureService _voiceCaptureService = VoiceCaptureService();
  final SafeZoneService _safeZoneService = SafeZoneService();
  final IncidentStore _incidentStore = IncidentStore();
  final ContactsStore _contactsStore = ContactsStore();
  final AlertService alertService = AlertService();
  final _uuid = const Uuid();

  EmergencyIncident? _activeIncident;
  List<SafePlace> _safePlaces = [];
  bool _isRecordingVoice = false;
  bool _isAnalyzingVoice = false;
  bool _isAnalyzingText = false;
  List<EmergencyIncident> _history = [];

  StreamSubscription<LocationPoint>? _locationSub;

  bool _ambientMonitoringEnabled = false;
  bool _ambientLoopRunning = false;
  bool _isAssessingAmbient = false;
  AmbientThreatAssessment? _latestAmbientAssessment;

  /// How long the app waits for a manual "I'm safe" after the AI flags
  /// something concerning, before treating silence itself as a signal and
  /// escalating on its own.
  static const checkInWindow = Duration(seconds: 30);
  AmbientThreatAssessment? _pendingCheckIn;
  Timer? _checkInTimer;
  int _checkInSecondsRemaining = 0;

  bool _safePlacesLookupFailed = false;

  EmergencyIncident? get activeIncident => _activeIncident;
  bool get hasActiveIncident => _activeIncident != null;
  List<SafePlace> get safePlaces => List.unmodifiable(_safePlaces);
  bool get safePlacesLookupFailed => _safePlacesLookupFailed;
  bool get isRecordingVoice => _isRecordingVoice;
  bool get isAnalyzingVoice => _isAnalyzingVoice;
  bool get isAnalyzingText => _isAnalyzingText;
  bool get isAmbientMonitoringEnabled => _ambientMonitoringEnabled;
  bool get isAssessingAmbient => _isAssessingAmbient;
  AmbientThreatAssessment? get latestAmbientAssessment => _latestAmbientAssessment;
  AmbientThreatAssessment? get pendingCheckIn => _pendingCheckIn;
  int get checkInSecondsRemaining => _checkInSecondsRemaining;
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
    _latestAmbientAssessment = null;
    _watchLocation();
    unawaited(refreshSafePlaces());
    startAmbientMonitoring();
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
    final incident = _activeIncident ?? await _startIncident(type: ThreatType.unknown);

    final result = await aiAnalysisService.analyzeVoiceClip(file);
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

    final incident = _activeIncident ?? await _startIncident(type: ThreatType.unknown);

    final result = await aiAnalysisService.analyzeTextMessage(trimmed);
    _applyAnalysisResult(incident, result, source: UpdateSource.textInput);

    _isAnalyzingText = false;
    await _persist();
    notifyListeners();
  }

  /// Only a real, [VoiceAnalysisResult.analyzed] result may change the
  /// incident's classification — an unanalyzed result (no key, no clear
  /// speech, a failed request) still gets logged honestly to the timeline,
  /// but never overwrites [EmergencyIncident.threatType] with a guess.
  void _applyAnalysisResult(
    EmergencyIncident incident,
    VoiceAnalysisResult result, {
    required UpdateSource source,
  }) {
    if (result.analyzed && result.threatType != null) {
      incident.threatType = result.threatType!;
      incident.aiSummary = result.summary;
    }
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

  /// How long each ambient listening window records before it's handed to
  /// Sarvam for assessment. Short enough to catch a spoken threat quickly,
  /// long enough to give the transcript real sentences to reason about.
  static const _ambientClipDuration = Duration(seconds: 8);

  /// Starts (or leaves running) the background listen-and-assess loop.
  /// Runs automatically for the life of an incident so danger is caught
  /// without anyone touching the phone — call [stopAmbientMonitoring] only
  /// if it should be deliberately turned off (e.g. a false alarm).
  void startAmbientMonitoring() {
    if (_ambientMonitoringEnabled) return;
    _ambientMonitoringEnabled = true;
    notifyListeners();
    if (!_ambientLoopRunning) {
      unawaited(_runAmbientLoop());
    }
  }

  void stopAmbientMonitoring() {
    _ambientMonitoringEnabled = false;
    notifyListeners();
  }

  Future<void> _runAmbientLoop() async {
    _ambientLoopRunning = true;
    try {
      while (_ambientMonitoringEnabled && _activeIncident != null) {
        // Yield the mic to a deliberate voice report rather than fighting it,
        // and pause new listening cycles while a check-in is unresolved —
        // one concern at a time.
        if (_isRecordingVoice || _pendingCheckIn != null) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        await _voiceCaptureService.startRecording();
        await Future.delayed(_ambientClipDuration);

        if (!_ambientMonitoringEnabled || _activeIncident == null) {
          await _voiceCaptureService.stopRecording();
          break;
        }

        final clip = await _voiceCaptureService.stopRecording();
        _isAssessingAmbient = true;
        notifyListeners();

        final assessment = await aiAnalysisService.assessAmbientAudio(clip);

        _isAssessingAmbient = false;
        _latestAmbientAssessment = assessment;

        // Only a real, analyzed danger/caution judgment ever means
        // anything — an unanalyzed cycle (silence, a failed request) is
        // shown live but never acted on, and "none" is a real judgment,
        // not the default for "we don't know". A real concern doesn't
        // escalate immediately: it asks the person first.
        if (assessment.analyzed &&
            assessment.level != null &&
            assessment.level != ThreatLevel.none) {
          _startCheckIn(assessment);
        }
        notifyListeners();
      }
    } finally {
      _ambientLoopRunning = false;
    }
  }

  /// Starts the "are you okay?" window after the AI flags something
  /// concerning. Confirmed safe ([confirmSafeFromCheckIn]) logs it quietly
  /// and monitoring resumes; silence for [checkInWindow] is itself treated
  /// as a signal — [_resolveCheckInTimeout] escalates and reaches out to
  /// trusted contacts on the assumption that no response may mean no one
  /// was able to respond.
  void _startCheckIn(AmbientThreatAssessment assessment) {
    _pendingCheckIn = assessment;
    _checkInSecondsRemaining = checkInWindow.inSeconds;
    HapticFeedback.heavyImpact();
    notifyListeners();

    _checkInTimer?.cancel();
    _checkInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkInSecondsRemaining--;
      if (_checkInSecondsRemaining <= 0) {
        timer.cancel();
        unawaited(_resolveCheckInTimeout());
      } else {
        notifyListeners();
      }
    });
  }

  /// Called when the person taps "I'm safe" during the check-in window.
  Future<void> confirmSafeFromCheckIn() async {
    if (_pendingCheckIn == null) return;
    _checkInTimer?.cancel();
    _pendingCheckIn = null;
    _checkInSecondsRemaining = 0;

    final incident = _activeIncident;
    if (incident != null) {
      incident.updates.add(IncidentUpdate(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        text: "AI flagged a possible concern — you confirmed you're safe.",
        source: UpdateSource.ambient,
      ));
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _resolveCheckInTimeout() async {
    final assessment = _pendingCheckIn;
    _pendingCheckIn = null;
    _checkInSecondsRemaining = 0;

    final incident = _activeIncident;
    if (assessment == null || incident == null) {
      notifyListeners();
      return;
    }

    incident.updates.add(IncidentUpdate(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      text: '[AI listening] ${assessment.reason} — no response to check-in; '
          'notifying trusted contacts.',
      source: UpdateSource.ambient,
      rawTranscript: assessment.transcript,
    ));
    await _persist();
    notifyListeners();

    // Best-effort: opens the SMS composer per contact, same as the manual
    // "notify all contacts" action — there's no SEND_SMS permission wired
    // up, so this still needs the person's own final tap to actually send.
    // A no-response scenario is exactly the case where that tap may not
    // come, which is a real limitation of this approach, not a bug to
    // silently paper over.
    final contacts = await _contactsStore.load();
    if (contacts.isNotEmpty) {
      await notifyAllContacts(contacts);
    }
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
    incident.contactsNotified = true;
    incident.contactsNotifiedAt = DateTime.now();
    await _persist();
    notifyListeners();
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
    _checkInTimer?.cancel();
    _pendingCheckIn = null;
    _checkInSecondsRemaining = 0;
    stopAmbientMonitoring();
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
    _checkInTimer?.cancel();
    _ambientMonitoringEnabled = false;
    _voiceCaptureService.dispose();
    super.dispose();
  }
}
