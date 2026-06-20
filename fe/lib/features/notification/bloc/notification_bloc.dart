import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/websocket/websocket_client.dart';
import '../services/notification_api_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationApiService _apiService;
  StreamSubscription? _wsSub;

  NotificationBloc({NotificationApiService? apiService})
      : _apiService = apiService ?? NotificationApiService(),
        super(const NotificationState()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationMarkAsReadRequested>(_onMarkAsRead);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationNewReceived>(_onNewReceived);
    on<NotificationAcceptInvitationRequested>(_onAcceptInvitation);
    on<NotificationRejectInvitationRequested>(_onRejectInvitation);

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.notificationStream.listen((event) {
      print('[WS_DEBUG] Received event: type=${event.type}, data=${event.data}');

      NotificationItemModel notif;
      if (event.type == WsEventType.joinRequestAccepted) {
        notif = NotificationItemModel(
          id: event.data['requestId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'join_request',
          title: 'Yêu cầu được chấp nhận!',
          body: 'Bạn đã được thêm vào nhóm. Nhấn để xem nhóm.',
          timestamp: DateTime.now(),
          actionId: event.data['teamId']?.toString(),
        );
      } else if (event.type == WsEventType.joinRequestRejected) {
        notif = NotificationItemModel(
          id: event.data['requestId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'join_request',
          title: 'Yêu cầu bị từ chối',
          body: 'Yêu cầu tham gia nhóm của bạn đã bị từ chối.',
          timestamp: DateTime.now(),
          actionId: null,
        );
      } else if (event.type == WsEventType.invitationReceived) {
        notif = NotificationItemModel(
          id: event.data['invitationId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'team_invite',
          title: 'Bạn có lời mời mới',
          body: 'Có người muốn chơi cùng bạn',
          timestamp: DateTime.now(),
          actionId: event.data['invitationId']?.toString(),
        );
      } else {
        notif = NotificationItemModel(
          id: event.data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: event.type.name,
          title: event.data['title'] as String? ?? 'Thông báo mới',
          body: event.data['body'] as String? ?? '',
          timestamp: DateTime.now(),
          actionId: event.data['actionId']?.toString(),
        );
      }

      add(NotificationNewReceived(notif));
    });
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    print('[BLOC_DEBUG] _onLoadRequested called');
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      print('[BLOC_DEBUG] Calling API...');
      final notifs = await _apiService.getNotifications();
      print('[BLOC_DEBUG] Got ${notifs.length} notifications');
      final unread = notifs.where((n) => !n.isRead).length;
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifs,
        unreadCount: unread,
      ));
      print('[BLOC_DEBUG] State updated successfully');
    } catch (e, stack) {
      print('[BLOC_DEBUG] ERROR loading notifications: $e');
      print('[BLOC_DEBUG] Stack trace: $stack');
      emit(state.copyWith(status: NotificationStatus.error, errorMessage: 'Không thể tải thông báo: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    NotificationMarkAsReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _apiService.markAsRead(event.notificationId);
      final updated = state.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      emit(state.copyWith(
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      ));
    } catch (_) {}
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _apiService.markAllAsRead();
      emit(state.copyWith(
        unreadCount: 0,
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      ));
    } catch (_) {}
  }

  void _onNewReceived(
    NotificationNewReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      notifications: [event.notif, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    ));
  }

  Future<void> _onAcceptInvitation(
    NotificationAcceptInvitationRequested event,
    Emitter<NotificationState> emit,
  ) async {
    NotificationItemModel? notification;
    for (final item in state.notifications) {
      if (item.id == event.notificationId) {
        notification = item;
        break;
      }
    }

    if (notification?.type != 'team_invite') {
      emit(state.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Yêu cầu tham gia chỉ xử lý trong mục Team',
      ));
      return;
    }

    emit(state.copyWith(actionStatus: ActionStatus.accepting));

    try {
      await _apiService.acceptInvitation(event.invitationId);

      final updated = state.notifications.where((n) => n.id != event.notificationId).toList();
      emit(state.copyWith(
        actionStatus: ActionStatus.success,
        actionMessage: 'Đã chấp nhận lời mời!',
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Không thể chấp nhận lời mời',
      ));
    }
  }

  Future<void> _onRejectInvitation(
    NotificationRejectInvitationRequested event,
    Emitter<NotificationState> emit,
  ) async {
    NotificationItemModel? notification;
    for (final item in state.notifications) {
      if (item.id == event.notificationId) {
        notification = item;
        break;
      }
    }

    if (notification?.type != 'team_invite') {
      emit(state.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Yêu cầu tham gia chỉ xử lý trong mục Team',
      ));
      return;
    }

    emit(state.copyWith(actionStatus: ActionStatus.rejecting));

    try {
      await _apiService.rejectInvitation(event.invitationId);

      final updated = state.notifications.where((n) => n.id != event.notificationId).toList();
      emit(state.copyWith(
        actionStatus: ActionStatus.success,
        actionMessage: 'Đã từ chối lời mời',
        notifications: updated,
        unreadCount: updated.where((n) => !n.isRead).length,
      ));
    } catch (e) {
      emit(state.copyWith(
        actionStatus: ActionStatus.error,
        actionMessage: 'Không thể từ chối lời mời',
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
