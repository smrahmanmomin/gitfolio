import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing authentication tokens
class TokenService {
  static const String _tokenKey = 'github_token';
  static const String _tokenTimestampKey = 'github_token_timestamp';

  /// Save GitHub token to local storage
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(
        _tokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get stored GitHub token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if token exists
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear stored token (logout)
  static Future<bool> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenTimestampKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get token age in days
  static Future<int?> getTokenAgeDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_tokenTimestampKey);
      if (timestamp == null) return null;

      final savedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      return now.difference(savedDate).inDays;
    } catch (e) {
      return null;
    }
  }
}
