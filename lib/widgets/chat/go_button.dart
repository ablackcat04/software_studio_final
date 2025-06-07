// import 'package:flutter/material.dart';

// class GoButton extends StatelessWidget {
//   final VoidCallback? onGoPressed; // 修改為可空類型
//   final bool isLoading;

//   const GoButton({
//     super.key,
//     required this.onGoPressed,
//     required this.isLoading,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Positioned.fill(
//       child: Center(
//         child: ElevatedButton(
//           onPressed: onGoPressed, // 當 isLoading 為 true 時，onGoPressed 為 null
//           style: ElevatedButton.styleFrom(
//             backgroundColor: isLoading ? Colors.grey : Colors.orangeAccent,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30),
//             ),
//             padding: const EdgeInsets.symmetric(
//               horizontal: 64,
//               vertical: 24,
//             ),
//           ),
//           child: Text(
//             isLoading ? "Thinking..." : "GO!",
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: theme.colorScheme.onTertiaryContainer,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
