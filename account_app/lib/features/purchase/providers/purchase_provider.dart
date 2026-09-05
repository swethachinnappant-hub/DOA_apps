import 'package:flutter/material.dart';

class PurchaseProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      
      _purchases = [
        {'billNo': 'BILL/24-25/001', 'supplier': 'Vendor A', 'amount': 18500, 'status': 'Paid', 'date': '11/07/2025'},
        {'billNo': 'BILL/24-25/002', 'supplier': 'Vendor B', 'amount': 32000, 'status': 'Pending', 'date': '10/07/2025'},
        {'billNo': 'BILL/24-25/003', 'supplier': 'Vendor C', 'amount': 15750, 'status': 'Paid', 'date': '09/07/2025'},
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchase(Map<String, dynamic> purchase) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _purchases.insert(0, purchase);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
