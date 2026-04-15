import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyUserName = 'user_name';
  static const String _defaultName = 'Balaji';

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? _defaultName;
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }
}
