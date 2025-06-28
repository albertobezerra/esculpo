import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guarda_corpo_2024/services/plan_generator_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'tela_treino.dart';
import 'tela_detalhe_treino.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const TelaInicial(),
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
  ];
  bool hasNotification = false;
  DateTime _focusedDay = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final PlanGeneratorService _planGenerator = PlanGeneratorService();
  bool _showCreatePlanDialog = false;

  @override
  void initState() {
    super.initState();
    _suggestAndSavePlanIfNeeded(); // Verifica e sugere plano ao iniciar
  }

  Future<void> _suggestAndSavePlanIfNeeded() async {
    if (user == null) return;
    final userId = user!.uid;
    final planDoc = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('planos_treino')
        .doc('personalized')
        .get();
    if (!planDoc.exists) {
      await _suggestAndSavePlan(); // Gera plano apenas se não existir
    }
  }

  Future<void> _suggestAndSavePlan() async {
    if (user == null) return;
    final userId = user!.uid;
    try {
      // Verificar se os dados do onboarding existem na subcoleção
      final onboardingSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();
      if (!onboardingSnapshot.exists) {
        debugPrint('Dados de onboarding não encontrados. Criando padrão...');
        await _firestore
            .collection('usuarios')
            .doc(userId)
            .collection('onboarding')
            .doc('data')
            .set({
          'peso': 70.0, // Valor padrão
          'altura': 170.0, // Valor padrão
          'frequencia': 3, // Valor padrão
        });
      }

      // Gerar o plano com os dados disponíveis
      await _planGenerator.generateTrainingPlan(userId, customDays: 5);
    } catch (e) {
      debugPrint('Erro ao sugerir plano: $e');
    }
  }

  Future<void> _generatePlan() async {
    if (user == null) return;
    try {
      await _planGenerator.generateTrainingPlan(user!.uid, customDays: 5);
      setState(() => _showCreatePlanDialog = false); // Recarrega a UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plano de treino gerado com sucesso!')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao gerar plano: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar plano: $e')),
        );
      }
    }
  }

  void _showCreatePlanOptions() {
    setState(() => _showCreatePlanDialog = true);
  }

  Future<Map<String, dynamic>?> _getActiveWorkout(DateTime date) async {
    if (user == null) return null;
    final userId = user!.uid;
    final dayOfWeek = date.weekday; // 1 = Segunda, ..., 7 = Domingo
    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      final planosSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('planos_treino')
          .doc('personalized')
          .get();

      Map<String, dynamic>? plano;
      if (!planosSnapshot.exists) {
        return {
          'tipo': 'Nenhum',
          'musculos': 'Nenhum plano de treino ativo'.toUpperCase(),
          'porcentagem': 0.0,
          'treinos': [],
          'createdAt': null,
          'tempoEstimado': 0,
          'caloriasEstimadas': 0.0,
        };
      } else {
        plano = planosSnapshot.data();
      }

      final treinos = plano?['treinos'] as List<dynamic>? ?? [];
      final treinoIndex = (dayOfWeek - 1) %
          (plano?['frequenciaTreino'] as int? ?? treinos.length);

      if (treinoIndex >= treinos.length) {
        return {
          'tipo': 'Nenhum',
          'musculos': 'Nenhum treino para hoje'.toUpperCase(),
          'porcentagem': 0.0,
          'treinos': [],
          'createdAt': null,
          'tempoEstimado': 0,
          'caloriasEstimadas': 0.0,
        };
      }

      final treino = treinos[treinoIndex];
      final exercicios = treino['exercicios'] as List<dynamic>? ?? [];
      final musculosMap = {
        'Peito': 'Peito, Tríceps',
        'Costas': 'Costas, Bíceps',
        'Pernas': 'Quadríceps, Glúteos, Panturrilhas',
        'Ombros': 'Ombros',
        'Abdômen': 'Core',
      };

      final musculosList = exercicios.map((ex) {
        final group = ex['grupoMuscular'] as String?;
        return musculosMap[group] ?? 'Músculos não mapeados';
      }).toList();

      int tempoEstimado = 0;
      double caloriasEstimadas = 0.0;
      final onboardingData = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('onboarding')
          .doc('data')
          .get();
      final peso = onboardingData.data()?['peso']?.toDouble() ?? 70.0;
      for (var ex in exercicios) {
        final series = ex['series'] as int? ?? 0;
        final repeticoes = ex['repeticoes'] as int? ?? 0;
        tempoEstimado += series * (repeticoes * 3 + 60);
        caloriasEstimadas += series * repeticoes * 0.5 * (peso / 70);
      }
      tempoEstimado = (tempoEstimado / 60).round();

      final treinoSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      double porcentagem = 0.0;
      if (treinoSnapshot.docs.isNotEmpty) {
        final workout = treinoSnapshot.docs.first.data();
        final exerciciosList = workout['exercicios'] as List<dynamic>? ?? [];
        int totalSeries = 0;
        int seriesConcluidas = 0;
        for (var ex in exerciciosList) {
          final series = (ex['series'] as num?)?.toInt() ?? 0;
          totalSeries += series;
          if (ex['concluido'] == true) seriesConcluidas += series;
        }
        porcentagem =
            totalSeries > 0 ? (seriesConcluidas / totalSeries) * 100 : 0.0;
      }

      return {
        'treinos': [
          {
            'exercicios': exercicios,
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'tempoEstimado': tempoEstimado,
        'caloriasEstimadas': caloriasEstimadas,
        'tipo': treino['nome'] ?? 'Treino',
        'musculos': musculosList.isNotEmpty
            ? musculosList.join(', ').toUpperCase()
            : 'Sem informações de músculos'.toUpperCase(),
        'porcentagem': porcentagem,
      };
    } catch (e) {
      debugPrint('Erro ao obter treino ativo: $e');
      return {
        'tipo': 'Erro',
        'musculos': 'Erro ao carregar treino'.toUpperCase(),
        'porcentagem': 0.0,
        'treinos': [],
        'createdAt': null,
        'tempoEstimado': 0,
        'caloriasEstimadas': 0.0,
      };
    }
  }

  Future<Map<String, double>> _getProgressData() async {
    if (user == null) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
    final userId = user!.uid;
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);

    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      double calorias = 0.0;
      double pesoLevantado = 0.0;
      double tempoCardio = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final exercicios = data['exercicios'] as List<dynamic>? ?? [];
        for (var ex in exercicios) {
          calorias += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
          pesoLevantado += (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
          tempoCardio += (ex['duracao'] as num?)?.toDouble() ?? 0.0;
        }
      }

      return {
        'calorias': calorias,
        'pesoLevantado': pesoLevantado,
        'tempoCardio': tempoCardio
      };
    } catch (e) {
      debugPrint('Erro ao obter progresso: $e');
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now(); // 11:45 PM WEST, 26 de junho de 2025
    final String formattedDate =
        DateFormat('EEE, dd \'DE\' MMMM \'DE\' yyyy', 'pt_BR')
            .format(now)
            .toUpperCase();
    final int hour = now.hour;
    String greeting = 'Bom dia,';
    if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde,';
    } else if (hour >= 18 || hour < 6) {
      greeting = 'Boa noite,';
    }
    final userName = user?.displayName ?? 'Usuário';

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF9D291A),
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          greeting.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox.shrink(),
                        Text(
                          userName.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFF9D291A),
                            fontSize: 38,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox.shrink(),
                        Text(
                          formattedDate,
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: hasNotification
                          ? const Color(0xFF9D291A)
                          : AppTheme.theme.colorScheme.surface,
                      child: IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Color.fromARGB(255, 225, 225, 225),
                            size: 20),
                        onPressed: () {
                          setState(() {
                            hasNotification = !hasNotification;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Treino do Dia
                Text(
                  'HOJE É DIA DE TREINAR'.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _getActiveWorkout(now),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final workout = snapshot.data ??
                          {
                            'tipo': 'Nenhum',
                            'musculos':
                                'Nenhum plano de treino ativo'.toUpperCase(),
                            'porcentagem': 0.0,
                          };
                      return GestureDetector(
                        onTap: () {
                          if (workout['tipo'] == 'Nenhum' &&
                              workout['musculos'] ==
                                  'Nenhum plano de treino ativo'
                                      .toUpperCase()) {
                            _showCreatePlanOptions();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const TelaTreino()),
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9D291A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout['musculos'],
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 30,
                                  color: Colors.white,
                                ),
                              ),
                              if (workout['musculos'] ==
                                  'Nenhum plano de treino ativo'.toUpperCase())
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ElevatedButton(
                                    onPressed: _showCreatePlanOptions,
                                    child: const Text('Criar Plano de Treino'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Calendário de Treinos
                Text(
                  'CALÉNDARIO DE TREINOS'.toUpperCase(),
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _getActiveWorkout(
                              now.subtract(const Duration(days: 1))),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {
                                  'tipo': 'Nenhum',
                                  'musculos': 'Sem treino',
                                  'porcentagem': 0.0
                                };
                            return _buildDayCard(
                                now.subtract(const Duration(days: 1)),
                                data['tipo'],
                                data['porcentagem'],
                                Colors.grey);
                          },
                        ),
                      ),
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _getActiveWorkout(now),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {
                                  'tipo': 'Nenhum',
                                  'musculos': 'Sem treino',
                                  'porcentagem': 0.0
                                };
                            return _buildDayCard(
                                now,
                                data['tipo'],
                                data['porcentagem'],
                                AppTheme.theme.colorScheme.secondary);
                          },
                        ),
                      ),
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _getActiveWorkout(
                              now.add(const Duration(days: 1))),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {
                                  'tipo': 'Nenhum',
                                  'musculos': 'Sem treino',
                                  'porcentagem': 0.0
                                };
                            return _buildDayCard(
                                now.add(const Duration(days: 1)),
                                data['tipo'],
                                data['porcentagem'],
                                Colors.grey);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Progresso
                const Text('PROGRESSO',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9D291A))),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, double>>(
                  future: _getProgressData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final progress = snapshot.data ??
                        {
                          'calorias': 0.0,
                          'pesoLevantado': 0.0,
                          'tempoCardio': 0.0
                        };
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGauge(
                            'Calorias',
                            progress['calorias']!,
                            500,
                            '${progress['calorias']!.toStringAsFixed(0)}kcal',
                            'Calorias gastas no treino'),
                        _buildGauge(
                            'Peso Levantado',
                            progress['pesoLevantado']!,
                            200,
                            '${progress['pesoLevantado']!.toStringAsFixed(0)}kg',
                            'Peso total levantado'),
                        _buildGauge(
                            'Tempo Cardio',
                            progress['tempoCardio']!,
                            60,
                            '${progress['tempoCardio']!.toStringAsFixed(0)}min',
                            'Tempo de cardio'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index != 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => _pages[index]),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today), label: 'Planos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'Histórico'),
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_run), label: 'Exercícios'),
          ],
          selectedItemColor: AppTheme.theme.colorScheme.primary,
          unselectedItemColor: AppTheme.theme.colorScheme.onPrimary,
          backgroundColor: AppTheme.theme.scaffoldBackgroundColor,
        ),
        // Diálogo para criar plano
        bottomSheet: _showCreatePlanDialog
            ? Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Como deseja criar o plano?',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generatePlan,
                      child: const Text(
                          'Gerar Automaticamente (com base no Onboarding)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Criação manual ainda não implementada')),
                        );
                        setState(() => _showCreatePlanDialog = false);
                      },
                      child: const Text('Criar Manualmente'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showCreatePlanDialog = false),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildDayCard(
      DateTime date, String treino, double porcentagem, Color backgroundColor) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _focusedDay = date;
        });
        final workout = await _getActiveWorkout(date);
        if (workout != null &&
            (workout['treinos'] as List?)?.isNotEmpty == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaDetalheTreino(workout: workout),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Nenhum treino disponível para este dia')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: _focusedDay == date
              ? Border.all(color: AppTheme.theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text('${date.day}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              //const SizedBox(height: 8),
              Center(
                child: Text(treino,
                    style: AppTheme.theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.theme.colorScheme.onPrimary)),
              ),
              Text('${porcentagem.toStringAsFixed(0)}%',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9D291A))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGauge(String title, double value, double maxValue, String label,
      String description) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: maxValue,
                showLabels: false,
                showTicks: false,
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: value,
                    color: AppTheme.theme.colorScheme.secondary,
                  ),
                  GaugeRange(
                    startValue: value,
                    endValue: maxValue,
                    color: AppTheme.theme.colorScheme.surface.withAlpha(77),
                  ),
                ],
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 0.1,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: AppTheme.theme.colorScheme.secondary,
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(label,
                        style: AppTheme.theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.theme.colorScheme.onPrimary)),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(description,
            textAlign: TextAlign.center,
            style: AppTheme.theme.textTheme.bodySmall),
      ],
    );
  }
}
