import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../data/profile_repository.dart';
import '../models/profile_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stat_card.dart';
import '../../notification/screens/notification_screen.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? AppColors.error : AppColors.primary, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await ProfileRepository().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;
    final profile = ProfileRepository().getMyProfile();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProfileHeader(
              profile: profile,
              isSmallScreen: isSmallScreen,
              onEditTap: () => _showSnackBar(context, 'Tính năng chỉnh sửa hồ sơ sẽ được thêm sau'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  ProfileGameInfoCard(gameInfo: profile.gameInfo, isSmallScreen: isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  ProfileStatCard(stats: profile.stats, isSmallScreen: isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildCurrentTeam(profile, isSmallScreen, context),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildCommunitySection(profile, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildSettingsSection(isSmallScreen, context),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildSettingsSection(bool isSmallScreen, BuildContext context) {
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
            onTap: () => _showSnackBar(context, 'Tính năng chỉnh sửa hồ sơ sẽ được thêm sau'),
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
