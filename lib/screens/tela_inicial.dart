// lib/screens/tela_inicial.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/providers/navigation_provider.dart';
import 'package:guarda_corpo_2024/screens/profile_screen.dart';
import 'package:guarda_corpo_2024/screens/tela_fotos_progresso.dart';
import 'package:guarda_corpo_2024/widgets/home/tela_inicial_content.dart';
import 'tela_exercicios.dart';
import 'tela_historico_treinos.dart';
import 'tela_planos_treino.dart';

class TelaInicial extends ConsumerWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final pages = <Widget>[
      const TelaInicialContent(),
      const TelaPlanosTreino(),
      const TelaHistoricoTreinos(),
      const TelaExercicios(),
      const TelaFotosProgresso(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(ref, selectedIndex),
    );
  }

  Widget _buildBottomNav(WidgetRef ref, int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(
                  ref, Icons.home_outlined, Icons.home, 0, selectedIndex),
              _buildNavIcon(ref, Icons.calendar_today_outlined,
                  Icons.calendar_today, 1, selectedIndex),
              _buildNavIcon(
                  ref, Icons.history_outlined, Icons.history, 2, selectedIndex),
              _buildNavIcon(ref, Icons.fitness_center_outlined,
                  Icons.fitness_center, 3, selectedIndex),
              _buildNavIcon(ref, Icons.photo_camera_outlined,
                  Icons.photo_camera, 4, selectedIndex),
              _buildNavIcon(
                  ref, Icons.person_outline, Icons.person, 5, selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    WidgetRef ref,
    IconData outlinedIcon,
    IconData filledIcon,
    int index,
    int currentIndex,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(selectedIndexProvider.notifier).state = index;
        debugPrint('📍 Navegou para índice: $index');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? AppColors.textDark : AppColors.textLight,
          size: 28,
        ),
      ),
    );
  }
}
