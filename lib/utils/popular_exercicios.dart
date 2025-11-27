// lib/utils/popular_exercicios.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PopularExercicios {
  static Future<void> executar() async {
    final firestore = FirebaseFirestore.instance;

    // Verificar se já existem exercícios
    final snapshot = await firestore.collection('exercicios').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      debugPrint('✅ Exercícios já existem no Firestore!');
      return;
    }

    debugPrint('🔄 Populando exercícios no Firestore...');

    final exercicios = [
      // PEITO
      {
        'nome': 'Supino Reto',
        'grupoPrincipal': 'peito',
        'gruposSecundarios': ['triceps'],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra', 'Banco'],
        'caloriasEstimadas': 60.0,
        'duracaoEstimadaMinutos': 3.0,
        'descricao': 'Exercício fundamental para desenvolvimento do peitoral',
      },
      {
        'nome': 'Flexão de Braço',
        'grupoPrincipal': 'peito',
        'gruposSecundarios': ['triceps', 'core'],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': [],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Exercício básico de peso corporal',
      },
      {
        'nome': 'Crucifixo com Halteres',
        'grupoPrincipal': 'peito',
        'gruposSecundarios': [],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres', 'Banco'],
        'caloriasEstimadas': 50.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Isolamento do peitoral',
      },

      // COSTAS
      {
        'nome': 'Remada Curvada',
        'grupoPrincipal': 'costas',
        'gruposSecundarios': ['biceps'],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra'],
        'caloriasEstimadas': 55.0,
        'duracaoEstimadaMinutos': 3.0,
        'descricao': 'Exercício composto para costas',
      },
      {
        'nome': 'Puxada Alta',
        'grupoPrincipal': 'costas',
        'gruposSecundarios': ['biceps'],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Máquina'],
        'caloriasEstimadas': 50.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Desenvolve largura das costas',
      },
      {
        'nome': 'Remada Baixa',
        'grupoPrincipal': 'costas',
        'gruposSecundarios': ['biceps'],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Cabo'],
        'caloriasEstimadas': 50.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Trabalha espessura das costas',
      },

      // PERNAS
      {
        'nome': 'Agachamento Livre',
        'grupoPrincipal': 'pernas',
        'gruposSecundarios': ['gluteos', 'core'],
        'nivel': 'avancado',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra'],
        'caloriasEstimadas': 70.0,
        'duracaoEstimadaMinutos': 3.0,
        'descricao': 'Rei dos exercícios para pernas',
      },
      {
        'nome': 'Leg Press',
        'grupoPrincipal': 'pernas',
        'gruposSecundarios': ['gluteos'],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Máquina'],
        'caloriasEstimadas': 65.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Alternativa segura ao agachamento',
      },
      {
        'nome': 'Cadeira Extensora',
        'grupoPrincipal': 'pernas',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Máquina'],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Isolamento do quadríceps',
      },
      {
        'nome': 'Mesa Flexora',
        'grupoPrincipal': 'pernas',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Máquina'],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Isolamento dos posteriores',
      },

      // GLÚTEOS
      {
        'nome': 'Stiff',
        'grupoPrincipal': 'gluteos',
        'gruposSecundarios': ['pernas'],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra'],
        'caloriasEstimadas': 60.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Trabalha posterior e glúteos',
      },
      {
        'nome': 'Elevação Pélvica',
        'grupoPrincipal': 'gluteos',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': [],
        'caloriasEstimadas': 45.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Ativação glútea',
      },
      {
        'nome': 'Coice na Máquina',
        'grupoPrincipal': 'gluteos',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Máquina'],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Isolamento glúteo',
      },

      // OMBROS
      {
        'nome': 'Desenvolvimento com Halteres',
        'grupoPrincipal': 'ombros',
        'gruposSecundarios': ['triceps'],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres'],
        'caloriasEstimadas': 50.0,
        'duracaoEstimadaMinutos': 2.5,
        'descricao': 'Exercício base para ombros',
      },
      {
        'nome': 'Elevação Lateral',
        'grupoPrincipal': 'ombros',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Isolamento do deltoide lateral',
      },
      {
        'nome': 'Elevação Frontal',
        'grupoPrincipal': 'ombros',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Trabalha deltoide anterior',
      },

      // BÍCEPS
      {
        'nome': 'Rosca Direta',
        'grupoPrincipal': 'biceps',
        'gruposSecundarios': [],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra'],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Exercício base para bíceps',
      },
      {
        'nome': 'Rosca Martelo',
        'grupoPrincipal': 'biceps',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Trabalha braquial e bíceps',
      },
      {
        'nome': 'Rosca Alternada',
        'grupoPrincipal': 'biceps',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Halteres'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Variação com halteres',
      },

      // TRÍCEPS
      {
        'nome': 'Tríceps Testa',
        'grupoPrincipal': 'triceps',
        'gruposSecundarios': [],
        'nivel': 'intermediario',
        'tipo': 'hipertrofia',
        'equipamentos': ['Barra'],
        'caloriasEstimadas': 40.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Isolamento do tríceps',
      },
      {
        'nome': 'Mergulho no Banco',
        'grupoPrincipal': 'triceps',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Banco'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Exercício de peso corporal',
      },
      {
        'nome': 'Tríceps Corda',
        'grupoPrincipal': 'triceps',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'hipertrofia',
        'equipamentos': ['Cabo'],
        'caloriasEstimadas': 35.0,
        'duracaoEstimadaMinutos': 2.0,
        'descricao': 'Extensão no cabo',
      },

      // CORE
      {
        'nome': 'Prancha',
        'grupoPrincipal': 'core',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'resistencia',
        'equipamentos': [],
        'caloriasEstimadas': 30.0,
        'duracaoEstimadaMinutos': 1.5,
        'descricao': 'Exercício isométrico para core',
      },
      {
        'nome': 'Abdominal Supra',
        'grupoPrincipal': 'core',
        'gruposSecundarios': [],
        'nivel': 'iniciante',
        'tipo': 'resistencia',
        'equipamentos': [],
        'caloriasEstimadas': 25.0,
        'duracaoEstimadaMinutos': 1.5,
        'descricao': 'Trabalha reto abdominal',
      },
      {
        'nome': 'Abdominal Infra',
        'grupoPrincipal': 'core',
        'gruposSecundarios': [],
        'nivel': 'intermediario',
        'tipo': 'resistencia',
        'equipamentos': [],
        'caloriasEstimadas': 30.0,
        'duracaoEstimadaMinutos': 1.5,
        'descricao': 'Trabalha região inferior do abdômen',
      },
    ];

    final batch = firestore.batch();
    for (var ex in exercicios) {
      final docRef = firestore.collection('exercicios').doc();
      batch.set(docRef, ex);
    }

    await batch.commit();
    debugPrint('✅ ${exercicios.length} exercícios criados com sucesso!');
  }
}
