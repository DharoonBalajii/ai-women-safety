import 'package:flutter/foundation.dart';

import '../services/settings_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  String? _sarvamApiKey;
  bool _loaded = false;

  String? get sarvamApiKey => _sarvamApiKey;
  bool get isSarvamConfigured => _sarvamApiKey != null;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _sarvamApiKey = await _service.getSarvamApiKey();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSarvamApiKey(String? key) async {
    await _service.setSarvamApiKey(key);
    _sarvamApiKey = (key == null || key.trim().isEmpty) ? null : key.trim();
    notifyListeners();
  }
}
