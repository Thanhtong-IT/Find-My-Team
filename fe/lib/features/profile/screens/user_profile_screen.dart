import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../models/profile_model.dart';
import '../services/user_api_service.dart';
import '../../team/models/friendship_model.dart';
import '../../team/services/friendship_api_service.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stat_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _apiService = UserApiService();
  final _storage = SecureStorageRepository();
  UserProfileModel? _profile;
  FriendshipModel? _friendship;
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _currentUserId = await _storage.getUserId();
    if (mounted) {
      setState(() {
        _isOwnProfile = _currentUserId == widget.userId;
      });
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getUserProfile(widget.userId),
        FriendshipApiService().getFriendshipWith(widget.userId),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfileModel?;
        _friendship = results[1] as FriendshipModel?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải thông tin người dùng';
        _isLoading = false;
      });
    }
  }

  Future<void> _onFriendTap() async {
    final api = FriendshipApiService();
    try {
      // Nếu chưa có quan hệ hoặc status là NONE, gửi lời mời mới (POST)
      if (_friendship == null || _friendship!.status.toUpperCase() == 'NONE') {
        await api.sendFriendRequest(widget.userId);
        if (!mounted) return;
        _showSnackBar('Đã gửi lời mời kết bạn');
        _loadProfile();
        return;
      }

      final friendshipId = _friendship!.id;
      if (friendshipId == null) {
        _showSnackBar('Không thể xác định lời mời kết bạn', isError: true);
        return;
      }

      if (_friendship!.isPending && _friendship!.isSent) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            title: const Text('Hủy lời mời', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            content: const Text('Bạn có muốn hủy lời mời kết bạn này không?', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Hủy lời mời')),
            ],
          ),
        );
        if (confirm == true) {
          await api.cancelFriendRequest(friendshipId);
          if (!mounted) return;
          _showSnackBar('Đã hủy lời mời kết bạn');
          _loadProfile();
        }
        return;
      }

      if (_friendship!.isPending && _friendship!.isReceived) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            title: const Text('Lời mời kết bạn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            content: Text('${_friendship!.friendDisplayName ?? _friendship!.friendUsername} muốn kết bạn với bạn', style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, 'reject'), child: const Text('Từ chối', style: TextStyle(color: AppColors.error))),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, 'accept'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary), child: const Text('Chấp nhận')),
            ],
          ),
        );

        if (choice == 'accept') {
          await api.acceptFriendRequest(friendshipId);
          if (!mounted) return;
          _showSnackBar('Đã chấp nhận lời mời kết bạn');
          _loadProfile();
          return;
        }

        if (choice == 'reject') {
          await api.rejectFriendRequest(friendshipId);
          if (!mounted) return;
          _showSnackBar('Đã từ chối lời mời kết bạn');
          _loadProfile();
          return;
        }
        return;
      }

      if (_friendship!.isAccepted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            title: const Text('Hủy kết bạn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            content: Text('Bạn có muốn hủy kết bạn với ${_friendship!.friendDisplayName ?? _friendship!.friendUsername} không?', style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Để sau')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Hủy kết bạn')),
            ],
          ),
        );
        if (confirm == true) {
          await api.unfriend(friendshipId);
          if (!mounted) return;
          _showSnackBar('Đã hủy kết bạn');
          _loadProfile();
        }
        return;
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('$e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hồ sơ người dùng',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: _buildBody(isSmallScreen),
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    GameInfoModel? gameInfo;
    if (_profile!.gameProfiles.isNotEmpty) {
      final gp = _profile!.gameProfiles.first;
      gameInfo = GameInfoModel(
        gameName: gp.gameName ?? 'Game',
        rank: gp.displayRank ?? 'Chưa có hạng',
        role: gp.role ?? 'Chưa chọn vai trò',
        hasMic: gp.hasMic,
      );
    }

    final stats = [
      const StatModel(label: 'Trận đã chơi', value: '-'),
      const StatModel(label: 'Tỉ lệ thắng', value: '-'),
      const StatModel(label: 'Đội đã tham gia', value: '-'),
      const StatModel(label: 'Điểm uy tín', value: '-'),
    ];

    final profile = ProfileModel(
      id: _profile!.id,
      displayName: _profile!.displayName ?? _profile!.username,
      username: '@${_profile!.username}',
      avatarUrl: _profile!.avatarUrl,
      isOnline: _profile!.isOnline,
      gameInfo: gameInfo,
      stats: stats,
      currentTeam: _profile!.currentTeam,
      communities: _profile!.communities,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(
            profile: profile,
            isSmallScreen: isSmallScreen,
            onEditTap: _isOwnProfile ? () {} : null,
            onFriendTap: !_isOwnProfile ? _onFriendTap : null,
            friendship: _friendship,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 16 : 20),
                if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
                  _buildBioSection(_profile!.bio!, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],
                if (profile.gameInfo != null) ...[
                  ProfileGameInfoCard(gameInfo: profile.gameInfo!, isSmallScreen: isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],
                ProfileStatCard(stats: profile.stats, isSmallScreen: isSmallScreen),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildGameProfilesSection(isSmallScreen),
                if (profile.currentTeam != null) ...[
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildCurrentTeam(profile.currentTeam!, isSmallScreen),
                ],
                SizedBox(height: isSmallScreen ? 24 : 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(String bio, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giới thiệu', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(bio, style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildGameProfilesSection(bool isSmallScreen) {
    if (_profile!.gameProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hồ sơ game', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...(_profile!.gameProfiles.map((gp) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GameProfileItem(gameProfile: gp, isSmallScreen: isSmallScreen),
              ))),
        ],
      ),
    );
  }

  Widget _buildCurrentTeam(TeamInfoModel team, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nhóm hiện tại', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: isSmallScreen ? 44 : 50,
                height: isSmallScreen ? 44 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.teamName, style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${team.game} • ${team.memberCount} thành viên', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 4 : 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  team.myRole,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameProfileItem extends StatelessWidget {
  final UserGameProfileModel gameProfile;
  final bool isSmallScreen;

  const _GameProfileItem({required this.gameProfile, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final verified = gameProfile.riotVerified;
    final rankText = gameProfile.displayRank ?? '-';

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 36 : 40,
                height: isSmallScreen ? 36 : 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_esports_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            gameProfile.gameName ?? 'Game',
                            style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                                const SizedBox(width: 4),
                                Text('Riot', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$rankText • ${gameProfile.role ?? '-'}',
                      style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textSecondary),
                    ),
                    if (verified && gameProfile.riotIdDisplay != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        gameProfile.riotIdDisplay!,
                        style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.textLight),
                      ),
                    ],
                  ],
                ),
              ),
              if (gameProfile.hasMic)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('Mic', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.success, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
