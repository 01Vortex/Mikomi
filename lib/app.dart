import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'config/app_localizations.dart';
import 'core/services/locale_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/navigation_service.dart';
import 'core/providers/app_theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => AnimationProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()..init()),
        ChangeNotifierProvider(create: (_) => NavigationService()),
      ],
      child: Consumer2<AppThemeProvider, FontProvider>(
        builder: (context, themeProvider, fontProvider, _) {
          final effectiveColor = themeProvider.useDynamicColor
              ? null
              : themeProvider.currentTheme.primaryColor;
          final effectiveFontFamily = fontProvider.getEffectiveFontFamily();

          return MaterialApp(
            key: ValueKey('${effectiveColor}_$effectiveFontFamily'),
            title: 'Mikomi',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: effectiveColor != null
                  ? ColorScheme.fromSeed(
                      seedColor: effectiveColor,
                      brightness: Brightness.light,
                    )
                  : AppTheme.lightTheme.colorScheme,
              fontFamily: effectiveFontFamily,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: effectiveColor != null
                  ? ColorScheme.fromSeed(
                      seedColor: effectiveColor,
                      brightness: Brightness.dark,
                    )
                  : AppTheme.darkTheme.colorScheme,
              fontFamily: effectiveFontFamily,
            ),
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
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode &&
                      supportedLocale.scriptCode == locale.scriptCode) {
                    return supportedLocale;
                  }
                }
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
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
