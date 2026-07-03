import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../navigation/app_navigator.dart';
import '../websocket/websocket_client.dart';
import 'dio_client.dart';

/// Lưu trữ access token để AuthInterceptor đọc khi retry.
class TokenRepository {
  final FlutterSecureStorage _storage;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  TokenRepository(this._storage);

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

  Future<void> clearAll() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyAccessToken);
        await prefs.remove(_keyRefreshToken);
        return;
      }
      await _storage.deleteAll();
    } catch (_) {}
  }
}

/// Cố gắng refresh token và retry request gốc.
/// Nếu refresh thất bại → throw DioException để AuthInterceptor re-throw.
Future<Response<dynamic>> _refreshAndRetry(
  Dio dio,
  DioException err,
  TokenRepository tokenRepo,
) async {
  try {
    final refreshToken = await tokenRepo.getRefreshToken();
    if (refreshToken == null) throw err;

    final dioRefresh = Dio(BaseOptions(baseUrl: DioClient.instance.options.baseUrl));
    final resp = await dioRefresh.post(
      ApiConstants.refresh,
      data: {'refreshToken': refreshToken},
    );

    if (resp.statusCode == 200 && resp.data['success'] == true) {
      final newAccess = resp.data['data']['accessToken'] as String;
      final newRefresh = resp.data['data']['refreshToken'] as String?;
      await tokenRepo.saveAccessToken(newAccess);
      if (newRefresh != null) await tokenRepo.saveRefreshToken(newRefresh);

      // Retry request gốc với access token mới
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResp = await dio.fetch(err.requestOptions);
      return retryResp;
    } else {
      await tokenRepo.clearAll();
      throw err;
    }
  } catch (_) {
    await tokenRepo.clearAll();
    rethrow;
  }
}

Future<void> _logoutAndRedirectToLogin(TokenRepository tokenRepo) async {
  await tokenRepo.clearAll();
  WebSocketClient.instance.disconnect();
  final navigator = appNavigatorKey.currentState;
  if (navigator != null) {
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class AuthInterceptor extends Interceptor {
  final TokenRepository tokenRepo;

  AuthInterceptor(this.tokenRepo);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenRepo.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('[AUTH] Added token to ${options.path}');
    } else {
      debugPrint('[AUTH] No token available for ${options.path}');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('[AUTH] onError: ${err.requestOptions.path} status=${err.response?.statusCode}');

    // Chỉ retry khi gặp 401 và không phải request refresh ban đầu
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      debugPrint('[AUTH] Got 401, attempting refresh...');
      try {
        final retryResp = await _refreshAndRetry(
          Dio(),
          err,
          tokenRepo,
        );
        debugPrint('[AUTH] Refresh SUCCESS, retrying ${err.requestOptions.path}');
        return handler.resolve(retryResp);
      } on DioException catch (e) {
        debugPrint('[AUTH] Refresh FAILED: ${e.message}');
        return handler.next(e);
      }
    }

    if (err.response?.statusCode == 403) {
      debugPrint('[AUTH] Got 403, logging out and redirecting to login');
      await _logoutAndRedirectToLogin(tokenRepo);
    }

    handler.next(err);
  }
}
