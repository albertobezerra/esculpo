import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/services/ad_service.dart';
import 'package:guarda_corpo_2024/services/exercise_service.dart';
import 'package:guarda_corpo_2024/services/plan_generator_service.dart';
import 'package:guarda_corpo_2024/services/subscription_service.dart';
import 'package:guarda_corpo_2024/services/suggestion_service.dart';
import 'package:guarda_corpo_2024/services/workout_service.dart';

final exerciseProvider =
    Provider<ExerciseService>((ref) => ExerciseService(ref));
final workoutProvider = Provider<WorkoutService>((ref) => WorkoutService(ref));
final planGeneratorServiceProvider =
    Provider<PlanGeneratorService>((ref) => PlanGeneratorService(ref));
final suggestionServiceProvider =
    Provider<SuggestionService>((ref) => SuggestionService());
final subscriptionProvider =
    Provider<SubscriptionService>((ref) => SubscriptionService());
final adServiceProvider = Provider<AdService>((ref) => AdService());
