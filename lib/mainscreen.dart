import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/page/chat_page.dart';
import 'package:software_studio_final/page/upload_page.dart';
import 'package:software_studio_final/state/current_chat_notifier.dart';
import 'package:software_studio_final/widgets/custom_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

enum MainState { blank, uploaded, conversation }

class _MainScreenState extends State<MainScreen> {
  @override
  dispose() {
    context.read<CurrentChatNotifier>().clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final active = context.select<CurrentChatNotifier, bool>(
      (notifier) => notifier.currentChat?.active ?? false,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.secondaryContainer,
        title: const Text("AI Meme Suggestor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: '新增對話',
            onPressed: () => context.read<CurrentChatNotifier>().clear(),
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: !active ? UploadPage() : ChatPage(),
    );
  }
}
