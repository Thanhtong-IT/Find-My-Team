import 'dart:async';
import 'package:flutter/foundation.dart';
import '../websocket/websocket_client.dart';

class UnreadFriendManager {
  UnreadFriendManager._();
  static final UnreadFriendManager instance = UnreadFriendManager._();

  final Set<String> _unreadFriendIds = {};
  final _controller = StreamController<Set<String>>.broadcast();
  StreamSubscription? _wsSubscription;
  String? _currentUserId;
  String? activeChatFriendId;

  Set<String> get unreadFriendIds => Set.unmodifiable(_unreadFriendIds);
  Stream<Set<String>> get stream => _controller.stream;
  bool get hasUnread => _unreadFriendIds.isNotEmpty;

  void init(String currentUserId) {
    _currentUserId = currentUserId;
    _wsSubscription?.cancel();
    _wsSubscription = WebSocketClient.instance.eventStream.listen((event) {
      if (event.type == WsEventType.privateMessageCreated) {
        final senderId = event.data['senderId']?.toString();
        if (senderId != null && senderId.isNotEmpty && senderId != _currentUserId) {
          if (activeChatFriendId != senderId) {
            _unreadFriendIds.add(senderId);
            _controller.add(Set.from(_unreadFriendIds));
            debugPrint('[UnreadFriendManager] Added unread message from friend: $senderId');
          }
        }
      }
    });
    debugPrint('[UnreadFriendManager] Initialized for user: $currentUserId');
  }

  bool hasUnreadFrom(String friendId) => _unreadFriendIds.contains(friendId);

  void markAsRead(String friendId) {
    if (_unreadFriendIds.remove(friendId)) {
      _controller.add(Set.from(_unreadFriendIds));
      debugPrint('[UnreadFriendManager] Marked as read for friend: $friendId');
    }
  }

  void clear() {
    _unreadFriendIds.clear();
    _controller.add(Set.from(_unreadFriendIds));
  }

  void dispose() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
  }
}
