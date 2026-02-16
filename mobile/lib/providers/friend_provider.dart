import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/friendship.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class FriendProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<User> _friends = [];
  List<Friendship> _receivedRequests = [];
  List<Friendship> _sentRequests = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<User> get friends => _friends;
  List<Friendship> get receivedRequests => _receivedRequests;
  List<Friendship> get sentRequests => _sentRequests;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.friends);

      if (response['success']) {
        _friends = (response['data']['friends'] as List)
            .map((f) => User.fromJson(f))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPendingRequests() async {
    try {
      final response = await _api.get(ApiConfig.friendsPending);

      if (response['success']) {
        _receivedRequests = (response['data']['received'] as List)
            .map((f) => Friendship.fromJson(f))
            .toList();
        _sentRequests = (response['data']['sent'] as List)
            .map((f) => Friendship.fromJson(f))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      final response = await _api.get('${ApiConfig.friendsSearch}?query=$query');

      if (response['success']) {
        _searchResults = (response['data']['users'] as List)
            .map((u) => User.fromJson(u))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> sendFriendRequest({String? email, String? phone}) async {
    try {
      final response = await _api.post(ApiConfig.friendsRequest, {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });

      if (response['success']) {
        await fetchPendingRequests();
        return true;
      }
      _error = response['error'];
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> acceptRequest(int friendshipId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.friends}/$friendshipId/accept',
        {},
      );

      if (response['success']) {
        await fetchFriends();
        await fetchPendingRequests();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectRequest(int friendshipId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.friends}/$friendshipId/reject',
        {},
      );

      if (response['success']) {
        await fetchPendingRequests();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(int friendId) async {
    try {
      final response = await _api.delete('${ApiConfig.friends}/$friendId');

      if (response['success']) {
        await fetchFriends();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
