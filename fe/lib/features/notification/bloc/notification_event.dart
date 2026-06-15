import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
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
}
