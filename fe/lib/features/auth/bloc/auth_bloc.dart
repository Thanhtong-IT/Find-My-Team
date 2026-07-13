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
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final hasToken = await _secureStorage.hasAccessToken();
      if (!hasToken) {
        emit(const AuthState.unauthenticated());
        return;
      }
      final user = await _authApiService.getCurrentUser();
      _connectWebSocket();
      emit(AuthState.authenticated(user));
    } on DioException {
      await _secureStorage.clearAll();
      emit(const AuthState.unauthenticated());
    } catch (_) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final result = await _authApiService.login(
        email: event.email,
        password: event.password,
      );
      await _saveTokens(result.tokens);
      await _secureStorage.saveUserId(result.user.id);
      _connectWebSocket();
      emit(AuthState.authenticated(result.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Đăng nhập thất bại';
      emit(AuthState.error(msg));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Lỗi không xác định: $e'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    try {
      final result = await _authApiService.register(
        email: event.email,
        password: event.password,
        username: event.username,
        fullName: event.fullName,
      );
      await _saveTokens(result.tokens);
      await _secureStorage.saveUserId(result.user.id);
      emit(AuthState.authenticated(result.user));
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String? ??
          e.message ??
          'Đăng ký thất bại';
      emit(AuthState.error(msg));
      emit(const AuthState.unauthenticated());
    } catch (e) {
      emit(AuthState.error('Lỗi không xác định: $e'));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _secureStorage.clearAll();
    _wsClient.disconnect();
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
    AppEventBus.instance.register(_wsClient);
  }
}
