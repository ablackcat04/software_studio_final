import 'package:uuid/uuid.dart';

class ChatHistory {
  ChatHistory({
    required this.name,
    required this.createdAt,
    required this.messages,
    this.hasSetup = false,
  }){
    id = const Uuid().v4();
  }

  late String id;
  String name;
  DateTime createdAt;
  List<ChatMessage> messages;
  Map<String, bool> activateFolder = {
    'Favorite': true,
    'Mygo': true,
  };
  bool hasSetup;

  ChatHistory copyWith({
    String? name,
    DateTime? createdAt,
    List<ChatMessage>? messages,
    bool? hasSetup
  }) {
    return ChatHistory(
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      hasSetup: hasSetup ?? this.hasSetup,
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
