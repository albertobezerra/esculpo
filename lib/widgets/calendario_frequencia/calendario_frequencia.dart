// lib/widgets/calendario_frequencia.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class CalendarioFrequencia extends StatefulWidget {
  const CalendarioFrequencia({super.key});

  @override
  State<CalendarioFrequencia> createState() => _CalendarioFrequenciaState();
}

class _CalendarioFrequenciaState extends State<CalendarioFrequencia> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Armazena os dias que tiveram treino.
  // O valor (List) pode guardar detalhes do treino se quisermos mostrar depois.
  Map<DateTime, List<dynamic>> _diasTreinados = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  // Busca no Firebase todos os treinos concluídos deste mês (e arredores)
  Future<void> _carregarHistorico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Otimização: Pegar apenas os últimos 90 dias para não pesar
      final start = DateTime.now().subtract(const Duration(days: 90));

      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('historico_concluido')
          .where('finalizadoEm', isGreaterThan: start)
          .get();

      final Map<DateTime, List<dynamic>> dados = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['finalizadoEm'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          // Normaliza a data para meia-noite (para o calendário agrupar corretamente)
          final dateKey = DateTime(date.year, date.month, date.day);

          if (dados[dateKey] == null) dados[dateKey] = [];
          dados[dateKey]!.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _diasTreinados = dados;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar calendário: $e");
    }
  }

  List<dynamic> _getEventosDoDia(DateTime day) {
    // Normaliza para buscar na chave
    final dateKey = DateTime(day.year, day.month, day.day);
    return _diasTreinados[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
          height: 300,
          child: Center(
              child:
                  CircularProgressIndicator(color: AppColors.primaryPurple)));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: TableCalendar(
        locale:
            'pt_BR', // Se der erro, verifique se inicializou o intl date formatting
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 30)),
        focusedDay: _focusedDay,

        // Estilo do Cabeçalho (Mês/Ano)
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          leftChevronIcon:
              Icon(Icons.chevron_left, color: AppColors.primaryPurple),
          rightChevronIcon:
              Icon(Icons.chevron_right, color: AppColors.primaryPurple),
        ),

        // Calendário
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Color(0xFFE1BEE7), // Roxo clarinho
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
              color: AppColors.primaryPurple, fontWeight: FontWeight.bold),

          selectedDecoration: BoxDecoration(
            color: AppColors.primaryPurple,
            shape: BoxShape.circle,
          ),

          // Marcador de dia treinado (Bolinha verde por padrão, ou customizado abaixo)
          markerDecoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),

        // Lógica de Eventos (Treinos)
        eventLoader: _getEventosDoDia,

        // CUSTOMIZAÇÃO DOS MARCADORES (O "100%" ou Bolinha)
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              // Se tiver treino nesse dia, mostra o check verde
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },

          // Estilo do dia quando tem treino (Opcional: Mudar o fundo do dia todo)
          // Se quiser que o dia inteiro fique verde, use o `prioritizedBuilder` ou similar,
          // mas o markerBuilder (bolinha embaixo) costuma ser mais elegante.
        ),

        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          // Feedback tátil ou mostrar detalhes abaixo
          final treinos = _getEventosDoDia(selectedDay);
          if (treinos.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Treino feito: ${treinos.first['musculos'] ?? 'Musculação'}"),
                backgroundColor: AppColors.primaryGreen,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }
}
