import 'package:equatable/equatable.dart';

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();
  @override
  List<Object?> get props => [];
}

class ExploreLoadRequested extends ExploreEvent {
  final String? gameId;
  final String? query;
  const ExploreLoadRequested({this.gameId, this.query});
  @override
  List<Object?> get props => [gameId, query];
}

class ExploreSwipeRequested extends ExploreEvent {
  final String targetUserId;
  final bool liked;
  const ExploreSwipeRequested({required this.targetUserId, required this.liked});
  @override
  List<Object?> get props => [targetUserId, liked];
}

class ExploreMatchReceived extends ExploreEvent {
  final String matchId;
  final String otherUserName;
  const ExploreMatchReceived({required this.matchId, required this.otherUserName});
  @override
  List<Object?> get props => [matchId, otherUserName];
}
