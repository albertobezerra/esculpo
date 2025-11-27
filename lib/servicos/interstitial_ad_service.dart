import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

final interstitialAdProvider = Provider((ref) => InterstitialAdService());

class InterstitialAdService {
  InterstitialAd? interstitialAd;
  bool isAdLoaded = false;
  DateTime? lastAdShownTime;
  static const int adCooldownSeconds = 120; // 2 minutos

  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // ID de teste
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
          isAdLoaded = true;
          debugPrint('Interstitial carregado');
        },
        onAdFailedToLoad: (error) {
          isAdLoaded = false;
          debugPrint('Erro no interstitial: $error');
          interstitialAd = null;
        },
      ),
    );
  }

  bool canShowAd() {
    if (!isAdLoaded || interstitialAd == null) {
      debugPrint('Anúncio não carregado');
      return false;
    }
    if (lastAdShownTime == null) {
      return true;
    }
    final now = DateTime.now();
    final diff = now.difference(lastAdShownTime!).inSeconds;
    if (diff < adCooldownSeconds) {
      debugPrint('Cooldown ativo: faltam ${adCooldownSeconds - diff} segundos');
      return false;
    }
    return true;
  }

  bool showAd() {
    debugPrint('Tentando exibir interstitial: isAdLoaded=$isAdLoaded');
    if (canShowAd()) {
      interstitialAd!.show();
      debugPrint('Interstitial exibido');
      lastAdShownTime = DateTime.now();
      interstitialAd = null;
      loadInterstitialAd(); // Pré-carrega o próximo
      return true;
    }
    debugPrint('Falha ao exibir interstitial');
    return false;
  }

  void dispose() {
    interstitialAd?.dispose();
  }
}
