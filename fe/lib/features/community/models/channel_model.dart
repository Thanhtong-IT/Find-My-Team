enum ChannelType { text, voice }

class ChannelModel {
  final String id;
  final String name;
  final ChannelType type;
  final String communityId;
  final int memberCount;
  final int onlineCount;
  final DateTime createdAt;

  ChannelModel({
    required this.id,
    required this.name,
    required this.type,
    required this.communityId,
    this.memberCount = 0,
    this.onlineCount = 0,
    required this.createdAt,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'text';
    final type = typeStr == 'voice' ? ChannelType.voice : ChannelType.text;
    return ChannelModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      type: type,
      communityId: json['communityId']?.toString() ?? json['community_id']?.toString() ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      onlineCount: (json['onlineCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  String get displayName => type == ChannelType.text ? '# $name' : '\uD83D\uDD0A $name';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'communityId': communityId,
    'memberCount': memberCount,
    'onlineCount': onlineCount,
    'createdAt': createdAt.toIso8601String(),
  };
}
