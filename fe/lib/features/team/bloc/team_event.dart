import 'package:equatable/equatable.dart';
import '../models/team_model.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();
  @override
  List<Object?> get props => [];
}

class TeamLoadRequested extends TeamEvent {
  const TeamLoadRequested();
}

class TeamCreateRequested extends TeamEvent {
  final String name;
  final String gameId;
  final int maxMembers;
  final String? description;
  final String? requiredRank;

  const TeamCreateRequested({
    required this.name,
    required this.gameId,
    required this.maxMembers,
    this.description,
    this.requiredRank,
  });

  @override
  List<Object?> get props => [name, gameId, maxMembers, description, requiredRank];
}

class TeamReadyToggled extends TeamEvent {
  final bool ready;
  const TeamReadyToggled(this.ready);
  @override
  List<Object?> get props => [ready];
}

class TeamLeaveRequested extends TeamEvent {
  const TeamLeaveRequested();
}

class TeamDisbandRequested extends TeamEvent {
  const TeamDisbandRequested();
}

class TeamJoinRequestsLoadRequested extends TeamEvent {
  const TeamJoinRequestsLoadRequested();
}

class JoinRequestAccepted extends TeamEvent {
  final String requestId;
  const JoinRequestAccepted(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class JoinRequestRejected extends TeamEvent {
  final String requestId;
  const JoinRequestRejected(this.requestId);
  @override
  List<Object?> get props => [requestId];
}

class TeamOpenLoadRequested extends TeamEvent {
  final String? gameId;
  const TeamOpenLoadRequested({this.gameId});
  @override
  List<Object?> get props => [gameId];
}

class TeamJoinRequestSent extends TeamEvent {
  final String teamId;
  final String? message;
  const TeamJoinRequestSent({required this.teamId, this.message});
  @override
  List<Object?> get props => [teamId, message];
}

// Realtime events forwarded from WebSocket
class TeamMemberJoinedEvent extends TeamEvent {
  final String userId;
  final String displayName;
  const TeamMemberJoinedEvent({required this.userId, required this.displayName});
  @override
  List<Object?> get props => [userId, displayName];
}

class TeamMemberLeftEvent extends TeamEvent {
  final String userId;
  const TeamMemberLeftEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

class TeamMemberReadyEvent extends TeamEvent {
  final String userId;
  final bool isReady;
  const TeamMemberReadyEvent({required this.userId, required this.isReady});
  @override
  List<Object?> get props => [userId, isReady];
}

class TeamDisbandedEvent extends TeamEvent {
  final String teamId;
  const TeamDisbandedEvent(this.teamId);
  @override
  List<Object?> get props => [teamId];
}

class JoinRequestCreatedEvent extends TeamEvent {
  final JoinRequestModel request;
  const JoinRequestCreatedEvent(this.request);
  @override
  List<Object?> get props => [request];
}

