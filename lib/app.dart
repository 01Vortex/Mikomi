import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/routes/app_routes.dart';
import 'config/themes/app_theme.dart';
import 'config/localization/app_localizations.dart';
import 'core/services/locale_service.dart';
import 'core/providers/theme_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          final effectiveColor = themeProvider.useDynamicColor
              ? null
              : themeProvider.themeColor;
          final effectiveFontFamily = themeProvider.getEffectiveFontFamily();

          return MaterialApp(
            key: ValueKey('${effectiveColor}_${effectiveFontFamily}'),
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
