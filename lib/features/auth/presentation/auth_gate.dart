import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/features/onboarding/data/onboarding_repository.dart';
import 'package:guarda_corpo_2024/screens/tela_inicial.dart';
import 'package:guarda_corpo_2024/screens/tela_login.dart';
import 'package:guarda_corpo_2024/screens/tela_onboarding.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading();
        }

        if (snapshot.hasError) {
          return const _GateError(
            message: 'Não foi possível verificar sua conta.',
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const TelaLogin();
        }

        return _OnboardingGate(key: ValueKey(user.uid), userId: user.uid);
      },
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate({super.key, required this.userId});

  final String userId;

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  final _repository = OnboardingRepository();
  late Future<bool> _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _status = _repository.hasCompleted(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _GateLoading();
        }

        if (snapshot.hasError) {
          return _GateError(
            message: 'Não foi possível carregar seu perfil.',
            onRetry: () => setState(_load),
          );
        }

        return snapshot.data == true
            ? const TelaInicial()
            : const TelaOnboarding();
      },
    );
  }
}

class _GateLoading extends StatelessWidget {
  const _GateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
  }
}

class _GateError extends StatelessWidget {
  const _GateError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: AppColors.textGray,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
