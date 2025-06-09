import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TelaOnboarding extends StatefulWidget {
  const TelaOnboarding({super.key});

  @override
  State<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends State<TelaOnboarding> {
  final _nameController = TextEditingController();
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
  bool _isLoading = false;
  int _currentPage = 0;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'birthDate': _birthDate,
          'gender': _gender,
          'weight': _weight,
          'height': _height,
          'weightGoal': _weightGoal,
          'objective': _objective,
          'experience': _experience,
          'frequency': _frequency,
          'activityLevel': _activityLevel,
          'equipment': _equipment,
          'preference': _preference,
          'schedule': _schedule,
          'restrictions': _restrictions,
          'onboardingCompleted': true,
        }, SetOptions(merge: true));

        await user.updateDisplayName(_nameController.text.trim());

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/tela_inicial');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar dados: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        color: const Color(0xFFE07A5F),
        child: SafeArea(
          child: Column(
            children: [
              // Barra de progresso minimalista
              LinearProgressIndicator(
                value: (_currentPage + 1) / 14,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF5F5F0)),
                minHeight: 4.0,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // Slide 1: Nome
                    _buildPage(
                      title: 'Qual Seu Nome?',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                        ),
                      ),
                    ),
                    // Slide 2: Data de Nascimento
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
                                : DateFormat('dd/MM/yyyy').format(_birthDate!),
                            style: GoogleFonts.bebasNeue(
                              fontSize: 18,
                              color: const Color(0xFFF5F5F0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Slide 3: Gênero
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
                                value: 'Masculino',
                                child: Text('Masculino',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Feminino',
                                child: Text('Feminino',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Não binário',
                                child: Text('Não binário',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Outro',
                                child: Text('Outro',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Prefiro não dizer',
                                child: Text('Prefiro não dizer',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _gender = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 4: Peso
                    _buildPage(
                      title: 'Qual Seu Peso?',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.words,
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
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _weight = double.tryParse(value);
                          },
                        ),
                      ),
                    ),
                    // Slide 5: Altura
                    _buildPage(
                      title: 'Qual Sua Altura?',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.words,
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
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _height = double.tryParse(value);
                          },
                        ),
                      ),
                    ),
                    // Slide 6: Meta de Peso
                    _buildPage(
                      title: 'Qual Sua Meta de Peso?',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: TextFormField(
                          textCapitalization: TextCapitalization.words,
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
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _weightGoal = double.tryParse(value);
                          },
                        ),
                      ),
                    ),
                    // Slide 7: Objetivo
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
                                child: Text('Perder peso',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Ganhar massa',
                                child: Text('Ganhar massa',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _objective = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 8: Experiência
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
                                child: Text('Sim, treino regularmente',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Sim, >6 meses',
                                child: Text('Sim, treino a mais de seis meses',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Sim, <6 meses',
                                child: Text('Sim, treino a menos de seis meses',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Não',
                                child: Text('Não tenho experiência',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _experience = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 9: Frequência
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
                                value: 1,
                                child: Text('1 dia na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 2,
                                child: Text('2 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 3,
                                child: Text('3 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 4,
                                child: Text('4 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 5,
                                child: Text('5 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 6,
                                child: Text('6 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 7,
                                child: Text('7 dias na semana',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _frequency = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 10: Nível de Atividade Diária
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
                                child: Text('Sedentário',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Levemente ativo',
                                child: Text('Levemente ativo',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Moderadamente ativo',
                                child: Text('Moderadamente ativo',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Muito ativo',
                                child: Text('Muito ativo',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _activityLevel = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 11: Equipamento Disponível
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
                                child: Text('Nenhum equipamento',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Básico',
                                child: Text('Equipamento básico',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Academia',
                                child: Text('Academia completa',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _equipment = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 12: Preferência de Treino
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
                                value: 'Cardio',
                                child: Text('Cardio',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Musculação',
                                child: Text('Musculação',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Nenhuma',
                                child: Text('Não tenho preferência',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _preference = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 13: Horário Disponível
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
                                value: 'Manhã',
                                child: Text('Manhã',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Tarde',
                                child: Text('Tarde',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Noite',
                                child: Text('Noite',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _schedule = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    // Slide 14: Restrições ou Lesões
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
                                child: Text('Não tenho restrições',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Lesões',
                                child: Text('Tenho lesões',
                                    style: TextStyle(color: Colors.black))),
                            DropdownMenuItem(
                                value: 'Alimentares',
                                child: Text('Restrições alimentares',
                                    style: TextStyle(color: Colors.black))),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _restrictions = value;
                            });
                          },
                          style: GoogleFonts.bebasNeue(
                            color: const Color(0xFFF5F5F0),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_currentPage == 13)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(
                        color: Color(0xFFF5F5F0),
                        width: 2,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE07A5F)),
                          )
                        : const Text(
                            'Concluir',
                            style: TextStyle(color: Color(0xFFF5F5F0)),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required Widget child}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.bebasNeue(
              fontSize: 32,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
