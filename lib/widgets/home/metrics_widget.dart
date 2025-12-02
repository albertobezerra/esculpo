// lib/widgets/home/metrics_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';

class MetricsWidget extends StatelessWidget {
  final int rebuildKey;

  const MetricsWidget({super.key, required this.rebuildKey});

  Future<Map<String, double>> _getProgressData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }

    final userId = user.uid;
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      double calorias = 0.0;
      double pesoLevantado = 0.0;
      double tempoCardio = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final exercicios = data['exercicios'] as List<dynamic>? ?? [];
        for (var ex in exercicios) {
          if (ex['concluido'] == true) {
            calorias += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
            pesoLevantado += (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
            tempoCardio += (ex['duracao'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      return {
        'calorias': calorias,
        'pesoLevantado': pesoLevantado,
        'tempoCardio': tempoCardio
      };
    } catch (e) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.metrics,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
          key: ValueKey('${rebuildKey}_metrics'),
          future: _getProgressData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final progress = snapshot.data ??
                {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.local_fire_department,
                    progress['calorias']!.toStringAsFixed(0),
                    strings.kcal,
                    strings.burned,
                    AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.fitness_center,
                    progress['pesoLevantado']!.toStringAsFixed(0),
                    strings.kg,
                    strings.lifted,
                    AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    Icons.timer,
                    progress['tempoCardio']!.toStringAsFixed(0),
                    strings.minutes,
                    strings.trained,
                    AppColors.primaryGreen,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    IconData icon,
    String value,
    String unit,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
