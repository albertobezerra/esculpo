import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'package:video_player/video_player.dart';

class TelaExercicios extends ConsumerStatefulWidget {
  const TelaExercicios({super.key});

  @override
  ConsumerState<TelaExercicios> createState() => _TelaExerciciosState();
}

class _TelaExerciciosState extends ConsumerState<TelaExercicios> {
  String? _selectedMuscleGroup;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer(String? urlVideo) async {
    if (urlVideo != null && urlVideo.isNotEmpty) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(urlVideo))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    } else {
      _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync =
        ref.watch(exerciseProvider).getExercises(_selectedMuscleGroup);

    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedMuscleGroup,
              hint: const Text('Selecione o grupo muscular'),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'Peito', child: Text('Peito')),
                DropdownMenuItem(value: 'Costas', child: Text('Costas')),
                DropdownMenuItem(value: 'Pernas', child: Text('Pernas')),
                DropdownMenuItem(value: 'Braços', child: Text('Braços')),
                DropdownMenuItem(value: 'Ombros', child: Text('Ombros')),
                DropdownMenuItem(value: 'Abdômen', child: Text('Abdômen')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMuscleGroup = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: exercisesAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Erro ao carregar exercícios'));
                }
                final exercises = snapshot.data ?? [];
                if (exercises.isEmpty) {
                  return const Center(
                      child: Text('Nenhum exercício encontrado'));
                }
                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return ListTile(
                      title: Text(exercise['nome'] ?? 'Sem nome'),
                      subtitle: Text(exercise['grupoMuscular'] ?? 'Sem grupo'),
                      onTap: () {
                        _initializeVideoPlayer(exercise['urlVideo']);
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
        ],
      ),
    );
  }
}
