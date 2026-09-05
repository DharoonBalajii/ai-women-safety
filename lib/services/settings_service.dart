import 'package:shared_preferences/shared_preferences.dart';

/// Local, on-device settings store for the hackathon prototype.
/// The Sarvam API key is kept only on-device; there is no backend yet.
class SettingsService {
  static const _sarvamKeyPref = 'sarvam_api_key';

  Future<String?> getSarvamApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_sarvamKeyPref);
    return (key == null || key.trim().isEmpty) ? null : key.trim();
  }

  Future<void> setSarvamApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_sarvamKeyPref);
    } else {
      await prefs.setString(_sarvamKeyPref, key.trim());
    }
  }
}
