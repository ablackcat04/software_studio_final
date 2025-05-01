import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/AIMessageBlock.dart';
import 'package:software_studio_final/widgets/UserMessageBlock.dart';

class ConversationWidget extends StatelessWidget {
  final ScrollController scrollController;
  final double imageSize;
  final Function(String) onCopy;
  final Function(String) onToggleLike;
  final Set<String> likedImages;

  const ConversationWidget({
    super.key,
    required this.scrollController,
    required this.imageSize,
    required this.onCopy,
    required this.onToggleLike,
    required this.likedImages,
  });

  @override
  Widget build(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );
    final messages = chatHistoryNotifier.currentChatHistory.messages;

    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          if (message.isAI) {
            return AIMessageBlock(
              imagePaths: message.images,
              imageSize: imageSize,
              onCopy: onCopy,
              onToggleLike: onToggleLike,
              likedImages: likedImages,
            );
          } else {
            return UserMessageBlock(messageContent: message.content);
          }
        },
      ),
    );
  }
}
