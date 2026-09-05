import 'package:flutter/material.dart';

class ClientProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get clients => _clients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadClients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      _clients = [
        {'name': 'ABC Traders', 'gstin': '06AAACR1234F1Z5', 'balance': 325000, 'status': 'Active'},
        {'name': 'XYZ Enterprises', 'gstin': '06BBCCE1234F1Z5', 'balance': 125000, 'status': 'Active'},
        {'name': 'Suresh & Co.', 'gstin': '06CCLRE1234F1Z5', 'balance': 65000, 'status': 'Active'},
        {'name': 'Mahesh Traders', 'gstin': '06DMDRE1234F1Z5', 'balance': 110000, 'status': 'Inactive'},
        {'name': 'Pooja Enterprises', 'gstin': '06EEPUR1234F1Z5', 'balance': 50500, 'status': 'Active'},
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addClient(Map<String, dynamic> client) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _clients.insert(0, client);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
