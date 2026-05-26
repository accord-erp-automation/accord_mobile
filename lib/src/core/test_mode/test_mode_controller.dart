import 'package:shared_preferences/shared_preferences.dart';

class TestModeController {
  TestModeController._();

  static final TestModeController instance = TestModeController._();
  static const String _enabledKey = 'test_mode_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
