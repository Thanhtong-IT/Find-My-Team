class CommunityModel {
  final String id;
  final String name;
  final String game;
  final String description;
  final String? avatarPath;
  final String? coverPath;
  final bool isPublic;
  final int memberCount;
  final int onlineCount;
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.name,
    required this.game,
    required this.description,
    this.avatarPath,
    this.coverPath,
    required this.isPublic,
    this.memberCount = 0,
    this.onlineCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'game': game,
    'description': description,
    'avatarPath': avatarPath,
    'coverPath': coverPath,
    'isPublic': isPublic,
    'memberCount': memberCount,
    'onlineCount': onlineCount,
    'createdAt': createdAt.toIso8601String(),
  };
}
