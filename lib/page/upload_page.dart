import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/service/ai_suggestion_service.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
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
  bool _analysisCompleted = false;
  Uint8List? _uploadedImage;

  // ADDED: State for cancellation
  CancellationToken? _cancellationToken;
  final AiSuggestionService _aiService = AiSuggestionService();

  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ADDED: Handler to trigger cancellation
  void _onStopPressed() {
    if (_cancellationToken != null) {
      print("Stop generation requested by user on upload page.");
      _cancellationToken!.cancel();
    }
  }

  Future<void> _onUpload() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _cancellationToken =
          CancellationToken(); // Create a token for this operation
    });

    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final ImagePicker picker = ImagePicker();

    XFile? image;
    try {
      image = await picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      print("Image picking cancelled or failed: $e");
    }

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key not found.')));
      setState(() {
        _isLoading = false;
        _cancellationToken = null;
      });
      return;
    }
    // If user cancels the picker, image will be null
    if (image == null) {
      setState(() {
        _isLoading = false;
        _cancellationToken = null;
      });
      return;
    }

    final imageBytes = await image.readAsBytes();
    setState(() {
      uploaded = true;
      _uploadedImage = imageBytes;
    });

    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: false, content: '圖片已上傳 ✅，可以趁機打字'),
    );
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '正在分析圖片並生成建議指南...'),
    );

    try {
      chatHistoryNotifier.currentChatHistory.setImage(imageBytes);

      final aiGuideText = await _aiService.generateGuide(
        imageBytes: imageBytes,
        mimeType: image.mimeType,
        intension:
            "This is the first generation, no intension provided now, do your best!",
        selectedMode: chatHistoryNotifier.mode,
        cancellationToken: _cancellationToken!, // Pass the token
      );

      if (aiGuideText != null && aiGuideText.isNotEmpty) {
        setState(() {
            _analysisCompleted = true; // 更新分析完成狀態
        });
        chatHistoryNotifier.removeMessage('圖片已上傳 ✅，可以趁機打字');
        chatHistoryNotifier.removeMessage('正在分析圖片並生成建議指南...');
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
      // ADDED: Catch cancellation exception
    } on CancellationException catch (_) {
      print('Guide generation cancelled.');
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: '指南生成已取消。'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Generation stopped.')));
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
      setState(() {
        _isLoading = false;
        _cancellationToken = null; // Clean up the token
      });
    }
  }

  Future<void> _onSendMessage() async {
    if (_isLoading) return;

    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
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

    setState(() {
      _isLoading = true;
      _cancellationToken =
          CancellationToken(); // Create a token for this operation
    });
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: true, content: '正在尋找最適合的梗圖...'),
    );

    try {
      final guide = chatHistoryNotifier.currentChatHistory.guide;
      final currentAIMode = chatHistoryNotifier.mode;
      final optionNumber = settingsNotifier.settings.optionNumber;

      final List<MemeSuggestion>
      suggestions = await _aiService.getMemeSuggestions(
        guide:
            guide ??
            'no guide now, please throw invalid result to warn the developer',
        userInput: userInput,
        aiMode: currentAIMode,
        optionNumber: optionNumber,
        notifier: chatHistoryNotifier,
        cancellationToken: _cancellationToken!, // Pass the token
      );

      suggestions.map((suggestion) => suggestion.imagePath).toList();

      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: "給你的梗圖建議:", suggestions: suggestions),
      );

      chatHistoryNotifier.currentSetup();
      widget.onNavigate.call(1);
      // ADDED: Catch cancellation exception
    } on CancellationException catch (_) {
      print('Meme suggestion cancelled.');
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: true, content: '梗圖建議已取消。'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Suggestion stopped.')));
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
      setState(() {
        _isLoading = false;
        _cancellationToken = null; // Clean up the token
      });
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
      appBar: _analysisCompleted ? null : AppBar(title: const Text('上傳圖片')),
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
                        : '用戶: ${message.content}',
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isAI ? Colors.grey[800] : Colors.blue[800],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_uploadedImage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.memory(
                _uploadedImage!,
                width: screenWidth * 0.8,
                height: screenHeight * 0.4,
                fit: BoxFit.cover,
              ),
            ),
          // MODIFIED: Show stop button during initial upload
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child:
                _isLoading && !uploaded
                    ? Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _onStopPressed,
                          icon: const Icon(Icons.stop),
                          label: const Text('停止'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                    )
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
                      // 移除禁用邏輯，讓輸入框始終可用
                      decoration: InputDecoration(
                        hintText: '輸入訊息已獲得精準的建議...',
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
                      onSubmitted: (_) => _onSendMessage(), // 始終允許提交
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 按鈕狀態切換保持不變
                  if (_isLoading)
                    IconButton(
                      onPressed: _onStopPressed,
                      icon: const Icon(Icons.stop_circle_outlined),
                      color: Colors.red.shade700,
                      tooltip: '停止',
                    )
                  else
                    IconButton(
                      onPressed: _onSendMessage,
                      icon: const Icon(Icons.send),
                      color: theme.colorScheme.primary,
                      tooltip: '發送',
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
    // ADDED: Cancel any ongoing operations when the page is disposed
    _cancellationToken?.cancel();
    _messageController.dispose();
    super.dispose();
  }
}
