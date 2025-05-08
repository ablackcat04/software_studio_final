import 'dart:io';
import 'package:flutter/material.dart';

class AIMessage extends StatelessWidget {
  final List<String> imagePaths;
  final double imageSize;
  final Function(String) onCopy;
  final Function(String) onToggleLike;
  final Set<String> likedImages;

  const AIMessage({
    super.key,
    required this.imagePaths,
    required this.imageSize,
    required this.onCopy,
    required this.onToggleLike,
    required this.likedImages,
  });

  @override
  Widget build(BuildContext context) {
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
                imagePaths.map((path) {
                  final bool isFile =
                      path.startsWith('/') || path.startsWith('file://');
                  Widget imageWidget =
                      isFile
                          ? Image.file(
                            File(path),
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
                          )
                          : Image.asset(
                            path,
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
                          );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      imageWidget,
                      SizedBox(
                        width: imageSize,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => onCopy(path),
                                icon: const Icon(Icons.copy),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  likedImages.contains(path)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      likedImages.contains(path)
                                          ? Colors.pinkAccent
                                          : Colors.grey,
                                  size: 24,
                                ),
                                onPressed: () => onToggleLike(path),
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
