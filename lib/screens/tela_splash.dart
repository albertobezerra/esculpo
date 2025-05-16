import 'package:flutter/material.dart';
import 'dart:math';
import '../main.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> {
  // Lista de imagens (substitua pelos caminhos das suas imagens)
  final List<String> backgroundImages = [
    'assets/images/splash1.jpg',
    'assets/images/splash2.jpg',
    'assets/images/splash3.jpg',
    'assets/images/splash4.jpg',
    'assets/images/splash5.jpg',
    'assets/images/splash6.jpg',
    'assets/images/splash7.jpg',
    'assets/images/splash8.jpg',
    'assets/images/splash9.jpg',
    'assets/images/splash10.jpg',
    'assets/images/splash11.jpg',
    'assets/images/splash12.jpg',
    'assets/images/splash13.jpg',
    'assets/images/splash14.jpg',
    'assets/images/splash15.jpg',
    'assets/images/splash16.jpg',
  ];

  // Seleciona uma imagem aleatória
  String getRandomImage() {
    final random = Random();
    return backgroundImages[random.nextInt(backgroundImages.length)];
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem de fundo aleatória
          Image.asset(
            getRandomImage(),
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}
