import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:software_studio_final/service/navigation.dart'; // 引入主畫面 (assuming this defines 'router')
import 'package:software_studio_final/state/chat_list_notifier.dart';
import 'package:software_studio_final/state/current_chat_notifier.dart';
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart'; // <-- Add this import
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 引入主畫面
//import 'mygo_folder.dart'; // 引入 MyGO 資料夾頁面
//import 'your_pictures_folder.dart'; // 引入 Your Pictures 資料夾頁面

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);

  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsNotifier>(
          create: (context) => SettingsNotifier(),
        ),
        ChangeNotifierProvider(create: (_) => ChatListNotifier()),
        ChangeNotifierProvider(create: (_) => CurrentChatNotifier()),
        ChangeNotifierProvider(create: (_) => FavoriteNotifier()), // 新增收藏功能
        ChangeNotifierProvider<GuideNotifier>(
          create: (context) => GuideNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = context.select<SettingsNotifier, bool>(
      (notifier) => notifier.settings.isDarkTheme,
    );

    return MaterialApp.router(
      routerConfig: router,
      title: 'AI Meme Suggester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color.fromARGB(220, 0, 0, 0),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
