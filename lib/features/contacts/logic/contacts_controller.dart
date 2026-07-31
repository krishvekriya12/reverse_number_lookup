import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';

class ContactsController extends ChangeNotifier {
  static final ContactsController instance = ContactsController._internal();

  ContactsController._internal();

  final ContactsRepository _repository = ContactsRepository();

  final ValueNotifier<List<ContactModel>> contactsNotifier = ValueNotifier<List<ContactModel>>([]);
  final ValueNotifier<bool> loadingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> permissionDeniedNotifier = ValueNotifier<bool>(false);

  List<ContactModel> _fullContactList = [];
  Timer? _debounceTimer;
  String _currentQuery = '';

  List<ContactModel> get fullContactList => _fullContactList;
  String get currentQuery => _currentQuery;

  Future<void> init() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await loadContacts();
    }
  }

  Future<void> loadContacts() async {
    loadingNotifier.value = true;
    permissionDeniedNotifier.value = false;

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      loadingNotifier.value = false;
      permissionDeniedNotifier.value = true;
      contactsNotifier.value = [];
      _fullContactList = [];
      return;
    }

    _fullContactList = await _repository.fetchContacts();
    loadingNotifier.value = false;
    performSearch(_currentQuery, debounceMs: 0);
  }

  void onSearchQueryChanged(String query) {
    _currentQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      performSearch(query, debounceMs: 0);
    });
  }

  void performSearch(String query, {int debounceMs = 0}) {
    _currentQuery = query;

    if (_fullContactList.isEmpty) {
      contactsNotifier.value = [];
      return;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      contactsNotifier.value = List.from(_fullContactList);
      return;
    }

    final normalizedQuery = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    final filtered = _fullContactList.where((contact) {
      final nameMatch = contact.name.toLowerCase().contains(normalizedQuery);
      final cleanedPhone = contact.phone.replaceAll(RegExp(r'[\s\-]'), '').toLowerCase();
      final phoneMatch = cleanedPhone.contains(normalizedQuery);
      return nameMatch || phoneMatch;
    }).toList();

    contactsNotifier.value = filtered;
  }

  List<ContactUiState> toUiStateList(List<ContactModel> list) {
    final size = list.length;
    return list.asMap().entries.map((entry) {
      final index = entry.key;
      final contact = entry.value;
      return ContactUiState(
        contact: contact,
        isFirst: index == 0,
        isLast: index == size - 1,
        isSingle: size == 1,
      );
    }).toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    contactsNotifier.dispose();
    loadingNotifier.dispose();
    permissionDeniedNotifier.dispose();
    super.dispose();
  }
}
