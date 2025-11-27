import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutService {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  WorkoutService(this.ref);

  Future<void> saveWorkout(String userId, Map<String, dynamic> workout) async {
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .add(workout);
  }
}
