import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/coin_utils.dart';
import 'lookup_model.dart';

class LookupRepository {
  final Dio _dio = Dio();
  static const String _historyKey = 'search_history_list';
  static const String _baseUrl = 'https://lookup.smartonsolution.in/';

  Future<int> getCoinBalance() async {
    await CoinUtils.initialize();
    return CoinUtils.coinBalance;
  }

  Future<void> addCoin(int amount) async {
    await CoinUtils.addRewardCoins();
  }

  Future<LookupResultModel> resolveManual(
    String rawNumber,
    String countryDialCode,
    String countryIso,
  ) async {
    String e164Phone;
    String nationalNumber;
    String finalCountryCode;
    String finalIso;

    try {
      final iso = IsoCode.values.firstWhere(
        (e) => e.name == countryIso.toUpperCase(),
        orElse: () => IsoCode.IN,
      );
      final parsed = PhoneNumber.parse(rawNumber, callerCountry: iso);
      e164Phone = parsed.international;
      nationalNumber = parsed.nsn;
      finalCountryCode = parsed.countryCode.toString();
      finalIso = parsed.isoCode.name;
    } catch (_) {
      final clean = rawNumber.replaceAll(RegExp(r'\D'), '');
      e164Phone = '+$countryDialCode$clean';
      nationalNumber = clean;
      finalCountryCode = countryDialCode;
      finalIso = countryIso;
    }

    await CoinUtils.consumeCoin();

    // 1. Priority 1: DB Cache First
    final cached = await getValidCache(e164Phone);
    if (cached != null && cached.isFound) {
      final isApiResult = !((cached.rawJsonStr ?? '').contains('"src":"contact"'));
      if (isApiResult) {
        await _updateHistoryTimestamp(cached);
        return cached;
      }
      return cached;
    }

    final apiResult = await _fetchFromRemote(e164Phone, finalCountryCode, nationalNumber, finalIso, true);
    if (apiResult != null && apiResult.isFound) {
      await saveToHistory(apiResult);
      return apiResult;
    }

    final contactMatch = await _resolveFromContacts(e164Phone, finalIso);
    if (contactMatch != null) {
      await saveToHistory(contactMatch);
      return contactMatch;
    }

    final unknown = LookupResultModel.fromUnknown(
      phone: e164Phone,
      countryIso: finalIso,
    );
    await saveToHistory(unknown);
    return unknown;
  }

  Future<LookupResultModel?> _fetchFromRemote(
    String phone,
    String code,
    String nationalNumber,
    String countryIso,
    bool isManual,
  ) async {
    try {
      final token = await CoinUtils.getFreshToken() ?? '';
      if (token.isEmpty) {
        return null;
      }

      final safeUrl = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';

      final response = await _dio.post(
        safeUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
        data: {
          'code': code,
          'number': nationalNumber,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data)
            : Map<String, dynamic>.from(response.data);

        if (body['status'] != true) {
          return null;
        }

        final result = LookupResultModel.fromApiResponse(
          json: body,
          phone: phone,
          countryCode: code,
          countryIso: countryIso,
          isManual: isManual,
        );

        if (!result.isFound) {
          return null;
        }

        return result;
      }
    } catch (_) {}
    return null;
  }

  Future<LookupResultModel?> _resolveFromContacts(
      String phone, String countryIso) async {
    try {
      if (await Permission.contacts.isGranted) {
        final contacts = await FlutterContacts.getContacts(
            withProperties: true, withPhoto: true);

        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
        final suffix = cleanPhone.length >= 7
            ? cleanPhone.substring(cleanPhone.length - 7)
            : cleanPhone;

        for (final c in contacts) {
          for (final p in c.phones) {
            final cleanP = p.number.replaceAll(RegExp(r'\D'), '');
            if (cleanP.length >= 7 &&
                (cleanP.endsWith(suffix) || cleanPhone.endsWith(cleanP.substring(cleanP.length - 7)))) {
              return LookupResultModel.fromContact(
                name: c.displayName,
                photoUri: c.photo != null ? base64Encode(c.photo!) : null,
                phone: phone,
                countryIso: countryIso,
              );
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<LookupResultModel?> getValidCache(String phone) async {
    final history = await getSearchHistory();
    for (final item in history) {
      if (item.phoneNumber == phone) return item;
    }
    return null;
  }

  Future<List<LookupResultModel>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> raw = prefs.getStringList(_historyKey) ?? [];
      final List<LookupResultModel> list = [];
      for (final item in raw) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            list.add(
                LookupResultModel.fromJson(Map<String, dynamic>.from(decoded)));
          }
        } catch (_) {}
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveToHistory(LookupResultModel item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      history.removeWhere((e) => e.phoneNumber == item.phoneNumber);
      history.insert(0, item);
      final encoded = history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, encoded);
    } catch (_) {}
  }

  Future<void> deleteMultipleEntries(List<String> phones) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getSearchHistory();
      history.removeWhere((e) => phones.contains(e.phoneNumber));
      final encoded = history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_historyKey, encoded);
    } catch (_) {}
  }

  Future<void> _updateHistoryTimestamp(LookupResultModel item) async {
    final updated = LookupResultModel(
      phoneNumber: item.phoneNumber,
      countryCode: item.countryCode,
      countryIso: item.countryIso,
      name: item.name,
      tags: item.tags,
      images: item.images,
      rawJsonStr: item.rawJsonStr,
      isFound: item.isFound,
      isManualSearch: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await saveToHistory(updated);
  }
}