import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class TelaOnboarding extends StatefulWidget {
  const TelaOnboarding({super.key});

  @override
  State<TelaOnboarding> createState() => _TelaOnboardingState();
}

class _TelaOnboardingState extends State<TelaOnboarding> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _idadeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    super.dispose();
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtém o UID do usuário logado
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Salva os dados no Firestore usando set() com merge: true
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nome': _nomeController.text.trim(),
        'idade': int.parse(_idadeController.text.trim()),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );
      }

      // Navega pra próxima tela (ex.: tela inicial ou planos de treino)
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProximaTela()));
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'BEM-VINDO AO ESCULPO',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'NOME',
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
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  controller: _idadeController,
                  decoration: InputDecoration(
                    labelText: 'IDADE',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua idade';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Por favor, insira uma idade válida';
                    }
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE07A5F)),
                      )
                    : GestureDetector(
                        onTap: _salvarDados,
                        child: const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.arrow_circle_right_outlined,
                            color: Color(0xFFF5F5F0),
                            size: 70,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
