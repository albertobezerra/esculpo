import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Tenta fazer login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        // Se o usuário não existe ou a senha está errada, tenta criar uma nova conta
        try {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } on FirebaseAuthException catch (createError) {
          String message;
          if (createError.code == 'email-already-in-use') {
            message = 'Este email já está em uso. Tente redefinir sua senha.';
          } else {
            message = 'Erro ao criar conta: ${createError.message}';
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        }
      } else {
        // Outros erros de login
        String message = 'Erro ao fazer login: ${e.message}';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
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

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Por favor, insira seu email para redefinir a senha')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Email de redefinição de senha enviado! Verifique sua caixa de entrada.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'invalid-email') {
        message = 'Email inválido. Por favor, verifique o email inserido.';
      } else if (e.code == 'user-not-found') {
        message = 'Nenhum usuário encontrado com este email.';
      } else {
        message = 'Erro ao enviar email de redefinição: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Impede redimensionamento pelo teclado
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo
          Image.asset(
            'assets/images/back_login.jpg',
            fit: BoxFit.cover,
          ),
          // Título fixo no topo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/images/titulo_login.png',
                    fit: BoxFit.contain,
                    height: screenHeight * 0.15,
                  ),
                ),
              ),
            ),
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
                    mainAxisSize: MainAxisSize.min, // Corrigido de MainSize
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
          // Conteúdo central (título + formulário)
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: screenHeight * 0.18, // Espaço pra imagem de título
                bottom: screenHeight * 0.28, // Espaço pra logo
              ),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  // Título unificado
                  Text(
                    'LOGIN/CADASTRO',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // Formulário
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Corrigido de MainSize
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: const Color(0xFFF5F5F0),
                                selectionColor: const Color(0xFFF5F5F0)
                                    .withValues(
                                        alpha: 0.3), // Corrigido withOpacity
                                selectionHandleColor: const Color(0xFFF5F5F0),
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'EMAIL',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color:
                                      const Color(0xFFF5F5F0), // Branco Creme
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0), // Bordas brancas
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0), // Bordas brancas
                                    width: 2,
                                  ),
                                ),
                                filled: true, // Habilita preenchimento
                                fillColor:
                                    Colors.transparent, // Fundo transparente
                              ),
                              style: const TextStyle(
                                  color: Color(0xFFF5F5F0)), // Texto branco
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira seu email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Por favor, insira um email válido';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: const Color(0xFFF5F5F0),
                                selectionColor: const Color(0xFFF5F5F0)
                                    .withValues(
                                        alpha: 0.3), // Corrigido withOpacity
                                selectionHandleColor: const Color(0xFFF5F5F0),
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'SENHA',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color:
                                      const Color(0xFFF5F5F0), // Branco Creme
                                  fontSize: 18,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0), // Bordas brancas
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF5F5F0), // Bordas brancas
                                    width: 2,
                                  ),
                                ),
                                filled: true, // Habilita preenchimento
                                fillColor:
                                    Colors.transparent, // Fundo transparente
                              ),
                              style: const TextStyle(
                                  color: Color(0xFFF5F5F0)), // Texto branco
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira sua senha';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE07A5F)),
                                )
                              : GestureDetector(
                                  onTap: _submit,
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
                          SizedBox(height: screenHeight * 0.04),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'ESQUECI A SENHA',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFFF5F5F0),
                                    fontSize: 16,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
