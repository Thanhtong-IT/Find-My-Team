import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/events/event_bus.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  StreamSubscription? _wsSub;

  NotificationBloc() : super(const NotificationState()) {
    on<NotificationLoadRequested>(_onLoadRequested);
    on<NotificationMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationNewReceived>(_onNewReceived);

    _listenWebSocket();
  }

  void _listenWebSocket() {
    _wsSub = AppEventBus.instance.notificationStream.listen((event) {
      final notif = NotificationItemModel(
        id: event.data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: event.type.name,
        title: event.data['title'] as String? ?? 'Thông báo mới',
        body: event.data['body'] as String? ?? '',
        timestamp: DateTime.now(),
        actionId: event.data['actionId']?.toString(),
      );
      add(NotificationNewReceived(notif));
    });
  }

  Future<void> _onLoadRequested(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading));
    try {
      final resp = await DioClient.get(ApiConstants.notifications);
      final json = resp.data as Map<String, dynamic>;
      if (json['success'] != true) throw Exception();
      final list = json['data'] as List<dynamic>;
      final notifs = list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
      final unread = notifs.where((n) => !n.isRead).length;
      emit(state.copyWith(
        status: NotificationStatus.loaded,
        notifications: notifs,
        unreadCount: unread,
      ));
    } catch (e) {
      emit(state.copyWith(status: NotificationStatus.error));
    }
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await DioClient.put(ApiConstants.markAllRead);
      emit(state.copyWith(
        unreadCount: 0,
        notifications: state.notifications.map((n) {
          return NotificationItemModel(
            id: n.id,
            type: n.type,
            title: n.title,
            body: n.body,
            timestamp: n.timestamp,
            isRead: true,
            actionId: n.actionId,
          );
        }).toList(),
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

  NotificationItemModel _fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'].toString(),
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? 'Thông báo',
      body: json['body'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      actionId: json['actionId']?.toString(),
    );
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
