import 'user.dart';
import 'loan.dart';

class LoanNotification {
  final int id;
  final int userId;
  final int? senderId;
  final int? loanId;
  final String type;
  final String title;
  final String? message;
  final bool isRead;
  final DateTime createdAt;
  final User? sender;
  final Loan? loan;

  LoanNotification({
    required this.id,
    required this.userId,
    this.senderId,
    this.loanId,
    required this.type,
    required this.title,
    this.message,
    required this.isRead,
    required this.createdAt,
    this.sender,
    this.loan,
  });

  factory LoanNotification.fromJson(Map<String, dynamic> json) {
    return LoanNotification(
      id: json['id'],
      userId: json['user_id'],
      senderId: json['sender_id'],
      loanId: json['loan_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      loan: json['loan'] != null ? Loan.fromJson(json['loan']) : null,
    );
  }
}
