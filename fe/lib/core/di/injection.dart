import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import '../repository/secure_storage_repository.dart';
import '../websocket/websocket_client.dart';
import '../events/event_bus.dart';
import '../voice/voice_chat_service.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  // Core
  getIt.registerLazySingleton<SecureStorageRepository>(
    () => SecureStorageRepository(),
  );

  getIt.registerLazySingleton<TokenRepository>(
    () => TokenRepository(getIt<FlutterSecureStorage>()),
  );

  // DioClient — gọi init 1 lần
  DioClient.init();

  // WebSocket
  getIt.registerLazySingleton<WebSocketClient>(() => WebSocketClient.instance);

  // Event Bus
  getIt.registerLazySingleton<AppEventBus>(() => AppEventBus.instance);

  // Voice Chat
  getIt.registerLazySingleton<VoiceChatService>(() {
    final service = VoiceChatService.instance;
    service.init(getIt<WebSocketClient>());
    return service;
  });
}
