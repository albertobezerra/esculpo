// lib/modelos/plano_treino.dart

import 'treino_dia.dart';

class PlanoTreino {
  final String id;
  final String usuarioId;
  final String objetivo;
  final int frequenciaSemanal;
  final DateTime criadoEm;
  final List<TreinoDia> dias;

  const PlanoTreino({
    required this.id,
    required this.usuarioId,
    required this.objetivo,
    required this.frequenciaSemanal,
    required this.criadoEm,
    required this.dias,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'objetivo': objetivo,
      'frequenciaSemanal': frequenciaSemanal,
      'criadoEm': criadoEm,
      'treinos': dias.map((d) => d.paraMapa()).toList(),
    };
  }
}
