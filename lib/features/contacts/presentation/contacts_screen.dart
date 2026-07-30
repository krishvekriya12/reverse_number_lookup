import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/contact_model.dart';
import '../logic/contacts_controller.dart';
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'contacts_fab_dialer',
        backgroundColor: theme.colorScheme.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DialerScreen(),
            ),
          );
        },
        child: const Icon(Icons.dialpad, color: Colors.white),
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

                          final uiStateList = _controller.toUiStateList(contacts);

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: uiStateList.length,
                            itemBuilder: (context, index) {
                              final item = uiStateList[index];
                              return _buildContactListItem(item);
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

  Widget _buildContactListItem(ContactUiState state) {
    final theme = Theme.of(context);
    final contact = state.contact;
    BorderRadius borderRadius;

    if (state.isSingle) {
      borderRadius = BorderRadius.circular(16);
    } else if (state.isFirst) {
      borderRadius = const BorderRadius.vertical(top: Radius.circular(16));
    } else if (state.isLast) {
      borderRadius = const BorderRadius.vertical(bottom: Radius.circular(16));
    } else {
      borderRadius = BorderRadius.zero;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: theme.cardColor,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          leading: contact.photo != null && contact.photo!.isNotEmpty
              ? CircleAvatar(
                  radius: 22,
                  backgroundImage: MemoryImage(contact.photo!),
                )
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
          title: Text(
            contact.name,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            contact.phone,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ContactDetailScreen(
                  contactId: contact.id,
                  initialContact: contact,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}