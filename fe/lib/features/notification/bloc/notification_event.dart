import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

class NotificationMarkAsReadRequested extends NotificationEvent {
  final String notificationId;
  const NotificationMarkAsReadRequested(this.notificationId);
  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllReadRequested extends NotificationEvent {
  const NotificationMarkAllReadRequested();
}

class NotificationNewReceived extends NotificationEvent {
  final NotificationItemModel notif;
  const NotificationNewReceived(this.notif);
  @override
  List<Object?> get props => [notif];
}

class NotificationAcceptInvitationRequested extends NotificationEvent {
  final String notificationId;
  final String invitationId;
  const NotificationAcceptInvitationRequested({
    required this.notificationId,
    required this.invitationId,
  });
  @override
  List<Object?> get props => [notificationId, invitationId];
}

class NotificationRejectInvitationRequested extends NotificationEvent {
  final String notificationId;
  final String invitationId;
  const NotificationRejectInvitationRequested({
    required this.notificationId,
    required this.invitationId,
  });
  @override
  List<Object?> get props => [notificationId, invitationId];
}

class NotificationItemModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? actionId;

  const NotificationItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.actionId,
  });

  NotificationItemModel copyWith({bool? isRead}) {
    return NotificationItemModel(
      id: id,
      type: type,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      actionId: actionId,
    );
  }
}
