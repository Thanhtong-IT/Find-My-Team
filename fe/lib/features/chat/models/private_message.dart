enum PrivateMessageStatus { sending, sent, failed }

class PrivateMessage {
  final String? id; // Server ID
  final String clientMessageId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final PrivateMessageStatus status;
  final bool isMe;

  const PrivateMessage({
    this.id,
    required this.clientMessageId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.status = PrivateMessageStatus.sent,
    this.isMe = false,
  });

  factory PrivateMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId']?.toString() ?? '';
    return PrivateMessage(
      id: json['id']?.toString(),
      clientMessageId: json['clientMessageId'] as String? ?? json['id']?.toString() ?? '',
      senderId: senderId,
      receiverId: json['receiverId']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      status: PrivateMessageStatus.sent,
      isMe: currentUserId != null && senderId == currentUserId,
    );
  }

  PrivateMessage copyWith({
    String? id,
    String? clientMessageId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    PrivateMessageStatus? status,
    bool? isMe,
  }) {
    return PrivateMessage(
      id: id ?? this.id,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      isMe: isMe ?? this.isMe,
    );
  }
}
