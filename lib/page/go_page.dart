import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/chat/chat.dart';
import 'package:software_studio_final/widgets/chat/go_button.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart'; // 引入 GoButton

class GoPage extends StatelessWidget {
  const GoPage({super.key});

  void _onGoPressed(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    chatHistoryNotifier.addMessage(
      ChatMessage(
        isAI: true,
        content: '這是AI的回覆',
        images: [
          'assets/images/image1.jpg',
          'assets/images/image2.jpg',
          'assets/images/image3.jpg',
          'assets/images/image4.jpg',
        ],
      ),
    );
    chatHistoryNotifier.currentSetup();
  }

  @override
  Widget build(BuildContext context) {
    final memeFolder = ['Favorite', 'Mygo'];
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );
    chatHistoryNotifier.currentChatHistory.activateFolder = {
      'Favorite': false,
      'Mygo': false,
    };
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: ListView(children: [UserMessage(messageContent: "圖片已上傳 ✅")])),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    memeFolder
                        .map(
                          (folder) => Row(
                            children: [
                              Checkbox(
                                value: chatHistoryNotifier.getFolder(folder),
                                onChanged: (bool? value) {
                                  chatHistoryNotifier.setFolder(folder, value!);
                                },
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.folder, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(folder),
                            ],
                          ),
                        )
                        .toList(),
              ),
            ),
            AIModeSwitch(),
          ],
        ),
        GoButton(onGoPressed: () => _onGoPressed(context)),
      ],
    );
  }
}
