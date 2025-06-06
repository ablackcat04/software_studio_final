import 'package:software_studio_final/model/chat_history.dart'; // For ChatMessage, ChatHistory
import 'package:software_studio_final/state/guide_notifier.dart';
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_message.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
import 'package:software_studio_final/widgets/chat/message_input.dart';
import 'package:software_studio_final/widgets/chat/user_message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/custom_drawer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController(
    initialPage: 0,
  ); // Assuming ChatPage is page 0

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // final List<Map<String, dynamic>> _messages = []; // Replaced by ChatHistoryNotifier
  // final List<List<Map<String, dynamic>>> _chatHistory = []; // Replaced by ChatHistoryNotifier

  final Set<String> _likedImages = {}; // For AIMessage interactions
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
      final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
        context,
        listen: false,
      );
      if (chatHistoryNotifier.chatHistory.isEmpty) {
        chatHistoryNotifier.newChat(); // Create initial chat session
      }
      // If starting blank, set state, otherwise could be conversation
      // This depends on how you want to resume chats.
      // For now, new instance of ChatPage starts blank.
      // If chatHistoryNotifier.currentChatHistory.messages.isNotEmpty,
      // you might want to set mstate = MainState.conversation.
      if (chatHistoryNotifier.currentChatHistory.messages.isEmpty) {
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
    _pageController.dispose();
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

  void _copyOnTap(String imagePath) {
    // Implement copy logic (e.g., Clipboard.setData)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $imagePath to clipboard!'), // Placeholder
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLike(String imagePath) {
    setState(() {
      if (_likedImages.contains(imagePath)) {
        _likedImages.remove(imagePath);
      } else {
        _likedImages.add(imagePath);
      }
      // Persist liked images if necessary (e.g., via SettingsNotifier or other service)
    });
  }

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> _getMemeDataForImageSuggestion(String mode) async {
    // Mode is now a parameter, e.g., "一般", "已讀亂回"
    final optionNumber =
        Provider.of<SettingsNotifier>(
          context,
          listen: false,
        ).getoptionnumbers();

    String memeSuggestionGeneratePrompt = """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's 
processing pipeline. Your primary function is to follow a provided meme 
suggestion guide and find suitable meme from the database, 
the database is in ID: description. 
Your output will only consist $optionNumber ID, separated by a newline. 
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
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final userInput = _textController.text.trim();

    if (userInput.isEmpty) return;

    chatHistoryNotifier.addMessage(
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
    // String pastInputs = chatHistoryNotifier.currentChatHistory.messages
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

      final optionNumber =
          Provider.of<SettingsNotifier>(
            context,
            listen: false,
          ).getoptionnumbers();

      final guideContext = guide;
      final userRequestPart = TextPart(
        "This is the guide, ${guideContext}\nThe user typed: \"$userInput\". Current AI Mode: '$_currentAIMode'. Provide $optionNumber image IDs based on this.",
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
          chatHistoryNotifier.addMessage(
            ChatMessage(isAI: true, content: "給你的梗圖建議:", images: imagePaths),
          );
        } else {
          chatHistoryNotifier.addMessage(
            ChatMessage(
              isAI: true,
              content: "無法解析AI回覆中的圖片建議。原始回覆: $aiResponseText",
            ),
          );
        }
      } else {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: 'AI沒有回覆，可能無法理解請求。'),
        );
      }
    } catch (e) {
      print('Error in _onSendPressed with Gemini: $e');
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: 'AI回覆時發生錯誤：\n${e.toString()}'),
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

  void _onNewChatPressed() {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    chatHistoryNotifier.newChat();
    Provider.of<GuideNotifier>(context, listen: false);
    setState(() {
      mstate = MainState.blank; // Start new chat in blank state
      _textController.clear();
    });
    _pageController.jumpToPage(0); // If this page is part of a PageView
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop(); // Close drawer
    }
  }

  void _handleHistorySelection(BuildContext context, int index) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    chatHistoryNotifier.switchCurrentByIndex(index);
    // Determine state based on selected history. For simplicity, assume conversation.
    // More complex logic might be needed to restore 'guide' if applicable.
    setState(() {
      mstate = MainState.conversation;
      _textController.clear();
    });
    _pageController.jumpToPage(0);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop(); // Close drawer
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(context);
    // Ensure notifier has a current chat, especially on first load or after all chats deleted.
    if (chatHistoryNotifier.chatHistory.isEmpty) {
      // This can happen if all chats are deleted.
      // We might show a "No chats, start a new one" message or auto-create.
      // For now, let's rely on initState to create one if empty.
      // If still no chat, show a fallback.
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: const Text("Meme AI Chat")),
        drawer: CustomDrawer(
          // onNewChat: _onNewChatPressed,
          onHistoryItemSelected: (idx) => _handleHistorySelection(context, idx),
          // Pass other necessary props like isAllSelected etc.
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Please start a new chat from the drawer."),
              ElevatedButton(
                onPressed: _onNewChatPressed,
                child: Text("New Chat"),
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
