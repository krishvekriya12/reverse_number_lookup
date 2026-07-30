import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
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
        : 'Unknown';

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
    if (isoCode.isEmpty) return 'Unknown';
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
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showActionFailedToast();
    }
  }

  Future<void> _sendSms(String number) async {
    final uri = Uri.parse('sms:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showActionFailedToast();
    }
  }

  Future<void> _saveContact(String name, String number) async {
    try {
      final status = await Permission.contacts.request();
      if (status.isGranted) {
        final newContact = Contact()
          ..name.first = name.isNotEmpty ? name : 'Unknown'
          ..phones = [Phone(number)];
        await FlutterContacts.insertContact(newContact);
        _showToast('Contact saved successfully!');
      } else {
        _showToast('Contacts permission denied');
      }
    } catch (_) {
      _showActionFailedToast();
    }
  }

  Future<void> _openWhatsApp(String number) async {
    final clean = number.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showActionFailedToast();
    }
  }

  void _showActionFailedToast() {
    _showToast('Action failed: App not found');
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
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  onPressed: _onBackPressed,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      _buildProfileImage(),

                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _displayName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _formattedPhone,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActionRow(),

                            const SizedBox(height: 20),

                            if (_tagsList.isNotEmpty) ...[
                              _buildCommunityTagsSection(),
                              const SizedBox(height: 20),
                            ],

                            Text(
                              'Country',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Text(
                                _countryName,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final theme = Theme.of(context);
    if (_firstImageUrl != null) {
      return GestureDetector(
        onTap: () => _showFullImage(_firstImageUrl!),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: _firstImageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
              errorWidget: (_, __, ___) => _buildAvatarFallback(),
            ),
          ),
        ),
      );
    }
    return _buildAvatarFallback();
  }

  Widget _buildAvatarFallback() {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.cardColor,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(Icons.person, size: 60, color: theme.colorScheme.primary),
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.call,
          label: 'Call',
          color: Colors.green,
          onTap: () => _makeCall(_formattedPhone),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'SMS',
          color: Colors.blue,
          onTap: () => _sendSms(_formattedPhone),
        ),
        _buildActionButton(
          icon: Icons.person_add,
          label: 'Save',
          color: Colors.orange,
          onTap: () => _saveContact(_displayName, _formattedPhone),
        ),
        _buildActionButton(
          icon: Icons.chat,
          label: 'WhatsApp',
          color: Colors.teal,
          onTap: () => _openWhatsApp(_formattedPhone),
        ),
      ],
    );
  }

  Widget _buildActionButton({
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

  Widget _buildCommunityTagsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Tags',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagsList
                .map((tag) => Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}