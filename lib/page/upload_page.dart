import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart';
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';

// Convert UploadPage to a StatefulWidget
class UploadPage extends StatefulWidget {
  final void Function(int) onNavigate;

  const UploadPage({super.key, required this.onNavigate});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false; // Add loading state

  bool uploaded = false;

  static const String imageAnalysisPrompt = """
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

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<void> _onUpload() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Use context from the state
    final guideNotifier = Provider.of<GuideNotifier>(
      context,
      listen: false,
    ); // Use listen: false as we only call setGuide
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    uploaded = true;

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key not found.')));
      setState(() {
        _isLoading = false;
      }); // Stop loading on API key error
      return;
    }
    if (image == null) {
      setState(() {
        _isLoading = false;
      }); // Stop loading if no image is picked
      return;
    }

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: false, content: '圖片已上傳 ✅', images: []),
    ); // User action
    // Add an immediate message indicating processing started
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '正在分析圖片並生成建議指南...'),
    );

    try {
      final Uint8List imageBytes = await image.readAsBytes();
      String mimeType = image.mimeType ?? 'image/jpeg';
      if (image.mimeType == null) {
        final String extension = image.path.split('.').last.toLowerCase();
        if (extension == 'png')
          mimeType = 'image/png';
        else if (extension == 'jpg' || extension == 'jpeg')
          mimeType = 'image/jpeg';
        // Add other types as needed
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash-preview-04-17',
        apiKey: apiKey,
      );

      final promptTextPart = TextPart(imageAnalysisPrompt);
      final imagePart = DataPart(mimeType, imageBytes);
      final content = [
        Content.multi([promptTextPart, imagePart]),
      ];

      // This is the potentially long-running part
      final GenerateContentResponse response = await model.generateContent(
        content,
      );
      final aiGuideText = response.text;

      // Optional: Find and remove the "正在分析圖片..." message before adding the result
      // This requires ChatHistoryNotifier to support removing specific messages or the last one.
      // For simplicity, let's just add the new message.
      // chatHistoryNotifier.removeLastMessage(); // Example if supported

      if (aiGuideText != null && aiGuideText.isNotEmpty) {
        guideNotifier.setGuide(aiGuideText); // Store the guide
        // Replace or add the guide message
        // Find the '正在分析圖片...' message and update it or add a new one
        // A simple approach is to just add the new message and let the history build up
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: aiGuideText),
        );

        _isLoading = false;

        // Optionally navigate *after* the guide is ready
        // widget.onNavigate.call(1); // <-- Only navigate if generation was successful?
      } else {
        // Find the '正在分析圖片...' message and update it
        // chatHistoryNotifier.updateLastMessage('無法生成建議指南，模型未返回文本。'); // Example if supported
        // Or just add a new error message
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: '無法生成建議指南，模型未返回文本。'),
        );
      }
    } catch (e) {
      print('Error generating guide with Gemini: $e');
      // Find the '正在分析圖片...' message and update it
      // chatHistoryNotifier.updateLastMessage('生成建議指南時發生錯誤：\n${e.toString()}'); // Example if supported
      // Or just add a new error message
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: '生成建議指南時發生錯誤：\n${e.toString()}'),
      );
      // Show a SnackBar for more immediate user feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating guide: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading state back to false
      });
    }
  }

  void _onSendMessage() {
    // Remove BuildContext
    final message = _messageController.text.trim();
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
    _messageController.clear();

    // 根據 settings 中的 optionNumber 決定圖片數量
    final settingsNotifier = Provider.of<SettingsNotifier>(
      context,
      listen: false,
    );
    final optionNumber = settingsNotifier.settings.optionNumber;
    final List<String> images = List.generate(
      optionNumber,
      (index) => 'assets/images/image${index + 1}.jpg',
    );

    // 模擬進入聊天畫面

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '這是AI的回覆', images: images),
    );
    chatHistoryNotifier.currentSetup();

    // 切換到聊天畫面
    Navigator.pushNamed(context, '/chat');

    // 切換到下一個頁面 (This should probably only happen AFTER a guide is generated or maybe based on other logic)
    // For now, keeping it here as per original code, but consider if this navigation should be conditional.
    widget.onNavigate.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    // Listen to chat history changes to update the list view
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );
    final messages = chatHistoryNotifier.currentChatHistory.messages;

    return Scaffold(
      appBar: AppBar(title: const Text('上傳圖片')),
      body: Column(
        children: [
          // Chat history
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                // Basic list tile - consider adding more styling later
                return ListTile(
                  title: Text(
                    message.isAI
                        ? 'AI: ${message.content}'
                        : '使用者: ${message.content}',
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isAI ? Colors.grey[800] : Colors.blue[800],
                    ),
                  ),
                  // If you added timestamps to ChatMessage, you could add a subtitle
                  // subtitle: Text(message.timestamp.toString()),
                );
              },
            ),
          ),

          // Upload button area
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
            ), // Add some padding
            child:
                _isLoading // Show loading indicator when loading
                    ? const CircularProgressIndicator()
                    : !uploaded
                    ? Container(
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
                        onPressed: _onUpload, // Call the stateful method
                        color: theme.colorScheme.onTertiaryContainer,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        iconSize:
                            screenWidth *
                            0.6, // Maybe make icon slightly smaller for wider screens?
                        padding: const EdgeInsets.all(12),
                        tooltip: '上傳對話截圖', // Add a tooltip
                      ),
                    )
                    : SizedBox(),
          ),

          !uploaded
              ? SizedBox(
                width: screenWidth * 0.9,
                child: Text(
                  'Upload conversation screenshots to provide context!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  softWrap: true,
                ),
              )
              : SizedBox(),
          const SizedBox(height: 16),
          uploaded ? AIModeSwitch() : SizedBox(),
          // Input field
          uploaded
              ? Padding(
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
                            borderSide: BorderSide.none, // No border line
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ), // Adjust padding
                        ),
                        // Allow submitting with Enter key (optional)
                        onSubmitted: (text) => _onSendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Disable send button if loading? Maybe not strictly necessary.
                    IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _onSendMessage, // Disable send button while loading image/guide
                      icon: const Icon(Icons.send),
                      color: theme.colorScheme.primary,
                      disabledColor: theme.colorScheme.onSurface.withOpacity(
                        0.5,
                      ), // Dim disabled button
                    ),
                  ],
                ),
              )
              : SizedBox(height: screenHeight / 5),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose(); // Dispose controller
    super.dispose();
  }
}
