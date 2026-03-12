import 'package:flutter/material.dart';
import '../../features/home/presentation/pages/home_page.dart';

class AppRoutes {
  static const String home = '/';

  static Map<String, WidgetBuilder> get routes {
    return {home: (context) => const HomePage()};
  }
}
