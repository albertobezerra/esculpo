import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:introduction_screen/introduction_screen.dart';

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
  int _currentPage = 0; // Rastreia a página atual
  final int _totalPages = 14; // Total de slides

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validação dos campos
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

        // Atualiza o displayName do usuário
        await user.updateDisplayName(_nameController.text.trim());

        // Navega pra próxima tela
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
    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFF4A4A4A), // Cinza Pedra Escuro
      showSkipButton: false,
      showNextButton: true,
      showDoneButton: true,
      next: const Icon(Icons.arrow_forward, color: Color(0xFFF5F5F0)),
      done: _isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE07A5F)),
            )
          : const Text(
              'Concluir',
              style: TextStyle(color: Color(0xFFF5F5F0)),
            ),
      onDone: _submit,
      onChange: (page) {
        setState(() {
          _currentPage = page;
        });
      },
      dotsDecorator: DotsDecorator(
        size: const Size(6.0, 6.0),
        activeSize: const Size(8.0, 8.0),
        spacing: const EdgeInsets.symmetric(horizontal: 2.0),
        color: Color.fromRGBO(
            245, 245, 240, 0.3), // Indicadores inativos com opacidade
        activeColor: const Color(0xFFE07A5F), // Indicador ativo
      ),
      pages: [
        // Slide 1: Nome
        PageViewModel(
          title: 'QUAL SEU NOME?',
          bodyWidget: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Digite seu nome',
                  labelStyle: TextStyle(color: Color(0xFF9D291A)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Color(0xFF4A4A4A)),
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/welcome_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 2: Data de Nascimento
        PageViewModel(
          title: 'QUAL SUA DATA DE NASCIMENTO?',
          bodyWidget: Column(
            children: [
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _birthDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  _birthDate == null
                      ? 'Selecionar data'
                      : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                  style: const TextStyle(color: Color(0xFFF5F5F0)),
                ),
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/calendar_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 3: Gênero
        PageViewModel(
          title: 'QUAL É SEU GÊNERO?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _gender,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                      value: 'Não binário', child: Text('Não binário')),
                  DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  DropdownMenuItem(
                      value: 'Prefiro não dizer',
                      child: Text('Prefiro não dizer')),
                ],
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/inclusive_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 4: Peso
        PageViewModel(
          title: 'QUAL SEU PESO?',
          bodyWidget: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Digite seu peso (kg)',
                  labelStyle: TextStyle(color: Color(0xFF9D291A)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Color(0xFF4A4A4A)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _weight = double.tryParse(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/weight_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 5: Altura
        PageViewModel(
          title: 'QUAL SUA ALTURA?',
          bodyWidget: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Digite sua altura (cm)',
                  labelStyle: TextStyle(color: Color(0xFF9D291A)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Color(0xFF4A4A4A)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _height = double.tryParse(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/height_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 6: Meta de Peso
        PageViewModel(
          title: 'QUAL SUA META DE PESO?',
          bodyWidget: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Digite sua meta (kg)',
                  labelStyle: TextStyle(color: Color(0xFF9D291A)),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Color(0xFF4A4A4A)),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _weightGoal = double.tryParse(value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) return 'Valor inválido';
                  return null;
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/goal_weight_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 7: Objetivo
        PageViewModel(
          title: 'QUAL SEU OBJETIVO?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _objective,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Perder peso', child: Text('Perder peso')),
                  DropdownMenuItem(
                      value: 'Ganhar massa', child: Text('Ganhar massa')),
                ],
                onChanged: (value) {
                  setState(() {
                    _objective = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/objective_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 8: Experiência
        PageViewModel(
          title: 'VOCÊ JÁ TEM EXPERIÊNCIA COM TREINOS?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _experience,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Sim, regularmente',
                      child: Text('Sim, treino regularmente')),
                  DropdownMenuItem(
                      value: 'Sim, >6 meses',
                      child: Text('Sim, treino a mais de seis meses')),
                  DropdownMenuItem(
                      value: 'Sim, <6 meses',
                      child: Text('Sim, treino a menos de seis meses')),
                  DropdownMenuItem(
                      value: 'Não', child: Text('Não tenho experiência')),
                ],
                onChanged: (value) {
                  setState(() {
                    _experience = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/experience_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 9: Frequência
        PageViewModel(
          title: 'COM QUAL FREQUÊNCIA DESEJA TREINAR?',
          bodyWidget: Column(
            children: [
              DropdownButton<int>(
                value: _frequency,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 dia na semana')),
                  DropdownMenuItem(value: 2, child: Text('2 dias na semana')),
                  DropdownMenuItem(value: 3, child: Text('3 dias na semana')),
                  DropdownMenuItem(value: 4, child: Text('4 dias na semana')),
                  DropdownMenuItem(value: 5, child: Text('5 dias na semana')),
                  DropdownMenuItem(value: 6, child: Text('6 dias na semana')),
                  DropdownMenuItem(value: 7, child: Text('7 dias na semana')),
                ],
                onChanged: (value) {
                  setState(() {
                    _frequency = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/frequency_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 10: Nível de Atividade Diária
        PageViewModel(
          title: 'QUAL SEU NÍVEL DE ATIVIDADE DIÁRIA?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _activityLevel,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Sedentário', child: Text('Sedentário')),
                  DropdownMenuItem(
                      value: 'Levemente ativo', child: Text('Levemente ativo')),
                  DropdownMenuItem(
                      value: 'Moderadamente ativo',
                      child: Text('Moderadamente ativo')),
                  DropdownMenuItem(
                      value: 'Muito ativo', child: Text('Muito ativo')),
                ],
                onChanged: (value) {
                  setState(() {
                    _activityLevel = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/activity_level_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 11: Equipamento Disponível
        PageViewModel(
          title: 'QUAL EQUIPAMENTO VOCÊ TEM?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _equipment,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Nenhum', child: Text('Nenhum equipamento')),
                  DropdownMenuItem(
                      value: 'Básico', child: Text('Equipamento básico')),
                  DropdownMenuItem(
                      value: 'Academia', child: Text('Academia completa')),
                ],
                onChanged: (value) {
                  setState(() {
                    _equipment = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/equipment_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 12: Preferência de Treino
        PageViewModel(
          title: 'QUAL SUA PREFERÊNCIA?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _preference,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Cardio', child: Text('Cardio')),
                  DropdownMenuItem(
                      value: 'Musculação', child: Text('Musculação')),
                  DropdownMenuItem(
                      value: 'Nenhuma', child: Text('Não tenho preferência')),
                ],
                onChanged: (value) {
                  setState(() {
                    _preference = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/preference_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 13: Horário Disponível
        PageViewModel(
          title: 'QUAL SEU HORÁRIO DISPONÍVEL?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _schedule,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Manhã', child: Text('Manhã')),
                  DropdownMenuItem(value: 'Tarde', child: Text('Tarde')),
                  DropdownMenuItem(value: 'Noite', child: Text('Noite')),
                ],
                onChanged: (value) {
                  setState(() {
                    _schedule = value;
                  });
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/schedule_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
        // Slide 14: Restrições ou Lesões
        PageViewModel(
          title: 'TEM RESTRIÇÕES OU LESÕES?',
          bodyWidget: Column(
            children: [
              DropdownButton<String>(
                value: _restrictions,
                hint: const Text('Selecione',
                    style: TextStyle(color: Color(0xFFB0B0B0))),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'Não', child: Text('Não tenho restrições')),
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
                },
              ),
            ],
          ),
          image: Image.asset(
            'assets/images/restrictions_illustration.png',
            height: 200,
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontFamily: 'Bebas Neue',
              fontSize: 28,
              color: Color(0xFF9D291A),
            ),
            bodyTextStyle: TextStyle(color: Color(0xFFF5F5F0)),
            imagePadding: EdgeInsets.only(top: 50),
          ),
        ),
      ],
    );
  }
}
