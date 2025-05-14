import 'package:flutter/material.dart';

class GoButton extends StatelessWidget {
  final VoidCallback onGoPressed;
  final bool isLoading;

  const GoButton({
    super.key,
    required this.onGoPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Center(
        child: ElevatedButton(
          onPressed: isLoading ? null : onGoPressed, // 禁用按鈕時設置為 null
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading ? Colors.grey : Colors.orangeAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 64,
              vertical: 24,
            ),
          ),
          child: Text(
            isLoading ? "Thinking..." : "GO!",
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}