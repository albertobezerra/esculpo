import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'tela_treino.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Usuário';
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

    // Dados fictícios para gráficos (substituir por dados reais)
    const double caloriesBurned = 300.0;
    const double weightLifted = 120.0;
    const double cardioTime = 25.0;

    return Scaffold(
      backgroundColor: Colors.white,
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
                    backgroundColor: Color(0xFFF97316),
                    child: Icon(Icons.person, size: 40, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: const TextStyle(fontSize: 16)),
                      Text(userName,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(formattedDate, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: hasNotification
                        ? const Color(0xFF9D291A)
                        : const Color(0xFFD9D9D9),
                    child: IconButton(
                      icon: const Icon(Icons.notifications,
                          color: Colors.white, size: 20),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
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
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CARDIO'),
                      SizedBox(height: 8),
                      Text('QUADRÍCEPS, GLUTÉOS E PANTURRILHAS',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Calendário de Treinos
              const Text('CALÉNDARIO DE TREINOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDayCard(
                        now.subtract(const Duration(days: 1)), Colors.grey),
                    _buildDayCard(now, const Color(0xFFF97316)),
                    _buildDayCard(
                        now.add(const Duration(days: 1)), Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progresso
              const Text('PROGRESSO',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGauge('Calorias', caloriesBurned, 500, '300kcal',
                      'Calorias gastas no treino'),
                  _buildGauge('Peso Levantado', weightLifted, 200, '120kg',
                      'Peso total levantado'),
                  _buildGauge('Tempo Cardio', cardioTime, 60, '25min',
                      'Tempo de cardio'),
                ],
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
        selectedItemColor: const Color(0xFFF97316),
        unselectedItemColor: const Color(0xFFD1D5DB),
        backgroundColor: const Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildDayCard(DateTime date, Color backgroundColor) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _focusedDay = date;
          });
        },
        child: FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('usuarios') // Alterado de 'users' para 'usuarios'
              .doc(userId)
              .collection('treinos') // Alterado de 'workouts' para 'treinos'
              .where(
                  'dataCriacao', // Alterado de 'createdAt' para 'dataCriacao'
                  isGreaterThanOrEqualTo: normalizedDate,
                  isLessThan: normalizedDate.add(const Duration(days: 1)))
              .get(),
          builder: (context, snapshot) {
            String treino = 'Sem treino';
            double porcentagem = 0.0;

            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                final workout =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>?;

                if (workout != null) {
                  final exerciciosList =
                      workout['treinos']?[0]?['exercicios'] as List<dynamic>? ??
                          [];

                  if (exerciciosList.isNotEmpty) {
                    treino = exerciciosList[0]['nome'] ?? 'Treino';
                  }

                  int totalSeries = 0;
                  int seriesConcluidas = 0;

                  for (var ex in exerciciosList) {
                    final series = (ex['series'] as num?)?.toInt() ?? 0;

                    totalSeries += series;

                    if (ex['concluido'] == true) {
                      seriesConcluidas += series;
                    }
                  }

                  porcentagem = totalSeries > 0
                      ? (seriesConcluidas / totalSeries) * 100
                      : 0.0;
                }
              }
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: _focusedDay == date
                    ? Border.all(color: const Color(0xFFF97316), width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${date.day}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(treino, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('${porcentagem.toStringAsFixed(0)}%',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
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
                    color: const Color(0xFFF97316),
                  ),
                  GaugeRange(
                    startValue: value,
                    endValue: maxValue,
                    color: const Color(0xFFD9D9D9).withAlpha(77),
                  ),
                ],
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 0.1,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: const Color(0xFFF97316),
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(label, style: const TextStyle(fontSize: 12)),
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
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
