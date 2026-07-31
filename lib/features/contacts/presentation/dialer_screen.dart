import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../logic/contacts_controller.dart';
import 'contact_detail_screen.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  late final ContactsController _contactsController;
  final StringBuffer _currentNumber = StringBuffer();
  List<ContactModel> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _contactsController = ContactsController.instance;
    _filterContacts();
  }

  void _appendDigit(String digit) {
    setState(() {
      _currentNumber.write(digit);
      _filterContacts();
    });
  }

  void _backspace() {
    if (_currentNumber.isNotEmpty) {
      final str = _currentNumber.toString();
      _currentNumber.clear();
      _currentNumber.write(str.substring(0, str.length - 1));
      setState(() {
        _filterContacts();
      });
    }
  }

  void _clearAll() {
    setState(() {
      _currentNumber.clear();
      _filterContacts();
    });
  }

  void _filterContacts() {
    final query = _currentNumber.toString().trim();
    final all = _contactsController.fullContactList;
    if (query.isEmpty) {
      _filteredContacts = List.from(all);
    } else {
      final cleanQuery = query.replaceAll(RegExp(r'\s+'), '');
      _filteredContacts = all.where((c) {
        final cleanPhone = c.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').toLowerCase();
        final nameMatch = c.name.toLowerCase().contains(cleanQuery.toLowerCase());
        final phoneMatch = cleanPhone.contains(cleanQuery);
        return nameMatch || phoneMatch;
      }).toList();
    }
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberStr = _currentNumber.toString();
    final showActions = numberStr.isNotEmpty && _filteredContacts.isEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Keypad Dialer',
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: showActions
                  ? _buildActionButtonsContainer(numberStr)
                  : _buildContactsList(),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            numberStr,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (numberStr.isNotEmpty)
                          GestureDetector(
                            onTap: _backspace,
                            onLongPress: _clearAll,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.backspace_outlined, color: theme.colorScheme.primary, size: 24),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildKeypadGrid(),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _makeCall(numberStr),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final theme = Theme.of(context);
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Text(
          'No contacts found',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              onTap: () {
                setState(() {
                  _currentNumber.clear();
                  _currentNumber.write(contact.phone);
                  _filterContacts();
                });
              },
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                contact.name,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                contact.phone,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              trailing: IconButton(
                icon: Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContactDetailScreen(contactId: contact.id, initialContact: contact),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtonsContainer(String number) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_outlined, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              number,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary),
                  onPressed: () => _makeCall(number),
                  icon: const Icon(Icons.call, color: Colors.white, size: 18),
                  label: const Text('Call', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => _sendSms(number),
                  icon: const Icon(Icons.message, color: Colors.white, size: 18),
                  label: const Text('SMS', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () => _openWhatsApp(number),
                  icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadGrid() {
    final theme = Theme.of(context);
    final keys = [
      {'main': '1', 'sub': ''},
      {'main': '2', 'sub': 'ABC'},
      {'main': '3', 'sub': 'DEF'},
      {'main': '4', 'sub': 'GHI'},
      {'main': '5', 'sub': 'JKL'},
      {'main': '6', 'sub': 'MNO'},
      {'main': '7', 'sub': 'PQRS'},
      {'main': '8', 'sub': 'TUV'},
      {'main': '9', 'sub': 'WXYZ'},
      {'main': '*', 'sub': ''},
      {'main': '0', 'sub': '+'},
      {'main': '#', 'sub': ''},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 14,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final item = keys[index];
        final main = item['main']!;
        final sub = item['sub']!;

        return Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _appendDigit(main),
            onLongPress: main == '0' ? () => _appendDigit('+') : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    main,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
