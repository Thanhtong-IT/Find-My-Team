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

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.notificationStream.listen((event) {
      NotificationItemModel notif;
      if (event.type == WsEventType.joinRequestAccepted) {
        notif = NotificationItemModel(
          id: event.data['requestId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: event.type.name,
          title: 'Yêu cầu được chấp nhận!',
          body: 'Bạn đã được thêm vào nhóm. Nhấn để xem nhóm.',
          timestamp: DateTime.now(),
          actionId: event.data['teamId']?.toString(),
        );
      } else if (event.type == WsEventType.joinRequestRejected) {
        notif = NotificationItemModel(
          id: event.data['requestId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          type: event.type.name,
          title: 'Yêu cầu bị từ chối',
          body: 'Yêu cầu tham gia nhóm của bạn đã bị từ chối.',
          timestamp: DateTime.now(),
          actionId: null,
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
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final notifs = await _apiService.getNotifications();
      final unread = notifs.where((n) => !n.isRead).length;
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifs,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(state.copyWith(status: NotificationStatus.error, errorMessage: 'Không thể tải thông báo'));
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

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
