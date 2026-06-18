import 'package:equatable/equatable.dart';

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
  final String? bio;
  final String? region;

  const ProfileUpdateRequested({this.displayName, this.bio, this.region});

  @override
  List<Object?> get props => [displayName, bio, region];
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
