import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  final SharedPreferences _prefs;

  PrefService(this._prefs);

  static const String _keyCoins = 'key_user_coins';
  static const String _keyThemeMode = 'key_theme_mode';
  static const String _keyLanguageCode = 'key_language_code';
  static const String _keySplashAdShow = 'key_splash_ad_show';
  static const String _keyAppOpenShow = 'key_app_open_show';

  // --- Coins Management ---
  int get userCoins => _prefs.getInt(_keyCoins) ?? 5; // Default 5 free coins

  Future<bool> setCoins(int coins) async {
    return await _prefs.setInt(_keyCoins, coins);
  }

  Future<bool> addCoins(int amount) async {
    return await setCoins(userCoins + amount);
  }

  Future<bool> deductCoin() async {
    final current = userCoins;
    if (current > 0) {
      return await setCoins(current - 1);
    }
    return false;
  }

  // --- Theme Mode ---
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';

  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_keyThemeMode, mode);
  }

  // --- Language Configuration ---
  String get languageCode => _prefs.getString(_keyLanguageCode) ?? 'en';

  Future<bool> setLanguageCode(String code) async {
    return await _prefs.setString(_keyLanguageCode, code);
  }

  // --- Remote Config Ad Flags ---
  bool get splashInterstitialShow => _prefs.getBool(_keySplashAdShow) ?? true;
  bool get appOpenShow => _prefs.getBool(_keyAppOpenShow) ?? true;

  Future<void> saveAdConfigs({required bool splashAd, required bool appOpen}) async {
    await _prefs.setBool(_keySplashAdShow, splashAd);
    await _prefs.setBool(_keyAppOpenShow, appOpen);
  }
}
