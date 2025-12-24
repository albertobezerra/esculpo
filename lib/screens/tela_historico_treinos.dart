// lib/screens/tela_historico_treinos.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/servicos/streak_servico.dart';
import 'package:fl_chart/fl_chart.dart';

class TelaHistoricoTreinos extends StatefulWidget {
  const TelaHistoricoTreinos({super.key});

  @override
  State<TelaHistoricoTreinos> createState() => _TelaHistoricoTreinosState();
}

class _TelaHistoricoTreinosState extends State<TelaHistoricoTreinos> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  String _filtroSelecionado = 'semana'; // semana, mes, ano

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Histórico',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list),
                    color: AppColors.textDark,
                  ),
                ],
              ),
            ),

            // FILTROS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildFiltroChip('Semana', 'semana'),
                  const SizedBox(width: 12),
                  _buildFiltroChip('Mês', 'mes'),
                  const SizedBox(width: 12),
                  _buildFiltroChip('Ano', 'ano'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CONTEÚDO
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getTreinosStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final treinos = snapshot.data!.docs;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ESTATÍSTICAS
                        _buildEstatisticas(treinos),
                        const SizedBox(height: 16),

                        // STREAK CARD
                        _buildStreakCard(),
                        const SizedBox(height: 24),

                        // GRÁFICO
                        _buildGrafico(treinos),
                        const SizedBox(height: 24),

                        // LISTA DE TREINOS
                        Text(
                          'Treinos Recentes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),

                        ...treinos.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _buildTreinoCard(data);
                        }),

                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final isSelected = _filtroSelecionado == valor;

    return GestureDetector(
      onTap: () => setState(() => _filtroSelecionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDark : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? AppTheme.subtleShadow : [],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isSelected ? Colors.white : AppColors.textGray,
              ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum treino registrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textGray,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece seu primeiro treino!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textLight,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstatisticas(List<QueryDocumentSnapshot> treinos) {
    // Calcular estatísticas
    int totalTreinos = treinos.length;
    double totalCalorias = 0;
    int totalTempo = 0;

    for (var doc in treinos) {
      final data = doc.data() as Map<String, dynamic>;
      final exercicios = data['exercicios'] as List<dynamic>? ?? [];

      for (var ex in exercicios) {
        if (ex['concluido'] == true) {
          totalCalorias += (ex['calorias'] as num?)?.toDouble() ?? 0;
        }
      }

      totalTempo += (data['tempoEstimado'] as num?)?.toInt() ?? 0;
    }

    final mediaCalorias = totalTreinos > 0 ? totalCalorias / totalTreinos : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            Icons.fitness_center,
            '$totalTreinos',
            'Treinos',
            AppColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.local_fire_department,
            mediaCalorias.toStringAsFixed(0),
            'Kcal/média',
            AppColors.accentOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            Icons.timer,
            '${totalTempo}min',
            'Total',
            AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: StreakServico().calcularStreak(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 140,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final streakAtual = data['streakAtual'] as int;
        final melhorStreak = data['melhorStreak'] as int;
        final mensagem = data['mensagem'] as String;
        final icone = data['icone'] as String;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    icone,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak Atual',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        ),
                        Text(
                          '$streakAtual dia${streakAtual != 1 ? 's' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Recorde',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                        ),
                        Text(
                          '$melhorStreak',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        mensagem,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrafico(List<QueryDocumentSnapshot> treinos) {
    // Preparar dados para o gráfico
    List<FlSpot> spots = [];

    for (int i = 0; i < treinos.length && i < 7; i++) {
      final data = treinos[i].data() as Map<String, dynamic>;
      final exercicios = data['exercicios'] as List<dynamic>? ?? [];

      double calorias = 0;
      for (var ex in exercicios) {
        if (ex['concluido'] == true) {
          calorias += (ex['calorias'] as num?)?.toDouble() ?? 0;
        }
      }

      spots.add(FlSpot(i.toDouble(), calorias));
    }

    return Container(
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
            'Calorias Queimadas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'Sem dados para exibir',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textGray,
                          ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt() + 1}',
                                style: Theme.of(context).textTheme.bodySmall,
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.primaryGreen,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreinoCard(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] as Timestamp?;
    final musculos = data['musculos'] as String? ?? 'Treino';
    final porcentagem = (data['porcentagem'] as num?)?.toDouble() ?? 0;
    final exercicios = data['exercicios'] as List<dynamic>? ?? [];

    double calorias = 0;
    for (var ex in exercicios) {
      if (ex['concluido'] == true) {
        calorias += (ex['calorias'] as num?)?.toDouble() ?? 0;
      }
    }

    String dataFormatada = 'Data desconhecida';
    if (createdAt != null) {
      dataFormatada = DateFormat('dd/MM/yyyy').format(createdAt.toDate());
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${porcentagem.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  musculos,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  dataFormatada,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textGray,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${calorias.toStringAsFixed(0)} kcal',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${exercicios.length} ex',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getTreinosStream() {
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    DateTime startDate;

    switch (_filtroSelecionado) {
      case 'semana':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'mes':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'ano':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return _firestore
        .collection('usuarios')
        .doc(user!.uid)
        .collection('historico_concluido') // <--- MUDANÇA AQUI
        .where('finalizadoEm',
            isGreaterThanOrEqualTo: startDate) // <--- MUDANÇA DE CAMPO
        .orderBy('finalizadoEm', descending: true)
        .snapshots();
  }
}
