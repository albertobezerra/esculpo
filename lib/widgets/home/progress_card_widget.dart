// lib/widgets/home/progress_card_widget.dart

import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/screens/tela_detalhe_treino.dart';
import 'circular_progress_painter.dart';

class ProgressCardWidget extends StatelessWidget {
  final int rebuildKey;
  final Future<Map<String, dynamic>?> Function(DateTime) getCachedWorkout;
  final VoidCallback? onTreinoFinalizado;

  const ProgressCardWidget({
    super.key,
    required this.rebuildKey,
    required this.getCachedWorkout,
    this.onTreinoFinalizado,
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
        if (workout == null) return const SizedBox();

        final musculos = workout['musculos'] ?? strings.noWorkout.toUpperCase();
        final porcentagem = (workout['porcentagem'] as num?)?.toDouble() ?? 0.0;
        final treinosList = workout['treinos'] as List?;
        final exerciciosList = workout['exercicios'] as List?;
        final temExercicios = (treinosList?.isNotEmpty ?? false) ||
            (exerciciosList?.isNotEmpty ?? false);
        final tempoEstimado = workout['tempoEstimado'] ?? 0;

        // --- LÓGICA DE CONCLUÍDO ---
        final bool isConcluido =
            porcentagem >= 100.0 || workout['concluido'] == true;

        return GestureDetector(
          onTap: temExercicios
              ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaDetalheTreino(
                        workout: workout,
                        treinoDocId: workout['treinoDocId'] as String,
                      ),
                    ),
                  );
                  if (onTreinoFinalizado != null) onTreinoFinalizado!();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
              // Borda verde sutil se concluído
              border: isConcluido
                  ? Border.all(color: AppColors.primaryGreen, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isConcluido
                          ? "Treino Concluído! 🎉"
                          : strings.todayWorkout,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isConcluido
                              ? AppColors.primaryGreen
                              : AppColors.textDark,
                          fontWeight: isConcluido
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                    if (isConcluido)
                      const Icon(Icons.check_circle,
                          color: AppColors.primaryGreen)
                  ],
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
                              color: isConcluido
                                  ? AppColors.primaryGreen
                                  : AppColors.primaryGreen,
                            ),
                          ),
                          Center(
                            child: isConcluido
                                ? const Icon(Icons.thumb_up,
                                    color: AppColors.primaryGreen, size: 32)
                                : Text(
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
                                  // Se concluiu, mostra texto fixo ou o tempo real se vc tiver salvo
                                  isConcluido
                                      ? "Finalizado"
                                      : '$tempoEstimado ${strings.minutes}',
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
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaDetalheTreino(
                              workout: workout,
                              treinoDocId: workout['treinoDocId'] as String,
                            ),
                          ),
                        );
                        if (onTreinoFinalizado != null) onTreinoFinalizado!();
                      },
                      // MUDANÇA VISUAL AQUI
                      icon: Icon(
                          isConcluido ? Icons.visibility : Icons.play_arrow,
                          size: 20,
                          color: isConcluido
                              ? AppColors.primaryGreen
                              : Colors.white),
                      label: Text(
                          isConcluido
                              ? "Ver Detalhes"
                              : strings.continueWorkout,
                          style: TextStyle(
                              color: isConcluido
                                  ? AppColors.primaryGreen
                                  : Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isConcluido ? Colors.white : AppColors.textDark,
                        side: isConcluido
                            ? const BorderSide(color: AppColors.primaryGreen)
                            : null,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: isConcluido ? 0 : 2,
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
