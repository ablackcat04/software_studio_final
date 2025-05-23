import 'package:software_studio_final/model/chat.dart'; // For ChatMessage, ChatHistory
import 'package:software_studio_final/state/current_chat_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_message.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/message_input.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadJsonData() async {
  String jsonString = await rootBundle.loadString(
    'assets/images/basic/description/mygo.json', // Ensure path is correct
  );
  return jsonDecode(jsonString);
}

Future<Map<String, dynamic>?> getItemById(int id) async {
  final Map<String, dynamic> data = await loadJsonData();
  final String key = id.toString();
  return data[key];
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

enum MainState {
  blank, // Initial state, show upload prompt
  uploaded, // Image uploaded, guide not yet generated
  generating, // AI is processing (for guide or memes)
  suggestionReady, // Guide generated, ready for "Go" or chat
  conversation, // Active chat session
  error,
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final List<Map<String, dynamic>> _messages = []; // Replaced by ChatHistoryNotifier
  // final List<List<Map<String, dynamic>>> _chatHistory = []; // Replaced by ChatHistoryNotifier

  // final Set<String> _likedImages = {}; // For AIMessage interactions
  // bool _isAllSelected = true; // Example state for drawer/filtering
  // bool _isMygoSelected = false;
  // bool _isFavoriteSelected = false;

  MainState mstate = MainState.blank;
  bool _isLoading = false;
  late List<String> lines; // Stores image IDs from Gemini
  final String _currentAIMode = "一般"; // Default AI mode

  @override
  void initState() {
    super.initState();
    // Ensure a chat history exists when the page loads
    // Needs to be done after the first frame to access Provider safely if ChatHistoryNotifier auto-creates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentChatNotifier = Provider.of<CurrentChatNotifier>(
        context,
        listen: false,
      );
      // If starting blank, set state, otherwise could be conversation
      // This depends on how you want to resume chats.
      // For now, new instance of ChatPage starts blank.
      // If currentChatNotifier.currentChatHistory.messages.isNotEmpty,
      // you might want to set mstate = MainState.conversation.
      if (currentChatNotifier.currentChatId == null) {
        setState(() {
          mstate = MainState.blank;
        });
      } else {
        setState(() {
          mstate =
              MainState.conversation; // Or suggestionReady if guide was last
        });
      }
    });
  }

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
          duration: const Duration(milliseconds: 300), // Adjusted duration
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> _getMemeDataForImageSuggestion(String mode) async {
    // Mode is now a parameter, e.g., "一般", "已讀亂回"
    String memeSuggestionGeneratePrompt = """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's 
processing pipeline. Your primary function is to follow a provided meme 
suggestion guide and find suitable meme from the database, 
the database is in ID: description. 
Your output will only consist 4 ID, separated by a newline. 
The suggestion mode now is $mode. The database is provided below. 
Thinking should be concise since speed is critical in this task.

------------------------------------------------------------------------------
""";
    // Load database descriptions
    for (int id = 1; id <= 100; id++) {
      // Iterate as needed for your DB size
      final result = await getItemById(id);
      if (result != null) {
        // Assuming result is a Map, convert to String appropriately, e.g., result['description']
        memeSuggestionGeneratePrompt += "$id: ${result.toString()}\n\n";
      }
    }
    return memeSuggestionGeneratePrompt;
  }

  Future<void> _onSendPressed() async {
    // For sending text messages and getting image suggestions
    if (_isLoading) return;
    final currentChatNotifier = Provider.of<CurrentChatNotifier>(
      context,
      listen: false,
    );
    final userInput = _textController.text.trim();

    if (userInput.isEmpty) return;

    currentChatNotifier.addMessage(
      ChatMessage(isAI: false, content: userInput),
    );
    _textController.clear();
    // Set state to conversation if not already, and show loading
    setState(() {
      _isLoading = true;
      if (mstate != MainState.conversation && mstate != MainState.generating) {
        mstate = MainState.generating; // Indicates AI is working
      }
    });
    _scrollToBottom(); // Scroll after user message is added

    // Prepare past inputs for context (optional, depending on Gemini prompt needs)
    // String pastInputs = currentChatNotifier.currentChatHistory.messages
    //     .where((m) => !m.isAI)
    //     .map((m) => m.content)
    //     .join('\n');

    try {
      String systemPromptForImages = await _getMemeDataForImageSuggestion(
        _currentAIMode,
      );
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-preview-04-17',
        apiKey: apiKey,
      ); // Or your preferred text model

      final systemPart = TextPart(systemPromptForImages);

      final guide = Provider.of<GuideNotifier>(context, listen: false).guide;
      print('guide: $guide');

      final guideContext = guide;
      final userRequestPart = TextPart(
        "This is the guide, $guideContext\nThe user typed: \"$userInput\". Current AI Mode: '$_currentAIMode'. Provide 4 image IDs based on this.",
      );

      final content = [
        Content.multi([systemPart, userRequestPart]),
      ];

      print(systemPart.text);
      print(userRequestPart.text);

      final GenerateContentResponse response = await model.generateContent(
        content,
      );
      final aiResponseText = response.text; // Expected to be image IDs

      print(aiResponseText);

      if (aiResponseText != null && aiResponseText.isNotEmpty) {
        lines =
            aiResponseText
                .trim()
                .split('\n')
                .where((line) => line.isNotEmpty)
                .toList();
        List<String> imagePaths =
            lines.map((number) => 'images/basic/$number.jpg').toList();

        if (imagePaths.isNotEmpty) {
          currentChatNotifier.addMessage(
            ChatMessage(isAI: true, content: "給你的梗圖建議:", images: imagePaths),
          );
        } else {
          currentChatNotifier.addMessage(
            ChatMessage(
              isAI: true,
              content: "無法解析AI回覆中的圖片建議。原始回覆: $aiResponseText",
            ),
          );
        }
      } else {
        currentChatNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI沒有回覆，可能無法理解請求。'),
        );
      }
    } catch (e) {
      print('Error in _onSendPressed with Gemini: $e');
      currentChatNotifier.addMessage(
        ChatMessage(
          isAI: true,
          content: 'AI回覆時發生錯誤：\n${e.toString()}',
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('AI回覆錯誤: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _isLoading = false;
        mstate = MainState.conversation; // Ensure it's conversation state
      });
      _scrollToBottom(); // Scroll after AI message is added
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.select<CurrentChatNotifier, List>(
      (notifier) => notifier.currentChat?.messages ?? [],
    );

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
                  // messageContent: message.content,
                  imagePaths: message.images,
                  // onImageTap: _copyOnTap, // Pass interaction handlers
                  // onLikeToggle: _toggleLike,
                  // likedImages: _likedImages,
                );
              } else {
                return UserMessage(messageContent: message.content);
              }
            },
          ),
        ),
        if (mstate == MainState.error)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "An error occurred. Please try again.",
              style: TextStyle(color: Colors.red),
            ),
          ),

        // Show AI Mode Switch and Message Input for relevant states
        if (mstate == MainState.suggestionReady ||
            mstate == MainState.conversation ||
            mstate == MainState.generating)
          AIModeSwitch(
            // currentMode: _currentAIMode,
            // onModeChanged: (newMode) {
            //   setState(() {
            //     _currentAIMode = newMode;
            //   });
            // },
          ),
        if (mstate == MainState.suggestionReady ||
            mstate == MainState.conversation ||
            mstate == MainState.generating)
          MessageInput(
            textController: _textController,
            onSendPressed: _onSendPressed,
            // Optionally, always show upload button or only in blank state
            // onUploadPressed: (mstate == MainState.blank || mstate == MainState.conversation) ? _onUploadPressed : null,
          ),
      ],
    );
  }
}
