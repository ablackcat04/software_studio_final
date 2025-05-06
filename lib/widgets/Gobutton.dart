import 'package:flutter/material.dart';

class GoButton extends StatelessWidget {
  final VoidCallback onGoPressed;

  const GoButton({
    Key? key,
    required this.onGoPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Container(
        child: Center(
          child: ElevatedButton(
            onPressed: onGoPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 64,
                vertical: 24,
              ),
            ),
            child: Text(
              "GO!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}