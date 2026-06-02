import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../models/profile_model.dart';

class ProfileStatCard extends StatelessWidget {
  final List<StatModel> stats;
  final bool isSmallScreen;

  const ProfileStatCard({
    super.key,
    required this.stats,
    required this.isSmallScreen,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: stats.map((stat) => Expanded(child: _StatItem(stat: stat, isSmallScreen: isSmallScreen))).toList(),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final StatModel stat;
  final bool isSmallScreen;

  const _StatItem({required this.stat, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          stat.value,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: TextStyle(
            fontSize: isSmallScreen ? 9 : 10,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class ProfileGameInfoCard extends StatelessWidget {
  final GameInfoModel gameInfo;
  final bool isSmallScreen;

  const ProfileGameInfoCard({
    super.key,
    required this.gameInfo,
    required this.isSmallScreen,
  });

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin game',
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Row(
            children: [
              Container(
                width: isSmallScreen ? 44 : 50,
                height: isSmallScreen ? 44 : 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sports_esports_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameInfo.gameName,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${gameInfo.rank} \u2022 ${gameInfo.role}',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 4 : 5),
                decoration: BoxDecoration(
                  color: gameInfo.hasMic ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      gameInfo.hasMic ? Icons.mic_rounded : Icons.mic_off_rounded,
                      size: isSmallScreen ? 14 : 16,
                      color: gameInfo.hasMic ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      gameInfo.hasMic ? 'Có mic' : 'Không mic',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: gameInfo.hasMic ? AppColors.success : AppColors.error,
                      ),
                    ),
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
