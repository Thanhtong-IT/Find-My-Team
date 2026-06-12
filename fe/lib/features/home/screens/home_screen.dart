import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../notification/screens/notification_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                    SizedBox(height: 20),
                    _HomeSearchBar(),
                    SizedBox(height: 24),
                    _FeaturedActionCard(),
                    SizedBox(height: 24),
                    _SectionTitle(title: 'Game phổ biến'),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              const _PopularGamesSection(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    SizedBox(height: 24),
                    _SectionTitle(title: 'Đội đang tuyển'),
                    SizedBox(height: 12),
                  ],
                ),
              ),
              const _RecruitingTeamsSection(),
              const SizedBox(height: 24),
            ],
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

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: AppColors.textLight, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text('Tìm game, đội hoặc cộng đồng...', style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          ),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _FeaturedActionCard extends StatelessWidget {
  const _FeaturedActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tìm đồng đội phù hợp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
                const SizedBox(height: 6),
                const Text('Tạo yêu cầu tìm team theo game, rank và thời gian chơi của bạn.', style: TextStyle(fontSize: 13, color: AppColors.white)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 140, height: 40,
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Tạo yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.groups_rounded, size: 40, color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const Text('Xem tất cả', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PopularGamesSection extends StatelessWidget {
  const _PopularGamesSection();

  static const _games = [
    {'name': 'Liên Quân', 'teams': '24 đội', 'icon': Icons.sports_esports_rounded},
    {'name': 'Valorant', 'teams': '18 đội', 'icon': Icons.sports_esports_rounded},
    {'name': 'Liên Minh', 'teams': '32 đội', 'icon': Icons.sports_esports_rounded},
    {'name': 'PUBG Mobile', 'teams': '15 đội', 'icon': Icons.sports_esports_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _games.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = _games[index];
          return _PopularGameCard(name: game['name'] as String, teams: game['teams'] as String, icon: game['icon'] as IconData);
        },
      ),
    );
  }
}

class _PopularGameCard extends StatelessWidget {
  final String name;
  final String teams;
  final IconData icon;

  const _PopularGameCard({required this.name, required this.teams, required this.icon});

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(teams, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RecruitingTeamsSection extends StatelessWidget {
  const _RecruitingTeamsSection();

  static final _teams = [
    {'name': 'Blue Wolves', 'game': 'Liên Quân Mobile', 'rank': 'Kim cương trở lên', 'need': 'Cần 2 người'},
    {'name': 'Valorant VN Squad', 'game': 'Valorant', 'rank': 'Gold - Platinum', 'need': 'Cần 1 Duelist'},
    {'name': 'PUBG Chill Team', 'game': 'PUBG Mobile', 'rank': 'Không yêu cầu', 'need': 'Cần 3 người'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: _teams.map((team) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: _RecruitingTeamCard(name: team['name'] as String, game: team['game'] as String, rank: team['rank'] as String, need: team['need'] as String))).toList());
  }
}

class _RecruitingTeamCard extends StatelessWidget {
  final String name;
  final String game;
  final String rank;
  final String need;

  const _RecruitingTeamCard({required this.name, required this.game, required this.rank, required this.need});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: AppColors.divider.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(game, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(need, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoChip(label: rank, icon: Icons.emoji_events_outlined),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 40,
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang xem chi tiết: $name'), backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating),
              ),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
