import 'package:flutter/material.dart';

class UploadButton extends StatelessWidget {
  final VoidCallback onUploadPressed;
  final double screenWidth;

  const UploadButton({
    super.key,
    required this.onUploadPressed,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center( // 使用 Center 將按鈕和文字置於螢幕正中間
      child: Column(
        mainAxisSize: MainAxisSize.min, // 讓 Column 的大小適配內容
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
              iconSize: screenWidth * 0.6,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16), // 增加按鈕與文字之間的間距
          SizedBox(
            width: screenWidth * 1.2,
            child: Text(
              'Upload conversation screenshots to provide context!',
              textAlign: TextAlign.center, // 文字置中
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