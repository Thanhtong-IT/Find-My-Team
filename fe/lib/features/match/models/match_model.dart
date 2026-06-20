class MatchModel {
  final String id;
  final String userAId;
  final String userAUsername;
  final String? userADisplayName;
  final String? userAAvatarUrl;
  final String userBId;
  final String? userBUsername;
  final String? userBDisplayName;
  final String? userBAvatarUrl;
  final String? gameId;
  final DateTime createdAt;

  const MatchModel({
    required this.id,
    required this.userAId,
    required this.userAUsername,
    this.userADisplayName,
    this.userAAvatarUrl,
    required this.userBId,
    this.userBUsername,
    this.userBDisplayName,
    this.userBAvatarUrl,
    this.gameId,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id']?.toString() ?? '',
      userAId: json['userAId']?.toString() ?? '',
      userAUsername: json['userAUsername'] as String? ?? '',
      userADisplayName: json['userADisplayName'] as String?,
      userAAvatarUrl: json['userAAvatarUrl'] as String?,
      userBId: json['userBId']?.toString() ?? '',
      userBUsername: json['userBUsername'] as String?,
      userBDisplayName: json['userBDisplayName'] as String?,
      userBAvatarUrl: json['userBAvatarUrl'] as String?,
      gameId: json['gameId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
