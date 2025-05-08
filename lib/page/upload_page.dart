import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/model/chat_history.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';

class UploadPage extends StatelessWidget {
  final void Function(int) onNavigate;

  const UploadPage({super.key, required this.onNavigate});


  void _onUpload(BuildContext context) {
    final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    chatHistoryNotifier.addMessage(
      ChatMessage(isAI: false, content: '圖片已上傳 ✅', images: []),
    );
    onNavigate.call(1);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
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
            onPressed: () => _onUpload(context),
            color: theme.colorScheme.onTertiaryContainer,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            iconSize: 80,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
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
    );
  }
}
