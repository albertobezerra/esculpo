// lib/screens/tela_configuracoes_notificacoes.dart

import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/servicos/notification_service.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';

class TelaConfiguracoesNotificacoes extends StatefulWidget {
  const TelaConfiguracoesNotificacoes({super.key});

  @override
  State<TelaConfiguracoesNotificacoes> createState() =>
      _TelaConfiguracoesNotificacoesState();
}

class _TelaConfiguracoesNotificacoesState
    extends State<TelaConfiguracoesNotificacoes> {
  bool _notificacoesAtivas = true;

  @override
  void initState() {
    super.initState();
    _verificarNotificacoes();
  }

  Future<void> _verificarNotificacoes() async {
    final ativas = await NotificationService().areNotificationsEnabled();
    setState(() => _notificacoesAtivas = ativas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Aviso informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recebes notificações quando completares um treino e outras atividades importantes no app.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Card principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _notificacoesAtivas
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: _notificacoesAtivas
                            ? AppColors.primaryPurple
                            : AppColors.textGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado das Notificações',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _notificacoesAtivas ? 'Ativadas' : 'Desativadas',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _notificacoesAtivas
                                          ? AppColors.primaryGreen
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tipos de notificações
                _buildNotificationItem(
                  context,
                  Icons.emoji_events,
                  'Treino Concluído',
                  'Recebe parabéns ao completar todos os exercícios',
                  AppColors.primaryGreen,
                ),

                const SizedBox(height: 12),

                _buildNotificationItem(
                  context,
                  Icons.camera_alt,
                  'Fotos de Progresso',
                  'Lembretes para registar o teu progresso',
                  AppColors.accentOrange,
                ),

                const SizedBox(height: 20),

                // Botão de configurações do sistema
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Abre configurações do sistema
                      await openAppSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurações do Sistema'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primaryPurple),
                      foregroundColor: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGray,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
