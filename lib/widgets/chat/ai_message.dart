import 'package:flutter/material.dart';
import 'package:software_studio_final/widgets/copy_button.dart';
import 'package:software_studio_final/widgets/favorite_button.dart';

class AIMessage extends StatelessWidget {
  final List<String> imagePaths;

  const AIMessage({super.key, required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.375;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: imagePaths.map((imagePath) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    imagePath,
                    width: imageSize,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: imageSize,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: imageSize,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CopyButton(imagePath: imagePath),
                          const SizedBox(width: 8),
                          FavoriteButton(
                            id: imagePath, // 使用圖片路徑作為唯一的 ID
                            imageUrl: imagePath,
                            title: "Image", // 可以根據需求修改標題
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
