import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/models/settings.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/models/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/customDrawer.dart';
import 'package:software_studio_final/widgets/favorite.dart';
import 'package:software_studio_final/widgets/settings.dart';
import 'package:software_studio_final/widgets/toggleButton.dart';
import 'package:software_studio_final/widgets/trending.dart';
import 'package:software_studio_final/widgets/folder.dart';
import 'package:software_studio_final/widgets/conversation.dart';
import 'package:software_studio_final/widgets/uploadbutton.dart'; // 引入 UploadButton
import 'package:software_studio_final/widgets/gobutton.dart'; // 引入 GoButton
import 'package:software_studio_final/widgets/MessageInput.dart'; // 引入 MessageInput

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum MainState { blank, uploaded, conversation }

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
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

  void _onSendPressed(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    final userInput = _textController.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        chatHistoryNotifier.addMessage(
          ChatMessage(isAI: false, content: userInput, images: []),
        );
        _textController.clear();
      });
      _scrollToBottom();
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
    }
  }

  void _onUploadPressed(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    setState(() {
      chatHistoryNotifier.addMessage(
        ChatMessage(isAI: false, content: '圖片已上傳 ✅', images: []),
      );
      mstate = MainState.uploaded;
    });
  }

  void _onGoPressed(BuildContext context) {
    setState(() {
      mstate = MainState.conversation;
    });
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
  }

  void _onNewChatPressed(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );

    chatHistoryNotifier.newChat();
    setState(() {
      _textController.clear();
      _likedImages.clear();
      mstate = MainState.blank;
    });
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
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

  void _handleHistorySelection(BuildContext context, int index) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );

    chatHistoryNotifier.switchCurrentByIndex(index);
    setState(() {
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
            onPressed: () => _onNewChatPressed(context),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onHistoryItemSelected:
            (index) => _handleHistorySelection(context, index),
        onGoToTrending: _goToTrending,
        onGoToFavorite: _goToFavorite,
        onGoToSettings: _goToSettings,
        onDeleteChat: (int index) {
          final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
            context,
            listen: false,
          );
          chatHistoryNotifier.removeChatHistoryByIndex(index);
        },
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ConversationWidget(
                scrollController: _scrollController,
                imageSize: imageSize,
                onCopy: _copyOnTap,
                onToggleLike: _toggleLike,
                likedImages: _likedImages,
              ),
              if (mstate == MainState.uploaded)
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
                  onSendPressed: () => _onSendPressed(context),
                ),
            ],
          ),
          if (mstate == MainState.uploaded)
            GoButton(onGoPressed: () => _onGoPressed(context)),
          if (mstate == MainState.blank)
            UploadButton(
              onUploadPressed: () => _onUploadPressed(context),
              screenWidth: screenWidth,
            ),
        ],
      ),
    );
  }
}
