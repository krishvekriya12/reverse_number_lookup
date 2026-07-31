import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';

class ContactDetailScreen extends StatefulWidget {
  final String contactId;
  final ContactModel? initialContact;

  const ContactDetailScreen({
    super.key,
    required this.contactId,
    this.initialContact,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late final ContactsRepository _repository;
  ContactModel? _contact;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = ContactsRepository();
    if (widget.initialContact != null) {
      _contact = widget.initialContact;
      _isLoading = false;
    } else {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final fetched = await _repository.fetchContactById(widget.contactId);
    if (mounted) {
      setState(() {
        _contact = fetched ?? widget.initialContact;
        _isLoading = false;
      });
    }
  }

  String _sanitizePhone(String raw) {
    final trimmed = raw.trim();
    final plus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    return plus ? '+$digits' : digits;
  }

  Future<void> _makeCall(String phone) async {
    final sanitized = _sanitizePhone(phone);
    if (sanitized.isEmpty) return;
    final uri = Uri.parse('tel:$sanitized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    final sanitized = _sanitizePhone(phone);
    if (sanitized.isEmpty) return;
    final uri = Uri.parse('sms:$sanitized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final sanitized = _sanitizePhone(phone);
    if (sanitized.isEmpty) return;
    final digitsOnly = sanitized.replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$digitsOnly');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _editContact() async {
    if (_contact == null) return;
    try {
      final nativeContact = await FlutterContacts.getContact(_contact!.id);
      if (nativeContact != null) {
        await FlutterContacts.openExternalEdit(nativeContact.id);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          _contact?.name ?? 'Contact Details',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _contact == null
              ? Center(
                  child: Text(
                    'Contact details unavailable',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      Center(
                        child: _contact!.photo != null && _contact!.photo!.isNotEmpty
                            ? CircleAvatar(
                                radius: 48,
                                backgroundImage: MemoryImage(_contact!.photo!),
                              )
                            : Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.cardColor,
                                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 56,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _contact!.name,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickAction(
                            icon: Icons.call,
                            label: 'Call',
                            color: Colors.green,
                            onTap: () => _makeCall(_contact!.phone),
                          ),
                          _buildQuickAction(
                            icon: Icons.message,
                            label: 'SMS',
                            color: Colors.blue,
                            onTap: () => _sendSms(_contact!.phone),
                          ),
                          _buildQuickAction(
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: Colors.teal,
                            onTap: () => _openWhatsApp(_contact!.phone),
                          ),
                          _buildQuickAction(
                            icon: Icons.edit,
                            label: 'Edit',
                            color: theme.colorScheme.primary,
                            onTap: _editContact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: theme.colorScheme.primary, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _contact!.phone,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mobile',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
