// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:software_studio_final/state/chat_history_notifier.dart';
// import 'package:software_studio_final/widgets/chat/ai_message.dart';
// import 'package:software_studio_final/widgets/chat/user_message.dart';

// class Chat extends StatelessWidget {
//   final ScrollController _scrollController = ScrollController();

//   Chat({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
//       context,
//       listen: true,
//     );
//     final messages = chatHistoryNotifier.currentChatHistory.messages;

//     return Expanded(
//       child: ListView.builder(
//         controller: _scrollController,
//         itemCount: messages.length,
//         itemBuilder: (context, index) {
//           final message = messages[index];

//           final suggestions = message.getSuggestions();

//           if (message.isAI) {
//             return AIMessage(suggestions: suggestions);
//           } else {
//             return UserMessage(messageContent: message.content);
//           }
//         },
//       ),
//     );
//   }
// }
