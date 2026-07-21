import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/events/event_bus.dart';
import '../../notification/screens/notification_screen.dart';
import '../../profile/models/game_model.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../explore/services/explore_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<GameModel> _games = [];
  List<OnlinePlayerModel> _onlinePlayers = [];
  bool _isLoadingGames = true;
  bool _isLoadingPlayers = true;
  String? _gamesError;
  String? _playersError;
  StreamSubscription? _presenceSub;
  final ExploreApiService _exploreApiService = ExploreApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenPresenceEvents();
  }

  void _listenPresenceEvents() {
    _presenceSub = AppEventBus.instance.presenceStream.listen((_) {
      if (!mounted) return;
      _loadOnlinePlayers(silent: true);
    });
  }

  @override
  void dispose() {
    _presenceSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadGames(),
      _loadOnlinePlayers(),
    ]);
  }

  Future<void> _loadGames() async {
    if (!mounted) return;
    setState(() => _isLoadingGames = true);

    try {
      final resp = await DioClient.get(ApiConstants.popularGames);
      final json = resp.data as Map<String, dynamic>?;
      if (json != null && json['success'] == true) {
        final list = json['data'] as List<dynamic>?;
        if (list != null && mounted) {
          setState(() {
            _games = list.map((e) => GameModel.fromJson(e as Map<String, dynamic>)).toList();
            _isLoadingGames = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingGames = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gamesError = 'Không thể tải games';
          _isLoadingGames = false;
        });
      }
    }
  }

  Future<void> _loadOnlinePlayers({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoadingPlayers = true);

    try {
      final players = await _exploreApiService.getOnlinePlayers();
      if (mounted) {
        setState(() {
          _onlinePlayers = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _playersError = 'Không thể tải người chơi';
          _isLoadingPlayers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      SizedBox(height: 20),
                      _HomeHeader(),
                      SizedBox(height: 24),
                      _SectionTitle(title: 'Game phổ biến'),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
                _PopularGamesSection(
                  games: _games,
                  isLoading: _isLoadingGames,
                  error: _gamesError,
                  onRetry: _loadGames,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      SizedBox(height: 24),
                      _SectionTitle(title: 'Người chơi đang online'),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
                _OnlinePlayersSection(
                  players: _onlinePlayers,
                  isLoading: _isLoadingPlayers,
                  error: _playersError,
                  onRetry: _loadOnlinePlayers,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xin chào, Game thủ 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('Hôm nay bạn muốn tìm đội nào?', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }
}

class _PopularGamesSection extends StatelessWidget {
  final List<GameModel> games;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _PopularGamesSection({
    required this.games,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && games.isEmpty) {
      return SizedBox(
        height: 110,
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ),
      );
    }

    if (games.isEmpty) {
      return const SizedBox(
        height: 110,
        child: Center(child: Text('Chưa có game')),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: games.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = games[index];
          return _PopularGameCard(
            name: game.name,
            rankCount: game.ranks.length,
            iconUrl: game.iconUrl,
            gradientStart: game.gradientStart,
            gradientEnd: game.gradientEnd,
          );
        },
      ),
    );
  }
}

class _PopularGameCard extends StatelessWidget {
  final String name;
  final int rankCount;
  final String? iconUrl;
  final String? gradientStart;
  final String? gradientEnd;

  const _PopularGameCard({
    required this.name,
    required this.rankCount,
    this.iconUrl,
    this.gradientStart,
    this.gradientEnd,
  });

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorStart = _parseHex(gradientStart, AppColors.primary);
    final colorEnd = _parseHex(gradientEnd, const Color(0xFF0F172A));
    final hasImage = iconUrl != null && iconUrl!.isNotEmpty;

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: hasImage
                ? Image.network(
                    iconUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _GradientFallback(
                      colorStart: colorStart,
                      colorEnd: colorEnd,
                    ),
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colorStart, colorEnd],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                  )
                : _GradientFallback(colorStart: colorStart, colorEnd: colorEnd),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$rankCount ranks',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GradientFallback extends StatelessWidget {
  final Color colorStart;
  final Color colorEnd;
  const _GradientFallback({required this.colorStart, required this.colorEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorStart, colorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 20),
    );
  }
}

class _OnlinePlayersSection extends StatelessWidget {
  final List<OnlinePlayerModel> players;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  const _OnlinePlayersSection({
    required this.players,
    required this.isLoading,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && players.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ),
      );
    }

    if (players.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 100,
          child: Center(child: Text('Chưa có người chơi nào online')),
        ),
      );
    }

    return Column(
      children: players.map((player) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: _OnlinePlayerCard(player: player),
        );
      }).toList(),
    );
  }
}

class _OnlinePlayerCard extends StatelessWidget {
  final OnlinePlayerModel player;

  const _OnlinePlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.divider.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: player.avatarUrl != null && player.avatarUrl!.isNotEmpty
                    ? NetworkImage(player.avatarUrl!)
                    : null,
                child: player.avatarUrl == null || player.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary, size: 26)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
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
                  player.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.username ?? ''}${player.gameName != null ? ' • ${player.gameName}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (player.rank != null && player.rank!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events_outlined, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          player.rank!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: player.userId),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Hồ sơ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
