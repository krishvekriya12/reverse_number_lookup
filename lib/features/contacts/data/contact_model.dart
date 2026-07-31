import 'dart:typed_data';

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final Uint8List? photo;
  final List<String> emails;
  final String? company;
  final String? jobTitle;
  final String? address;
  final String? accountType;
  final DateTime? lastUpdated;
  final List<String> allNumbers;

  ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photo,
    this.emails = const [],
    this.company,
    this.jobTitle,
    this.address,
    this.accountType,
    this.lastUpdated,
    this.allNumbers = const [],
  });

  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    Uint8List? photo,
    List<String>? emails,
    String? company,
    String? jobTitle,
    String? address,
    String? accountType,
    DateTime? lastUpdated,
    List<String>? allNumbers,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      emails: emails ?? this.emails,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      address: address ?? this.address,
      accountType: accountType ?? this.accountType,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      allNumbers: allNumbers ?? this.allNumbers,
    );
  }
}

class ContactUiState {
  final ContactModel contact;
  final bool isFirst;
  final bool isLast;
  final bool isSingle;

  ContactUiState({
    required this.contact,
    required this.isFirst,
    required this.isLast,
    required this.isSingle,
  });
}
