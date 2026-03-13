import 'package:flutter/material.dart';
import '../../features/main/presentation/pages/main_page.dart';

class AppRoutes {
  static const String main = '/';

  static Map<String, WidgetBuilder> get routes {
    return {main: (context) => const MainPage()};
  }
}
