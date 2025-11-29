import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'screens/tela_inicial.dart';
import 'screens/tela_onboarding.dart';
import 'screens/tela_login.dart';
import 'screens/tela_splash.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      title: 'Esculpo',
      theme: AppTheme.lightTheme, // CORRIGIDO
      home: const TelaSplash(),
      routes: {
        '/tela_login': (context) => const TelaLogin(),
        '/tela_onboarding': (context) => const TelaOnboarding(),
        '/tela_inicial': (context) => const TelaInicial(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: Text('Erro ao verificar autenticação'),
            ),
          );
        }
        if (snapshot.hasData) {
          final userId = snapshot.data!.uid;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: Text('Erro ao carregar dados do usuário'),
                  ),
                );
              }
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data['onboardingConcluido'] == true) {
                  return const TelaInicial();
                }
              }
              return const TelaOnboarding();
            },
          );
        }
        return const TelaLogin();
      },
    );
  }
}
