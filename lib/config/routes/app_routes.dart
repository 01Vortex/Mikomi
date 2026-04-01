import 'package:flutter/material.dart';
import '../../shared/main_page.dart';
import '../../features/anime/ui/pages/anime_page.dart';
import '../../features/home/ui/pages/schedule_page.dart';
import '../../features/home/ui/pages/rank_page.dart';
import '../../features/home/ui/pages/category_page.dart';
import '../../features/settings/video_play/pages/plugin_manage_page.dart';
import '../../features/settings/video_play/pages/plugin_editor_page.dart';
import '../../features/settings/video_play/pages/plugin_test_page.dart';
import '../../features/settings/video_play/pages/plugin_shop_page.dart';
import '../../features/settings/danmaku/danmaku_setting_page.dart';
import '../../features/auth/ui/pages/login_page.dart';
import '../../features/settings/video_play/pages/hardware_decode_page.dart';
import '../../features/settings/video_play/pages/play_setting_page.dart';
import '../../features/settings/video_play/pages/video_renderer_page.dart';
import '../../core/models/anime.dart';
import '../../features/home/models/home_anime_model.dart';
import '../../features/video/models/video_plugin.dart';

class AppRoutes {
  static const String main = '/';
static const String animeDetail = '/anime_detail';
  static const String bangumiDetail = animeDetail;
  static const String schedule = '/schedule';
  static const String ranking = '/ranking';
  static const String category = '/category';
  static const String pluginManage = '/plugin_manage';
  static const String pluginEditor = '/plugin_editor';
  static const String pluginTest = '/plugin_test';
  static const String pluginShop = '/plugin_shop';
  static const String danmakuSetting = '/danmaku_setting';
  static const String login = '/login';
  static const String hardwareDecode = '/hardware_decode';
  static const String videoBasis = '/video_basis';
  static const String videoRenderer = '/video_renderer';

  static Map<String, WidgetBuilder> get routes {
    return {
      main: (context) => const MainPage(),
      schedule: (context) => const SchedulePage(),
      ranking: (context) => const RankPage(),
      category: (context) => const CategoryPage(),
      pluginManage: (context) => const PluginManagePage(),
      pluginShop: (context) => const PluginShopPage(),
      danmakuSetting: (context) => const DanmakuSettingPage(),
      login: (context) => const LoginPage(),
      hardwareDecode: (context) => const HardwareDecodePage(),
      videoBasis: (context) => const VideoBasisPage(),
      videoRenderer: (context) => const VideoRendererPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case animeDetail:
        final argument = settings.arguments;
        final anime = switch (argument) {
          Anime value => value,
          HomeAnimeModel value => Anime(
            id: value.id,
            name: value.name,
            nameCn: value.nameCn,
            summary: value.summary,
            airDate: value.airDate,
            images: value.images,
            ratingScore: value.ratingScore,
            ratingCount: value.ratingCount,
            rank: value.rank,
            tags: value.tags
                .map((tag) => BangumiTag(name: tag.name, count: tag.count))
                .toList(),
            info: value.info,
          ),
          _ => throw ArgumentError('Invalid anime route argument: $argument'),
        };
        return MaterialPageRoute(
          builder: (context) => AnimePage(anime: anime),
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
