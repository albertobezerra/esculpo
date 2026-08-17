// lib/screens/tela_inicial.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/providers/navigation_provider.dart';
import 'package:guarda_corpo_2024/screens/perfil/profile_screen.dart';
import 'package:guarda_corpo_2024/widgets/home/tela_inicial_content.dart';

import 'tela_exercicios.dart';
import 'tela_historico_treinos.dart';

class TelaInicial extends ConsumerStatefulWidget {
  const TelaInicial({super.key});

  @override
  ConsumerState<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends ConsumerState<TelaInicial> {
  late final List<Widget?> _pages = [
    const TelaInicialContent(),
    null,
    null,
    null,
  ];

  Widget _createPage(int index) {
    return switch (index) {
      0 => const TelaInicialContent(),
      1 => const TelaExercicios(),
      2 => const TelaHistoricoTreinos(),
      3 => const ProfileScreen(),
      _ => const TelaInicialContent(),
    };
  }

  void _selectPage(int index) {
    if (_pages[index] == null) {
      setState(() => _pages[index] = _createPage(index));
    }
    ref.read(selectedIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    _pages[selectedIndex] ??= _createPage(selectedIndex);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: selectedIndex,
        children: _pages
            .map((page) => page ?? const SizedBox.shrink())
            .toList(growable: false),
      ),
      bottomNavigationBar: _buildBottomNav(selectedIndex),
    );
  }

  Widget _buildBottomNav(int selectedIndex) {
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
              _buildNavIcon(
                Icons.home_outlined,
                Icons.home,
                0,
                selectedIndex,
                'Início',
              ),
              _buildNavIcon(
                Icons.fitness_center_outlined,
                Icons.fitness_center,
                1,
                selectedIndex,
                'Exercícios',
              ),
              _buildNavIcon(
                Icons.history_outlined,
                Icons.history,
                2,
                selectedIndex,
                'Histórico',
              ),
              _buildNavIcon(
                Icons.person_outline,
                Icons.person,
                3,
                selectedIndex,
                'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(
    IconData outlinedIcon,
    IconData filledIcon,
    int index,
    int currentIndex,
    String label,
  ) {
    final isSelected = currentIndex == index;
    return Semantics(
      selected: isSelected,
      label: label,
      button: true,
      child: InkResponse(
        onTap: () => _selectPage(index),
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        ),
      ),
    );
  }
}
