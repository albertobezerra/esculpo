import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guarda_corpo_2024/screens/tela_treino.dart';
import 'package:guarda_corpo_2024/services/plan_generator_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
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
    const TelaInicialContent(),
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth * 0.64; // 60% da largura da tela (ajustável)
    final leftOffset = (screenWidth - barWidth) / 2; // Centraliza dinamicamente

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          Positioned(
            left: leftOffset > 20
                ? leftOffset
                : 20, // Garante mínimo de 20 pixels de margem
            bottom: 30,
            child: Container(
              width: barWidth, // Largura proporcional
              height: 70,
              child: Material(
                color: const Color(0xFF9D291A),
                borderRadius: const BorderRadius.all(Radius.circular(35)),
                elevation: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildNavIcon(Icons.home, 0)),
                    Expanded(child: _buildNavIcon(Icons.calendar_today, 1)),
                    Expanded(child: _buildNavIcon(Icons.history, 2)),
                    Expanded(child: _buildNavIcon(Icons.directions_run, 3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : null,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? const Color(0xFF9D291A) : Colors.white70,
          size: 30,
        ),
        onPressed: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// Widget separado para o conteúdo da tela inicial
class TelaInicialContent extends StatefulWidget {
  const TelaInicialContent({super.key});

  @override
  State<TelaInicialContent> createState() => _TelaInicialContentState();
}

class _TelaInicialContentState extends State<TelaInicialContent> {
  bool hasNotification = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  final PlanGeneratorService _planGenerator = PlanGeneratorService();

  Future<Map<String, dynamic>?> _getActiveWorkout(DateTime date) async {
    if (user == null) return null;
    final userId = user!.uid;
    final normalizedDate = DateTime(date.year, date.month, date.day);

    try {
      final workout = await _planGenerator.generateDynamicWorkout(userId, date);

      final treinoSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      double porcentagem = workout['porcentagem'] as double? ?? 0.0;
      if (treinoSnapshot.docs.isNotEmpty) {
        final workoutData = treinoSnapshot.docs.first.data();
        final exerciciosList =
            workoutData['exercicios'] as List<dynamic>? ?? [];
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
        ...workout,
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

  Widget _buildDayCard(
      DateTime date, String treino, double porcentagem, Color backgroundColor,
      {Color textColor = Colors.black,
      Color? borderColor,
      required DateTime now}) {
    String porcentagemTexto = '';
    if (date == now && porcentagem > 0 && porcentagem < 100) {
      porcentagemTexto = 'Em andamento';
    } else if (date == now.subtract(const Duration(days: 1)) &&
        (porcentagem == 0 || treino == 'Nenhum')) {
      porcentagemTexto = 'Descanso!';
    } else {
      porcentagemTexto = '${porcentagem.toStringAsFixed(0)}%';
    }

    return GestureDetector(
      onTap: () async {
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
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  '${date.day}',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Center(
                child: Text(
                  treino,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                porcentagemTexto,
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
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
                        style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9D291A))),
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
            style: GoogleFonts.bebasNeue(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9D291A))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now(); // 07:29 PM WEST, 15 de julho de 2025
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

    return SafeArea(
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
                        color: Color.fromARGB(255, 225, 225, 225), size: 20),
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
              padding: const EdgeInsets.only(top: 2),
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
                      if (workout['musculos'] ==
                          'Nenhum plano de treino ativo'.toUpperCase()) {
                        // _showCreatePlanOptions(); // Desativado por agora
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TelaTreino()),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9D291A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: 10,
                            bottom: 0,
                            child: Text(
                              workout['musculos'],
                              style: GoogleFonts.bebasNeue(
                                fontSize: 30,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (workout['musculos'] ==
                              'Nenhum plano de treino ativo'.toUpperCase())
                            Positioned(
                              left: 20,
                              top: 20,
                              child: ElevatedButton(
                                onPressed: () {
                                  // _showCreatePlanOptions(); // Desativado por agora
                                },
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

            const SizedBox(height: 20),

            // Calendário de Treinos
            Text(
              'CALÉNDARIO DE TREINOS'.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
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
                          data['musculos'],
                          data['porcentagem'],
                          Colors.white,
                          textColor: const Color(0xFF9D291A),
                          borderColor: const Color(0xFF9D291A),
                          now: now,
                        );
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
                          data['musculos'],
                          data['porcentagem'],
                          const Color(0xFF9D291A),
                          textColor: Colors.white,
                          now: now,
                        );
                      },
                    ),
                  ),
                  Flexible(
                    child: FutureBuilder<Map<String, dynamic>?>(
                      future:
                          _getActiveWorkout(now.add(const Duration(days: 1))),
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
                          data['musculos'],
                          data['porcentagem'],
                          Colors.white,
                          textColor: const Color(0xFF9D291A),
                          borderColor: const Color(0xFF9D291A),
                          now: now,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progresso
            Text(
              'PROGRESSO'.toUpperCase(),
              style: GoogleFonts.bebasNeue(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, double>>(
              future: _getProgressData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final progress = snapshot.data ??
                    {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
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
    );
  }
}
