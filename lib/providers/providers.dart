import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/servicos/ad_service.dart';
import 'package:guarda_corpo_2024/servicos/exercise_service.dart';
import 'package:guarda_corpo_2024/servicos/gerador_treinos_servico.dart';
import 'package:guarda_corpo_2024/servicos/subscription_service.dart';
import 'package:guarda_corpo_2024/servicos/suggestion_service.dart';
import 'package:guarda_corpo_2024/servicos/workout_service.dart';

final exerciseProvider =
    Provider<ExerciseService>((ref) => ExerciseService(ref));
final workoutProvider = Provider<WorkoutService>((ref) => WorkoutService(ref));

// NOVO: Substituindo o planGeneratorServiceProvider antigo
final geradorTreinosProvider = Provider<GeradorTreinosServico>(
  (ref) => GeradorTreinosServico(ref),
);

final suggestionServiceProvider =
    Provider<SuggestionService>((ref) => SuggestionService());
final subscriptionProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());
final adServiceProvider = Provider<AdService>((ref) => AdService());
