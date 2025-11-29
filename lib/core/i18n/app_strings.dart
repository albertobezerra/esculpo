// lib/core/i18n/app_strings.dart

import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  // Saudações
  String get goodMorning =>
      locale.languageCode == 'pt' ? 'Bom dia' : 'Good morning';
  String get goodAfternoon =>
      locale.languageCode == 'pt' ? 'Boa tarde' : 'Good afternoon';
  String get goodEvening =>
      locale.languageCode == 'pt' ? 'Boa noite' : 'Good evening';

  // Tela Inicial
  String get progress => locale.languageCode == 'pt' ? 'Progresso' : 'Progress';
  String get continueWorkout =>
      locale.languageCode == 'pt' ? 'Continuar treino' : 'Continue workout';
  String get noWorkout =>
      locale.languageCode == 'pt' ? 'Sem treino' : 'No workout';
  String get rest => locale.languageCode == 'pt' ? 'Descanso' : 'Rest';
  String get todayWorkout =>
      locale.languageCode == 'pt' ? 'Treino de Hoje' : 'Today\'s Workout';

  // Calendário
  String get workoutCalendar => locale.languageCode == 'pt'
      ? 'Calendário de Treinos'
      : 'Workout Calendar';
  String get yesterday => locale.languageCode == 'pt' ? 'Ontem' : 'Yesterday';
  String get today => locale.languageCode == 'pt' ? 'Hoje' : 'Today';
  String get tomorrow => locale.languageCode == 'pt' ? 'Amanhã' : 'Tomorrow';

  // Métricas
  String get metrics => locale.languageCode == 'pt' ? 'Métricas' : 'Metrics';
  String get calories => locale.languageCode == 'pt' ? 'Calorias' : 'Calories';
  String get weight => locale.languageCode == 'pt' ? 'Peso' : 'Weight';
  String get time => locale.languageCode == 'pt' ? 'Tempo' : 'Time';
  String get burned => locale.languageCode == 'pt' ? 'queimadas' : 'burned';
  String get lifted => locale.languageCode == 'pt' ? 'levantado' : 'lifted';
  String get trained => locale.languageCode == 'pt' ? 'treinado' : 'trained';

  // Badges
  String get cardio => locale.languageCode == 'pt' ? 'Cardio' : 'Cardio';
  String get muscle => locale.languageCode == 'pt' ? 'Músculo' : 'Muscle';
  String get strength => locale.languageCode == 'pt' ? 'Força' : 'Strength';
  String get beginner => locale.languageCode == 'pt' ? 'Iniciante' : 'Beginner';
  String get intermediate =>
      locale.languageCode == 'pt' ? 'Intermediário' : 'Intermediate';
  String get advanced => locale.languageCode == 'pt' ? 'Avançado' : 'Advanced';

  // Unidades
  String get hours => locale.languageCode == 'pt' ? 'horas' : 'hours';
  String get minutes => locale.languageCode == 'pt' ? 'min' : 'min';
  String get kcal => 'kcal';
  String get kg => 'kg';

  // Grupos musculares
  String get chest => locale.languageCode == 'pt' ? 'Peito' : 'Chest';
  String get back => locale.languageCode == 'pt' ? 'Costas' : 'Back';
  String get legs => locale.languageCode == 'pt' ? 'Pernas' : 'Legs';
  String get glutes => locale.languageCode == 'pt' ? 'Glúteos' : 'Glutes';
  String get shoulders => locale.languageCode == 'pt' ? 'Ombros' : 'Shoulders';
  String get biceps => locale.languageCode == 'pt' ? 'Bíceps' : 'Biceps';
  String get triceps => locale.languageCode == 'pt' ? 'Tríceps' : 'Triceps';
  String get core => locale.languageCode == 'pt' ? 'Core' : 'Core';
  String get fullBody =>
      locale.languageCode == 'pt' ? 'Corpo Todo' : 'Full Body';
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['pt', 'en'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}
