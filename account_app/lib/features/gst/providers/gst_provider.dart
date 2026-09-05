import 'package:flutter/material.dart';

class GstProvider extends ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic> _gstSummary = {};

  bool get isLoading => _isLoading;
  Map<String, dynamic> get gstSummary => _gstSummary;

  Future<void> loadGstData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _gstSummary = {
      'outputCgst': 125000,
      'outputSgst': 125000,
      'inputCgst': 85000,
      'inputSgst': 85000,
      'netPayable': 80000,
    };

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fileGstReturn(String returnType) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();
  }
}
