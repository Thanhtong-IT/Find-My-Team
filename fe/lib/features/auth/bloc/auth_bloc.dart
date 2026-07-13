import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../../../core/websocket/websocket_client.dart';
import '../../../core/events/event_bus.dart';
import '../models/auth_tokens.dart';
import '../services/auth_api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthApiService _authApiService;
  final SecureStorageRepository _secureStorage;
  final WebSocketClient _wsClient;
  StreamSubscription? _wsStatusSub;

  AuthBloc({
    required AuthApiService authApiService,
    required SecureStorageRepository secureStorage,
    required WebSocketClient wsClient,
  })  : _authApiService = authApiService,
        _secureStorage = secureStorage,
        _wsClient = wsClient,
        super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);

    // Listen to WebSocket reconnection to re-register AppEventBus
    _wsStatusSub = _wsClient.statusStream.listen((status) {
      if (status == WsConnectionStatus.connected && _isAuthenticated) {
        _ensureEventBusRegistered();
      }
    });
  }

  bool _isAuthenticated = false;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final hasToken = await _secureStorage.hasAccessToken();
      if (!hasToken) {
        debugPrint('[Auth] Không có token - yêu cầu đăng nhập');
        emit(const AuthState.unauthenticated());
        return;
      }
      debugPrint('[Auth] Token tìm thấy - kiểm tra user...');
      final user = await _authApiService.getCurrentUser();
      _isAuthenticated = true;
      debugPrint('[Auth] Check thành công: ${user.email}');
      _connectWebSocket();
      emit(AuthState.authenticated(user));
    } on DioException catch (e) {
      debugPrint('[Auth] Check thất bại: ${e.message}');
      await _secureStorage.clearAll();
      emit(const AuthState.unauthenticated());
    } catch (e) {
      debugPrint('[Auth] Check lỗi không xác định: $e');
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading()); //Loading state
    debugPrint('[Auth] Bắt đầu login: ${event.email}');
    try {
      final result = await _authApiService.login(
        email: event.email,
        password: event.password,
      );
      await _saveTokens(result.tokens);
      await _secureStorage.saveUserId(result.user.id);
      _isAuthenticated = true;
      debugPrint('[Auth] Login thành công: ${event.email}');
      _connectWebSocket();
      emit(AuthState.authenticated(result.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Đăng nhập thất bại';
      debugPrint('[Auth] Login thất bại: $msg');
      emit(AuthState.error(msg));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      debugPrint('[Auth] Login lỗi: $e');
      emit(AuthState.error('Lỗi không xác định: $e'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    debugPrint('[Auth] Bắt đầu register: ${event.email}');
    try {
      final result = await _authApiService.register(
        email: event.email,
        password: event.password,
        username: event.username,
        fullName: event.fullName,
      );
      await _saveTokens(result.tokens);
      await _secureStorage.saveUserId(result.user.id);
      _isAuthenticated = true;
      debugPrint('[Auth] Register thành công: ${event.email}');
      _connectWebSocket();
      emit(AuthState.authenticated(result.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Đăng ký thất bại';
      debugPrint('[Auth] Register thất bại: $msg');
      emit(AuthState.error(msg));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      debugPrint('[Auth] Register lỗi: $e');
      emit(AuthState.error('Lỗi không xác định: $e'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _isAuthenticated = false;
    AppEventBus.instance.unregister();
    await _secureStorage.clearAll();
    _wsClient.disconnect();
    debugPrint('[Auth] Logout thành công');
    emit(const AuthState.unauthenticated());
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    await _secureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<void> _connectWebSocket() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return;
    final wsUrl = dotenv.env['WS_URL'] ?? ApiConstants.defaultWsUrl;
    _wsClient.connect(
      url: wsUrl,
      token: token,
    );
    _ensureEventBusRegistered();
  }

  void _ensureEventBusRegistered() {
    // Đảm bảo AppEventBus được register với WebSocket
    // Nếu đã register rồi thì bỏ qua
    AppEventBus.instance.register(_wsClient);
  }

  @override
  Future<void> close() {
    _wsStatusSub?.cancel();
    return super.close();
  }
}
