import 'package:flutter/material.dart';

class ReportsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _selectedReport;

  bool get isLoading => _isLoading;
  String? get selectedReport => _selectedReport;

  void selectReport(String report) {
    _selectedReport = report;
    notifyListeners();
  }

  Future<Map<String, dynamic>> generateReport(String type, DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();

    return {
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'data': [],
    };
  }
}
