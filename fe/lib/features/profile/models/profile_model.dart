class GameInfoModel {
  final String gameName;
  final String rank;
  final String role;
  final bool hasMic;

  const GameInfoModel({
    required this.gameName,
    required this.rank,
    required this.role,
    required this.hasMic,
  });
}

class StatModel {
  final String label;
  final String value;

  const StatModel({required this.label, required this.value});
}

class TeamInfoModel {
  final String teamName;
  final String game;
  final int memberCount;
  final String myRole;

  const TeamInfoModel({
    required this.teamName,
    required this.game,
    required this.memberCount,
    required this.myRole,
  });
}

class CommunityInfoModel {
  final String id;
  final String name;
  final String memberCount;
  final bool isOnline;

  const CommunityInfoModel({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.isOnline,
  });
}

class ProfileModel {
  final String id;
  final String displayName;
  final String username;
  final bool isOnline;
  final GameInfoModel? gameInfo;
  final List<StatModel> stats;
  final TeamInfoModel? currentTeam;
  final List<CommunityInfoModel> communities;

  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.isOnline = false,
    this.gameInfo,
    this.stats = const [],
    this.currentTeam,
    this.communities = const [],
  });

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    GameInfoModel? gameInfo,
  }) {
    return ProfileModel(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username,
      isOnline: isOnline,
      gameInfo: gameInfo ?? this.gameInfo,
      stats: stats,
      currentTeam: currentTeam,
      communities: communities,
    );
  }
}

class UserGameProfileModel {
  final String id;
  final String gameId;
  final String? gameName;
  final String? rank;
  final String? role;
  final bool hasMic;
  final DateTime createdAt;

  const UserGameProfileModel({
    required this.id,
    required this.gameId,
    this.gameName,
    this.rank,
    this.role,
    this.hasMic = false,
    required this.createdAt,
  });

  factory UserGameProfileModel.fromJson(Map<String, dynamic> json) {
    return UserGameProfileModel(
      id: json['id']?.toString() ?? '',
      gameId: json['gameId']?.toString() ?? '',
      gameName: json['gameName'] as String?,
      rank: json['rank'] as String?,
      role: json['role'] as String?,
      hasMic: json['hasMic'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class UserProfileModel {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? region;
  final bool isOnline;
  final List<UserGameProfileModel> gameProfiles;
  final TeamInfoModel? currentTeam;
  final List<CommunityInfoModel> communities;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.region,
    this.isOnline = false,
    this.gameProfiles = const [],
    this.currentTeam,
    this.communities = const [],
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final currentTeamJson = json['currentTeam'] as Map<String, dynamic>?;
    final communitiesJson = json['communities'] as List<dynamic>?;

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? 'unknown',
      fullName: json['fullName'] as String?,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      region: json['region'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      gameProfiles: (json['gameProfiles'] as List<dynamic>?)
              ?.map((e) => UserGameProfileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentTeam: currentTeamJson != null
          ? TeamInfoModel(
              teamName: currentTeamJson['name'] as String? ?? '',
              game: currentTeamJson['gameName'] as String? ?? '',
              memberCount: 0,
              myRole: currentTeamJson['role'] as String? ?? '',
            )
          : null,
      communities: communitiesJson
              ?.map((e) {
                final m = e as Map<String, dynamic>;
                return CommunityInfoModel(
                  id: m['id']?.toString() ?? '',
                  name: m['name'] as String? ?? '',
                  memberCount: '0',
                  isOnline: false,
                );
              })
              .toList() ??
          [],
    );
  }
}
