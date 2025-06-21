import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'tela_inicial.dart';

class TelaOnboarding extends StatefulWidget {
  const TelaOnboarding({super.key});

  @override
  State<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends State<TelaOnboarding>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightGoalController = TextEditingController();

  DateTime? _birthDate;
  String? _gender;
  double? _weight;
  double? _height;
  double? _weightGoal;
  String? _objective;
  String? _experience;
  int? _frequency;
  String? _activityLevel;
  String? _equipment;
  String? _preference;
  String? _schedule;
  String? _restrictions;

  int _currentPage = 0;
  final PageController _pageController = PageController();

  bool _isSubmitting = false;

  final _nameFormKey = GlobalKey<FormState>();
  final _weightFormKey = GlobalKey<FormState>();
  final _heightFormKey = GlobalKey<FormState>();
  final _weightGoalFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weightGoalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 14) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _confirmAndSubmit() async {
    if (_nameController.text.trim().isEmpty ||
        _birthDate == null ||
        _gender == null ||
        _weight == null ||
        _height == null ||
        _weightGoal == null ||
        _objective == null ||
        _experience == null ||
        _frequency == null ||
        _activityLevel == null ||
        _equipment == null ||
        _preference == null ||
        _schedule == null ||
        _restrictions == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .set({
          'nome': _nameController.text.trim(),
          'dataNascimento': _birthDate,
          'genero': _gender,
          'peso': _weight,
          'altura': _height,
          'metaPeso': _weightGoal,
          'objetivo': _objective,
          'experiencia': _experience,
          'frequencia': _frequency,
          'nivelAtividade': _activityLevel,
          'equipamento': _equipment,
          'preferencia': _preference,
          'horario': _schedule,
          'restricoes': _restrictions,
          'onboardingConcluido': true,
        }, SetOptions(merge: true));

        debugPrint('Salvamento no Firebase concluído.');
        await user.updateDisplayName(_nameController.text.trim());

        // Verifica se o widget ainda está montado antes de navegar
        if (mounted) {
          debugPrint('Navegando para TelaInicial...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TelaInicial()),
          );
          debugPrint('Navegação concluída.');
        }
      } catch (e) {
        debugPrint('Erro ao salvar no Firebase ou navegar: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Erro ao salvar ou navegar. Tente novamente.')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildPage({required String title, required Widget child}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              title,
              style: GoogleFonts.bebasNeue(
                fontSize: 32,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A4A4A),
      body: SafeArea(
        child: Stack(
          children: [
            // Barra de progresso
            LinearProgressIndicator(
              value: (_currentPage + 1) / 15,
              backgroundColor: const Color.fromRGBO(255, 255, 255, 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF5F5F0)),
              minHeight: 4.0,
            ),

            // Conteúdo principal
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // Slide 0 - Boas-vindas
                      _buildPage(
                        title:
                            'Para tornar sua jornada mais personalizada e proveitosa, responda todas as perguntas a seguir com carinho. Vamos construir algo especial juntos! 😊',
                        child: const SizedBox.shrink(),
                      ),

                      // Slide 1 - Nome
                      _buildPage(
                        title: 'Qual Seu Nome?',
                        child: Form(
                          key: _nameFormKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Digite Seu Nome',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              style: const TextStyle(color: Color(0xFFF5F5F0)),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                if (_nameFormKey.currentState!.validate()) {
                                  _nextPage();
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Slide 2 - Data de Nascimento
                      _buildPage(
                        title: 'Qual Sua Data de Nascimento?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: ElevatedButton(
                            onPressed: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                locale: const Locale('pt', 'BR'),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _birthDate = pickedDate;
                                });
                                _nextPage();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: const BorderSide(
                                color: Color(0xFFF5F5F0),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _birthDate == null
                                  ? 'Selecionar Data'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_birthDate!),
                              style: GoogleFonts.bebasNeue(
                                fontSize: 18,
                                color: const Color(0xFFF5F5F0),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Slide 3 - Gênero
                      _buildPage(
                        title: 'Qual é Seu Gênero?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _gender,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Masculino', child: Text('Masculino')),
                              DropdownMenuItem(
                                  value: 'Feminino', child: Text('Feminino')),
                              DropdownMenuItem(
                                  value: 'Não binário',
                                  child: Text('Não binário')),
                              DropdownMenuItem(
                                  value: 'Outro', child: Text('Outro')),
                              DropdownMenuItem(
                                  value: 'Prefiro não dizer',
                                  child: Text('Prefiro não dizer')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _gender = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 4 - Peso
                      _buildPage(
                        title: 'Qual Seu Peso?',
                        child: Form(
                          key: _weightFormKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Digite Seu Peso (KG)',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              style: const TextStyle(color: Color(0xFFF5F5F0)),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Por favor, digite seu peso';
                                }
                                return null;
                              },
                              onFieldSubmitted: (value) {
                                if (_weightFormKey.currentState!.validate()) {
                                  setState(() {
                                    _weight = double.tryParse(value) ?? 0.0;
                                    _nextPage();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Slide 5 - Altura
                      _buildPage(
                        title: 'Qual Sua Altura?',
                        child: Form(
                          key: _heightFormKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Digite Sua Altura (CM)',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              style: const TextStyle(color: Color(0xFFF5F5F0)),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Por favor, digite sua altura';
                                }
                                return null;
                              },
                              onFieldSubmitted: (value) {
                                if (_heightFormKey.currentState!.validate()) {
                                  setState(() {
                                    _height = double.tryParse(value) ?? 0.0;
                                    _nextPage();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Slide 6 - Meta de Peso
                      _buildPage(
                        title: 'Qual Sua Meta de Peso?',
                        child: Form(
                          key: _weightGoalFormKey,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TextFormField(
                              controller: _weightGoalController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Digite Sua Meta (KG)',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0),
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                              ),
                              style: const TextStyle(color: Color(0xFFF5F5F0)),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Por favor, digite sua meta';
                                }
                                return null;
                              },
                              onFieldSubmitted: (value) {
                                if (_weightGoalFormKey.currentState!
                                    .validate()) {
                                  setState(() {
                                    _weightGoal = double.tryParse(value) ?? 0.0;
                                    _nextPage();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Slide 7 - Objetivo
                      _buildPage(
                        title: 'Qual Seu Objetivo?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _objective,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Perder peso',
                                  child: Text('Perder peso')),
                              DropdownMenuItem(
                                  value: 'Ganhar massa',
                                  child: Text('Ganhar massa')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _objective = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 8 - Experiência
                      _buildPage(
                        title: 'Você Já Tem Experiência com Treinos?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _experience,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Sim, regularmente',
                                  child: Text('Sim, treino regularmente')),
                              DropdownMenuItem(
                                  value: 'Sim, >6 meses',
                                  child: Text(
                                      'Sim, treino há mais de seis meses')),
                              DropdownMenuItem(
                                  value: 'Sim, <6 meses',
                                  child: Text(
                                      'Sim, treino há menos de seis meses')),
                              DropdownMenuItem(
                                  value: 'Não',
                                  child: Text('Não tenho experiência')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _experience = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 9 - Frequência
                      _buildPage(
                        title: 'Com Qual Frequência Deseja Treinar?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<int>(
                            value: _frequency,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 1, child: Text('1 dia na semana')),
                              DropdownMenuItem(
                                  value: 2, child: Text('2 dias na semana')),
                              DropdownMenuItem(
                                  value: 3, child: Text('3 dias na semana')),
                              DropdownMenuItem(
                                  value: 4, child: Text('4 dias na semana')),
                              DropdownMenuItem(
                                  value: 5, child: Text('5 dias na semana')),
                              DropdownMenuItem(
                                  value: 6, child: Text('6 dias na semana')),
                              DropdownMenuItem(
                                  value: 7, child: Text('7 dias na semana')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _frequency = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 10 - Nível de Atividade
                      _buildPage(
                        title: 'Qual Seu Nível de Atividade Diária?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _activityLevel,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Sedentário',
                                  child: Text('Sedentário')),
                              DropdownMenuItem(
                                  value: 'Levemente ativo',
                                  child: Text('Levemente ativo')),
                              DropdownMenuItem(
                                  value: 'Moderadamente ativo',
                                  child: Text('Moderadamente ativo')),
                              DropdownMenuItem(
                                  value: 'Muito ativo',
                                  child: Text('Muito ativo')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _activityLevel = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 11 - Equipamento
                      _buildPage(
                        title: 'Qual Equipamento Você Tem?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _equipment,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Nenhum',
                                  child: Text('Nenhum equipamento')),
                              DropdownMenuItem(
                                  value: 'Básico',
                                  child: Text('Equipamento básico')),
                              DropdownMenuItem(
                                  value: 'Academia',
                                  child: Text('Academia completa')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _equipment = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 12 - Preferência
                      _buildPage(
                        title: 'Qual Sua Preferência?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _preference,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Cardio', child: Text('Cardio')),
                              DropdownMenuItem(
                                  value: 'Musculação',
                                  child: Text('Musculação')),
                              DropdownMenuItem(
                                  value: 'Nenhuma',
                                  child: Text('Não tenho preferência')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _preference = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 13 - Horário
                      _buildPage(
                        title: 'Qual Seu Horário Disponível?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _schedule,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Manhã', child: Text('Manhã')),
                              DropdownMenuItem(
                                  value: 'Tarde', child: Text('Tarde')),
                              DropdownMenuItem(
                                  value: 'Noite', child: Text('Noite')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _schedule = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 14 - Restrições
                      _buildPage(
                        title: 'Tem Restrições ou Lesões?',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: DropdownButton<String>(
                            value: _restrictions,
                            hint: Text(
                              'Selecione',
                              style: GoogleFonts.bebasNeue(
                                color: const Color(0xFFB0B0B0),
                                fontSize: 18,
                              ),
                            ),
                            isExpanded: true,
                            underline: const SizedBox(
                              height: 2,
                              child: DecoratedBox(
                                decoration:
                                    BoxDecoration(color: Color(0xFFF5F5F0)),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Não',
                                  child: Text('Não tenho restrições')),
                              DropdownMenuItem(
                                  value: 'Lesões', child: Text('Tenho lesões')),
                              DropdownMenuItem(
                                  value: 'Alimentares',
                                  child: Text('Restrições alimentares')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _restrictions = value;
                              });
                              _nextPage();
                            },
                            style: GoogleFonts.bebasNeue(
                              color: const Color(0xFFF5F5F0),
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                      // Slide 15 - Confirmação
                      _buildPage(
                        title: 'Confirme Suas Informações',
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome: ${_nameController.text}',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text(
                                  'Data de Nascimento: ${_birthDate != null ? DateFormat('dd/MM/yyyy').format(_birthDate!) : ''}',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Gênero: $_gender',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Peso: $_weight kg',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Altura: $_height cm',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Meta de Peso: $_weightGoal kg',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Objetivo: $_objective',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Experiência: $_experience',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Frequência: $_frequency dias/semana',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Nível de Atividade: $_activityLevel',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Equipamento: $_equipment',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Preferência: $_preference',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Horário: $_schedule',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              Text('Restrições: $_restrictions',
                                  style: GoogleFonts.bebasNeue(
                                      color: Colors.white)),
                              const SizedBox(height: 20),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: IconButton(
                                  icon: const Icon(Icons.check,
                                      color: Color(0xFFF5F5F0), size: 40),
                                  onPressed: _confirmAndSubmit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
