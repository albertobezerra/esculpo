// lib/screens/tela_detalhe_treino.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'tela_treino_ativo.dart';
import 'tela_editar_exercicio.dart';

class TelaDetalheTreino extends StatefulWidget {
  final Map<String, dynamic> workout;
  final String treinoDocId;

  const TelaDetalheTreino({
    super.key,
    required this.workout,
    required this.treinoDocId,
  });

  @override
  State<TelaDetalheTreino> createState() => _TelaDetalheTreinoState();
}

class _TelaDetalheTreinoState extends State<TelaDetalheTreino> {
  void _reordenarExercicios(
      int oldIndex, int newIndex, List<dynamic> listaAtual) async {
    if (widget.treinoDocId.isEmpty) return;
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = listaAtual.removeAt(oldIndex);
      listaAtual.insert(newIndex, item);
    });
    HapticFeedback.lightImpact();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .doc(widget.treinoDocId)
          .update({'exercicios': listaAtual});
      // ignore: empty_catches
    } catch (e) {}
  }

  String _formatarSegundosParaMinutos(dynamic segundosOuMinutos) {
    if (segundosOuMinutos == null) return "0 min";
    int valor = int.tryParse(segundosOuMinutos.toString()) ?? 0;
    // Se for > 100, assumimos que está em segundos e converte
    if (valor > 100) {
      return "${(valor / 60).round()} min";
    }
    return "$valor min";
  }

  @override
  Widget build(BuildContext context) {
    if (widget.treinoDocId.isNotEmpty) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('treinos')
            .doc(widget.treinoDocId)
            .snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> currentWorkout = widget.workout;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            currentWorkout = {...data, 'treinoDocId': widget.treinoDocId};
          }
          return _buildContent(context, currentWorkout);
        },
      );
    }
    return _buildContent(context, widget.workout);
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    final strings = AppStrings.of(context);
    final musculos = data['musculos'] as String? ?? 'Treino';
    final exercicios =
        List<dynamic>.from((data['exercicios'] as List<dynamic>?) ?? []);

    // VERIFICAÇÃO DE CONCLUSÃO
    final bool isConcluido =
        data['concluido'] == true || (data['status'] == 'concluido');
    final porcentagem = (data['porcentagem'] as num?)?.toDouble() ?? 0.0;

    // --- LÓGICA DE EXIBIÇÃO CORRIGIDA ---

    // 1. TEMPO: Prioriza 'tempoReal' se concluído. Se não, usa 'tempoEstimado'.
    final tempoDisplay = isConcluido
        ? _formatarSegundosParaMinutos(data['tempoReal'])
        : "${data['tempoEstimado'] ?? 0} min";

    // 2. CALORIAS: O Pulo do Gato.
    // Prioriza 'caloriasQueimadas' (o que calculamos no final).
    // Se for nulo ou 0, tenta somar as calorias dos exercícios individuais.
    // Só em último caso usa 'caloriasEstimadas' (que deve ser o 1000 errado).
    String caloriasDisplay = "0 kcal";

    if (isConcluido) {
      double caloriasReais =
          (data['caloriasQueimadas'] as num?)?.toDouble() ?? 0.0;

      // Fallback: Se caloriasQueimadas vier zerado, recalcula somando os exercícios
      if (caloriasReais == 0 && exercicios.isNotEmpty) {
        for (var ex in exercicios) {
          // Assume ~50kcal se não tiver info, ou usa o campo do exercicio
          caloriasReais += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Se ainda for zero, aí sim usa o estimado (melhor que nada)
      if (caloriasReais == 0)
        caloriasReais = (data['caloriasEstimadas'] as num?)?.toDouble() ?? 0.0;

      caloriasDisplay = "${caloriasReais.toStringAsFixed(0)} kcal";
    } else {
      // Treino não feito: Mostra a estimativa do plano
      caloriasDisplay =
          "${(data['caloriasEstimadas'] as num?)?.toDouble() ?? 0} kcal";
    }

    // DATA
    final createdAt =
        data['createdAt'] as Timestamp? ?? data['dataCriacao'] as Timestamp?;
    final dateDisplay = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : '';

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
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textDark),
                  ),
                  Expanded(
                    child: Text(musculos,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center),
                  ),
                  if (isConcluido)
                    const Icon(Icons.check_circle,
                        color: AppColors.primaryGreen)
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // CARDS
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoCard(context, Icons.calendar_today,
                                dateDisplay, 'Data', AppColors.primaryPurple)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildInfoCard(
                                context,
                                isConcluido ? Icons.timer_off : Icons.timer,
                                tempoDisplay,
                                isConcluido ? 'Tempo Real' : strings.time,
                                AppColors.primaryGreen)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoCard(
                                context,
                                Icons.local_fire_department,
                                caloriasDisplay,
                                isConcluido ? 'Queimadas' : strings.calories,
                                AppColors.accentOrange)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildInfoCard(
                                context,
                                isConcluido ? Icons.flag : Icons.trending_up,
                                isConcluido
                                    ? 'Concluído'
                                    : '${porcentagem.toStringAsFixed(0)}%',
                                'Status',
                                AppColors.accentPink)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // LISTA
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exercicios.length,
                      onReorder: isConcluido
                          ? (a, b) {}
                          : (oldIdx, newIdx) =>
                              _reordenarExercicios(oldIdx, newIdx, exercicios),
                      proxyDecorator: (child, index, animation) => Material(
                          elevation: 8,
                          color: Colors.transparent,
                          child: child),
                      itemBuilder: (ctx, idx) {
                        final ex = exercicios[idx];
                        return Padding(
                          key: ValueKey("${ex['nome']}_$idx"),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildExercicioCard(
                              context, ex, idx, isConcluido),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // BOTÃO
            if (!isConcluido && exercicios.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration:
                    BoxDecoration(color: AppColors.cardWhite, boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5))
                ]),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TelaTreinoAtivo(workout: data)));
                    },
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: Text(
                        porcentagem > 0 ? 'Continuar Treino' : 'Iniciar Treino',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Cards mantidos iguais...
  Widget _buildInfoCard(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.subtleShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 12),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textGray)),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(BuildContext context, Map<String, dynamic> ex,
      int index, bool isReadOnly) {
    final nome = ex['nome'] ?? 'Exercicio';
    final series = ex['series'] ?? 0;
    final reps = ex['repeticoes'] ?? 0;
    // Se estiver concluído, tenta mostrar as cargas reais médias, senão a sugerida
    final carga = isReadOnly && ex['cargaRealizada'] != null
        ? ex['cargaRealizada']
        : (ex['cargaSugerida'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.subtleShadow),
      child: Row(
        children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple)))),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text("$series x $reps • ${carga}kg",
                  style: const TextStyle(color: AppColors.textGray)),
            ]),
          ),
          if (!isReadOnly)
            IconButton(
                icon:
                    const Icon(Icons.edit, size: 20, color: AppColors.textGray),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => TelaEditarExercicio(
                            exercicio: ex,
                            treinoDocId: widget.treinoDocId,
                            exercicioIndex: index)))),
          if (!isReadOnly)
            ReorderableDragStartListener(
                index: index,
                child: const Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        Icon(Icons.drag_handle, color: AppColors.textLight))),
        ],
      ),
    );
  }
}
