import 'package:equatable/equatable.dart';

import '../models/profile_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class ProfileUpdateRequested extends ProfileEvent {
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? region;
  final List<GameProfileUpdateItem>? gameProfiles;

  const ProfileUpdateRequested({this.displayName, this.avatarUrl, this.bio, this.region, this.gameProfiles});

  @override
  List<Object?> get props => [displayName, avatarUrl, bio, region, gameProfiles];
}

class RiotAccountVerifyRequested extends ProfileEvent {
  final String profileId;
  final String riotGameName;
  final String riotTagLine;
  final String region;

  const RiotAccountVerifyRequested({
    required this.profileId,
    required this.riotGameName,
    required this.riotTagLine,
    required this.region,
  });

  @override
  List<Object?> get props => [profileId, riotGameName, riotTagLine, region];
}

class RiotAccountRefreshRequested extends ProfileEvent {
  final String profileId;

  const RiotAccountRefreshRequested({required this.profileId});

  @override
  List<Object?> get props => [profileId];
}

class RiotAccountUnlinkRequested extends ProfileEvent {
  final String profileId;

  const RiotAccountUnlinkRequested({required this.profileId});

  @override
  List<Object?> get props => [profileId];
}

class GameProfileAddRequested extends ProfileEvent {
  final String gameId;
  final String? rank;
  final String? role;

  const GameProfileAddRequested({required this.gameId, this.rank, this.role});

  @override
  List<Object?> get props => [gameId, rank, role];
}

class GameProfileDeleteRequested extends ProfileEvent {
  final String profileId;

  const GameProfileDeleteRequested({required this.profileId});

  @override
  List<Object?> get props => [profileId];
}

class PopularGamesLoadRequested extends ProfileEvent {
  const PopularGamesLoadRequested();
}
