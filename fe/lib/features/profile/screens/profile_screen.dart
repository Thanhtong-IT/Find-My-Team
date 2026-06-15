import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stat_card.dart';
import '../../notification/screens/notification_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileLoadRequested());
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ProfileRepository().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.success && state.errorMessage == null) {
            // Hiển thị thông báo khi lưu thành công nếu cần
          }
          if (state.status == ProfileStatus.error && state.errorMessage != null) {
            _showSnackBar(context, state.errorMessage!, isError: true);
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userProfile = state.profile;
          if (userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage ?? 'Không thể tải thông tin hồ sơ',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(const ProfileLoadRequested());
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Thử lại', style: TextStyle(color: AppColors.white)),
                  ),
                ],
              ),
            );
          }

          // Map UserProfileModel to UI ProfileModel
          GameInfoModel? gameInfo;
          if (userProfile.gameProfiles.isNotEmpty) {
            final gp = userProfile.gameProfiles.first;
            gameInfo = GameInfoModel(
              gameName: gp.gameName ?? 'Game',
              rank: gp.rank ?? 'Chưa có hạng',
              role: gp.role ?? 'Chưa chọn vai trò',
              hasMic: gp.hasMic,
            );
          }

          // Mock default stats for display since backend has no stats fields
          final stats = [
            const StatModel(label: 'Trận đã chơi', value: '1,284'),
            const StatModel(label: 'Tỉ lệ thắng', value: '62%'),
            const StatModel(label: 'Đội đã tham gia', value: '48'),
            const StatModel(label: 'Điểm uy tín', value: '98'),
          ];

          final profile = ProfileModel(
            id: userProfile.id,
            displayName: userProfile.displayName ?? userProfile.username,
            username: '@${userProfile.username}',
            isOnline: userProfile.isOnline,
            gameInfo: gameInfo,
            stats: stats,
            currentTeam: userProfile.currentTeam,
            communities: userProfile.communities,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProfileHeader(
                  profile: profile,
                  isSmallScreen: isSmallScreen,
                  onEditTap: () => _showEditProfileBottomSheet(context, userProfile),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      if (profile.gameInfo != null)
                        ProfileGameInfoCard(gameInfo: profile.gameInfo!, isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      ProfileStatCard(stats: profile.stats, isSmallScreen: isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildCurrentTeam(profile, isSmallScreen, context),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildCommunitySection(profile, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      _buildSettingsSection(isSmallScreen, context, userProfile),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTeam(ProfileModel profile, bool isSmallScreen, BuildContext context) {
    final team = profile.currentTeam;
    if (team == null) {
      return _CardWrapper(
        isSmallScreen: isSmallScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhóm hiện tại', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Icon(Icons.group_off_rounded, size: isSmallScreen ? 40 : 48, color: AppColors.textLight),
                  const SizedBox(height: 8),
                  Text('Bạn chưa có nhóm', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Tìm đội để bắt đầu chơi!', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textLight)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _CardWrapper(
      isSmallScreen: isSmallScreen,
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
                    Text('${team.game} \u2022 ${team.memberCount} thành viên', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary)),
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

  Widget _buildCommunitySection(ProfileModel profile, bool isSmallScreen) {
    return _CardWrapper(
      isSmallScreen: isSmallScreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cộng đồng đã tham gia', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: isSmallScreen ? 96 : 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.communities.length,
              separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final comm = profile.communities[index];
                return _CommunityItem(comm: comm, isSmallScreen: isSmallScreen);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isSmallScreen, BuildContext context, UserProfileModel userProfile) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.edit_rounded,
            title: 'Chỉnh sửa hồ sơ',
            subtitle: 'Cập nhật thông tin cá nhân',
            isSmallScreen: isSmallScreen,
            onTap: () => _showEditProfileBottomSheet(context, userProfile),
          ),
          _divider(isSmallScreen),
          _buildSettingsItem(
            context,
            icon: Icons.notifications_rounded,
            title: 'Thông báo',
            subtitle: 'Cài đặt thông báo',
            isSmallScreen: isSmallScreen,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          _divider(isSmallScreen),
          _buildSettingsItem(
            context,
            icon: Icons.lock_rounded,
            title: 'Đổi mật khẩu',
            subtitle: 'Thay đổi mật khẩu tài khoản',
            isSmallScreen: isSmallScreen,
            onTap: () => _showSnackBar(context, 'Tính năng đổi mật khẩu sẽ được thêm sau'),
          ),
          _divider(isSmallScreen),
          _buildSettingsItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            subtitle: 'Đăng xuất khỏi tài khoản',
            isSmallScreen: isSmallScreen,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isSmallScreen) => Divider(color: AppColors.divider, height: 1);

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSmallScreen,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 12 : 14),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 38 : 42,
              height: isSmallScreen ? 38 : 42,
              decoration: BoxDecoration(
                color: isDestructive ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: isSmallScreen ? 18 : 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.w600, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textLight, size: isSmallScreen ? 20 : 22),
          ],
        ),
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, UserProfileModel profile) {
    final nameController = TextEditingController(text: profile.displayName ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');
    final regionController = TextEditingController(text: profile.region ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Chỉnh sửa hồ sơ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tên hiển thị', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên hiển thị của bạn',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Giới thiệu bản thân (Bio)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: bioController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Mô tả ngắn về bạn (sở thích, game hay chơi...)',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Khu vực (Region)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                TextField(
                  controller: regionController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Hà Nội, TP. HCM...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final displayName = nameController.text.trim();
                      final bio = bioController.text.trim();
                      final region = regionController.text.trim();

                      if (displayName.isEmpty) {
                        _showSnackBar(context, 'Tên hiển thị không được để trống', isError: true);
                        return;
                      }

                      context.read<ProfileBloc>().add(ProfileUpdateRequested(
                        displayName: displayName,
                        bio: bio,
                        region: region,
                      ));

                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Bạn có chắc muốn đăng xuất không?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final Widget child;
  final bool isSmallScreen;

  const _CardWrapper({required this.child, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}

class _CommunityItem extends StatelessWidget {
  final CommunityInfoModel comm;
  final bool isSmallScreen;

  const _CommunityItem({required this.comm, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final itemWidth = isSmallScreen ? 70.0 : 78.0;
    return SizedBox(
      width: itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: isSmallScreen ? 52 : 58,
                height: isSmallScreen ? 52 : 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    comm.name.isNotEmpty ? comm.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                ),
              ),
              if (comm.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comm.name,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
