import 'package:flutter/material.dart';

class BankingProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bankAccounts = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get bankAccounts => _bankAccounts;
  List<Map<String, dynamic>> get transactions => _transactions;
  bool get isLoading => _isLoading;

  double get totalBalance => _bankAccounts.fold(0, (sum, acc) => sum + (acc['balance'] as double));

  Future<void> loadBankingData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _bankAccounts = [
      {'name': 'SBI Current A/c', 'balance': 245680.00, 'color': 0xFF1E3A5F},
      {'name': 'HDFC Bank A/c', 'balance': 125430.00, 'color': 0xFF2196F3},
      {'name': 'ICICI Bank A/c', 'balance': 75890.00, 'color': 0xFF4CAF50},
      {'name': 'Axis Bank A/c', 'balance': 110250.00, 'color': 0xFFFF9800},
    ];

    _transactions = [
      {'type': 'Cheque Issue', 'party': 'Vendor A', 'amount': 15000, 'date': '11/07/2025', 'status': 'Completed'},
      {'type': 'Bank Transfer', 'party': 'Client B', 'amount': 25000, 'date': '10/07/2025', 'status': 'Completed'},
      {'type': 'Cheque Deposit', 'party': 'Client C', 'amount': 32000, 'date': '09/07/2025', 'status': 'Pending'},
    ];

    _isLoading = false;
    notifyListeners();
  }
}
