class ApiConfig {
  // Change this to your server URL
  // For Android emulator use: http://10.0.2.2:8000/api
  // For iOS simulator use: http://127.0.0.1:8000/api
  // For real device use your computer's IP: http://192.168.x.x:8000/api
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String updateFcmToken = '/auth/fcm-token';

  static const String friends = '/friends';
  static const String friendsPending = '/friends/pending';
  static const String friendsSearch = '/friends/search';
  static const String friendsRequest = '/friends/request';

  static const String loans = '/loans';

  static const String payments = '/payments';
  static const String paymentsPending = '/payments/pending';

  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';

  static const String analyticsSummary = '/analytics/summary';
  static const String analyticsByFriend = '/analytics/by-friend';
  static const String analyticsMonthly = '/analytics/monthly';
  static const String analyticsUpcomingDue = '/analytics/upcoming-due';
}
