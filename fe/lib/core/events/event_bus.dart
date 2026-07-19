import 'dart:async';
import 'package:flutter/foundation.dart';
import '../websocket/websocket_client.dart';

/// EventBus đơn giản để distribute WebSocket events tới các Bloc.
/// Sử dụng singleton pattern với lazy initialization.
class AppEventBus {
  AppEventBus._();

  static final AppEventBus instance = AppEventBus._();

  final _subController = StreamController<WsIncomingEvent>.broadcast();
  final _teamReloadController = StreamController<void>.broadcast();
  final _profileReloadController = StreamController<void>.broadcast();
  final _navigateToTabController = StreamController<int>.broadcast();
  final _exploreTeamReloadController = StreamController<void>.broadcast();
  bool _isRegistered = false;
  StreamSubscription? _wsSubscription;

  Stream<WsIncomingEvent> get stream => _subController.stream;

  /// Stream to trigger team data reload (e.g., after accepting invitation)
  Stream<void> get teamReloadStream => _teamReloadController.stream;

  /// Stream to trigger profile data reload (e.g., after creating/leaving team)
  Stream<void> get profileReloadStream => _profileReloadController.stream;

  /// Stream to navigate to a specific tab (e.g., switch to Team tab after accepting)
  Stream<int> get navigateToTabStream => _navigateToTabController.stream;

  /// Stream to trigger explore teams reload (e.g., after creating/disbanding team)
  Stream<void> get exploreTeamReloadStream => _exploreTeamReloadController.stream;

  /// Trigger team reload from anywhere in the app
  void triggerTeamReload() {
    _teamReloadController.add(null);
  }

  /// Trigger profile reload from anywhere in the app
  void triggerProfileReload() {
    _profileReloadController.add(null);
  }

  /// Trigger explore teams reload from anywhere in the app
  void triggerExploreTeamReload() {
    debugPrint('[EventBus] triggerExploreTeamReload called');
    _exploreTeamReloadController.add(null);
  }

  /// Navigate to a specific tab index
  void navigateToTab(int tabIndex) {
    _navigateToTabController.add(tabIndex);
  }

  Stream<WsIncomingEvent> get messageStream =>
      stream.where((e) => e.type == WsEventType.messageCreated);

  Stream<WsIncomingEvent> get privateMessageStream =>
      stream.where((e) => e.type == WsEventType.privateMessageCreated);

  Stream<WsIncomingEvent> get teamEventStream => stream.where((e) =>
      e.type == WsEventType.teamMemberJoined ||
      e.type == WsEventType.teamMemberLeft ||
      e.type == WsEventType.teamMemberReady ||
      e.type == WsEventType.teamMemberMicChanged ||
      e.type == WsEventType.teamDisbanded ||
      e.type == WsEventType.teamMemberKicked ||
      e.type == WsEventType.joinRequestCreated ||
      e.type == WsEventType.joinRequestAccepted);

  Stream<WsIncomingEvent> get joinRequestStream =>
      stream.where((e) => e.type == WsEventType.joinRequestCreated);

  Stream<WsIncomingEvent> get notificationStream => stream.where((e) =>
      e.type == WsEventType.notificationNew ||
      e.type == WsEventType.invitationReceived ||
      e.type == WsEventType.joinRequestAccepted ||
      e.type == WsEventType.joinRequestRejected);

  Stream<WsIncomingEvent> get matchStream =>
      stream.where((e) => e.type == WsEventType.matchCreated);

  Stream<WsIncomingEvent> get presenceStream => stream.where((e) =>
      e.type == WsEventType.userOnline || e.type == WsEventType.userOffline);

  Stream<WsIncomingEvent> get exploreTeamStream => stream.where((e) =>
      e.type == WsEventType.teamCreated ||
      e.type == WsEventType.teamDisbanded ||
      e.type == WsEventType.teamMemberJoined ||
      e.type == WsEventType.teamMemberLeft);

  Stream<WsIncomingEvent> get typingStream => stream.where((e) =>
      e.type == WsEventType.typingStart || e.type == WsEventType.typingStop);


  /// Register WebSocket client - safe to call multiple times.
  /// Nếu đã register rồi, sẽ re-register để đảm bảo nhận được events sau reconnect.
  void register(WebSocketClient ws) {
    // Cancel previous subscription if exists
    _wsSubscription?.cancel();

    _wsSubscription = ws.eventStream.listen((event) {
      _subController.add(event);
    });
    _isRegistered = true;
  }

  /// Unregister - call on app dispose.
  void unregister() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _isRegistered = false;
  }

  void dispose() {
    unregister();
    _subController.close();
    _teamReloadController.close();
    _profileReloadController.close();
    _navigateToTabController.close();
    _exploreTeamReloadController.close();
  }
}
