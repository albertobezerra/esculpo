import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TelaDetalheTreino extends StatelessWidget {
  final Map<String, dynamic> workout;

  const TelaDetalheTreino({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    // Extrair dados com fallbacks
    final musculos = workout['musculos'] as String? ?? 'Treino';
    final exercicios = (workout['treinos'] as List<dynamic>?) ?? [];
    final tempoEstimado = workout['tempoEstimado'] as int? ?? 0;
    final caloriasEstimadas =
        (workout['caloriasEstimadas'] as num?)?.toDouble() ?? 0.0;
    final createdAt = workout['createdAt'] as Timestamp?;

    String formattedDate = 'Data desconhecida';
    if (createdAt != null) {
      formattedDate = DateFormat('dd/MM/yyyy').format(createdAt.toDate());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'TREINO - $musculos'.toUpperCase(),
          style: GoogleFonts.bebasNeue(fontSize: 20),
        ),
        backgroundColor: const Color(0xFF9D291A),
        foregroundColor: Colors.white,
      ),
      body: exercicios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum exercício encontrado',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente regenerar o treino',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de informações gerais
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D291A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF9D291A),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoItem(
                              Icons.calendar_today,
                              formattedDate,
                              'Data',
                            ),
                            _buildInfoItem(
                              Icons.timer,
                              '$tempoEstimado min',
                              'Tempo',
                            ),
                            _buildInfoItem(
                              Icons.local_fire_department,
                              '${caloriasEstimadas.toStringAsFixed(0)} kcal',
                              'Calorias',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'EXERCÍCIOS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF9D291A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Lista de exercícios
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: exercicios.length,
                    itemBuilder: (context, index) {
                      final ex = exercicios[index] as Map<String, dynamic>;
                      final nome =
                          ex['nome'] as String? ?? 'Exercício ${index + 1}';
                      final series = ex['series'] as int? ?? 0;
                      final repeticoes = ex['repeticoes'] as int? ?? 0;
                      final carga =
                          (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
                      final descanso = ex['descansoSegundos'] as int? ?? 60;
                      final concluido = ex['concluido'] as bool? ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: concluido
                                ? Colors.green
                                : const Color(0xFF9D291A),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: concluido
                                ? Colors.green
                                : const Color(0xFF9D291A),
                            foregroundColor: Colors.white,
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            nome,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF9D291A),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildExerciseDetail(
                                    Icons.fitness_center,
                                    '$series séries',
                                  ),
                                  const SizedBox(width: 16),
                                  _buildExerciseDetail(
                                    Icons.repeat,
                                    '$repeticoes reps',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (carga > 0)
                                    _buildExerciseDetail(
                                      Icons.line_weight,
                                      '${carga.toStringAsFixed(1)} kg',
                                    ),
                                  const SizedBox(width: 16),
                                  _buildExerciseDetail(
                                    Icons.timer,
                                    '${descanso}s descanso',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: concluido
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 32,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF9D291A), size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.bebasNeue(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9D291A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.bebasNeue(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
