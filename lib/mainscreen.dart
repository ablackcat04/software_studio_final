// main_screen.dart (Updated)
import 'package:flutter/material.dart';
import 'package:software_studio_final/models/settings.dart';
import 'package:software_studio_final/widgets/customDrawer.dart';
import 'package:software_studio_final/widgets/favorite.dart'; // Keep widget imports here if MainScreen navigates
import 'package:software_studio_final/widgets/settings.dart';
import 'package:software_studio_final/widgets/toggleButton.dart';
import 'package:software_studio_final/widgets/trending.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum MainState { blank, uploaded, conversation }

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final List<List<Map<String, dynamic>>> _chatHistory = [
    // ... (keep your example history)
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

  final ScrollController _scrollController = ScrollController();

  MainState mstate = MainState.blank;

  @override
  void dispose() {
    // 5. Dispose the controller
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Use addPostFrameCallback to scroll after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if the controller is attached to a scroll view and has dimensions
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Scroll to the bottom
          duration: const Duration(
            milliseconds: 200,
          ), // Adjust duration as needed
          curve: Curves.easeOut, // Adjust curve as needed
        );
      }
    });
  }

  void _copyOnTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // --- Navigation Methods (remain in MainScreen as they use its context) ---
  void _goToSettings() {
    // Navigator.pop(context); // Close drawer before navigating
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
    // Navigator.pop(context); // Close drawer before navigating
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FavoritePage()),
    );
  }

  void _goToTrending() {
    // Navigator.pop(context); // Close drawer before navigating
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrendingPage()),
    );
  }

  // --- Method to handle history item selection ---
  void _handleHistorySelection(int index) {
    if (index < 0 || index >= _chatHistory.length) return; // Bounds check

    setState(() {
      _messages.clear();
      // Deep copy the selected history to the current messages
      // Ensure content lists are also copied if they exist
      _messages.addAll(
        _chatHistory[index].map((msg) {
          final newMsg = Map<String, dynamic>.from(msg);
          if (newMsg['content'] is List) {
            newMsg['content'] = List.from(newMsg['content']);
          }
          return newMsg;
        }),
      );

      // Reset UI state when loading history
      _textController.clear();
      _likedImages.clear(); // Clear likes for the new chat context
      mstate = MainState.conversation;
    });
    // Note: Navigator.pop(context) is called within the CustomDrawer's onTap
  }

  // --- Other methods (_onSendPressed, _onUploadPressed, etc.) remain the same ---
  void _onSendPressed() {
    final userInput = _textController.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        _messages.add({'isUser': true, 'content': userInput});
        _textController.clear();
      });
      _scrollToBottom();
      setState(() {
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
    } else {
      setState(() {
        _messages.add({'isUser': true, 'content': 'regenerate'});
        _textController.clear();
      });
      _scrollToBottom();
      setState(() {
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

  void _onUploadPressed() {
    setState(() {
      _messages.add({'isUser': true, 'content': '圖片已上傳 ✅'});
      mstate = MainState.uploaded;
    });
  }

  void _onGoPressed() {
    setState(() {
      mstate = MainState.conversation;
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

  void _toggleLike(String imagePath) {
    setState(() {
      if (_likedImages.contains(imagePath)) {
        _likedImages.remove(imagePath);
      } else {
        _likedImages.add(imagePath);
      }
    });
  }

  void _onNewChatPressed() {
    setState(() {
      if (_messages.isNotEmpty) {
        // Deep copy necessary to prevent modification issues
        _chatHistory.add(
          List<Map<String, dynamic>>.from(
            _messages.map((m) {
              final newMsg = Map<String, dynamic>.from(m);
              if (newMsg['content'] is List) {
                newMsg['content'] = List.from(
                  newMsg['content'],
                ); // Deep copy list content too
              }
              return newMsg;
            }),
          ),
        );
      }
      _messages.clear();
      _textController.clear();
      _likedImages.clear();
      mstate = MainState.blank;
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
            icon: const Icon(Icons.edit),
            tooltip: '新增對話',
            onPressed: _onNewChatPressed,
          ),
        ],
      ),

      // --- Use the new CustomDrawer ---
      drawer: CustomDrawer(
        chatHistory: _chatHistory, // Pass the history list
        onHistoryItemSelected:
            _handleHistorySelection, // Pass the handler method
        onGoToTrending: _goToTrending, // Pass navigation methods
        onGoToFavorite: _goToFavorite,
        onGoToSettings: _goToSettings,
      ),

      // --- Body remains the same ---
      body: Stack(
        children: [
          Column(
            children: [
              // 訊息列表
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message['isUser']) {
                      // User message bubble
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['content'].toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // AI response (images)
                      final imagePaths =
                          (message['content'] is List)
                              ? List<String>.from(message['content'])
                              : <String>[];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children:
                                  imagePaths.map((imagePath) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          imagePath,
                                          width: imageSize,
                                          height: imageSize,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              // Placeholder on error
                                              width: imageSize,
                                              height: imageSize,
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.grey[600],
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          width: imageSize,
                                          child: Center(
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize
                                                      .min, // <--- This keeps the Row just as wide as needed
                                              children: [
                                                IconButton(
                                                  onPressed: _copyOnTap,
                                                  icon: Icon(Icons.copy),
                                                ),
                                                SizedBox(
                                                  width: 8,
                                                ), // Space between the icons
                                                IconButton(
                                                  icon: Icon(
                                                    _likedImages.contains(
                                                          imagePath,
                                                        )
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color:
                                                        _likedImages.contains(
                                                              imagePath,
                                                            )
                                                            ? Colors.pinkAccent
                                                            : Colors.grey,
                                                    size: 24,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed:
                                                      () => _toggleLike(
                                                        imagePath,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // 只有在 _showCheckboxes 為 true 時顯示 Checkbox 區域
              if (mstate == MainState.uploaded)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ALL Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isAllSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _isAllSelected = value ?? false;
                                if (_isAllSelected ) {
                                  _isMygoSelected = false; // 取消 MYGO 的勾選
                                  _isFavoriteSelected = false; // 取消 FAVORITE 的勾選
                              }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.folder, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('ALL'),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // MYGO Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isMygoSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _isMygoSelected = value ?? false;
                              if (_isMygoSelected) {
                                  _isAllSelected = false; // 取消 ALL 的勾選
                              }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.folder, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('MYGO'),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // FAVORITE Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isFavoriteSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                _isFavoriteSelected = value ?? false;
                                if (_isFavoriteSelected) {
                                  _isAllSelected = false; // 取消 ALL 的勾選
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.folder, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('FAVORITE'),
                        ],
                      ),
                    ],
                  ),
                ),
              (mstate != MainState.blank)
                  ? CustomToggleButton()
                  : Padding(padding: EdgeInsets.all(0.0)),
              (mstate == MainState.conversation)
                  ? Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 16.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: "輸入提示...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onSubmitted: (_) => _onSendPressed(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: theme.colorScheme.primary,
                          iconSize: 28,
                          onPressed: _onSendPressed,
                        ),
                      ],
                    ),
                  )
                  : Padding(padding: const EdgeInsets.all(4.0)),
            ],
          ),
          // Central GO button (conditionally shown)
          if (mstate == MainState.uploaded)
            Positioned.fill(
              child: Container(
                // color: Colors.black.withOpacity(0.1),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _onGoPressed();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 24,
                      ),
                    ),
                    child: Text(
                      "GO!",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Top-left Add button and text (conditionally shown)
          if (mstate == MainState.blank)
            Positioned(
              top: 20,
              left: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    // Decorated Add button
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _onUploadPressed,
                      color: theme.colorScheme.onTertiaryContainer,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      iconSize: 80,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    // Context text
                    width: screenWidth * 0.6,
                    child: Text(
                      'Upload conversation screenshots to provide context!',
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
