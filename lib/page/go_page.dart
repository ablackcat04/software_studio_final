import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/chat/go_button.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';

class GoPage extends StatefulWidget {
  const GoPage({super.key});

  @override
  State<GoPage> createState() => _GoPageState();
}

class _GoPageState extends State<GoPage> {
  bool _isLoading = true; // 初始狀態為 true，GoButton 為灰色

  @override
  void initState() {
    super.initState();

    // 模擬 2 秒的初始化延遲
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false; // 2 秒後解除禁用
      });
    });
  }

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
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  UserMessage(messageContent: "圖片已上傳 ✅"),
                ],
              ),
            ),
            const AIModeSwitch(),
          ],
        ),
        GoButton(
          onGoPressed: () => _onGoPressed(context),
          isLoading: _isLoading, // 傳遞加載狀態
        ),
      ],
    );
  }
}
