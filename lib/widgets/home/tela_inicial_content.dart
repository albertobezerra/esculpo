// lib/widgets/home/tela_inicial_content.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'header_widget.dart';
import 'streak_badge_widget.dart';
import 'progress_card_widget.dart';
import 'workout_calendar_widget.dart';
import 'metrics_widget.dart';
import 'progress_photos_card_widget.dart';

class TelaInicialContent extends ConsumerStatefulWidget {
  const TelaInicialContent({super.key});

  @override
  ConsumerState<TelaInicialContent> createState() => _TelaInicialContentState();
}

class _TelaInicialContentState extends ConsumerState<TelaInicialContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // Chave para forçar reconstrução
  int _rebuildKey = 0;
  final Map<String, Future<Map<String, dynamic>?>> _workoutCache = {};

  @override
  void initState() {
    super.initState();
    _checkOnboardingAndGeneratePlan();
  }

  // DENTRO DE lib/widgets/home/tela_inicial_content.dart

  // Limpa o cache e força a tela a redesenhar
  void _refreshData() {
    // CORREÇÃO DO ERRO DE CRASH
    if (!mounted) return;

    setState(() {
      _workoutCache.clear();
      _rebuildKey++;
    });
  }

  Future<Map<String, dynamic>?> getCachedWorkout(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    if (!_workoutCache.containsKey(key)) {
      _workoutCache[key] = _getActiveWorkout(date);
    }
    return _workoutCache[key]!;
  }

  Future<void> _checkOnboardingAndGeneratePlan() async {
    if (user == null) return;
    final userId = user!.uid;

    final onboardingSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();

    if (onboardingSnapshot.exists &&
        onboardingSnapshot.data()?['onboardingConcluido'] == true) {
      final planSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('planos_treino')
          .doc('personalized')
          .get();

      if (!planSnapshot.exists) {
        try {
          await ref
              .read(geradorTreinosProvider)
              .gerarPlanoCompleto(usuarioId: userId);
          _refreshData(); // Usa o método novo
        } catch (e) {
          debugPrint('❌ Erro ao gerar plano: $e');
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _getActiveWorkout(DateTime date) async {
    if (user == null) return null;
    final userId = user!.uid;

    try {
      final geradorTreinos = ref.read(geradorTreinosProvider);
      final workout = await geradorTreinos.gerarTreinoDiario(userId, date);

      if (workout == null ||
          (workout['treinos'] == null && workout['exercicios'] == null)) {
        return {
          'tipo': 'Sem treino',
          'musculos': 'DESCANSO',
          'porcentagem': 0.0,
          'treinos': [],
        };
      }
      return workout;
    } catch (e) {
      return {
        'tipo': 'Erro',
        'musculos': 'ERRO',
        'porcentagem': 0.0,
        'treinos': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    AppStrings.of(context);

    return SafeArea(
      child: RefreshIndicator(
        // Bônus: Permite arrastar pra baixo pra atualizar
        onRefresh: () async {
          _refreshData();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: HeaderWidget(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreakBadgeWidget(
                        key:
                            ValueKey('streak_$_rebuildKey')), // Atualiza streak
                    const SizedBox(height: 24),

                    // --- AQUI ESTÁ A LIGAÇÃO ---
                    ProgressCardWidget(
                      rebuildKey: _rebuildKey,
                      getCachedWorkout: getCachedWorkout,
                      onTreinoFinalizado:
                          _refreshData, // <--- Passamos o refresh aqui!
                    ),
                    // ---------------------------

                    const SizedBox(height: 24),
                    WorkoutCalendarWidget(
                      rebuildKey: _rebuildKey,
                      getCachedWorkout: getCachedWorkout,
                    ),
                    const SizedBox(height: 24),
                    MetricsWidget(rebuildKey: _rebuildKey),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
