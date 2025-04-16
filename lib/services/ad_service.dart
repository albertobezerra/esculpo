import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:guarda_corpo_2024/screens/subscription_service.dart';
import '../screens/webview_test_screen.dart';

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
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final isPremium = ref.watch(subscriptionProvider).isPremium(userId);

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
                      Navigator.pushNamed(context, '/create-workout');
                    },
                    child: const Text('Criar Treino'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/exercises');
                    },
                    child: const Text('Ver Exercícios'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: const Text('Perfil'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/subscription');
                    },
                    child: const Text('Assinatura'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WebViewTestScreen()));
                    },
                    child: const Text('Testar WebView'),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<bool>(
            stream: isPremium,
            builder: (context, snapshot) {
              if (snapshot.data == true || !adService.isBannerLoaded) {
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
