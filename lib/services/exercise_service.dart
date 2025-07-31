import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExerciseService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExerciseService(this.ref);

  Stream<List<Map<String, dynamic>>> getExercises(String? muscleGroup) {
    try {
      return _firestore.collection('exercicios').snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .where((ex) =>
                    muscleGroup == null || ex['grupoMuscular'] == muscleGroup)
                .toList(),
          );
    } catch (e) {
      throw Exception('Erro ao carregar exercícios: $e');
    }
  }
}
