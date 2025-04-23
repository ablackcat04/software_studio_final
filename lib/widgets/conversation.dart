import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    return Expanded(
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
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                          SizedBox(
                            width: imageSize,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () => onCopy(imagePath),
                                    icon: const Icon(Icons.copy),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      likedImages.contains(imagePath)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: likedImages.contains(imagePath)
                                          ? Colors.pinkAccent
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                    onPressed: () => onToggleLike(imagePath),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}