// lib/widgets/home/progress_photos_card_widget.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/screens/tela_fotos_progresso.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';

class ProgressPhotosCardWidget extends ConsumerWidget {
  const ProgressPhotosCardWidget({super.key});

  Future<Map<String, dynamic>?> _getUltimaFoto(WidgetRef ref) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final fotoServico = ref.read(fotoProgressoServicoProvider);
      final dados = await fotoServico.buscarFotosComparacao();
      return dados?['ultima'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Erro ao buscar última foto: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUltimaFoto(ref),
      builder: (context, snapshot) {
        final ultimaFoto = snapshot.data;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TelaFotosProgresso()),
            );
          },
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.accentPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ultimaFoto != null
                ? _buildCardComFoto(ultimaFoto)
                : _buildCardSemFoto(),
          ),
        );
      },
    );
  }

  Widget _buildCardComFoto(Map<String, dynamic> foto) {
    final data = (foto['data'] as Timestamp?)?.toDate();
    final diasAtras = data != null ? DateTime.now().difference(data).inDays : 0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                foto['urlFoto'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera,
                        color: Colors.white, size: 32),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fotos de Progresso',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diasAtras == 0
                        ? 'Última foto: hoje'
                        : 'Última foto: há $diasAtras dia${diasAtras > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardSemFoto() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.photo_camera, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fotos de Progresso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Registre sua primeira foto!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}
