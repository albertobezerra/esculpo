import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guarda_corpo_2024/screens/tela_exercicios.dart';
import 'package:share_plus/share_plus.dart';
import '../services/subscription_service.dart';

final workoutProvider = Provider((ref) => WorkoutService());

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveWorkout(String userId, Map<String, dynamic> workout) async {
    await _firestore
        .collection('usuarios') // Coleção alterada de 'users' para 'usuarios'
        .doc(userId)
        .collection('treinos') // Coleção alterada de 'workouts' para 'treinos'
        .add(workout);
  }

  Future<void> updateCompletedSets(String userId, int sets) async {
    await _firestore.collection('usuarios').doc(userId).update({
      'seriesConcluidas': FieldValue.increment(sets),
    });
  }

  Future<Map<String, dynamic>?> getOnboardingData(String userId) async {
    final doc = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();
    return doc.exists ? doc.data() : null;
  }
}

final interstitialAdProvider = Provider((ref) => InterstitialAdService());

class InterstitialAdService {
  InterstitialAd? interstitialAd;
  bool isAdLoaded = false;
  DateTime? lastAdShownTime;

  static const int adCooldownSeconds = 0; // Desativado pra testes

  Future<void> loadInterstitialAd() async {
    if (isAdLoaded && interstitialAd != null) {
      debugPrint('Interstitial já carregado');
      return;
    }
    debugPrint('Iniciando carregamento do interstitial');

    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          isAdLoaded = true;
          debugPrint('Interstitial carregado');
        },
        onAdFailedToLoad: (error) {
          isAdLoaded = false;
          debugPrint('Erro no interstitial: $error');
          interstitialAd = null;
        },
      ),
    );
  }

  bool canShowAd() {
    if (!isAdLoaded || interstitialAd == null) {
      debugPrint('Anúncio não carregado');
      return false;
    }
    if (adCooldownSeconds == 0 || lastAdShownTime == null) {
      return true;
    }
    final now = DateTime.now();
    final diff = now.difference(lastAdShownTime!).inSeconds;
    if (diff < adCooldownSeconds) {
      debugPrint('Cooldown ativo: faltam ${adCooldownSeconds - diff} segundos');
      return false;
    }
    return true;
  }

  bool showAd() {
    debugPrint('Tentando exibir interstitial: isAdLoaded=$isAdLoaded');
    if (canShowAd()) {
      interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial fechado');
          ad.dispose();
          interstitialAd = null;
          isAdLoaded = false;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Erro ao exibir interstitial: $error');
          ad.dispose();
          interstitialAd = null;
          isAdLoaded = false;
          loadInterstitialAd();
        },
      );
      interstitialAd!.show();
      debugPrint('Interstitial exibido');
      lastAdShownTime = DateTime.now();
      return true;
    }
    debugPrint('Falha ao exibir interstitial');
    return false;
  }

  void dispose() {
    interstitialAd?.dispose();
    interstitialAd = null;
    isAdLoaded = false;
  }
}

class TelaTreino extends ConsumerStatefulWidget {
  const TelaTreino({super.key});

  @override
  ConsumerState<TelaTreino> createState() => _TelaTreinoState();
}

class _TelaTreinoState extends ConsumerState<TelaTreino> {
  final List<Map<String, dynamic>> exercises = [];
  String? _selectedExerciseId;
  final _customExerciseController = TextEditingController();
  String? _customMuscleGroup;
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  int _restTime = 60;
  bool _isTimerRunning = false;
  int _currentTime = 0;
  int _completedSets = 0;
  StreamSubscription<bool>? _premiumSubscription;
  Map<String, dynamic>? _onboardingData;
  int _estimatedTime = 0;
  double _estimatedCalories = 0.0;

