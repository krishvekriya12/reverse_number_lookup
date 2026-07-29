import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.language, color: AppColors.primary),
            title: Text('Language', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text('English', style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ),
          Divider(color: AppColors.card),
          ListTile(
            leading: Icon(Icons.shield_outlined, color: AppColors.primary),
            title: Text('Caller ID Overlay', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: Text('Enabled', style: TextStyle(color: AppColors.textSecondary)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
