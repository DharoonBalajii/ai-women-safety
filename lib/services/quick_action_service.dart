import 'package:flutter/foundation.dart';
import 'package:quick_actions/quick_actions.dart';

/// Wires a long-press home-screen shortcut ("SOS") as the closest hackathon
/// equivalent of the iPhone Action Button / Android hardware gesture —
/// full OS-level Action Button (App Intents) integration needs native
/// Swift/Kotlin work beyond this prototype's scope.
class QuickActionService {
  static const sosActionType = 'sos_trigger';
  final QuickActions _quickActions = const QuickActions();

  Future<void> initialize({required VoidCallback onSosShortcut}) async {
    if (kIsWeb) return;
    await _quickActions.initialize((type) {
      if (type == sosActionType) onSosShortcut();
    });
    await _quickActions.setShortcutItems([
      const ShortcutItem(
        type: sosActionType,
        localizedTitle: 'Trigger SOS',
      ),
    ]);
  }
}
