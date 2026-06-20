import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../models/channel_model.dart';

class CreateChannelDialog extends StatefulWidget {
  final ChannelType initialType;
  final void Function(String name, ChannelType type) onSubmit;
  final VoidCallback? onCancel;

  const CreateChannelDialog({
    super.key,
    required this.initialType,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends State<CreateChannelDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late ChannelType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim().toLowerCase().replaceAll(' ', '-');
    widget.onSubmit(name, _selectedType);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? screenWidth * 0.85 : 380,
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tạo kênh mới',
                style: TextStyle(
                  fontSize: isSmallScreen ? 17 : 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 20),
              Text(
                'Loại kênh',
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
                      onTap: () => setState(() => _selectedType = ChannelType.text),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: _selectedType == ChannelType.text ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _selectedType == ChannelType.text ? AppColors.primary : AppColors.divider, width: _selectedType == ChannelType.text ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tag_rounded, size: isSmallScreen ? 16 : 18, color: _selectedType == ChannelType.text ? AppColors.primary : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('Chat', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: _selectedType == ChannelType.text ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = ChannelType.voice),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: _selectedType == ChannelType.voice ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _selectedType == ChannelType.voice ? AppColors.primary : AppColors.divider, width: _selectedType == ChannelType.voice ? 2 : 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_rounded, size: isSmallScreen ? 16 : 18, color: _selectedType == ChannelType.voice ? AppColors.primary : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('Voice', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600, color: _selectedType == ChannelType.voice ? AppColors.primary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 14 : 18),
              Text(
                'Tên kênh',
                style: TextStyle(fontSize: isSmallScreen ? 12 : 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'VD: leo-rank',
                  hintStyle: TextStyle(fontSize: isSmallScreen ? 14 : 15, color: AppColors.textLight),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 14, vertical: isSmallScreen ? 11 : 13),
                  errorMaxLines: 2,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên kênh không được để trống';
                  }
                  if (value.trim().length > 100) {
                    return 'Tên kênh tối đa 100 ký tự';
                  }
                  return null;
                },
              ),
              SizedBox(height: isSmallScreen ? 20 : 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: isSmallScreen ? 42 : 46,
                      child: OutlinedButton(
                        onPressed: () {
                          if (widget.onCancel != null) {
                            widget.onCancel!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.divider), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isSmallScreen ? 13 : 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: isSmallScreen ? 42 : 46,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('Tạo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 13 : 14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
