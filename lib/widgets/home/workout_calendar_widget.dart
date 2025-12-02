// lib/widgets/home/workout_calendar_widget.dart

import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/screens/tela_detalhe_treino.dart';

class WorkoutCalendarWidget extends StatelessWidget {
  final int rebuildKey;
  final Future<Map<String, dynamic>?> Function(DateTime) getCachedWorkout;

  const WorkoutCalendarWidget({
    super.key,
    required this.rebuildKey,
    required this.getCachedWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.workoutCalendar,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDayCard(
                context,
                now.subtract(const Duration(days: 1)),
                strings.yesterday,
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(context, now, strings.today, true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(
                context,
                now.add(const Duration(days: 1)),
                strings.tomorrow,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCard(
      BuildContext context, DateTime date, String label, bool isToday) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('${rebuildKey}_${date.day}'),
      future: getCachedWorkout(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeleton(isToday);
        }

        final data = snapshot.data;
        final musculos = data?['musculos'] ?? 'Descanso';
        final porcentagem = (data?['porcentagem'] as num?)?.toDouble() ?? 0.0;

        return GestureDetector(
          onTap: () {
            if (data != null &&
                (data['treinos'] as List?)?.isNotEmpty == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaDetalheTreino(workout: data),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday ? AppColors.textDark : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isToday ? Colors.white : AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? Colors.white70 : AppColors.textGray,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  musculos,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${porcentagem.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isToday ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(bool isToday) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? AppColors.textDark : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: isToday ? Colors.white : AppColors.primaryGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
