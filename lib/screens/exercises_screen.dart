import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'subscription_service.dart';
import 'workout_screen.dart';

final exerciseProvider = Provider((ref) => ExerciseService());

class ExerciseService {
  Stream<List<Map<String, dynamic>>> getExercises() {
    return FirebaseFirestore.instance.collection('exercises').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc.data()['name'] ?? 'Sem nome',
                    'muscleGroup': doc.data()['muscleGroup'] ?? 'Desconhecido',
                  })
              .toList(),
        );
  }
}

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  StreamSubscription<bool>? _premiumSubscription;

  @override
  void initState() {
    super.initState();
    ref.read(interstitialAdProvider).loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitial();
    });
  }

  Future<void> _showInterstitial() async {
    if (!mounted) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _premiumSubscription =
        ref.read(subscriptionProvider).isPremium(userId).listen(
      (isPremium) {
        if (!mounted) return;
        if (!isPremium) {
          final interstitialAdService = ref.read(interstitialAdProvider);
          interstitialAdService.showAd();
        }
      },
      onError: (error) {
        debugPrint('Erro ao verificar premium: $error');
      },
    );
  }

  @override
  void dispose() {
    _premiumSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesStream = ref.watch(exerciseProvider).getExercises();
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: exercisesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Erro no StreamBuilder (Exercises): ${snapshot.error}');
            return const Center(child: Text('Erro ao carregar exercícios'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum exercício encontrado'));
          }
          final exercises = snapshot.data!;
          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final ex = exercises[index];
              return ListTile(
                title: Text(ex['name'] ?? 'Sem nome'),
                subtitle: Text(ex['muscleGroup'] ?? 'Desconhecido'),
              );
            },
          );
        },
      ),
    );
  }
}
