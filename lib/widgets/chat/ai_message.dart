import 'package:flutter/material.dart';

class AIMessage extends StatelessWidget {
  final List<String> imagePaths;

  const AIMessage({super.key, required this.imagePaths});

  void _onCopy(BuildContext context, String image) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $image to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _onToggleLike(String image) {}

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
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                imagePaths.map((imagePath) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        imagePath,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: imageSize,
                            height: imageSize,
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
                              IconButton(
                                onPressed: () => _onCopy(context, imagePath),
                                icon: const Icon(Icons.copy),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  true ? Icons.favorite : Icons.favorite_border,
                                  color: true ? Colors.pinkAccent : Colors.grey,
                                  size: 24,
                                ),
                                onPressed: () => _onToggleLike(imagePath),
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
