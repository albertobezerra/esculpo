// lib/screens/tela_inicial.dart

import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/screens/tela_fotos_progresso.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/widgets/home/tela_inicial_content.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TelaInicialContent(),
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
    const TelaFotosProgresso(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
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
              _buildNavIcon(Icons.home_outlined, Icons.home, 0),
              _buildNavIcon(
                  Icons.calendar_today_outlined, Icons.calendar_today, 1),
              _buildNavIcon(Icons.history_outlined, Icons.history, 2),
              _buildNavIcon(
                  Icons.fitness_center_outlined, Icons.fitness_center, 3),
              _buildNavIcon(Icons.photo_camera_outlined, Icons.photo_camera, 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
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
