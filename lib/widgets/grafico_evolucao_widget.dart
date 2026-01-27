import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class GraficoEvolucaoWidget extends StatelessWidget {
  const GraficoEvolucaoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('fotos_progresso')
          .orderBy('data',
              descending: false) // Ordem cronológica para o gráfico
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator()));
        }

        final docs = snapshot.data!.docs;
        List<FlSpot> spots = [];
        double minPeso = 1000;
        double maxPeso = 0;

        // Extrai pontos (Peso vs Índice)
        // Nota: Um gráfico temporal real requer conversão de Data -> Double,
        // mas índice sequencial (1ª foto, 2ª foto...) funciona bem para MVP.
        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final peso = (data['peso'] as num?)?.toDouble();

          if (peso != null && peso > 0) {
            spots.add(FlSpot(i.toDouble(), peso));
            if (peso < minPeso) minPeso = peso;
            if (peso > maxPeso) maxPeso = peso;
          }
        }

        if (spots.isEmpty) {
          return Container(
            height: 150,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.show_chart, color: Colors.grey, size: 40),
                SizedBox(height: 8),
                Text("Adicione fotos com peso para ver o gráfico!",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        // Margem para o gráfico não bater no teto/chão
        minPeso -= 5;
        maxPeso += 5;

        return Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(16, 24, 24, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Evolução do Peso",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: minPeso,
                    maxY: maxPeso,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primaryPurple,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppColors.primaryPurple,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withValues(alpha: 0.3),
                              AppColors.primaryPurple.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        // tooltipBgColor: AppColors.textDark, // Ajuste conforme versão do pacote
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y} kg',
                              const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
