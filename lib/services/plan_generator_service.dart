import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlanGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateTrainingPlan(String userId, {int? customDays}) async {
    try {
      // Carregar dados do onboarding
      final onboardingDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();

      if (!onboardingDoc.exists) {
        throw Exception('Dados do onboarding não encontrados');
      }

      final onboardingData = onboardingDoc.data()!;
      final experienceLevel =
          onboardingData['experienceLevel'] as String? ?? 'Iniciante';
      final focusMuscleGroups = List<String>.from(
          onboardingData['focusMuscleGroups'] ?? ['Peito', 'Costas', 'Pernas']);
      final objectives =
          List<String>.from(onboardingData['objectives'] ?? ['Força']);

      // Sugerir dias com base no nível
      int suggestedDays;
      switch (experienceLevel) {
        case 'Iniciante':
          suggestedDays = 3;
          break;
        case 'Intermediário':
          suggestedDays = 4;
          break;
        case 'Avançado':
          suggestedDays = 5;
          break;
        default:
          suggestedDays = 3;
      }

      // Usar dias customizados, se fornecidos
      final trainingFrequency = customDays ?? suggestedDays;

      // Carregar exercícios
      final exercisesSnapshot = await _firestore.collection('exercises').get();
      final exercises =
          exercisesSnapshot.docs.map((doc) => doc.data()).toList();

      // Filtrar exercícios com base em grupos musculares, nível e objetivos
      final filteredExercises = exercises.where((ex) {
        final muscleGroup = ex['muscleGroup'] as String?;
        final level = ex['level'] as String?;
        final exerciseType = ex['type'] as String? ?? 'Força';
        return focusMuscleGroups.contains(muscleGroup) &&
            (level == experienceLevel || level == 'Iniciante') &&
            objectives.contains(exerciseType);
      }).toList();

      if (filteredExercises.isEmpty) {
        throw Exception('Nenhum exercício compatível encontrado');
      }

      // Configurações por nível
      final sets = experienceLevel == 'Iniciante'
          ? 3
          : experienceLevel == 'Intermediário'
              ? 4
              : 5;
      final reps = experienceLevel == 'Iniciante'
          ? 12
          : experienceLevel == 'Intermediário'
              ? 10
              : 8;
      final restTime = experienceLevel == 'Iniciante'
          ? 60
          : experienceLevel == 'Intermediário'
              ? 45
              : 30;

      // Gerar treinos
      final workouts = <Map<String, dynamic>>[];
      for (int i = 0; i < trainingFrequency; i++) {
        final selectedExercises = filteredExercises
            .asMap()
            .entries
            .where((entry) =>
                entry.key % trainingFrequency == i % filteredExercises.length)
            .take(6)
            .map((entry) => {
                  'id': entry.value['id'],
                  'name': entry.value['name'],
                  'muscleGroup': entry.value['muscleGroup'],
                  'sets': sets,
                  'reps': reps,
                  'weight': 0,
                  'restTime': restTime,
                })
            .toList();

        workouts.add({
          'name': 'Treino ${String.fromCharCode(65 + i)}',
          'exercises': selectedExercises,
        });
      }

      // Salvar plano
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('training_plans')
          .doc('personalized')
          .set({
        'name': 'Plano Personalizado',
        'workouts': workouts,
        'trainingFrequency': trainingFrequency,
        'suggestedDays': suggestedDays,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'Plano personalizado gerado para $userId com $trainingFrequency dias');
    } catch (e) {
      debugPrint('Erro ao gerar plano: $e');
      rethrow;
    }
  }
}
