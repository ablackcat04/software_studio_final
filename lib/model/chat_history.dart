import 'dart:convert';
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

  String? guide;

  String get title => name;

  void setImage(Uint8List _imageBytes) {
    imageBytes = _imageBytes;
  }

  void setGuide(String newGuide) {
    guide = newGuide;
  }

  String toPromptString() {
    return messages
        .map((message) {
          final speaker = message.isAI ? 'AI' : 'USER';
          return '$speaker: ${message.content.trim()}';
        })
        .join('\n\n');
  }

  Future<void> renameHistory({
    required CancellationToken cancellationToken,
  }) async {
    final AiSuggestionService _aiService = AiSuggestionService();
    name = await _aiService.nameHistory(
      history: toPromptString(),
      cancellationToken: cancellationToken,
    );
  }

  // In ChatHistory
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((e) => e.toJson()).toList(),
    'activateFolder': activateFolder,
    'hasSetup': hasSetup,
    'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    'guide': guide,
  };

  factory ChatHistory.fromJson(Map<String, dynamic> json) =>
      ChatHistory(
          name: json['name'],
          createdAt: DateTime.parse(json['createdAt']),
          messages:
              (json['messages'] as List)
                  .map((e) => ChatMessage.fromJson(e))
                  .toList(),
          hasSetup: json['hasSetup'] ?? false,
        )
        ..id = json['id']
        ..activateFolder = Map<String, bool>.from(json['activateFolder'])
        ..imageBytes =
            json['imageBytes'] != null ? base64Decode(json['imageBytes']) : null
        ..guide = json['guide'];

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

  // In ChatMessage
  Map<String, dynamic> toJson() => {
    'isAI': isAI,
    'content': content,
    'suggestions': suggestions?.map((e) => e.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    isAI: json['isAI'],
    content: json['content'],
    suggestions:
        (json['suggestions'] as List?)
            ?.map((e) => MemeSuggestion.fromJson(e))
            .toList(),
  );
}
