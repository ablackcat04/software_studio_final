import 'package:flutter/material.dart';
import 'package:software_studio_final/model/chat.dart';
import 'package:hive/hive.dart';

// [{
//  "unique_id": {
//    "messages": [
//      "isAI": true,
//      "content": "Hello, how can I help you?",
//      "images": []
//    ],
//    "activateFolder": []
//  }
// }]

class CurrentChatNotifier extends ChangeNotifier {
  String? _currentChatId;
  String? get currentChatId => _currentChatId;

  Chat? _currentChat;
  Chat? get currentChat => _currentChat;

  Future<void> save() async {
    if (_currentChat == null) {
      return;
    }
    final box = await Hive.openBox('chat_history');
    await box.put(_currentChatId, _currentChat?.toMap());
    print("Chat saved to Hive with ID: $_currentChatId");
  }

  Future<void> switchCurrent(String id) async {
    if (_currentChatId == id) {
      return;
    }
    if (_currentChat != null) {
      await save();
    }
    _currentChatId = id;

    final box = await Hive.openBox('chat_history');
    print("Loading chat with ID: $id");
    if (!box.containsKey(id)) {
      _currentChat = Chat(
        messages: [],
        activateFolder: {'Favorite': true, 'Mygo': true},
      );
      print("Chat not found in Hive, creating new chat.");
      notifyListeners();
      return;
    }

    final map = Map<String, dynamic>.from(box.get(id));
    _currentChat = Chat.fromMap(map);

    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    if (_currentChat == null) {
      return;
    }
    _currentChat!.messages.add(message);
    notifyListeners();
  }

  void setFolder(String folder, bool value) {
    if (_currentChat == null) {
      return;
    }
    _currentChat!.activateFolder[folder] = value;
    notifyListeners();
  }

  void activate() {
    if (_currentChat == null) {
      return;
    }
    _currentChat!.active = true;
    notifyListeners();
  }

  Future<void> clear() async {
    if (_currentChat != null) {
      await save();
    }
    _currentChat = null;
    _currentChatId = null;
    notifyListeners();
  }
}
