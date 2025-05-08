import 'package:uuid/uuid.dart';

class ChatHistory {
  ChatHistory({
    required this.name,
    required this.createdAt,
    required this.messages,
  }){
    id = const Uuid().v4();
  }

  late String id;
  String name;
  DateTime createdAt;
  List<ChatMessage> messages;

  ChatHistory copyWith({
    String? name,
    DateTime? createdAt,
    List<ChatMessage>? messages,
  }) {
    return ChatHistory(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.isAI,
    required this.content,
    required this.images,
  });

  bool isAI;
  String content;
  List<String> images;

  ChatMessage copyWith({bool? isAI, String? content, List<String>? images}) {
    return ChatMessage(
      isAI: isAI ?? this.isAI,
      content: content ?? this.content,
      images: images ?? this.images,
    );
  }
}
