import 'package:flutter/material.dart';
import 'package:guarda_corpo_2024/core/navigation/app_route_names.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> {
  static const _backgroundImage = 'assets/images/splash1.jpg';

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.auth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'ESCULPO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
