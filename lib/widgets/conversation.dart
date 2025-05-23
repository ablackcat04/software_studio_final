import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/chat/ai_message.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';

class ConversationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final double imageSize;
  final Function(String) onCopy;
  final Function(String) onToggleLike;
  final Set<String> likedImages;

  const ConversationWidget({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.imageSize,
    required this.onCopy,
    required this.onToggleLike,
    required this.likedImages,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          if (message['isUser']) {
            // 使用者訊息
            return UserMessage(messageContent: message['content'].toString());
          } else {
            if (message['content'] is String) {
              UserMessage(messageContent: message['content'].toString());
            } else {
              final imagePaths =
                  (message['content'] is List)
                      ? List<String>.from(message['content'])
                      : <String>[];
              return AIMessage(imagePaths: imagePaths);
            }
          }
          return null;
        },
      ),
    );
  }
}