  @override
  void initState() {
    super.initState();
    ref.read(interstitialAdProvider).loadInterstitialAd();
    _loadOnboardingData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitial();
    });
  }

  Future<void> _loadOnboardingData() async {
    final data = await ref.read(workoutProvider).getOnboardingData(
          FirebaseAuth.instance.currentUser!.uid,
        );
    if (mounted && data != null) {
      setState(() => _onboardingData = data);
    }
  }

  Future<void> _showInterstitial() async {
    if (!mounted) return;
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _premiumSubscription =
        ref.read(subscriptionProvider).isPremium(userId).listen(
      (isPremium) {
        if (!mounted) return;
        if (!isPremium) {
          final interstitialAdService = ref.read(interstitialAdProvider);
          interstitialAdService.showAd();
        }
      },
      onError: (error) {
        debugPrint('Erro ao verificar premium: $error');
      },
    );
  }

  void _startTimer() {
    if (!mounted) return;
    setState(() {
      _isTimerRunning = true;
      _currentTime = _restTime;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isTimerRunning || !mounted) return false;
      setState(() => _currentTime--);
      if (_currentTime <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descanso terminou!')),
          );
        }
        setState(() => _isTimerRunning = false);
        return false;
      }
      return true;
    });
  }

  void _estimateWorkout() {
    int totalTime = 0;
    double totalCalories = 0;
    final weight = _onboardingData?['peso']?.toDouble() ?? 70.0;

    for (var ex in exercises) {
      final sets = ex['series'] as int? ?? 3;
      final reps = ex['repeticoes'] as int? ?? 12;
      totalTime += sets * (reps * 3 + _restTime); // 3s por repetição
      totalCalories += sets * reps * 0.5 * (weight / 70); // Estimativa
    }

    setState(() {
      _estimatedTime = totalTime ~/ 60;
      _estimatedCalories = totalCalories;
    });
  }

  void _shareWorkout() {
    final summary = exercises
        .map((e) =>
            "${e['nome']}: ${e['series']} séries, ${e['repeticoes']} reps, ${e['cargaSugerida']} kg${e['weightVariation'] != null ? ' (${e['weightVariation']})' : ''}")
        .join('\n');
    Share.share('Meu treino no Esculpo:\n$summary\n💪 #EsculpoApp');
  }

  Future<void> _salvarTreino() async {
    try {
      final workoutService = ref.read(workoutProvider);
      final interstitialAdService = ref.read(interstitialAdProvider);
      final isPremium = await ref
          .read(subscriptionProvider)
          .isPremium(FirebaseAuth.instance.currentUser!.uid)
          .first;

      if (exercises.isNotEmpty) {
        await workoutService.saveWorkout(
          FirebaseAuth.instance.currentUser!.uid,
          {
            'exercicios': exercises,
            'dataCriacao': FieldValue.serverTimestamp(),
            'tempoEstimado': _estimatedTime,
            'caloriasEstimadas': _estimatedCalories,
          },
        );

        if (_completedSets > 0) {
          await workoutService.updateCompletedSets(
              FirebaseAuth.instance.currentUser!.uid, _completedSets);
        }

        if (!isPremium && mounted) {
          interstitialAdService.showAd();
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino salvo! Parabéns!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _premiumSubscription?.cancel();
    ref.read(interstitialAdProvider).dispose();
    _customExerciseController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesStream = ref.watch(exerciseProvider).getExercises();
    final experienceLevel = _onboardingData?['experiencia'] ?? 'Iniciante';
    final suggestedReps = experienceLevel == 'Sim, regularmente'
        ? 12
        : experienceLevel == 'Sim, >6 meses'
            ? 10
            : 8;
    final suggestedWeightMultiplier = experienceLevel == 'Sim, regularmente'
        ? 0.5
        : experienceLevel == 'Sim, >6 meses'
            ? 0.7
            : 0.9;

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
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: exercisesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint(
                      'Erro no StreamBuilder (Workout): ${snapshot.error}');
                  return const Center(
                      child: Text('Erro ao carregar exercícios'));
                }

                final exerciseItems =
                    snapshot.hasData && snapshot.data!.isNotEmpty
                        ? snapshot.data!
                            .map((e) => DropdownMenuItem<String>(
                                  value: e['id'],
                                  child: Text(e['nome'] ?? 'Sem nome'),
                                ))
                            .toList()
                        : <DropdownMenuItem<String>>[];

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Exercício'),
                  value: _selectedExerciseId,
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Selecione um exercício'),
                    ),
                    ...exerciseItems,
                  ],
                  onChanged: (value) {
                    if (mounted) {
                      setState(() =>
                          _selectedExerciseId = value == '' ? null : value);
                    }
                  },
                );
              },
            ),
            TextFormField(
              controller: _customExerciseController,
              decoration: const InputDecoration(
                  labelText: 'Exercício Personalizado (opcional)'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'Grupo Muscular (para personalizado)'),
              value: _customMuscleGroup,
              items: [
                'Peito',
                'Costas',
                'Pernas',
                'Braços',
                'Ombros',
                'Abdômen'
              ]
                  .map((muscle) =>
                      DropdownMenuItem(value: muscle, child: Text(muscle)))
                  .toList(),
              onChanged: (value) {
                if (mounted) {
                  setState(() => _customMuscleGroup = value);
                }
              },
            ),
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(labelText: 'Séries'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _repsController,
              decoration: InputDecoration(
                labelText: 'Repetições (sugerido: $suggestedReps)',
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Carga (kg)'),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                const Text('Descanso (s): '),
                Expanded(
                  child: Slider(
                    value: _restTime.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 15,
                    label: _restTime.toString(),
                    onChanged: (value) {
                      if (mounted) {
                        setState(() => _restTime = value.round());
                      }
                    },
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                String? exerciseName;
                if (_customExerciseController.text.isNotEmpty) {
                  exerciseName = _customExerciseController.text;
                } else if (_selectedExerciseId != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('exercicios')
                      .doc(_selectedExerciseId)
                      .get();
                  exerciseName = doc.data()?['nome'] as String?;
                }

                if (exerciseName == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Selecione ou insira um exercício')),
                    );
                    return;
                  }
                }

                final sets = int.tryParse(_setsController.text) ?? 3;
                final reps =
                    int.tryParse(_repsController.text) ?? suggestedReps;
                final weight = double.tryParse(_weightController.text) ?? 0.0;
                final suggestedWeight = weight * suggestedWeightMultiplier;
                final weightVariation = weight > suggestedWeight
                    ? '↑'
                    : weight < suggestedWeight
                        ? '↓'
                        : '=';

                final exercise = {
                  'id': _selectedExerciseId ??
                      'custom_${DateTime.now().millisecondsSinceEpoch}',
                  'nome': exerciseName,
                  'grupoMuscular': _customMuscleGroup ?? 'Desconhecido',
                  'series': sets,
                  'repeticoes': reps,
                  'cargaSugerida': weight,
                  'suggestedWeight': suggestedWeight,
                  'weightVariation': weightVariation,
                };

                setState(() {
                  exercises.add(exercise);
                  _selectedExerciseId = null;
                  _customExerciseController.clear();
                  _customMuscleGroup = null;
                  _setsController.clear();
                  _repsController.clear();
                  _weightController.clear();
                  _estimateWorkout();
                });
              },
              child: const Text('Adicionar Exercício'),
            ),
            if (_estimatedTime > 0) Text('Tempo estimado: $_estimatedTime min'),
            if (_estimatedCalories > 0)
              Text(
                  'Calorias estimadas: ${_estimatedCalories.toStringAsFixed(1)} kcal'),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return ListTile(
                    title: Text(ex['nome'] as String),
                    subtitle: Text(
                      '${ex['series']} séries, ${ex['repeticoes']} reps, ${ex['cargaSugerida']} kg (${ex['weightVariation']})',
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        ex['concluido'] == true
                            ? Icons.check_circle
                            : Icons.check,
                      ),
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          final isCompleted = ex['concluido'] == true;
                          ex['concluido'] = !isCompleted;
                          if (!isCompleted) {
                            _completedSets += ex['series'] as int;
                          } else {
                            _completedSets -= ex['series'] as int;
                          }
                        });
                        if (!_isTimerRunning && ex['concluido'] == true) {
                          _startTimer();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            if (_isTimerRunning)
              Text('Descanso: $_currentTime s',
                  style: const TextStyle(fontSize: 20)),
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
