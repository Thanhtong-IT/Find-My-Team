import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../../core/network/dio_client.dart';
import '../../profile/models/game_model.dart';
import 'create_request_screen.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  List<GameModel> _games = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);

    try {
      final resp = await DioClient.get(ApiConstants.games);
      final json = resp.data as Map<String, dynamic>?;
      if (json != null && json['success'] == true) {
        final list = json['data'] as List<dynamic>?;
        if (list != null && mounted) {
          setState(() {
            _games = list.map((e) => GameModel.fromJson(e as Map<String, dynamic>)).toList();
            _isLoading = false;
          });
          return;
        }
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách game';
          _isLoading = false;
        });
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn trò chơi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _games.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadGames,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _games.isEmpty
                    ? const Center(child: Text('Chưa có game nào', style: TextStyle(color: AppColors.textSecondary)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Chọn tựa game bạn muốn tìm đồng đội hoặc tham gia nhóm ngay hôm nay.',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 24),
                            ..._games.map((game) => Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: _GameSelectionCard(
                                    game: game,
                                    isSmallScreen: isSmallScreen,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CreateRequestScreen(gameName: game.name),
                                        ),
                                      );
                                    },
                                  ),
                                )),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
      ),
    );
  }
}

class _GameSelectionCard extends StatelessWidget {
  final GameModel game;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _GameSelectionCard({
    required this.game,
    required this.isSmallScreen,
    required this.onTap,
  });

  List<Color> get _gradientColors {
    final startHex = game.gradientStart ?? '#6D28D9';
    final endHex = game.gradientEnd ?? '#4C1D95';
    return [
      _hexToColor(startHex),
      _hexToColor(endHex),
    ];
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  String get _gameTag {
    final roles = game.roles;
    if (roles.isNotEmpty) {
      return roles.length > 2 ? 'Multi-role' : roles.join(', ');
    }
    return 'Game';
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = isSmallScreen ? 170.0 : 190.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _gradientColors,
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.12,
                  child: Center(
                    child: Icon(
                      Icons.sports_esports_rounded,
                      size: isSmallScreen ? 80 : 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: isSmallScreen ? 16 : 20,
                right: isSmallScreen ? 60 : 70,
                bottom: isSmallScreen ? 16 : 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _gameTag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${game.roles.length} vai trò',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: isSmallScreen ? 16 : 20,
                bottom: isSmallScreen ? 16 : 20,
                child: Container(
                  width: isSmallScreen ? 40 : 46,
                  height: isSmallScreen ? 40 : 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _gradientColors[0],
                    size: isSmallScreen ? 20 : 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

