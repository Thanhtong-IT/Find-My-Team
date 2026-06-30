import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioClient {
  DioClient._();

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static late final TokenRepository tokenRepository;
  static late final Dio instance;

  /// Gọi 1 lần duy nhất từ main() trước khi app khởi chạy.
  static void init() {
    tokenRepository = TokenRepository(_storage);

    final baseUrl = dotenv.env['API_BASE_URL'] ?? ApiConstants.defaultBaseUrl;

    instance = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    instance.interceptors.add(AuthInterceptor(tokenRepository));
    instance.interceptors.add(LogInterceptor(
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      error: true,
    ));
  }

  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      instance.get<T>(path, queryParameters: queryParameters, options: options);

  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      instance.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      instance.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      instance.delete<T>(path, data: data, queryParameters: queryParameters, options: options);

  /// Xóa toàn bộ token (khi logout).
  static Future<void> clearAuth() => tokenRepository.clearAll();
}
