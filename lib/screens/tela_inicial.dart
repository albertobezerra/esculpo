import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
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
    const TelaInicial(), // Substituir por um widget único se possível
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
  ];
  bool hasNotification = false; // Simulação de notificação

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

    // Dados fictícios pra gráficos
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
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
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
                        // Lógica de notificação
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bloco 1: Treino do Dia
              const Text(
                'HOJE É DIA DE TREINAR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaTreino()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARDIO',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'QUADRÍCEPS, GLUTÉOS E PANTURRILHAS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Bloco 2: Calendário de Treinos
              const Text(
                'CALÉNDARIO DE TREINOS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              EasyDateTimeLine(
                initialDate: now,
                onDateChange: (selectedDate) {
                  // Lógica ao mudar a data
                },
                activeColor: const Color(0xFFF97316),
              ),
              const SizedBox(height: 24),
              // Bloco 3: Gráficos
              const Text(
                'PROGRESSO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
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
            // Evita loop recriando TelaInicial
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
                showLabels: false, // Remove numerações
                showTicks: false, // Remove marcadores com traços
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: value,
                    color: const Color(0xFFF97316),
                  ),
                  GaugeRange(
                    startValue: value,
                    endValue: maxValue,
                    color: const Color(0xFFD9D9D9).withValues(alpha: 0.3),
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
                  // Apenas o valor
                  GaugeAnnotation(
                    widget: Text(
                      label,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
