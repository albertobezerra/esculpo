// lib/servicos/streak_servico.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StreakServico {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calcula o streak atual (dias consecutivos de treino)
  Future<Map<String, dynamic>> calcularStreak(String userId) async {
    try {
      // Buscar todos os treinos do usuário ordenados por data
      final treinosSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .orderBy('dataCriacao', descending: true)
          .get();

      if (treinosSnapshot.docs.isEmpty) {
        return {
          'streakAtual': 0,
          'melhorStreak': 0,
          'ultimoTreino': null,
          'mensagem': 'Comece seu primeiro treino!',
          'icone': '💪',
        };
      }

      // Verificar se há treinos com algum exercício concluído
      final treinosConcluidos = treinosSnapshot.docs.where((doc) {
        final data = doc.data();
        final porcentagem = (data['porcentagem'] as num?)?.toDouble() ?? 0;
        return porcentagem > 0;
      }).toList();

      if (treinosConcluidos.isEmpty) {
        return {
          'streakAtual': 0,
          'melhorStreak': 0,
          'ultimoTreino': null,
          'mensagem': 'Complete seu primeiro treino!',
          'icone': '🎯',
        };
      }

      // Calcular streak atual
      int streakAtual = 0;
      int melhorStreak = 0;
      int streakTemporario = 0;
      DateTime? dataAnterior;

      for (var doc in treinosConcluidos) {
        final data = doc.data();
        final dataTreino = (data['dataCriacao'] as Timestamp).toDate();
        final dataFormatada =
            DateTime(dataTreino.year, dataTreino.month, dataTreino.day);

        if (dataAnterior == null) {
          // Primeiro treino
          final hoje = DateTime.now();
          final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
          final ontem = hojeSemHora.subtract(const Duration(days: 1));

          if (dataFormatada == hojeSemHora || dataFormatada == ontem) {
            streakAtual = 1;
            streakTemporario = 1;
          }
          dataAnterior = dataFormatada;
        } else {
          // Verificar se é dia consecutivo
          final diferenca = dataAnterior.difference(dataFormatada).inDays;

          if (diferenca == 1) {
            // Dia consecutivo
            streakTemporario++;
            if (streakAtual > 0 || diferenca == 1) {
              streakAtual = streakTemporario;
            }
          } else if (diferenca > 1) {
            // Quebrou o streak
            if (streakAtual > 0) {
              // Já encontramos o streak atual, então paramos
              break;
            }
            streakTemporario = 1;
          }
          // Se diferenca == 0 (mesmo dia), não faz nada

          if (streakTemporario > melhorStreak) {
            melhorStreak = streakTemporario;
          }

          dataAnterior = dataFormatada;
        }
      }

      if (melhorStreak < streakAtual) {
        melhorStreak = streakAtual;
      }

      // Última data de treino
      final ultimoTreino =
          (treinosConcluidos.first.data()['dataCriacao'] as Timestamp).toDate();

      // Mensagem e ícone baseado no streak
      final resultado = _getMensagemStreak(streakAtual, melhorStreak);

      return {
        'streakAtual': streakAtual,
        'melhorStreak': melhorStreak,
        'ultimoTreino': ultimoTreino,
        'mensagem': resultado['mensagem'],
        'icone': resultado['icone'],
      };
    } catch (e) {
      debugPrint('❌ Erro ao calcular streak: $e');
      return {
        'streakAtual': 0,
        'melhorStreak': 0,
        'ultimoTreino': null,
        'mensagem': 'Erro ao carregar streak',
        'icone': '❌',
      };
    }
  }

  Map<String, String> _getMensagemStreak(int streakAtual, int melhorStreak) {
    if (streakAtual == 0) {
      return {
        'mensagem': 'Comece sua jornada hoje!',
        'icone': '🚀',
      };
    } else if (streakAtual == 1) {
      return {
        'mensagem': 'Ótimo começo! Continue amanhã!',
        'icone': '💪',
      };
    } else if (streakAtual >= 2 && streakAtual <= 6) {
      return {
        'mensagem': 'Você está no caminho certo!',
        'icone': '🔥',
      };
    } else if (streakAtual == 7) {
      return {
        'mensagem': '1 semana consecutiva! 🎉',
        'icone': '⭐',
      };
    } else if (streakAtual >= 8 && streakAtual <= 13) {
      return {
        'mensagem': 'Impressionante! Continue assim!',
        'icone': '🏆',
      };
    } else if (streakAtual == 14) {
      return {
        'mensagem': '2 semanas! Você é incrível!',
        'icone': '👑',
      };
    } else if (streakAtual >= 15 && streakAtual <= 29) {
      return {
        'mensagem': 'Disciplina de campeão!',
        'icone': '💎',
      };
    } else if (streakAtual == 30) {
      return {
        'mensagem': '1 MÊS CONSECUTIVO! 🎊',
        'icone': '🌟',
      };
    } else {
      return {
        'mensagem': 'LENDA! $streakAtual dias!',
        'icone': '🔥',
      };
    }
  }
}
