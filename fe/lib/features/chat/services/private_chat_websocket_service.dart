import 'dart:async';
import '../../../core/websocket/websocket_client.dart';
import '../../../core/events/event_bus.dart';
import '../models/private_message.dart';

class PrivateChatWebSocketService {
  final WebSocketClient _wsClient = WebSocketClient.instance;
  final AppEventBus _eventBus = AppEventBus.instance;

  /// Subscribe vào queue tin nhắn cá nhân (STOMP-like behavior)
  void subscribeToPrivateMessages() {
    // Theo yêu cầu Backend: lắng nghe từ /user/queue/messages
    _wsClient.subscribeRoom('messages', 'user_queue'); 
  }

  /// Gửi tin nhắn 1v1 qua WebSocket
  void sendPrivateMessage({
    required String receiverId,
    required String content,
    required String clientMessageId,
  }) {
    _wsClient.sendPayload('SEND_PRIVATE_MESSAGE', {
      'receiverId': receiverId,
      'content': content,
      'clientMessageId': clientMessageId,
    });
  }

  /// Stream nhận tin nhắn 1v1 real-time từ EventBus
  Stream<PrivateMessage> get onMessageReceived {
    return _eventBus.privateMessageStream.map((event) {
      return PrivateMessage.fromJson(event.data);
    });
  }
}
