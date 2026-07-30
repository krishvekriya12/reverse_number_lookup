import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../data/lookup_model.dart';
import '../data/lookup_repository.dart';
import '../../../core/utils/coin_utils.dart';

enum LookupStatus { initial, loading, success, error, outOfCoins }

class LookupController extends ChangeNotifier {
  static final LookupController instance = LookupController();
  final LookupRepository _repository = LookupRepository();

  LookupStatus status = LookupStatus.initial;
  String selectedCountryCode = '91';
  String selectedCountryIso = 'IN';
  String selectedCountryName = 'India';
  int coinBalance = 10;
  LookupResultModel? lastResult;
  List<LookupResultModel> history = [];
  String? errorMessage;
  bool isInitialized = false;

  int _lastClickMs = 0;

  Future<void> init() async {
    await CoinUtils.initialize();
    coinBalance = CoinUtils.coinBalance;
    history = await _repository.getSearchHistory();
    isInitialized = true;
    notifyListeners();
  }

  void updateCountry(String dialCode, String isoCode, String name) {
    selectedCountryCode = dialCode;
    selectedCountryIso = isoCode;
    selectedCountryName = name;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage != null) {
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> searchNumber(String rawNumber) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastClickMs < 250) return;
    _lastClickMs = now;

    final phone = rawNumber.trim();

    clearError();

    if (phone.isEmpty) {
      errorMessage = 'Please enter a phone number';
      status = LookupStatus.error;
      notifyListeners();
      return;
    }

    try {
      final parsed = PhoneNumber.parse(
        phone,
        callerCountry: IsoCode.values.firstWhere(
          (e) => e.name == selectedCountryIso.toUpperCase(),
          orElse: () => IsoCode.IN,
        ),
      );

      if (!parsed.isValid()) {
        errorMessage = 'Invalid number format for $selectedCountryName';
        status = LookupStatus.error;
        notifyListeners();
        return;
      }
    } catch (_) {
      errorMessage = 'Invalid phone number';
      status = LookupStatus.error;
      notifyListeners();
      return;
    }

    if (CoinUtils.coinBalance <= 0) {
      status = LookupStatus.outOfCoins;
      notifyListeners();
      return;
    }

    final contactsStatus = await Permission.contacts.request();
    if (contactsStatus.isPermanentlyDenied) {
      errorMessage =
          'Contacts permission denied. Go to Settings to enable.';
      status = LookupStatus.error;
      notifyListeners();
      return;
    }

    status = LookupStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.resolveManual(
        phone,
        selectedCountryCode,
        selectedCountryIso,
      );
      coinBalance = CoinUtils.coinBalance;
      history = await _repository.getSearchHistory();
      lastResult = result;
      status = LookupStatus.success;
    } catch (e) {
      errorMessage = 'Search failed. Please try again.';
      status = LookupStatus.error;
    }
    notifyListeners();
  }

  Future<void> rewardUserWithCoins() async {
    await CoinUtils.addRewardCoins();
    coinBalance = CoinUtils.coinBalance;
    status = LookupStatus.initial;
    notifyListeners();
  }

  Future<void> deleteMultipleEntries(List<String> phones) async {
    await _repository.deleteMultipleEntries(phones);
    history = await _repository.getSearchHistory();
    notifyListeners();
  }
}