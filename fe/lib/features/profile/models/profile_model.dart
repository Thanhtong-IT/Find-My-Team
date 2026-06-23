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
  final String? gameName;
  final String? role;
  final String memberCount;
  final bool isOnline;

  const CommunityInfoModel({
    required this.id,
    required this.name,
    this.gameName,
    this.role,
    this.memberCount = '',
    this.isOnline = false,
  });
}

class ProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final GameInfoModel? gameInfo;
  final List<StatModel> stats;
  final TeamInfoModel? currentTeam;
  final List<CommunityInfoModel> communities;

  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
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
  final String? verifiedRank;
  final String? rankSource;
  final String? role;
  final bool hasMic;
  final bool isPrimary;
  final String? riotGameName;
  final String? riotTagLine;
  final String? riotRegion;
  final String? riotVerificationStatus;
  final bool riotVerified;
  final DateTime? riotVerifiedAt;
  final DateTime? riotProfileLastSyncedAt;
  final DateTime createdAt;

  const UserGameProfileModel({
    required this.id,
    required this.gameId,
    this.gameName,
    this.rank,
    this.verifiedRank,
    this.rankSource,
    this.role,
    this.hasMic = false,
    this.isPrimary = false,
    this.riotGameName,
    this.riotTagLine,
    this.riotRegion,
    this.riotVerificationStatus,
    this.riotVerified = false,
    this.riotVerifiedAt,
    this.riotProfileLastSyncedAt,
    required this.createdAt,
  });

  bool get usesVerifiedRank => (rankSource ?? '').toUpperCase() == 'RIOT';

  String? get displayRank => verifiedRank ?? rank;

  String? get riotIdDisplay {
    final gameName = riotGameName?.trim();
    final tagLine = riotTagLine?.trim();
    if (gameName == null || gameName.isEmpty || tagLine == null || tagLine.isEmpty) {
      return null;
    }
    return '$gameName#$tagLine';
  }

  factory UserGameProfileModel.fromJson(Map<String, dynamic> json) {
    return UserGameProfileModel(
      id: json['id']?.toString() ?? '',
      gameId: json['gameId']?.toString() ?? '',
      gameName: json['gameName'] as String?,
      rank: json['rank'] as String?,
      verifiedRank: json['verifiedRank'] as String?,
      rankSource: json['rankSource'] as String?,
      role: json['role'] as String?,
      hasMic: json['hasMic'] as bool? ?? false,
      isPrimary: json['isPrimary'] as bool? ?? false,
      riotGameName: json['riotGameName'] as String?,
      riotTagLine: json['riotTagLine'] as String?,
      riotRegion: json['riotRegion'] as String?,
      riotVerificationStatus: json['riotVerificationStatus'] as String?,
      riotVerified: json['riotVerified'] as bool? ?? false,
      riotVerifiedAt: json['riotVerifiedAt'] != null
          ? DateTime.tryParse(json['riotVerifiedAt'] as String)
          : null,
      riotProfileLastSyncedAt: json['riotProfileLastSyncedAt'] != null
          ? DateTime.tryParse(json['riotProfileLastSyncedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class GameProfileUpdateItem {
  final String? id;
  final String gameId;
  final String? rank;
  final String? role;
  final bool hasMic;
  final bool isPrimary;

  const GameProfileUpdateItem({
    this.id,
    required this.gameId,
    this.rank,
    this.role,
    this.hasMic = false,
    this.isPrimary = false,
  });

  factory GameProfileUpdateItem.fromModel(UserGameProfileModel model) {
    return GameProfileUpdateItem(
      id: model.id,
      gameId: model.gameId,
      rank: model.rank,
      role: model.role,
      hasMic: model.hasMic,
      isPrimary: model.isPrimary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'gameId': gameId,
      'rank': rank,
      'role': role,
      'hasMic': hasMic,
      'isPrimary': isPrimary,
    };
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

    TeamInfoModel? parsedTeam;
    if (currentTeamJson != null) {
      final teamName = currentTeamJson['name'] as String?;
      final teamId = currentTeamJson['id'];
      if ((teamName != null && teamName.isNotEmpty) || teamId != null) {
        parsedTeam = TeamInfoModel(
          teamName: teamName ?? '',
          game: currentTeamJson['gameName'] as String? ?? '',
          memberCount: (currentTeamJson['memberCount'] as num?)?.toInt() ?? 1,
          myRole: currentTeamJson['role'] as String? ?? 'Thành viên',
        );
      }
    }

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
      currentTeam: parsedTeam,
      communities: communitiesJson
              ?.map((e) {
                final m = e as Map<String, dynamic>;
                return CommunityInfoModel(
                  id: m['id']?.toString() ?? '',
                  name: m['name'] as String? ?? '',
                  gameName: m['gameName'] as String?,
                  role: m['role'] as String?,
                  memberCount: '0',
                  isOnline: false,
                );
              })
              .toList() ??
          [],
    );
  }
}
