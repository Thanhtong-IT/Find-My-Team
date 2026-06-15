import 'dart:async';
import '../websocket/websocket_client.dart';

/// EventBus đơn giản để distribute WebSocket events tới các Bloc.
class AppEventBus {
  AppEventBus._();

  static final AppEventBus instance = AppEventBus._();

  final _subController = StreamController<WsIncomingEvent>.broadcast();

  Stream<WsIncomingEvent> get stream => _subController.stream;

  Stream<WsIncomingEvent> get messageStream =>
      stream.where((e) => e.type == WsEventType.messageCreated);

  Stream<WsIncomingEvent> get teamEventStream => stream.where((e) =>
      e.type == WsEventType.teamMemberJoined ||
      e.type == WsEventType.teamMemberLeft ||
      e.type == WsEventType.teamMemberReady ||
      e.type == WsEventType.teamDisbanded ||
      e.type == WsEventType.joinRequestAccepted);

  Stream<WsIncomingEvent> get joinRequestStream =>
      stream.where((e) => e.type == WsEventType.joinRequestCreated);

  Stream<WsIncomingEvent> get notificationStream => stream.where((e) =>
      e.type == WsEventType.notificationNew ||
      e.type == WsEventType.invitationReceived);

  Stream<WsIncomingEvent> get matchStream =>
      stream.where((e) => e.type == WsEventType.matchCreated);

  Stream<WsIncomingEvent> get presenceStream => stream.where((e) =>
      e.type == WsEventType.userOnline || e.type == WsEventType.userOffline);

  Stream<WsIncomingEvent> get typingStream => stream.where((e) =>
      e.type == WsEventType.typingStart || e.type == WsEventType.typingStop);

  void register(WebSocketClient ws) {
    ws.eventStream.listen((event) {
      _subController.add(event);
    });
  }

  void dispose() {
    _subController.close();
  }
}
