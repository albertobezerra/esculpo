import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

class TelaDetalheExercicio extends StatelessWidget {
  final Map<String, dynamic> exercicio;

  const TelaDetalheExercicio({
    super.key,
    required this.exercicio,
  });

  @override
  Widget build(BuildContext context) {
    final nome = exercicio['nome'] ?? 'Exercício';
    final imagem = exercicio['imagem']; // URL da imagem/gif
    final musculoAlvo = exercicio['musculo'] ?? 'Geral'; // Ex: "Peito"
    // Simulando instruções se não tiver no banco (para você testar o layout)
    final instrucoes = exercicio['instrucoes'] as List<dynamic>? ??
        [
          "Ajuste o banco ou o equipamento para a sua altura.",
          "Segure as manoplas ou a barra com firmeza, mantendo os pulsos alinhados.",
          "Execute o movimento de forma controlada, focando na contração do músculo alvo.",
          "Retorne à posição inicial lentamente, sem deixar os pesos baterem.",
          "Mantenha a respiração constante: expire no esforço e inspire no retorno."
        ];
    final dicas = exercicio['dicas'] as String? ??
        "Mantenha a postura ereta e evite usar o impulso do corpo para mover a carga.";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(musculoAlvo,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textDark),
            onPressed: () {
              // Futuro: Salvar como favorito
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÁREA VISUAL (IMAGEM/GIF)
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: imagem != null
                  ? Image.network(
                      imagem,
                      fit: BoxFit.contain, // Contain para ver o movimento todo
                      errorBuilder: (ctx, err, stack) => const Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: Colors.grey),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_not_supported_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("Sem imagem disponível",
                            style: TextStyle(color: Colors.grey))
                      ],
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. CABEÇALHO DO EXERCÍCIO
                  Text(
                    nome,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      musculoAlvo.toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 3. INSTRUÇÕES (PASSO A PASSO)
                  const Text(
                    "Instrução",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: instrucoes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bolinha com número
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPurple,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Texto
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFFF8F9FA), // Fundo bem clarinho tipo as refs
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                instrucoes[index].toString(),
                                style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontSize: 14,
                                    height: 1.5),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // 4. ALERTA / DICAS (Card Amarelo/Laranja)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Amarelo bem claro
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              const Color(0xFFFFE082).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("DICA IMPORTANTE",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                dicas,
                                style: TextStyle(
                                    color: Colors.orange.shade900,
                                    fontSize: 14,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
