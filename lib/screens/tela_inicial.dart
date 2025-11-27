import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';
import 'tela_exercicios.dart';
import 'tela_detalhe_treino.dart';
import 'package:guarda_corpo_2024/core/theme/app_theme.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final barWidth = screenWidth * 0.64;
    final leftOffset = (screenWidth - barWidth) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
          Positioned(
            left: leftOffset > 20 ? leftOffset : 20,
            bottom: 30,
            child: SizedBox(
              width: barWidth,
              height: 70,
              child: Material(
                color: const Color(0xFF9D291A),
                borderRadius: const BorderRadius.all(Radius.circular(35)),
                elevation: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildNavIcon(Icons.home, 0)),
                    Expanded(child: _buildNavIcon(Icons.calendar_today, 1)),
                    Expanded(child: _buildNavIcon(Icons.history, 2)),
                    Expanded(child: _buildNavIcon(Icons.directions_run, 3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : null,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? const Color(0xFF9D291A) : Colors.white70,
          size: 30,
        ),
        onPressed: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class TelaInicialContent extends ConsumerStatefulWidget {
  const TelaInicialContent({super.key});

  @override
  ConsumerState<TelaInicialContent> createState() => _TelaInicialContentState();
}

class _TelaInicialContentState extends ConsumerState<TelaInicialContent> {
  bool hasNotification = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Cache e controle de rebuild
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
      setState(() {
        _profileImage = file;
      });
    }
  }

  Future<void> _saveProfileImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = path.join(directory.path, 'profile_image.jpg');
    final file = File(imagePath);
    await image.copy(file.path);
    setState(() {
      _profileImage = file;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await _saveProfileImage(file);
    }
  }

  Future<void> _showChangePhotoDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Foto'),
        content: const Text('Deseja alterar a foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImage();
            },
            child: const Text('Sim'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    _workoutCache.clear();
  }

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
          debugPrint('🔄 Gerando plano inicial...');
          await ref.read(geradorTreinosProvider).gerarPlanoCompleto(
                usuarioId: userId,
              );
          debugPrint('✅ Plano gerado!');
          _clearCache();
          setState(() {
            _rebuildKey++;
          });
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
      debugPrint('Erro ao obter treino: $e');
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
      debugPrint('Erro ao obter progresso: $e');
      return {'calorias': 0.0, 'pesoLevantado': 0.0, 'tempoCardio': 0.0};
    }
  }

  Widget _buildDayCard(
      DateTime date, String treino, double porcentagem, Color backgroundColor,
      {Color textColor = Colors.black,
      Color? borderColor,
      required DateTime now}) {
    String porcentagemTexto = '${porcentagem.toStringAsFixed(0)}%';

    return GestureDetector(
      onTap: () async {
        final workout = await _getCachedWorkout(date);
        if (workout != null &&
            (workout['treinos'] as List?)?.isNotEmpty == true) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TelaDetalheTreino(workout: workout),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Dia de descanso'),
                  duration: Duration(seconds: 1)),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: GoogleFonts.bebasNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                treino,
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                porcentagemTexto,
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGauge(String title, double value, double maxValue, String label,
      String description) {
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: maxValue,
                showLabels: false,
                showTicks: false,
                ranges: <GaugeRange>[
                  GaugeRange(
                    startValue: 0,
                    endValue: value,
                    color: AppTheme.theme.colorScheme.secondary,
                  ),
                  GaugeRange(
                    startValue: value,
                    endValue: maxValue,
                    color: AppTheme.theme.colorScheme.surface.withAlpha(77),
                  ),
                ],
                pointers: <GaugePointer>[
                  RangePointer(
                    value: value,
                    width: 0.1,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: AppTheme.theme.colorScheme.secondary,
                  ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Text(label,
                        style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9D291A))),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(description,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9D291A))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate =
        DateFormat('EEE, dd \'DE\' MMMM \'DE\' yyyy', 'pt_BR')
            .format(now)
            .toUpperCase();
    final int hour = now.hour;
    String greeting = 'Bom dia,';
    if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde,';
    } else if (hour >= 18 || hour < 6) {
      greeting = 'Boa noite,';
    }
    final userName = user?.displayName ?? 'Usuário';

    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _profileImage == null
                        ? _pickImage
                        : _showChangePhotoDialog,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF9D291A),
                      foregroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.add_a_photo_outlined,
                              size: 30, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          userName.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFF9D291A),
                            fontSize: 28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formattedDate,
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: hasNotification
                        ? const Color(0xFF9D291A)
                        : AppTheme.theme.colorScheme.surface,
                    child: IconButton(
                      icon: const Icon(Icons.notifications,
                          color: Color.fromARGB(255, 225, 225, 225), size: 20),
                      onPressed: () {
                        setState(() {
                          hasNotification = !hasNotification;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'HOJE É DIA DE TREINAR'.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<Map<String, dynamic>?>(
                key: ValueKey(_rebuildKey),
                future: _getCachedWorkout(now),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9D291A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final workout = snapshot.data;
                  final musculos = workout?['musculos'] ?? 'SEM TREINO';
                  final temExercicios =
                      (workout?['treinos'] as List?)?.isNotEmpty ?? false;

                  return GestureDetector(
                    onTap: temExercicios
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TelaDetalheTreino(workout: workout!),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: 110,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9D291A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          musculos,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'CALENDÁRIO DE TREINOS'.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        key: ValueKey('${_rebuildKey}_prev'),
                        future: _getCachedWorkout(
                            now.subtract(const Duration(days: 1))),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final data = snapshot.data ??
                              {'musculos': 'Descanso', 'porcentagem': 0.0};
                          return _buildDayCard(
                            now.subtract(const Duration(days: 1)),
                            data['musculos'],
                            data['porcentagem'],
                            Colors.white,
                            textColor: const Color(0xFF9D291A),
                            borderColor: const Color(0xFF9D291A),
                            now: now,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        key: ValueKey('${_rebuildKey}_today'),
                        future: _getCachedWorkout(now),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final data = snapshot.data ??
                              {'musculos': 'Sem treino', 'porcentagem': 0.0};
                          return _buildDayCard(
                            now,
                            data['musculos'],
                            data['porcentagem'],
                            const Color(0xFF9D291A),
                            textColor: Colors.white,
                            now: now,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<Map<String, dynamic>?>(
                        key: ValueKey('${_rebuildKey}_next'),
                        future:
                            _getCachedWorkout(now.add(const Duration(days: 1))),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final data = snapshot.data ??
                              {'musculos': 'Sem treino', 'porcentagem': 0.0};
                          return _buildDayCard(
                            now.add(const Duration(days: 1)),
                            data['musculos'],
                            data['porcentagem'],
                            Colors.white,
                            textColor: const Color(0xFF9D291A),
                            borderColor: const Color(0xFF9D291A),
                            now: now,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PROGRESSO'.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, double>>(
                key: ValueKey('${_rebuildKey}_progress'),
                future: _getProgressData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final progress = snapshot.data ??
                      {
                        'calorias': 0.0,
                        'pesoLevantado': 0.0,
                        'tempoCardio': 0.0
                      };
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildGauge(
                            'Calorias',
                            progress['calorias']!,
                            500,
                            progress['calorias']!.toStringAsFixed(0),
                            'Calorias'),
                      ),
                      Expanded(
                        child: _buildGauge(
                            'Peso',
                            progress['pesoLevantado']!,
                            200,
                            '${progress['pesoLevantado']!.toStringAsFixed(0)}kg',
                            'Peso levantado'),
                      ),
                      Expanded(
                        child: _buildGauge(
                            'Tempo',
                            progress['tempoCardio']!,
                            60,
                            '${progress['tempoCardio']!.toStringAsFixed(0)}min',
                            'Tempo treino'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
