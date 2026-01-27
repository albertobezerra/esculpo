// lib/providers/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/servicos/foto_progresso_servico.dart';
import 'package:guarda_corpo_2024/servicos/ad_service.dart';
import 'package:guarda_corpo_2024/servicos/exercise_service.dart';
import 'package:guarda_corpo_2024/servicos/gerador_treinos_servico.dart';
import 'package:guarda_corpo_2024/servicos/subscription_service.dart';
import 'package:guarda_corpo_2024/servicos/suggestion_service.dart';
import 'package:guarda_corpo_2024/servicos/workout_service.dart';
import 'package:guarda_corpo_2024/servicos/profile_image_service.dart';

final exerciseProvider =
    Provider<ExerciseService>((ref) => ExerciseService(ref));
final workoutProvider = Provider<WorkoutService>((ref) => WorkoutService(ref));

final geradorTreinosProvider = Provider<GeradorTreinosServico>(
  (ref) => GeradorTreinosServico(ref),
);

final suggestionServiceProvider =
    Provider<SuggestionService>((ref) => SuggestionService());
final subscriptionProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());
final adServiceProvider = Provider<AdService>((ref) => AdService());

final fotoProgressoServicoProvider = Provider<FotoProgressoServico>((ref) {
  return FotoProgressoServico();
});

// ✅ Provider com a API moderna do Riverpod 3.0
final profileImageProvider =
    NotifierProvider<ProfileImageNotifier, ProfileImageState>(() {
  return ProfileImageNotifier();
});
