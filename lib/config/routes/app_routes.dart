import 'package:flutter/material.dart';
import '../../shared/widgets/main_page.dart';
import '../../features/anime/ui/pages/anime_page.dart';
import '../../features/home/ui/pages/schedule_page.dart';
import '../../features/home/ui/pages/ranking_page.dart';
import '../../features/home/ui/pages/category_page.dart';
import '../../features/settings/video_settings/pages/plugin_manage_page.dart';
import '../../features/settings/video_settings/pages/plugin_editor_page.dart';
import '../../features/settings/video_settings/pages/plugin_test_page.dart';
import '../../features/auth/ui/pages/login_page.dart';
import '../../features/settings/video_settings/pages/hardware_decode_page.dart';
import '../../core/models/bangumi_item.dart';
import '../../core/models/video_plugin.dart';

class AppRoutes {
  static const String main = '/';
  static const String bangumiDetail = '/bangumi_detail';
  static const String schedule = '/schedule';
  static const String ranking = '/ranking';
  static const String category = '/category';
  static const String pluginManage = '/plugin_manage';
  static const String pluginEditor = '/plugin_editor';
  static const String pluginTest = '/plugin_test';
  static const String login = '/login';
  static const String hardwareDecode = '/hardware_decode';

  static Map<String, WidgetBuilder> get routes {
    return {
      main: (context) => const MainPage(),
      schedule: (context) => const SchedulePage(),
      ranking: (context) => const RankingPage(),
      category: (context) => const CategoryPage(),
      pluginManage: (context) => const PluginManagePage(),
      login: (context) => const LoginPage(),
      hardwareDecode: (context) => const HardwareDecodePage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case bangumiDetail:
        final bangumiItem = settings.arguments as BangumiItem;
        return MaterialPageRoute(
          builder: (context) => AnimePage(bangumiItem: bangumiItem),
        );
      case pluginEditor:
        final plugin = settings.arguments as VideoPlugin?;
        return MaterialPageRoute(
          builder: (context) => PluginEditorPage(plugin: plugin),
        );
      case pluginTest:
        final plugin = settings.arguments as VideoPlugin;
        return MaterialPageRoute(
          builder: (context) => PluginTestPage(plugin: plugin),
        );
      default:
        return null;
    }
  }
}
