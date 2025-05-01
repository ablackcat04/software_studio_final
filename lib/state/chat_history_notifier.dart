import 'package:flutter/material.dart';
import 'package:software_studio_final/models/chat_history.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  final List<ChatHistory> _chatHistory = [];
  ChatHistory _currentChatHistory = ChatHistory(
    name: 'Test',
    createdAt: DateTime.now(),
    messages: [],
  );

  ChatHistory get currentChatHistory => _currentChatHistory;
  List<ChatHistory> get chatHistory => _chatHistory;

  ChatHistoryNotifier() {
    newChat();
    addMessage(ChatMessage(isAI: false, content: 'Old message 1', images: []));
    addMessage(
      ChatMessage(
        isAI: true,
        content: '',
        images: ['assets/images/image1.jpg', 'assets/images/image2.jpg'],
      ),
    );
    newChat();
    addMessage(ChatMessage(isAI: false, content: 'Another chat', images: []));
  }

  void newChat() {
    if (_currentChatHistory.messages.isNotEmpty) {
      _chatHistory
          .firstWhere((history) => history.id == _currentChatHistory.id)
          .messages = _currentChatHistory.messages;
    }

    _currentChatHistory = ChatHistory(
      name: DateTime.now().toString(),
      createdAt: DateTime.now(),
      messages: [],
    );
    _chatHistory.add(_currentChatHistory);
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _currentChatHistory.messages.add(message);
    notifyListeners();
  }

  void addChatHistory(ChatHistory chatHistory) {
    _chatHistory.add(chatHistory);
    notifyListeners();
  }

  void switchCurrent(String id) {
    if (_currentChatHistory.id == id) {
      return;
    }
    _currentChatHistory = _chatHistory.firstWhere(
      (history) => history.id == id,
    );
    notifyListeners();
  }


  void switchCurrentByIndex(int index) {
    _currentChatHistory = _chatHistory[index];
    notifyListeners();
  }


  void removeChatHistory(String id) {
    _chatHistory.removeWhere((history) => history.id == id);
    if (_currentChatHistory.id == id) {
      _currentChatHistory = ChatHistory(
        name: 'Test',
        createdAt: DateTime.now(),
        messages: [],
      );
    }
    notifyListeners();
  }


  void removeChatHistoryByIndex(int index) {
    if (_currentChatHistory.id == _chatHistory[index].id) {
      _currentChatHistory = ChatHistory(
        name: 'Test',
        createdAt: DateTime.now(),
        messages: [],
      );
    }
    _chatHistory.removeAt(index);
    notifyListeners();
  }
}
