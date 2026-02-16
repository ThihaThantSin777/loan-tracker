import 'user.dart';
import 'loan.dart';

class Payment {
  final int id;
  final int loanId;
  final int payerId;
  final double amount;
  final String paymentMethod;
  final String? screenshotUrl;
  final String status;
  final String? rejectedReason;
  final DateTime? verifiedAt;
  final int? verifiedBy;
  final DateTime createdAt;
  final User? payer;
  final Loan? loan;

  Payment({
    required this.id,
    required this.loanId,
    required this.payerId,
    required this.amount,
    required this.paymentMethod,
    this.screenshotUrl,
    required this.status,
    this.rejectedReason,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    this.payer,
    this.loan,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      loanId: json['loan_id'],
      payerId: json['payer_id'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'],
      screenshotUrl: json['screenshot_url'],
      status: json['status'],
      rejectedReason: json['rejected_reason'],
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'])
          : null,
      verifiedBy: json['verified_by'],
      createdAt: DateTime.parse(json['created_at']),
      payer: json['payer'] != null ? User.fromJson(json['payer']) : null,
      loan: json['loan'] != null ? Loan.fromJson(json['loan']) : null,
    );
  }

  bool get isCash => paymentMethod == 'cash';
  bool get isEWallet => paymentMethod == 'e_wallet';
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}
