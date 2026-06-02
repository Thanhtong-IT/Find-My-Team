import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../models/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final bool isSmallScreen;
  final VoidCallback? onEditTap;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isSmallScreen,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: isSmallScreen ? 12 : 16),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: isSmallScreen ? 90 : 100,
                  height: isSmallScreen ? 90 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 3),
                  ),
                  child: const Icon(Icons.person, color: AppColors.white, size: 48),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: isSmallScreen ? 26 : 30,
                    height: isSmallScreen ? 26 : 30,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),
            Text(
              profile.displayName,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              profile.username,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 40 : 60),
              child: SizedBox(
                height: isSmallScreen ? 38 : 42,
                child: ElevatedButton.icon(
                  onPressed: onEditTap,
                  icon: Icon(Icons.edit_rounded, size: isSmallScreen ? 16 : 18),
                  label: Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 14 : 20),
          ],
        ),
      ),
    );
  }
}
