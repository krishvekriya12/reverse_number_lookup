import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../block/logic/block_controller.dart';
import '../../contacts/logic/contacts_controller.dart';
import '../data/lookup_model.dart';

class LookupResultScreen extends StatefulWidget {
  final LookupResultModel result;
  const LookupResultScreen({super.key, required this.result});

  @override
  State<LookupResultScreen> createState() => _LookupResultScreenState();
}

class _LookupResultScreenState extends State<LookupResultScreen> {
  String? _firstImageUrl;
  List<String> _tagsList = [];
  late String _displayName;
  late String _formattedPhone;
  late String _countryName;

  @override
  void initState() {
    super.initState();

    _displayName = (widget.result.name?.trim().isNotEmpty == true)
        ? widget.result.name!.trim()
        : 'Unknown Caller';

    _formattedPhone = _formatToInternational(widget.result.phoneNumber);
    _countryName = _getLocalizedCountryName(widget.result.countryIso);

    _firstImageUrl = widget.result.images.isNotEmpty
        ? widget.result.images.first
        : null;

    _tagsList = _extractTagsList();

    if (_tagsList.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          InAppReview.instance.isAvailable().then((available) {
            if (available) InAppReview.instance.requestReview();
          });
        }
      });
    }
  }

  String _formatToInternational(String rawPhone) {
    try {
      final parsed = PhoneNumber.parse(rawPhone);
      return parsed.international;
    } catch (_) {
      return rawPhone;
    }
  }

  String _getLocalizedCountryName(String isoCode) {
    if (isoCode.isEmpty) return 'Unknown Country';
    try {
      final country = Country.tryParse(isoCode.toUpperCase());
      if (country != null) return country.name;
    } catch (_) {}
    return isoCode.toUpperCase();
  }

  List<String> _extractTagsList() {
    try {
      final rawJson = widget.result.rawJsonStr;
      if (rawJson == null || rawJson.isEmpty) return [];

      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final otherNames = data['otherNames'];
      if (otherNames == null || otherNames is! List) return [];

      final List<String> tags = [];
      for (final item in otherNames) {
        if (item is! Map) continue;
        final name = (item['name']?.toString() ?? '').trim();
        if (name.isEmpty) continue;
        final type = (item['type']?.toString() ?? '').trim();
        tags.add(type.isNotEmpty ? '$name ($type)' : name);
      }
      return tags;
    } catch (_) {
      return widget.result.tags;
    }
  }

  void _onBackPressed() {
    InterstitialAdManager.instance.showWithoutDialog(
      onFinished: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  Future<void> _makeCall(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d\+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showToast('Unable to place call');
    }
  }

  Future<void> _sendSms(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d\+]'), '');
    final uri = Uri.parse('sms:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showToast('Unable to open SMS app');
    }
  }

  Future<Uint8List?> _downloadPhotoBytes(String url) async {
    try {
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == HttpStatus.ok) {
        final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        return Uint8List.fromList(bytes);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveContact(String name, String number) async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        Uint8List? photoBytes;
        if (_firstImageUrl != null && _firstImageUrl!.isNotEmpty) {
          photoBytes = await _downloadPhotoBytes(_firstImageUrl!);
        }

        final newContact = Contact()
          ..name.first = name.isNotEmpty ? name : 'Unknown'
          ..phones = [Phone(number)];

        if (photoBytes != null) {
          newContact.photo = photoBytes;
        }

        await FlutterContacts.insertContact(newContact);
        await ContactsController.instance.init();
        _showToast('Contact saved to phonebook with photo!');
      } else {
        _showToast('Contacts permission denied');
      }
    } catch (_) {
      _showToast('Failed to save contact');
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showToast('WhatsApp not installed');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast('$label copied to clipboard');
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 60),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface, size: 20),
            onPressed: _onBackPressed,
          ),
          title: Text(
            'Caller Profile',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.copy_outlined, color: theme.colorScheme.primary, size: 20),
              onPressed: () => _copyToClipboard(_formattedPhone, 'Phone number'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
                      _buildProfileAvatar(theme),
                      const SizedBox(height: 16),
                      Text(
                        _displayName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formattedPhone,
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
                            Icon(Icons.verified_user, size: 14, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Identified Caller Result',
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
                      onTap: () => _makeCall(_formattedPhone),
                    ),
                    _buildQuickActionBtn(
                      theme: theme,
                      icon: Icons.message,
                      label: 'SMS',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _sendSms(_formattedPhone),
                    ),
                    _buildQuickActionBtn(
                      theme: theme,
                      icon: Icons.chat,
                      label: 'WhatsApp',
                      color: const Color(0xFF14B8A6),
                      onTap: () => _openWhatsApp(_formattedPhone),
                    ),
                    _buildQuickActionBtn(
                      theme: theme,
                      icon: Icons.person_add,
                      label: 'Save',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _saveContact(_displayName, _formattedPhone),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_tagsList.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'COMMUNITY TAGS & ALIASES',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tagsList.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 72,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.label_outlined, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'CALLER & NETWORK DETAILS',
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
                          _formattedPhone,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'International Format',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.copy_outlined, color: theme.colorScheme.primary, size: 19),
                          onPressed: () => _copyToClipboard(_formattedPhone, 'Phone number'),
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
                          child: const Icon(Icons.public, color: Color(0xFF10B981), size: 20),
                        ),
                        title: Text(
                          _countryName,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Country Origin & Region',
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
                          child: const Icon(Icons.cell_tower, color: Color(0xFFA855F7), size: 20),
                        ),
                        title: Text(
                          'Mobile Line Network',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'GSM / Telecom Carrier',
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
                    'SECURITY & ACTIONS',
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
                          'Share Caller Info',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        onTap: () {
                          _copyToClipboard('$_displayName: $_formattedPhone', 'Caller details');
                        },
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      ListTile(
                        leading: Icon(Icons.person_add_outlined, color: theme.colorScheme.primary, size: 22),
                        title: Text(
                          'Save to Phonebook',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        onTap: () => _saveContact(_displayName, _formattedPhone),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      ListTile(
                        leading: const Icon(Icons.block_outlined, color: Colors.red, size: 22),
                        title: const Text(
                          'Block This Number',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await BlockController.instance.addRule(_formattedPhone);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('$_displayName added to blocklist'),
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
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ThemeData theme) {
    if (_firstImageUrl != null && _firstImageUrl!.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showFullImage(_firstImageUrl!),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundImage: NetworkImage(_firstImageUrl!),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: CircleAvatar(
        radius: 54,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
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