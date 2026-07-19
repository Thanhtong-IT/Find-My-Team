import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../team/services/friendship_api_service.dart';
import '../../team/models/friendship_model.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final _api = FriendshipApiService();
  bool _isLoading = true;
  String? _error;
  List<FriendshipModel> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final requests = await _api.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải lời mời kết bạn';
        _isLoading = false;
      });
    }
  }

  Future<void> _accept(FriendshipModel request) async {
    try {
      final id = request.id;
      if (id == null) return;
      await _api.acceptFriendRequest(id);
      if (!mounted) return;
      _showSnackBar('Đã chấp nhận lời mời kết bạn');
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể chấp nhận lời mời', isError: true);
    }
  }

  Future<void> _reject(FriendshipModel request) async {
    try {
      final id = request.id;
      if (id == null) return;
      await _api.rejectFriendRequest(id);
      if (!mounted) return;
      _showSnackBar('Đã từ chối lời mời kết bạn');
      _loadRequests();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Không thể từ chối lời mời', isError: true);
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
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lời mời kết bạn',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_requests.length} lời mời',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        toolbarHeight: isSmallScreen ? 80 : 90,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
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
                onPressed: _loadRequests,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add_disabled_rounded, size: isSmallScreen ? 48 : 56, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Không có lời mời nào',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Khi có người muốn kết bạn với bạn, lời mời sẽ xuất hiện ở đây',
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
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RequestTile(request: request, isSmallScreen: isSmallScreen, onAccept: () => _accept(request), onReject: () => _reject(request)),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendshipModel request;
  final bool isSmallScreen;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestTile({required this.request, required this.isSmallScreen, required this.onAccept, required this.onReject});

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
            backgroundImage: request.friendAvatarUrl != null && request.friendAvatarUrl!.isNotEmpty
                ? NetworkImage(request.friendAvatarUrl!)
                : null,
            child: request.friendAvatarUrl == null || request.friendAvatarUrl!.isEmpty
                ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 24 : 28)
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
                    fontSize: isSmallScreen ? 14 : 16,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onReject,
                icon: Icon(Icons.close_rounded, color: AppColors.error, size: isSmallScreen ? 20 : 22),
                style: IconButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.08)),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAccept,
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
