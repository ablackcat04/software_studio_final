import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';

class UploadPage extends StatelessWidget {
  final void Function(int) onNavigate;

  const UploadPage({super.key, required this.onNavigate});

  void _onUpload(BuildContext context) {
    final ImagePicker picker = ImagePicker();

    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    picker.pickImage(source: ImageSource.gallery).then((XFile? image) {
      if (image != null) {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: false, content: '圖片已上傳 ✅', images: []),
        );

        // TODO: 傳圖片至後端
        print('圖片已上傳: ${image.path}');
      }
    });
  }

  void _onSendMessage(BuildContext context, TextEditingController controller) {
    final message = controller.text.trim();
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );

    // 如果有輸入訊息，新增到聊天記錄
    if (message.isNotEmpty) {
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: false, content: message, images: []),
      );
    }

    // 清空輸入框
    controller.clear();

    // 切換到下一個頁面
    onNavigate.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );
    final messages = chatHistoryNotifier.currentChatHistory.messages;
    final TextEditingController _messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('上傳圖片')),
      body: Column(
        children: [
          // 聊天記錄
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return ListTile(
                  title: Text(
                    message.isAI ? 'AI: ${message.content}' : '使用者: ${message.content}',
                  ),
                );
              },
            ),
          ),

          // 上傳按鈕
          Container(
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _onUpload(context),
              color: theme.colorScheme.onTertiaryContainer,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              iconSize: screenWidth * 0.6,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),

          // 提示文字
          SizedBox(
            width: screenWidth * 1.2,
            child: Text(
              'Upload conversation screenshots to provide context!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 16),

          // 輸入框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _onSendMessage(context, _messageController),
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
