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
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

Future<File> getChatHistoryFile() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/chat_histories.json');
  } catch (e) {
    // fallback for development desktop use
    print("Using fallback path due to path_provider error: $e");
    return File('chat_histories_fallback.json');
  }
}

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

  final AiSuggestionService _aiService = AiSuggestionService();

  MainState mstate = MainState.blank;
  bool _isLoading = false;

  // ADDED: The cancellation token for the current main AI operation (send button)
  CancellationToken? _cancellationToken;
  // ADDED: A separate cancellation token for the history renaming in initState
  CancellationToken? _renameHistoryCancellationToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // MADE ASYNC
      if (!mounted) return; // Prevent context usage after unmounting

      final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
        context,
        listen: false,
      );

      // Initialize a new chat if no history exists
      if (chatHistoryNotifier.chatHistory.isEmpty) {
        chatHistoryNotifier.newChat();
      }

      // Set initial UI state based on current chat messages
      if (chatHistoryNotifier.currentChatHistory.messages.isEmpty) {
        if (mounted) setState(() => mstate = MainState.blank);
      } else {
        if (mounted) setState(() => mstate = MainState.conversation);
      }

      // ADDED: Attempt to rename chat history only if it's the default title
      // and has sufficient messages (at least 2 for a meaningful summary).
      if (chatHistoryNotifier.currentChatHistory.title == '新對話' &&
          chatHistoryNotifier.currentChatHistory.messages.length >= 2) {
        _renameHistoryCancellationToken =
            CancellationToken(); // Create a new token for this specific operation
        try {
          await chatHistoryNotifier.currentChatHistory.renameHistory(
            cancellationToken:
                _renameHistoryCancellationToken!, // Pass the dedicated token
          );
          // The ChatHistoryNotifier should ideally listen to changes in ChatHistory
          // or you might need to call chatHistoryNotifier.notifyListeners() if the UI
          // doesn't update automatically after renaming.
          // For now, we assume title change is observed.
        } on CancellationException catch (_) {
          print("Chat history renaming in initState was cancelled.");
        } catch (e) {
          print("Error renaming chat history in initState: $e");
          // Optionally, add a user-facing error message.
        } finally {
          // Dispose the token after the operation completes (success or failure)
          _renameHistoryCancellationToken?.dispose();
          _renameHistoryCancellationToken = null; // Clear reference
        }
      } else {
        // Ensure the rename token is null if conditions for renaming aren't met
        _renameHistoryCancellationToken = null;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _pageController.dispose();
    // Dispose both cancellation tokens if they are still active
    _cancellationToken?.dispose();
    _renameHistoryCancellationToken?.dispose();
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

  // ADDED: A new method to handle stopping the generation
  void _onStopPressed() {
    if (_cancellationToken != null) {
      print("Stop generation requested by user.");
      _cancellationToken!.cancel();
      // The `_onSendPressed`'s catch block will handle the state change
    }
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
      // CREATE a new token for this specific operation
      _cancellationToken = CancellationToken();
    });
    _scrollToBottom(); // 滾動到最下面

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: 'AI正在判斷是否需重新生成推薦指南...'),
    );
    _scrollToBottom(); // 滾動到最下面

    try {
      final guide = guideNotifier.guide;
      final currentAIMode = guideNotifier.mode;
      final optionNumber = settingsNotifier.getoptionnumbers();

      final analysisResult = await _aiService.decideOnGuideRegeneration(
        notifier: chatHistoryNotifier,
        cancellationToken: _cancellationToken!, // Pass the token
      );

      if (analysisResult.shouldRegenerateGuide) {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI正在重新生成推薦指南'),
        );
        _scrollToBottom(); // 滾動到最下面

        Uint8List? imageBytes =
            chatHistoryNotifier.currentChatHistory.imageBytes;

        final aiGuideText = await _aiService.generateGuide(
          imageBytes: imageBytes,
          mimeType: null,
          intension: analysisResult.userIntention,
          selectedMode: currentAIMode, // Pass the mode for guide generation
          cancellationToken: _cancellationToken!, // Pass the token
        );
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI完成重新生成推薦指南'),
        );
        _scrollToBottom(); // 滾動到最下面

        if (aiGuideText != null && aiGuideText.isNotEmpty) {
          chatHistoryNotifier.removeMessage('圖片已上傳 ✅，可以趁機打字');
          chatHistoryNotifier.removeMessage('正在分析圖片並生成建議指南...');
          guideNotifier.setGuide(aiGuideText);
          chatHistoryNotifier.currentChatHistory.setGuide(aiGuideText);
          chatHistoryNotifier.addMessage(
            ChatMessage(
              isAI: true,
              content: chatHistoryNotifier.currentChatHistory.guide ?? '',
            ),
          );
          _scrollToBottom(); // 滾動到最下面
        } else {
          chatHistoryNotifier.addMessage(
            ChatMessage(isAI: true, content: 'AI無法生成建議指南，模型未返回文本。'),
          );
          _scrollToBottom(); // 滾動到最下面
        }
      } else {
        print(
          "AI decided to keep the current guide. User intention: ${analysisResult.userIntention}",
        );
      }

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: 'AI正在尋找最適合的梗圖...'),
      );
      _scrollToBottom(); // 滾動到最下面

      final List<MemeSuggestion> suggestions = await _aiService
          .getMemeSuggestions(
            guide: guide,
            userInput: userInput,
            aiMode: currentAIMode,
            optionNumber: optionNumber,
            notifier: chatHistoryNotifier,
            cancellationToken: _cancellationToken!, // Pass the token
          );

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: "給你的梗圖建議:", suggestions: suggestions),
      );
      _scrollToBottom(); // 滾動到最下面
      // ADDED: Specific catch block for our cancellation
    } on CancellationException catch (_) {
      print('Operation successfully cancelled.');
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: 'AI suggestion cancelled by user.'),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Generation stopped.')));
      }
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
      _scrollToBottom(); // 滾動到最下面
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          mstate = MainState.conversation;
          // Clean up the main operation token
          _cancellationToken?.dispose(); // Ensure dispose is called
          _cancellationToken = null; // Clear the reference
        });
      }
      _scrollToBottom(); // 滾動到最下面
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
          // PASS the new properties to MessageInput
          isLoading: _isLoading,
          onStopPressed: _onStopPressed,
        ),
      ],
    );
  }
}
