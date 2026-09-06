import 'package:shared_preferences/shared_preferences.dart';

/// Small local device preferences — nothing here is synced to the backend
/// or tied to a signed-in account; it's per-device behavior.
class AppSettingsService {
  static const _autoTriggerKey = 'auto_trigger_sos_on_launch';

  Future<bool> getAutoTriggerOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoTriggerKey) ?? false;
  }

  Future<void> setAutoTriggerOnLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoTriggerKey, value);
  }
}

final appSettingsService = AppSettingsService();
