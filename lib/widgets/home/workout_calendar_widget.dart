// lib/widgets/home/workout_calendar_widget.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/screens/tela_detalhe_treino.dart';

class WorkoutCalendarWidget extends StatefulWidget {
  final int rebuildKey;
  final Future<Map<String, dynamic>?> Function(DateTime) getCachedWorkout;

  const WorkoutCalendarWidget({
    super.key,
    required this.rebuildKey,
    required this.getCachedWorkout,
  });

  @override
  State<WorkoutCalendarWidget> createState() => _WorkoutCalendarWidgetState();
}

class _WorkoutCalendarWidgetState extends State<WorkoutCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _diasTreinados = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _carregarHistorico();
  }

  @override
  void didUpdateWidget(covariant WorkoutCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rebuildKey != widget.rebuildKey) {
      _carregarHistorico();
    }
  }

  Future<void> _carregarHistorico() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
          final dateKey = DateTime(date.year, date.month, date.day);
          if (dados[dateKey] == null) dados[dateKey] = [];
          dados[dateKey]!.add(data);
        }
      }

      if (mounted) {
        setState(() {
          _diasTreinados = dados;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar calendário: $e");
    }
  }

  List<dynamic> _getEventosDoDia(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _diasTreinados[dateKey] ?? [];
  }

  void _abrirTreinoDoDia(DateTime date) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final treinoData = await widget.getCachedWorkout(date);

    if (treinoData != null &&
        (treinoData['treinos'] as List?)?.isNotEmpty == true &&
        treinoData['treinoDocId'] != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaDetalheTreino(
            workout: treinoData,
            treinoDocId: treinoData['treinoDocId'] as String,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum treino planejado para este dia.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título e Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Consistência",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text("Feito", style: Theme.of(context).textTheme.bodySmall),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Calendário Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.subtleShadow,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: TableCalendar(
            locale: 'pt_BR',

            // ✅ CORREÇÃO: Permite swipe horizontal mas libera scroll vertical
            availableGestures: AvailableGestures.horizontalSwipe,

            firstDay: DateTime.now().subtract(const Duration(days: 120)),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,

            rowHeight: 48,
            daysOfWeekHeight: 30,

            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.grey, fontSize: 13),
              weekendStyle: TextStyle(color: Colors.grey, fontSize: 13),
            ),

            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              leftChevronIcon:
                  Icon(Icons.chevron_left, size: 24, color: AppColors.textGray),
              rightChevronIcon: Icon(Icons.chevron_right,
                  size: 24, color: AppColors.textGray),
              headerMargin: EdgeInsets.only(bottom: 8),
            ),

            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(fontSize: 14),
              weekendTextStyle: TextStyle(fontSize: 14),
              todayDecoration: BoxDecoration(
                color: Color(0xFFE1BEE7),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                  color: AppColors.primaryPurple, fontWeight: FontWeight.bold),
              selectedDecoration: BoxDecoration(
                color: AppColors.primaryPurple,
                shape: BoxShape.circle,
              ),
            ),

            eventLoader: _getEventosDoDia,

            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 6,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),

            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _abrirTreinoDoDia(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
      ],
    );
  }
}
