class OnboardingProfile {
  const OnboardingProfile({
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.weight,
    required this.height,
    required this.goalWeight,
    required this.objective,
    required this.experience,
    required this.weeklyFrequency,
    required this.activityLevel,
    required this.equipment,
    required this.preference,
    required this.schedule,
    required this.restrictions,
  });

  final String name;
  final DateTime birthDate;
  final String gender;
  final double weight;
  final double height;
  final double goalWeight;
  final String objective;
  final String experience;
  final int weeklyFrequency;
  final String activityLevel;
  final String equipment;
  final String preference;
  final String schedule;
  final String restrictions;

  double get bmi {
    final heightInMeters = height > 3 ? height / 100 : height;
    if (heightInMeters <= 0) return 0;
    return weight / (heightInMeters * heightInMeters);
  }

  Map<String, Object?> toLegacyMap() {
    return {
      'nome': name,
      'dataNascimento': birthDate,
      'genero': gender,
      'peso': weight,
      'altura': height,
      'metaPeso': goalWeight,
      'objetivo': objective,
      'experiencia': experience,
      'frequencia': weeklyFrequency,
      'nivelAtividade': activityLevel,
      'equipamento': equipment,
      'preferencia': preference,
      'horario': schedule,
      'restricoes': restrictions,
      'onboardingConcluido': true,
      'schemaVersion': 2,
    };
  }

  Map<String, Object?> toUserSummaryMap() {
    return {
      'nome': name,
      'peso': weight,
      'altura': height,
      'metaPeso': goalWeight,
      'objetivo': objective,
      'frequencia': weeklyFrequency,
      'imc': bmi,
      'onboardingConcluido': true,
      'schemaVersion': 2,
    };
  }
}
