import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/services/suggestion_service.dart';

final planGeneratorServiceProvider =
    Provider((ref) => PlanGeneratorService(ref));

class PlanGeneratorService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PlanGeneratorService(this.ref);

  Future<void> generateTrainingPlan(String userId, {int? customDays}) async {
    final suggestionService = ref.read(suggestionServiceProvider);
    final userDoc = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();
    final onboardingData = userDoc.data();
    if (onboardingData == null) return;

    final nivel = onboardingData['nivel'] ?? 'Iniciante';
    final trainingFrequency =
        customDays ?? onboardingData['frequenciaTreino'] ?? 3;
    final sets = nivel == 'Iniciante'
        ? 3
        : nivel == 'Intermediário'
            ? 4
            : 5;
    final reps = nivel == 'Iniciante'
        ? 12
        : nivel == 'Intermediário'
            ? 10
            : 8;
    final restTime = nivel == 'Iniciante'
        ? 60
        : nivel == 'Intermediário'
            ? 45
            : 30;

    final exercisesSnapshot = await _firestore.collection('exercicios').get();
    final filteredExercises = exercisesSnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .where((ex) => ex['nivel'] == nivel || ex['nivel'] == 'Todos')
        .toList();

    final history = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .get();
    final historyData = history.docs.map((doc) => doc.data()).toList();

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

      Map<String, dynamic> treino = {
        'nome': 'Treino ${String.fromCharCode(65 + i)}',
        'exercicios': selectedExercises,
      };

      treino = suggestionService.adjustIntensity(treino, historyData);
      treinos.add(treino);
    }

    final batch = _firestore.batch();
    final planRef = _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('planos_treino')
        .doc('personalized');
    batch.set(planRef, {'treinos': treinos, 'dataCriacao': Timestamp.now()});
    await batch.commit();
  }

  Future<Map<String, dynamic>?> generateDailyWorkout(
      String userId, DateTime date) async {
    final suggestionService = ref.read(suggestionServiceProvider);
    final planSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('planos_treino')
        .doc('personalized')
        .get();
    final planData = planSnapshot.data();
    if (planData == null) return null;

    final treinos =
        (planData['treinos'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];
    if (treinos.isEmpty) return null;

    final history = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .get();
    final historyData = history.docs.map((doc) => doc.data()).toList();

    final dayIndex = date.weekday % treinos.length;
    var dailyWorkout = treinos[dayIndex];
    dailyWorkout = suggestionService.adjustIntensity(dailyWorkout, historyData);
    return dailyWorkout;
  }
}
