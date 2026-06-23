import '../models/profile_model.dart';

class ProfileRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  ProfileModel? _currentProfile;

  ProfileModel _buildDefaultProfile() => ProfileModel(
    id: 'u1',
    displayName: 'ShadowHunter',
    username: '@shadowhunter99',
    isOnline: true,
    gameInfo: const GameInfoModel(gameName: 'Liên Minh Huyền Thoại', rank: 'Kim Cương II', role: 'Mid / Top', hasMic: true),
    stats: const [
      StatModel(label: 'Trận đã chơi', value: '-'),
      StatModel(label: 'Tỉ lệ thắng', value: '-'),
      StatModel(label: 'Đội đã tham gia', value: '-'),
      StatModel(label: 'Điểm uy tín', value: '-'),
    ],
    currentTeam: null,
    communities: const [],
  );

  ProfileModel getMyProfile() {
    _currentProfile ??= _buildDefaultProfile();
    return _currentProfile!;
  }

  void updateProfile({String? displayName, GameInfoModel? gameInfo}) {
    final current = getMyProfile();
    _currentProfile = current.copyWith(
      displayName: displayName,
      gameInfo: gameInfo,
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentProfile = null;
  }
}
