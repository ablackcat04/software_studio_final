import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/page/chat_page.dart';
import 'package:software_studio_final/page/go_page.dart';
import 'package:software_studio_final/page/upload_page.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/widgets/custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum MainState { blank, uploaded, conversation }

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageController = PageController(initialPage: 0);
  
  void _onNewChatPressed() {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    chatHistoryNotifier.newChat();
    _pageController.jumpToPage(0);
  }

  void _handleHistorySelection(BuildContext context, int index) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );

    chatHistoryNotifier.switchCurrentByIndex(index);
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: true,
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        title: const Text("AI Meme Suggestor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.message), // 將圖標改為訊息圖案
            tooltip: '新增對話',
            onPressed: () => _onNewChatPressed(),
          ),
        ],
      ),
      drawer: CustomDrawer(
        onHistoryItemSelected:
            (index) => _handleHistorySelection(context, index),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children:
            !chatHistoryNotifier.currentChatHistory.hasSetup
                ? [
                  UploadPage(onNavigate: _pageController.jumpToPage),
                  GoPage(),
                  ChatPage(),
                ]
                : [ChatPage()],
      ),
    );
  }
}
