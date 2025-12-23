// lib/widgets/timer/timer_descanso_modal.dart

import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import relativo para garantir que funcione independente do nome do pacote
import '../../core/theme/app_theme.dart';

class TimerDescansoModal extends StatefulWidget {
  final int tempoInicialSegundos;
  final VoidCallback onTimerFinalizado;

  const TimerDescansoModal({
    super.key,
    required this.tempoInicialSegundos,
    required this.onTimerFinalizado,
  });

  @override
  State<TimerDescansoModal> createState() => _TimerDescansoModalState();
}

class _TimerDescansoModalState extends State<TimerDescansoModal> {
  final CountDownController _controller = CountDownController();
  bool _isPaused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pega-mão (drag handle) visual
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight, // Cinza claro
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Descanso",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark, // Preto suave
            ),
          ),
          const SizedBox(height: 32),

          // O Timer Circular Bonitão
          CircularCountDownTimer(
            duration: widget.tempoInicialSegundos,
            initialDuration: 0,
            controller: _controller,
            width: 180,
            height: 180,
            ringColor:
                AppColors.backgroundLight, // Fundo do anel cinza clarinho
            fillColor: AppColors.primaryGreen, // Seu Verde menta #7FD957
            backgroundColor: AppColors.cardWhite,
            strokeWidth: 12.0,
            strokeCap: StrokeCap.round,
            textStyle: const TextStyle(
              fontSize: 48.0,
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            textFormat: CountdownTextFormat.S,
            isReverse: true,
            isReverseAnimation: true,
            isTimerTextShown: true,
            autoStart: true,
            onComplete: () {
              // 1. Vibração Pesada (Ideal para avisar que acabou)
              HapticFeedback.heavyImpact();

              // 2. Chama o callback (pode tocar som no futuro)
              widget.onTimerFinalizado();

              // 3. Fecha o modal
              if (mounted) Navigator.of(context).pop();
            },
          ),

          const SizedBox(height: 32),

          // Botões de Controle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _botaoControle(
                icon: Icons.more_time, // Ícone correto para adicionar tempo
                label: "+10s",
                onTap: () {
                  // Pega o tempo atual e soma 10
                  final tempoAtual =
                      int.tryParse(_controller.getTime() ?? '0') ?? 0;
                  _controller.restart(duration: tempoAtual + 10);
                },
              ),
              _botaoControle(
                icon:
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                label: _isPaused ? "Retomar" : "Pausar",
                onTap: () {
                  setState(() {
                    if (_isPaused) {
                      _controller.resume();
                    } else {
                      _controller.pause();
                    }
                    _isPaused = !_isPaused;
                  });
                },
              ),
              _botaoControle(
                icon: Icons.skip_next_rounded,
                label: "Pular",
                cor: AppColors.textGray,
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _botaoControle({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color cor = AppColors.primaryGreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              // Correção para Flutter novo: withValues em vez de withOpacity
              backgroundColor: cor.withValues(alpha: 0.1),
              child: Icon(icon, color: cor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
