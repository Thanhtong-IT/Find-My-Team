import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  teamMessageCreated,
  // Team
  teamCreated,
  teamMemberJoined,
  teamMemberLeft,
  teamMemberReady,
  teamMemberMicChanged,
  teamDisbanded,
  teamMemberKicked,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WsIncomingEvent &&
        other.eventId == eventId &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(eventId, type);
}

typedef WsEventListener = void Function(WsIncomingEvent event);

/// Connection status enum.
enum WsConnectionStatus { disconnected, connecting, connected, reconnecting }

class WebSocketClient {
  WebSocketClient._();

  static final WebSocketClient instance = WebSocketClient._();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _connectionGeneration = 0;
  int? _reconnectPendingGeneration;

  final _eventController = StreamController<WsIncomingEvent>.broadcast();
  final _statusController = StreamController<WsConnectionStatus>.broadcast();

  Stream<WsIncomingEvent> get eventStream => _eventController.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;

  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  WsConnectionStatus get status => _status;

  bool get isConnected => _status == WsConnectionStatus.connected;

  String? _lastEventId;
  String? _wsUrl;
  String? _token;

  // Subscription tracking - prevent duplicate subscriptions
  final Set<String> _subscribedRooms = {};
  // Processed event IDs for deduplication
  final Set<String> _processedEventIds = {};

  // Exponential backoff config
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 10;

  int _reconnectAttempts = 0;

  void connect({required String url, required String token}) {
    final sameConnection = _wsUrl == url && _token == token;
    if (sameConnection && _status != WsConnectionStatus.disconnected) {
      return;
    }

    _closeCurrentChannel();
    _wsUrl = url;
    _token = token;
    _reconnectAttempts = 0;
    debugPrint('[WS] Bắt đầu kết nối: $url');
    _doConnect();
  }

  void _doConnect() {
    if (_wsUrl == null || _token == null || _token!.isEmpty) {
      debugPrint('[WS] Không thể kết nối - URL hoặc token null');
      return;
    }

    _reconnectTimer?.cancel();
    _closeCurrentChannel();
    final generation = ++_connectionGeneration;
    _setStatus(WsConnectionStatus.connecting);
    debugPrint('[WS] Đang kết nối...');

    try {
      final uri = Uri.parse('${_wsUrl!}?token=$_token');
      _channel = WebSocketChannel.connect(uri);

      _channelSubscription = _channel!.stream.listen(
        (raw) {
          if (generation == _connectionGeneration) _onData(raw);
        },
        onError: (Object error) {
          if (generation == _connectionGeneration) {
            _onError(error);
            _scheduleReconnect();
          }
        },
        onDone: () {
          if (generation == _connectionGeneration) {
            _onDone();
          }
        },
      );
    } catch (e) {
      debugPrint('[WS] Lỗi kết nối: $e');
      _scheduleReconnect();
    }
  }

  void _closeCurrentChannel() {
    _heartbeatTimer?.cancel();
    final subscription = _channelSubscription;
    final channel = _channel;
    _channelSubscription = null;
    _channel = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    if (channel != null) {
      unawaited(channel.sink.close());
    }
  }

