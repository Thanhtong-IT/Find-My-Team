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
    gameInfo: GameInfoModel(gameName: 'Liên Minh Huyền Thoại', rank: 'Kim Cương II', role: 'Mid / Top', hasMic: true),
    stats: [
      StatModel(label: 'Trận đã chơi', value: '1,284'),
      StatModel(label: 'Tỉ lệ thắng', value: '62%'),
      StatModel(label: 'Đội đã tham gia', value: '48'),
      StatModel(label: 'Điểm uy tín', value: '98'),
    ],
    currentTeam: TeamInfoModel(teamName: 'Team Phoenix', game: 'Liên Minh Huyền Thoại', memberCount: 5, myRole: 'Đội trưởng'),
    communities: [
      CommunityInfoModel(id: 'c1', name: 'Liên Minh Đại Chiến', memberCount: '1.2k', isOnline: true),
      CommunityInfoModel(id: 'c2', name: 'PUBG VN', memberCount: '850', isOnline: false),
      CommunityInfoModel(id: 'c3', name: 'Valorant Elite', memberCount: '2.4k', isOnline: true),
    ],
  );

  ProfileModel getMyProfile() {
    _currentProfile ??= _buildDefaultProfile();
    return _currentProfile!;
  }

  void updateProfile({String? displayName, String? avatarUrl, GameInfoModel? gameInfo}) {
    final current = getMyProfile();
    _currentProfile = current.copyWith(
      displayName: displayName,
      avatarUrl: avatarUrl,
      gameInfo: gameInfo,
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentProfile = null;
  }
}
