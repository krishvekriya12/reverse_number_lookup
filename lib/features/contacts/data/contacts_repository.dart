import 'package:flutter_contacts/flutter_contacts.dart';
import 'contact_model.dart';

class ContactsRepository {
  Future<List<ContactModel>> fetchContacts() async {
    try {
      final bool permissionGranted = await FlutterContacts.requestPermission(readonly: true);
      if (!permissionGranted) {
        return [];
      }

      final List<Contact> rawContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final List<ContactModel> result = [];

      for (final contact in rawContacts) {
        if (contact.phones.isEmpty) {
          continue;
        }

        final primaryPhone = contact.phones.first.number;
        final allPhones = contact.phones.map((e) => e.number).toList();
        final emails = contact.emails.map((e) => e.address).toList();
        final companyName = contact.organizations.isNotEmpty ? contact.organizations.first.company : null;
        final jobTitleStr = contact.organizations.isNotEmpty ? contact.organizations.first.title : null;
        final addressStr = contact.addresses.isNotEmpty ? contact.addresses.first.address : null;

        final displayName = contact.displayName.trim().isNotEmpty
            ? contact.displayName.trim()
            : (contact.name.first.isNotEmpty
                ? '${contact.name.first} ${contact.name.last}'.trim()
                : 'Unknown');

        result.add(
          ContactModel(
            id: contact.id,
            name: displayName,
            phone: primaryPhone,
            photo: contact.photo ?? contact.thumbnail,
            emails: emails,
            company: companyName,
            jobTitle: jobTitleStr,
            address: addressStr,
            accountType: 'Phone',
            allNumbers: allPhones,
          ),
        );
      }

      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<ContactModel?> fetchContactById(String id) async {
    try {
      final Contact? contact = await FlutterContacts.getContact(id);
      if (contact == null) {
        return null;
      }

      final primaryPhone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
      final allPhones = contact.phones.map((e) => e.number).toList();
      final emails = contact.emails.map((e) => e.address).toList();
      final companyName = contact.organizations.isNotEmpty ? contact.organizations.first.company : null;
      final jobTitleStr = contact.organizations.isNotEmpty ? contact.organizations.first.title : null;
      final addressStr = contact.addresses.isNotEmpty ? contact.addresses.first.address : null;

      final displayName = contact.displayName.trim().isNotEmpty
          ? contact.displayName.trim()
          : 'Unknown';

      return ContactModel(
        id: contact.id,
        name: displayName,
        phone: primaryPhone,
        photo: contact.photo ?? contact.thumbnail,
        emails: emails,
        company: companyName,
        jobTitle: jobTitleStr,
        address: addressStr,
        accountType: 'Phone',
        allNumbers: allPhones,
      );
    } catch (_) {
      return null;
    }
  }
}
