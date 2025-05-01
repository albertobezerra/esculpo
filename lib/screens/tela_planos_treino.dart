import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'tela_detalhe_treino.dart';

class TelaPlanosTreino extends ConsumerStatefulWidget {
  const TelaPlanosTreino({super.key});

  @override
  ConsumerState<TelaPlanosTreino> createState() => _TelaPlanosTreinoState();
}

class _TelaPlanosTreinoState extends ConsumerState<TelaPlanosTreino> {
  int _selectedDays = 3;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Planos de Treino')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Dias por semana: '),
                DropdownButton<int>(
                  value: _selectedDays,
                  items: List.generate(7, (index) => index + 1)
                      .map((days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days dias'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDays = value!;
                    });
                    ref.read(planGeneratorServiceProvider).generateTrainingPlan(
                          userId,
                          customDays: _selectedDays,
                        );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('training_plans')
                  .doc('personalized')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar plano'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Nenhum plano gerado'));
                }

                final plan = snapshot.data!.data() as Map<String, dynamic>;
                final workouts = plan['workouts'] as List<dynamic>? ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(workout['name'] as String),
                        subtitle: Text(
                            'Exercícios: ${(workout['exercises'] as List).length}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TelaDetalheTreino(workout: workout),
                            ),
                          );
                        },
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
