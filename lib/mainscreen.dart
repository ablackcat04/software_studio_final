import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/settings.dart';
import 'package:software_studio_final/widgets/trending.dart';
// Keep your existing imports
// import 'mygo_folder.dart';
// import 'your_pictures_folder.dart';
// import 'mygogarbage_folder.dart';
// import 'yourpicturegarbage_folder.dart';
import 'widgets/favorite.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // --- Add GlobalKey for Scaffold ---
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // 儲存訊息列表
  // Example initial history for testing
  final List<List<Map<String, dynamic>>> _chatHistory = [
    [
      {'isUser': true, 'content': 'Old message 1'},
    ],
    [
      {
        'isUser': false,
        'content': ['assets/images/image1.jpg'],
      },
    ],
  ];
  final Set<String> _likedImages = {}; // 儲存被點擊愛心的圖片路徑
  bool _showGoButton = false; // 控制 GO 按鈕的顯示
  bool _hideButtons = false; // 控制加號和 GO 按鈕的隱藏
  bool _showSourceAndFolders = true; // 控制 Source 和資料夾按鈕的顯示

  // 新增狀態變數來控制 Checkbox 的選中狀態
  bool _isAllSelected = false;
  bool _isMygoSelected = false;
  bool _isFavoriteSelected = false;

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

  // --- Your existing methods (_onSendPressed, _onUploadPressed, _onGoPressed, _toggleLike, _onNewChatPressed) remain the same ---
  void _onSendPressed() {
    final userInput = _textController.text.trim();
    if (userInput.isNotEmpty) {
      setState(() {
        // 使用者的訊息
        _messages.add({'isUser': true, 'content': userInput});
        _textController.clear();

        // AI 的回應（模擬回傳五張圖片）
        _messages.add({
          'isUser': false,
          'content': [
            'assets/images/image1.jpg',
            'assets/images/image2.jpg',
            'assets/images/image3.jpg',
            'assets/images/image4.jpg',
            'assets/images/image5.jpg',
          ],
        });
        // Reset flags if needed when sending text
        _showGoButton = false;
        _hideButtons = false;
        _showSourceAndFolders = true;
      });
    }
  }

  void _onUploadPressed() {
    // 模擬上傳圖片的功能
    setState(() {
      _messages.add({'isUser': true, 'content': '圖片已上傳 ✅'});
      _showGoButton = true; // 顯示 GO 按鈕
      _hideButtons = true; // Hide add button immediately
      _showSourceAndFolders = true; // Keep folders visible initially if needed
    });
  }

  void _onGoPressed() {
    // 點擊 GO 按鈕後的行為
    setState(() {
      _showGoButton = false; // 隱藏 GO 按鈕
      _hideButtons = true; // 確保加號按鈕保持隱藏
      _showSourceAndFolders = false; // 隱藏 Source 和資料夾按鈕
      _messages.add({
        'isUser': false,
        'content': [
          'assets/images/image1.jpg',
          'assets/images/image2.jpg',
          'assets/images/image3.jpg',
          'assets/images/image4.jpg',
          'assets/images/image5.jpg',
        ],
      });
    });
  }

  void _toggleLike(String imagePath) {
    // 切換愛心按鈕的狀態
    setState(() {
      if (_likedImages.contains(imagePath)) {
        _likedImages.remove(imagePath); // 移除愛心
      } else {
        _likedImages.add(imagePath); // 添加愛心
      }
    });
  }

  void _onNewChatPressed() {
    // 創建新的對話
    setState(() {
      if (_messages.isNotEmpty) {
        // Deep copy the messages to avoid modifying history later
        _chatHistory.add(
          List<Map<String, dynamic>>.from(
            _messages.map((m) => Map<String, dynamic>.from(m)),
          ),
        );
      }
      _messages.clear(); // 清空當前聊天
      _textController.clear(); // Clear text field
      _likedImages.clear(); // Clear likes
      _showGoButton = false;
      _hideButtons = false;
      _showSourceAndFolders = true; // 顯示 Source 和資料夾按鈕
    });
  }

  // --- MODIFIED: This method now opens the Drawer ---
  void _onHistoryPressed() {
    // Use the GlobalKey to open the drawer
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.4; // 圖片寬度為螢幕寬度的 40%

    ThemeData theme = Theme.of(context);

    return Scaffold(
      // --- Assign the key to the Scaffold ---
      key: _scaffoldKey,

      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        title: const Text("AI Meme Suggestion"),
        actions: [
          // --- Add a History Button to trigger _onHistoryPressed ---
          IconButton(
            icon: const Icon(Icons.edit), // 右上角按鈕（筆形狀）
            tooltip: '新增對話',
            onPressed: _onNewChatPressed,
          ),
        ],
      ),

      // --- Your Drawer code (looks correct) ---
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Container(
              child: const Column(
                children: [
                  SizedBox(height: 12),
                  Text(
                    'History',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text("對話 ${index + 1}"),
                    onTap: () {
                      setState(() {
                        _messages.clear();
                        // Make sure to deep copy if needed, though often reading is fine
                        _messages.addAll(_chatHistory[index]);
                        // Reset UI state when loading history
                        _textController.clear();
                        _likedImages.clear();
                        _showGoButton = false;
                        _hideButtons = false;
                        _showSourceAndFolders = true;
                      });
                      Navigator.pop(context); // Close the drawer
                    },
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _goToTrending,
                      label: Text('Trending'),
                      icon: Icon(Icons.trending_up, size: 32),
                      iconAlignment: IconAlignment.start,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w200,
                        ),
                        // You can remove the alignment here as the Column's crossAxisAlignment will handle it
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _goToFavorite,
                      label: Text('Favorite '),
                      icon: Icon(Icons.favorite, size: 32),
                      iconAlignment: IconAlignment.start,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w200,
                        ),
                        // You can remove the alignment here as the Column's crossAxisAlignment will handle it
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _goToSettings,
                      label: Text('Settings '),
                      icon: Icon(Icons.settings, size: 32),
                      iconAlignment: IconAlignment.start,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w200,
                        ),
                        // You can remove the alignment here as the Column's crossAxisAlignment will handle it
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // --- Your Body code (Stack with Column, input field, etc.) ---
      // --- (Keep your existing body code here) ---
      body: Stack(
        children: [
          Column(
            children: [
              // 新增 Checkbox 區域
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ALL Checkbox
                    Column(
                      children: [
                        const Text('ALL'),
                        Checkbox(
                          value: _isAllSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAllSelected = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // MYGO Checkbox
                    Column(
                      children: [
                        const Text('MYGO'),
                        Checkbox(
                          value: _isMygoSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _isMygoSelected = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // FAVORITE Checkbox
                    Column(
                      children: [
                        const Text('FAVORITE'),
                        Checkbox(
                          value: _isFavoriteSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              _isFavoriteSelected = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 訊息列表
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message['isUser']) {
                      // User message
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
                              color:
                                  theme
                                      .colorScheme
                                      .primaryContainer, // Use theme color
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message['content']
                                  .toString(), // Handle text/upload confirmation
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
                      // Ensure content is a List<String>
                      final imagePaths =
                          (message['content'] is List)
                              ? List<String>.from(message['content'])
                              : <String>[]; // Handle potential type errors

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: Align(
                          // Align the whole block left
                          alignment: Alignment.centerLeft,
                          child: Container(
                            // Optional: Add background for AI messages
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color:
                                  theme
                                      .colorScheme
                                      .surfaceContainerHighest, // Use theme color
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Wrap(
                              // Use Wrap for better layout if many images
                              spacing: 8.0, // Horizontal space between items
                              runSpacing: 8.0, // Vertical space between lines
                              children:
                                  imagePaths.map((imagePath) {
                                    return Column(
                                      // Column for image and button
                                      mainAxisSize:
                                          MainAxisSize
                                              .min, // Take minimum space
                                      children: [
                                        Image.asset(
                                          imagePath,
                                          width: imageSize,
                                          height: imageSize,
                                          fit:
                                              BoxFit.cover, // Or BoxFit.contain
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            // Handle image load errors
                                            return Container(
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
                                        IconButton(
                                          icon: Icon(
                                            _likedImages.contains(imagePath)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color:
                                                _likedImages.contains(imagePath)
                                                    ? Colors
                                                        .pinkAccent // Use a more vibrant pink
                                                    : Colors.grey,
                                            size: 24, // Adjust size if needed
                                          ),
                                          visualDensity:
                                              VisualDensity
                                                  .compact, // Reduce padding around icon
                                          padding:
                                              EdgeInsets
                                                  .zero, // Remove default padding
                                          constraints:
                                              BoxConstraints(), // Remove default constraints
                                          onPressed:
                                              () => _toggleLike(imagePath),
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
              // 打字框
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: "輸入提示...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              24,
                            ), // More rounded
                            borderSide: BorderSide.none, // Remove border line
                          ),
                          filled: true, // Add fill color
                          fillColor:
                              theme
                                  .colorScheme
                                  .surfaceVariant, // Use theme color
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted:
                            (_) => _onSendPressed(), // Send on keyboard done
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
              ),
            ],
          ),
          // Central GO button
          if (_showGoButton)
            Positioned.fill(
              // Use Positioned.fill to easily center
              child: Container(
                color: Colors.black.withOpacity(
                  0.1,
                ), // Optional: Dim background
                child: Center(
                  child: ElevatedButton(
                    onPressed: _onGoPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Adjust rounding
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 64,
                        vertical: 24, // Reduced vertical padding slightly
                      ),
                    ),
                    child: Text(
                      "GO!",
                      style: TextStyle(
                        fontSize: 36, // Slightly smaller
                        fontWeight: FontWeight.bold,
                        color:
                            theme
                                .colorScheme
                                .onTertiaryContainer, // Adjust color if needed
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Top-left Add button and text
          if (!_hideButtons)
            Positioned(
              top: 20, // Adjust position as needed
              left: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        // Add shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _onUploadPressed,
                      color:
                          theme
                              .colorScheme
                              .onTertiaryContainer, // Adjust if needed
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
                      ), // More relevant icon
                      iconSize: 36, // Adjust size
                      padding: EdgeInsets.all(12), // Adjust padding
                    ),
                  ),
                  SizedBox(width: 16),
                  SizedBox(
                    width: screenWidth * 0.6, // Adjust width relative to screen
                    child: Text(
                      'Upload screenshots to provide context!', // Clearer text
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
