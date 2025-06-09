import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:path_provider/path_provider.dart';
import 'favorite_notifier.dart';

Future<void> saveChatHistories(List<ChatHistory> histories) async {
  try {
    if (kIsWeb) {
      print("Running on web");
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/chat_histories.json');

      final jsonList = histories.map((history) => history.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    }
  } catch (e) {
    print('Failed to save chat histories: $e');
  }
}

class ChatHistoryNotifier extends ChangeNotifier {
  final FavoriteNotifier favoriteNotifier = FavoriteNotifier(); // 添加 FavoriteNotifier 实例

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

  String _mode = "一般";
  String get mode => _mode;

  void setMode(String newMode) {
    _mode = newMode;
    notifyListeners();
  }

  ChatHistoryNotifier() {
    // newChat();
    // currentSetup();
  }

  Future<File> getChatHistoryFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/chat_histories.json');
    } catch (e) {
      // fallback for development desktop use
      print("Using fallback path due to path_provider error: $e");
      return File('chat_histories_fallback.json');
    }
  }

  Future<List<ChatHistory>> loadChatHistories() async {
    if (kIsWeb) {
      print("Running on web");
      return [];
    } else {
      final file = await getChatHistoryFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final jsonList = jsonDecode(content);
      return (jsonList as List).map((e) => ChatHistory.fromJson(e)).toList();
    }
  }

  Future<void> load() async {
    final loadedHistories =
        await loadChatHistories(); // Your disk load function
    _chatHistory.clear();
    _chatHistory.addAll(loadedHistories);
    if (_chatHistory.isNotEmpty) {
      _currentChatHistory = _chatHistory.first;
    }
    notifyListeners();
  }

  void newChat() {
    _currentChatHistory = ChatHistory(
      name: "新對話",
      createdAt: DateTime.now(),
      messages: [],
    );
    saveChatHistories(_chatHistory);
    notifyListeners();
  }

  void currentSetup() {
    _currentChatHistory.hasSetup = true;
    _chatHistory.insert(0, _currentChatHistory);
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    _currentChatHistory.messages.add(message);
    saveChatHistories(_chatHistory);
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

  void removeMessage(String content) {
  // 從當前聊天歷史中移除指定內容的消息
  _currentChatHistory.messages.removeWhere((message) => message.content == content);
  notifyListeners();
  }
}
