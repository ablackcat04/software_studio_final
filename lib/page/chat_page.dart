import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_message.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/message_input.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';
import 'package:software_studio_final/state/settings_notifier.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onSendPressed() {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final settingsNotifier = Provider.of<SettingsNotifier>(
      context,
      listen: false,
    );

    final userInput = _textController.text.trim();
    if (userInput.isNotEmpty) {
      // 新增使用者的訊息到聊天記錄
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: false, content: userInput, images: []),
      );

      setState(() {
        _textController.clear();
      });

      _scrollToBottom();

      // 根據 settings 中的 optionNumber 決定圖片數量
      final optionNumber = settingsNotifier.settings.optionNumber;
      final List<String> images = List.generate(
        optionNumber,
        (index) => 'assets/images/image${index + 1}.jpg',
      );

      // 新增 AI 的回覆到聊天記錄
      chatHistoryNotifier.addMessage(
        ChatMessage(
          isAI: true,
          content: '這是AI的回覆',
          images: images,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );
    final messages = chatHistoryNotifier.currentChatHistory.messages;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder:
                (context, index) =>
                    messages[index].isAI
                        ? AIMessage(imagePaths: messages[index].images)
                        : UserMessage(messageContent: messages[index].content),
          ),
        ),
        AIModeSwitch(),
        MessageInput(
          textController: _textController,
          onSendPressed: _onSendPressed,
        ),
      ],
    );
  }
}
