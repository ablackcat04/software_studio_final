// lib/pages/upload_page.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/service/ai_suggestion_service.dart'; // IMPORT THE SERVICE
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart';
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';

class UploadPage extends StatefulWidget {
  final void Function(int) onNavigate;

  const UploadPage({super.key, required this.onNavigate});

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  bool uploaded = false;

  // ADDED: Create an instance of the service
  final AiSuggestionService _aiService = AiSuggestionService();

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<void> _onUpload() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final guideNotifier = Provider.of<GuideNotifier>(context, listen: false);
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key not found.')));
      setState(() => _isLoading = false);
      return;
    }
    if (image == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => uploaded = true);

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: false, content: '圖片已上傳 ✅，可以趁機打字'),
    );
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '正在分析圖片並生成建議指南...'),
    );

    try {
      final Uint8List imageBytes = await image.readAsBytes();

      chatHistoryNotifier.currentChatHistory.setImage(imageBytes);

      final aiGuideText = await _aiService.generateGuide(
        imageBytes: imageBytes,
        mimeType: image.mimeType,
        intension:
            "This is the first generation, no intension provided now, do your best!",
      );

      if (aiGuideText != null && aiGuideText.isNotEmpty) {
        guideNotifier.setGuide(aiGuideText);
        chatHistoryNotifier.currentChatHistory.setGuide(aiGuideText);
        chatHistoryNotifier.addMessage(
          ChatMessage(
            isAI: true,
            content: chatHistoryNotifier.currentChatHistory.guide ?? '',
          ),
        );
      } else {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: true, content: '無法生成建議指南，模型未返回文本。'),
        );
      }
    } catch (e) {
      print('Error generating guide with Gemini: $e');
      final errorMessage = '生成建議指南時發生錯誤：\n${e.toString()}';
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: errorMessage),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating guide: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSendMessage() async {
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

    final userInput = _messageController.text.trim();

    if (userInput.isNotEmpty) {
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: false, content: userInput),
      );
    }
    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '正在尋找最適合的梗圖...'),
    );

    try {
      final guide = guideNotifier.guide;
      final currentAIMode = guideNotifier.mode;
      final optionNumber = settingsNotifier.settings.optionNumber;

      final List<MemeSuggestion> suggestions = await _aiService
          .getMemeSuggestions(
            guide: guide,
            userInput: userInput,
            aiMode: currentAIMode,
            optionNumber: optionNumber,
            notifier: chatHistoryNotifier,
          );

      suggestions.map((suggestion) => suggestion.imagePath).toList();

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: "給你的梗圖建議:", suggestions: suggestions),
      );

      chatHistoryNotifier.currentSetup();
      widget.onNavigate.call(1);
    } catch (e) {
      print('Error getting suggestions from service: $e');
      final errorMessage = '生成建議時發生錯誤：\n${e.toString()}';
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: errorMessage),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('錯誤: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(context);
    final messages = chatHistoryNotifier.currentChatHistory.messages;

    return Scaffold(
      appBar: AppBar(title: const Text('上傳圖片')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
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
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child:
                _isLoading
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
                        onPressed: _onUpload,
                        color: theme.colorScheme.onTertiaryContainer,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        iconSize: screenWidth * 0.6,
                        padding: const EdgeInsets.all(12),
                        tooltip: '上傳對話截圖',
                      ),
                    )
                    : const SizedBox(),
          ),
          if (!uploaded)
            SizedBox(
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
            ),
          const SizedBox(height: 16),
          if (uploaded) AIModeSwitch(),
          if (uploaded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '輸入訊息以獲得更精準的建議...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      ),
                      onSubmitted: (_) => _isLoading ? null : _onSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading ? null : _onSendMessage,
                    icon: const Icon(Icons.send),
                    color: theme.colorScheme.primary,
                    disabledColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ],
              ),
            )
          else
            SizedBox(height: screenHeight / 5),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
