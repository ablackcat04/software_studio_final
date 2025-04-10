import 'package:flutter/material.dart';

class MyGoGarbageFolderScreen extends StatelessWidget {
  const MyGoGarbageFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mygogarbage"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text(
          "這是 Mygogarbage 資料夾",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}