import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import 'tela_treino.dart';

final exerciseProvider = Provider((ref) => ExerciseService());

class ExerciseService {
  Stream<List<Map<String, dynamic>>> getExercises({String? muscleGroupFilter}) {
    Query query = FirebaseFirestore.instance.collection('exercises');
    if (muscleGroupFilter != null && muscleGroupFilter.isNotEmpty) {
      query = query.where('muscleGroup', isEqualTo: muscleGroupFilter);
    }
    return query.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              return {
                'id': doc.id,
                'name': 'Sem nome',
                'muscleGroup': 'Desconhecido',
                'level': 'Iniciante',
                'description': '',
                'videoUrl': '',
              };
            }
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Sem nome',
              'muscleGroup': data['muscleGroup'] ?? 'Desconhecido',
              'level': data['level'] ?? 'Iniciante',
              'description': data['description'] ?? '',
              'videoUrl': data['videoUrl'] ?? '',
            };
          }).toList(),
        );
  }
}

class TelaExercicios extends ConsumerStatefulWidget {
  const TelaExercicios({super.key});

  @override
  ConsumerState<TelaExercicios> createState() => _TelaExerciciosState();
}

class _TelaExerciciosState extends ConsumerState<TelaExercicios> {
  String? _selectedMuscleGroup;
  StreamSubscription<bool>? _premiumSubscription;

  @override
  void initState() {
    super.initState();
    ref.read(interstitialAdProvider).loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitial();
    });
  }

  Future<void> _showInterstitial() async {
    if (!mounted) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _premiumSubscription =
        ref.read(subscriptionProvider).isPremium(userId).listen(
      (isPremium) {
        if (!mounted) return;
        if (!isPremium) {
          final interstitialAdService = ref.read(interstitialAdProvider);
          interstitialAdService.showAd();
        }
      },
      onError: (error) {
        debugPrint('Erro ao verificar premium: $error');
      },
    );
  }

  @override
  void dispose() {
    _premiumSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesStream = ref.watch(exerciseProvider).getExercises(
          muscleGroupFilter: _selectedMuscleGroup,
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'Filtrar por Grupo Muscular'),
              value: _selectedMuscleGroup,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...['Peito', 'Costas', 'Pernas', 'Braços', 'Ombros', 'Abdômen']
                    .map((muscle) =>
                        DropdownMenuItem(value: muscle, child: Text(muscle))),
              ],
              onChanged: (value) =>
                  setState(() => _selectedMuscleGroup = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: exercisesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint(
                      'Erro no StreamBuilder (Exercícios): ${snapshot.error}');
                  return const Center(
                      child: Text('Erro ao carregar exercícios'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum exercício encontrado'));
                }
                final exercises = snapshot.data!;
                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return Card(
                      child: ListTile(
                        title: Text(ex['name'] ?? 'Sem nome'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Grupo: ${ex['muscleGroup'] ?? 'Desconhecido'}'),
                            Text('Nível: ${ex['level']}'),
                            if (ex['description'].isNotEmpty)
                              Text('Descrição: ${ex['description']}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
