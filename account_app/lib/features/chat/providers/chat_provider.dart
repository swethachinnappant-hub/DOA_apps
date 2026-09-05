import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get chats => _chats;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _chats = [
      {'id': '1', 'name': 'Admin', 'lastMessage': 'Please check the invoice', 'time': '11:20 AM', 'unread': 2},
      {'id': '2', 'name': 'Client A', 'lastMessage': 'Payment received', 'time': '10:15 AM', 'unread': 0},
      {'id': '3', 'name': 'Vendor B', 'lastMessage': 'Please send the bill', 'time': 'Yesterday', 'unread': 1},
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages(String chatId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _messages = [
      {'text': 'Please check the invoice from Client A', 'isMe': false, 'time': '11:20 AM'},
      {'text': 'Yes, checking now', 'isMe': true, 'time': '11:25 AM'},
      {'text': 'Payment received for INV-001', 'isMe': false, 'time': '11:30 AM'},
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String text) async {
    _messages.add({
      'text': text,
      'isMe': true,
      'time': DateTime.now().toString(),
    });
    notifyListeners();
  }
}
