import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/models/settings.dart';
import 'package:software_studio_final/widgets/customDrawer.dart';
import 'package:software_studio_final/widgets/favorite.dart';
import 'package:software_studio_final/widgets/settings.dart';
import 'package:software_studio_final/widgets/toggleButton.dart';
import 'package:software_studio_final/widgets/trending.dart';
import 'package:software_studio_final/widgets/folder.dart';
import 'package:software_studio_final/widgets/conversation.dart';
import 'package:software_studio_final/widgets/uploadbutton.dart';
import 'package:software_studio_final/widgets/gobutton.dart';
import 'package:software_studio_final/widgets/MessageInput.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // If apiKey comes from here

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum MainState {
  blank,
  uploaded,
  conversation,
  generating,
  suggestionReady,
  error,
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final List<List<Map<String, dynamic>>> _chatHistory = [
    [
      {'isUser': true, 'content': 'Old message 1'},
      {
        'isUser': false,
        'content': ['assets/images/image1.jpg', 'assets/images/image2.jpg'],
      },
    ],
    [
      {'isUser': true, 'content': 'Another chat'},
    ],
  ];
  final Set<String> _likedImages = {};
  bool _isAllSelected = true;
  bool _isMygoSelected = false;
  bool _isFavoriteSelected = false;

  MainState mstate = MainState.blank;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _copyOnTap(String imagePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $imagePath to clipboard!'),
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
    });
  }

  void _onSendPressed() {
    final userInput = _textController.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        // 新增使用者訊息
        _messages.add({'isUser': true, 'content': userInput});
        _textController.clear();

        // 模擬 AI 回覆
        _scrollToBottom();
        _messages.add({
          'isUser': false,
          'content': [
            'assets/images/image1.jpg',
            'assets/images/image2.jpg',
            'assets/images/image3.jpg',
            'assets/images/image4.jpg',
          ],
        });
      });
    }
  }

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  bool _isLoading = false;

  static const String memeSuggestionPrompt = """
Your Role:

You are a specialized analysis component within an AI Meme Suggestion App's processing pipeline. Your primary function is to analyze a user-provided screenshot of a conversation and extract key contextual information. Your output will be a structured "Guide" used by a downstream Large Language Model (LLM) to select relevant memes.

Input:

You will receive a screenshot image of a conversation.

Your Tasks:

Analyze the Screenshot: Carefully examine both the visual elements and the text content of the screenshot.
Identify Platform: Determine the platform where the conversation is taking place (e.g., Discord, Facebook Messenger, LINE, Instagram DM, WhatsApp, Twitter/X, PTT, Dcard, 巴哈姆特動畫瘋, a generic web forum, SMS, etc.). If uncertain, state the most likely options.
Identify User: Infer who the 'user' is (the person who captured the screenshot and intends to reply). Look for indicators like "Me," message alignment (left/right), profile picture conventions, or other UI cues. If ambiguous, describe the participants neutrally (e.g., "User is Person A on the left").
Summarize Conversation Content: Briefly summarize the topic and tone of the recent conversation exchange shown in the screenshot. Focus on the last few messages to capture the immediate context for the user's potential reply. Note any strong emotions or key points being made.
Infer User Intentions (Categorized): Based specifically on the current state of the conversation in the screenshot, infer why the user might want to send a meme right now. Generate four distinct potential intentions for each of the following reply modes. These intentions should reflect plausible reasons for using a meme in that specific context and mode:
一般 (General/Normal): Standard conversational reactions (agreement, disagreement, humor, surprise, empathy, acknowledgement, topic change).
已讀亂回 (Read & Random Reply): Intentions focused on playful disruption, absurdity, non-sequiturs, ignoring the previous point humorously, or chaotic energy.
正經 (Serious/Formal): Intentions for more serious or formal replies (polite agreement/disagreement, concluding a point, emphasizing something seriously, expressing formal surprise or concern, perhaps even ironic use of a meme in a serious context).
關鍵字 (Keyword): Intentions directly related to specific nouns, verbs, concepts, or objects explicitly mentioned in the recent messages. Focus on the most salient keywords.
Output Format:

Structure your findings as a "Mindful Guide" using clear Markdown formatting. This guide will directly inform the next LLM.

Guide for Meme Suggestion LLM
1. Platform Analysis
Detected Platform: [e.g., Facebook Messenger, Discord, 巴哈姆特動畫瘋 - or "Likely X or Y", "Uncertain"]
2. User Identification
Inferred User: [e.g., "Me" (Right side), Person A (Left side), Bottom participant]
3. Conversation Context Summary
Topic: [Brief summary of what's being discussed]
Recent Exchange: [Summary of the last 1-3 messages]
Tone/Emotion: [e.g., Casual, Humorous, Tense, Excited, Neutral, Argumentative]
4. Potential User Intentions (Why send a meme now?)
Mode: 一般 (General/Normal)
[Intention 1 - e.g., Express agreement with the last message]
[Intention 2 - e.g., Show amusement at the situation]
[Intention 3 - e.g., Lighten the mood]
[Intention 4 - e.g., Casually acknowledge the message]
Mode: 已讀亂回 (Read & Random Reply)
[Intention 1 - e.g., Completely change the subject absurdly]
[Intention 2 - e.g., Pretend to misunderstand the last message humorously]
[Intention 3 - e.g., Reply with something totally unrelated and chaotic]
[Intention 4 - e.g., Respond to an older message as if just seeing it]
Mode: 正經 (Serious/Formal)
[Intention 1 - e.g., Formally agree or disagree with a point made]
[Intention 2 - e.g., Emphasize the seriousness of their own previous point]
[Intention 3 - e.g., Politely signal the end of the discussion topic]
[Intention 4 - e.g., Express genuine concern or surprise in a non-casual way]
Mode: 關鍵字 (Keyword)
Identified Keywords: [List 1-3 key terms from recent messages, e.g., "cat", "exam", "dinner"]
[Intention 1 - e.g., React specifically to the mention of "cat"]
[Intention 2 - e.g., Show feelings about the upcoming "exam"]
[Intention 3 - e.g., Make a joke related to "dinner"]
[Intention 4 - e.g., Find a meme visually representing keyword X]
Important Considerations:

Be concise but informative.
Focus on the immediate context provided in the screenshot.
If information is ambiguous, acknowledge it.
Ensure the generated intentions are distinct within each category and plausible given the conversation summary.
""";

  Future<void> _onUploadPressed() async {
    if (_isLoading) return; // Prevent multiple simultaneous requests

    final ImagePicker picker = ImagePicker();
    // Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (apiKey.isEmpty) {
      if (mounted) {
        // Check if the widget is still in the tree
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('找不到API密鑰，請檢查.env文件配置')));
      }
      return;
    }

    if (image == null) {
      // Optionally, show a message if no image was selected
      // if (mounted) {
      //   ScaffoldMessenger.of(context)
      //       .showSnackBar(const SnackBar(content: Text('未選擇任何圖片。')));
      // }
      return;
    }

    setState(() {
      _isLoading = true;
      // Update UI to show image is uploaded and processing has started
      _messages.add({'isUser': true, 'content': '圖片已上傳 ✅'});
      _messages.add({'isUser': true, 'content': '正在分析圖片並生成建議指南...'});
      mstate = MainState.uploaded; // Or your equivalent state
    });

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      String mimeType =
          image.mimeType ?? 'image/jpeg'; // Default to JPEG if null

      // Basic MIME type detection from path extension if image.mimeType is null
      if (image.mimeType == null) {
        final String extension = image.path.split('.').last.toLowerCase();
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'jpg' || extension == 'jpeg') {
          mimeType = 'image/jpeg';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        }
        // Consider logging a warning or handling unsupported types if needed
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash-preview-04-17',
        apiKey: apiKey,
      );

      // Your detailed prompt (ensure memeSuggestionPrompt is defined in your class scope)
      final promptTextPart = TextPart(memeSuggestionPrompt);
      final imagePart = DataPart(mimeType, imageBytes);

      final content = [
        Content.multi([promptTextPart, imagePart]),
      ];

      final GenerateContentResponse response = await model.generateContent(
        content,
      );

      // Access your desired message from the response.
      final message = response.text ?? 'Content generated successfully';

      // Show a Snackbar
      print(message);

      setState(() {
        // Remove the "Generating..." message
        if (_messages.isNotEmpty &&
            _messages.last['content'] == '正在分析圖片並生成建議指南...') {
          _messages.removeLast();
        }

        if (response.text != null && response.text!.isNotEmpty) {
          _messages.add({
            'isUser': true,
            'content': response.text!, // This is the "Mindful Guide"
          });
          mstate = MainState.suggestionReady; // Or your equivalent state
        } else {
          _messages.add({
            'isUser': true,
            'content': '無法生成建議指南，模型未返回文本。可能是內容被過濾，請檢查安全設置或提示。',
          });
          mstate = MainState.error; // Or your equivalent state
        }
      });
    } catch (e) {
      print('Error generating content with Gemini: $e');
      setState(() {
        // Remove the "Generating..." message if it's still there
        if (_messages.isNotEmpty &&
            _messages.last['content'] == '正在分析圖片並生成建議指南...') {
          _messages.removeLast();
        }
        _messages.add({
          'isUser': true,
          'content': '生成建議指南時發生錯誤：\n${e.toString()}',
        });
        mstate = MainState.error; // Or your equivalent state
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('生成建議時發生錯誤: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onGoPressed() {
    setState(() {
      // 儲存當前對話到歷史對話
      if (_messages.isNotEmpty) {
        _chatHistory.add(
          List<Map<String, dynamic>>.from(
            _messages.map((m) {
              final newMsg = Map<String, dynamic>.from(m);
              if (newMsg['content'] is List) {
                newMsg['content'] = List.from(newMsg['content']);
              }
              return newMsg;
            }),
          ),
        );
      }

      // 切換到對話狀態
      mstate = MainState.conversation;

      // 模擬 AI 回覆
      _messages.add({
        'isUser': false,
        'content': [
          'assets/images/image1.jpg',
          'assets/images/image2.jpg',
          'assets/images/image3.jpg',
          'assets/images/image4.jpg',
        ],
      });

      // 更新歷史對話（包含 AI 回覆）
      _chatHistory[_chatHistory.length - 1] = List<Map<String, dynamic>>.from(
        _messages.map((m) {
          final newMsg = Map<String, dynamic>.from(m);
          if (newMsg['content'] is List) {
            newMsg['content'] = List.from(newMsg['content']);
          }
          return newMsg;
        }),
      );
    });
  }

  void _onNewChatPressed() {
    setState(() {
      _messages.clear();
      _textController.clear();
      _likedImages.clear();
      mstate = MainState.blank;
    });
  }

  void _goToSettings() {
    Settings initSettings = Settings(
      optionNumbers: 4,
      myFavorite: true,
      hiddenPictures: false,
      privacyPolicy: true,
      isDarkTheme: false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsPage(
              initSettings: initSettings,
              onChanged: (Settings settings) {},
            ),
      ),
    );
  }

  void _goToFavorite() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritePage()),
    );
  }

  void _goToTrending() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrendingPage()),
    );
  }

  void _handleHistorySelection(int index) {
    if (index < 0 || index >= _chatHistory.length) return;

    setState(() {
      _messages.clear();
      _messages.addAll(
        _chatHistory[index].map((msg) {
          final newMsg = Map<String, dynamic>.from(msg);
          if (newMsg['content'] is List) {
            newMsg['content'] = List.from(newMsg['content']);
          }
          return newMsg;
        }),
      );
      _textController.clear();
      _likedImages.clear();
      mstate = MainState.conversation;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.375;
    ThemeData theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        title: const Text("AI Meme Suggestion"),
        actions: [
          IconButton(
            icon: const Icon(Icons.message), // 將圖標改為訊息圖案
            tooltip: '新增對話',
            onPressed: _onNewChatPressed,
          ),
        ],
      ),
      drawer: CustomDrawer(
        chatHistory: _chatHistory,
        onHistoryItemSelected: _handleHistorySelection,
        onGoToTrending: _goToTrending,
        onGoToFavorite: _goToFavorite,
        onGoToSettings: _goToSettings,
        onDeleteChat: (int index) {
          setState(() {
            if (index >= 0 && index < _chatHistory.length) {
              _chatHistory.removeAt(index);
            }
          });
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ConversationWidget(
                messages: _messages,
                scrollController: _scrollController,
                imageSize: imageSize,
                onCopy: _copyOnTap,
                onToggleLike: _toggleLike,
                likedImages: _likedImages,
              ),
              if (mstate == MainState.uploaded ||
                  mstate == MainState.suggestionReady)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FolderSelection(
                    isAllSelected: _isAllSelected,
                    isMygoSelected: _isMygoSelected,
                    isFavoriteSelected: _isFavoriteSelected,
                    onAllChanged: (bool value) {
                      setState(() {
                        _isAllSelected = value;
                        if (_isAllSelected) {
                          _isMygoSelected = false;
                          _isFavoriteSelected = false;
                        }
                      });
                    },
                    onMygoChanged: (bool value) {
                      setState(() {
                        _isMygoSelected = value;
                        if (_isMygoSelected) {
                          _isAllSelected = false;
                        }
                      });
                    },
                    onFavoriteChanged: (bool value) {
                      setState(() {
                        _isFavoriteSelected = value;
                        if (_isFavoriteSelected) {
                          _isAllSelected = false;
                        }
                      });
                    },
                  ),
                ),
              (mstate != MainState.blank)
                  ? CustomToggleButton()
                  : Padding(padding: EdgeInsets.all(0.0)),
              if (mstate == MainState.conversation)
                MessageInput(
                  textController: _textController,
                  onSendPressed: _onSendPressed,
                ),
            ],
          ),
          if (mstate == MainState.uploaded ||
              mstate == MainState.suggestionReady)
            GoButton(onGoPressed: _onGoPressed),
          if (mstate == MainState.blank)
            UploadButton(
              onUploadPressed: _onUploadPressed,
              screenWidth: screenWidth,
            ),
        ],
      ),
    );
  }
}
