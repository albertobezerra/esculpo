import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/plan_generator_service.dart';

// Provider para PlanGeneratorService
final planGeneratorServiceProvider = Provider((ref) => PlanGeneratorService());
