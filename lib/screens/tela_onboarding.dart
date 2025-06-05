import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo
          Image.asset(
            'assets/images/back_login.jpg',
            fit: BoxFit.cover,
          ),
          // Logo fixo na base
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: screenHeight * 0.2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Conteúdo central com IntroductionScreen
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: screenHeight * 0.28, // Espaço pra logo
              ),
              child: SizedBox(
                height: screenHeight *
                    0.72, // Altura restrita pro IntroductionScreen
                child: IntroductionScreen(
                  globalBackgroundColor: Colors.transparent,
                  showSkipButton: false,
                  showNextButton: true,
                  showDoneButton: true,
                  next:
                      const Icon(Icons.arrow_forward, color: Color(0xFFF5F5F0)),
                  done: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFE07A5F)),
                        )
                      : const Text(
                          'Concluir',
                          style: TextStyle(color: Color(0xFFF5F5F0)),
                        ),
                  onDone: _submit,
                  dotsDecorator: DotsDecorator(
                    size: const Size(4.0, 4.0),
                    activeSize: const Size(6.0, 6.0),
                    spacing: const EdgeInsets.symmetric(horizontal: 1.0),
                    color: Color.fromRGBO(245, 245, 240, 0.3),
                    activeColor: const Color(0xFFE07A5F),
                  ),
                  pages: [
                    // Slide 1: Nome
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SEU NOME?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: const Color(0xFFF5F5F0),
                                    selectionColor: const Color(0xFFF5F5F0)
                                        .withValues(alpha: 0.3),
                                    selectionHandleColor:
                                        const Color(0xFFF5F5F0),
                                  ),
                                ),
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'DIGITE SEU NOME',
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
                                  style:
                                      const TextStyle(color: Color(0xFFF5F5F0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 2: Data de Nascimento
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SUA DATA DE NASCIMENTO?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
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
                                      ? 'SELECIONAR DATA'
                                      : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 18,
                                    color: const Color(0xFFF5F5F0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 3: Gênero
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL É SEU GÊNERO?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _gender,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Masculino',
                                      child: Text('Masculino')),
                                  DropdownMenuItem(
                                      value: 'Feminino',
                                      child: Text('Feminino')),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 4: Peso
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SEU PESO?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: const Color(0xFFF5F5F0),
                                    selectionColor: const Color(0xFFF5F5F0)
                                        .withValues(alpha: 0.3),
                                    selectionHandleColor:
                                        const Color(0xFFF5F5F0),
                                  ),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'DIGITE SEU PESO (KG)',
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
                                  style:
                                      const TextStyle(color: Color(0xFFF5F5F0)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _weight = double.tryParse(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 5: Altura
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SUA ALTURA?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: const Color(0xFFF5F5F0),
                                    selectionColor: const Color(0xFFF5F5F0)
                                        .withValues(alpha: 0.3),
                                    selectionHandleColor:
                                        const Color(0xFFF5F5F0),
                                  ),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'DIGITE SUA ALTURA (CM)',
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
                                  style:
                                      const TextStyle(color: Color(0xFFF5F5F0)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _height = double.tryParse(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 6: Meta de Peso
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SUA META DE PESO?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  textSelectionTheme: TextSelectionThemeData(
                                    cursorColor: const Color(0xFFF5F5F0),
                                    selectionColor: const Color(0xFFF5F5F0)
                                        .withValues(alpha: 0.3),
                                    selectionHandleColor:
                                        const Color(0xFFF5F5F0),
                                  ),
                                ),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'DIGITE SUA META (KG)',
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
                                  style:
                                      const TextStyle(color: Color(0xFFF5F5F0)),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _weightGoal = double.tryParse(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 7: Objetivo
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SEU OBJETIVO?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _objective,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 8: Experiência
                    PageViewModel(
                      titleWidget: Text(
                        'VOCÊ JÁ TEM EXPERIÊNCIA COM TREINOS?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _experience,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Sim, regularmente',
                                      child: Text('Sim, treino regularmente')),
                                  DropdownMenuItem(
                                      value: 'Sim, >6 meses',
                                      child: Text(
                                          'Sim, treino a mais de seis meses')),
                                  DropdownMenuItem(
                                      value: 'Sim, <6 meses',
                                      child: Text(
                                          'Sim, treino a menos de seis meses')),
                                  DropdownMenuItem(
                                      value: 'Não',
                                      child: Text('Não tenho experiência')),
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
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 9: Frequência
                    PageViewModel(
                      titleWidget: Text(
                        'COM QUAL FREQUÊNCIA DESEJA TREINAR?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<int>(
                                value: _frequency,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 1, child: Text('1 dia na semana')),
                                  DropdownMenuItem(
                                      value: 2,
                                      child: Text('2 dias na semana')),
                                  DropdownMenuItem(
                                      value: 3,
                                      child: Text('3 dias na semana')),
                                  DropdownMenuItem(
                                      value: 4,
                                      child: Text('4 dias na semana')),
                                  DropdownMenuItem(
                                      value: 5,
                                      child: Text('5 dias na semana')),
                                  DropdownMenuItem(
                                      value: 6,
                                      child: Text('6 dias na semana')),
                                  DropdownMenuItem(
                                      value: 7,
                                      child: Text('7 dias na semana')),
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
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 10: Nível de Atividade Diária
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SEU NÍVEL DE ATIVIDADE DIÁRIA?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _activityLevel,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 11: Equipamento Disponível
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL EQUIPAMENTO VOCÊ TEM?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _equipment,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 12: Preferência de Treino
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SUA PREFERÊNCIA?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _preference,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 13: Horário Disponível
                    PageViewModel(
                      titleWidget: Text(
                        'QUAL SEU HORÁRIO DISPONÍVEL?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _schedule,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
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
                                },
                                style: GoogleFonts.bebasNeue(
                                  color: const Color(0xFFF5F5F0),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                    // Slide 14: Restrições ou Lesões
                    PageViewModel(
                      titleWidget: Text(
                        'TEM RESTRIÇÕES OU LESÕES?',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                        ),
                      ),
                      bodyWidget: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),
                              DropdownButton<String>(
                                value: _restrictions,
                                hint: Text(
                                  'SELECIONE',
                                  style: GoogleFonts.bebasNeue(
                                    color: const Color(0xFFB0B0B0),
                                    fontSize: 18,
                                  ),
                                ),
                                isExpanded: true,
                                underline: Container(
                                  height: 2,
                                  color: const Color(0xFFF5F5F0),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Não',
                                      child: Text('Não tenho restrições')),
                                  DropdownMenuItem(
                                      value: 'Lesões',
                                      child: Text('Tenho lesões')),
                                  DropdownMenuItem(
                                      value: 'Alimentares',
                                      child: Text('Restrições alimentares')),
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
                            ],
                          ),
                        ),
                      ),
                      decoration: const PageDecoration(
                        titleTextStyle: TextStyle(color: Colors.transparent),
                        bodyTextStyle: TextStyle(color: Colors.transparent),
                        contentMargin: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
