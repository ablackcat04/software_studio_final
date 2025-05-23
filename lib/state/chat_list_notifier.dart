import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:software_studio_final/model/chat.dart';
import 'package:uuid/uuid.dart';

// [{
//  "unique_id": {
//    "id": "unique_id",
//    "name": "Chat Name",
//    "createdAt": "2023-10-01T12:00:00Z"
//  }
// }]

class ChatListNotifier extends ChangeNotifier {
  List<ChatMeta> _chats = [];
  List<ChatMeta> get chats => _chats;

  ChatListNotifier() {
    loadChatsFromHive();
  }

  String addChat(String name) {
    final newChatMeta = ChatMeta(
      id: Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    _chats.insert(0, newChatMeta);

    Hive.openBox('chat_meta').then((box) {
      box.put(newChatMeta.id, newChatMeta.toMap());
    });

    notifyListeners();
    return newChatMeta.id;
  }

  void removeChat(String id) {
    Hive.openBox('chat_meta').then((box) async {
      await box.delete(id);
    });
    _chats.removeWhere((chat) => chat.id == id);

    notifyListeners();
  }

  Future<void> loadChatsFromHive() async {
    final box = await Hive.openBox('chat_meta');
    _chats =
        box.values
            .map((m) => ChatMeta.fromMap(Map<String, dynamic>.from(m)))
            .toList();
    _chats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }
}
