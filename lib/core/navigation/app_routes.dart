import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/navigation/app_route_names.dart';
import 'package:guarda_corpo_2024/features/auth/presentation/auth_gate.dart';
import 'package:guarda_corpo_2024/screens/tela_inicial.dart';
import 'package:guarda_corpo_2024/screens/tela_login.dart';
import 'package:guarda_corpo_2024/screens/tela_onboarding.dart';
import 'package:guarda_corpo_2024/screens/tela_splash.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      AppRoutes.splash => (_) => const TelaSplash(),
      AppRoutes.auth => (_) => const AuthGate(),
      AppRoutes.login || AppRoutes.legacyLogin => (_) => const TelaLogin(),
      AppRoutes.onboarding ||
      AppRoutes.legacyOnboarding => (_) => const TelaOnboarding(),
      AppRoutes.home || AppRoutes.legacyHome => (_) => const TelaInicial(),
      _ => (_) => const _UnknownRouteScreen(),
    };

    return MaterialPageRoute<void>(builder: builder, settings: settings);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.auth,
            (_) => false,
          ),
          child: const Text('Voltar ao início'),
        ),
      ),
    );
  }
}
