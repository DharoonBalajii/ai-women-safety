import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/guardian_alert.dart';
import '../models/guardian_invite.dart';
import '../services/guardian_service.dart';

/// Drives the Guardian dashboard: pending invites and live alerts, kept
/// fresh by polling on a short interval.
///
/// This polls rather than subscribing to Supabase Realtime — Realtime
/// hasn't been turned on for this project yet. Swapping this for a
/// Realtime channel subscription later is a self-contained change here;
/// nothing in the UI layer needs to know which one is feeding it.
class GuardianProvider extends ChangeNotifier {
  static const _pollInterval = Duration(seconds: 8);

  List<GuardianInvite> _invites = [];
  List<GuardianAlert> _alerts = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  List<GuardianInvite> get invites => List.unmodifiable(_invites);
  List<GuardianAlert> get alerts => List.unmodifiable(_alerts);
  bool get loading => _loading;
  String? get error => _error;

  void start() {
    unawaited(refresh());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        guardianService.fetchPendingInvites(),
        guardianService.fetchAlerts(),
      ]);
      _invites = results[0] as List<GuardianInvite>;
      _alerts = results[1] as List<GuardianAlert>;
      _error = null;
    } catch (e) {
      // Keep showing the last-known good state through a transient
      // failure — only surface the error if we have nothing else to show.
      if (_alerts.isEmpty && _invites.isEmpty) {
        _error = 'Could not reach the server: $e';
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> respondToInvite(String relationshipId, {required bool accept}) async {
    await guardianService.respondToInvite(relationshipId, accept: accept);
    _invites.removeWhere((i) => i.relationshipId == relationshipId);
    notifyListeners();
    unawaited(refresh());
  }

  Future<void> acknowledge(String incidentId) => _actOnAlert(
        incidentId,
        () => guardianService.acknowledgeAlert(incidentId),
      );

  Future<void> markResponding(String incidentId) => _actOnAlert(
        incidentId,
        () => guardianService.markResponding(incidentId),
      );

  Future<void> resolve(String incidentId) => _actOnAlert(
        incidentId,
        () => guardianService.resolveAlert(incidentId),
        removeOnSuccess: true,
      );

  Future<void> _actOnAlert(
    String incidentId,
    Future<void> Function() action, {
    bool removeOnSuccess = false,
  }) async {
    await action();
    if (removeOnSuccess) {
      _alerts.removeWhere((a) => a.incidentId == incidentId);
      notifyListeners();
    }
    unawaited(refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
