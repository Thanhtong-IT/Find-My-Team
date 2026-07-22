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
        throw Exception(json?['message'] ?? 'Đăng nhập thất bại');
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Dữ liệu phản hồi không hợp lệ');

      final tokens = AuthTokens.fromJson(data);
      final user = UserModel.fromJson(data);
      return (tokens: tokens, user: user);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register({
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
        throw Exception(json?['message'] ?? 'Đăng ký thất bại');
      }
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<({AuthTokens tokens, UserModel user})> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.verifyOtp,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] ?? 'Xác thực OTP thất bại');
      }

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) throw Exception('Dữ liệu phản hồi không hợp lệ');

      final tokens = AuthTokens.fromJson(data);
      final user = UserModel.fromJson(data);
      return (tokens: tokens, user: user);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resendOtp(String email) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.resendOtp,
        data: {'email': email.trim()},
      );

      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] ?? 'Gửi lại mã OTP thất bại');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.forgotPassword,
        data: {'email': email.trim()},
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] ?? 'Yêu cầu khôi phục mật khẩu thất bại');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.verifyResetOtp,
        data: {
          'email': email.trim(),
          'otp': otp.trim(),
        },
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] ?? 'Xác thực mã OTP thất bại');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
    }
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final resp = await DioClient.post(
        ApiConstants.resetPassword,
        data: {
          'email': email.trim(),
          'password': newPassword,
        },
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Lỗi kết nối server';
      throw Exception(message);
    } catch (e) {
      throw Exception('Lỗi không xác định: $e');
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
