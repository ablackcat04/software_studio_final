import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:software_studio_final/models/settings.dart';
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

  Future<void> _onUploadPressed() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _messages.add({'isUser': true, 'content': '圖片已上傳 ✅'});
        _messages.add({
          'isUser': false,
          'content': [image.path],
        });
        mstate = MainState.uploaded;
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
                  onSendPressed: _onSendPressed,
                ),
            ],
          ),
          if (mstate == MainState.uploaded) GoButton(onGoPressed: _onGoPressed),
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
