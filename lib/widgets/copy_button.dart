import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:http/http.dart' as http;

class CopyButton extends StatelessWidget {
  final String imagePath;

  const CopyButton({super.key, required this.imagePath});

  void _notifyResult(ScaffoldMessengerState scaffoldMessenger, bool success) {
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(success ? 'Copy success' : 'Copy error'),
        duration: const Duration(seconds: 1),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _onCopy(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (imagePath.startsWith('http')) {
      http
          .get(Uri.parse(imagePath))
          .then((onValue) {
            if (onValue.statusCode == 200) {
              final bytes = onValue.bodyBytes;
              try {
                Pasteboard.writeImage(bytes);
                _notifyResult(scaffoldMessenger, true);
              } catch (e) {
                _notifyResult(scaffoldMessenger, false);
              }
            } else {
              _notifyResult(scaffoldMessenger, false);
            }
          })
          .catchError((onError) {
            _notifyResult(scaffoldMessenger, false);
          });
    } else {
      rootBundle
          .load(imagePath)
          .then((onValue) {
            final bytes = onValue.buffer.asUint8List();
            Pasteboard.writeImage(bytes);
            _notifyResult(scaffoldMessenger, true);
          })
          .catchError((onError) {
            _notifyResult(scaffoldMessenger, false);
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
