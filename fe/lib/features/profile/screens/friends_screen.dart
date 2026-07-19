import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../team/services/friendship_api_service.dart';
import '../../team/models/friendship_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final friends = await _api.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
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
              '${_friends.length} người bạn',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              onPressed: _loadFriends,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            ),
          ),
        ],
        toolbarHeight: isSmallScreen ? 80 : 90,
      ),
      body: RefreshIndicator(
        onRefresh: _loadFriends,
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
                onPressed: _loadFriends,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 8 : 12),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FriendTile(friend: friend, isSmallScreen: isSmallScreen),
        );
      },
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendshipModel friend;
  final bool isSmallScreen;

  const _FriendTile({required this.friend, required this.isSmallScreen});

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
          TextButton.icon(
            onPressed: () {
              // Optional: navigate to chat or profile
            },
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
        ],
      ),
    );
  }
}
