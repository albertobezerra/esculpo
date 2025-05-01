import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_service.dart';
import 'tela_treino.dart';
import 'tela_exercicios.dart';
import 'tela_planos_treino.dart';
import 'tela_historico_treinos.dart';

final adProvider = Provider((ref) => AdService());

class AdService {
  BannerAd? bannerAd;
  bool isBannerLoaded = false;

  Future<void> loadBannerAd() async {
    debugPrint('Iniciando carregamento do banner');
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // ID de teste
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isBannerLoaded = true;
          debugPrint('Banner carregado');
        },
        onAdFailedToLoad: (ad, error) {
          isBannerLoaded = false;
          debugPrint('Erro no banner: $error');
          ad.dispose();
        },
      ),
    );
    try {
      await bannerAd!.load();
      debugPrint('Banner load concluído');
    } catch (e) {
      debugPrint('Exceção ao carregar banner: $e');
    }
  }

  void dispose() {
    bannerAd?.dispose();
    bannerAd = null;
    isBannerLoaded = false;
  }
}

class TelaInicial extends ConsumerStatefulWidget {
  const TelaInicial({super.key});

  @override
  ConsumerState<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends ConsumerState<TelaInicial> {
  @override
  void initState() {
    super.initState();
    ref.read(adProvider).loadBannerAd();
  }

  @override
  void dispose() {
    ref.read(adProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = ref.watch(adProvider);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isPremiumAsync = ref.watch(subscriptionProvider).isPremium(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Esculpo')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Você tá ficando mais forte! 💪',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TelaTreino()),
                      );
                    },
                    child: const Text('Criar Treino'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TelaExercicios()),
                      );
                    },
                    child: const Text('Ver Exercícios'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TelaHistoricoTreinos()),
                      );
                    },
                    child: const Text('Histórico de Treinos'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TelaPlanosTreino()),
                      );
                    },
                    child: const Text('Planos de Treino'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Tela de perfil ainda não implementada')),
                      );
                    },
                    child: const Text('Perfil'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Tela de assinatura ainda não implementada')),
                      );
                    },
                    child: const Text('Assinatura'),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<bool>(
            stream: isPremiumAsync,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }
              if (snapshot.hasError) {
                debugPrint('Erro no isPremium: ${snapshot.error}');
                return const SizedBox();
              }
              if (snapshot.data == true || !adService.isBannerLoaded) {
                debugPrint(
                    'Banner não exibido: premium=${snapshot.data}, loaded=${adService.isBannerLoaded}');
                return const SizedBox();
              }
              debugPrint('Exibindo banner: ${adService.bannerAd}');
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
    );
  }
}
