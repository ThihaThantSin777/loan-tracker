import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/loan_provider.dart';
import '../../providers/friend_provider.dart';
import '../../config/theme.dart';
import '../../models/loan.dart';
import '../loans/create_loan_screen.dart';
import '../loans/loan_detail_screen.dart';

class LoansTab extends StatefulWidget {
  const LoansTab({super.key});

  @override
  State<LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<LoansTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Given'),
            Tab(text: 'Taken'),
          ],
        ),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, loanProvider, _) {
          if (loanProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLoanList(loanProvider.loansGiven, isLender: true),
              _buildLoanList(loanProvider.loansTaken, isLender: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateLoanScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoanList(List<Loan> loans, {required bool isLender}) {
    final formatter = NumberFormat('#,###');

    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isLender ? 'No loans given yet' : 'No loans taken yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<LoanProvider>(context, listen: false).fetchLoans(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          final otherUser = isLender ? loan.borrower : loan.lender;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoanDetailScreen(loan: loan, isLender: isLender),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            otherUser?.name.substring(0, 1).toUpperCase() ?? '?',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUser?.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (loan.description != null)
                                Text(
                                  loan.description!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(loan),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remaining',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${formatter.format(loan.remainingAmount)} ${loan.currency}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isLender
                                    ? AppTheme.successColor
                                    : AppTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                        if (loan.dueDate != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, y').format(loan.dueDate!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: loan.isOverdue
                                      ? AppTheme.dangerColor
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'No due date',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(Loan loan) {
    Color color;
    String text;

    if (loan.isPaid) {
      color = AppTheme.successColor;
      text = 'PAID';
    } else if (loan.isOverdue) {
      color = AppTheme.dangerColor;
      text = 'OVERDUE';
    } else if (loan.isPartial) {
      color = AppTheme.warningColor;
      text = 'PARTIAL';
    } else {
      color = AppTheme.primaryColor;
      text = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
