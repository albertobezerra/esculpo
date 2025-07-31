import 'package:flutter_riverpod/flutter_riverpod.dart';

final suggestionServiceProvider = Provider((ref) => SuggestionService());

class SuggestionService {
  Map<String, dynamic> adjustIntensity(
      Map<String, dynamic> workout, List<Map<String, dynamic>> history) {
    int totalSets = 0;
    double totalWeight = 0.0;
    int totalWorkouts = history.length;

    for (var prevWorkout in history) {
      final exercises = prevWorkout['exercicios'] as List<dynamic>? ?? [];
      for (var ex in exercises) {
        totalSets += (ex['series'] as int?) ?? 0;
        totalWeight += (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
      }
    }

    double avgWeight = totalWorkouts > 0 ? totalWeight / totalWorkouts : 0.0;
    bool increaseIntensity =
        history.length >= 4 && avgWeight > 0 && totalSets > 20;

    if (increaseIntensity) {
      final exercises = (workout['exercicios'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final updatedExercises = exercises.map((ex) {
        return {
          ...ex,
          'series': (ex['series'] as int? ?? 3) + 1,
          'repeticoes': (ex['repeticoes'] as int? ?? 12) + 2,
        };
      }).toList();
      return {...workout, 'exercicios': updatedExercises};
    }
    return workout;
  }
}
