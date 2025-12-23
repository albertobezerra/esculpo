// lib/screens/tela_detalhe_treino.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:intl/intl.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
// Import do nosso Timer (ajuste o caminho se necessário)
import '../widgets/timer/timer_descanso_modal.dart';
import 'tela_treino_ativo.dart';
import 'tela_editar_exercicio.dart';

class TelaDetalheTreino extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String treinoDocId; // id do doc em /treinos

  const TelaDetalheTreino({
    super.key,
    required this.workout,
    required this.treinoDocId,
  });

  // --- LÓGICA NOVA: Marcar como feito e Abrir Timer ---
  Future<void> _toggleConcluido(BuildContext context, int index,
      Map<String, dynamic> exercicioAtual) async {
    if (treinoDocId.isEmpty)
      return; // Não faz nada se for só visualização do plano

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .doc(treinoDocId);

    try {
      // 1. Busca o treino atual para garantir que temos a lista sincronizada
      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> exercicios =
          List.from((data['exercicios'] as List<dynamic>?) ?? []);

      // 2. Modifica o status do exercício clicado
      bool novoStatus = !(exercicioAtual['concluido'] as bool? ?? false);

      // Atualiza o mapa do exercício dentro da lista
      Map<String, dynamic> exercicioEditado = Map.from(exercicios[index]);
      exercicioEditado['concluido'] = novoStatus;
      exercicios[index] = exercicioEditado;

      // 3. Salva no Firestore
      await docRef.update({'exercicios': exercicios});

      // 4. SE marcou como concluído -> ABRE O TIMER!
      if (novoStatus && context.mounted) {
        // Vibra para dar feedback tátil
        HapticFeedback.mediumImpact();

        final tempoDescanso =
            exercicioEditado['descansoSegundos'] as int? ?? 60;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => TimerDescansoModal(
            tempoInicialSegundos: tempoDescanso,
            onTimerFinalizado: () {
              // Opcional: Tocar som aqui futuramente
              print("Descanso finalizado!");
            },
          ),
        );
      }
    } catch (e) {
      print("Erro ao atualizar exercício: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se temos um ID de treino válido (não é visualização de plano),
    // ouvimos o Firestore em tempo real.
    if (treinoDocId.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('treinos')
            .doc(treinoDocId)
            .snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> currentWorkout = workout;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentWorkout = {
              ...data,
              'treinoDocId': treinoDocId,
            };
          }

          return _buildContent(context, currentWorkout);
        },
      );
    }

    return _buildContent(context, workout);
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final strings = AppStrings.of(context);
    final musculos = data['musculos'] as String? ?? 'Treino';
    final exercicios = (data['exercicios'] as List<dynamic>?) ??
        (data['treinos'] as List<dynamic>?) ??
        [];
    final tempoEstimado = data['tempoEstimado'] as int? ?? 0;
    final caloriasEstimadas =
        (data['caloriasEstimadas'] as num?)?.toDouble() ?? 0.0;
    final createdAt =
        data['createdAt'] as Timestamp? ?? data['dataCriacao'] as Timestamp?;
    final porcentagem = (data['porcentagem'] as num?)?.toDouble() ?? 0.0;

    String formattedDate = '';
    if (createdAt != null) {
      formattedDate = DateFormat('dd/MM/yyyy').format(createdAt.toDate());
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: AppColors.textDark,
                  ),
                  Expanded(
                    child: Text(
                      musculos,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz),
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),

            // CONTEÚDO
            Expanded(
              child: exercicios.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            size: 80,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum exercício',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.textGray),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // INFO CARDS
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  Icons.calendar_today,
                                  formattedDate,
                                  'Data',
                                  AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  Icons.timer,
                                  '$tempoEstimado min',
                                  strings.time,
                                  AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  Icons.local_fire_department,
                                  '${caloriasEstimadas.toStringAsFixed(0)} kcal',
                                  strings.calories,
                                  AppColors.accentOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  context,
                                  Icons.trending_up,
                                  '${porcentagem.toStringAsFixed(0)}%',
                                  strings.progress,
                                  AppColors.accentPink,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // EXERCÍCIOS
                          Text(
                            'Exercícios',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),

                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: exercicios.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ex =
                                  exercicios[index] as Map<String, dynamic>;
                              return _buildExercicioCard(
                                context,
                                ex,
                                index,
                              );
                            },
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),

            // BOTÃO INICIAR TREINO
            if (exercicios.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TelaTreinoAtivo(workout: data),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: Text(
                      porcentagem > 0 ? 'Continuar Treino' : 'Iniciar Treino',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textGray,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(
    BuildContext context,
    Map<String, dynamic> ex,
    int index,
  ) {
    final nome = ex['nome'] as String? ?? 'Exercício ${index + 1}';
    final series = ex['series'] as int? ?? 0;
    final repeticoes = ex['repeticoes'] as int? ?? 0;
    final carga = (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
    final descanso = ex['descansoSegundos'] as int? ?? 60;
    final concluido = ex['concluido'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: concluido ? AppColors.primaryGreen : Colors.transparent,
          width: 2,
        ),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          // --- ÁREA DE CLIQUE: BOLINHA ---
          InkWell(
            onTap: () => _toggleConcluido(context, index, ex),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: concluido
                    ? AppColors.primaryGreen
                    : AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: concluido
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
              ),
            ),
          ),
          // ------------------------------

          const SizedBox(width: 16),

          // texto do exercício
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildDetail(Icons.fitness_center, '$series séries'),
                    _buildDetail(Icons.repeat, '$repeticoes reps'),
                    if (carga > 0)
                      _buildDetail(
                        Icons.line_weight,
                        '${carga.toStringAsFixed(1)} kg',
                      ),
                    _buildDetail(Icons.timer, '${descanso}s'),
                  ],
                ),
              ],
            ),
          ),

          // botão lápis
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppColors.textGray),
            onPressed: treinoDocId.isEmpty
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaEditarExercicio(
                          exercicio: ex,
                          treinoDocId: treinoDocId,
                          exercicioIndex: index,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textGray),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textGray,
          ),
        ),
      ],
    );
  }
}
