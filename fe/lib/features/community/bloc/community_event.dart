import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();
  @override
  List<Object?> get props => [];
}

class CommunityLoadRequested extends CommunityEvent {
  final String? gameId;
  const CommunityLoadRequested({this.gameId});
  @override
  List<Object?> get props => [gameId];
}

class CommunityCreateRequested extends CommunityEvent {
  final String name;
  final String gameId;
  final String description;
  final String avatarUrl;
  final bool isPublic;
  const CommunityCreateRequested({
    required this.name,
    required this.gameId,
    required this.description,
    required this.avatarUrl,
    required this.isPublic,
  });
  @override
  List<Object?> get props => [name, gameId, description, avatarUrl, isPublic];
}

class CommunityJoinRequested extends CommunityEvent {
  final String communityId;
  const CommunityJoinRequested(this.communityId);
  @override
  List<Object?> get props => [communityId];
}

class CommunityLeaveRequested extends CommunityEvent {
  final String communityId;
  const CommunityLeaveRequested(this.communityId);
  @override
  List<Object?> get props => [communityId];
}

class CommunityChannelsLoadRequested extends CommunityEvent {
  final String communityId;
  const CommunityChannelsLoadRequested(this.communityId);
  @override
  List<Object?> get props => [communityId];
}
