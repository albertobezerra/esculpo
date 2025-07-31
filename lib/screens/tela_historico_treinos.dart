import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TelaHistoricoTreinos extends StatelessWidget {
  const TelaHistoricoTreinos({super.key});

  Future<List<Map<String, dynamic>>> _fetchWorkoutData(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .orderBy('dataCriacao')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Treinos')),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchWorkoutData(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar dados'));
                }
                final workouts = snapshot.data ?? [];
                final spots = workouts.asMap().entries.map((entry) {
                  final index = entry.key.toDouble();
                  final calories =
                      (entry.value['caloriasEstimadas']?.toDouble() ?? 0.0);
                  return FlSpot(index, calories);
                }).toList();

                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < workouts.length) {
                              final date =
                                  (workouts[index]['dataCriacao'] as Timestamp)
                                      .toDate();
                              return Text(
                                DateFormat('dd/MM').format(date),
                                style: const TextStyle(fontSize: 12),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 12),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF9D291A),
                        barWidth: 2,
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    minY: 0,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(userId)
                  .collection('treinos')
                  .orderBy('dataCriacao', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar treinos'));
                }
                final treinos = snapshot.data?.docs ?? [];
                return ListView.builder(
                  itemCount: treinos.length,
                  itemBuilder: (context, index) {
                    final treino =
                        treinos[index].data() as Map<String, dynamic>;
                    final dataCriacao =
                        (treino['dataCriacao'] as Timestamp?)?.toDate();
                    return ListTile(
                      title: Text(treino['nome'] ?? 'Treino sem nome'),
                      subtitle: Text(dataCriacao != null
                          ? DateFormat('dd/MM/yyyy').format(dataCriacao)
                          : 'Data desconhecida'),
                      trailing: Text('${treino['caloriasEstimadas'] ?? 0} cal'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/detalhe_treino',
                          arguments: treino,
                        );
                      },
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
