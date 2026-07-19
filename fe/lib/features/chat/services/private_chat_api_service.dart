import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/private_message.dart';

class PrivateChatApiService {
  /// Lấy lịch sử tin nhắn 1v1 giữa user hiện tại và friendId
  Future<List<PrivateMessage>> getChatHistory({
    required String friendId,
    int page = 0,
    int size = 20,
    String? currentUserId,
  }) async {
    try {
      final resp = await DioClient.get(
        '${ApiConstants.friendships}/chat/$friendId',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': 'createdAt,desc',
        },
      );
      
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] as String? ?? 'Không thể tải lịch sử chat');
      }

      // BẮT BUỘC: Bóc tách qua hai lớp data -> content cho API phân trang
      final dataMap = json['data'] as Map<String, dynamic>?;
      if (dataMap == null) return [];
      
      final list = dataMap['content'] as List<dynamic>?;
      if (list == null) return [];

      return list
          .map((e) => PrivateMessage.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
    } catch (e) {
      print('Lỗi PrivateChatApiService.getChatHistory: $e');
      rethrow;
    }
  }

  /// Gửi tin nhắn qua REST API (Dùng nếu không gửi qua WebSocket hoặc để fallback)
  Future<PrivateMessage> sendMessage({
    required String receiverId,
    required String content,
    required String clientMessageId,
  }) async {
    final resp = await DioClient.post(
      '${ApiConstants.friendships}/chat/send',
      data: {
        'receiverId': receiverId,
        'content': content,
        'clientMessageId': clientMessageId,
      },
    );

    final json = resp.data as Map<String, dynamic>?;
    if (json == null || json['success'] != true) {
      throw Exception(json?['message'] as String? ?? 'Không thể gửi tin nhắn');
    }

    return PrivateMessage.fromJson(json['data'] as Map<String, dynamic>);
  }
}
