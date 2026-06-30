import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  Future<void> acceptInvitation(String invitationId) async {
    final resp = await DioClient.post('${ApiConstants.invitations}/$invitationId/accept');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể chấp nhận lời mời',
      );
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    final resp = await DioClient.post('${ApiConstants.invitations}/$invitationId/reject');
    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw DioException(
        requestOptions: resp.requestOptions,
        message: json?['message'] as String? ?? 'Không thể từ chối lời mời',
      );
    }
  }

  NotificationItemModel _fromJson(Map<String, dynamic> json) {
    // DEBUG LOG
    debugPrint('[NOTIFICATION_DEBUG] Parsing notification: $json');

    // Check for null id
    final idRaw = json['id'];
    if (idRaw == null) {
      debugPrint('[NOTIFICATION_DEBUG] ERROR: id is null in notification json');
      throw Exception('Notification id is null');
    }

    // Check for timestamp field name - backend uses 'createdAt'
    DateTime timestamp;
    if (json['timestamp'] != null) {
      timestamp = DateTime.parse(json['timestamp'] as String);
    } else if (json['createdAt'] != null) {
      timestamp = DateTime.parse(json['createdAt'] as String);
      debugPrint('[NOTIFICATION_DEBUG] NOTE: using createdAt instead of timestamp');
    } else {
      debugPrint('[NOTIFICATION_DEBUG] NOTE: no timestamp field found, using now');
      timestamp = DateTime.now();
    }

    return NotificationItemModel(
      id: idRaw.toString(),
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? 'Thông báo',
      body: json['body'] as String? ?? '',
      timestamp: timestamp,
      isRead: json['isRead'] as bool? ?? false,
      actionId: json['actionId']?.toString(),
    );
  }
}
