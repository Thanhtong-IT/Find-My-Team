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

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    return CommunityModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'No Name',
      game: json['gameName'] as String? ?? json['game'] as String? ?? '',
      description: json['description'] as String? ?? '',
      avatarPath: json['avatarPath'] as String? ?? json['avatarUrl'] as String?,
      coverPath: json['coverPath'] as String? ?? json['coverUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? true,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      onlineCount: (json['onlineCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    );
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? game,
    String? description,
    String? avatarPath,
    String? coverPath,
    bool? isPublic,
    int? memberCount,
    int? onlineCount,
    DateTime? createdAt,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      game: game ?? this.game,
      description: description ?? this.description,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      isPublic: isPublic ?? this.isPublic,
      memberCount: memberCount ?? this.memberCount,
      onlineCount: onlineCount ?? this.onlineCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
