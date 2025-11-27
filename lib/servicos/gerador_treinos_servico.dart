// lib/servicos/gerador_treinos_servico.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/models/exercicio.dart';
import 'package:guarda_corpo_2024/models/plano_treino.dart';
import 'package:guarda_corpo_2024/models/treino_dia.dart';

class GeradorTreinosServico {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GeradorTreinosServico(this.ref);

  /// Gera um plano de treino completo baseado nos dados do onboarding
  Future<PlanoTreino> gerarPlanoCompleto({
    required String usuarioId,
  }) async {
    try {
      debugPrint('📋 Iniciando geração do plano...');

      // 1. Buscar dados do onboarding
      final onboardingSnapshot = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('onboarding')
          .doc('data')
          .get();

      if (!onboardingSnapshot.exists) {
        throw Exception('Dados do onboarding não encontrados');
      }

      final dados = onboardingSnapshot.data()!;
      final objetivo = dados['objetivo'] as String? ?? 'Ganhar massa';
      final experiencia = dados['experiencia'] as String? ?? 'Não';
      final frequencia = dados['frequencia'] as int? ?? 3;

      debugPrint('🎯 Objetivo: $objetivo');
      debugPrint('💪 Experiência: $experiencia');
      debugPrint('📅 Frequência: $frequencia dias/semana');

      // 2. Mapear experiência para nível
      final nivel = _mapearExperienciaParaNivel(experiencia);
      debugPrint('📊 Nível: $nivel');

      // 3. Buscar exercícios
      final todosExercicios = await _buscarExercicios();
      debugPrint(
          '🏋️ Total de exercícios disponíveis: ${todosExercicios.length}');

      if (todosExercicios.isEmpty) {
        throw Exception('Nenhum exercício disponível no banco de dados');
      }

      // 4. Definir split baseado na frequência
      final split = _definirSplitPorFrequencia(frequencia);

      // 5. Gerar dias de treino
      final List<TreinoDia> dias = [];
      for (int i = 0; i < split.length; i++) {
        final gruposDoDia = split[i];
        final nomeDia = _nomeDoDia(gruposDoDia);

        debugPrint('📝 Gerando dia ${i + 1}: $nomeDia');

        final exerciciosDoDia = _escolherExerciciosParaGrupos(
          todosExercicios: todosExercicios,
          grupos: gruposDoDia,
          objetivo: objetivo,
          nivel: nivel,
        );

        debugPrint('   ✅ ${exerciciosDoDia.length} exercícios selecionados');

        dias.add(
          TreinoDia(
            id: 'dia_${i + 1}',
            nome: nomeDia,
            exercicios: exerciciosDoDia,
            dataCriacao: DateTime.now(),
          ),
        );
      }

      // 6. Criar plano
      final plano = PlanoTreino(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        usuarioId: usuarioId,
        objetivo: objetivo,
        frequenciaSemanal: frequencia,
        criadoEm: DateTime.now(),
        dias: dias,
      );

      // 7. Salvar no Firestore
      await _salvarPlanoNoFirestore(usuarioId, plano);
      debugPrint('✅ Plano salvo com sucesso!');

      return plano;
    } catch (e) {
      debugPrint('❌ Erro ao gerar plano: $e');
      rethrow;
    }
  }

