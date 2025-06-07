// lib/pages/chat_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/service/ai_suggestion_service.dart'; // IMPORT THE SERVICE
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart';
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_message.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/message_input.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';
import 'package:software_studio_final/widgets/custom_drawer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum MainState {
  blank,
  uploaded,
  generating,
  suggestionReady,
  conversation,
  error,
}

class _ChatPageState extends State<ChatPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController(initialPage: 0);
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _likedImages = {};

  // ADDED: Create an instance of the service
  final AiSuggestionService _aiService = AiSuggestionService();

  MainState mstate = MainState.blank;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
        context,
        listen: false,
      );
      if (chatHistoryNotifier.chatHistory.isEmpty) {
        chatHistoryNotifier.newChat();
      }
      if (chatHistoryNotifier.currentChatHistory.messages.isEmpty) {
        setState(() => mstate = MainState.blank);
      } else {
        setState(() => mstate = MainState.conversation);
      }
      chatHistoryNotifier.currentChatHistory.renameHistory();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSendPressed() async {
    if (_isLoading) return;

    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final guideNotifier = Provider.of<GuideNotifier>(context, listen: false);
    final settingsNotifier = Provider.of<SettingsNotifier>(
      context,
      listen: false,
    );

    final userInput = _textController.text.trim();
    if (userInput.isEmpty) return;

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: false, content: userInput),
    );
    _textController.clear();

    setState(() {
      _isLoading = true;
      mstate = MainState.generating;
    });
    _scrollToBottom();
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: 'AI正在判斷是否需重新生成推薦指南...'),
    );
    _scrollToBottom();

    try {
      final guide = guideNotifier.guide;
      final currentAIMode = guideNotifier.mode;
      final optionNumber = settingsNotifier.getoptionnumbers();

      final analysisResult = await _aiService.decideOnGuideRegeneration(
        notifier: chatHistoryNotifier,
      );

      if (analysisResult.shouldRegenerateGuide) {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI正在重新生成推薦指南'),
        );
        _scrollToBottom();

        Uint8List? imageBytes =
            chatHistoryNotifier.currentChatHistory.imageBytes;

        final aiGuideText = await _aiService.generateGuide(
          imageBytes: imageBytes,
          mimeType: null,
          intension: analysisResult.userIntention,
        );
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI完成重新生成推薦指南'),
        );
        _scrollToBottom();

        if (aiGuideText != null && aiGuideText.isNotEmpty) {
          guideNotifier.setGuide(aiGuideText);
          chatHistoryNotifier.addMessage(
            ChatMessage(isAI: true, content: aiGuideText),
          );
          print(aiGuideText);
        } else {
          chatHistoryNotifier.addMessage(
            ChatMessage(isAI: true, content: 'AI無法生成建議指南，模型未返回文本。'),
          );
        }
      } else {
        print(
          "AI decided to keep the current guide. User intention: ${analysisResult.userIntention}",
        );
      }

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: 'AI正在尋找最適合的梗圖...'),
      );
      _scrollToBottom();

      final List<MemeSuggestion> suggestions = await _aiService
          .getMemeSuggestions(
            guide: guide,
            userInput: userInput,
            aiMode: currentAIMode,
            optionNumber: optionNumber,
            notifier: chatHistoryNotifier,
          );

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: "給你的梗圖建議:", suggestions: suggestions),
      );
      _scrollToBottom();
    } catch (e) {
      print('Error in _onSendPressed with service: $e');
      final errorMessage = 'AI回覆時發生錯誤：\n${e.toString()}';
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: errorMessage),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI回覆錯誤: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          mstate = MainState.conversation;
        });
      }
      _scrollToBottom();
    }
  }

  void _onNewChatPressed() {
    Provider.of<ChatHistoryNotifier>(context, listen: false).newChat();
    setState(() {
      mstate = MainState.blank;
      _textController.clear();
    });
    _pageController.jumpToPage(0);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _handleHistorySelection(BuildContext context, int index) {
    Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    ).switchCurrentByIndex(index);
    setState(() {
      mstate = MainState.conversation;
      _textController.clear();
    });
    _pageController.jumpToPage(0);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(context);

    if (chatHistoryNotifier.chatHistory.isEmpty) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: const Text("Meme AI Chat")),
        drawer: CustomDrawer(
          onHistoryItemSelected: (idx) => _handleHistorySelection(context, idx),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please start a new chat."),
              ElevatedButton(
                onPressed: _onNewChatPressed,
                child: const Text("New Chat"),
              ),
            ],
          ),
        ),
      );
    }

    final messages = chatHistoryNotifier.currentChatHistory.messages;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              if (message.isAI) {
                return AIMessage(
                  suggestions: message.suggestions,
                  messageContent: message.content,
                );
              } else {
                return UserMessage(messageContent: message.content);
              }
            },
          ),
        ),
        if (mstate == MainState.error)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "An error occurred. Please try again.",
              style: TextStyle(color: Colors.red),
            ),
          ),
        AIModeSwitch(),
        MessageInput(
          textController: _textController,
          onSendPressed: _onSendPressed,
          // isLoading: _isLoading,
        ),
      ],
    );
  }
}
