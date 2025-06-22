import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'tela_treino.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart'; // Importe o tema correto

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const SizedBox(), // Placeholder para evitar loop infinito
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
  ];
  bool hasNotification = false;
  DateTime _focusedDay = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  // Função para buscar treino do dia
  Future<Map<String, dynamic>?> _getTodayWorkout() async {
    if (user == null) return null;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final userId = user!.uid;

    final planosSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('planos')
        .where('dataInicio', isLessThanOrEqualTo: normalizedToday)
        .orderBy('dataInicio', descending: true)
        .limit(1)
        .get();

    if (planosSnapshot.docs.isEmpty) return null;

    final plano = planosSnapshot.docs.first.data();
    final treinos = plano['treinos'] as List<dynamic>? ?? [];
    for (var treino in treinos) {
      final treinoData = (treino['data'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final normalizedTreinoData =
          DateTime(treinoData.year, treinoData.month, treinoData.day);
      if (normalizedTreinoData == normalizedToday) {
        return {
          'tipo': treino['tipo'] ?? 'Treino',
          'musculos':
              treino['musculos']?.join(', ') ?? 'Sem informações de músculos',
        };
      }
    }
    return null;
  }

  // Função para buscar dados do calendário
  Future<Map<String, dynamic>> _getWorkoutForDay(DateTime date) async {
    if (user == null) return {'treino': 'Sem treino', 'porcentagem': 0.0};
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final userId = user!.uid;

    final snapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .where('dataCriacao',
            isGreaterThanOrEqualTo: normalizedDate,
            isLessThan: normalizedDate.add(const Duration(days: 1)))
        .get();

    if (snapshot.docs.isEmpty) {
      return {'treino': 'Sem treino', 'porcentagem': 0.0};
    }

    final workout = snapshot.docs.first.data();
    final exerciciosList =
        workout['treinos']?[0]?['exercicios'] as List<dynamic>? ?? [];
    String treino = 'Sem treino';
    double porcentagem = 0.0;

    if (exerciciosList.isNotEmpty) {
      treino = exerciciosList[0]['nome'] ?? 'Treino';
      int totalSeries = 0;
      int seriesConcluidas = 0;

      for (var ex in exerciciosList) {
        final series = (ex['series'] as num?)?.toInt() ?? 0;
        totalSeries += series;
        if (ex['concluido'] == true) {
          seriesConcluidas += series;
        }
      }

      porcentagem =
          totalSeries > 0 ? (seriesConcluidas / totalSeries) * 100 : 0.0;
    }

    return {'treino': treino, 'porcentagem': porcentagem};
  }

  // Função para buscar progresso
  Future<Map<String, double>> _getProgressData() async {
    if (user == null) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
    final userId = user!.uid;
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('treinos')
        .where('dataCriacao',
            isGreaterThanOrEqualTo: normalizedToday,
            isLessThan: normalizedToday.add(const Duration(days: 1)))
        .get();

    double calorias = 0.0;
    double pesoLevantado = 0.0;
    double tempoCardio = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final treinos = data['treinos'] as List<dynamic>? ?? [];
      for (var treino in treinos) {
        final exercicios = treino['exercicios'] as List<dynamic>? ?? [];
        for (var ex in exercicios) {
          calorias += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
          pesoLevantado += (ex['peso'] as num?)?.toDouble() ?? 0.0;
          tempoCardio += (ex['duracao'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    return {
      'calorias': calorias,
      'pesoLevantado': pesoLevantado,
      'tempoCardio': tempoCardio
    };
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate =
        DateFormat('EEE, dd \'DE\' MMMM \'DE\' yyyy', 'pt_BR')
            .format(now)
            .toUpperCase();
    final int hour = now.hour;
    String greeting = 'Bom dia';
    if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde';
    } else if (hour >= 18 || hour < 6) {
      greeting = 'Boa noite';
    }
    final userName = user?.displayName ?? 'Usuário';

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F0), // Fundo ajustado
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFE07A5F),
                      child: Icon(Icons.person,
                          size: 40, color: Color(0xFF4A4A4A)),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: AppTheme.theme.textTheme.bodyMedium),
                        Text(userName,
                            style: AppTheme.theme.textTheme.headlineLarge),
                        Text(formattedDate,
                            style: AppTheme.theme.textTheme.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: hasNotification
                          ? const Color(0xFF9D291A) // Ícone do sino ajustado
                          : AppTheme.theme.colorScheme.surface,
                      child: IconButton(
                        icon: const Icon(Icons.notifications,
                            color: Color(0xFFF5F5F0), size: 20),
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
                const Text('HOJE É DIA DE TREINAR',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9D291A))), // Título ajustado
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getTodayWorkout(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    final workout = snapshot.data ??
                        {
                          'tipo': 'Treino',
                          'musculos': 'Sem informações de músculos'
                        };
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaTreino()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workout['tipo'],
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF9D291A))), // Tipo ajustado
                            const SizedBox(height: 8),
                            Text(workout['musculos'],
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(
                                        0xFF9D291A))), // Músculos ajustado
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Calendário de Treinos
                const Text('CALÉNDARIO DE TREINOS',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9D291A))), // Título ajustado
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _getWorkoutForDay(
                              now.subtract(const Duration(days: 1))),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {'treino': 'Sem treino', 'porcentagem': 0.0};
                            return _buildDayCard(
                                now.subtract(const Duration(days: 1)),
                                data['treino'],
                                data['porcentagem'],
                                Colors.grey);
                          },
                        ),
                      ),
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _getWorkoutForDay(now),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {'treino': 'Sem treino', 'porcentagem': 0.0};
                            return _buildDayCard(
                                now,
                                data['treino'],
                                data['porcentagem'],
                                AppTheme.theme.colorScheme.secondary);
                          },
                        ),
                      ),
                      Flexible(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _getWorkoutForDay(
                              now.add(const Duration(days: 1))),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final data = snapshot.data ??
                                {'treino': 'Sem treino', 'porcentagem': 0.0};
                            return _buildDayCard(
                                now.add(const Duration(days: 1)),
                                data['treino'],
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
                        color: Color(0xFF9D291A))), // Título ajustado
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
      ),
    );
  }

  Widget _buildDayCard(
      DateTime date, String treino, double porcentagem, Color backgroundColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _focusedDay = date;
        });
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${date.day}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(treino,
                style: AppTheme.theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.theme.colorScheme.onPrimary)),
            const SizedBox(height: 4),
            Text('${porcentagem.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9D291A))), // Porcentagem ajustada
          ],
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
