import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider pra gerenciar dados do usuário
final userProvider = Provider((ref) => UserService());

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveUserData({
    required double weight,
    required int height,
    required int age,
    required String sex,
    required String experience,
    required String goal,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Usuário não autenticado';

    final imc = weight / ((height / 100) * (height / 100));
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'weight': weight,
      'height': height,
      'age': age,
      'sex': sex,
      'experience': experience,
      'goal': goal,
      'imc': imc,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  String? _sex;
  String? _experience;
  String? _goal;

  @override
  Widget build(BuildContext context) {
    final userService = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Altura (cm)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Idade'),
                keyboardType: TextInputType.number,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Sexo'),
                value: _sex,
                items: ['Masculino', 'Feminino', 'Outro']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _sex = value),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Experiência'),
                value: _experience,
                items: ['Iniciante', 'Intermediário', 'Avançado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _experience = value),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Objetivo'),
                value: _goal,
                items: [
                  'Força',
                  'Emagrecimento',
                  'Resistência',
                  'Flexibilidade'
                ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _goal = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final weight = double.tryParse(_weightController.text);
                    final height = int.tryParse(_heightController.text);
                    final age = int.tryParse(_ageController.text);
                    if (weight == null ||
                        height == null ||
                        age == null ||
                        _sex == null ||
                        _experience == null ||
                        _goal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Preencha todos os campos')),
                      );
                      return;
                    }
                    await userService.saveUserData(
                      weight: weight,
                      height: height,
                      age: age,
                      sex: _sex!,
                      experience: _experience!,
                      goal: _goal!,
                    );
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
