// lib/screens/tela_inicial.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/providers/navigation_provider.dart';
import 'package:guarda_corpo_2024/screens/perfil/profile_screen.dart';
import 'package:guarda_corpo_2024/widgets/home/tela_inicial_content.dart';
import 'tela_exercicios.dart';
import 'tela_historico_treinos.dart';

class TelaInicial extends ConsumerWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final pages = <Widget>[
      const TelaInicialContent(),
      const TelaExercicios(), // ✅ Mantém exercícios (importante)
      const TelaHistoricoTreinos(), // ✅ Mantém histórico
      const ProfileScreen(), // ✅ Perfil com acesso a fotos/planos
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavIcon(ref, Icons.home_outlined, Icons.home, 0,
                  selectedIndex, 'Início'),
              _buildNavIcon(ref, Icons.fitness_center_outlined,
                  Icons.fitness_center, 1, selectedIndex, 'Exercícios'),
              _buildNavIcon(ref, Icons.history_outlined, Icons.history, 2,
                  selectedIndex, 'Histórico'),
              _buildNavIcon(ref, Icons.person_outline, Icons.person, 3,
                  selectedIndex, 'Perfil'),
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
    String label,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        ref.read(selectedIndexProvider.notifier).state = index;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected ? AppColors.textDark : AppColors.textLight,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppColors.textDark : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
