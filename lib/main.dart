import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';
import 'package:software_studio_final/service/navigation.dart'; // 引入主畫面 (assuming this defines 'router')
import 'package:software_studio_final/state/settings_notifier.dart';
import 'package:software_studio_final/state/favorite_notifier.dart';
import 'package:software_studio_final/state/guide_notifier.dart'; // <-- Add this import
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  final chatHistoryNotifier = ChatHistoryNotifier();
  await chatHistoryNotifier.load();

  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsNotifier>(
          create: (_) => SettingsNotifier(),
        ),
        ChangeNotifierProvider<ChatHistoryNotifier>.value(
          value: chatHistoryNotifier,
        ),
        ChangeNotifierProvider(create: (_) => FavoriteNotifier()),
        ChangeNotifierProvider(create: (_) => GuideNotifier()),
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
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
