import 'package:intl/intl.dart';

/// Format ngày giờ cho chat message hiển thị.
String formatMessageTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes}p';
  if (diff.inDays < 1) return DateFormat('HH:mm').format(dt);
  if (diff.inDays < 7) return DateFormat('EEE HH:mm').format(dt);
  return DateFormat('dd/MM/yy').format(dt);
}

/// Format ngày sinh hoặc ngày đăng ký.
String formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

/// Format thời gian tương đối cho notification.
String formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM/yyyy').format(dt);
}

/// Truncate string giới hạn độ dài.
String truncate(String text, int maxLen) {
  if (text.length <= maxLen) return text;
  return '${text.substring(0, maxLen)}...';
}
