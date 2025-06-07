// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:software_studio_final/model/chat_history.dart';
// import 'package:software_studio_final/state/chat_history_notifier.dart';
// import 'package:software_studio_final/state/settings_notifier.dart';
// import 'package:software_studio_final/widgets/chat/go_button.dart';
// import 'package:software_studio_final/widgets/chat/ai_mode_switch.dart';
// import 'package:software_studio_final/widgets/chat/user_message.dart';

// class GoPage extends StatefulWidget {
//   const GoPage({super.key});

//   @override
//   State<GoPage> createState() => _GoPageState();
// }

// class _GoPageState extends State<GoPage> {
//   bool _isLoading = false; // 初始狀態為 false，表示未加載
//   bool _isButtonEnabled = false; // 初始狀態為 false，表示按鈕不可用

//   @override
//   void initState() {
//     super.initState();

//     setState(() {
//       _isButtonEnabled = true;
//     });
//   }

//   void _onGoPressed(BuildContext context) {
//     setState(() {
//       _isLoading = true; // 開始加載
//     });

//     // 根據 settings 中的 optionNumber 決定圖片數量
//     final settingsNotifier = Provider.of<SettingsNotifier>(
//       context,
//       listen: false,
//     );
//     final optionNumber = settingsNotifier.settings.optionNumber;
//     final List<String> images = List.generate(
//       optionNumber,
//       (index) => 'assets/images/image${index + 1}.jpg',
//     );

//     // 模擬進入聊天畫面
//     final chatHistoryNotifier = Provider.of<ChatHistoryNotifier>(
//       context,
//       listen: false,
//     );
//     chatHistoryNotifier.addMessage(
//       ChatMessage(isAI: true, content: '這是AI的回覆', images: images),
//     );
//     chatHistoryNotifier.currentSetup();

//     // 切換到聊天畫面
//     Navigator.pushNamed(context, '/chat');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Column(
//             children: [
//               Expanded(
//                 child: ListView(
//                   children: [UserMessage(messageContent: "圖片已上傳 ✅")],
//                 ),
//               ),
//               const AIModeSwitch(),
//             ],
//           ),
//           if (_isLoading)
//             // 顯示轉圈圈的加載畫面
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//           // if (!_isLoading)
//           //   // 只有在未加載時顯示 GoButton
//           //   GoButton(
//           //     onGoPressed:
//           //         (_isButtonEnabled && !_isLoading)
//           //             ? () => _onGoPressed(context)
//           //             : null, // 按鈕在未啟用或加載中時不可按
//           //     isLoading:
//           //         _isLoading || !_isButtonEnabled, // 顯示 "Thinking..." 或禁用狀態
//           //   ),
//         ],
//       ),
//     );
//   }
// }
