import 'package:flutter_test/flutter_test.dart';
import 'package:guarda_corpo_2024/features/onboarding/domain/onboarding_profile.dart';

void main() {
  final profile = OnboardingProfile(
    name: 'Pessoa Teste',
    birthDate: DateTime(1995, 1, 10),
    gender: 'Outro',
    weight: 80,
    height: 180,
    goalWeight: 75,
    objective: 'Ganhar massa',
    experience: 'Sim, <6 meses',
    weeklyFrequency: 3,
    activityLevel: 'Moderado',
    equipment: 'Academia',
    preference: 'Musculação',
    schedule: 'Manhã',
    restrictions: 'Não',
  );

  test('calcula IMC com altura informada em centímetros', () {
    expect(profile.bmi, closeTo(24.69, 0.01));
  });

  test('mantém as chaves usadas pelo gerador legado', () {
    final data = profile.toLegacyMap();

    expect(data['objetivo'], 'Ganhar massa');
    expect(data['frequencia'], 3);
    expect(data['onboardingConcluido'], isTrue);
    expect(data['schemaVersion'], 2);
  });
}
