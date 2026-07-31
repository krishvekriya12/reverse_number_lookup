import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_controller.dart';
import '../../lookup/logic/caller_id_controller.dart';
import '../../lookup/presentation/activate_caller_id_screen.dart';
import 'language_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  late final CallerIdController _callerIdController;
  String _versionName = '1.0.0';
  String _selectedLanguageNative = 'English';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callerIdController = CallerIdController.instance;
    _callerIdController.refresh();
    _loadPackageInfo();
    _loadSavedLanguage();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _callerIdController.refresh();
      _loadSavedLanguage();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionName = info.version;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nativeName = prefs.getString('app_language_native') ?? 'English';
      if (mounted) {
        setState(() {
          _selectedLanguageNative = nativeName;
        });
      }
    } catch (_) {}
  }

  Future<void> _onToggleCallerId(bool value) async {
    if (value) {
      final isConfigured = await _callerIdController.isCallerIdFullyConfigured();
      if (!isConfigured) {
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ActivateCallerIdScreen(),
          ),
        );
        _callerIdController.refresh();
      } else {
        await _callerIdController.setEnabled(true);
        setState(() {});
      }
    } else {
      await _callerIdController.setEnabled(false);
      setState(() {});
    }
  }

  Future<void> _openUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out this app to find number details:\n\nhttps://play.google.com/store/apps/details?id=com.reversenumberlookup.app',
        subject: 'Reverse Number Lookup',
      );
    } catch (_) {}
  }

  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'apps4funinfotech@gmail.com',
      queryParameters: {
        'subject': 'Feedback for Reverse Number Lookup ($_versionName)',
        'body': 'Hello Support Team,\n\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          child: ListenableBuilder(
            listenable: Listenable.merge([_callerIdController, ThemeController.instance]),
            builder: (context, _) {
              final isCallerIdActive = _callerIdController.state == CallerIdState.healthy;
              final isDark = ThemeController.instance.isDark;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APP PREFERENCES',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildSectionHeader('GENERAL'),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Caller ID Protection',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isCallerIdActive,
                                activeTrackColor: theme.colorScheme.primary,
                                onChanged: _onToggleCallerId,
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 1, color: theme.dividerColor),
                        _buildClickableRow(
                          icon: Icons.language,
                          title: 'Change Language',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedLanguageNative,
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                              ),
                              const SizedBox(width: 7),
                              Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.onSurfaceVariant, size: 16),
                            ],
                          ),
                          onTap: () async {
                            final selectedNative = await Navigator.of(context).push<String>(
                              MaterialPageRoute(
                                builder: (_) => const LanguageScreen(),
                              ),
                            );
                            if (selectedNative != null && mounted) {
                              setState(() {
                                _selectedLanguageNative = selectedNative;
                              });
                            }
                          },
                        ),
                        Divider(height: 1, thickness: 1, color: theme.dividerColor),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          child: Row(
                            children: [
                              Icon(
                                isDark ? Icons.dark_mode : Icons.light_mode,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Dark Mode',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Switch(
                                value: isDark,
                                activeTrackColor: theme.colorScheme.primary,
                                onChanged: (val) {
                                  ThemeController.instance.setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionHeader('PRIVACY & SECURITY'),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildClickableRow(
                          icon: Icons.policy_outlined,
                          title: 'Privacy Policy',
                          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          onTap: () => _openUrl('https://reverse-number-lookup.web.app/privacy-policy.html'),
                        ),
                        Divider(height: 1, thickness: 1, color: theme.dividerColor),
                        _buildClickableRow(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          onTap: () => _openUrl('https://reverse-number-lookup.web.app/terms.html'),
                        ),
                      ],
                    ),
                  ),

                  _buildSectionHeader('SUPPORT'),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _buildClickableRow(
                          icon: Icons.share_outlined,
                          title: 'Share App',
                          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          onTap: _shareApp,
                        ),
                        Divider(height: 1, thickness: 1, color: theme.dividerColor),
                        _buildClickableRow(
                          icon: Icons.email_outlined,
                          title: 'Support / Feedback',
                          trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant, size: 20),
                          onTap: _sendFeedback,
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 32, bottom: 20),
                    child: Center(
                      child: Text(
                        'Version $_versionName',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildClickableRow({
    required IconData icon,
    required String title,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Icon(icon, size: 24, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}