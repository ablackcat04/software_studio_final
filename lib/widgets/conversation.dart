import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/AIMessageBlock.dart';
import 'package:software_studio_final/widgets/UserMessageBlock.dart';

class ConversationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final double imageSize;
  final Function(String) onCopy;
  final Function(String) onToggleLike;
  final Set<String> likedImages;

  const ConversationWidget({
    Key? key,
    required this.messages,
    required this.scrollController,
    required this.imageSize,
    required this.onCopy,
    required this.onToggleLike,
    required this.likedImages,
  }) : super(key: key);

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
            return UserMessageBlock(
              messageContent: message['content'].toString(),
            );
          } else {
            // AI 回應（圖片）
            final imagePaths =
                (message['content'] is List)
                    ? List<String>.from(message['content'])
                    : <String>[];
            return AIMessageBlock(
              imagePaths: imagePaths,
              imageSize: imageSize,
              onCopy: onCopy,
              onToggleLike: onToggleLike,
              likedImages: likedImages,
            );
          }
        },
      ),
    );
  }
}
