enum NotificationType {
  teamInvite,
  joinRequest,
  communityPost,
  chatMessage,
  requestAccepted,
  requestRejected,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;
  final String? actionId;
  final String? actionId2;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
    this.actionId,
    this.actionId2,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id, type: type, title: title, body: body,
    timestamp: timestamp, isRead: isRead ?? this.isRead,
    avatarUrl: avatarUrl, actionId: actionId, actionId2: actionId2,
  );
}
