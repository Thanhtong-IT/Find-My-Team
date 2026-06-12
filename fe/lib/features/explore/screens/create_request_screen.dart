import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';

class CreateRequestScreen extends StatefulWidget {
  final String gameName;

  const CreateRequestScreen({super.key, required this.gameName});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? _selectedRank;
  final Set<String> _selectedRoles = {};
  bool _requireMic = false;
  final TextEditingController _descriptionController = TextEditingController();

  List<String> get _ranks {
    switch (widget.gameName) {
      case 'Valorant':
        return ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương', 'Bất tử', 'Radiant'];
      case 'Liên Quân Mobile':
        return ['Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương', 'Tinh anh', 'Cao thủ', 'Thách đấu'];
      case 'Liên Minh Huyền Thoại':
        return ['Sắt', 'Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương', 'Cao thủ', 'Đại cao thủ', 'Thách đấu'];
      case 'PUBG Mobile':
        return ['Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương', 'Crown', 'Ace', 'Conqueror'];
      default:
        return ['Đồng', 'Bạc', 'Vàng', 'Bạch kim', 'Kim cương'];
    }
  }

  List<String> get _roles {
    switch (widget.gameName) {
      case 'Valorant':
        return ['Duelist', 'Controller', 'Initiator', 'Sentinel'];
      case 'Liên Quân Mobile':
        return ['Trợ thủ', 'Đường giữa', 'Rừng', 'Xạ thủ', 'Đường Caesar'];
      case 'Liên Minh Huyền Thoại':
        return ['Top', 'Jungle', 'Mid', 'ADC', 'Support'];
      case 'PUBG Mobile':
        return ['Leader', 'Sniper', 'Support', 'Scout', 'Fragger'];
      default:
        return ['Đội trưởng', 'Người chơi'];
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

  void _handleSubmit() {
    if (_selectedRank == null || _selectedRank!.isEmpty) {
      _showSnackBar('Vui lòng chọn bậc xếp hạng', isError: true);
      return;
    }
    if (_selectedRoles.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất 1 vị trí', isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar('Vui lòng nhập mô tả chi tiết', isError: true);
      return;
    }

    _showSnackBar('Đã đăng yêu cầu tìm đội');
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo yêu cầu',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _SelectedGameInfoCard(gameName: widget.gameName, isSmallScreen: isSmallScreen),
              const SizedBox(height: 20),
              _RankDropdown(
                ranks: _ranks,
                selectedRank: _selectedRank,
                isSmallScreen: isSmallScreen,
                onChanged: (value) => setState(() => _selectedRank = value),
              ),
              const SizedBox(height: 20),
              _RoleChoiceChips(
                roles: _roles,
                selectedRoles: _selectedRoles,
                isSmallScreen: isSmallScreen,
                onToggle: (role) => setState(() {
                  if (_selectedRoles.contains(role)) {
                    _selectedRoles.remove(role);
                  } else {
                    _selectedRoles.add(role);
                  }
                }),
              ),
              const SizedBox(height: 20),
              _MicRequirementSwitch(
                requireMic: _requireMic,
                isSmallScreen: isSmallScreen,
                onChanged: (value) => setState(() => _requireMic = value),
              ),
              const SizedBox(height: 20),
              _RequestDescriptionField(
                controller: _descriptionController,
                isSmallScreen: isSmallScreen,
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                isSmallScreen: isSmallScreen,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'FINDING LEGENDS - CONNECTING GAMERS',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedGameInfoCard extends StatelessWidget {
  final String gameName;
  final bool isSmallScreen;

  const _SelectedGameInfoCard({required this.gameName, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 50 : 56,
            height: isSmallScreen ? 50 : 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.sports_esports_rounded, color: AppColors.primary, size: isSmallScreen ? 26 : 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Trận đấu xếp hạng \u2022 5v5',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 4 : 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '92',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: isSmallScreen ? 70 : 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.92,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: isSmallScreen ? 4 : 5,
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

class _RankDropdown extends StatelessWidget {
  final List<String> ranks;
  final String? selectedRank;
  final bool isSmallScreen;
  final ValueChanged<String?> onChanged;

  const _RankDropdown({
    required this.ranks,
    required this.selectedRank,
    required this.isSmallScreen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bậc xếp hạng yêu cầu',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRank,
              hint: Text('Chọn bậc xếp hạng', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textLight)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
              dropdownColor: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              items: ranks.map((rank) => DropdownMenuItem<String>(value: rank, child: Text(rank))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChoiceChips extends StatelessWidget {
  final List<String> roles;
  final Set<String> selectedRoles;
  final bool isSmallScreen;
  final ValueChanged<String> onToggle;

  const _RoleChoiceChips({
    required this.roles,
    required this.selectedRoles,
    required this.isSmallScreen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vị trí cần tìm',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isSelected = selectedRoles.contains(role);
            return GestureDetector(
              onTap: () => onToggle(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 14, vertical: isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MicRequirementSwitch extends StatelessWidget {
  final bool requireMic;
  final bool isSmallScreen;
  final ValueChanged<bool> onChanged;

  const _MicRequirementSwitch({
    required this.requireMic,
    required this.isSmallScreen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.mic_rounded, color: requireMic ? AppColors.primary : AppColors.textSecondary, size: isSmallScreen ? 20 : 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu Mic',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Giao tiếp qua Voice Chat',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: requireMic,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _RequestDescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSmallScreen;

  const _RequestDescriptionField({
    required this.controller,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả chi tiết',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Ví dụ: Cần Mid làm đồng đội, không toxic, ưu tiên leo rank khuya...',
            hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 14),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSmallScreen;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSmallScreen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isSmallScreen ? 48 : 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'ĐĂNG YÊU CẦU NGAY',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
