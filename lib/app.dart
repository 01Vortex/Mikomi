import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/routes/app_routes.dart';
import 'config/themes/app_theme.dart';
import 'config/localization/app_localizations.dart';
import 'core/services/locale_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mikomi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('de', 'DE'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
        Locale('fr', 'FR'),
        Locale('ja', 'JP'),
        Locale('pt', 'BR'),
        Locale('ru', 'RU'),
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          LocaleService.setLocale(locale);
          // 精确匹配（包括scriptCode）
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode &&
                supportedLocale.scriptCode == locale.scriptCode) {
              return supportedLocale;
            }
          }
          // 语言代码匹配
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return supportedLocales.first;
      },
      initialRoute: AppRoutes.main,
      routes: AppRoutes.routes,
    );
  }
}
