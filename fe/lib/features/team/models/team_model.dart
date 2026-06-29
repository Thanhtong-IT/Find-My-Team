class TeamModel {
  final String id;
  final String name;
  final String? description;
  final String gameId;
  final String gameName;
  final String? requiredRank;
  final int maxMembers;
  final String ownerId;
  final String ownerName;
  final bool isRecruiting;
  final List<TeamMemberModel> members;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    required this.gameId,
    required this.gameName,
    this.requiredRank,
    required this.maxMembers,
    required this.ownerId,
    required this.ownerName,
    this.isRecruiting = false,
    this.members = const [],
    required this.createdAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'recruiting';
    final membersJson = json['members'] as List<dynamic>?;
    final membersList = membersJson
            ?.map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    
    // Find owner from members if not explicitly provided
    String resolvedOwnerName = json['ownerName'] as String? ?? '';
    if (resolvedOwnerName.isEmpty && membersList.isNotEmpty) {
      final owner = membersList.firstWhere(
        (m) => m.isLeader, 
        orElse: () => membersList.first,
      );
      resolvedOwnerName = owner.displayName;
    }

    return TeamModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'No Name',
      description: json['description'] as String?,
      gameId: json['gameId']?.toString() ?? '',
      gameName: json['gameName'] as String? ?? '',
      requiredRank: json['requiredRank'] as String?,
      maxMembers: (json['maxSize'] as num?)?.toInt() ?? (json['maxMembers'] as num?)?.toInt() ?? 5,
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: resolvedOwnerName,
      isRecruiting: statusStr == 'recruiting' || json['isRecruiting'] == true,
      members: membersList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TeamMemberModel {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? role;
  final bool isReady;
  final bool isMicEnabled;
  final bool isOnline;
  final bool isLeader;

  const TeamMemberModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.role,
    this.isReady = false,
    this.isMicEnabled = false,
    this.isOnline = false,
    this.isLeader = false,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String? ?? 'member';
    return TeamMemberModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName'] as String? ?? json['username'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      role: roleStr,
      isReady: json['isReady'] as bool? ?? json['ready'] as bool? ?? false,
      isMicEnabled: json['isMicEnabled'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      isLeader: roleStr == 'owner',
    );
  }
}

class JoinRequestModel {
  final String id;
  final String teamId;
  final String userId;
  final String userDisplayName;
  final String? userAvatarUrl;
  final String? message;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  const JoinRequestModel({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.userDisplayName,
    this.userAvatarUrl,
    this.message,
    this.status = 'pending',
    required this.createdAt,
  });

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) {
    return JoinRequestModel(
      id: json['id']?.toString() ?? '',
      teamId: json['teamId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userDisplayName: json['displayName'] as String? ?? json['username'] as String? ?? 'Unknown',
      userAvatarUrl: json['avatarUrl'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
