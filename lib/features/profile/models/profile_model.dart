class GameInfoModel {
  final String gameName;
  final String rank;
  final String role;
  final bool hasMic;

  GameInfoModel({
    required this.gameName,
    required this.rank,
    required this.role,
    required this.hasMic,
  });
}

class StatModel {
  final String label;
  final String value;
  final String? icon;

  StatModel({required this.label, required this.value, this.icon});
}

class TeamInfoModel {
  final String teamName;
  final String game;
  final int memberCount;
  final String myRole;

  TeamInfoModel({required this.teamName, required this.game, required this.memberCount, required this.myRole});
}

class CommunityInfoModel {
  final String id;
  final String name;
  final String memberCount;
  final bool isOnline;

  CommunityInfoModel({required this.id, required this.name, required this.memberCount, required this.isOnline});
}

class ProfileModel {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final GameInfoModel gameInfo;
  final List<StatModel> stats;
  final TeamInfoModel? currentTeam;
  final List<CommunityInfoModel> communities;

  ProfileModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isOnline = true,
    required this.gameInfo,
    required this.stats,
    this.currentTeam,
    required this.communities,
  });

  ProfileModel copyWith({
    String? displayName,
    String? avatarUrl,
    GameInfoModel? gameInfo,
  }) => ProfileModel(
    id: id, displayName: displayName ?? this.displayName,
    username: username, avatarUrl: avatarUrl ?? this.avatarUrl,
    isOnline: isOnline, gameInfo: gameInfo ?? this.gameInfo,
    stats: stats, currentTeam: currentTeam, communities: communities,
  );
}
