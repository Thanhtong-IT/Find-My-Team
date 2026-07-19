class FriendshipModel {
  final String? id;
  final String friendId;
  final String friendUsername;
  final String? friendDisplayName;
  final String? friendAvatarUrl;
  final String status;
  final String? direction;
  final DateTime? createdAt;

  const FriendshipModel({
    this.id,
    required this.friendId,
    required this.friendUsername,
    this.friendDisplayName,
    this.friendAvatarUrl,
    this.status = 'pending',
    this.direction,
    this.createdAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? json['friendshipId']?.toString();
    final createdAtRaw = json['createdAt'] as String? ?? json['created_at'] as String?;
    return FriendshipModel(
      id: rawId?.isEmpty == true ? null : rawId,
      friendId: json['friendId']?.toString() ?? json['user_id']?.toString() ?? '',
      friendUsername: json['friendUsername'] as String? ??
          json['username'] as String? ??
          json['friend_name'] as String? ??
          '',
      friendDisplayName: json['friendDisplayName'] as String? ??
          json['displayName'] as String? ??
          json['friend_display_name'] as String?,
      friendAvatarUrl: json['friendAvatarUrl'] as String? ??
          json['avatarUrl'] as String? ??
          json['friend_avatar_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      direction: json['direction'] as String?,
      createdAt: createdAtRaw != null ? DateTime.tryParse(createdAtRaw) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isSent => direction == 'sent';
  bool get isReceived => direction == 'received';

  String get displayName => friendDisplayName?.trim().isNotEmpty == true ? friendDisplayName! : friendUsername;
}
