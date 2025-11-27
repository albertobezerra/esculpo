// lib/modelos/treino_dia.dart

import 'exercicio.dart';

class ExercicioDoTreino {
  final Exercicio exercicio;
  final int series;
  final int repeticoes;
  final int descansoSegundos;
  final double? cargaSugerida;
  bool concluido;

  ExercicioDoTreino({
    required this.exercicio,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    this.cargaSugerida,
    this.concluido = false,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'exercicioId': exercicio.id,
      'nome': exercicio.nome,
      'series': series,
      'repeticoes': repeticoes,
      'descansoSegundos': descansoSegundos,
      'cargaSugerida': cargaSugerida ?? 0.0,
      'concluido': concluido,
      'calorias': exercicio.caloriasEstimadas,
      'duracao': exercicio.duracaoEstimadaMinutos,
    };
  }
}

class TreinoDia {
  final String id;
  final String nome;
  final List<ExercicioDoTreino> exercicios;
  final DateTime? dataCriacao;
  final double porcentagemConcluida;

  TreinoDia({
    required this.id,
    required this.nome,
    required this.exercicios,
    this.dataCriacao,
    this.porcentagemConcluida = 0.0,
  });

  int get tempoEstimadoMinutos {
    return exercicios
        .fold<double>(
          0,
          (total, ex) =>
              total + (ex.exercicio.duracaoEstimadaMinutos * ex.series),
        )
        .round();
  }

  double get caloriasEstimadas {
    return exercicios.fold<double>(
      0,
      (total, ex) => total + (ex.exercicio.caloriasEstimadas * ex.series),
    );
  }

  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'exercicios': exercicios.map((e) => e.paraMapa()).toList(),
      'dataCriacao': dataCriacao,
      'porcentagem': porcentagemConcluida,
      'tempoEstimado': tempoEstimadoMinutos,
      'caloriasEstimadas': caloriasEstimadas,
    };
  }
}
