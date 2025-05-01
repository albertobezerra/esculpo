import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'tela_inicial.dart';

final onboardingProvider = Provider((ref) => OnboardingService());

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveOnboardingData(
      String userId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .set(data);
  }
}

class TelaOnboarding extends ConsumerStatefulWidget {
  const TelaOnboarding({super.key});

  @override
  ConsumerState<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends ConsumerState<TelaOnboarding> {
  final _formKey = GlobalKey<FormState>();
  int _trainingFrequency = 3;
  String _sex = 'Masculino';
  DateTime? _birthDate;
  double _weight = 70;
  int _height = 170;
  double _weightGoal = 75;
  final List<String> _objectives = [];
  final List<String> _focusMuscleGroups = [];
  String _experienceLevel = 'Iniciante';
  String _trainingLocation = 'Academia';

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'trainingFrequency': _trainingFrequency,
        'weightUnit': 'kg',
        'distanceUnit': 'km',
        'sex': _sex,
        'birthDate': _birthDate?.toIso8601String(),
        'weight': _weight,
        'height': _height,
        'weightGoal': _weightGoal,
        'objectives': _objectives,
        'focusMuscleGroups': _focusMuscleGroups,
        'experienceLevel': _experienceLevel,
        'trainingLocation': _trainingLocation,
        'completedAt': FieldValue.serverTimestamp(),
      };
      try {
        await ref.read(onboardingProvider).saveOnboardingData(
              FirebaseAuth.instance.currentUser!.uid,
              data,
            );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaInicial()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo ao Esculpo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Quantas vezes por semana quer treinar?'),
              Slider(
                value: _trainingFrequency.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_trainingFrequency dias',
                onChanged: (value) =>
                    setState(() => _trainingFrequency = value.round()),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sexo'),
                value: _sex,
                items: ['Masculino', 'Feminino', 'Outro']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) => setState(() => _sex = value!),
              ),
              ListTile(
                title: Text(
                  _birthDate == null
                      ? 'Data de Nascimento'
                      : DateFormat('dd/MM/yyyy').format(_birthDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectBirthDate(context),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Digite seu peso' : null,
                onChanged: (value) => _weight = double.tryParse(value) ?? 70,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Altura (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Digite sua altura' : null,
                onChanged: (value) => _height = int.tryParse(value) ?? 170,
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Meta de Peso (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Digite sua meta' : null,
                onChanged: (value) =>
                    _weightGoal = double.tryParse(value) ?? 75,
              ),
              const Text('Objetivos (selecione um ou mais):'),
              Wrap(
                children:
                    ['Força', 'Hipertrofia', 'Resistência', 'Emagrecimento']
                        .map((obj) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                label: Text(obj),
                                selected: _objectives.contains(obj),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _objectives.add(obj);
                                    } else {
                                      _objectives.remove(obj);
                                    }
                                  });
                                },
                              ),
                            ))
                        .toList(),
              ),
              const Text('Grupos musculares de foco:'),
              Wrap(
                children:
                    ['Peito', 'Costas', 'Pernas', 'Braços', 'Ombros', 'Abdômen']
                        .map((muscle) => Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: FilterChip(
                                label: Text(muscle),
                                selected: _focusMuscleGroups.contains(muscle),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _focusMuscleGroups.add(muscle);
                                    } else {
                                      _focusMuscleGroups.remove(muscle);
                                    }
                                  });
                                },
                              ),
                            ))
                        .toList(),
              ),
              DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Nível de Experiência'),
                value: _experienceLevel,
                items: ['Iniciante', 'Intermediário', 'Avançado']
                    .map((level) =>
                        DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => _experienceLevel = value!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Local de Treino'),
                value: _trainingLocation,
                items: ['Academia', 'Casa', 'Ao ar livre']
                    .map(
                        (loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _trainingLocation = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Concluir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
