import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../config/theme.dart';
import '../payments/submit_payment_screen.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final bool isLender;

  const LoanDetailScreen({
    super.key,
    required this.loan,
    required this.isLender,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final otherUser = isLender ? loan.borrower : loan.lender;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        actions: [
          if (isLender && !loan.isPaid)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remind',
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active),
                      SizedBox(width: 8),
                      Text('Send Reminder'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit_due_date',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Change Due Date'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'remind') {
                  _showReminderDialog(context);
                } else if (value == 'edit_due_date') {
                  _showDueDateDialog(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              color: isLender ? AppTheme.successColor : AppTheme.dangerColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      isLender ? 'You will receive' : 'You need to pay',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatter.format(loan.remainingAmount)} ${loan.currency}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (loan.amount != loan.remainingAmount) ...[
                      const SizedBox(height: 4),
                      Text(
                        'of ${formatter.format(loan.amount)} ${loan.currency}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.person,
                      isLender ? 'Borrower' : 'Lender',
                      otherUser?.name ?? 'Unknown',
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.info_outline,
                      'Status',
                      loan.status.toUpperCase(),
                      valueColor: loan.isPaid
                          ? AppTheme.successColor
                          : loan.isOverdue
                              ? AppTheme.dangerColor
                              : AppTheme.warningColor,
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Due Date',
                      loan.dueDate != null
                          ? DateFormat('MMM d, yyyy').format(loan.dueDate!)
                          : 'No due date',
                      valueColor: loan.isOverdue ? AppTheme.dangerColor : null,
                    ),
                    if (loan.description != null) ...[
                      const Divider(),
                      _buildDetailRow(
                        Icons.description,
                        'Description',
                        loan.description!,
                      ),
                    ],
                    const Divider(),
                    _buildDetailRow(
                      Icons.access_time,
                      'Created',
                      DateFormat('MMM d, yyyy').format(loan.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payments History
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (loan.payments == null || loan.payments!.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No payments yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              )
            else
              ...loan.payments!.map((payment) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: payment.isAccepted
                          ? AppTheme.successColor.withOpacity(0.2)
                          : payment.isRejected
                              ? AppTheme.dangerColor.withOpacity(0.2)
                              : AppTheme.warningColor.withOpacity(0.2),
                      child: Icon(
                        payment.isCash ? Icons.money : Icons.smartphone,
                        color: payment.isAccepted
                            ? AppTheme.successColor
                            : payment.isRejected
                                ? AppTheme.dangerColor
                                : AppTheme.warningColor,
                      ),
                    ),
                    title: Text(
                      '${formatter.format(payment.amount)} ${loan.currency}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${payment.paymentMethod == 'cash' ? 'Cash' : 'E-Wallet'} - ${DateFormat('MMM d').format(payment.createdAt)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: payment.isAccepted
                            ? AppTheme.successColor.withOpacity(0.1)
                            : payment.isRejected
                                ? AppTheme.dangerColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: payment.isAccepted
                              ? AppTheme.successColor
                              : payment.isRejected
                                  ? AppTheme.dangerColor
                                  : AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      bottomNavigationBar: !isLender && !loan.isPaid
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubmitPaymentScreen(loan: loan),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Make Payment'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderDialog(BuildContext context) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Reminder'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            hintText: 'Custom message (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final loanProvider =
                  Provider.of<LoanProvider>(context, listen: false);
              await loanProvider.sendReminder(
                loan.id,
                message: messageController.text.isEmpty
                    ? null
                    : messageController.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder sent!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showDueDateDialog(BuildContext context) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Due Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Set new date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: loan.dueDate ?? DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (context.mounted) {
                  Navigator.pop(context, picked);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Remove due date'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final loanProvider = Provider.of<LoanProvider>(context, listen: false);

      if (result == 'remove') {
        await loanProvider.updateLoan(loanId: loan.id, removeDueDate: true);
      } else if (result is DateTime) {
        await loanProvider.updateLoan(loanId: loan.id, dueDate: result);
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