  void _onData(dynamic raw) {
    if (_status != WsConnectionStatus.connected) {
      _setStatus(WsConnectionStatus.connected);
      _startHeartbeat();
      _resubscribeRooms();
      debugPrint('[WS] Kết nối thành công');
    }

    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final op = json['op'] as String?;
      final data = json['data'] as Map<String, dynamic>? ?? {};
      final eventId = json['eventId'] as String?;

      debugPrint('[WS] Incoming: op=$op, hasEventId=${eventId != null}, dataKeys=${data.keys.toList()}');

      if (op == 'heartbeat_ack' || op == 'resume_ack') {
        return;
      }

      String? eventTypeStr = op;
      Map<String, dynamic> eventData = data;

      if (op == 'event') {
        final innerEvent = data['data'] as Map<String, dynamic>?;
        debugPrint('[WS] Inner event: $innerEvent');
        if (innerEvent != null) {
          eventTypeStr = innerEvent['type'] as String?;
          eventData = innerEvent['data'] as Map<String, dynamic>? ?? {};
        }
      }

      final type = _parseEventType(eventTypeStr);
      debugPrint('[WS] Parsed type: $type');

      if (type != WsEventType.unknown) {
        // Deduplicate by eventId
        if (eventId != null) {
          if (_processedEventIds.contains(eventId)) {
            debugPrint('[WS] Duplicate eventId $eventId, ignoring');
            return; // Already processed this event
          }
          _processedEventIds.add(eventId);
          // Keep set size bounded
          if (_processedEventIds.length > 1000) {
            _processedEventIds.clear();
          }
        }

        final event = WsIncomingEvent(type: type, data: eventData, eventId: eventId);
        debugPrint('[WS] Emitting event: $event');
        _eventController.add(event);
        debugPrint('[WS] Event: $op');
      }

      if (eventId != null) {
        _lastEventId = eventId;
      }
    } catch (e) {
      debugPrint('[WS] Lỗi parse message: $e');
    }
  }

  WsEventType _parseEventType(String? op) {
    switch (op) {
      case 'MESSAGE_CREATED':
        return WsEventType.messageCreated;
      case 'TEAM_MESSAGE_CREATED':
        return WsEventType.teamMessageCreated;
      case 'TEAM_CREATED':
        return WsEventType.teamCreated;
      case 'TEAM_MEMBER_JOINED':
        return WsEventType.teamMemberJoined;
      case 'TEAM_MEMBER_LEFT':
        return WsEventType.teamMemberLeft;
      case 'TEAM_MEMBER_READY':
        return WsEventType.teamMemberReady;
      case 'TEAM_MEMBER_MIC_CHANGED':
        return WsEventType.teamMemberMicChanged;
      case 'TEAM_DISBANDED':
        return WsEventType.teamDisbanded;
      case 'TEAM_MEMBER_KICKED':
        return WsEventType.teamMemberKicked;
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
    debugPrint('[WS] Lỗi: $error');
    _setDisconnected();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed by server');
    _setDisconnected();
    _scheduleReconnect();
  }

  void _setDisconnected() {
    _heartbeatTimer?.cancel();
    _setStatus(WsConnectionStatus.disconnected);
  }

  void _setStatus(WsConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(newStatus);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _send({'op': 'heartbeat'});
    });
  }

  void _scheduleReconnect() {
    final generation = _connectionGeneration;
    if (_reconnectPendingGeneration == generation) return;
    _reconnectPendingGeneration = generation;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setStatus(WsConnectionStatus.disconnected);
      return;
    }

    _setStatus(WsConnectionStatus.reconnecting);
    _reconnectTimer?.cancel();

    // Exponential backoff with jitter
    final delay = _initialReconnectDelay.inSeconds *
        (1 << _reconnectAttempts.clamp(0, 5)); // 1, 2, 4, 8, 16, 32s
    final cappedDelay = Duration(seconds: delay.clamp(1, _maxReconnectDelay.inSeconds));

    _reconnectAttempts++;

    _reconnectTimer = Timer(cappedDelay, () {
      if (_reconnectPendingGeneration != generation) return;
      _reconnectPendingGeneration = null;
      _doConnect();
    });
  }

  void _send(Map<String, dynamic> payload) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(jsonEncode(payload));
      debugPrint('[WS] Sent: ${payload['op']}');
    } else {
      debugPrint('[WS] Send failed - Not connected');
    }
  }

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


  void resume() {
    if (_lastEventId != null) {
      _send({
        'op': 'resume',
        'data': {'lastEventId': _lastEventId},
      });
      debugPrint('[WS] Resume với lastEventId: $_lastEventId');
    }
  }

  /// Subscribe vào một room - tracks subscriptions to prevent duplicates.
  void subscribeRoom(String roomId, String roomType) {
    final key = '${roomType}_$roomId';
    if (_subscribedRooms.contains(key)) {
      return; // Already subscribed
    }

    _subscribedRooms.add(key);
    _send({
      'op': 'subscribe',
      'data': {
        'roomId': roomId,
        'roomType': roomType,
      },
    });
    debugPrint('[WS] Subscribe room: $roomType/$roomId');
  }

  /// Unsubscribe khỏi một room.
  void unsubscribeRoom(String roomId, String roomType) {
    final key = '${roomType}_$roomId';
    _subscribedRooms.remove(key);
    _send({
      'op': 'unsubscribe',
      'data': {
        'roomId': roomId,
        'roomType': roomType,
      },
    });
    debugPrint('[WS] Unsubscribe room: $roomType/$roomId');
  }

  /// Resubscribe all rooms after reconnect.
  void _resubscribeRooms() {
    debugPrint('[WS] Resubscribing ${_subscribedRooms.length} rooms...');
    for (final key in _subscribedRooms.toList()) {
      final parts = key.split('_');
      if (parts.length == 2) {
        _send({
          'op': 'subscribe',
          'data': {
            'roomId': parts[1],
            'roomType': parts[0],
          },
        });
      }
    }
  }

  /// Check if room is already subscribed.
  bool isRoomSubscribed(String roomId, String roomType) {
    return _subscribedRooms.contains('${roomType}_$roomId');
  }

  /// Ngắt kết nối WebSocket (khi logout).
  void disconnect() {
    _connectionGeneration++;
    _reconnectPendingGeneration = null;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _closeCurrentChannel();
    _subscribedRooms.clear();
    _processedEventIds.clear();
    _reconnectAttempts = 0;
    _setStatus(WsConnectionStatus.disconnected);
    _lastEventId = null;
    _wsUrl = null;
    _token = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _statusController.close();
  }
}
