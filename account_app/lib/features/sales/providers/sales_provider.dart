import 'package:flutter/material.dart';

class SalesProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      _sales = [
        {'invoiceNo': 'INV/24-25/001', 'customer': 'Client A', 'amount': 25000, 'status': 'Paid', 'date': '11/07/2025'},
        {'invoiceNo': 'INV/24-25/002', 'customer': 'Client B', 'amount': 18500, 'status': 'Pending', 'date': '10/07/2025'},
        {'invoiceNo': 'INV/24-25/003', 'customer': 'Client C', 'amount': 32000, 'status': 'Paid', 'date': '09/07/2025'},
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSale(Map<String, dynamic> sale) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      _sales.insert(0, sale);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSale(String id, Map<String, dynamic> sale) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      final index = _sales.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _sales[index] = sale;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(String id) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _sales.removeWhere((s) => s['id'] == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
