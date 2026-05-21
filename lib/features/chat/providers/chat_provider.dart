import 'package:flutter/material.dart';
import '../../../core/services/gemini_service.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _hasError = false;
  String _errorMsg = '';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping  => _isTyping;
  bool get hasError  => _hasError;
  String get errorMsg => _errorMsg;

  ChatProvider() {
    GeminiService.init();
    _messages.add(ChatMessage(
      id: '0',
      text: '🛡️ AEGIS online and connected to Gemini 2.5 Flash.\n\nI\'m monitoring active disaster zones and real-time weather data. How can I help you stay safe?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _hasError = false;
    _messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isTyping = true;
    notifyListeners();

    try {
      final response = await GeminiService.sendMessage(text.trim());
      _messages.add(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _hasError = true;
      _errorMsg = e.toString();
      _messages.add(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: '⚠️ Connection error. Please check your internet and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }

    _isTyping = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    GeminiService.init(); // reset chat session
    _messages.add(ChatMessage(
      id: '0',
      text: '🛡️ AEGIS restarted. How can I help you?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
