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
  bool _modoEdicao = false;

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

  Future<void> _reiniciarProgresso(
      Map<String, dynamic> data, List<dynamic> exercicios) async {
    if (widget.treinoDocId.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    final exerciciosResetados = exercicios.map((e) {
      if (e is Map<String, dynamic>) {
        final novo = Map<String, dynamic>.from(e);
        // Tentativa de “reset” sem quebrar seu schema:
        novo['concluido'] = false;
        novo['status'] = 'pendente';
        novo['porcentagem'] = 0;
        // Se você usa cargaRealizada pra treino concluído:
        if (novo.containsKey('cargaRealizada')) novo['cargaRealizada'] = null;
        return novo;
      }
      return e;
    }).toList();

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .doc(widget.treinoDocId)
          .update({
        'concluido': false,
        'status': 'pendente',
        'porcentagem': 0,
        'tempoReal': 0,
        'caloriasQueimadas': 0,
        'exercicios': exerciciosResetados,
      });

      if (mounted) {
        setState(() {
          _modoEdicao = false;
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  String _formatarSegundosParaMinutos(dynamic segundosOuMinutos) {
    if (segundosOuMinutos == null) return "0 min";
    final valor = int.tryParse(segundosOuMinutos.toString()) ?? 0;

    // Se for > 100, assumimos que está em segundos e converte
    if (valor > 100) {
      return "${(valor / 60).round()} min";
    }
    return "$valor min";
  }

  double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

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
    AppStrings.of(context);

    final musculos = data['musculos'] as String? ?? 'Treino';
    final exercicios =
        List<dynamic>.from((data['exercicios'] as List<dynamic>?) ?? []);

    final bool isConcluido =
        data['concluido'] == true || (data['status'] == 'concluido');
    final porcentagem = (data['porcentagem'] as num?)?.toDouble() ?? 0.0;

    // Tempo exibido no “card-resumo”
    final tempoDisplay = isConcluido
        ? _formatarSegundosParaMinutos(data['tempoReal'])
        : "${data['tempoEstimado'] ?? 0} min";

    // Data (se existir)
    final createdAt =
        data['createdAt'] as Timestamp? ?? data['dataCriacao'] as Timestamp?;
    final dateDisplay = createdAt != null
        ? DateFormat('dd/MM/yyyy').format(createdAt.toDate())
        : '';

    // Progresso do card (no seu backend pode estar 0..100)
    final double progressoPct = isConcluido ? 100.0 : porcentagem;
    final double progresso01 = _clamp01(progressoPct / 100);

    // “Cara” do layout da imagem: título fixo, card resumo + lista clean + botões embaixo
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,

      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
        ),
        title: Text(
          'Exercícios',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          // lápis no topo (igual à imagem) para entrar/sair do modo edição
          if (!isConcluido && exercicios.isNotEmpty)
            IconButton(
              icon: Icon(
                _modoEdicao ? Icons.check : Icons.edit,
                color: AppColors.textDark,
              ),
              onPressed: () => setState(() => _modoEdicao = !_modoEdicao),
              tooltip: _modoEdicao ? 'Concluir edição' : 'Editar',
            )
          else
            const SizedBox(width: 48),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Card-resumo (igual ao topo da imagem)
            _buildResumoCard(
              context: context,
              titulo: musculos,
              subtitulo:
                  dateDisplay.isNotEmpty ? dateDisplay : '1 dia de exercício',
              tempo: isConcluido ? tempoDisplay : "~ $tempoDisplay",
              progresso01: progresso01,
              progressoTexto: "${progressoPct.round()}%",
            ),

            const SizedBox(height: 8),

            Expanded(
              child: exercicios.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum exercício encontrado.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textGray),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      buildDefaultDragHandles: false,
                      itemCount: exercicios.length,
                      onReorder: (!_modoEdicao || isConcluido)
                          ? (a, b) {}
                          : (oldIdx, newIdx) =>
                              _reordenarExercicios(oldIdx, newIdx, exercicios),
                      itemBuilder: (ctx, idx) {
                        final ex = exercicios[idx];
                        return Container(
                          key: ValueKey(
                              "${(ex is Map && ex['nome'] != null) ? ex['nome'] : 'ex'}_$idx"),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _buildLinhaExercicio(
                            context: context,
                            ex: (ex is Map<String, dynamic>)
                                ? ex
                                : <String, dynamic>{},
                            index: idx,
                            isConcluido: isConcluido,
                            modoEdicao: _modoEdicao,
                            // Se você tiver progresso por exercício, coloque em ex['porcentagem'].
                            progressoTexto: (isConcluido
                                ? '100%'
                                : ((ex is Map && ex['porcentagem'] != null)
                                    ? "${(ex['porcentagem'] as num).toStringAsFixed(0)}%"
                                    : "${progressoPct.toStringAsFixed(0)}%")),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Rodapé com dois botões (igual à imagem)
      bottomNavigationBar: exercicios.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // “Reiniciar o progresso” (outlined)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _reiniciarProgresso(data, exercicios),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color:
                                  AppColors.textDark.withValues(alpha: 0.25)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'REINICIAR O PROGRESSO',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.textDark,
                                    letterSpacing: 0.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // “Começar exercício” (filled)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TelaTreinoAtivo(workout: data)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(
                          (porcentagem > 0 && !isConcluido)
                              ? 'CONTINUAR EXERCÍCIO'
                              : 'COMEÇAR EXERCÍCIO',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.4,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResumoCard({
    required BuildContext context,
    required String titulo,
    required String subtitulo,
    required String tempo,
    required double progresso01,
    required String progressoTexto,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          // Anel de progresso
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progresso01,
                    strokeWidth: 5,
                    backgroundColor:
                        AppColors.primaryGreen.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen),
                  ),
                ),
                Text(
                  progressoTexto,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGray,
                      ),
                ),
              ],
            ),
          ),

          // Tempo à direita
          Text(
            tempo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaExercicio({
    required BuildContext context,
    required Map<String, dynamic> ex,
    required int index,
    required bool isConcluido,
    required bool modoEdicao,
    required String progressoTexto,
  }) {
    final nome = (ex['nome'] ?? 'Exercício').toString();
    final series = ex['series'] ?? 0;
    final reps = ex['repeticoes'] ?? 0;

    final String subtitle = "$series x $reps";

    // imagem (opcional): aceita URL http(s) ou asset path
    final dynamic img = ex['imagem'] ??
        ex['image'] ??
        ex['thumb'] ??
        ex['thumbnail'] ??
        ex['imagemUrl'];

    Widget thumb = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fitness_center, color: AppColors.textGray),
    );

    if (img is String && img.trim().isNotEmpty) {
      final s = img.trim();
      if (s.startsWith('http')) {
        thumb = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            s,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => thumb,
          ),
        );
      } else {
        // tenta como asset
        thumb = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            s,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => thumb,
          ),
        );
      }
    }

    return Row(
      children: [
        thumb,
        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textGray,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // coluna da direita: % + (quando em edição) edit + drag
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              progressoTexto,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (!isConcluido && modoEdicao) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    icon: const Icon(Icons.edit,
                        size: 20, color: AppColors.textGray),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TelaEditarExercicio(
                            exercicio: ex,
                            treinoDocId: widget.treinoDocId,
                            exercicioIndex: index,
                          ),
                        ),
                      );
                    },
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.drag_handle, color: AppColors.textGray),
                    ),
                  ),
                ],
              )
            ],
          ],
        ),
      ],
    );
  }
}
