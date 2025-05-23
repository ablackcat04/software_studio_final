import 'package:go_router/go_router.dart';
import 'package:software_studio_final/page/favorite_page.dart';
import 'package:software_studio_final/page/settings_page.dart';
import 'package:software_studio_final/page/trending_page.dart';
import 'package:software_studio_final/mainscreen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/trending',
      builder: (context, state) => TrendingPage(),
    ),
    GoRoute(
      path: '/favorite',
      builder: (context, state) => FavoritePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => SettingsPage(),
    ),
  ],
);