  /// Gera treino diário baseado no plano existente
  Future<Map<String, dynamic>?> gerarTreinoDiario(
    String usuarioId,
    DateTime data,
  ) async {
    try {
      final normalizedDate = DateTime(data.year, data.month, data.day);
      debugPrint('📅 Gerando treino para: $normalizedDate');

      // Verificar se já existe treino para hoje
      final treinoSnapshot = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      if (treinoSnapshot.docs.isNotEmpty) {
        debugPrint('✅ Treino já existe para hoje');
        final workoutData = treinoSnapshot.docs.first.data();
        return _formatarTreinoParaExibicao(workoutData);
      }

      // Buscar plano de treino
      final planSnapshot = await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('planos_treino')
          .doc('personalized')
          .get();

      if (!planSnapshot.exists) {
        debugPrint('⚠️ Plano não existe, gerando novo...');
        await gerarPlanoCompleto(usuarioId: usuarioId);
        return gerarTreinoDiario(usuarioId, data);
      }

      final planData = planSnapshot.data()!;
      final treinos = planData['treinos'] as List<dynamic>? ?? [];

      if (treinos.isEmpty) {
        debugPrint('⚠️ Plano vazio, regenerando...');
        await gerarPlanoCompleto(usuarioId: usuarioId);
        return gerarTreinoDiario(usuarioId, data);
      }

      // Selecionar treino do dia baseado no dia da semana
      final dayIndex = data.weekday % treinos.length;
      final treinoDoDia = treinos[dayIndex] as Map<String, dynamic>;

      debugPrint('📋 Treino selecionado: ${treinoDoDia['nome']}');
      debugPrint(
          '🏋️ Exercícios: ${(treinoDoDia['exercicios'] as List?)?.length ?? 0}');

      // Salvar treino do dia no Firestore
      final treinoParaSalvar = {
        'tipo': treinoDoDia['nome'] ?? 'Treino',
        'musculos': treinoDoDia['nome'] ?? 'Diversos',
        'porcentagem': 0.0,
        'exercicios': treinoDoDia['exercicios'] ?? [],
        'dataCriacao': Timestamp.fromDate(normalizedDate),
        'tempoEstimado': treinoDoDia['tempoEstimado'] ?? 0,
        'caloriasEstimadas': treinoDoDia['caloriasEstimadas'] ?? 0.0,
      };

      await _firestore
          .collection('usuarios')
          .doc(usuarioId)
          .collection('treinos')
          .doc(normalizedDate.toIso8601String())
          .set(treinoParaSalvar);

      debugPrint('✅ Treino do dia salvo com sucesso!');

      return _formatarTreinoParaExibicao(treinoParaSalvar);
    } catch (e) {
      debugPrint('❌ Erro ao gerar treino diário: $e');
      return {
        'tipo': 'Erro',
        'musculos': 'Erro ao carregar treino',
        'porcentagem': 0.0,
        'treinos': [],
        'createdAt': null,
        'tempoEstimado': 0,
        'caloriasEstimadas': 0.0,
      };
    }
  }

  Map<String, dynamic> _formatarTreinoParaExibicao(
      Map<String, dynamic> treinoData) {
    return {
      'tipo': treinoData['tipo'] ?? 'Treino',
      'musculos': treinoData['musculos'] ?? 'Diversos',
      'porcentagem': treinoData['porcentagem']?.toDouble() ?? 0.0,
      'treinos': treinoData['exercicios'] ?? [],
      'createdAt': treinoData['dataCriacao'],
      'tempoEstimado': treinoData['tempoEstimado']?.toInt() ?? 0,
      'caloriasEstimadas': treinoData['caloriasEstimadas']?.toDouble() ?? 0.0,
    };
  }

  // === MÉTODOS AUXILIARES ===

  NivelExercicio _mapearExperienciaParaNivel(String experiencia) {
    switch (experiencia) {
      case 'Não':
        return NivelExercicio.iniciante;
      case 'Sim, <6 meses':
        return NivelExercicio.intermediario;
      case 'Sim, >6 meses':
      case 'Sim, regularmente':
        return NivelExercicio.avancado;
      default:
        return NivelExercicio.iniciante;
    }
  }

  List<List<GrupoMuscular>> _definirSplitPorFrequencia(int frequencia) {
    if (frequencia <= 2) {
      return [
        [GrupoMuscular.corpoTodo],
        [GrupoMuscular.corpoTodo],
      ];
    } else if (frequencia == 3) {
      return [
        [GrupoMuscular.peito, GrupoMuscular.ombros, GrupoMuscular.triceps],
        [GrupoMuscular.costas, GrupoMuscular.biceps],
        [GrupoMuscular.pernas, GrupoMuscular.gluteos, GrupoMuscular.core],
      ];
    } else if (frequencia == 4) {
      return [
        [GrupoMuscular.peito, GrupoMuscular.triceps],
        [GrupoMuscular.costas, GrupoMuscular.biceps],
        [GrupoMuscular.pernas, GrupoMuscular.gluteos],
        [GrupoMuscular.ombros, GrupoMuscular.core],
      ];
    } else if (frequencia == 5) {
      return [
        [GrupoMuscular.peito, GrupoMuscular.triceps],
        [GrupoMuscular.costas, GrupoMuscular.biceps],
        [GrupoMuscular.pernas],
        [GrupoMuscular.ombros, GrupoMuscular.core],
        [GrupoMuscular.gluteos],
      ];
    } else {
      return [
        [GrupoMuscular.peito],
        [GrupoMuscular.costas],
        [GrupoMuscular.pernas],
        [GrupoMuscular.ombros],
        [GrupoMuscular.biceps, GrupoMuscular.triceps],
        [GrupoMuscular.gluteos, GrupoMuscular.core],
      ];
    }
  }

