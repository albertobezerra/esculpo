import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class TelaTreino extends ConsumerStatefulWidget {
  const TelaTreino({super.key});

  @override
  ConsumerState<TelaTreino> createState() => _TelaTreinoState();
}

class _TelaTreinoState extends ConsumerState<TelaTreino> {
  final _nomeTreinoController = TextEditingController();
  List<Map<String, dynamic>> exercises = [];
  String? _selectedExerciseId;
  int _series = 3;
  int _repeticoes = 12;
  double _carga = 0;
  int _descanso = 60;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (_selectedExerciseId != null) {
      final doc = await FirebaseFirestore.instance
          .collection('exercicios')
          .doc(_selectedExerciseId)
          .get();
      final urlVideo = doc.data()?['urlVideo'] as String?;
      if (urlVideo != null && urlVideo.isNotEmpty) {
        _videoController?.dispose();
        _videoController = VideoPlayerController.networkUrl(Uri.parse(urlVideo))
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
      }
    }
  }

  @override
  void dispose() {
    _nomeTreinoController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    if (_selectedExerciseId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('exercicios')
        .doc(_selectedExerciseId)
        .get();
    final exerciseData = doc.data();
    if (exerciseData != null && mounted) {
      setState(() {
        exercises.add({
          'id': _selectedExerciseId,
          'nome': exerciseData['nome'],
          'series': _series,
          'repeticoes': _repeticoes,
          'cargaSugerida': _carga,
          'tempoDescanso': _descanso,
        });
        _selectedExerciseId = null;
        _series = 3;
        _repeticoes = 12;
        _carga = 0;
        _descanso = 60;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  Future<void> _salvarTreino() async {
    if (exercises.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Adicione pelo menos um exercício')),
        );
      }
      return;
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final workoutService = ref.read(workoutProvider);
    final treino = {
      'nome': _nomeTreinoController.text.isEmpty
          ? 'Treino Personalizado'
          : _nomeTreinoController.text,
      'exercicios': exercises,
      'dataCriacao': Timestamp.now(),
      'caloriasEstimadas': exercises.length * 50,
    };

    await workoutService.saveWorkout(userId, treino);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino salvo com sucesso')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _shareWorkout() async {
    final workoutText = exercises
        .map((e) =>
            '${e['nome']}: ${e['series']} séries, ${e['repeticoes']} reps, ${e['cargaSugerida']}kg')
        .join('\n');
    await SharePlus.instance
        .share(ShareParams(text: 'Meu treino:\n$workoutText'));
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseProvider).getExercises(null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Treino'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: exercises.isEmpty ? null : _shareWorkout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeTreinoController,
              decoration: const InputDecoration(labelText: 'Nome do Treino'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: exercisesAsync,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text('Erro ao carregar exercícios');
                }
                final exList = snapshot.data ?? [];
                return DropdownButton<String>(
                  value: _selectedExerciseId,
                  hint: const Text('Selecione um exercício'),
                  isExpanded: true,
                  items: exList
                      .map((e) => DropdownMenuItem<String>(
                            value: e['id'] as String,
                            child: Text(e['nome'] ?? 'Sem nome'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExerciseId = value;
                      _initializeVideoPlayer();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Séries'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _series = int.tryParse(value) ?? _series,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Repetições'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _repeticoes = int.tryParse(value) ?? _repeticoes,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Carga (kg)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _carga = double.tryParse(value) ?? _carga,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: 'Descanso (seg)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _descanso = int.tryParse(value) ?? _descanso,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addExercise,
              child: const Text('Adicionar Exercício'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return ListTile(
                    title: Text(ex['nome'] ?? 'Sem nome'),
                    subtitle: Text(
                        '${ex['series']} séries, ${ex['repeticoes']} reps, ${ex['cargaSugerida']}kg, ${ex['tempoDescanso']}s'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          exercises.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _salvarTreino,
              child: const Text('Salvar Treino'),
            ),
          ],
        ),
      ),
    );
  }
}
