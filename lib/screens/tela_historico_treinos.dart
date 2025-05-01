import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'tela_detalhe_treino.dart';

class TelaHistoricoTreinos extends StatelessWidget {
  const TelaHistoricoTreinos({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('workouts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Erro ao carregar treinos: ${snapshot.error}');
            return const Center(child: Text('Erro ao carregar treinos'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum treino salvo ainda'));
          }

          final workouts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index].data() as Map<String, dynamic>;
              final exercises = workout['exercises'] as List<dynamic>? ?? [];
              final createdAt = workout['createdAt'] as Timestamp?;
              final formattedDate = createdAt != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt.toDate())
                  : 'Data desconhecida';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Treino - $formattedDate'),
                  subtitle: Text(
                      'Exercícios: ${exercises.length} | Tempo: ${workout['estimatedTime'] ?? 0} min'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaDetalheTreino(workout: workout),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
