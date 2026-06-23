import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/repository/secure_storage_repository.dart';
import '../../profile/services/user_api_service.dart';
import '../models/team_model.dart';
import '../services/invitation_api_service.dart';

class InviteMemberScreen extends StatefulWidget {
  final TeamModel team;

  const InviteMemberScreen({super.key, required this.team});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  final _apiService = UserApiService();
  final _invitationApi = InvitationApiService();
  final _storage = SecureStorageRepository();
  final _searchController = TextEditingController();

  List<UserSearchResult> _searchResults = [];
  List<UserSearchResult> _filteredResults = [];
  bool _isSearching = false;
  bool _isSending = false;
  String? _currentUserId;
  final Set<String> _sentInvitations = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _currentUserId = await _storage.getUserId();
    if (mounted) setState(() {});
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _filteredResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _apiService.searchUsers(query);
      // Filter out current user
      final filtered = results.where((u) => u.id != _currentUserId).toList();
      setState(() {
        _searchResults = filtered;
        _filteredResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      _showSnackBar('Không thể tìm kiếm người dùng', isError: true);
    }
  }

  Future<void> _sendInvitation(UserSearchResult user) async {
    if (_sentInvitations.contains(user.id) || _isSending) return;

    setState(() => _isSending = true);

    try {
      await _invitationApi.createInvitation(
        inviteeId: user.id,
        teamId: widget.team.id,
      );

      setState(() {
        _sentInvitations.add(user.id);
        _isSending = false;
      });

      _showSnackBar('Đã gửi lời mời tới ${user.displayName}');
    } catch (e) {
      setState(() => _isSending = false);
      _showSnackBar('Không thể gửi lời mời: ${e.toString()}', isError: true);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mời thành viên',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mời người chơi vào nhóm "${widget.team.name}"',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchUsers('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  onChanged: _searchUsers,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildResultsList(isSmallScreen)),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isSmallScreen) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: isSmallScreen ? 60 : 72,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Tìm kiếm người dùng để mời',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhập tên hoặc username',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: isSmallScreen ? 60 : 72,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy người dùng',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử từ khóa khác',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final user = _filteredResults[index];
        final isSent = _sentInvitations.contains(user.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _UserSearchCard(
            user: user,
            isSmallScreen: isSmallScreen,
            isSent: isSent,
            isSending: _isSending && !isSent,
            onInvite: () => _sendInvitation(user),
          ),
        );
      },
    );
  }
}

class _UserSearchCard extends StatelessWidget {
  final UserSearchResult user;
  final bool isSmallScreen;
  final bool isSent;
  final bool isSending;
  final VoidCallback onInvite;

  const _UserSearchCard({
    required this.user,
    required this.isSmallScreen,
    required this.isSent,
    required this.isSending,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 22 : 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: isSmallScreen ? 22 : 26,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (user.gameProfile != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${user.gameProfile!.gameName} \u2022 ${user.gameProfile!.rank}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isSent)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 14,
                vertical: isSmallScreen ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check,
                    size: isSmallScreen ? 14 : 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đã gửi',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: isSmallScreen ? 36 : 40,
              child: ElevatedButton(
                onPressed: isSending ? null : onInvite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                  ),
                ),
                child: isSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        'Mời',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
