import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
