import 'dart:typed_data';

import 'package:software_studio_final/service/ai_suggestion_service.dart';
import 'package:uuid/uuid.dart';

class ChatHistory {
  ChatHistory({
    required this.name,
    required this.createdAt,
    required this.messages,
    this.hasSetup = false,
  }) {
    id = const Uuid().v4();
  }

  late String id;
  String name;
  DateTime createdAt;
  List<ChatMessage> messages;
  Map<String, bool> activateFolder = {'Favorite': true, 'Mygo': true};
  bool hasSetup;
  Uint8List? imageBytes;

  void setImage(Uint8List _imageBytes) {
    imageBytes = _imageBytes;
  }

  String toPromptString() {
    return messages
        .map((message) {
          final speaker = message.isAI ? 'AI' : 'USER';
          return '$speaker: ${message.content.trim()}';
        })
        .join('\n\n');
  }

  Future<void> renameHistory() async {
    final AiSuggestionService _aiService = AiSuggestionService();
    name = await _aiService.nameHistory(history: toPromptString());
  }

  ChatHistory copyWith({
    String? name,
    DateTime? createdAt,
    List<ChatMessage>? messages,
    bool? hasSetup,
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
  ChatMessage({required this.isAI, required this.content, this.suggestions});

  bool isAI;
  String content;
  // List<String>? images;
  List<MemeSuggestion>? suggestions;

  List<MemeSuggestion>? getSuggestions() {
    return suggestions;
  }

  ChatMessage copyWith({bool? isAI, String? content, List<String>? images}) {
    return ChatMessage(
      isAI: isAI ?? this.isAI,
      content: content ?? this.content,
      suggestions: suggestions ?? suggestions,
    );
  }
}
