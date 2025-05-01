import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaDetalheTreino extends StatelessWidget {
  final Map<String, dynamic> workout;

  const TelaDetalheTreino({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final exercises = workout['exercises'] as List<dynamic>? ?? [];
    final createdAt = workout['createdAt'] as Timestamp?;
    final formattedDate = createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
        : 'Data desconhecida';

    return Scaffold(
      appBar: AppBar(title: Text('Treino - $formattedDate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tempo estimado: ${workout['estimatedTime'] ?? 0} min'),
            Text(
                'Calorias estimadas: ${(workout['estimatedCalories'] ?? 0).toStringAsFixed(1)} kcal'),
            const SizedBox(height: 16),
            const Text(
              'Exercícios:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(ex['name'] as String),
                    subtitle: Text(
                      '${ex['sets']} séries, ${ex['reps']} reps, ${ex['weight']} kg (${ex['weightVariation']})',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
