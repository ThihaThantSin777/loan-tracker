import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class LoanProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Loan> _loansGiven = [];
  List<Loan> _loansTaken = [];
  bool _isLoading = false;
  String? _error;

  List<Loan> get loansGiven => _loansGiven;
  List<Loan> get loansTaken => _loansTaken;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Loan> get allLoans => [..._loansGiven, ..._loansTaken];
  List<Loan> get pendingLoansGiven => _loansGiven.where((l) => !l.isPaid).toList();
  List<Loan> get pendingLoansTaken => _loansTaken.where((l) => !l.isPaid).toList();

  Future<void> fetchLoans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConfig.loans);

      if (response['success']) {
        _loansGiven = (response['data']['loans_given'] as List)
            .map((l) => Loan.fromJson(l))
            .toList();
        _loansTaken = (response['data']['loans_taken'] as List)
            .map((l) => Loan.fromJson(l))
            .toList();
      } else {
        _error = response['error'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createLoan({
    required int borrowerId,
    required double amount,
    String? description,
    DateTime? dueDate,
    String currency = 'MMK',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.post(ApiConfig.loans, {
        'borrower_id': borrowerId,
        'amount': amount,
        'currency': currency,
        if (description != null) 'description': description,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T')[0],
      });

      if (response['success']) {
        await fetchLoans();
        return true;
      } else {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLoan({
    required int loanId,
    String? description,
    DateTime? dueDate,
    bool removeDueDate = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (description != null) data['description'] = description;
      if (removeDueDate) {
        data['due_date'] = null;
      } else if (dueDate != null) {
        data['due_date'] = dueDate.toIso8601String().split('T')[0];
      }

      final response = await _api.put('${ApiConfig.loans}/$loanId', data);

      if (response['success']) {
        await fetchLoans();
        return true;
      } else {
        _error = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteLoan(int loanId) async {
    try {
      final response = await _api.delete('${ApiConfig.loans}/$loanId');
      if (response['success']) {
        await fetchLoans();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendReminder(int loanId, {String? message}) async {
    try {
      final response = await _api.post(
        '${ApiConfig.loans}/$loanId/remind',
        {if (message != null) 'message': message},
      );
      return response['success'];
    } catch (e) {
      return false;
    }
  }
}
