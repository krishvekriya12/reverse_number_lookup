import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../logic/contacts_controller.dart';
import 'contact_detail_screen.dart';

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  late final ContactsController _contactsController;
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _contactsController = ContactsController.instance;
    _contactsController.init();
    _filterContacts('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    final all = _contactsController.fullContactList;
    if (query.trim().isEmpty) {
      _filteredContacts = List.from(all);
    } else {
      final cleanQuery = query.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      _filteredContacts = all.where((c) {
        final cleanPhone = c.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '').toLowerCase();
        final nameMatch = c.name.toLowerCase().contains(cleanQuery);
        final phoneMatch = cleanPhone.contains(cleanQuery);
        return nameMatch || phoneMatch;
      }).toList();
    }
    setState(() {});
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

  void _showOptionsModal(ContactModel contact) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.call, color: Colors.green),
                title: Text('Call ${contact.name}', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  _makeCall(contact.phone);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: Text('Send SMS', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  _sendSms(contact.phone);
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: theme.colorScheme.primary),
                title: Text('View Contact Details', style: TextStyle(color: theme.colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContactDetailScreen(
                        contactId: contact.id,
                        initialContact: contact,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Call Logs',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                      onChanged: _filterContacts,
                      decoration: InputDecoration(
                        hintText: 'Search logs by name or number',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterContacts('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _contactsController.loadingNotifier,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.colorScheme.primary),
                    );
                  }

                  if (_filteredContacts.isEmpty) {
                    final isSearching = _searchController.text.trim().isNotEmpty;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSearching ? Icons.search_off : Icons.phone_disabled_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isSearching ? 'No Logs Found' : 'No Call Logs',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSearching
                                  ? 'No recent logs match "${_searchController.text.trim()}"'
                                  : 'Your recent call logs will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final callType = index % 3;
                      IconData directionIcon;
                      Color statusColor;
                      String statusText;
                      String timeStr;

                      if (callType == 0) {
                        directionIcon = Icons.south_west;
                        statusColor = const Color(0xFF10B981);
                        statusText = 'Incoming';
                        timeStr = '${10 + (index % 3)}:${(index * 13) % 60 < 10 ? '0' : ''}${(index * 13) % 60} AM';
                      } else if (callType == 1) {
                        directionIcon = Icons.north_east;
                        statusColor = const Color(0xFF3B82F6);
                        statusText = 'Outgoing';
                        timeStr = '${1 + (index % 4)}:${(index * 17) % 60 < 10 ? '0' : ''}${(index * 17) % 60} PM';
                      } else {
                        directionIcon = Icons.south_west;
                        statusColor = const Color(0xFFEF4444);
                        statusText = 'Missed';
                        timeStr = 'Yesterday';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _makeCall(contact.phone),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                              child: Row(
                                children: [
                                  contact.photo != null && contact.photo!.isNotEmpty
                                      ? CircleAvatar(
                                          radius: 26,
                                          backgroundImage: MemoryImage(contact.photo!),
                                        )
                                      : CircleAvatar(
                                          radius: 26,
                                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                          child: Icon(
                                            Icons.person,
                                            color: theme.colorScheme.primary,
                                            size: 28,
                                          ),
                                        ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          contact.name,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          contact.phone,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(directionIcon, size: 14, color: statusColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              statusText,
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '  •  $timeStr',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurfaceVariant,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ContactDetailScreen(
                                            contactId: contact.id,
                                            initialContact: contact,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF0066FF),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: theme.colorScheme.primary,
                                              border: Border.all(color: theme.cardColor, width: 1.5),
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                      size: 20,
                                    ),
                                    onPressed: () => _showOptionsModal(contact),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
