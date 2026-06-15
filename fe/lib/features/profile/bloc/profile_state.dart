import 'package:equatable/equatable.dart';
import '../models/profile_model.dart';
import '../models/game_model.dart';

enum ProfileStatus { initial, loading, success, error }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserProfileModel? profile;
  final List<GameModel> popularGames;
  final String? errorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.popularGames = const [],
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfileModel? profile,
    List<GameModel>? popularGames,
    String? errorMessage,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      popularGames: popularGames ?? this.popularGames,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, popularGames, errorMessage];
}
