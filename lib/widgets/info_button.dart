import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Not directly used in this specific widget's logic, but kept if other parts of your app use it.
// import 'package:software_studio_final/state/favorite_notifier.dart'; // Not directly used in this specific widget's logic.

class ReasonButton extends StatelessWidget {
  final String reason;
  // You can add an image path or URL if you have a specific image to show.
  // For now, we'll just use a placeholder.
  final String? imagePath; // Optional image URL

  const ReasonButton({super.key, required this.reason, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        _showReasonPopup(context);
      },
      icon: Icon(Icons.info),
      color: Colors.grey,
    );
  }

  void _showReasonPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reason Details'),
          content: SingleChildScrollView(
            // Use SingleChildScrollView for potentially long content
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep the column compact
              children: <Widget>[
                // Image Placeholder
                Container(
                  width: double.infinity, // Take full width
                  child: Image.asset(
                    imagePath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(child: Icon(Icons.broken_image));
                    },
                  ),
                ),
                SizedBox(height: 16), // Space between image and reason
                // Reason Text
                Text(reason, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }
}
