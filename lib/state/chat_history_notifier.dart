import 'package:flutter/material.dart';
import 'package:software_studio_final/model/chat_history.dart';

class ChatHistoryNotifier extends ChangeNotifier {
  final List<ChatHistory> _chatHistory = [];
  ChatHistory _currentChatHistory = ChatHistory(
    name: 'Test',
    createdAt: DateTime.now(),
    messages: [],
  );

  ChatHistory get currentChatHistory => _currentChatHistory;
  List<ChatHistory> get chatHistory => _chatHistory;
  Map<String, bool> get activateFolder => _currentChatHistory.activateFolder;
  bool getFolder(String folder) =>
      _currentChatHistory.activateFolder[folder] ?? false;

  ChatHistoryNotifier() {
    newChat();
    currentSetup();
    addMessage(ChatMessage(isAI: false, content: 'Old message 1', images: []));
    addMessage(
      ChatMessage(
        isAI: true,
        content: '',
        images: ['images/basic/1.jpg', 'images/basic/2.jpg'],
      ),
    );

    newChat();
    currentSetup();
    addMessage(ChatMessage(isAI: false, content: 'Another chat', images: []));
    newChat();
  }

  void newChat() {
    _currentChatHistory = ChatHistory(
      name: "新對話",
      createdAt: DateTime.now(),
      messages: [],
    );
    notifyListeners();
  }

  void currentSetup() {
    _currentChatHistory.hasSetup = true;
    _chatHistory.insert(0, _currentChatHistory);
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _currentChatHistory.messages.add(message);
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
      newChat();
    }
    notifyListeners();
  }

  void removeChatHistoryByIndex(int index) {
    if (_currentChatHistory.id == _chatHistory[index].id) {
      newChat();
    }
    _chatHistory.removeAt(index);
    notifyListeners();
  }

  void setFolder(String folder, bool value) {
    _currentChatHistory.activateFolder[folder] = value;
    notifyListeners();
  }
}
