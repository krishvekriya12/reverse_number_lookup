import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';
import '../../block/logic/block_controller.dart';

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
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
          'Contact Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 22),
            onPressed: _editContact,
          ),
        ],
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
                              ),
                              child: _contact!.photo != null && _contact!.photo!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 54,
                                      backgroundImage: MemoryImage(_contact!.photo!),
                                    )
                                  : CircleAvatar(
                                      radius: 54,
                                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      child: Text(
                                        _contact!.name.isNotEmpty ? _contact!.name[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 42,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _contact!.name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _contact!.phone,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.contacts, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Saved Phone Contact',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildQuickActionBtn(
                            theme: theme,
                            icon: Icons.call,
                            label: 'Call',
                            color: const Color(0xFF10B981),
                            onTap: () => _makeCall(_contact!.phone),
                          ),
                          _buildQuickActionBtn(
                            theme: theme,
                            icon: Icons.message,
                            label: 'SMS',
                            color: const Color(0xFF3B82F6),
                            onTap: () => _sendSms(_contact!.phone),
                          ),
                          _buildQuickActionBtn(
                            theme: theme,
                            icon: Icons.chat,
                            label: 'WhatsApp',
                            color: const Color(0xFF14B8A6),
                            onTap: () => _openWhatsApp(_contact!.phone),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'CONTACT INFORMATION',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                      Material(
                        color: theme.cardColor,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.phone_outlined, color: theme.colorScheme.primary, size: 20),
                              ),
                              title: Text(
                                _contact!.phone,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Mobile  •  Default Number',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.copy_outlined, color: theme.colorScheme.primary, size: 19),
                                onPressed: () => _copyToClipboard(_contact!.phone, 'Phone number'),
                              ),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.cell_tower, color: Color(0xFF10B981), size: 20),
                              ),
                              title: Text(
                                'Network & Location',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'GSM Mobile Network  •  Active Line',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.sim_card_outlined, color: Color(0xFFA855F7), size: 20),
                              ),
                              title: Text(
                                'Storage Source',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Device Phonebook Storage',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'ACTIONS & OPTIONS',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),

                      Material(
                        color: theme.cardColor,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.share_outlined, color: theme.colorScheme.primary, size: 22),
                              title: Text(
                                'Share Contact Info',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                              onTap: () {
                                _copyToClipboard('${_contact!.name}: ${_contact!.phone}', 'Contact details');
                              },
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 22),
                              title: Text(
                                'Edit Contact Details',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                              onTap: _editContact,
                            ),
                            Divider(height: 1, color: theme.dividerColor),
                            ListTile(
                              leading: const Icon(Icons.block_outlined, color: Colors.red, size: 22),
                              title: const Text(
                                'Block Contact Number',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                              onTap: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final name = _contact!.name;
                                await BlockController.instance.addRule(_contact!.phone);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to blocklist'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuickActionBtn({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
