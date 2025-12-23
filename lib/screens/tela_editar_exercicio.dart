// lib/screens/tela_editar_exercicio.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class TelaEditarExercicio extends StatefulWidget {
  final Map<String, dynamic> exercicio;
  final String treinoDocId; // id do documento em 'treinos'
  final int exercicioIndex;

  const TelaEditarExercicio({
    super.key,
    required this.exercicio,
    required this.treinoDocId,
    required this.exercicioIndex,
  });

  @override
  State<TelaEditarExercicio> createState() => _TelaEditarExercicioState();
}

class _TelaEditarExercicioState extends State<TelaEditarExercicio> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _seriesController;
  late TextEditingController _repsController;
  late TextEditingController _cargaController;
  late TextEditingController _descansoController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seriesController = TextEditingController(
      text: (widget.exercicio['series'] ?? 3).toString(),
    );
    _repsController = TextEditingController(
      text: (widget.exercicio['repeticoes'] ?? 12).toString(),
    );
    _cargaController = TextEditingController(
      text: (widget.exercicio['cargaSugerida'] ?? 0).toString(),
    );
    _descansoController = TextEditingController(
      text: (widget.exercicio['descansoSegundos'] ?? 60).toString(),
    );
  }

  @override
  void dispose() {
    _seriesController.dispose();
    _repsController.dispose();
    _cargaController.dispose();
    _descansoController.dispose();
    super.dispose();
  }

  Future<void> _salvarAlteracoes() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final treinoRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .doc(widget.treinoDocId);

      final doc = await treinoRef.get();
      if (!doc.exists) throw Exception('Treino não encontrado');

      final data = doc.data()!;
      final exercicios =
          List<Map<String, dynamic>>.from(data['exercicios'] ?? []);

      if (widget.exercicioIndex < 0 ||
          widget.exercicioIndex >= exercicios.length) {
        throw Exception('Índice de exercício inválido');
      }

      // Atualiza o exercício específico
      exercicios[widget.exercicioIndex] = {
        ...exercicios[widget.exercicioIndex],
        'series': int.parse(_seriesController.text),
        'repeticoes': int.parse(_repsController.text),
        'cargaSugerida': double.parse(_cargaController.text),
        'descansoSegundos': int.parse(_descansoController.text),
        'editado': true,
        'editadoEm': Timestamp.now(),
      };

      // Recalcula totais do treino com base na nova lista
      final novosTotais = _recalcularTotais(exercicios);

      await treinoRef.update({
        'exercicios': exercicios,
        'tempoEstimado': novosTotais['tempo'],
        'caloriasEstimadas': novosTotais['calorias'],
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Treino atualizado e recalculado!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _recalcularTotais(List<Map<String, dynamic>> lista) {
    double totalMinutos = 0;
    double totalCalorias = 0;

    for (var ex in lista) {
      final series = (ex['series'] as num?)?.toInt() ?? 3;
      // Tenta pegar duração/calorias salvas no exercício, ou usa defaults
      final duracaoPorSerie = (ex['duracao'] as num?)?.toDouble() ?? 2.0;
      final caloriasPorSerie = (ex['calorias'] as num?)?.toDouble() ?? 50.0;

      totalMinutos += series * duracaoPorSerie;
      totalCalorias += series * caloriasPorSerie;
    }

    return {
      'tempo': totalMinutos.round(),
      'calorias': totalCalorias,
    };
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.exercicio['nome'] ?? 'Exercício';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Editar Exercício'),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppColors.primaryGreen),
              onPressed: _salvarAlteracoes,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      nome,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ajustar parâmetros',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _seriesController,
              label: 'Séries',
              icon: Icons.repeat,
              suffix: 'séries',
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _repsController,
              label: 'Repetições',
              icon: Icons.numbers,
              suffix: 'reps',
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _cargaController,
              label: 'Carga sugerida',
              icon: Icons.monitor_weight,
              suffix: 'kg',
              decimal: true,
            ),
            const SizedBox(height: 16),
            _buildNumberField(
              controller: _descansoController,
              label: 'Descanso',
              icon: Icons.timer,
              suffix: 'seg',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvarAlteracoes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Salvar alterações',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    bool decimal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: decimal),
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                suffixText: suffix,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Obrigatório';
                }
                final n =
                    decimal ? double.tryParse(value) : int.tryParse(value);
                if (n == null || n < 0) return 'Valor inválido';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
