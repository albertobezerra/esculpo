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
            .collection('usuarios')
            .doc(userId)
            .collection('treinos') // Alterado de 'workouts' para 'treinos'
            .orderBy('dataCriacao', descending: true) // Campo renomeado
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
              final exerciciosList =
                  workout['treinos']?[0]?['exercicios'] as List<dynamic>? ?? [];
              final dataCriacao = workout['dataCriacao'] as Timestamp?;
              final formattedDate = dataCriacao != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(dataCriacao.toDate())
                  : 'Data desconhecida';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Treino - $formattedDate'),
                  subtitle: Text(
                      'Exercícios: ${exerciciosList.length} | Tempo: ${workout['tempoEstimado'] ?? 0} min'),
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
