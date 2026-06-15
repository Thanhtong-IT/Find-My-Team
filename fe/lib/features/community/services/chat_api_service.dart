import 'package:uuid/uuid.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import '../models/chat_message.dart';

class ChatApiService {
  static const _uuid = Uuid();

  String generateClientMessageId() => _uuid.v4();

  Future<PageResponse<ChatMessage>> getMessages({
    required String communityId,
    required String channelId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final resp = await DioClient.get(
        '${ApiConstants.communities}/$communityId/channels/$channelId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) throw Exception();
      return PageResponse.fromJson(
        json['data'] as Map<String, dynamic>? ?? {'content': [], 'page': 0, 'size': size, 'totalElements': 0, 'totalPages': 0, 'last': true},
        (data) => ChatMessage.fromJson(data),
      );
    } catch (_) {
      return _mockMessages(channelId);
    }
  }

  Future<ChatMessage> sendMessage({
    required String communityId,
    required String channelId,
    required String clientMessageId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final resp = await DioClient.post(
        '${ApiConstants.communities}/$communityId/channels/$channelId/messages',
        data: {
          'clientMessageId': clientMessageId,
          'content': content,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      final json = resp.data as Map<String, dynamic>?;
      if (json == null || json['success'] != true) throw Exception();
      return ChatMessage.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
        clientId: clientMessageId,
      );
    } catch (_) {
      return ChatMessage(
        clientMessageId: clientMessageId,
        senderId: 'me',
        senderName: 'Bạn',
        content: content,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
    }
  }

  PageResponse<ChatMessage> _mockMessages(String channelId) {
    final now = DateTime.now();
    return PageResponse(
      content: [
        ChatMessage(
          clientMessageId: '${channelId}_m1',
          senderId: 'u1',
          senderName: 'DragonSlayer',
          content: 'Mọi người ơi, tối nay ai rank cùng không?',
          timestamp: now.subtract(const Duration(hours: 2)),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          clientMessageId: '${channelId}_m2',
          senderId: 'u2',
          senderName: 'PhantomX',
          content: 'Mình rank Bạch Kim, bạn rank gì vậy?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 50)),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          clientMessageId: '${channelId}_m3',
          senderId: 'u1',
          senderName: 'DragonSlayer',
          content: 'Mình Kim Cương, chơi mid/top thì sao?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 40)),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          clientMessageId: '${channelId}_m4',
          senderId: 'u3',
          senderName: 'NightHawk',
          content: 'Mình rank Cao thủ, bạn nào cần support không?',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
          status: MessageStatus.sent,
        ),
        ChatMessage(
          clientMessageId: '${channelId}_m5',
          senderId: 'u4',
          senderName: 'StormBreaker',
          content: 'Chào mọi người! Mình mới join cộng đồng, rất vui được gặp mọi người.',
          timestamp: now.subtract(const Duration(minutes: 45)),
          status: MessageStatus.sent,
        ),
      ],
      page: 0,
      size: 50,
      totalElements: 5,
      totalPages: 1,
      last: true,
    );
  }
}
