import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/service/navigation.dart'; // 引入主畫面
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';
//import 'mygo_folder.dart'; // 引入 MyGO 資料夾頁面
//import 'your_pictures_folder.dart'; // 引入 Your Pictures 資料夾頁面

void main() async {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsNotifier>(
          create: (context) => SettingsNotifier(),
        ),
        ChangeNotifierProvider<ChatHistoryNotifier>(
          create: (context) => ChatHistoryNotifier(),
        ),
        ChangeNotifierProvider(create: (_) => FavoriteNotifier()), // 新增收藏功能
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme =
        Provider.of<SettingsNotifier>(context).settings.isDarkTheme;

    return MaterialApp.router(
      routerConfig: router,
      title: 'AI Meme Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color.fromARGB(220, 0, 0, 0),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
