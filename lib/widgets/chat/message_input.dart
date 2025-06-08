import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onSendPressed;
  final VoidCallback? onStopPressed; // ADDED: Callback for stopping
  final bool isLoading;

  const MessageInput({
    super.key,
    required this.textController,
    required this.onSendPressed,
    this.onStopPressed, // ADDED
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Describe your meme...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => onSendPressed(),
              enabled: !isLoading, // Disable text field while loading
            ),
          ),
          const SizedBox(width: 8),
          // CONDITIONALLY SHOW a stop button or the send button
          if (isLoading)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              onPressed: onStopPressed,
              tooltip: 'Stop Generation',
            )
          else
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSendPressed,
              tooltip: 'Send',
            ),
        ],
      ),
    );
  }
}
