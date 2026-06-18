enum MessageStatus { sending, sent, failed }

class ChatMessage {
  final String clientMessageId;
  final String? serverMessageId;
  final String? channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.clientMessageId,
    this.serverMessageId,
    this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.status = MessageStatus.sending,
  });

  ChatMessage copyWith({
    String? serverMessageId,
    MessageStatus? status,
  }) {
    return ChatMessage(
      clientMessageId: clientMessageId,
      serverMessageId: serverMessageId ?? this.serverMessageId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      timestamp: timestamp,
      status: status ?? this.status,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? clientId}) {
    return ChatMessage(
      clientMessageId: clientId ?? json['clientMessageId'] as String? ?? json['id'] as String,
      serverMessageId: json['id'] as String?,
      channelId: json['channelId']?.toString(),
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderDisplayName'] as String? ?? json['senderUsername'] as String? ?? 'Unknown',
      senderAvatar: json['senderAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      status: MessageStatus.sent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientMessageId': clientMessageId,
      'content': content,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
