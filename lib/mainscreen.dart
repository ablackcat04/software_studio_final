import 'package:flutter/material.dart';
import 'mygo_folder.dart'; // 引入 MyGO 資料夾頁面
import 'your_pictures_folder.dart'; // 引入 Your Pictures 資料夾頁面
import 'mygogarbage_folder.dart'; // 引入 MyGO Garbage 資料夾頁面
import 'yourpicturegarbage_folder.dart'; // 引入 Your Pictures Garbage 資料夾頁面

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = []; // 儲存訊息列表
  final List<List<Map<String, dynamic>>> _chatHistory = []; // 儲存歷史聊天記錄
  final Set<String> _likedImages = {}; // 儲存被點擊愛心的圖片路徑
  bool _showGoButton = false; // 控制 GO 按鈕的顯示
  bool _hideButtons = false; // 控制加號和 GO 按鈕的隱藏
  bool _showSourceAndFolders = true; // 控制 Source 和資料夾按鈕的顯示

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
      });
    }
  }

  void _onUploadPressed() {
    // 模擬上傳圖片的功能
    setState(() {
      _messages.add({'isUser': true, 'content': '圖片已上傳 ✅'});
      _showGoButton = true; // 顯示 GO 按鈕
    });
  }

  void _onGoPressed() {
    // 點擊 GO 按鈕後的行為
    setState(() {
      _showGoButton = false; // 隱藏 GO 按鈕
      _hideButtons = true; // 隱藏加號按鈕
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

  void _onHistoryPressed() {
    // 顯示歷史聊天記錄
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("歷史聊天記錄"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("對話 ${index + 1}"),
                  onTap: () {
                    // 加載選中的歷史聊天記錄
                    setState(() {
                      _messages.clear();
                      _messages.addAll(_chatHistory[index]);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("關閉"),
            ),
          ],
        );
      },
    );
  }

  void _onNewChatPressed() {
    // 創建新的對話
    setState(() {
      if (_messages.isNotEmpty) {
        _chatHistory.add(List.from(_messages)); // 保存當前聊天記錄
      }
      _messages.clear(); // 清空當前聊天
      _showGoButton = false;
      _hideButtons = false;
      _showSourceAndFolders = true; // 顯示 Source 和資料夾按鈕
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.4; // 圖片寬度為螢幕寬度的 40%

    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        title: const Text("AI Meme Suggestion"),
        leading: IconButton(
          icon: const Icon(Icons.history), // 左上角按鈕（歷史記錄）
          onPressed: _onHistoryPressed,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit), // 右上角按鈕（筆形狀）
            onPressed: _onNewChatPressed,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 訊息列表
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    if (message['isUser']) {
                      // 使用者的訊息
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['content'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // AI 的回應（圖片）
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // 確保圖片靠左對齊
                          children:
                              (message['content'] as List<String>).map((
                                imagePath,
                              ) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      imagePath,
                                      width: imageSize,
                                      height: imageSize,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        _likedImages.contains(imagePath)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color:
                                            _likedImages.contains(imagePath)
                                                ? Colors.pink
                                                : Colors.grey,
                                      ),
                                      onPressed: () => _toggleLike(imagePath),
                                    ),
                                  ],
                                );
                              }).toList(),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _onSendPressed,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 中央的 GO 按鈕
          if (_showGoButton)
            Column(
              children: [
                Expanded(child: Container()), // Takes up available space
                Column(
                  children: [
                    Center(
                      child: ElevatedButton(
                        onPressed: _onGoPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 64,
                            vertical: 32,
                          ),
                        ),
                        child: Text(
                          "GO!",
                          style: TextStyle(
                            fontSize: 40,
                            color: theme.colorScheme.onTertiaryFixed,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ],
            ),
          // 左上方的加號按鈕
          if (!_hideButtons)
            Positioned(
              top: 60, // 稍稍往下移
              left: 40, // 稍稍往右移
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: _onUploadPressed,
                      color: theme.colorScheme.onTertiaryFixed,
                      icon: Icon(Icons.add),
                      iconSize: 48,
                    ),
                  ),
                  SizedBox(width: 20),
                  SizedBox(
                    width: 300, // Assign a fixed width here
                    child: Text(
                      'Let us know the context by uploading screenshots!',
                      style: TextStyle(fontSize: 16),
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
