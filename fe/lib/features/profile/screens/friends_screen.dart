import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/chat/unread_friend_manager.dart';
import '../../team/services/friendship_api_service.dart';
import '../../team/models/friendship_model.dart';
import '../../chat/screens/private_chat_screen.dart';
import '../../notification/screens/notification_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _api = FriendshipApiService();
  bool _isLoading = true;
  String? _error;
  List<FriendshipModel> _friends = [];
  List<FriendshipModel> _pendingRequests = [];
  StreamSubscription? _unreadSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _unreadSub = UnreadFriendManager.instance.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getFriends(),
        _api.getPendingRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _friends = results[0];
        _pendingRequests = results[1].where((r) => r.isReceived || r.direction == null).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải danh sách bạn bè';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await _api.acceptFriendRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã chấp nhận lời mời kết bạn'), backgroundColor: AppColors.success),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await _api.rejectFriendRequest(friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối lời mời kết bạn')),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
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
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn bè',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_friends.length} người bạn${_pendingRequests.isNotEmpty ? ' • ${_pendingRequests.length} lời mời' : ''}',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: _loadData,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationScreen())),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 20),
        ],
        toolbarHeight: isSmallScreen ? 80 : 90,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(isSmallScreen),
      ),
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingRequests.isNotEmpty) ...[
            Text(
              'Lời mời kết bạn (${_pendingRequests.length})',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ..._pendingRequests.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PendingRequestTile(
                request: req,
                isSmallScreen: isSmallScreen,
                onAccept: () => req.id != null ? _acceptRequest(req.id!) : null,
                onReject: () => req.id != null ? _rejectRequest(req.id!) : null,
              ),
            )),
            const SizedBox(height: 16),
          ],
          Text(
            'Danh sách bạn bè (${_friends.length})',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.textLight),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có bạn bè nào',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy kết bạn với người chơi khác để xem tại đây',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._friends.map((friend) {
              final hasUnread = UnreadFriendManager.instance.hasUnreadFrom(friend.friendId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FriendTile(
                  friend: friend,
                  isSmallScreen: isSmallScreen,
                  hasUnread: hasUnread,
                  onTap: () {
                    UnreadFriendManager.instance.markAsRead(friend.friendId);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PrivateChatScreen(
                          friendId: friend.friendId,
                          friendName: friend.displayName,
                          friendAvatar: friend.friendAvatarUrl,
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PendingRequestTile extends StatelessWidget {
  final FriendshipModel request;
  final bool isSmallScreen;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestTile({
    required this.request,
    required this.isSmallScreen,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
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
                  request.displayName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${request.friendUsername}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.divider),
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12, vertical: 0),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Từ chối', style: TextStyle(fontSize: isSmallScreen ? 11 : 12)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 14, vertical: 0),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Chấp nhận', style: TextStyle(fontSize: isSmallScreen ? 11 : 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendshipModel friend;
  final bool isSmallScreen;
  final bool hasUnread;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.isSmallScreen,
    this.hasUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 24 : 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: friend.friendAvatarUrl != null && friend.friendAvatarUrl!.isNotEmpty
                ? NetworkImage(friend.friendAvatarUrl!)
                : null,
            child: friend.friendAvatarUrl == null || friend.friendAvatarUrl!.isEmpty
                ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 24 : 28)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${friend.friendUsername}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.chat_bubble_outline_rounded, size: isSmallScreen ? 16 : 18),
                label: Text(
                  'Nhắn tin',
                  style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1.5),
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
