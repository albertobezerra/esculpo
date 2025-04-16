import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:share_plus/share_plus.dart';
import 'subscription_service.dart';
import 'exercises_screen.dart';

final workoutProvider = Provider((ref) => WorkoutService());

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveWorkout(String userId, Map<String, dynamic> workout) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .add(workout);
  }

  Future<void> updateCompletedSets(String userId, int sets) async {
    await _firestore.collection('users').doc(userId).update({
      'completedSets': FieldValue.increment(sets),
    });
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
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // ID de teste
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

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final List<Map<String, dynamic>> exercises = [];
  String? _selectedExerciseId;
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  int _restTime = 60;
  bool _isTimerRunning = false;
  int _currentTime = 0;
  int _completedSets = 0;
  StreamSubscription<bool>? _premiumSubscription;

  @override
  void initState() {
    super.initState();
    ref.read(interstitialAdProvider).loadInterstitialAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInterstitial();
    });
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
            const SnackBar(content: Text('Descanso acabou!')),
          );
        }
        setState(() => _isTimerRunning = false);
        return false;
      }
      return true;
    });
  }

  void _shareWorkout() {
    final summary = exercises
        .map((e) =>
            "${e['name']}: ${e['sets']} séries, ${e['reps']} reps, ${e['weight']} kg")
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
            'exercises': exercises,
            'createdAt': FieldValue.serverTimestamp(),
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
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesStream = ref.watch(exerciseProvider).getExercises();
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Nenhum exercício encontrado'));
                }
                final exerciseItems = snapshot.data!
                    .map((e) => DropdownMenuItem<String>(
                          value: e['id'],
                          child: Text((e['name'] ?? 'Sem nome') as String),
                        ))
                    .toList();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Exercício'),
                  value: _selectedExerciseId,
                  items: exerciseItems,
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => _selectedExerciseId = value);
                    }
                  },
                );
              },
            ),
            TextField(
              controller: _setsController,
              decoration: const InputDecoration(labelText: 'Séries'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: 'Repetições'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Carga (kg)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Descanso (s): '),
                Slider(
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
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedExerciseId == null) return;
                final snapshot = await FirebaseFirestore.instance
                    .collection('exercises')
                    .doc(_selectedExerciseId)
                    .get();
                final exerciseData = snapshot.data();
                if (exerciseData == null || !mounted) return;
                final exercise = {
                  'id': _selectedExerciseId,
                  'name': exerciseData['name'] ?? 'Sem nome',
                  'sets': int.tryParse(_setsController.text) ?? 0,
                  'reps': int.tryParse(_repsController.text) ?? 0,
                  'weight': double.tryParse(_weightController.text) ?? 0.0,
                };
                setState(() {
                  exercises.add(exercise);
                  _selectedExerciseId = null;
                  _setsController.clear();
                  _repsController.clear();
                  _weightController.clear();
                });
              },
              child: const Text('Adicionar Exercício'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final ex = exercises[index];
                  return ListTile(
                    title: Text(ex['name'] as String),
                    subtitle: Text(
                        '${ex['sets']} séries, ${ex['reps']} reps, ${ex['weight']} kg'),
                    trailing: IconButton(
                      icon: Icon(ex['completed'] == true
                          ? Icons.check_circle
                          : Icons.check),
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          exercises[index]['completed'] =
                              !(exercises[index]['completed'] ?? false);
                          if (exercises[index]['completed'] == true) {
                            _completedSets += ex['sets'] as int;
                          } else {
                            _completedSets -= ex['sets'] as int;
                          }
                        });
                        if (!_isTimerRunning &&
                            exercises[index]['completed'] == true) {
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
