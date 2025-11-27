// lib/modelos/exercicio.dart

enum GrupoMuscular {
  peito,
  costas,
  pernas,
  gluteos,
  ombros,
  biceps,
  triceps,
  core,
  corpoTodo,
}

enum NivelExercicio {
  iniciante,
  intermediario,
  avancado,
}

enum TipoExercicio {
  forca,
  hipertrofia,
  resistencia,
  mobilidade,
  cardio,
}

class Exercicio {
  final String id;
  final String nome;
  final GrupoMuscular grupoPrincipal;
  final List<GrupoMuscular> gruposSecundarios;
  final NivelExercicio nivel;
  final TipoExercicio tipo;
  final List<String> equipamentos;
  final String? urlVideo;
  final String? descricao;
  final double caloriasEstimadas; // calorias por série
  final double duracaoEstimadaMinutos; // tempo por série

  const Exercicio({
    required this.id,
    required this.nome,
    required this.grupoPrincipal,
    this.gruposSecundarios = const [],
    required this.nivel,
    required this.tipo,
    this.equipamentos = const [],
    this.urlVideo,
    this.descricao,
    this.caloriasEstimadas = 50.0,
    this.duracaoEstimadaMinutos = 2.0,
  });

  Map<String, dynamic> paraMapa() {
    return {
      'nome': nome,
      'grupoPrincipal': grupoPrincipal.name,
      'gruposSecundarios': gruposSecundarios.map((g) => g.name).toList(),
      'nivel': nivel.name,
      'tipo': tipo.name,
      'equipamentos': equipamentos,
      'urlVideo': urlVideo,
      'descricao': descricao,
      'caloriasEstimadas': caloriasEstimadas,
      'duracaoEstimadaMinutos': duracaoEstimadaMinutos,
    };
  }

  factory Exercicio.deMapa(String id, Map<String, dynamic> mapa) {
    return Exercicio(
      id: id,
      nome: mapa['nome'] ?? '',
      grupoPrincipal: GrupoMuscular.values.firstWhere(
        (g) => g.name == mapa['grupoPrincipal'],
        orElse: () => GrupoMuscular.corpoTodo,
      ),
      gruposSecundarios: (mapa['gruposSecundarios'] as List<dynamic>? ?? [])
          .map((e) => GrupoMuscular.values.firstWhere(
                (g) => g.name == e,
                orElse: () => GrupoMuscular.corpoTodo,
              ))
          .toList(),
      nivel: NivelExercicio.values.firstWhere(
        (n) => n.name == mapa['nivel'],
        orElse: () => NivelExercicio.iniciante,
      ),
      tipo: TipoExercicio.values.firstWhere(
        (t) => t.name == mapa['tipo'],
        orElse: () => TipoExercicio.hipertrofia,
      ),
      equipamentos: List<String>.from(mapa['equipamentos'] ?? []),
      urlVideo: mapa['urlVideo'],
      descricao: mapa['descricao'],
      caloriasEstimadas:
          (mapa['caloriasEstimadas'] as num?)?.toDouble() ?? 50.0,
      duracaoEstimadaMinutos:
          (mapa['duracaoEstimadaMinutos'] as num?)?.toDouble() ?? 2.0,
    );
  }
}
