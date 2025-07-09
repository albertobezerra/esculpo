import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlanGeneratorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Determina o tipo de treino dinamicamente
  String _determineWorkoutType(int dayOfWeek, int frequencia, double peso) {
    final cycleLength = 7 ~/ frequencia; // Ex.: 7 / 3 = 2-3 dias por ciclo
    final cycleIndex = (dayOfWeek - 1) % cycleLength;

    final muscleGroups = {
      0: peso > 80.0 ? 'Quadríceps, Glúteos, Panturrilhas' : 'Peito, Tríceps',
      1: 'Costas, Bíceps',
      2: 'Ombros',
    };

    return muscleGroups[cycleIndex] ?? 'Abdômen, Core';
  }

  // Gera um treino dinâmico com base no onboarding
  Future<Map<String, dynamic>> generateDynamicWorkout(
      String userId, DateTime date) async {
    final dayOfWeek = date.weekday;
    final onboardingData = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();
    final peso = onboardingData.data()?['peso']?.toDouble() ?? 70.0;
    final frequencia = onboardingData.data()?['frequencia']?.toInt() ?? 3;

    String tipo = _determineWorkoutType(dayOfWeek, frequencia, peso);
    int tempoEstimado = 60; // Valor base, a ajustar
    double caloriasEstimadas = peso * 0.5; // Estimativa simples

    return {
      'tipo': tipo,
      'musculos': tipo.toUpperCase(),
      'tempoEstimado': tempoEstimado,
      'caloriasEstimadas': caloriasEstimadas,
      'porcentagem': 0.0, // A ser calculado em _getActiveWorkout
      'treinos': [], // Pode ser expandido para incluir exercícios
    };
  }

  // Opcional: Gerar e salvar plano completo (se desejar)
  Future<void> generateTrainingPlan(String userId, {int? customDays}) async {
    try {
      debugPrint('Iniciando geração de plano para $userId...');

      final onboardingDoc = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();

      if (!onboardingDoc.exists) {
        debugPrint('Dados de onboarding não encontrados para $userId');
        throw Exception('Dados do onboarding não encontrados');
      }

      final onboardingData = onboardingDoc.data()!;
      final experienceLevel =
          onboardingData['experiencia'] as String? ?? 'Iniciante';
      final focusMuscleGroups = List<String>.from(
          onboardingData['preferencia'] ?? ['Peito', 'Costas', 'Pernas']);
      final objective =
          onboardingData['objetivo'] as String? ?? 'Ganho de Força';

      debugPrint(
          'Dados de onboarding carregados: experiencia=$experienceLevel, preferencia=$focusMuscleGroups, objetivo=$objective');

      int suggestedDays;
      switch (experienceLevel) {
        case 'Sim, regularmente':
          suggestedDays = 5;
          break;
        case 'Sim, >6 meses':
          suggestedDays = 4;
          break;
        case 'Sim, <6 meses':
        case 'Não':
          suggestedDays = 3;
          break;
        default:
          suggestedDays = 3;
      }

      final trainingFrequency =
          customDays != null && customDays <= 7 ? customDays : suggestedDays;

      final exercisesSnapshot = await _firestore.collection('exercicios').get();
      if (exercisesSnapshot.docs.isEmpty) {
        debugPrint('Nenhum exercício encontrado na coleção "exercicios"');
        throw Exception('Nenhum exercício disponível para gerar o plano');
      }

      final exercises = exercisesSnapshot.docs.map((doc) {
        return {
          ...doc.data(),
          'id': doc.id,
          'type': _mapExerciseType(doc.data()),
        };
      }).toList();
      debugPrint('Exercícios carregados: ${exercises.length} documentos');

      final filteredExercises = exercises.where((ex) {
        final muscleGroup = ex['grupoMuscular'] as String?;
        final level = ex['nivel'] as String?;
        final exerciseType = ex['type'] as String? ?? 'Força';
        final isMatch = muscleGroup != null &&
            focusMuscleGroups.contains(muscleGroup) &&
            (level == 'Iniciante' ||
                level == null ||
                level == experienceLevel) &&
            _matchesObjective(exerciseType, objective);
        debugPrint(
            'Exercício ${ex['nome']}: muscleGroup=$muscleGroup, level=$level, type=$exerciseType, match=$isMatch');
        return isMatch;
      }).toList();

      if (filteredExercises.isEmpty) {
        debugPrint(
            'Nenhum exercício compatível encontrado com os filtros: $focusMuscleGroups, $experienceLevel, $objective');
        throw Exception('Nenhum exercício compatível encontrado');
      }

      final sets = experienceLevel.contains('regularmente')
          ? 5
          : experienceLevel.contains('>6 meses')
              ? 4
              : 3;
      final reps = experienceLevel.contains('regularmente')
          ? 8
          : experienceLevel.contains('>6 meses')
              ? 10
              : 12;
      final restTime = experienceLevel.contains('regularmente')
          ? 30
          : experienceLevel.contains('>6 meses')
              ? 45
              : 60;

      final treinos = <Map<String, dynamic>>[];
      for (int i = 0; i < trainingFrequency; i++) {
        final selectedExercises = filteredExercises
            .asMap()
            .entries
            .where((entry) =>
                entry.key % trainingFrequency == i % filteredExercises.length)
            .take(6)
            .map((entry) => {
                  'id': entry.value['id'],
                  'nome': entry.value['nome'],
                  'grupoMuscular': entry.value['grupoMuscular'],
                  'series': sets,
                  'repeticoes': reps,
                  'cargaSugerida': 0,
                  'tempoDescanso': restTime,
                })
            .toList();

        treinos.add({
          'nome': 'Treino ${String.fromCharCode(65 + i)}',
          'exercicios': selectedExercises,
        });
      }

      await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('planos_treino')
          .doc('personalized')
          .set({
        'titulo': 'Plano Personalizado',
        'treinos': treinos,
        'frequenciaTreino': trainingFrequency,
        'diasSugeridos': suggestedDays,
        'dataCriacao': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'Plano personalizado gerado para $userId com $trainingFrequency dias');
    } catch (e) {
      debugPrint('Erro ao gerar plano: $e');
      rethrow;
    }
  }

  String _mapExerciseType(Map<String, dynamic> exercise) {
    final name = exercise['nome'] as String? ?? '';
    if (name.toLowerCase().contains('cardio') ||
        name.toLowerCase().contains('corrida')) {
      return 'Cardio';
    }
    return 'Força';
  }

  bool _matchesObjective(String exerciseType, String objective) {
    if (objective == 'Perder peso' &&
        (exerciseType == 'Cardio' || exerciseType == 'Força')) {
      return true;
    }
    if ((objective == 'Ganho de Força' || objective == 'Ganhar massa') &&
        exerciseType == 'Força') {
      return true;
    }
    return false;
  }
}
