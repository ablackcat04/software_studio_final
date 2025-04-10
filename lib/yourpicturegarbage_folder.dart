import 'package:flutter/material.dart';

class YourPictureGarbageFolderScreen extends StatelessWidget {
  const YourPictureGarbageFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yourpicturegarbage"),
        backgroundColor: Colors.purple,
      ),
      body: const Center(
        child: Text(
          "這是 Yourpicturegarbage 資料夾",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}