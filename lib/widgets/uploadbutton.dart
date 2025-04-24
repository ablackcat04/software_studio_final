import 'package:flutter/material.dart';

class UploadButton extends StatelessWidget {
  final VoidCallback onUploadPressed;
  final double screenWidth;

  const UploadButton({
    Key? key,
    required this.onUploadPressed,
    required this.screenWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: 20,
      left: 20,
      child: Row(
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
              onPressed: onUploadPressed,
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
      ),
    );
  }
}