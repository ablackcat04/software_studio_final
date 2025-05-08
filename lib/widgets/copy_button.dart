import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:http/http.dart' as http;

class CopyButton extends StatelessWidget {
  final String imagePath;

  const CopyButton({super.key, required this.imagePath});

  void _onCopy(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $imagePath to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
    if (imagePath.startsWith('http')) {
      http
          .get(Uri.parse(imagePath))
          .then((onValue) {
            if (onValue.statusCode == 200) {
              final bytes = onValue.bodyBytes;
              Pasteboard.writeImage(bytes);
            } else {
              print('Failed to copy image');
            }
          })
          .catchError((onError) {
            print('Error: $onError');
          });
    } else {
      rootBundle
          .load(imagePath)
          .then((onValue) {
            final bytes = onValue.buffer.asUint8List();
            Pasteboard.writeImage(bytes);
          })
          .catchError((onError) {
            print('Error: $onError');
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _onCopy(context),
      icon: const Icon(Icons.copy),
    );
  }
}
