import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import 'login_screen.dart';
import '../../main/screens/main_navigation_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../../profile/bloc/profile_bloc.dart';
import '../../profile/bloc/profile_event.dart';
import '../../profile/bloc/profile_state.dart';

class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedGame;
  String? _selectedRank;
  String? _selectedRole;
  String? _selectedRegion;

  bool _isLoading = false;

  final List<String> _games = ['Liên Quân Mobile', 'Liên Minh Huyền Thoại', 'Valorant', 'PUBG Mobile', 'Free Fire', 'Genshin Impact'];
  final List<String> _ranks = ['Chưa xếp hạng', 'Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương', 'Cao thủ', 'Thách đấu'];
  final List<String> _roles = ['Đội trưởng', 'Người chơi', 'Hỗ trợ', 'Xạ thủ', 'Đấu sĩ', 'Pháp sư', 'Sát thủ', 'Đỡ đòn'];
  final List<String> _regions = ['TP. Hồ Chí Minh', 'Hà Nội', 'Đà Nẵng', 'Cần Thơ', 'Khác'];

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập tên hiển thị');
      return;
    }

    setState(() => _isLoading = true);

    // Gọi API update profile
    context.read<ProfileBloc>().add(ProfileUpdateRequested(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
      region: _selectedRegion,
    ));
  }

  void _handleSkip() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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

  void _navigateToMain() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.status == ProfileStatus.error) {
          setState(() => _isLoading = false);
          _showSnackBar(state.errorMessage ?? 'Có lỗi xảy ra', isError: true);
        }
        if (state.status == ProfileStatus.success && _isLoading) {
          setState(() => _isLoading = false);
          _navigateToMain();
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.white, Color(0xFFEFF6FF)]),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSizes.paddingL),
                        _buildAvatarSection(),
                        const SizedBox(height: AppSizes.paddingXL),
                        _buildFormCard(),
                        const SizedBox(height: AppSizes.paddingXL),
                        _buildActionButtons(),
                        const SizedBox(height: AppSizes.paddingXL),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: AppSizes.paddingS),
      decoration: const BoxDecoration(color: AppColors.white, boxShadow: [BoxShadow(color: AppColors.divider, blurRadius: 4, offset: Offset(0, 2))]),
      child: Row(
        children: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout, color: AppColors.textPrimary), style: IconButton.styleFrom(backgroundColor: AppColors.surface)),
          const SizedBox(width: AppSizes.paddingM),
          const Expanded(child: Text('Thiết lập hồ sơ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.person, size: 48, color: AppColors.white),
            ),
            Positioned(
              right: 0, bottom: 0,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2)),
                  child: const Icon(Icons.camera_alt, size: 16, color: AppColors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.paddingS),
        const Text('THAY ĐỔI ẢNH ĐẠI DIỆN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppSizes.radiusXL), boxShadow: const [BoxShadow(color: AppColors.divider, blurRadius: 16, offset: Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Cho chúng tôi biết bạn chơi game gì để tìm đồng đội phù hợp hơn', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.paddingXL),
          _buildTextField(label: 'TÊN HIỂN THỊ', hint: 'Shadow Hunter_99', controller: _displayNameController, icon: Icons.person_outline),
          const SizedBox(height: AppSizes.paddingL),
          _buildDropdown(label: 'GAME YÊU THÍCH', value: _selectedGame, items: _games, icon: Icons.sports_esports_outlined, onChanged: (v) => setState(() => _selectedGame = v)),
          const SizedBox(height: AppSizes.paddingL),
          _buildDropdown(label: 'RANK HIỆN TẠI', value: _selectedRank, items: _ranks, icon: Icons.emoji_events_outlined, onChanged: (v) => setState(() => _selectedRank = v)),
          const SizedBox(height: AppSizes.paddingL),
          _buildDropdown(label: 'VAI TRÒ CHÍNH', value: _selectedRole, items: _roles, icon: Icons.shield_outlined, onChanged: (v) => setState(() => _selectedRole = v)),
          const SizedBox(height: AppSizes.paddingL),
          _buildDropdown(label: 'KHU VỰC', value: _selectedRegion, items: _regions, icon: Icons.location_on_outlined, onChanged: (v) => setState(() => _selectedRegion = v)),
          const SizedBox(height: AppSizes.paddingL),
          _buildTextArea(label: 'MÔ TẢ NGẮN VỀ BẢN THÂN', hint: 'Ví dụ: Mình thường chơi buổi tối, thích leo rank nghiêm túc...', controller: _bioController),
        ],
      ),
    );
  }

  Widget _buildTextField({required String label, required String hint, required TextEditingController controller, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.paddingS),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 16),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconM),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required IconData icon, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.paddingS),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusM), border: Border.all(color: AppColors.divider)),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconM),
              const SizedBox(width: AppSizes.paddingS),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    hint: const Text('Chọn một tùy chọn', style: TextStyle(color: AppColors.textLight, fontSize: 16)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                    style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    dropdownColor: AppColors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextArea({required String label, required String hint, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.paddingS),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 16),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusM), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.all(AppSizes.paddingM),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSizes.buttonHeightL,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Text('HOÀN TẤT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
        ),
        const SizedBox(height: AppSizes.paddingM),
        TextButton(
          onPressed: _isLoading ? null : _handleSkip,
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary, padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS)),
          child: const Text('Bỏ qua', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
