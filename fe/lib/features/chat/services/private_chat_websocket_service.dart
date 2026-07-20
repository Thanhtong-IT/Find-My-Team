import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/private_message.dart';

class PrivateChatWebSocketService {
  StompClient? _stompClient;
  final _messageController = StreamController<PrivateMessage>.broadcast();

  Stream<PrivateMessage> get onMessageReceived => _messageController.stream;

  void connect({required String baseUrl, required String token, required String currentUserId}) {
    if (_stompClient != null && _stompClient!.connected) return;

    final formattedUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    
    // Tự động chuyển đổi schema sang ws/wss để kết nối trực tiếp (Raw WebSocket)
    String wsUrl = formattedUrl;
    if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    } else if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: '$wsUrl/ws-stomp'.toString(),
        useSockJS: false, // Sử dụng Raw WebSocket thay vì SockJS
        onConnect: (frame) {
          debugPrint('[STOMP] Kết nối thành công: ${frame.body}');
          subscribeToPrivateQueue(currentUserId);
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[STOMP] Lỗi WebSocket: $error');
        },
        onStompError: (frame) {
          debugPrint('[STOMP] Lỗi Giao thức STOMP: ${frame.body}');
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _stompClient!.activate();
  }

  // Tìm hàm này và sửa lại:
// 1. Thêm String currentUserId vào làm tham số của hàm
void subscribeToPrivateQueue(String currentUserId) {
  if (_stompClient == null || !_stompClient!.connected) return;

  _stompClient!.subscribe(
    destination: '/topic/chat.private.$currentUserId',
    callback: (frame) {
      debugPrint('[STOMP] NHẬN TIN NHẮN REALTIME: ${frame.body}');
      if (frame.body != null) {
        final Map<String, dynamic> json = jsonDecode(frame.body!);
        final message = PrivateMessage.fromJson(json, currentUserId: currentUserId);
        
        // Chỉ đẩy vào stream nếu tin nhắn không phải do chính user hiện tại vừa gửi (đã được REST API xử lý)
        // Hoặc nếu backend không trả về clientMessageId trong websocket để deduplicate
        _messageController.add(message);
      }
    },
  );
  debugPrint('[STOMP] Đã lắng nghe tin nhắn tại /topic/chat.private.$currentUserId');
}

  void sendRealtimeMessage({
    required String receiverId,
    required String content,
    required String clientMessageId,
  }) {
    if (_stompClient == null || !_stompClient!.connected) {
      debugPrint('[STOMP] Cannot send message: Not connected');
      return;
    }

    final payload = {
      'receiverId': receiverId,
      'content': content,
      'clientMessageId': clientMessageId,
    };

    _stompClient!.send(
      destination: '/app/chat.sendPrivateMessage.$receiverId',
      body: jsonEncode(payload),
    );
    debugPrint('[STOMP] Sent message to $receiverId');
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
