import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:http/http.dart' as http;

class AIMessage extends StatelessWidget {
  final List<String> imagePaths;

  const AIMessage({super.key, required this.imagePaths});

  void _onCopy(BuildContext context, String imageUrl) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $imageUrl to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
    if (imageUrl.startsWith('http')) {
      http
          .get(Uri.parse(imageUrl))
          .then((onValue) {
            if (onValue.statusCode == 200) {
              final bytes = onValue.bodyBytes;
              print('Image bytes: ${bytes.length}');
              Pasteboard.writeImage(bytes);
            } else {
              print('Failed to load image');
            }
          })
          .catchError((onError) {
            print('Error: $onError');
          });
    } else {
      rootBundle
          .load(imageUrl)
          .then((onValue) {
            final bytes = onValue.buffer.asUint8List();
            Pasteboard.writeImage(bytes);
          })
          .catchError((onError) {
            print('Error: $onError');
          });
    }
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
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
