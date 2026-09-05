import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  double _totalSales = 0;
  double _totalPurchases = 0;
  double _bankBalance = 0;
  double _cashInHand = 0;
  double _debtors = 0;
  double _creditors = 0;
  int _todaysEntries = 0;
  int _pendingUploads = 0;

  double get totalSales => _totalSales;
  double get totalPurchases => _totalPurchases;
  double get bankBalance => _bankBalance;
  double get cashInHand => _cashInHand;
  double get debtors => _debtors;
  double get creditors => _creditors;
  int get todaysEntries => _todaysEntries;
  int get pendingUploads => _pendingUploads;

  Future<void> loadDashboardData() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    _totalSales = 1245000;
    _totalPurchases = 875000;
    _bankBalance = 215000;
    _cashInHand = 135000;
    _debtors = 325000;
    _creditors = 245000;
    _todaysEntries = 25;
    _pendingUploads = 18;
    
    notifyListeners();
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }
}
