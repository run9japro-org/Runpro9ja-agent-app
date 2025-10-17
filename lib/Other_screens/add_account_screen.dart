import 'package:flutter/material.dart';
import 'package:runpro9ja_agent/Auth/withdrawal_service.dart';
import 'dart:convert';
import '../Auth/auth_services.dart'; // Add this import

class AddAccountScreen extends StatefulWidget {
  final String userToken;

  const AddAccountScreen({Key? key, required this.userToken}) : super(key: key);

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  String? selectedBank;
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();

  final Map<String, String> banks = {
    'Access Bank': '044',
    'GTBank': '058',
    'Zenith Bank': '057',
    'UBA': '033',
    'First Bank': '011',
    'Ecobank': '050',
    'Fidelity Bank': '070',
    'Stanbic IBTC': '039',
    'Union Bank': '032',
  };

  bool isLoading = false;
  bool isVerifyingAccount = false;
  final WithdrawalService _bankService = WithdrawalService(); // Add this

  @override
  void initState() {
    super.initState();
    accountNumberController.addListener(_verifyAccountNumber);
    _checkAuthentication(); // Check auth on init
  }

  void _checkAuthentication() async {
    final token = await AuthService().getToken();
    print('🔐 Current Token: $token');
    print('🔐 Passed Token: ${widget.userToken}');
  }

  @override
  void dispose() {
    accountNumberController.removeListener(_verifyAccountNumber);
    accountNumberController.dispose();
    accountNameController.dispose();
    super.dispose();
  }

  void _verifyAccountNumber() async {
    if (selectedBank == null || accountNumberController.text.length < 10) {
      return;
    }

    if (accountNumberController.text.length == 10) {
      setState(() => isVerifyingAccount = true);

      try {
        // TODO: Implement actual account verification API
        await Future.delayed(const Duration(seconds: 1));

        // For now, simulate verification
        setState(() {
          accountNameController.text = 'John Doe'; // Simulated name
        });
      } catch (e) {
        accountNameController.text = '';
        _showErrorSnackBar('Account verification failed');
      } finally {
        setState(() => isVerifyingAccount = false);
      }
    }
  }

  Future<void> addBankAccount() async {
    if (!_validateForm()) return;

    setState(() => isLoading = true);

    try {
      final bankData = {
        'bankName': selectedBank,
        'bankCode': banks[selectedBank],
        'accountNumber': accountNumberController.text,
        'accountName': accountNameController.text,
      };

      print('🔄 Adding bank account with data: $bankData');

      final result = await _bankService.addBankAccount(bankData);

      if (result['success'] == true) {
        _showSuccessAndReturn(result['data']);
      } else {
        _showErrorSnackBar(result['error'] ?? 'Failed to add bank account');
      }
    } catch (e) {
      print('❌ Exception in addBankAccount: $e');
      _showErrorSnackBar('Unexpected error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _validateForm() {
    if (selectedBank == null) {
      _showErrorSnackBar('Please select a bank');
      return false;
    }

    if (accountNumberController.text.isEmpty) {
      _showErrorSnackBar('Please enter account number');
      return false;
    }

    if (accountNumberController.text.length != 10) {
      _showErrorSnackBar('Account number must be 10 digits');
      return false;
    }

    if (accountNameController.text.isEmpty) {
      _showErrorSnackBar('Account name is required');
      return false;
    }

    return true;
  }

  void _showSuccessAndReturn(Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Bank account added successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Return to previous screen with bank details
    if (mounted) {
      Navigator.pop(context, {
        'bankCode': banks[selectedBank],
        'accountNumber': accountNumberController.text,
        'bankName': selectedBank,
        'accountName': accountNameController.text,
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your bank account details for withdrawals',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Bank Selection
            DropdownButtonFormField<String>(
              value: selectedBank,
              decoration: InputDecoration(
                labelText: 'Select Bank',
                hintText: 'Choose your bank',
                prefixIcon: const Icon(Icons.account_balance, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: banks.keys.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedBank = value),
            ),
            const SizedBox(height: 16),

            // Account Number
            TextField(
              controller: accountNumberController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Account Number',
                hintText: '10-digit account number',
                prefixIcon: const Icon(Icons.credit_card, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: isVerifyingAccount
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Account Name
            TextField(
              controller: accountNameController,
              decoration: InputDecoration(
                labelText: 'Account Name',
                hintText: 'Account holder name',
                prefixIcon: const Icon(Icons.person, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              readOnly: isVerifyingAccount,
            ),

            const Spacer(),

            // Add Account Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addBankAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : const Text(
                  'Add Bank Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}