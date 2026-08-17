import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guarda_corpo_2024/features/onboarding/domain/onboarding_profile.dart';

class OnboardingRepository {
  OnboardingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> hasCompleted(String userId) async {
    final userReference = _firestore.collection('usuarios').doc(userId);
    final userSnapshot = await userReference.get();
    final userData = userSnapshot.data();

    if (userData?['onboardingConcluido'] == true) {
      return true;
    }

    // Compatibilidade com usuários criados antes da arquitetura v2.
    final legacySnapshot = await userReference
        .collection('onboarding')
        .doc('data')
        .get();
    final completed = legacySnapshot.data()?['onboardingConcluido'] == true;

    if (completed) {
      try {
        await userReference.set({
          'onboardingConcluido': true,
          'schemaVersion': 2,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } on FirebaseException {
        // O dado legado continua válido mesmo se a autorreparação falhar.
      }
    }

    return completed;
  }

  Future<void> save({
    required String userId,
    required OnboardingProfile profile,
  }) async {
    final userReference = _firestore.collection('usuarios').doc(userId);
    final legacyReference = userReference.collection('onboarding').doc('data');
    final batch = _firestore.batch();

    batch.set(userReference, {
      ...profile.toUserSummaryMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(legacyReference, {
      ...profile.toLegacyMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
