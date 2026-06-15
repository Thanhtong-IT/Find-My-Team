import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import 'create_request_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    final games = [
      _GameBanner(tag: 'FPS', title: 'Valorant', online: '1.2k đang tìm', gradient: const [Color(0xFFFD4556), Color(0xFFBD2020)]),
      _GameBanner(tag: 'MOBA 5v5', title: 'Liên Quân Mobile', online: '3.5k đang tìm', gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
      _GameBanner(tag: 'MOBA PC', title: 'Liên Minh Huyền Thoại', online: '3.1k đang tìm', gradient: const [Color(0xFF6D28D9), Color(0xFF4C1D95)]),
      _GameBanner(tag: 'Battle Royale', title: 'PUBG Mobile', online: '850 đang tìm', gradient: const [Color(0xFF059669), Color(0xFF065F46)]),
    ];

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
        child: SingleChildScrollView(
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
              ...games.map((game) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _GameSelectionCard(
                  game: game,
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRequestScreen(gameName: game.title),
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
  final _GameBanner game;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _GameSelectionCard({
    required this.game,
    required this.isSmallScreen,
    required this.onTap,
  });

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
                    colors: game.gradient,
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
                        game.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.title,
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
                          game.online,
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
                    color: game.gradient[0],
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

class _GameBanner {
  final String tag;
  final String title;
  final String online;
  final List<Color> gradient;

  _GameBanner({
    required this.tag,
    required this.title,
    required this.online,
    required this.gradient,
  });
}
