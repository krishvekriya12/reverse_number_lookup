import 'dart:convert';

class LookupResultModel {
  final String phoneNumber;
  final String countryCode;
  final String countryIso;
  final String? name;
  final List<String> tags;
  final List<String> images;
  final String? rawJsonStr;
  final bool isFound;
  final bool isManualSearch;
  final int timestamp;

  LookupResultModel({
    required this.phoneNumber,
    required this.countryCode,
    required this.countryIso,
    this.name,
    required this.tags,
    required this.images,
    this.rawJsonStr,
    required this.isFound,
    required this.isManualSearch,
    required this.timestamp,
  });

  factory LookupResultModel.fromApiResponse({
    required Map<String, dynamic> json,
    required String phone,
    required String countryCode,
    required String countryIso,
    required bool isManual,
  }) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : <String, dynamic>{};
    final fullName = (data['fullName']?.toString() ?? '').trim();

    final List<String> tagList = [];
    if (data['otherNames'] is List) {
      for (final item in data['otherNames']) {
        if (item is Map && item['name'] != null) {
          final n = item['name'].toString().trim();
          if (n.isNotEmpty) tagList.add(n);
        }
      }
    }

    final Set<String> urlSet = {};
    if (data['facebookID'] is Map && data['facebookID']['profileURL'] != null) {
      final url = data['facebookID']['profileURL'].toString();
      if (url.startsWith('http')) urlSet.add(url);
    }

    if (data['images'] is List) {
      for (final img in data['images']) {
        if (img is Map && img['pictures'] is Map) {
          final pics = img['pictures'] as Map;
          final url = (pics['600'] ?? pics['200'] ?? '').toString();
          if (url.startsWith('http')) urlSet.add(url);
        }
      }
    }

    return LookupResultModel(
      phoneNumber: phone,
      countryCode: countryCode,
      countryIso: countryIso,
      name: fullName.isNotEmpty ? fullName : null,
      tags: tagList,
      images: urlSet.toList(),
      rawJsonStr: jsonEncode(data),
      isFound: fullName.isNotEmpty || tagList.isNotEmpty,
      isManualSearch: isManual,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory LookupResultModel.fromContact({
    required String name,
    String? photoUri,
    required String phone,
    required String countryIso,
  }) {
    return LookupResultModel(
      phoneNumber: phone,
      countryCode: '',
      countryIso: countryIso,
      name: name,
      tags: [],
      images: photoUri != null && photoUri.isNotEmpty ? [photoUri] : [],
      rawJsonStr: jsonEncode({'fullName': name, 'src': 'contact'}),
      isFound: true,
      isManualSearch: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory LookupResultModel.fromUnknown({
    required String phone,
    required String countryIso,
  }) {
    return LookupResultModel(
      phoneNumber: phone,
      countryCode: '',
      countryIso: countryIso,
      name: null,
      tags: [],
      images: [],
      rawJsonStr: jsonEncode({'fullName': ''}),
      isFound: false,
      isManualSearch: false,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory LookupResultModel.fromJson(Map<String, dynamic> json) {
    int parseTimestamp(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? DateTime.now().millisecondsSinceEpoch;
      return DateTime.now().millisecondsSinceEpoch;
    }

    return LookupResultModel(
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      countryIso: json['countryIso']?.toString() ?? '',
      name: json['name']?.toString(),
      tags: json['tags'] is List ? List<String>.from((json['tags'] as List).map((e) => e.toString())) : [],
      images: json['images'] is List ? List<String>.from((json['images'] as List).map((e) => e.toString())) : [],
      rawJsonStr: json['rawJsonStr']?.toString(),
      isFound: json['isFound'] == true || json['isFound'] == 'true',
      isManualSearch: json['isManualSearch'] == true || json['isManualSearch'] == 'true',
      timestamp: parseTimestamp(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'countryIso': countryIso,
      'name': name,
      'tags': tags,
      'images': images,
      'rawJsonStr': rawJsonStr,
      'isFound': isFound,
      'isManualSearch': isManualSearch,
      'timestamp': timestamp,
    };
  }
}