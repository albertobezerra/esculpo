import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/core/navigation/app_route_names.dart';
import 'package:guarda_corpo_2024/core/navigation/app_routes.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class EsculpoApp extends StatelessWidget {
  const EsculpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Esculpo',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
