import 'package:equatable/equatable.dart';
import 'notification_event.dart';

enum NotificationStatus { initial, loading, loaded, error }

enum ActionStatus { idle, accepting, rejecting, success, error }

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationItemModel> notifications;
  final int unreadCount;
  final String? errorMessage;
  final ActionStatus actionStatus;
  final String? actionMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
    this.actionStatus = ActionStatus.idle,
    this.actionMessage,
  });

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationItemModel>? notifications,
    int? unreadCount,
    String? errorMessage,
    ActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, unreadCount, errorMessage, actionStatus, actionMessage];
}
