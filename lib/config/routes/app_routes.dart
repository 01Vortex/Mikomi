import 'package:flutter/material.dart';
import '../../shared/widgets/main_page.dart';
import '../../features/anime/ui/pages/anime_page.dart';
import '../../features/home/ui/pages/schedule_page.dart';
import '../../features/home/ui/pages/ranking_page.dart';
import '../../features/home/ui/pages/category_page.dart';
import '../../core/models/bangumi_item.dart';

class AppRoutes {
  static const String main = '/';
  static const String bangumiDetail = '/bangumi_detail';
  static const String schedule = '/schedule';
  static const String ranking = '/ranking';
  static const String category = '/category';

  static Map<String, WidgetBuilder> get routes {
    return {
      main: (context) => const MainPage(),
      schedule: (context) => const SchedulePage(),
      ranking: (context) => const RankingPage(),
      category: (context) => const CategoryPage(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case bangumiDetail:
        final bangumiItem = settings.arguments as BangumiItem;
        return MaterialPageRoute(
          builder: (context) => BangumiDetailPage(bangumiItem: bangumiItem),
        );
      default:
        return null;
    }
  }
}
