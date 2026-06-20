import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/events/event_bus.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback? onInvitationAccepted;

  const NotificationScreen({super.key, this.onInvitationAccepted});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const NotificationLoadRequested());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<NotificationItemModel> _getFilteredNotifications(NotificationState state) {
    switch (_selectedTabIndex) {
      case 0: return state.notifications;
      case 1: return state.notifications.where((n) => n.type == 'join_request' || n.type == 'team_invite').toList();
      case 2: return state.notifications.where((n) => n.type == 'community_post' || n.type == 'chat_message' || n.type == 'request_accepted' || n.type == 'request_rejected').toList();
      default: return [];
    }
  }

  void _onAccept(NotificationItemModel notif) {
    if (notif.type != 'team_invite' || notif.actionId == null) return;
    context.read<NotificationBloc>().add(NotificationAcceptInvitationRequested(
      notificationId: notif.id,
      invitationId: notif.actionId!,
    ));
  }

  void _onReject(NotificationItemModel notif) {
    if (notif.type != 'team_invite' || notif.actionId == null) return;
    context.read<NotificationBloc>().add(NotificationRejectInvitationRequested(
      notificationId: notif.id,
      invitationId: notif.actionId!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSnackBar(state.errorMessage!, isError: true);
        }
        if (state.actionStatus == ActionStatus.success && state.actionMessage != null) {
          _showSnackBar(state.actionMessage!);
          // Trigger team reload and navigate to Team tab after accepting invitation
          if (state.actionMessage!.contains('chấp nhận')) {
            AppEventBus.instance.triggerTeamReload();
            AppEventBus.instance.navigateToTab(1); // Switch to Team tab (index 1)
            // Pop back to TeamScreen
            Navigator.pop(context);
          }
        }
        if (state.actionStatus == ActionStatus.error) {
          _showSnackBar(state.actionMessage ?? 'Có lỗi xảy ra', isError: true);
        }
      },
      builder: (context, state) {
        final isActionLoading = state.actionStatus == ActionStatus.accepting || state.actionStatus == ActionStatus.rejecting;
        return Scaffold(
          backgroundColor: AppColors.white,
          body: Column(
            children: [
              _buildHeader(isSmallScreen, state),
              _buildTabs(isSmallScreen),
              Expanded(
                child: _buildNotificationList(isSmallScreen, state, isActionLoading),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen, NotificationState state) {
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
              'Thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.white),
            onPressed: () {
              context.read<NotificationBloc>().add(const NotificationMarkAllReadRequested());
              _showSnackBar('Đã đánh dấu tất cả là đã đọc');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isSmallScreen) {
    final tabs = ['Tất cả', 'Yêu cầu', 'Thông tin'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotificationList(bool isSmallScreen, NotificationState state, bool isActionLoading) {
    if (state.status == NotificationStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == NotificationStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: isSmallScreen ? 60 : 72, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Không thể tải thông báo',
              style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<NotificationBloc>().add(const NotificationLoadRequested()),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final notifications = _getFilteredNotifications(state);

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: isSmallScreen ? 60 : 72, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 1 ? 'Không có yêu cầu nào' : 'Không có thông báo nào',
              style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTabIndex == 1
                  ? 'Các yêu cầu tham gia sẽ xuất hiện ở đây'
                  : 'Bạn sẽ nhận thông báo khi có hoạt động mới',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 8 : 12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final showActions = notif.type == 'team_invite';
        return NotificationCard(
          notification: notif,
          isSmallScreen: isSmallScreen,
          onTap: () {
            if (!notif.isRead) {
              context.read<NotificationBloc>().add(NotificationMarkAsReadRequested(notif.id));
            }
          },
          onAccept: showActions ? () => _onAccept(notif) : null,
          onReject: showActions ? () => _onReject(notif) : null,
          isLoading: isActionLoading,
        );
      },
    );
  }
}
