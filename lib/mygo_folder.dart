import 'package:flutter/material.dart';

class MyGoFolderScreen extends StatelessWidget {
  const MyGoFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mygo!!!"),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          "這是 Mygo!!! 資料夾",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}