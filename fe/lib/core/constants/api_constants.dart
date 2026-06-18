class ApiConstants {
  ApiConstants._();

  // TODO: Đổi sang URL backend thực tế khi deploy lên server
  //
  // Lưu ý: Khi backend chạy trên máy khác (VD: Docker container trên server),
  // hãy thay đổi giá trị này thành IP/domain của server.
  //
  // 10.0.2.2 chỉ hoạt động trên Android emulator. Trên Chrome/Web/Desktop,
  // backend phải chạy trên localhost:8080.
  static const String baseUrl = 'http://localhost:8080/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/users/me';

  // User & Game endpoints
  static const String games = '/games';
  static const String popularGames = '/games/popular';
  static const String userProfile = '/users/me/profile';
  static const String userGameProfiles = '/users/me/game-profiles';
  static const String addGameProfile = '/users/me/game-profile';

  // Team endpoints
  static const String teams = '/teams';
  static const String myTeam = '/teams/my';
  static const String openTeams = '/teams/open';
  static const String recruitingTeams = '/teams/recruiting';
  static const String myJoinRequests = '/teams/my/join-requests';

  // Community endpoints
  static const String communities = '/communities';

  // Explore endpoints
  static const String explore = '/explore/search';
  static const String onlinePlayers = '/players/online';

  // Swipe & Match endpoints
  static const String swipes = '/swipes';
  static const String matches = '/matches';

  // Invitation endpoints
  static const String invitations = '/invitations';
  static const String invitationsReceived = '/invitations/received';
  static const String invitationsSent = '/invitations/sent';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String markAllRead = '/notifications/read-all';
}
