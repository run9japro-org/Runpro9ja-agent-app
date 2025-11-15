import 'package:flutter/material.dart';
import '../Auth/auth_services.dart';
import '../Auth/withdrawal_service.dart';
import 'add_account_screen.dart';

class WithdrawScreen extends StatefulWidget {
  final String userToken;
  final double totalEarnings; // Add this parameter

  const WithdrawScreen({
    Key? key,
    required this.userToken,
    required this.totalEarnings, // Make it required
  }) : super(key: key);

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountController = TextEditingController();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final AuthService _authService = AuthService();

  double walletBalance = 0.0;
  bool _isLoading = false;
  bool _isFetchingBalance = true;
  String? selectedBankCode;
  String? selectedAccountNumber;
  String? selectedBankName;
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
    _initializeBalance(); // Use the new method
  }

  Future<void> _loadToken() async {
    final token = await _authService.getToken();
    setState(() {
      _userToken = token;
    });
  }

  Future<void> _initializeBalance() async {
    try {
      setState(() => _isFetchingBalance = true);

      // Use the passed totalEarnings as the wallet balance
      // You can also fetch from API here if needed, but use totalEarnings as fallback
      setState(() {
        walletBalance = widget.totalEarnings;
        _isFetchingBalance = false;
      });

      // Optional: If you want to fetch actual wallet balance from API instead
      // await _fetchWalletBalanceFromAPI();

    } catch (e) {
      // Fallback to passed totalEarnings if API fails
      setState(() {
        walletBalance = widget.totalEarnings;
        _isFetchingBalance = false;
      });
      print('Error initializing balance: $e');
    }
  }

  // Optional: If you want to fetch from API instead of using passed value
  Future<void> _fetchWalletBalanceFromAPI() async {
    try {
      // TODO: Replace with actual API call to get wallet balance
      // For now, using the passed totalEarnings
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        walletBalance = widget.totalEarnings;
      });
    } catch (e) {
      // Fallback to passed totalEarnings
      setState(() {
        walletBalance = widget.totalEarnings;
      });
      print('Error fetching wallet balance: $e');
    }
  }

  // Rest of your existing methods remain the same...
  Future<void> _requestWithdrawal() async {
    if (!_validateForm()) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Enter a valid amount');
      return;
    }

    if (amount > walletBalance) {
      _showErrorSnackBar('Insufficient balance');
      return;
    }

    if (amount < 100) {
      _showErrorSnackBar('Minimum withdrawal amount is ₦100');
      return;
    }

    final confirmed = await _showConfirmationDialog(amount);
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      final tokenToUse = _userToken ?? widget.userToken.replaceAll('Bearer ', '');

      final response = await _withdrawalService.requestWithdrawal(
        token: tokenToUse,
        amount: amount,
        bankCode: selectedBankCode!,
        accountNumber: selectedAccountNumber!,
      );

      _showSuccessSnackBar(response['message'] ?? 'Withdrawal requested successfully!');

      _amountController.clear();

      // Update balance after withdrawal
      setState(() {
        walletBalance -= amount;
      });

    } catch (e) {
      _showErrorSnackBar('Withdrawal failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ... rest of your existing methods (validateForm, showConfirmationDialog, etc.)
  bool _validateForm() {
    if (_amountController.text.isEmpty) {
      _showErrorSnackBar('Please enter amount');
      return false;
    }

    if (selectedBankCode == null || selectedAccountNumber == null) {
      _showErrorSnackBar('Please select a bank account');
      return false;
    }

    return true;
  }

  Future<bool> _showConfirmationDialog(double amount) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Withdrawal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: ₦${amount.toStringAsFixed(2)}'),
            Text('Bank: $selectedBankName'),
            Text('Account: $selectedAccountNumber'),
            const SizedBox(height: 8),
            Text(
              'Processing time: 1-3 business days',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBalanceSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Available Balance",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            _isFetchingBalance
                ? const CircularProgressIndicator()
                : Text(
              "₦${walletBalance.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your completed services',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTile() {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: _navigateToAddAccount,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAccountNumber == null
                          ? "Add Bank Account"
                          : "Withdraw to",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (selectedAccountNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$selectedBankName • $selectedAccountNumber',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddAccount() async {
    final token = await _authService.getToken();

    if (token == null) {
      _showErrorSnackBar('Authentication error. Please login again.');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddAccountScreen(userToken: token),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        selectedBankCode = result['bankCode'];
        selectedAccountNumber = result['accountNumber'];
        selectedBankName = result['bankName'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Withdraw Funds"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceSection(),
            const SizedBox(height: 20),
            _buildAccountTile(),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                hintText: '₦0.00',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text(
              'Minimum withdrawal: ₦100',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Request Withdrawal",
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