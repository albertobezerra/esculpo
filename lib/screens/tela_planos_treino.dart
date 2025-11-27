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
                  onChanged: (value) async {
                    setState(() {
                      _selectedDays = value!;
                    });

                    // Mostra loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Gerando plano personalizado...'),
                          ],
                        ),
                      ),
                    );

                    try {
                      await ref.read(geradorTreinosProvider).gerarPlanoCompleto(
                            usuarioId: userId,
                          );

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plano atualizado!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios') // Alterado de 'users' para 'usuarios'
                  .doc(userId)
                  .collection(
                      'planos_treino') // Alterado de 'training_plans' para 'planos_treino'
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
                final workouts = plan['treinos'] as List<dynamic>? ??
                    []; // Alterado de 'workouts' para 'treinos'

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final workout = workouts[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(workout['titulo'] as String? ??
                            'Sem título'), // Alterado de 'name' para 'titulo'
                        subtitle: Text(
                            'Exercícios: ${(workout['exercicios'] as List?)?.length ?? 0}'), // Alterado de 'exercises' para 'exercicios'
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
