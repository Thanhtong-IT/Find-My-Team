import 'package:equatable/equatable.dart';

class OnlinePlayer {
  final int id;
  final String displayName;
  final String? avatarUrl;
  final String gameName;
  final String? rank;
  final String? role;
  final bool isOnline;

  const OnlinePlayer({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    required this.gameName,
    this.rank,
    this.role,
    this.isOnline = true,
  });

  factory OnlinePlayer.fromJson(Map<String, dynamic> json) {
    return OnlinePlayer(
      id: json['id'] as int,
      displayName: json['displayName'] as String? ?? 'Unknown',
      avatarUrl: json['avatarUrl'] as String?,
      gameName: json['gameName'] as String? ?? '',
      rank: json['rank'] as String?,
      role: json['role'] as String?,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }
}

class MatchModel {
  final int id;
  final int matchedUserId;
  final String matchedUserName;
  final String? matchedUserAvatar;
  final DateTime matchedAt;

  const MatchModel({
    required this.id,
    required this.matchedUserId,
    required this.matchedUserName,
    this.matchedUserAvatar,
    required this.matchedAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as int,
      matchedUserId: json['matchedUserId'] as int,
      matchedUserName: json['matchedUserName'] as String? ?? 'Unknown',
      matchedUserAvatar: json['matchedUserAvatar'] as String?,
      matchedAt: json['matchedAt'] != null
          ? DateTime.parse(json['matchedAt'] as String)
          : DateTime.now(),
    );
  }
}

enum ExploreStatus { initial, loading, loaded, swiping, error }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final List<OnlinePlayer> onlinePlayers;
  final List<MatchModel> matches;
  final int? selectedGameId;
  final String? query;
  final MatchModel? newMatch;
  final String? errorMessage;

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.onlinePlayers = const [],
    this.matches = const [],
    this.selectedGameId,
    this.query,
    this.newMatch,
    this.errorMessage,
  });

  ExploreState copyWith({
    ExploreStatus? status,
    List<OnlinePlayer>? onlinePlayers,
    List<MatchModel>? matches,
    int? selectedGameId,
    String? query,
    MatchModel? newMatch,
    String? errorMessage,
    bool clearNewMatch = false,
  }) {
    return ExploreState(
      status: status ?? this.status,
      onlinePlayers: onlinePlayers ?? this.onlinePlayers,
      matches: matches ?? this.matches,
      selectedGameId: selectedGameId ?? this.selectedGameId,
      query: query ?? this.query,
      newMatch: clearNewMatch ? null : (newMatch ?? this.newMatch),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, onlinePlayers, matches, selectedGameId, query, newMatch, errorMessage];
}
