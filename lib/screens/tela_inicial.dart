// lib/screens/tela_inicial.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'tela_detalhe_treino.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';
import 'package:guarda_corpo_2024/core/i18n/app_strings.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'dart:math' as math;

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const TelaInicialContent(),
    const TelaPlanosTreino(),
    const TelaHistoricoTreinos(),
    const TelaExercicios(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavIcon(Icons.home_outlined, Icons.home, 0),
                _buildNavIcon(
                    Icons.calendar_today_outlined, Icons.calendar_today, 1),
                _buildNavIcon(Icons.history_outlined, Icons.history, 2),
                _buildNavIcon(
                    Icons.fitness_center_outlined, Icons.fitness_center, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          color: isSelected ? AppColors.textDark : AppColors.textLight,
          size: 28,
        ),
      ),
    );
  }
}

// ===== CONTEÚDO DA TELA INICIAL =====

class TelaInicialContent extends ConsumerStatefulWidget {
  const TelaInicialContent({super.key});

  @override
  ConsumerState<TelaInicialContent> createState() => _TelaInicialContentState();
}

class _TelaInicialContentState extends ConsumerState<TelaInicialContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  int _rebuildKey = 0;
  final Map<String, Future<Map<String, dynamic>?>> _workoutCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _checkOnboardingAndGeneratePlan();
  }

  Future<void> _loadProfileImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_image.jpg');
    final file = File(imagePath);
    if (await file.exists()) {
      setState(() => _profileImage = file);
    }
  }

  Future<void> _saveProfileImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_image.jpg');
    await image.copy(imagePath);
    setState(() => _profileImage = File(imagePath));
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _saveProfileImage(File(pickedFile.path));
    }
  }

  void _clearCache() => _workoutCache.clear();

  Future<Map<String, dynamic>?> _getCachedWorkout(DateTime date) {
    final key = '${date.year}-${date.month}-${date.day}';
    if (!_workoutCache.containsKey(key)) {
      _workoutCache[key] = _getActiveWorkout(date);
    }
    return _workoutCache[key]!;
  }

  Future<void> _checkOnboardingAndGeneratePlan() async {
    if (user == null) return;
    final userId = user!.uid;

    final onboardingSnapshot = await _firestore
        .collection('usuarios')
        .doc(userId)
        .collection('onboarding')
        .doc('data')
        .get();

    if (onboardingSnapshot.exists &&
        onboardingSnapshot.data()?['onboardingConcluido'] == true) {
      final planSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('planos_treino')
          .doc('personalized')
          .get();

      if (!planSnapshot.exists) {
        try {
          await ref.read(geradorTreinosProvider).gerarPlanoCompleto(
                usuarioId: userId,
              );
          _clearCache();
          setState(() => _rebuildKey++);
        } catch (e) {
          debugPrint('❌ Erro ao gerar plano: $e');
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _getActiveWorkout(DateTime date) async {
    if (user == null) return null;
    final userId = user!.uid;

    try {
      final geradorTreinos = ref.read(geradorTreinosProvider);
      final workout = await geradorTreinos.gerarTreinoDiario(userId, date);

      if (workout == null || workout['treinos'] == null) {
        return {
          'tipo': 'Sem treino',
          'musculos': 'DESCANSO',
          'porcentagem': 0.0,
          'treinos': [],
        };
      }

      return workout;
    } catch (e) {
      return {
        'tipo': 'Erro',
        'musculos': 'ERRO',
        'porcentagem': 0.0,
        'treinos': [],
      };
    }
  }

  Future<Map<String, double>> _getProgressData() async {
    if (user == null) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
    final userId = user!.uid;
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);

    try {
      final snapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('treinos')
          .where('dataCriacao', isGreaterThanOrEqualTo: normalizedDate)
          .where('dataCriacao',
              isLessThan: normalizedDate.add(const Duration(days: 1)))
          .get();

      double calorias = 0.0;
      double pesoLevantado = 0.0;
      double tempoCardio = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final exercicios = data['exercicios'] as List<dynamic>? ?? [];
        for (var ex in exercicios) {
          if (ex['concluido'] == true) {
            calorias += (ex['calorias'] as num?)?.toDouble() ?? 0.0;
            pesoLevantado += (ex['cargaSugerida'] as num?)?.toDouble() ?? 0.0;
            tempoCardio += (ex['duracao'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      return {
        'calorias': calorias,
        'pesoLevantado': pesoLevantado,
        'tempoCardio': tempoCardio
      };
    } catch (e) {
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final DateTime now = DateTime.now();
    final int hour = now.hour;

    String greeting;
    String emoji;
    if (hour >= 6 && hour < 12) {
      greeting = strings.goodMorning;
      emoji = '🔥';
    } else if (hour >= 12 && hour < 18) {
      greeting = strings.goodAfternoon;
      emoji = '☀️';
    } else {
      greeting = strings.goodEvening;
      emoji = '🌙';
    }

    final userName = user?.displayName ?? 'User';

    return SafeArea(
      child: Column(
        children: [
          // HEADER FIXO
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _buildHeader(greeting, emoji, userName),
          ),

          // CONTEÚDO SCROLLÁVEL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // PROGRESS CARD
                  _buildProgressCard(strings),
                  const SizedBox(height: 24),

                  // CALENDÁRIO DE TREINOS
                  _buildWorkoutCalendar(strings, now),
                  const SizedBox(height: 24),

                  // MÉTRICAS/PROGRESSO
                  _buildMetrics(strings),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String greeting, String emoji, String userName) {
    return Row(
      children: [
        GestureDetector(
          onTap: _profileImage == null
              ? _pickImage
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'pt'
                            ? 'Alterar foto'
                            : 'Change photo',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'pt'
                                ? 'Cancelar'
                                : 'Cancel',
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'pt'
                                ? 'Alterar'
                                : 'Change',
                          ),
                        ),
                      ],
                    ),
                  );
                },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: _profileImage == null
                  ? const LinearGradient(
                      colors: [AppColors.primaryGreen, AppColors.primaryPurple],
                    )
                  : null,
            ),
            child: _profileImage == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textGray,
                    ),
              ),
              Text(
                userName,
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.textDark,
        ),
      ],
    );
  }

  Widget _buildProgressCard(AppStrings strings) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey(_rebuildKey),
      future: _getCachedWorkout(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildProgressCardSkeleton();
        }

        final workout = snapshot.data;
        final musculos =
            workout?['musculos'] ?? strings.noWorkout.toUpperCase();
        final porcentagem =
            (workout?['porcentagem'] as num?)?.toDouble() ?? 0.0;
        final temExercicios =
            (workout?['treinos'] as List?)?.isNotEmpty ?? false;
        final tempoEstimado = workout?['tempoEstimado'] ?? 0;

        return GestureDetector(
          onTap: temExercicios
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TelaDetalheTreino(workout: workout!),
                    ),
                  );
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.todayWorkout,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // CIRCULAR PROGRESS
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        children: [
                          CustomPaint(
                            size: const Size(90, 90),
                            painter: CircularProgressPainter(
                              progress: porcentagem / 100,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          Center(
                            child: Text(
                              '${porcentagem.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            musculos,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (tempoEstimado > 0)
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 16, color: AppColors.textGray),
                                const SizedBox(width: 4),
                                Text(
                                  '$tempoEstimado ${strings.minutes}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (temExercicios) ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TelaDetalheTreino(workout: workout!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: Text(strings.continueWorkout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressCardSkeleton() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
    );
  }

  Widget _buildWorkoutCalendar(AppStrings strings, DateTime now) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.workoutCalendar,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDayCard(
                now.subtract(const Duration(days: 1)),
                strings.yesterday,
                false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(now, strings.today, true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDayCard(
                now.add(const Duration(days: 1)),
                strings.tomorrow,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCard(DateTime date, String label, bool isToday) {
    return FutureBuilder<Map<String, dynamic>?>(
      key: ValueKey('${_rebuildKey}_${date.day}'),
      future: _getCachedWorkout(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDayCardSkeleton(isToday);
        }

        final data = snapshot.data;
        final musculos = data?['musculos'] ?? 'Descanso';
        final porcentagem = (data?['porcentagem'] as num?)?.toDouble() ?? 0.0;

        return GestureDetector(
          onTap: () async {
            if (data != null &&
                (data['treinos'] as List?)?.isNotEmpty == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TelaDetalheTreino(workout: data),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToday ? AppColors.textDark : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Column(
              children: [
                Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isToday ? Colors.white : AppColors.textDark,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? Colors.white70 : AppColors.textGray,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  musculos,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isToday ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${porcentagem.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isToday ? Colors.white : AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayCardSkeleton(bool isToday) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? AppColors.textDark : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: isToday ? Colors.white : AppColors.primaryGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildMetrics(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.metrics,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
          key: ValueKey('${_rebuildKey}_metrics'),
          future: _getProgressData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final progress = snapshot.data ??
                {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    Icons.local_fire_department,
                    progress['calorias']!.toStringAsFixed(0),
                    strings.kcal,
                    strings.burned,
                    AppColors.accentOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    Icons.fitness_center,
                    progress['pesoLevantado']!.toStringAsFixed(0),
                    strings.kg,
                    strings.lifted,
                    AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    Icons.timer,
                    progress['tempoCardio']!.toStringAsFixed(0),
                    strings.minutes,
                    strings.trained,
                    AppColors.primaryGreen,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    IconData icon,
    String value,
    String unit,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ===== CIRCULAR PROGRESS PAINTER =====
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 4, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
