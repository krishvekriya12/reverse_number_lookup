import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/ads/interstitial_ad_manager.dart';

enum SplashState { initial, noInternet, loadingAds, completed }

class SplashController extends ValueNotifier<SplashState> {
  SplashController() : super(SplashState.initial);

  bool splashInterstitialShow = true;
  bool _hasNavigated = false;

  Future<void> initSplash(BuildContext context,
      {required VoidCallback onNavigateNext}) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      value = SplashState.noInternet;
      return;
    }

    try {
      await ConsentService.instance.gatherConsent((error) async {
        try {
          if (InterstitialAdManager.adsEnabled) {
            await MobileAds.instance.initialize();
            InterstitialAdManager.instance.preloadAd();
          }
        } catch (_) {}
        await _executeSplashFlow(onNavigateNext);
      });
    } catch (_) {
      await _executeSplashFlow(onNavigateNext);
    }
  }

  Future<void> _executeSplashFlow(VoidCallback onNavigateNext) async {
    if (_hasNavigated) return;

    if (!splashInterstitialShow || !InterstitialAdManager.adsEnabled) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _navigateOnce(onNavigateNext);
      return;
    }

    value = SplashState.loadingAds;
    await Future.delayed(const Duration(seconds: 2));

    try {
      await InterstitialAdManager.instance.showWithoutDialog(
        onFinished: () {
          _navigateOnce(onNavigateNext);
        },
      );
    } catch (_) {
      _navigateOnce(onNavigateNext);
    }
  }

  void _navigateOnce(VoidCallback onNavigateNext) {
    if (!_hasNavigated) {
      _hasNavigated = true;
      value = SplashState.completed;
      onNavigateNext();
    }
  }
}
