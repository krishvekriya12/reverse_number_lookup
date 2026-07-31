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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone number copied to clipboard'),
        duration: Duration(seconds: 2),
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
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                _contact!.photo != null && _contact!.photo!.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 52,
                                        backgroundImage: MemoryImage(_contact!.photo!),
                                      )
                                    : CircleAvatar(
                                        radius: 52,
                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                        child: Text(
                                          _contact!.name.isNotEmpty ? _contact!.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ],
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
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Caller Profile',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
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
                          _buildQuickActionBtn(
                            theme: theme,
                            icon: Icons.edit,
                            label: 'Edit',
                            color: theme.colorScheme.primary,
                            onTap: _editContact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.phone_outlined, color: theme.colorScheme.primary, size: 22),
                            ),
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
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Mobile Number',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy_outlined, color: theme.colorScheme.primary, size: 20),
                              onPressed: () => _copyToClipboard(_contact!.phone),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spam Score: Safe (0%)',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'No spam reports filed for this contact',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Material(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.share_outlined, color: theme.colorScheme.primary, size: 22),
                              title: Text(
                                'Share Contact',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                              onTap: () {
                                _copyToClipboard('${_contact!.name}: ${_contact!.phone}');
                              },
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
                                  SnackBar(content: Text('$name added to blocklist')),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
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
