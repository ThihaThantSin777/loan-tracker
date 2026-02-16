import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LoanNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _hasMore = true;

  List<LoanNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('${ApiConfig.notifications}?page=$_currentPage');

      final List<dynamic> data = response['data'] ?? [];
      final newNotifications = data.map((json) => LoanNotification.fromJson(json)).toList();

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      _currentPage = response['current_page'] ?? 1;
      _lastPage = response['last_page'] ?? 1;
      _hasMore = _currentPage < _lastPage;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _api.get(ApiConfig.notificationsUnreadCount);
      _unreadCount = response['unread_count'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      await _api.put('${ApiConfig.notifications}/$notificationId/read', {});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        if (!notification.isRead) {
          _notifications[index] = LoanNotification(
            id: notification.id,
            userId: notification.userId,
            senderId: notification.senderId,
            loanId: notification.loanId,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            isRead: true,
            createdAt: notification.createdAt,
            sender: notification.sender,
            loan: notification.loan,
          );
          _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _api.put('${ApiConfig.notifications}/read-all', {});

      // Update local state
      _notifications = _notifications.map((n) => LoanNotification(
        id: n.id,
        userId: n.userId,
        senderId: n.senderId,
        loanId: n.loanId,
        type: n.type,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
        sender: n.sender,
        loan: n.loan,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      await _api.delete('${ApiConfig.notifications}/$notificationId');

      // Update local state
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
      }
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
