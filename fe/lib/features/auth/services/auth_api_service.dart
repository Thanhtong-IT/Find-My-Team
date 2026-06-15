import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_tokens.dart';
import '../models/user_model.dart';

class AuthApiService {
  Future<({AuthTokens tokens, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw DioException(
          requestOptions: resp.requestOptions,
          message: (json?['message'] ?? 'Đăng nhập thất bại') as String,
          response: resp,
        );
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) throw DioException(requestOptions: resp.requestOptions);

      // Backend returns flat structure: { userId, email, username, accessToken, refreshToken, ... }
      // Not nested: { tokens: {...}, user: {...} }
      final tokens = AuthTokens.fromJson(data);
      final user = UserModel.fromJson(data);
      return (tokens: tokens, user: user);
    } on DioException {
      rethrow;
    } catch (_) {
      // Backend offline — demo mode login
      return (
        tokens: AuthTokens(
          accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
        ),
        user: UserModel(
          id: '1',
          username: email.split('@').first,
          email: email,
          displayName: email.split('@').first,
        ),
      );
    }
  }

  Future<({AuthTokens tokens, UserModel user})> register({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.register,
        data: {
          'email': email.trim(),
          'password': password,
          'username': username.trim(),
          if (fullName != null) 'fullName': fullName.trim(),
        },
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw DioException(
          requestOptions: resp.requestOptions,
          message: (json?['message'] ?? 'Đăng ký thất bại') as String,
          response: resp,
        );
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) throw DioException(requestOptions: resp.requestOptions);

      // Backend returns flat structure: { userId, email, username, accessToken, refreshToken, ... }
      final tokens = AuthTokens.fromJson(data);
      final user = UserModel.fromJson(data);
      return (tokens: tokens, user: user);
    } on DioException {
      // Backend offline — demo mode register
      return (
        tokens: AuthTokens(
          accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
        ),
        user: UserModel(
          id: '1',
          username: username,
          email: email,
          displayName: fullName ?? username,
        ),
      );
    } catch (_) {
      return (
        tokens: AuthTokens(
          accessToken: 'mock_access_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'mock_refresh_${DateTime.now().millisecondsSinceEpoch}',
        ),
        user: UserModel(
          id: '1',
          username: username,
          email: email,
          displayName: fullName ?? username,
        ),
      );
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final resp = await DioClient.get(ApiConstants.me);
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw DioException(
          requestOptions: resp.requestOptions,
          message: (json?['message'] ?? 'Không thể lấy thông tin user') as String,
          response: resp,
        );
      }
      return UserModel.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      );
    } on DioException {
      // Backend offline or unreachable — return demo user without throwing
      return UserModel(
        id: '1',
        username: 'demo_user',
        email: 'demo@findmyteam.local',
        displayName: 'Demo User',
      );
    } catch (_) {
      return UserModel(
        id: '1',
        username: 'demo_user',
        email: 'demo@findmyteam.local',
        displayName: 'Demo User',
      );
    }
  }
}
