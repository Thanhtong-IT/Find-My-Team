import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../../home/screens/home_screen.dart';
import '../../explore/screens/explore_screen.dart';
import '../../team/screens/team_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/screens/friends_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    TeamScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: AppColors.divider, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppSizes.bottomNavHeight,
            child: Row(
              children: [
                _buildNavItem(index: 0, icon: Icons.home_rounded, label: 'Trang chủ'),
                _buildNavItem(index: 1, icon: Icons.explore_rounded, label: 'Khám phá'),
                _buildNavItem(index: 2, icon: Icons.groups_rounded, label: 'Nhóm'),
                _buildNavItem(index: 3, icon: Icons.people_rounded, label: 'Bạn bè'),
                _buildNavItem(index: 4, icon: Icons.person_rounded, label: 'Hồ sơ'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final isSelected = _currentIndex == index;
    return SizedBox(
      width: MediaQuery.of(context).size.width / 5,
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: isSelected ? AppColors.primary : AppColors.textLight),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
