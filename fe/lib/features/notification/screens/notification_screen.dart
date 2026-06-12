import 'package:flutter/material.dart';
import '../../../core/constants/constants.dart';
import '../data/notification_repository.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedTabIndex = 0;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<NotificationModel> _getFilteredNotifications() {
    final repo = NotificationRepository();
    switch (_selectedTabIndex) {
      case 0: return repo.getNotifications();
      case 1: return repo.getRequests();
      case 2: return repo.getInfo();
      default: return [];
    }
  }

  void _handleAccept(NotificationModel notif) {
    NotificationRepository().acceptRequest(notif.id);
    _showSnackBar('Đã chấp nhận yêu cầu');
    setState(() {});
  }

  void _handleReject(NotificationModel notif) {
    NotificationRepository().rejectRequest(notif.id);
    _showSnackBar('Đã từ chối yêu cầu');
    setState(() {});
  }

  void _handleMarkAllRead() {
    NotificationRepository().markAllAsRead();
    _showSnackBar('Đã đánh dấu tất cả là đã đọc');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          _buildHeader(isSmallScreen),
          _buildTabs(isSmallScreen),
          Expanded(
            child: _buildNotificationList(isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Thông báo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen ? 17 : 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppColors.white),
            onPressed: _handleMarkAllRead,
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(bool isSmallScreen) {
    final tabs = ['Tất cả', 'Yêu cầu', 'Thông tin'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == _selectedTabIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotificationList(bool isSmallScreen) {
    final notifications = _getFilteredNotifications();

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: isSmallScreen ? 60 : 72, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 1 ? 'Không có yêu cầu nào' : 'Không có thông báo nào',
              style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedTabIndex == 1
                  ? 'Các yêu cầu tham gia sẽ xuất hiện ở đây'
                  : 'Bạn sẽ nhận thông báo khi có hoạt động mới',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20, vertical: isSmallScreen ? 8 : 12),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return NotificationCard(
          notification: notif,
          isSmallScreen: isSmallScreen,
          onAccept: () => _handleAccept(notif),
          onReject: () => _handleReject(notif),
          onTap: () {
            if (!notif.isRead) {
              NotificationRepository().markAsRead(notif.id);
              setState(() {});
            }
          },
        );
      },
    );
  }
}
