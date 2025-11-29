// lib/screens/tela_treino_ativo.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:confetti/confetti.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  bool _isRunning = false;

  List<Map<String, dynamic>> _exercicios = [];
  double _calorias = 0;
  int _heartRate = 0;

  bool _mostrarParabens = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    debugPrint('🚀 Iniciando TelaTreinoAtivo');
    debugPrint('📦 Workout recebido: ${widget.workout.keys}');

    _carregarExercicios();
    _simularHeartRate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _carregarExercicios() {
    // Tentar múltiplas chaves possíveis
    List<dynamic>? exerciciosRaw;

    // Tentar 'treinos' primeiro
    if (widget.workout.containsKey('treinos')) {
      exerciciosRaw = widget.workout['treinos'] as List<dynamic>?;
      debugPrint(
          '📍 Encontrado ${exerciciosRaw?.length ?? 0} items em "treinos"');
    }

    // Se não encontrou ou está vazio, tentar 'exercicios'
    if ((exerciciosRaw == null || exerciciosRaw.isEmpty) &&
        widget.workout.containsKey('exercicios')) {
      exerciciosRaw = widget.workout['exercicios'] as List<dynamic>?;
      debugPrint(
          '📍 Encontrado ${exerciciosRaw?.length ?? 0} items em "exercicios"');
    }

    if (exerciciosRaw == null || exerciciosRaw.isEmpty) {
      debugPrint('❌ ERRO: Nenhum exercício encontrado!');
      debugPrint('🔍 Estrutura completa do workout:');
      widget.workout.forEach((key, value) {
        debugPrint('   - $key: ${value.runtimeType}');
      });

      // Mostrar alerta ao usuário
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum exercício encontrado neste treino'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }

    setState(() {
      _exercicios = (exerciciosRaw ?? [])
          .map((e) {
            if (e is Map<String, dynamic>) {
              return e;
            } else if (e is Map) {
              return Map<String, dynamic>.from(e);
            } else {
              debugPrint('⚠️ Item inválido: $e (${e.runtimeType})');
              return <String, dynamic>{};
            }
          })
          .where((e) => e.isNotEmpty)
          .toList();

      debugPrint('✅ ${_exercicios.length} exercícios carregados');

      // Mostrar detalhes dos exercícios
      for (var i = 0; i < _exercicios.length; i++) {
        debugPrint('   Exercício $i: ${_exercicios[i]['nome'] ?? 'Sem nome'}');
      }

      // Calcular calorias iniciais
      for (var ex in _exercicios) {
        if (ex['concluido'] == true) {
          _calorias += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
        }
      }

      debugPrint('🔥 Calorias iniciais: $_calorias kcal');
    });
  }

  void _simularHeartRate() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_isRunning) {
        setState(() {
          _heartRate = 120 + (DateTime.now().second % 20);
        });
      }
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _segundos++);
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  Future<void> _marcarExercicioConcluido(int index) async {
    final jaEstaConcluido = _exercicios[index]['concluido'] ?? false;

    setState(() {
      _exercicios[index]['concluido'] = !jaEstaConcluido;

      // Atualizar calorias
      if (_exercicios[index]['concluido'] == true) {
        _calorias +=
            (_exercicios[index]['calorias'] as num?)?.toDouble() ?? 0.0;
      } else {
        _calorias -=
            (_exercicios[index]['calorias'] as num?)?.toDouble() ?? 0.0;
      }
    });

    // Feedback háptico
    if (await Vibration.hasVibrator()) {
      if (_exercicios[index]['concluido'] == true) {
        Vibration.vibrate(duration: 50);
      }
    }

    // Verificar se completou todos
    final todosConcluidos = _exercicios.every((e) => e['concluido'] == true);
    if (todosConcluidos && !_mostrarParabens) {
      _mostrarDialogParabens();
    }

    // Salvar no Firestore
    await _salvarProgresso();
  }

  void _mostrarDialogParabens() {
    setState(() => _mostrarParabens = true);
    _confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 64,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '🎉 Parabéns!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Você completou todos os exercícios!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textGray,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${_calorias.toStringAsFixed(0)} kcal queimadas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(); // Volta pra tela inicial
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                  ),
                  child: const Text('Finalizar'),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 300.ms, curve: Curves.elasticOut).fadeIn(),
    );
  }

  Future<void> _salvarProgresso() async {
    if (user == null) return;

    final createdAt = widget.workout['createdAt'] as Timestamp?;
    if (createdAt == null) return;

    final date = createdAt.toDate();
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Calcular porcentagem
    int totalSeries = 0;
    int seriesConcluidas = 0;
    for (var ex in _exercicios) {
      final series = (ex['series'] as num?)?.toInt() ?? 0;
      totalSeries += series;
      if (ex['concluido'] == true) seriesConcluidas += series;
    }
    final porcentagem =
        totalSeries > 0 ? (seriesConcluidas / totalSeries) * 100 : 0.0;

    await _firestore
        .collection('usuarios')
        .doc(user!.uid)
        .collection('treinos')
        .doc(normalizedDate.toIso8601String())
        .update({
      'exercicios': _exercicios,
      'porcentagem': porcentagem,
      'ultimaAtualizacao': FieldValue.serverTimestamp(),
    });
  }

  String _formatarTempo(int segundos) {
    final horas = segundos ~/ 3600;
    final minutos = (segundos % 3600) ~/ 60;
    final segs = segundos % 60;
    return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final musculos = widget.workout['musculos'] ?? 'Treino';

    final totalExercicios = _exercicios.length;
    final concluidos = _exercicios.where((e) => e['concluido'] == true).length;
    final porcentagemConclusao =
        totalExercicios > 0 ? (concluidos / totalExercicios * 100).toInt() : 0;

    // DEBUG
    debugPrint('🎨 BUILD - Total exercícios: $totalExercicios');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_isRunning) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Sair do treino?'),
                                content: const Text(
                                    'O cronômetro está rodando. Deseja realmente sair?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Sair'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios),
                        color: AppColors.textDark,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              musculos,
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$concluidos/$totalExercicios exercícios',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textGray,
                                  ),
                            ),
                          ],
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

                // BARRA DE PROGRESSO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$porcentagemConclusao%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: totalExercicios > 0
                              ? porcentagemConclusao / 100
                              : 0,
                          backgroundColor:
                              AppColors.textLight.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // CONTEÚDO SCROLLÁVEL
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // MÉTRICAS
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                Icons.local_fire_department,
                                _calorias.toStringAsFixed(0),
                                strings.kcal,
                                strings.calories,
                                AppColors.accentOrange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                Icons.favorite,
                                '$_heartRate',
                                'bpm',
                                'Heart Rate',
                                AppColors.accentPink,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // TIMER
                        _buildTimerCard(),

                        const SizedBox(height: 24),

                        // LISTA DE EXERCÍCIOS - VERSÃO CORRIGIDA
                        // LISTA DE EXERCÍCIOS - VERSÃO ULTRA SIMPLIFICADA
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Exercícios ($totalExercicios)',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),

                              // EXERCÍCIO 1
                              if (_exercicios.isNotEmpty)
                                _buildExercicioItem(0),
                              if (_exercicios.length > 1) ...[
                                const SizedBox(height: 12),
                                _buildExercicioItem(1),
                              ],
                              if (_exercicios.length > 2) ...[
                                const SizedBox(height: 12),
                                _buildExercicioItem(2),
                              ],
                              if (_exercicios.length > 3) ...[
                                const SizedBox(height: 12),
                                _buildExercicioItem(3),
                              ],
                              if (_exercicios.length > 4) ...[
                                const SizedBox(height: 12),
                                _buildExercicioItem(4),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // BOTÃO PLAY/PAUSE FIXO
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
                    child: ElevatedButton(
                      onPressed: _toggleTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRunning ? AppColors.error : AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRunning ? 'Pausar Treino' : 'Iniciar Treino',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONFETTI
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                AppColors.primaryGreen,
                AppColors.primaryPurple,
                AppColors.accentOrange,
                AppColors.accentPink,
              ],
              numberOfParticles: 30,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    String value,
    String unit,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textGray,
                ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tempo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatarTempo(_segundos),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercicioItem(int index) {
    final ex = _exercicios[index];
    final nome = ex['nome'] ?? 'Exercício ${index + 1}';
    final series = ex['series'] ?? 0;
    final repeticoes = ex['repeticoes'] ?? 0;
    final concluido = ex['concluido'] ?? false;

    return GestureDetector(
      onTap: () => _marcarExercicioConcluido(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: concluido
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: concluido ? AppColors.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: concluido ? AppColors.primaryGreen : Colors.transparent,
                border: Border.all(
                  color:
                      concluido ? AppColors.primaryGreen : AppColors.textLight,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: concluido
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          decoration:
                              concluido ? TextDecoration.lineThrough : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$series séries × $repeticoes reps',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textGray,
                        ),
                  ),
                ],
              ),
            ),
            if (concluido)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '✓',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
