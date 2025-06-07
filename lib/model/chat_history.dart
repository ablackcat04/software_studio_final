import 'dart:typed_data';

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
    // Use .map to transform each ChatMessage into a formatted string
    // and .join to combine them into a single string.
    return messages
        .map((message) {
          // Determine the speaker's prefix based on the isAI flag.
          final speaker = message.isAI ? 'AI' : 'USER';

          // Check if there are any images and create a placeholder text if so.
          final imageIndicator =
              (message.images != null && message.images!.isNotEmpty)
                  ? ' [Image Attached]'
                  : '';

          // Combine the parts into a single line for this message.
          // The trim() on content handles cases where it might have leading/trailing whitespace.
          return '$speaker:$imageIndicator ${message.content.trim()}';
        })
        .join(
          '\n\n',
        ); // Join all message strings with a double newline for readability.
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
  ChatMessage({required this.isAI, required this.content, this.images});

  bool isAI;
  String content;
  List<String>? images;

  ChatMessage copyWith({bool? isAI, String? content, List<String>? images}) {
    return ChatMessage(
      isAI: isAI ?? this.isAI,
      content: content ?? this.content,
      images: images ?? this.images,
    );
  }
}
