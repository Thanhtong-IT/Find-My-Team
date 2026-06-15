import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageRepository {
  SecureStorageRepository._internal();

  static final SecureStorageRepository _instance = SecureStorageRepository._internal();
  factory SecureStorageRepository() => _instance;

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';

  Future<void> saveAccessToken(String token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyAccessToken, token);
        return;
      }
      await _storage.write(key: _keyAccessToken, value: token);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_keyAccessToken);
      }
      return await _storage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyAccessToken);
        return;
      }
      await _storage.delete(key: _keyAccessToken);
    } catch (_) {}
  }

  Future<void> saveRefreshToken(String token) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyRefreshToken, token);
        return;
      }
      await _storage.write(key: _keyRefreshToken, value: token);
    } catch (_) {}
  }

  Future<String?> getRefreshToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_keyRefreshToken);
      }
      return await _storage.read(key: _keyRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteRefreshToken() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyRefreshToken);
        return;
      }
      await _storage.delete(key: _keyRefreshToken);
    } catch (_) {}
  }

  Future<void> saveUserId(String userId) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserId, userId);
        return;
      }
      await _storage.write(key: _keyUserId, value: userId);
    } catch (_) {}
  }

  Future<String?> getUserId() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_keyUserId);
      }
      return await _storage.read(key: _keyUserId);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyAccessToken);
        await prefs.remove(_keyRefreshToken);
        await prefs.remove(_keyUserId);
        return;
      }
      await _storage.deleteAll();
    } catch (_) {}
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
