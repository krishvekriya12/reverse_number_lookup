import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BlockScreen extends StatelessWidget {
  const BlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Blocking'),
      ),
      body: const Center(
        child: Text(
          'Block List & Spam Protection',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }
}
