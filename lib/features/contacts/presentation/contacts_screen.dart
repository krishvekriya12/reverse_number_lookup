import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../logic/contacts_controller.dart';
import '../../block/logic/block_controller.dart';
import 'contact_detail_screen.dart';
import 'dialer_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with WidgetsBindingObserver {
  late final ContactsController _controller;
  final TextEditingController _searchController = TextEditingController();
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ContactsController.instance;
    _controller.init();
    _searchController.text = _controller.currentQuery;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
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

  void _openDetails(ContactModel contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(
          contactId: contact.id,
          initialContact: contact,
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permission Required',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Contacts permission is required to display your saved contacts list in the app.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Go to Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 0),
        child: FloatingActionButton(
          heroTag: 'contacts_dialer_fab',
          backgroundColor: theme.colorScheme.primary,
          elevation: 6,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DialerScreen(),
              ),
            );
          },
          child: const Icon(
            Icons.dialpad,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
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
                    'ADDRESS BOOK',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Contacts',
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
                      onChanged: (val) {
                        _expandedIndex = null;
                        _controller.onSearchQueryChanged(val);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or number',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _expandedIndex = null;
                                  _controller.onSearchQueryChanged('');
                                  setState(() {});
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
                valueListenable: _controller.loadingNotifier,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.colorScheme.primary),
                    );
                  }

                  return ValueListenableBuilder<bool>(
                    valueListenable: _controller.permissionDeniedNotifier,
                    builder: (context, isDenied, _) {
                      if (isDenied) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Card(
                              color: theme.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: theme.dividerColor),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.contacts_outlined,
                                      size: 56,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Contacts Permission Needed',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Allow access to your contacts to view and search them directly inside the app.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _showPermissionDialog,
                                      child: const Text(
                                        'Grant Permission',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ValueListenableBuilder<List<ContactModel>>(
                        valueListenable: _controller.contactsNotifier,
                        builder: (context, contacts, _) {
                          if (contacts.isEmpty) {
                            final isSearching = _searchController.text.trim().isNotEmpty;
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSearching ? Icons.search_off : Icons.contacts_outlined,
                                      size: 64,
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isSearching ? 'No Contacts Found' : 'No Contacts Yet',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isSearching
                                          ? 'No contacts match "${_searchController.text.trim()}"'
                                          : 'Your saved device contacts will be listed here.',
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
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              final isExpanded = _expandedIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isExpanded ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.dividerColor,
                                      width: isExpanded ? 1.5 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openDetails(contact),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _expandedIndex = isExpanded ? null : index;
                                                  });
                                                },
                                                child: contact.photo != null && contact.photo!.isNotEmpty
                                                    ? CircleAvatar(
                                                        radius: 24,
                                                        backgroundImage: MemoryImage(contact.photo!),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 24,
                                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                                        child: Text(
                                                          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                                          style: TextStyle(
                                                            color: theme.colorScheme.primary,
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => _openDetails(contact),
                                                  behavior: HitTestBehavior.opaque,
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
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.call_outlined,
                                                  color: theme.colorScheme.onSurface,
                                                  size: 22,
                                                ),
                                                onPressed: () => _makeCall(contact.phone),
                                              ),
                                            ],
                                          ),

                                          if (isExpanded) ...[
                                            const SizedBox(height: 14),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                children: [
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.chat_bubble_outline,
                                                    label: 'Message',
                                                    onTap: () => _sendSms(contact.phone),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.chat_outlined,
                                                    label: 'WhatsApp',
                                                    onTap: () => _openWhatsApp(contact.phone),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.history,
                                                    label: 'History',
                                                    onTap: () => _openDetails(contact),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.block_outlined,
                                                    label: 'Block Number',
                                                    labelColor: Colors.red,
                                                    iconColor: Colors.red,
                                                    onTap: () async {
                                                      final messenger = ScaffoldMessenger.of(context);
                                                      final name = contact.name;
                                                      await BlockController.instance.addRule(contact.phone);
                                                      messenger.showSnackBar(
                                                        SnackBar(content: Text('$name added to blocklist')),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
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

  Widget _buildGoogleActionTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? theme.colorScheme.onSurface,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}