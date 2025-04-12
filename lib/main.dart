import 'package:flutter/material.dart';
import 'mainscreen.dart'; // 引入主畫面
import 'mygo_folder.dart'; // 引入 MyGO 資料夾頁面
import 'your_pictures_folder.dart'; // 引入 Your Pictures 資料夾頁面

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Meme Suggester',
      home: const MainScreen(), // 主畫面
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color.fromARGB(220, 0, 0, 0),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          // Customize other text styles for dark mode
        ),
      ),
      // themeMode: ThemeMode.system,
    );
  }
}
