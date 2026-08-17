import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:guarda_corpo_2024/core/navigation/app_route_names.dart';
import 'package:guarda_corpo_2024/features/auth/data/auth_repository.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _isRegisterMode = false;

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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegisterMode) {
        await _authRepository.createAccount(email: email, password: password);
      } else {
        await _authRepository.signIn(email: email, password: password);
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.auth,
          (_) => false,
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro inesperado: $e')));
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
          content: Text('Por favor, insira seu email para redefinir a senha'),
        ),
      );
      return;
    }

    try {
      await _authRepository.sendPasswordReset(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email de redefinição de senha enviado! Verifique sua caixa de entrada.',
            ),
          ),
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  String _messageFor(AuthFailure failure) {
    return switch (failure.code) {
      'invalid-email' => 'Email inválido. Verifique o endereço informado.',
      'invalid-credential' || 'wrong-password' => 'Email ou senha incorretos.',
      'user-not-found' => 'Nenhuma conta encontrada com este email.',
      'email-already-in-use' => 'Este email já possui uma conta.',
      'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde um pouco e tente novamente.',
      'network-request-failed' =>
        'Sem conexão. Verifique sua internet e tente novamente.',
      'profile-write-failed' =>
        'A conta foi criada, mas o perfil não pôde ser preparado.',
      _ => failure.details ?? 'Não foi possível concluir a operação.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo
          Image.asset('assets/images/back_login.jpg', fit: BoxFit.cover),
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
                    _isRegisterMode ? 'CRIAR CONTA' : 'ENTRAR',
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: const Color(0xFFF5F5F0),
                                selectionColor: const Color(0xFFF5F5F0)
                                    .withValues(alpha: 0.3),
                                selectionHandleColor: const Color(0xFFF5F5F0),
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'EMAIL',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(
                                    0xFFF5F5F0,
                                  ), // Branco Creme
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
                                color: Color(0xFFF5F5F0),
                              ), // Texto branco
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
                                    .withValues(alpha: 0.3),
                                selectionHandleColor: const Color(0xFFF5F5F0),
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'SENHA',
                                labelStyle: GoogleFonts.bebasNeue(
                                  color: const Color(
                                    0xFFF5F5F0,
                                  ), // Branco Creme
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
                                color: Color(0xFFF5F5F0),
                              ), // Texto branco
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
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isRegisterMode
                                          ? 'CRIAR MINHA CONTA'
                                          : 'ENTRAR',
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(
                                    () => _isRegisterMode = !_isRegisterMode,
                                  ),
                            child: Text(
                              _isRegisterMode
                                  ? 'JÁ TENHO CONTA'
                                  : 'QUERO CRIAR UMA CONTA',
                              style: const TextStyle(color: Color(0xFFF5F5F0)),
                            ),
                          ),
                          if (!_isRegisterMode)
                            TextButton(
                              onPressed: _isLoading ? null : _resetPassword,
                              child: Text(
                                'ESQUECI A SENHA',
                                style: Theme.of(context).textTheme.bodyMedium
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
