import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/constants.dart';
import '../data/profile_repository.dart';
import '../models/game_model.dart';
import '../models/profile_model.dart';
import '../services/user_api_service.dart';
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
    context.read<ProfileBloc>().add(const PopularGamesLoadRequested());
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

  void _navigateToExploreTab(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
      (route) => false,
    ).then((_) {});
    Navigator.pushReplacementNamed(context, '/main', arguments: 1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.error && state.errorMessage != null) {
            _showSnackBar(context, state.errorMessage!, isError: true);
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading && state.profile == null) {
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

          GameInfoModel? gameInfo;
          if (userProfile.gameProfiles.isNotEmpty) {
            final gp = userProfile.gameProfiles.first;
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
            id: userProfile.id,
            displayName: userProfile.displayName ?? userProfile.username,
            username: '@${userProfile.username}',
            avatarUrl: userProfile.avatarUrl,
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
                  onEditTap: () => _showEditProfileBottomSheet(context, userProfile, state.popularGames),
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
                      _buildSettingsSection(isSmallScreen, context, userProfile, state.popularGames),
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

    if (team == null || team.teamName.isEmpty) {
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
                  Text('Bạn chưa tham gia đội nhóm nào', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Tìm đội để bắt đầu chơi!', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textLight)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final mainNav = Navigator.of(context, rootNavigator: true);
                      if (mainNav.canPop()) {
                        mainNav.pop();
                      }
                      _navigateToExploreTab(context);
                    },
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Tìm đội ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 8 : 10,
                      ),
                    ),
                  ),
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

  Widget _buildSettingsSection(bool isSmallScreen, BuildContext context, UserProfileModel userProfile, List<GameModel> games) {
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
            onTap: () => _showEditProfileBottomSheet(context, userProfile, games),
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

  void _showEditProfileBottomSheet(BuildContext context, UserProfileModel profile, List<GameModel> games) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _EditProfileSheet(profile: profile, games: games);
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
                    width: 14,
                    height: 14,
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

class _GameProfileDraft {
  final String? id;
  final String gameId;
  final String? gameName;
  final String? rank;
  final String? verifiedRank;
  final String? rankSource;
  final String? role;
  final bool hasMic;
  final bool isPrimary;
  final String? riotGameName;
  final String? riotTagLine;
  final String? riotRegion;
  final String? riotVerificationStatus;
  final bool riotVerified;

  const _GameProfileDraft({
    this.id,
    required this.gameId,
    this.gameName,
    this.rank,
    this.verifiedRank,
    this.rankSource,
    this.role,
    this.hasMic = false,
    this.isPrimary = false,
    this.riotGameName,
    this.riotTagLine,
    this.riotRegion,
    this.riotVerificationStatus,
    this.riotVerified = false,
  });

  factory _GameProfileDraft.fromModel(UserGameProfileModel model) {
    return _GameProfileDraft(
      id: model.id,
      gameId: model.gameId,
      gameName: model.gameName,
      rank: model.rank,
      verifiedRank: model.verifiedRank,
      rankSource: model.rankSource,
      role: model.role,
      hasMic: model.hasMic,
      isPrimary: model.isPrimary,
      riotGameName: model.riotGameName,
      riotTagLine: model.riotTagLine,
      riotRegion: model.riotRegion,
      riotVerificationStatus: model.riotVerificationStatus,
      riotVerified: model.riotVerified,
    );
  }

  _GameProfileDraft copyWith({
    String? id,
    String? gameId,
    String? gameName,
    String? rank,
    String? verifiedRank,
    String? rankSource,
    String? role,
    bool? hasMic,
    bool? isPrimary,
    String? riotGameName,
    String? riotTagLine,
    String? riotRegion,
    String? riotVerificationStatus,
    bool? riotVerified,
  }) {
    return _GameProfileDraft(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      rank: rank ?? this.rank,
      verifiedRank: verifiedRank ?? this.verifiedRank,
      rankSource: rankSource ?? this.rankSource,
      role: role ?? this.role,
      hasMic: hasMic ?? this.hasMic,
      isPrimary: isPrimary ?? this.isPrimary,
      riotGameName: riotGameName ?? this.riotGameName,
      riotTagLine: riotTagLine ?? this.riotTagLine,
      riotRegion: riotRegion ?? this.riotRegion,
      riotVerificationStatus: riotVerificationStatus ?? this.riotVerificationStatus,
      riotVerified: riotVerified ?? this.riotVerified,
    );
  }

  String? get displayRank => verifiedRank ?? rank;

  bool get usesVerifiedRank => (rankSource ?? '').toUpperCase() == 'RIOT';

  GameProfileUpdateItem toRequest() {
    return GameProfileUpdateItem(
      id: id,
      gameId: gameId,
      rank: rank,
      role: role,
      hasMic: hasMic,
      isPrimary: isPrimary,
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final UserProfileModel profile;
  final List<GameModel> games;

  const _EditProfileSheet({required this.profile, required this.games});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _userApiService = UserApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _regionController;
  late final List<GameModel> _gameOptions;
  late List<_GameProfileDraft> _drafts;
  final _imagePicker = ImagePicker();
  Uint8List? _avatarBytes;
  String? _avatarMimeType;
  String? _avatarPreviewUrl;
  bool _isSubmitting = false;
  bool _closeOnSuccess = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _regionController = TextEditingController(text: widget.profile.region ?? '');
    _avatarPreviewUrl = widget.profile.avatarUrl;
    _gameOptions = _mergeGames(widget.games, widget.profile.gameProfiles);
    _drafts = widget.profile.gameProfiles.map(_GameProfileDraft.fromModel).toList();
    if (_drafts.isEmpty && _gameOptions.isNotEmpty) {
      _drafts = [
        _GameProfileDraft(
          gameId: _gameOptions.first.id,
          gameName: _gameOptions.first.name,
        ),
      ];
    }
  }

  List<GameModel> _mergeGames(List<GameModel> source, List<UserGameProfileModel> existingProfiles) {
    final result = <GameModel>[];
    final seen = <String>{};

    for (final game in source) {
      if (seen.add(game.id)) {
        result.add(game);
      }
    }

    for (final profile in existingProfiles) {
      if (seen.add(profile.gameId)) {
        result.add(
          GameModel(
            id: profile.gameId,
            name: profile.gameName ?? 'Game',
          ),
        );
      }
    }

    return result;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _pickAvatar() async {
    if (_isSubmitting) return;
    final result = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (result == null) return;

    final bytes = await result.readAsBytes();
    final mimeType = _mimeTypeForPickedFile(result, bytes);
    if (mimeType == null) {
      _showSnackBar('Chỉ hỗ trợ ảnh jpg, png hoặc webp', isError: true);
      return;
    }

    setState(() {
      _avatarBytes = bytes;
      _avatarMimeType = mimeType;
      _avatarPreviewUrl = null;
    });
  }

  String? _mimeTypeForPickedFile(XFile file, Uint8List bytes) {
    final fromPicker = _normalizeImageMimeType(file.mimeType);
    if (fromPicker != null) return fromPicker;

    final fromName = _mimeTypeForFileName(file.name);
    if (fromName != null) return fromName;

    final fromPath = _mimeTypeForFileName(file.path);
    if (fromPath != null) return fromPath;

    return _mimeTypeFromBytes(bytes);
  }

  String? _normalizeImageMimeType(String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase();
    switch (normalized) {
      case 'image/jpeg':
      case 'image/jpg':
      case 'image/pjpeg':
        return 'image/jpeg';
      case 'image/png':
        return 'image/png';
      case 'image/webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  String? _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase().split('?').first;
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  String? _mimeTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  void _syncDraftsFromProfile(UserProfileModel profile) {
    setState(() {
      _drafts = profile.gameProfiles.map(_GameProfileDraft.fromModel).toList();
      if (_drafts.isEmpty && _gameOptions.isNotEmpty) {
        _drafts = [
          _GameProfileDraft(
            gameId: _gameOptions.first.id,
            gameName: _gameOptions.first.name,
          ),
        ];
      }
    });
  }

  void _addDraft() {
    if (_gameOptions.isEmpty) {
      return;
    }
    setState(() {
      _drafts = [
        ..._drafts,
        _GameProfileDraft(gameId: _gameOptions.first.id, gameName: _gameOptions.first.name),
      ];
    });
  }

  void _removeDraft(int index) {
    setState(() {
      _drafts = List.of(_drafts)..removeAt(index);
    });
  }

  void _setPrimary(int index, bool value) {
    setState(() {
      _drafts = _drafts
          .asMap()
          .entries
          .map((entry) => entry.key == index
              ? entry.value.copyWith(isPrimary: value)
              : entry.value.copyWith(isPrimary: false))
          .toList();
    });
  }

  Future<void> _save() async {
    final displayName = _nameController.text.trim();
    if (displayName.isEmpty) {
      _showSnackBar('Tên hiển thị không được để trống', isError: true);
      return;
    }

    final filtered = _drafts
        .where((draft) => draft.gameId.trim().isNotEmpty)
        .map((draft) => draft.toRequest())
        .toList();

    setState(() {
      _isSubmitting = true;
      _closeOnSuccess = true;
    });

    final profileBloc = context.read<ProfileBloc>();

    try {
      String? avatarUrl = widget.profile.avatarUrl;
      if (_avatarBytes != null && _avatarMimeType != null) {
        final uploadTarget = await _userApiService.createAvatarUploadUrl(_avatarMimeType!);
        await _userApiService.uploadAvatarToPresignedUrl(
          uploadUrl: uploadTarget.uploadUrl,
          contentType: _avatarMimeType!,
          bytes: _avatarBytes!,
        );
        avatarUrl = uploadTarget.publicUrl;
      }

      if (!mounted) return;
      profileBloc.add(
        ProfileUpdateRequested(
          displayName: displayName,
          avatarUrl: avatarUrl,
          bio: _bioController.text.trim(),
          region: _regionController.text.trim(),
          gameProfiles: filtered,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _closeOnSuccess = false;
      });
      _showSnackBar('$e', isError: true);
    }
  }

  void _verifyRiot(int index) {
    final draft = _drafts[index];
    if ((draft.id ?? '').isEmpty) {
      _showSnackBar('Hãy lưu game profile trước khi xác thực Riot', isError: true);
      return;
    }

    final riotGameName = (draft.riotGameName ?? '').trim();
    final riotTagLine = (draft.riotTagLine ?? '').trim();
    final riotRegion = (draft.riotRegion ?? '').trim();

    if (riotGameName.isEmpty || riotTagLine.isEmpty || riotRegion.isEmpty) {
      _showSnackBar('Vui lòng nhập đủ Riot ID và region', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _closeOnSuccess = false;
    });

    context.read<ProfileBloc>().add(
      RiotAccountVerifyRequested(
        profileId: draft.id!,
        riotGameName: riotGameName,
        riotTagLine: riotTagLine,
        region: riotRegion,
      ),
    );
  }

  void _refreshRiot(_GameProfileDraft draft) {
    if ((draft.id ?? '').isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _closeOnSuccess = false;
    });

    context.read<ProfileBloc>().add(RiotAccountRefreshRequested(profileId: draft.id!));
  }

  void _unlinkRiot(_GameProfileDraft draft) {
    if ((draft.id ?? '').isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _closeOnSuccess = false;
    });

    context.read<ProfileBloc>().add(RiotAccountUnlinkRequested(profileId: draft.id!));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (!_isSubmitting) {
          return;
        }

        if (state.status == ProfileStatus.error) {
          setState(() {
            _isSubmitting = false;
            _closeOnSuccess = false;
          });
          _showSnackBar(state.errorMessage ?? 'Có lỗi xảy ra', isError: true);
        }

        if (state.status == ProfileStatus.success && state.profile != null) {
          final shouldClose = _closeOnSuccess;
          setState(() {
            _isSubmitting = false;
            _closeOnSuccess = false;
          });

          if (shouldClose) {
            Navigator.pop(context);
          } else {
            _syncDraftsFromProfile(state.profile!);
            _showSnackBar('Đã cập nhật xác thực Riot');
          }
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Thông tin cá nhân', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  _buildAvatarPicker(),
                  const SizedBox(height: 12),
                  _buildTextField('Tên hiển thị', _nameController, 'Nhập tên hiển thị của bạn', enabled: !_isSubmitting),
                  const SizedBox(height: 12),
                  _buildTextField('Bio', _bioController, 'Mô tả ngắn về bạn', maxLines: 3, enabled: !_isSubmitting),
                  const SizedBox(height: 12),
                  _buildTextField('Khu vực', _regionController, 'Ví dụ: Hà Nội, TP. HCM...', enabled: !_isSubmitting),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Game profiles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      TextButton.icon(
                        onPressed: _isSubmitting ? null : _addDraft,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Thêm game'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_drafts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Text('Chưa có game profile nào.'),
                    )
                  else
                    ..._drafts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final draft = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildGameDraftCard(index, draft),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _isSubmitting ? null : _pickAvatar,
        child: Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: AppColors.divider),
              ),
              child: ClipOval(
                child: _avatarBytes != null
                    ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                    : (_avatarPreviewUrl != null && _avatarPreviewUrl!.isNotEmpty)
                        ? Image.network(_avatarPreviewUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 48, color: AppColors.white))
                        : const Icon(Icons.person, size: 48, color: AppColors.white),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildGameDraftCard(int index, _GameProfileDraft draft) {
    final items = _gameOptions;
    final selectedGame = items.where((game) => game.id == draft.gameId).isNotEmpty
        ? items.firstWhere((game) => game.id == draft.gameId)
        : null;
    final isRiotGame = _isRiotGameName(draft.gameName ?? selectedGame?.name);
    final rankReadOnly = isRiotGame && draft.riotVerified && draft.usesVerifiedRank;
    final riotRegions = _riotRegionsForGame(draft.gameName ?? selectedGame?.name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: items.any((game) => game.id == draft.gameId) ? draft.gameId : null,
                  decoration: const InputDecoration(labelText: 'Game'),
                  items: items
                      .map((game) => DropdownMenuItem<String>(
                            value: game.id,
                            child: Text(game.name),
                          ))
                      .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          final selected = items.firstWhere((game) => game.id == value);
                          setState(() {
                            _drafts[index] = _GameProfileDraft(
                              id: draft.id,
                              gameId: selected.id,
                              gameName: selected.name,
                              rank: draft.rank,
                              role: draft.role,
                              hasMic: draft.hasMic,
                              isPrimary: draft.isPrimary,
                            );
                          });
                        },
                ),
              ),
              IconButton(
                onPressed: _isSubmitting || _drafts.length == 1 ? null : () => _removeDraft(index),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isRiotGame) ...[
            _buildRiotStatus(draft),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('riot-game-name-$index-${draft.id ?? draft.gameId}-${draft.riotGameName ?? ''}'),
                    initialValue: draft.riotGameName ?? '',
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Riot ID',
                      hintText: 'gameName',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _drafts[index] = draft.copyWith(riotGameName: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('riot-tag-line-$index-${draft.id ?? draft.gameId}-${draft.riotTagLine ?? ''}'),
                    initialValue: draft.riotTagLine ?? '',
                    enabled: !_isSubmitting,
                    decoration: InputDecoration(
                      labelText: 'Tag line',
                      hintText: 'VN2',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _drafts[index] = draft.copyWith(riotTagLine: value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: riotRegions.contains(draft.riotRegion) ? draft.riotRegion : null,
              decoration: const InputDecoration(labelText: 'Region Riot'),
              items: riotRegions
                  .map((region) => DropdownMenuItem<String>(
                        value: region,
                        child: Text(region.toUpperCase()),
                      ))
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _drafts[index] = draft.copyWith(riotRegion: value);
                      });
                    },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _verifyRiot(index),
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(draft.riotVerified ? 'Xác thực lại' : 'Xác thực'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isSubmitting || (draft.id ?? '').isEmpty || !draft.riotVerified ? null : () => _refreshRiot(draft),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Làm mới'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSubmitting || (draft.id ?? '').isEmpty || (!draft.riotVerified && (draft.riotGameName ?? '').isEmpty && (draft.riotTagLine ?? '').isEmpty)
                      ? null
                      : () => _unlinkRiot(draft),
                  icon: const Icon(Icons.link_off, size: 18),
                  label: const Text('Gỡ liên kết'),
                ),
              ],
            ),
            if ((draft.id ?? '').isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Lưu game profile trước rồi mới xác thực Riot được.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('rank-$index-${draft.id ?? draft.gameId}-${draft.displayRank ?? ''}-${draft.riotVerified}'),
                  initialValue: draft.displayRank ?? '',
                  readOnly: rankReadOnly,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: rankReadOnly ? 'Rank đã xác thực' : 'Rank',
                    hintText: rankReadOnly ? 'Rank từ Riot' : 'Ví dụ: Vàng II',
                    helperText: rankReadOnly ? 'Rank thủ công bị khóa sau khi xác thực Riot' : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: rankReadOnly
                      ? null
                      : (value) {
                          setState(() {
                            _drafts[index] = draft.copyWith(rank: value);
                          });
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  key: ValueKey('role-$index-${draft.id ?? draft.gameId}-${draft.role ?? ''}'),
                  initialValue: draft.role ?? '',
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    hintText: 'Ví dụ: Mid / Support',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _drafts[index] = draft.copyWith(role: value);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: draft.hasMic,
                    title: const Text('Có mic'),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _drafts[index] = draft.copyWith(hasMic: value);
                            });
                          },
                  ),
                ),
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: draft.isPrimary,
                    title: const Text('Profile chính'),
                    onChanged: _isSubmitting ? null : (value) => _setPrimary(index, value),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiotStatus(_GameProfileDraft draft) {
    final statusLabel = _verificationStatusLabel(draft);
    final statusColor = _verificationStatusColor(draft);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(draft.riotVerified ? Icons.verified_rounded : Icons.info_outline_rounded, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(fontWeight: FontWeight.w700, color: statusColor),
              ),
              if (draft.usesVerifiedRank && (draft.verifiedRank ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    draft.verifiedRank!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            draft.riotVerified
                ? 'Rank đang lấy từ Riot account đã liên kết.'
                : 'Game Riot có thể xác thực để tăng độ tin cậy của rank.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

bool _isRiotGameName(String? gameName) {
  if (gameName == null) {
    return false;
  }
  final normalized = _normalizeGameName(gameName);
  return normalized == 'lien minh huyen thoai' ||
      normalized == 'league of legends' ||
      normalized == 'lol' ||
      normalized == 'dau truong chan ly' ||
      normalized == 'teamfight tactics' ||
      normalized == 'tft' ||
      normalized == 'valorant';
}

List<String> _riotRegionsForGame(String? gameName) {
  final normalized = _normalizeGameName(gameName ?? '');
  if (normalized == 'valorant') {
    return const ['ap', 'kr', 'na', 'latam', 'br', 'eu'];
  }
  return const ['vn2', 'kr', 'jp1', 'na1', 'br1', 'euw1', 'eun1', 'la1', 'la2', 'oc1', 'tr1', 'ru', 'ph2', 'sg2', 'th2', 'tw2'];
}

String _normalizeGameName(String value) {
  const vietnameseMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };

  final normalized = value
      .trim()
      .toLowerCase()
      .split('')
      .map((char) => vietnameseMap[char] ?? char)
      .join();

  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

String _verificationStatusLabel(_GameProfileDraft draft) {
  if (draft.riotVerified) {
    return 'Đã xác thực Riot';
  }

  final status = (draft.riotVerificationStatus ?? '').toUpperCase();
  if (status == 'FAILED') {
    return 'Xác thực thất bại';
  }
  return 'Chưa xác thực Riot';
}

Color _verificationStatusColor(_GameProfileDraft draft) {
  if (draft.riotVerified) {
    return AppColors.success;
  }

  final status = (draft.riotVerificationStatus ?? '').toUpperCase();
  if (status == 'FAILED') {
    return AppColors.error;
  }
  return const Color(0xFFF59E0B);
}
