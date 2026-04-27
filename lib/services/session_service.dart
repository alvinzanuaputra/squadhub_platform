import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyLoginTime = 'login_time';
  static const String _keyUid = 'session_uid';
  static const String _keyEmail = 'session_email';
  static const String _keyName = 'session_name';
  static const int _sessionDuration = 60;

  static Future<void> saveSession({
    required String uid,
    required String email,
    required String name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    await prefs.setInt(
      _keyLoginTime, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_keyLoginTime);
    if (loginTime == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - loginTime;
    final elapsedMinutes = elapsed / 1000 / 60;
    return elapsedMinutes < _sessionDuration;
  }

  static Future<Map<String, String?>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString(_keyUid),
      'email': prefs.getString(_keyEmail),
      'name': prefs.getString(_keyName),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoginTime);
    await prefs.remove(_keyUid);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
  }

  static Future<int> getRemainingMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt(_keyLoginTime);
    if (loginTime == null) return 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - loginTime;
    final elapsedMinutes = (elapsed / 1000 / 60).floor();
    final remaining = _sessionDuration - elapsedMinutes;
    return remaining > 0 ? remaining : 0;
  }
}
