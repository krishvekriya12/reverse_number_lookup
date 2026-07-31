import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/caller_id_controller.dart';

class ActivateCallerIdScreen extends StatefulWidget {
  const ActivateCallerIdScreen({super.key});

  @override
  State<ActivateCallerIdScreen> createState() => _ActivateCallerIdScreenState();
}

class _ActivateCallerIdScreenState extends State<ActivateCallerIdScreen> {
  final CallerIdController _controller = CallerIdController();

  bool _phoneContactGranted = false;
  bool _notificationGranted = false;
  bool _overlayGranted = false;

  @override
  void initState() {
    super.initState();
    _updateUIStates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateUIStates();
  }

  Future<void> _updateUIStates() async {
    final phoneContact = await _controller.isPhoneContactGranted();
    final notification = await _controller.isNotificationGranted();
    final overlay = await _controller.isOverlayGranted();

    if (mounted) {
      setState(() {
        _phoneContactGranted = phoneContact;
        _notificationGranted = notification;
        _overlayGranted = overlay;
      });
    }

    await _checkCompletion();
  }

  Future<void> _checkCompletion() async {
    final isHealthy = await _controller.isCallerIdFullyConfigured();
    if (isHealthy) {
      await _controller.setEnabled(true);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _requestPhoneContacts() async {
    await _controller.requestPhoneContacts();
    await _updateUIStates();
  }

  Future<void> _requestNotifications() async {
    await _controller.requestNotifications();
    await _updateUIStates();
  }

  Future<void> _requestOverlay() async {
    final status = await Permission.systemAlertWindow.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    await _updateUIStates();
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
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Activate Caller ID',
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, theme.colorScheme.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Caller ID Setup',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Grant the permissions below to enable real-time Caller ID identification.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'REQUIRED PERMISSIONS',
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2),
            ),

            const SizedBox(height: 12),

            _buildPermissionCard(
              icon: Icons.contacts_outlined,
              title: 'Phone & Contacts',
              description:
                  'Required to identify unknown callers and match with your contacts.',
              isGranted: _phoneContactGranted,
              onGrant: _requestPhoneContacts,
            ),

            const SizedBox(height: 10),

            _buildPermissionCard(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              description:
                  'Required to show caller info during incoming calls.',
              isGranted: _notificationGranted,
              onGrant: _requestNotifications,
            ),

            const SizedBox(height: 10),

            _buildPermissionCard(
              icon: Icons.picture_in_picture_outlined,
              title: 'Display Over Other Apps',
              description:
                  'Required to show the caller ID overlay on top of the call screen.',
              isGranted: _overlayGranted,
              onGrant: _requestOverlay,
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All permissions are required for Caller ID to function. '
                      'Your data stays private and is never shared.',
                      style:
                          TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
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

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onGrant,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGranted
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isGranted
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isGranted ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isGranted)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Granted',
                style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton(
              onPressed: onGrant,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('GRANT'),
            ),
        ],
      ),
    );
  }
}
