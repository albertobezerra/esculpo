import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guarda_corpo_2024/providers/providers.dart';
import 'package:guarda_corpo_2024/screens/tela_planos_treino.dart';
import 'package:guarda_corpo_2024/screens/tela_historico_treinos.dart';
import 'package:guarda_corpo_2024/screens/tela_exercicios.dart';
import 'package:guarda_corpo_2024/screens/profile_screen.dart';
import 'package:guarda_corpo_2024/services/ad_service.dart';

class TelaInicial extends ConsumerStatefulWidget {
  const TelaInicial({super.key});

  @override
  ConsumerState<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends ConsumerState<TelaInicial> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    ref.read(adProvider).loadBannerAd();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>?> _getTodayWorkout() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final planGenerator = ref.read(planGeneratorServiceProvider);
    return await planGenerator.generateDailyWorkout(userId, _selectedDate);
  }

  @override
  void dispose() {
    ref.read(adProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = ref.watch(adProvider);
    final screens = [
      _buildHomeContent(),
      const TelaPlanosTreino(),
      const TelaHistoricoTreinos(),
      const TelaExercicios(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Esculpo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Implementar notificações
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: screens[_selectedIndex]),
          StreamBuilder<bool>(
            stream: ref
                .watch(subscriptionProvider)
                .isPremium(FirebaseAuth.instance.currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.data == true || !adService.isBannerLoaded) {
                return const SizedBox();
              }
              return adService.bannerAd != null
                  ? SizedBox(
                      height: adService.bannerAd!.size.height.toDouble(),
                      width: adService.bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: adService.bannerAd!),
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Planos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Exercícios'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF9D291A),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Treino do Dia',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>?>(
            future: _getTodayWorkout(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return const Text('Nenhum treino disponível para hoje');
              }
              final treino = snapshot.data!;
              return Card(
                child: ListTile(
                  title: Text(treino['nome'] ?? 'Treino do Dia'),
                  subtitle: Text(
                      'Exercícios: ${(treino['exercicios'] as List?)?.length ?? 0}'),
                  onTap: () {
                    Navigator.pushNamed(context, '/detalhe_treino',
                        arguments: treino);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text('Progresso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressCard(
                      'Calorias', '${data?['caloriasGastas'] ?? 0} kcal'),
                  _buildProgressCard(
                      'Peso Levantado', '${data?['pesoLevantado'] ?? 0} kg'),
                  _buildProgressCard(
                      'Tempo Cardio', '${data?['tempoCardio'] ?? 0} min'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
