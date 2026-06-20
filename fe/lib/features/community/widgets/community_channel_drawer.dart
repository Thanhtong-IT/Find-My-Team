import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../models/community_model.dart';
import '../models/channel_model.dart';

class CommunityChannelDrawer extends StatelessWidget {
  final CommunityModel community;
  final ChannelModel? selectedChannel;
  final List<ChannelModel> channels;
  final bool isLoading;
  final void Function(ChannelModel) onChannelSelected;
  final void Function(ChannelType type) onCreateChannelPressed;

  const CommunityChannelDrawer({
    super.key,
    required this.community,
    required this.selectedChannel,
    required this.channels,
    required this.isLoading,
    required this.onChannelSelected,
    required this.onCreateChannelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;
    final textChannels = channels.where((c) => c.type == ChannelType.text).toList();
    final voiceChannels = channels.where((c) => c.type == ChannelType.voice).toList();

    return Container(
      width: isSmallScreen ? screenWidth * 0.78 : 300,
      color: AppColors.white,
      child: Column(
        children: [
          _buildHeader(context, isSmallScreen),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChannelSection(context, 'Kênh chat', Icons.tag_rounded, textChannels, ChannelType.text, isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildChannelSection(context, 'Kênh voice', Icons.volume_up_rounded, voiceChannels, ChannelType.voice, isSmallScreen),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              height: isSmallScreen ? 90 : 110,
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 44 : 52,
                    height: isSmallScreen ? 44 : 52,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.forum_rounded, color: AppColors.white, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          community.name,
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.bold, color: AppColors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text(
                              '${community.onlineCount} online',
                              style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${community.memberCount} thành viên',
                          style: TextStyle(fontSize: isSmallScreen ? 11 : 12, color: AppColors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.white.withValues(alpha: 0.0), AppColors.white.withValues(alpha: 0.4), AppColors.white.withValues(alpha: 0.0)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: AppColors.white.withValues(alpha: 0.9), size: isSmallScreen ? 15 : 17),
                          const SizedBox(width: 6),
                          Text('Tìm kiếm...', style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSection(
    BuildContext context,
    String title,
    IconData icon,
    List<ChannelModel> channels,
    ChannelType type,
    bool isSmallScreen,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16),
          child: Row(
            children: [
              Icon(icon, size: isSmallScreen ? 13 : 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showCreateChannelDialog(context, type),
                child: Icon(Icons.add_rounded, size: isSmallScreen ? 16 : 18, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        ...channels.map((channel) => _buildChannelItem(context, channel, isSmallScreen)),
      ],
    );
  }

  Widget _buildChannelItem(BuildContext context, ChannelModel channel, bool isSmallScreen) {
    final isSelected = selectedChannel?.id == channel.id;

    // Text channel - clickable
    if (channel.type == ChannelType.text) {
      return GestureDetector(
        onTap: () {
          onChannelSelected(channel);
          Navigator.pop(context);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 7 : 9),
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          child: Row(
            children: [
              Text('#', style: TextStyle(fontSize: isSmallScreen ? 16 : 18, fontWeight: FontWeight.w500, color: isSelected ? AppColors.primary : AppColors.textSecondary)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  channel.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Voice channel - Discord style with speaker icon
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 14 : 16, vertical: isSmallScreen ? 6 : 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
      child: Row(
        children: [
          Icon(Icons.volume_up_rounded, size: isSmallScreen ? 16 : 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              channel.name,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (channel.onlineCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 10, color: AppColors.success),
                  const SizedBox(width: 2),
                  Text('${channel.onlineCount}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
                ],
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // TODO: Voice connection logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Voice channel: ${channel.name}'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: Icon(Icons.volume_off_rounded, size: isSmallScreen ? 18 : 20, color: AppColors.textSecondary),
            tooltip: 'Voice',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  void _showCreateChannelDialog(BuildContext context, ChannelType type) {
    onCreateChannelPressed(type);
  }
}
