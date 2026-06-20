import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../../../core/events/event_bus.dart';
import 'game_selection_screen.dart';
import '../../team/services/team_api_service.dart';
import '../../team/models/team_model.dart';
import '../../profile/models/game_model.dart';
import '../../profile/services/user_api_service.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../services/explore_api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGame = 'Tất cả game';
  String _searchQuery = '';

  List<GameModel> _games = [];
  List<TeamModel> _teams = [];
  List<OnlinePlayerModel> _onlinePlayers = [];
  List<SearchUserModel> _searchResults = [];
  bool _isLoadingGames = true;
  bool _isLoadingTeams = true;
  bool _isLoadingPlayers = true;
  bool _isSearching = false;
  bool _hasSearchError = false;
  GameModel? _selectedGameModel;

  final ExploreApiService _exploreService = ExploreApiService();
  StreamSubscription? _exploreTeamSub;
  Timer? _searchDebounce;

  List<String> get _gameFilters {
    return ['Tất cả game', ..._games.map((g) => g.name)];
  }

  List<TeamModel> get _filteredTeams {
    if (_searchQuery.isEmpty) return _teams;
    return _teams.where((team) {
      return team.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          team.gameName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (team.description != null && team.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  List<OnlinePlayerModel> get _filteredPlayers {
    return _onlinePlayers.where((player) {
      final matchGame = _selectedGame == 'Tất cả game' || player.gameName == _selectedGame;
      final matchSearch = _searchQuery.isEmpty ||
          player.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (player.gameName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (player.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchGame && matchSearch;
    }).toList();
  }

  bool get _isSearchMode => _searchQuery.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenTeamEvents();
  }

  void _listenTeamEvents() {
    _exploreTeamSub = AppEventBus.instance.exploreTeamStream.listen((event) {
      if (!mounted) return;
      _loadTeams();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingGames = true;
    });
    try {
      final games = await UserApiService().getPopularGames();
      if (!mounted) return;
      setState(() {
        _games = games;
        _isLoadingGames = false;
      });
      await Future.wait([
        _loadTeams(),
        _loadOnlinePlayers(),
      ]);
    } catch (e, stack) {
      debugPrint('Error loading initial data: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _isLoadingGames = false;
      });
    }
  }

  Future<void> _loadOnlinePlayers() async {
    if (!mounted) return;
    setState(() => _isLoadingPlayers = true);
    try {
      final players = await _exploreService.getOnlinePlayers();
      if (mounted) {
        setState(() {
          _onlinePlayers = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading online players: $e');
      if (mounted) {
        setState(() {
          _onlinePlayers = [];
          _isLoadingPlayers = false;
        });
      }
    }
  }

  Future<void> _loadTeams() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTeams = true;
    });
    try {
      List<TeamModel> loadedTeams;
      if (_selectedGameModel == null) {
        loadedTeams = await TeamApiService().getRecruitingTeams(limit: 5);
      } else {
        loadedTeams = await TeamApiService().getOpenTeams(gameId: _selectedGameModel!.id);
      }
      if (!mounted) return;
      setState(() {
        _teams = loadedTeams;
        _isLoadingTeams = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading teams: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _teams = [];
        _isLoadingTeams = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    _searchDebounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchError = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearchError = false;
    });

    try {
      final results = await _exploreService.searchUsers(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchError = true;
      });
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

  void _joinTeam(String teamId) async {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        title: const Text('Xin vào đội', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: TextField(
          controller: messageController,
          maxLines: 2,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Nhập lời giới thiệu (ví dụ: Mình đi rừng, có mic...)',
            hintStyle: TextStyle(color: AppColors.textLight),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TeamApiService().sendJoinRequest(teamId, message: messageController.text.trim());
                _showSnackBar('Đã gửi yêu cầu tham gia đội!');
              } catch (e) {
                String errorMsg = 'Gửi yêu cầu thất bại';
                if (e is DioException) {
                  final respData = e.response?.data;
                  if (respData is Map && respData['message'] != null) {
                    errorMsg = respData['message'].toString();
                  }
                }
                _showSnackBar(errorMsg, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _exploreTeamSub?.cancel();
    _searchDebounce?.cancel();
    super.dispose();
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
              'Khám phá',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Text(
              'Tìm đội đang mở và người chơi phù hợp để lập team',
              style: TextStyle(fontSize: isSmallScreen ? 11 : 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            ),
          ),
        ],
        toolbarHeight: isSmallScreen ? 80 : 90,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              _ExploreSearchBar(
                controller: _searchController,
                isSmallScreen: isSmallScreen,
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 16),
              if (!_isSearchMode) ...[
                _isLoadingGames
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator()))
                    : _GameFilterChips(
                        filters: _gameFilters,
                        selected: _selectedGame,
                        onSelected: (value) {
                          setState(() {
                            _selectedGame = value;
                            if (value == 'Tất cả game') {
                              _selectedGameModel = null;
                            } else {
                              _selectedGameModel = _games.firstWhere((g) => g.name == value);
                            }
                          });
                          _loadTeams();
                        },
                      ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Đội đang mở',
                  onViewAll: () {},
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 12),
                _isLoadingTeams
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                    : _filteredTeams.isEmpty
                        ? _EmptyState(message: 'Không có đội nào phù hợp', isSmallScreen: isSmallScreen)
                        : Column(
                            children: _filteredTeams
                                .map((team) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _TeamOpenCard(
                                        team: team,
                                        isSmallScreen: isSmallScreen,
                                        onJoin: () => _joinTeam(team.id),
                                        onShare: () => _showSnackBar('Chia sẻ thông tin đội'),
                                      ),
                                    ))
                                .toList(),
                          ),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'Người chơi đang online',
                  onViewAll: () {},
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 12),
                _isLoadingPlayers
                    ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                    : _filteredPlayers.isEmpty
                        ? _EmptyState(message: 'Không có người chơi nào phù hợp', isSmallScreen: isSmallScreen)
                        : Column(
                            children: _filteredPlayers
                                .map((player) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _OnlinePlayerCardFromApi(
                                        player: player,
                                        isSmallScreen: isSmallScreen,
                                        onProfile: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserProfileScreen(userId: player.userId),
                                            ),
                                          );
                                        },
                                        onInvite: () {},
                                      ),
                                    ))
                                .toList(),
                          ),
              ] else ...[
                _SectionHeader(
                  title: 'Kết quả tìm kiếm',
                  onViewAll: () {},
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 12),
                _buildSearchResults(isSmallScreen),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: _isSearchMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'explore_create_request_fab',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameSelectionScreen())),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo yêu cầu tìm đội', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSearchResults(bool isSmallScreen) {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasSearchError) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _EmptyState(
          message: 'Đã xảy ra lỗi khi tìm kiếm',
          isSmallScreen: isSmallScreen,
          icon: Icons.error_outline_rounded,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: _EmptyState(
          message: 'Không tìm thấy người dùng nào',
          isSmallScreen: isSmallScreen,
        ),
      );
    }

    return Column(
      children: _searchResults
          .map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SearchUserCard(
                  user: user,
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: user.id),
                      ),
                    );
                  },
                ),
              ))
          .toList(),
    );
  }
}

