import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinUtils {
  static const int _initialCoins = 10;
  static const int _rewardCoins = 5;
  static const String _prefKey = 'COINS';

  static int _coins = _initialCoins;
  static bool _initialized = false;

  static int get coinBalance => _coins;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasData = prefs.containsKey(_prefKey);

      if (!hasData) {
        await _saveObfuscatedCoins(prefs, _initialCoins);
        _coins = _initialCoins;
      } else {
        _coins = _getObfuscatedCoins(prefs);
      }

      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final result = await FirebaseAuth.instance.signInAnonymously();
        user = result.user;
      }

      if (user != null) {
        try {
          await user.getIdToken(true);
        } catch (_) {}
      }

      _initialized = true;
    } catch (_) {
      _coins = 0;
    }
  }

  static Future<bool> consumeCoin() async {
    if (_coins > 0) {
      _coins = _coins - 1;
      final prefs = await SharedPreferences.getInstance();
      await _saveObfuscatedCoins(prefs, _coins);
      return true;
    }
    return false;
  }

  static Future<bool> addRewardCoins() async {
    _coins = _coins + _rewardCoins;
    final prefs = await SharedPreferences.getInstance();
    await _saveObfuscatedCoins(prefs, _coins);
    return true;
  }

  static Future<String?> getFreshToken() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        final result = await FirebaseAuth.instance.signInAnonymously();
        user = result.user;
      }
      if (user == null) return null;
      final result = await user.getIdToken(false);
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveObfuscatedCoins(SharedPreferences prefs, int value) async {
    final stringVal = value.toString();
    final encoded = base64.encode(utf8.encode(stringVal));
    await prefs.setString(_prefKey, encoded);
  }

  static int _getObfuscatedCoins(SharedPreferences prefs) {
    final encoded = prefs.getString(_prefKey);
    if (encoded == null) return 0;
    try {
      final decoded = utf8.decode(base64.decode(encoded));
      return int.parse(decoded);
    } catch (_) {
      return 0;
    }
  }
}
