import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../community/models/chat_message.dart';

class TeamChatApiService {
  Future<List<ChatMessage>> getMessages({
    required String teamId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final resp = await DioClient.get(
        '${ApiConstants.teams}/$teamId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        throw Exception(json?['message'] as String? ?? 'Không thể tải tin nhắn');
      }
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => _teamMessageFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<ChatMessage?> sendMessage({
    required String teamId,
    required String clientMessageId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'clientMessageId': clientMessageId,
        'content': content,
      };
      if (imageUrl != null) payload['imageUrl'] = imageUrl;
      final resp = await DioClient.post(
        '${ApiConstants.teams}/$teamId/messages',
        data: payload,
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) {
        return null;
      }
      return _teamMessageFromJson(
        json['data'] as Map<String, dynamic>? ?? {},
        clientId: clientMessageId,
      );
    } catch (_) {
      return null;
    }
  }

  ChatMessage _teamMessageFromJson(Map<String, dynamic> json, {String? clientId}) {
    return ChatMessage(
      clientMessageId: clientId ?? json['clientMessageId'] as String? ?? json['id'] as String? ?? '',
      serverMessageId: json['id'] as String?,
      channelId: json['teamId']?.toString(),
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderAvatar: json['senderAvatar'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
      status: MessageStatus.sent,
    );
  }
}