  String _nomeDoDia(List<GrupoMuscular> grupos) {
    final nomes = grupos.map((g) => _nomeGrupo(g)).toList();
    return nomes.join(' + ');
  }

  String _nomeGrupo(GrupoMuscular grupo) {
    switch (grupo) {
      case GrupoMuscular.peito:
        return 'Peito';
      case GrupoMuscular.costas:
        return 'Costas';
      case GrupoMuscular.pernas:
        return 'Pernas';
      case GrupoMuscular.gluteos:
        return 'Glúteos';
      case GrupoMuscular.ombros:
        return 'Ombros';
      case GrupoMuscular.biceps:
        return 'Bíceps';
      case GrupoMuscular.triceps:
        return 'Tríceps';
      case GrupoMuscular.core:
        return 'Core';
      case GrupoMuscular.corpoTodo:
        return 'Corpo Todo';
    }
  }

  List<ExercicioDoTreino> _escolherExerciciosParaGrupos({
    required List<Exercicio> todosExercicios,
    required List<GrupoMuscular> grupos,
    required String objetivo,
    required NivelExercicio nivel,
  }) {
    // Filtrar exercícios por grupo muscular
    final candidatos = todosExercicios.where((ex) {
      return grupos.contains(ex.grupoPrincipal);
    }).toList();

    debugPrint('   🔍 Candidatos encontrados: ${candidatos.length}');

    // Se não houver exercícios suficientes, relaxar filtro
    if (candidatos.length < 3) {
      candidatos.addAll(todosExercicios.where((ex) {
        return !candidatos.contains(ex);
      }).take(5));
    }

    candidatos.shuffle();
    final selecionados = candidatos.take(5).toList();

    // Definir séries/reps baseado no objetivo
    int series = 3;
    int repeticoes = 12;
    int descanso = 60;
    double carga = 10.0;

    if (objetivo.toLowerCase().contains('força') ||
        objetivo.toLowerCase().contains('forca')) {
      series = 5;
      repeticoes = 5;
      descanso = 120;
      carga = 20.0;
    } else if (objetivo.toLowerCase().contains('perder')) {
      series = 3;
      repeticoes = 15;
      descanso = 45;
      carga = 8.0;
    } else {
      series = 4;
      repeticoes = 10;
      descanso = 60;
      carga = 15.0;
    }

    return selecionados.map((ex) {
      return ExercicioDoTreino(
        exercicio: ex,
        series: series,
        repeticoes: repeticoes,
        descansoSegundos: descanso,
        cargaSugerida: carga,
      );
    }).toList();
  }

  Future<List<Exercicio>> _buscarExercicios() async {
    final snapshot = await _firestore.collection('exercicios').get();
    return snapshot.docs
        .map((doc) => Exercicio.deMapa(doc.id, doc.data()))
        .toList();
  }

  Future<void> _salvarPlanoNoFirestore(
    String usuarioId,
    PlanoTreino plano,
  ) async {
    final planoMap = {
      'objetivo': plano.objetivo,
      'frequenciaSemanal': plano.frequenciaSemanal,
      'criadoEm': Timestamp.fromDate(plano.criadoEm),
      'treinos': plano.dias.map((dia) {
        return {
          'titulo': dia.nome,
          'nome': dia.nome,
          'exercicios': dia.exercicios.map((ex) => ex.paraMapa()).toList(),
          'tempoEstimado': dia.tempoEstimadoMinutos,
          'caloriasEstimadas': dia.caloriasEstimadas,
        };
      }).toList(),
    };

    await _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('planos_treino')
        .doc('personalized')
        .set(planoMap);
  }
}
