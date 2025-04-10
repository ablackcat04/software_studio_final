import 'package:flutter/material.dart';

class YourPicturesFolderScreen extends StatelessWidget {
  const YourPicturesFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your pictures"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          "這是 Your pictures 資料夾",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}