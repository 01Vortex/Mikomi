import 'package:flutter/material.dart';
import '../../features/main/ui/pages/main_page.dart';
import '../../features/anime/ui/pages/anime_page.dart';
import '../../core/models/bangumi_item.dart';

class AppRoutes {
  static const String main = '/';
  static const String bangumiDetail = '/bangumi_detail';

  static Map<String, WidgetBuilder> get routes {
    return {main: (context) => const MainPage()};
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
