// lib/widgets/home/progress_card_widget.dart

import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/screens/tela_detalhe_treino.dart';
import 'circular_progress_painter.dart';

class ProgressCardWidget extends StatelessWidget {
  final int rebuildKey;
  final Future<Map<String, dynamic>?> Function(DateTime) getCachedWorkout;

  const ProgressCardWidget({
    super.key,
    required this.rebuildKey,
    required this.getCachedWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey(rebuildKey),
      future: getCachedWorkout(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton();
        }

        final workout = snapshot.data;
        final musculos =
            workout?['musculos'] ?? strings.noWorkout.toUpperCase();
        final porcentagem =
            (workout?['porcentagem'] as num?)?.toDouble() ?? 0.0;
        final temExercicios =
            (workout?['treinos'] as List?)?.isNotEmpty ?? false;
        final tempoEstimado = workout?['tempoEstimado'] ?? 0;

        return GestureDetector(
          onTap: temExercicios
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaDetalheTreino(workout: workout!),
                    ),
                  );
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.todayWorkout,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(90, 90),
                            painter: CircularProgressPainter(
                              progress: porcentagem / 100,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${porcentagem.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            musculos,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (tempoEstimado > 0)
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: AppColors.textGray),
                                const SizedBox(width: 4),
                                Text(
                                  '$tempoEstimado ${strings.minutes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (temExercicios) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TelaDetalheTreino(workout: workout!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(strings.continueWorkout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
  }
}
