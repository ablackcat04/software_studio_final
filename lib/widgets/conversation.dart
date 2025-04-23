import 'package:flutter/material.dart';

class ConversationWidget extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final TextEditingController textController;
  final Function(String) onSendPressed;
  final Function(String) onToggleLike;
  final bool isConversationActive;

  const ConversationWidget({
    Key? key,
    required this.messages,
    required this.scrollController,
    required this.textController,
    required this.onSendPressed,
    required this.onToggleLike,
    required this.isConversationActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.375;

    return Column(
      children: [
        // 訊息列表
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              if (message['isUser']) {
                // 使用者訊息
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message['content'].toString(),
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                // AI 回應（圖片）
                final imagePaths = (message['content'] is List)
                    ? List<String>.from(message['content'])
                    : <String>[];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: imagePaths.map((imagePath) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              imagePath,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: imageSize,
                                  height: imageSize,
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                messages.any((msg) =>
                                        msg['content'] is List &&
                                        msg['content'].contains(imagePath))
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: messages.any((msg) =>
                                        msg['content'] is List &&
                                        msg['content'].contains(imagePath))
                                    ? Colors.pinkAccent
                                    : Colors.grey,
                                size: 24,
                              ),
                              onPressed: () => onToggleLike(imagePath),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        // 輸入框和發送按鈕
        if (isConversationActive)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: "輸入提示...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: onSendPressed,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                  iconSize: 28,
                  onPressed: () => onSendPressed(textController.text),
                ),
              ],
            ),
          ),
      ],
    );
  }
}