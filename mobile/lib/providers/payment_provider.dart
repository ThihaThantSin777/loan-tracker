import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class PaymentProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Payment> _pendingPayments = [];
  bool _isLoading = false;
  String? _error;

  List<Payment> get pendingPayments => _pendingPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingCount => _pendingPayments.length;

  Future<void> fetchPendingPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.paymentsPending);

      if (response['success']) {
        final List<dynamic> data = response['data']['payments'] ?? [];
        _pendingPayments = data.map((json) => Payment.fromJson(json)).toList();
      } else {
        _error = response['error'] ?? 'Failed to load pending payments';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> acceptPayment(int paymentId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.payments}/$paymentId/accept',
        {},
      );

      if (response['success']) {
        // Remove from pending list
        _pendingPayments.removeWhere((p) => p.id == paymentId);
        notifyListeners();
        return {'success': true, 'message': 'Payment accepted'};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to accept payment',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectPayment(int paymentId, String reason) async {
    try {
      final response = await _api.post(
        '${ApiConfig.payments}/$paymentId/reject',
        {'reason': reason},
      );

      if (response['success']) {
        // Remove from pending list
        _pendingPayments.removeWhere((p) => p.id == paymentId);
        notifyListeners();
        return {'success': true, 'message': 'Payment rejected'};
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to reject payment',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
