import 'user.dart';
import 'payment.dart';

class Loan {
  final int id;
  final int lenderId;
  final int borrowerId;
  final double amount;
  final String currency;
  final String? description;
  final DateTime? dueDate;
  final String status;
  final double remainingAmount;
  final DateTime createdAt;
  final User? lender;
  final User? borrower;
  final List<Payment>? payments;

  Loan({
    required this.id,
    required this.lenderId,
    required this.borrowerId,
    required this.amount,
    required this.currency,
    this.description,
    this.dueDate,
    required this.status,
    required this.remainingAmount,
    required this.createdAt,
    this.lender,
    this.borrower,
    this.payments,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      lenderId: json['lender_id'],
      borrowerId: json['borrower_id'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'] ?? 'MMK',
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      status: json['status'],
      remainingAmount: double.parse(json['remaining_amount'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      lender: json['lender'] != null ? User.fromJson(json['lender']) : null,
      borrower: json['borrower'] != null ? User.fromJson(json['borrower']) : null,
      payments: json['payments'] != null
          ? (json['payments'] as List).map((p) => Payment.fromJson(p)).toList()
          : null,
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isPartial => status == 'partial';
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid;
  bool get isDueSoon => dueDate != null &&
      dueDate!.isAfter(DateTime.now()) &&
      dueDate!.isBefore(DateTime.now().add(const Duration(days: 3))) &&
      !isPaid;
}
