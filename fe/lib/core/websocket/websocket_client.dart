import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Các loại event từ WebSocket server.
enum WsEventType {
  connected,
  disconnected,
  error,
  // Auth
  authSuccess,
  authFailed,
  // Messaging
  messageCreated,
  // Team
  teamCreated,
  teamMemberJoined,
  teamMemberLeft,
  teamMemberReady,
  teamDisbanded,
  // Join request
  joinRequestCreated,
  joinRequestAccepted,
  joinRequestRejected,
  // Notification
  notificationNew,
  invitationReceived,
  // Explore
  matchCreated,
  // Presence
  userOnline,
  userOffline,
  // Typing
  typingStart,
  typingStop,
  // Generic
  heartbeatAck,
  unknown,
}

class WsIncomingEvent {
  final WsEventType type;
  final Map<String, dynamic> data;
  final String? eventId;

  const WsIncomingEvent({
    required this.type,
    required this.data,
    this.eventId,
  });
}

typedef WsEventListener = void Function(WsIncomingEvent event);

class WebSocketClient {
  WebSocketClient._();

  static final WebSocketClient instance = WebSocketClient._();

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final _eventController = StreamController<WsIncomingEvent>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<WsIncomingEvent> get eventStream => _eventController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String? _lastEventId;
  String? _wsUrl;
  String? _token;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 5);

  void connect({required String url, required String token}) {
    _wsUrl = url;
    _token = token;
    _doConnect();
  }

  void _doConnect() {
    if (_wsUrl == null || _token == null || _token!.isEmpty) return;
    _reconnectTimer?.cancel();

    try {
      final uri = Uri.parse('${_wsUrl!}?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (!_isConnected) {
      _isConnected = true;
      _connectionController.add(true);
      _startHeartbeat();
    }

    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final op = json['op'] as String?;
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final eventId = json['eventId'] as String?;

      if (op == 'heartbeat_ack') {
        return; // heartbeat ack — bỏ qua
      }

      if (op == 'resume_ack') {
        return; // resume thành công
      }

      String? eventTypeStr = op;
      Map<String, dynamic> eventData = data;

      if (op == 'event') {
        final innerEvent = data['data'] as Map<String, dynamic>?;
        if (innerEvent != null) {
          eventTypeStr = innerEvent['type'] as String?;
          eventData = innerEvent['data'] as Map<String, dynamic>? ?? {};
        }
      }

      final type = _parseEventType(eventTypeStr);

      if (type != WsEventType.unknown) {
        final event = WsIncomingEvent(type: type, data: eventData, eventId: eventId);
        _eventController.add(event);
      }

      if (eventId != null) {
        _lastEventId = eventId;
      }
    } catch (_) {
      // Malformed message — ignore
    }
  }

  WsEventType _parseEventType(String? op) {
    switch (op) {
      case 'MESSAGE_CREATED':
        return WsEventType.messageCreated;
      case 'TEAM_CREATED':
        return WsEventType.teamCreated;
      case 'TEAM_MEMBER_JOINED':
        return WsEventType.teamMemberJoined;
      case 'TEAM_MEMBER_LEFT':
        return WsEventType.teamMemberLeft;
      case 'TEAM_MEMBER_READY':
        return WsEventType.teamMemberReady;
      case 'TEAM_DISBANDED':
        return WsEventType.teamDisbanded;
      case 'JOIN_REQUEST_CREATED':
        return WsEventType.joinRequestCreated;
      case 'JOIN_REQUEST_ACCEPTED':
        return WsEventType.joinRequestAccepted;
      case 'JOIN_REQUEST_REJECTED':
        return WsEventType.joinRequestRejected;
      case 'NOTIFICATION_NEW':
        return WsEventType.notificationNew;
      case 'INVITATION_RECEIVED':
        return WsEventType.invitationReceived;
      case 'MATCH_CREATED':
        return WsEventType.matchCreated;
      case 'USER_ONLINE':
        return WsEventType.userOnline;
      case 'USER_OFFLINE':
        return WsEventType.userOffline;
      case 'TYPING_START':
        return WsEventType.typingStart;
      case 'TYPING_STOP':
        return WsEventType.typingStop;
      default:
        return WsEventType.unknown;
    }
  }

  void _onError(Object error) {
    _setDisconnected();
  }

  void _onDone() {
    _setDisconnected();
    _scheduleReconnect();
  }

  void _setDisconnected() {
    _isConnected = false;
    _connectionController.add(false);
    _heartbeatTimer?.cancel();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _send({'op': 'heartbeat'});
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _doConnect();
    });
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  /// Gửi tin nhắn typing indicator.
  void sendTypingStart(String conversationId) {
    _send({
      'op': 'TYPING_START',
      'data': {'conversationId': conversationId},
    });
  }

  void sendTypingStop(String conversationId) {
    _send({
      'op': 'TYPING_STOP',
      'data': {'conversationId': conversationId},
    });
  }

  /// Gửi lệnh resume để sync event bị lỡ sau khi reconnect.
  void resume() {
    if (_lastEventId != null) {
      _send({
        'op': 'resume',
        'data': {'lastEventId': _lastEventId},
      });
    }
  }

  /// Subscribe vào một room
  void subscribeRoom(String roomId, String roomType) {
    _send({
      'op': 'subscribe',
      'data': {
        'roomId': roomId,
        'roomType': roomType,
      },
    });
  }

  /// Unsubscribe khỏi một room
  void unsubscribeRoom(String roomId, String roomType) {
    _send({
      'op': 'unsubscribe',
      'data': {
        'roomId': roomId,
        'roomType': roomType,
      },
    });
  }

  /// Ngắt kết nối WebSocket (khi logout).
  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _lastEventId = null;
    _wsUrl = null;
    _token = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}