class _ExploreSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSmallScreen;
  final ValueChanged<String> onChanged;

  const _ExploreSearchBar({
    required this.controller,
    required this.isSmallScreen,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isSmallScreen ? 44 : 48,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm tên đội, người chơi hoặc ID...',
          hintStyle: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textLight),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class _GameFilterChips extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _GameFilterChips({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = filters[index] == selected;
          return GestureDetector(
            onTap: () => onSelected(filters[index]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: AppColors.divider),
              ),
              alignment: Alignment.center,
              child: Text(
                filters[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final bool isSmallScreen;

  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            'Xem tất cả',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamOpenCard extends StatelessWidget {
  final TeamModel team;
  final bool isSmallScreen;
  final VoidCallback onJoin;
  final VoidCallback onShare;

  const _TeamOpenCard({
    required this.team,
    required this.isSmallScreen,
    required this.onJoin,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm dd/MM').format(team.createdAt);
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 40 : 48,
                height: isSmallScreen ? 40 : 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.groups_rounded, color: AppColors.primary, size: isSmallScreen ? 20 : 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team.gameName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 10, vertical: isSmallScreen ? 3 : 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Đang tuyển',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onShare,
                child: Icon(Icons.ios_share, color: AppColors.textSecondary, size: isSmallScreen ? 18 : 20),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Row(
            children: [
              _InfoChip(label: team.requiredRank ?? 'Không yêu cầu', icon: Icons.emoji_events_outlined, isSmallScreen: isSmallScreen),
              const SizedBox(width: 8),
              _InfoChip(label: '${team.members.length}/${team.maxMembers}', icon: Icons.people_outline, isSmallScreen: isSmallScreen),
              const SizedBox(width: 8),
              _InfoChip(label: timeStr, icon: Icons.access_time_rounded, isSmallScreen: isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            team.description ?? 'Không có mô tả',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 13,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
          SizedBox(
            width: double.infinity,
            height: isSmallScreen ? 36 : 40,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Xin vào đội',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSmallScreen;
  const _InfoChip({required this.label, required this.icon, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 10, vertical: isSmallScreen ? 3 : 5),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmallScreen ? 11 : 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: isSmallScreen ? 10 : 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final bool isSmallScreen;
  final IconData? icon;

  const _EmptyState({required this.message, required this.isSmallScreen, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon ?? Icons.search_off_rounded, size: isSmallScreen ? 40 : 48, color: AppColors.textLight),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            message,
            style: TextStyle(fontSize: isSmallScreen ? 13 : 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnlinePlayerCardFromApi extends StatelessWidget {
  final OnlinePlayerModel player;
  final bool isSmallScreen;
  final VoidCallback onProfile;
  final VoidCallback onInvite;

  const _OnlinePlayerCardFromApi({
    required this.player,
    required this.isSmallScreen,
    required this.onProfile,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: isSmallScreen ? 24 : 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: player.avatarUrl != null ? NetworkImage(player.avatarUrl!) : null,
                child: player.avatarUrl == null ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 24 : 28) : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: isSmallScreen ? 12 : 14,
                  height: isSmallScreen ? 12 : 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  player.displayName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 0 : 2),
                          Text(
                            '${player.username ?? ''} ${player.gameName != null ? '\u2022 ${player.gameName}' : ''}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Row(
                  children: [
                    if (player.rank != null) _InfoChip(label: player.rank!, icon: Icons.emoji_events_outlined, isSmallScreen: isSmallScreen),
                    if (player.rank != null && player.role != null) const SizedBox(width: 6),
                    if (player.role != null) _InfoChip(label: player.role!, icon: Icons.shield_outlined, isSmallScreen: isSmallScreen),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: isSmallScreen ? 30 : 34,
                child: OutlinedButton(
                  onPressed: onProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  ),
                  child: Text('Hồ sơ', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              SizedBox(
                height: isSmallScreen ? 30 : 34,
                child: ElevatedButton(
                  onPressed: onInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  ),
                  child: Text('Mời chơi', style: TextStyle(fontSize: isSmallScreen ? 10 : 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchUserCard extends StatelessWidget {
  final SearchUserModel user;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _SearchUserCard({
    required this.user,
    required this.isSmallScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: isSmallScreen ? 24 : 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Icon(Icons.person, color: AppColors.primary, size: isSmallScreen ? 24 : 28) : null,
                ),
                if (user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: isSmallScreen ? 12 : 14,
                      height: isSmallScreen ? 12 : 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.effectiveDisplayName,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: AppColors.textLight,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textLight, size: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }
}
