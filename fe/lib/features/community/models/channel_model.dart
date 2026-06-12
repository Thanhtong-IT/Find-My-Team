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
