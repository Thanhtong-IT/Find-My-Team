import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import '../../../core/events/event_bus.dart';
import '../../team/models/friendship_model.dart';
import '../../team/services/friendship_api_service.dart';
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
  final _friendshipApi = FriendshipApiService();
  List<FriendshipModel> _friendRequests = [];
  bool _isLoadingFriendRequests = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    context.read<NotificationBloc>().add(const NotificationLoadRequested());
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    if (!mounted) return;
    setState(() => _isLoadingFriendRequests = true);
    try {
      final reqs = await _friendshipApi.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _friendRequests = reqs;
        _isLoadingFriendRequests = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFriendRequests = false);
      }
    }
  }

  Future<void> _acceptFriendRequest(FriendshipModel request) async {
    try {
      if (request.id == null) return;
      await _friendshipApi.acceptFriendRequest(request.id!);
      if (!mounted) return;
      _showSnackBar('Đã chấp nhận lời mời kết bạn');
      _loadAll();
    } catch (e) {
      if (mounted) _showSnackBar('Không thể chấp nhận lời mời', isError: true);
    }
  }

  Future<void> _rejectFriendRequest(FriendshipModel request) async {
    try {
      if (request.id == null) return;
      await _friendshipApi.rejectFriendRequest(request.id!);
      if (!mounted) return;
      _showSnackBar('Đã từ chối lời mời kết bạn');
      _loadAll();
    } catch (e) {
      if (mounted) _showSnackBar('Không thể từ chối lời mời', isError: true);
    }
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
      case 0:
        return state.notifications;
      case 1:
        return state.notifications.where((n) => n.type == 'join_request' || n.type == 'team_invite').toList();
      case 2:
        return state.notifications
            .where((n) =>
                n.type == 'community_post' ||
                n.type == 'chat_message' ||
                n.type == 'request_accepted' ||
                n.type == 'request_rejected')
            .toList();
      default:
        return [];
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
          if (state.actionMessage!.contains('chấp nhận')) {
            AppEventBus.instance.triggerTeamReload();
            AppEventBus.instance.navigateToTab(1);
            Navigator.pop(context);
          }
        }
        if (state.actionStatus == ActionStatus.error) {
          _showSnackBar(state.actionMessage ?? 'Có lỗi xảy ra', isError: true);
        }
      },
      builder: (context, state) {
        final isActionLoading =
            state.actionStatus == ActionStatus.accepting || state.actionStatus == ActionStatus.rejecting;
        return Scaffold(
          backgroundColor: AppColors.white,
          body: RefreshIndicator(
            onRefresh: () async {
              _loadAll();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: Column(
              children: [
                _buildHeader(isSmallScreen, state),
                _buildTabs(isSmallScreen),
                Expanded(
                  child: _buildNotificationList(isSmallScreen, state, isActionLoading),
                ),
              ],
            ),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isSelected = index == _selectedTabIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTabIndex = index);
                    if (index == 1) {
                      _loadFriendRequests();
                    }
                  },
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
        ),
      ],
    );
  }

  Widget _buildNotificationList(bool isSmallScreen, NotificationState state, bool isActionLoading) {
    // Sửa logic check Loading tách biệt rõ ràng
    if (_selectedTabIndex == 1 && _isLoadingFriendRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_selectedTabIndex != 1 && state.status == NotificationStatus.loading) {
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
              onPressed: _loadAll,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final notifications = _getFilteredNotifications(state);
    final showFriendRequests = _selectedTabIndex == 1;

    // Sửa logic Check Rỗng chuẩn xác
    final isTabRequestsEmpty = showFriendRequests && _friendRequests.isEmpty && notifications.isEmpty;
    final isOtherTabEmpty = !showFriendRequests && notifications.isEmpty;

    if (isTabRequestsEmpty || isOtherTabEmpty) {
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
                  ? 'Các yêu cầu kết bạn và tham gia sẽ xuất hiện ở đây'
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
      itemCount: notifications.length + (showFriendRequests ? _friendRequests.length : 0),
      itemBuilder: (context, index) {
        if (showFriendRequests && index < _friendRequests.length) {
          final request = _friendRequests[index];
          return _buildFriendRequestTile(request, isSmallScreen);
        }

        final notificationIndex = showFriendRequests ? index - _friendRequests.length : index;
        final notif = notifications[notificationIndex];
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

  Widget _buildFriendRequestTile(FriendshipModel request, bool isSmallScreen) {
    // Sửa lỗi gọi sai tên biến mapping JSON: displayName -> friendDisplayName
    final displayName = request.friendDisplayName ?? request.friendUsername ?? 'Người dùng';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 22 : 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: request.friendAvatarUrl != null && request.friendAvatarUrl!.isNotEmpty
                ? NetworkImage(request.friendAvatarUrl!)
                : null,
            child: request.friendAvatarUrl == null || request.friendAvatarUrl!.isEmpty
                ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 22 : 26)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Muốn kết bạn với bạn',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _rejectFriendRequest(request),
                icon: Icon(Icons.close_rounded, color: AppColors.error, size: isSmallScreen ? 20 : 22),
                style: IconButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.08)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _acceptFriendRequest(request),
                icon: Icon(Icons.check_rounded, color: AppColors.success, size: isSmallScreen ? 20 : 22),
                style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.08)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}