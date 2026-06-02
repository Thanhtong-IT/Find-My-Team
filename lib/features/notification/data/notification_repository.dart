import '../models/notification_model.dart';

class NotificationRepository {
  static final NotificationRepository _instance = NotificationRepository._internal();
  factory NotificationRepository() => _instance;
  NotificationRepository._internal() { _initDefaults(); }

  final List<NotificationModel> _notifications = [];

  void _initDefaults() {
    final now = DateTime.now();
    _notifications.addAll([
      NotificationModel(id: 'n1', type: NotificationType.joinRequest, title: 'Yêu cầu vào nhóm', body: 'Alex Storm muốn tham gia nhóm của bạn', timestamp: now.subtract(const Duration(minutes: 5)), isRead: false, avatarUrl: null, actionId: 'req_alex', actionId2: 'n1'),
      NotificationModel(id: 'n2', type: NotificationType.joinRequest, title: 'Yêu cầu vào nhóm', body: 'Minh Gấu muốn tham gia nhóm của bạn', timestamp: now.subtract(const Duration(minutes: 15)), isRead: false, avatarUrl: null, actionId: 'req_minh', actionId2: 'n2'),
      NotificationModel(id: 'n3', type: NotificationType.teamInvite, title: 'Lời mời vào đội', body: 'ShadowHunter muốn mời bạn vào đội rank Kim Cương', timestamp: now.subtract(const Duration(minutes: 30)), isRead: false, avatarUrl: null, actionId: null, actionId2: 'n3'),
      NotificationModel(id: 'n4', type: NotificationType.chatMessage, title: 'Tin nhắn mới', body: 'PhantomX: Mình sẵn sàng rank cùng bạn rồi!', timestamp: now.subtract(const Duration(hours: 1)), isRead: false, avatarUrl: null, actionId: null, actionId2: 'n4'),
      NotificationModel(id: 'n5', type: NotificationType.communityPost, title: 'Cộng đồng có bài viết mới', body: 'Liên Minh Đại Chiến: Bài viết "Hướng dẫn leo rank mùa 25"', timestamp: now.subtract(const Duration(hours: 2)), isRead: true, avatarUrl: null, actionId: null, actionId2: 'n5'),
      NotificationModel(id: 'n6', type: NotificationType.requestAccepted, title: 'Yêu cầu được chấp nhận', body: 'Yêu cầu tham gia nhóm của bạn đã được chấp nhận!', timestamp: now.subtract(const Duration(hours: 3)), isRead: true, avatarUrl: null, actionId: null, actionId2: 'n6'),
      NotificationModel(id: 'n7', type: NotificationType.requestRejected, title: 'Yêu cầu bị từ chối', body: 'Yêu cầu tham gia nhóm "PUBG VN" đã bị từ chối.', timestamp: now.subtract(const Duration(hours: 5)), isRead: true, avatarUrl: null, actionId: null, actionId2: 'n7'),
      NotificationModel(id: 'n8', type: NotificationType.chatMessage, title: 'Tin nhắn mới', body: 'NightHawk: Tối nay rank cùng nhau nhé!', timestamp: now.subtract(const Duration(days: 1)), isRead: true, avatarUrl: null, actionId: null, actionId2: 'n8'),
    ]);
  }

  List<NotificationModel> getNotifications() => List.unmodifiable(_notifications);

  List<NotificationModel> getRequests() =>
    _notifications.where((n) => n.type == NotificationType.joinRequest || n.type == NotificationType.teamInvite).toList();

  List<NotificationModel> getInfo() =>
    _notifications.where((n) => n.type == NotificationType.communityPost || n.type == NotificationType.chatMessage || n.type == NotificationType.requestAccepted || n.type == NotificationType.requestRejected).toList();

  void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) _notifications[idx] = _notifications[idx].copyWith(isRead: true);
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  void acceptRequest(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  void rejectRequest(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  bool get hasUnread => _notifications.any((n) => !n.isRead);
}
