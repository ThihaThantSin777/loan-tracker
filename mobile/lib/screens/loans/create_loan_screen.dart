import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/loan_provider.dart';
import '../../providers/friend_provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';

class CreateLoanScreen extends StatefulWidget {
  const CreateLoanScreen({super.key});

  @override
  State<CreateLoanScreen> createState() => _CreateLoanScreenState();
}

class _CreateLoanScreenState extends State<CreateLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  User? _selectedFriend;
  DateTime? _dueDate;
  bool _hasDueDate = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _createLoan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFriend == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a friend'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final loanProvider = Provider.of<LoanProvider>(context, listen: false);
    final success = await loanProvider.createLoan(
      borrowerId: _selectedFriend!.id,
      amount: double.parse(_amountController.text),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      dueDate: _hasDueDate ? _dueDate : null,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan created successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loanProvider.error ?? 'Failed to create loan'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Loan'),
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Select Friend
                  const Text(
                    'Select Friend (Borrower)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<User>(
                    value: _selectedFriend,
                    decoration: const InputDecoration(
                      hintText: 'Choose a friend',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: friendProvider.friends.map((friend) {
                      return DropdownMenuItem<User>(
                        value: friend,
                        child: Text(friend.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFriend = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a friend';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  const Text(
                    'Amount (MMK)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Lunch, Movie tickets',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Due Date Toggle
                  SwitchListTile(
                    title: const Text('Set Due Date'),
                    subtitle: const Text('Enable to set a payment deadline'),
                    value: _hasDueDate,
                    onChanged: (value) {
                      setState(() {
                        _hasDueDate = value;
                        if (value && _dueDate == null) {
                          _dueDate = DateTime.now().add(const Duration(days: 7));
                        }
                      });
                    },
                  ),

                  // Due Date Picker
                  if (_hasDueDate) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDueDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _dueDate != null
                              ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                              : 'Select date',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Create Button
                  Consumer<LoanProvider>(
                    builder: (context, loanProvider, _) {
                      return ElevatedButton(
                        onPressed: loanProvider.isLoading ? null : _createLoan,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: loanProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Create Loan'),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
