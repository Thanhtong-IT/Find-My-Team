import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../bloc/notification_event.dart';

class NotificationApiService {
  Future<List<NotificationItemModel>> getNotifications() async {
    final resp = await DioClient.get(ApiConstants.notifications);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể tải thông báo',
      );
    }
    final list = json['data'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final resp = await DioClient.get(ApiConstants.notificationsUnreadCount);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      return 0;
    }
    return json['count'] as int? ?? 0;
  }

  Future<void> markAsRead(String notificationId) async {
    final resp = await DioClient.put('${ApiConstants.notifications}/$notificationId/read');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể đánh dấu đã đọc',
      );
    }
  }

  Future<void> markAllAsRead() async {
    final resp = await DioClient.put(ApiConstants.markAllRead);
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể đánh dấu tất cả đã đọc',
      );
    }
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
}
