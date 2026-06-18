import 'package:equatable/equatable.dart';

class OnlinePlayer {
  final String id;
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
      id: json['id']?.toString() ?? '',
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
  final String id;
  final String matchedUserId;
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
      id: json['id']?.toString() ?? '',
      matchedUserId: json['matchedUserId']?.toString() ?? '',
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
  final String? selectedGameId;
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
    String? selectedGameId,
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
