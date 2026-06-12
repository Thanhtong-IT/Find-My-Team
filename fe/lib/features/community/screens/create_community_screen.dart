import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../data/community_repository.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedGame;
  bool _isPublic = true;
  bool _isSubmitting = false;

  final List<_GameOption> _games = const [
    _GameOption(name: 'Liên Minh Huyền Thoại', icon: Icons.shield_outlined),
    _GameOption(name: 'Valorant', icon: Icons.sports_esports_outlined),
    _GameOption(name: 'PUBG Mobile', icon: Icons.gps_fixed_outlined),
    _GameOption(name: 'Liên Quân Mobile', icon: Icons.sports_motorsports_outlined),
  ];

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên cộng đồng', isError: true);
      return;
    }
    if (_selectedGame == null) {
      _showSnackBar('Vui lòng chọn trò chơi', isError: true);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập mô tả cộng đồng', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await CommunityRepository().createCommunity(
        name: _nameController.text.trim(),
        game: _selectedGame!,
        description: _descController.text.trim(),
        isPublic: _isPublic,
      );
      if (mounted) {
        _showSnackBar('Đã tạo cộng đồng thành công');
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar('Đã xảy ra lỗi, vui lòng thử lại', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(isSmallScreen),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  _buildCoverImage(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 28),
                  _buildNameField(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  _buildGameSection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  _buildDescField(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  _buildPrivacySection(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 28 : 36),
                  _buildSubmitButton(isSmallScreen),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Tạo cộng đồng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildCoverImage(bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 130 : 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showSnackBar('Tính năng tải ảnh bìa sẽ được thêm sau'),
            child: Container(
              width: isSmallScreen ? 48 : 56,
              height: isSmallScreen ? 48 : 56,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 26),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tải ảnh bìa',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tên cộng đồng',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'VD: Liên Minh Đại Chiến',
            hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14 : 16,
              vertical: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn trò chơi',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _games.map((game) {
            final isSelected = _selectedGame == game.name;
            return GestureDetector(
              onTap: () => setState(() => _selectedGame = game.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      game.icon,
                      size: isSmallScreen ? 14 : 16,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      game.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mô tả cộng đồng',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descController,
          maxLines: 4,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Giới thiệu cộng đồng của bạn...',
            hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 14 : 16,
              vertical: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quyền riêng tư',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isPublic = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 14,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: _isPublic ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isPublic ? AppColors.primary : AppColors.divider,
                      width: _isPublic ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: isSmallScreen ? 22 : 26,
                        color: _isPublic ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Công khai',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: _isPublic ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mọi người có thể tham gia',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isPublic = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 14,
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: !_isPublic ? AppColors.primary.withValues(alpha: 0.05) : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_isPublic ? AppColors.primary : AppColors.divider,
                      width: !_isPublic ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: isSmallScreen ? 22 : 26,
                        color: !_isPublic ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riêng tư',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: !_isPublic ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chỉ người được mời',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    return SizedBox(
      height: isSmallScreen ? 46 : 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tạo ngay',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GameOption {
  final String name;
  final IconData icon;

  const _GameOption({required this.name, required this.icon});
}
