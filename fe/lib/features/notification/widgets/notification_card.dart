import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../bloc/notification_event.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItemModel notification;
  final bool isSmallScreen;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isLoading;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isSmallScreen,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final showActions = notification.type == 'team_invite';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
          border: Border.all(
            color: notification.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: isSmallScreen ? 7 : 8,
                              height: isSmallScreen ? 7 : 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(notification.timestamp),
                        style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showActions && (onAccept != null || onReject != null)) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onAccept != null)
                    Expanded(
                      child: SizedBox(
                        height: isSmallScreen ? 32 : 36,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Text('Chấp nhận', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  if (onAccept != null && onReject != null)
                    const SizedBox(width: 8),
                  if (onReject != null)
                    Expanded(
                      child: SizedBox(
                        height: isSmallScreen ? 32 : 36,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text('Từ chối', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = _getIcon();
    final bgColor = _getBgColor();
    final fgColor = _getFgColor();

    return Container(
      width: isSmallScreen ? 40 : 46,
      height: isSmallScreen ? 40 : 46,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Icon(iconData, color: fgColor, size: isSmallScreen ? 20 : 22),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case 'team_invite':
      case 'teamInvite':
        return Icons.group_add_rounded;
      case 'join_request':
      case 'joinRequest':
        return Icons.person_add_alt_1_rounded;
      case 'community_post':
      case 'communityPost':
        return Icons.article_rounded;
      case 'chat_message':
      case 'chatMessage':
        return Icons.chat_rounded;
      case 'request_accepted':
      case 'requestAccepted':
        return Icons.check_circle_rounded;
      case 'request_rejected':
      case 'requestRejected':
        return Icons.cancel_rounded;
      case 'match_created':
      case 'matchCreated':
        return Icons.favorite_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getBgColor() {
    switch (notification.type) {
      case 'team_invite':
      case 'teamInvite':
        return const Color(0xFFEFF6FF);
      case 'join_request':
      case 'joinRequest':
        return const Color(0xFFF0FDF4);
      case 'community_post':
      case 'communityPost':
        return const Color(0xFFFEF3C7);
      case 'chat_message':
      case 'chatMessage':
        return const Color(0xFFF3E8FF);
      case 'request_accepted':
      case 'requestAccepted':
        return const Color(0xFFDCFCE7);
      case 'request_rejected':
      case 'requestRejected':
        return const Color(0xFFFEE2E2);
      case 'match_created':
      case 'matchCreated':
        return const Color(0xFFFFE4E6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _getFgColor() {
    switch (notification.type) {
      case 'team_invite':
      case 'teamInvite':
        return const Color(0xFF2563EB);
      case 'join_request':
      case 'joinRequest':
        return const Color(0xFF16A34A);
      case 'community_post':
      case 'communityPost':
        return const Color(0xFFD97706);
      case 'chat_message':
      case 'chatMessage':
        return const Color(0xFF9333EA);
      case 'request_accepted':
      case 'requestAccepted':
        return const Color(0xFF16A34A);
      case 'request_rejected':
      case 'requestRejected':
        return const Color(0xFFDC2626);
      case 'match_created':
      case 'matchCreated':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}g trước';
    if (diff.inDays < 7) return '${diff.inDays}ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
