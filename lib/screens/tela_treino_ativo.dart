// lib/screens/tela_treino_ativo.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:confetti/confetti.dart';
import 'package:guarda_corpo_2024/servicos/notification_service.dart';
import 'package:vibration/vibration.dart';
import '../widgets/timer/timer_descanso_modal.dart';
import 'tela_detalhe_exercicio.dart';

class TelaTreinoAtivo extends StatefulWidget {
  final Map<String, dynamic> workout;
  const TelaTreinoAtivo({super.key, required this.workout});

  @override
  State<TelaTreinoAtivo> createState() => _TelaTreinoAtivoState();
}

class _TelaTreinoAtivoState extends State<TelaTreinoAtivo> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  late ConfettiController _confettiController;

  Timer? _timer;
  int _segundos = 0;
  bool _isRunning = true;
  bool _isFinalizing = false;

  List<Map<String, dynamic>> _exercicios = [];
  String _treinoDocId = '';
  // Controle de Expansão dos cards (para focar no exercício atual)
  int _expandedIndex = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _treinoDocId = widget.workout['treinoDocId'] ?? '';
    _carregarExercicios();
    _iniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _carregarExercicios() {
    List<dynamic> listaBruta =
        widget.workout['exercicios'] ?? widget.workout['treinos'] ?? [];

    // Preparação dos dados: Garantir que cada exercício tenha estrutura para séries individuais
    _exercicios = listaBruta.map((e) {
      final map = Map<String, dynamic>.from(e);

      // Se ainda não tem registro detalhado, cria baseado no planejado
      if (map['registroSeries'] == null) {
        int seriesTotal = (map['series'] as num?)?.toInt() ?? 3;
        map['registroSeries'] = List.generate(
            seriesTotal,
            (index) => {
                  'feito': false,
                  'peso': map['cargaSugerida'],
                  'reps': map['repeticoes'],
                });
      } else {
        // Converte de dynamic para List<Map> se vier do banco
        map['registroSeries'] = List<Map<String, dynamic>>.from(
            (map['registroSeries'] as List)
                .map((s) => Map<String, dynamic>.from(s)));
      }
      return map;
    }).toList();

    // Encontrar o primeiro exercício não concluído para expandir
    _expandedIndex =
        _exercicios.indexWhere((ex) => (ex['concluido'] ?? false) == false);
    if (_expandedIndex == -1) _expandedIndex = 0;
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _segundos++);
    });
  }

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
      } else {
        _iniciarTimer();
      }
      _isRunning = !_isRunning;
    });
  }

  // --- LÓGICA DE SÉRIE A SÉRIE ---
  Future<void> _marcarSerieFeita(int exercicioIndex, int serieIndex) async {
    final ex = _exercicios[exercicioIndex];
    final serieAtual = ex['registroSeries'][serieIndex];

    // Se já está feita, não faz nada (ou poderia permitir desmarcar, mas vamos focar em progresso)
    if (serieAtual['feito'] == true) return;

    // 1. Confirmação de Carga/Reps
    final cargaCtrl =
        TextEditingController(text: serieAtual['peso'].toString());
    final repsCtrl = TextEditingController(text: serieAtual['reps'].toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardWhite,
        title: Text("${ex['nome']} - Série ${serieIndex + 1}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: cargaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Carga (kg)', suffixText: 'kg'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(
                controller: repsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Repetições', suffixText: 'reps'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _salvarSerie(exercicioIndex, serieIndex,
                  double.tryParse(cargaCtrl.text), int.tryParse(repsCtrl.text));
            },
            child: const Text("Concluir Série"),
          )
        ],
      ),
    );
  }

  Future<void> _salvarSerie(
      int exIdx, int serieIdx, double? peso, int? reps) async {
    setState(() {
      _exercicios[exIdx]['registroSeries'][serieIdx]['feito'] = true;
      _exercicios[exIdx]['registroSeries'][serieIdx]['peso'] = peso;
      _exercicios[exIdx]['registroSeries'][serieIdx]['reps'] = reps;

      // Verifica se acabou todas as séries deste exercício
      bool todasFeitas =
          _exercicios[exIdx]['registroSeries'].every((s) => s['feito'] == true);
      _exercicios[exIdx]['concluido'] = todasFeitas;

      // Auto-expandir próximo exercício se este acabou
      if (todasFeitas && exIdx < _exercicios.length - 1) {
        _expandedIndex = exIdx + 1;
      }
    });

    if (await Vibration.hasVibrator()) Vibration.vibrate(duration: 50);

    // Salva progresso parcial
    if (_treinoDocId.isNotEmpty && user != null) {
      // Calcula % geral baseado em SÉRIES totais, não exercícios
      // Lógica simplificada: % baseada em exercícios concluídos para a Home
      int feitos = _exercicios.where((e) => e['concluido'] == true).length;
      double pct = feitos / _exercicios.length * 100;

      await _firestore
          .collection('usuarios')
          .doc(user!.uid)
          .collection('treinos')
          .doc(_treinoDocId)
          .update({
        'exercicios': _exercicios,
        'porcentagem': pct,
      });
    }

    // Timer de Descanso (Baseado no exercício)
    if (mounted) {
      final tempoDescanso = _exercicios[exIdx]['descansoSegundos'] ?? 60;
      showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => TimerDescansoModal(
                tempoInicialSegundos: tempoDescanso,
                onTimerFinalizado: () {},
              ));
    }
  }

  // --- FINALIZAÇÃO ---
  Future<void> _finalizarTreino() async {
    setState(() => _isFinalizing = true);
    _timer?.cancel();

    try {
      final batch = _firestore.batch();
      final userId = user!.uid;

      // Calcular calorias reais baseadas em séries feitas
      // (Ex: 10 kcal por série média)
      double caloriasReais = 0;
      for (var ex in _exercicios) {
        for (var s in ex['registroSeries']) {
          if (s['feito'] == true) {
            caloriasReais +=
                (ex['calorias'] ?? 30) / (ex['registroSeries'] as List).length;
          }
        }
      }

      // 1. Salva Histórico
      final historicoRef = _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('historico_concluido')
          .doc();
      batch.set(historicoRef, {
        ...widget.workout,
        'exercicios': _exercicios,
        'tempoReal': _segundos, // Salva o tempo REAL do cronômetro
        'caloriasQueimadas': caloriasReais,
        'finalizadoEm': FieldValue.serverTimestamp(),
        'status': 'concluido',
      });

      // 2. Atualiza Agenda (Não deleta!)
      if (_treinoDocId.isNotEmpty) {
        final agendaRef = _firestore
            .collection('usuarios')
            .doc(userId)
            .collection('treinos')
            .doc(_treinoDocId);
        batch.update(agendaRef, {
          'concluido': true,
          'porcentagem': 100.0,
          'tempoReal':
              _segundos, // Atualiza o tempo na agenda também para a Home ler
          'caloriasQueimadas': caloriasReais,
          'status': 'concluido',
        });
      }

      await batch.commit();
      _confettiController.play();
      NotificationService().showNotification(
          title: 'Treino Concluído!', body: 'Parabéns! Foco total.');

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Treino Finalizado! 🏆"),
            content: Text("Tempo Total: ${_formatarTempo(_segundos)}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Fecha TelaTreinoAtivo
                  Navigator.pop(context); // Fecha TelaDetalheTreino
                },
                child: const Text("FINALIZAR"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // ✅ Adicione esta verificação
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  String _formatarTempo(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Contagem de séries totais vs feitas para barra de progresso mais precisa
    int totalSeries = 0;
    int feitasSeries = 0;
    for (var ex in _exercicios) {
      var series = ex['registroSeries'] as List;
      totalSeries += series.length;
      feitasSeries += series.where((s) => s['feito'] == true).length;
    }
    double progress = totalSeries > 0 ? feitasSeries / totalSeries : 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // HEADER TIMER
                Container(
                  padding: const EdgeInsets.all(24),
                  color: AppColors.backgroundLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: () => Navigator.pop(context)),
                      Column(
                        children: [
                          const Text("TEMPO DECORRIDO",
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1,
                                  color: AppColors.textGray)),
                          GestureDetector(
                            onTap: _toggleTimer,
                            child: Text(_formatarTempo(_segundos),
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Monospace',
                                    color: _isRunning
                                        ? AppColors.textDark
                                        : AppColors.textGray)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                LinearProgressIndicator(
                    value: progress,
                    color: AppColors.primaryGreen,
                    backgroundColor: Colors.grey[200],
                    minHeight: 6),

                // LISTA DE EXERCÍCIOS (EXPANDABLE)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercicios.length + 1,
                    itemBuilder: (ctx, idx) {
                      if (idx == _exercicios.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: ElevatedButton(
                            onPressed: _isFinalizing ? null : _finalizarTreino,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.all(20)),
                            child: _isFinalizing
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("FINALIZAR TREINO",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                      return _buildExercicioCard(idx);
                    },
                  ),
                ),
              ],
            ),
          ),
          Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false)),
        ],
      ),
    );
  }

  Widget _buildExercicioCard(int index) {
    final ex = _exercicios[index];
    final bool isConcluido = ex['concluido'] == true;
    final bool isExpanded = _expandedIndex == index;
    final List series = ex['registroSeries'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConcluido ? AppColors.primaryGreen : Colors.transparent,
          width: 2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == _expandedIndex,
          onExpansionChanged: (val) {
            if (val) setState(() => _expandedIndex = index);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

          // ÍCONE DE STATUS À ESQUERDA
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConcluido
                  ? AppColors.primaryGreen
                  : AppColors.primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConcluido ? Icons.check : Icons.fitness_center,
              color: isConcluido ? Colors.white : AppColors.primaryPurple,
              size: 20,
            ),
          ),

          // TÍTULO COM BOTÃO DE INFO
          title: Row(
            children: [
              Expanded(
                child: Text(
                  ex['nome'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline,
                    color: AppColors.primaryPurple, size: 22),
                constraints:
                    const BoxConstraints(), // Remove padding extra do IconButton
                padding: const EdgeInsets.only(left: 8),
                onPressed: () {
                  // Abre a tela de detalhes (manual) do exercício
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaDetalheExercicio(exercicio: ex),
                    ),
                  );
                },
              ),
            ],
          ),

          subtitle: Text(
            "${series.where((s) => s['feito']).length}/${series.length} séries",
            style: const TextStyle(color: Colors.grey),
          ),

          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: List.generate(series.length, (serieIdx) {
                  final s = series[serieIdx];
                  final bool feita = s['feito'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: feita
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            feita ? AppColors.primaryGreen : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // NÚMERO DA SÉRIE
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: feita
                                    ? AppColors.primaryGreen
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${serieIdx + 1}",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: feita
                                          ? Colors.white
                                          : Colors.black54),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // INFO DA CARGA
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feita
                                      ? "${s['peso']}kg"
                                      : "${ex['cargaSugerida']}kg",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: feita
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  feita
                                      ? "${s['reps']} reps"
                                      : "${ex['repeticoes']} reps (meta)",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // AÇÃO (CHECK / BOTÃO)
                        if (feita)
                          IconButton(
                            icon: const Icon(Icons.undo,
                                color: Colors.grey, size: 20),
                            onPressed: () {
                              // Opcional: Permitir desfazer
                              setState(() {
                                _exercicios[index]['registroSeries'][serieIdx]
                                    ['feito'] = false;
                                _exercicios[index]['concluido'] =
                                    false; // Reabre o exercício
                              });
                            },
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _marcarSerieFeita(index, serieIdx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text(
                              "CONCLUIR",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          )
                      ],
                    ),
                  );
                }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
