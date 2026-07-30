import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  static final InterstitialAdManager instance = InterstitialAdManager._internal();
  InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  final String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  void preloadAd() {
    if (_isLoading || _interstitialAd != null) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          debugPrint('InterstitialAd loaded successfully.');
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isLoading = false;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  Future<void> showWithoutDialog({required VoidCallback onFinished}) async {
    if (_interstitialAd == null) {
      debugPrint('Ad not ready yet, proceeding next.');
      onFinished();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadAd();
        onFinished();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onFinished();
      },
    );

    await _interstitialAd!.show();
  }
}