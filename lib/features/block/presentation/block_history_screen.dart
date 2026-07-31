import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../logic/block_controller.dart';

class BlockedCallsScreen extends StatefulWidget {
  final BlockController controller;

  const BlockedCallsScreen({super.key, required this.controller});

  @override
  State<BlockedCallsScreen> createState() => _BlockedCallsScreenState();
}

class _BlockedCallsScreenState extends State<BlockedCallsScreen> {
  void _onBackPressed() {
    if (widget.controller.history.isNotEmpty) {
      InterstitialAdManager.instance.showWithoutDialog(
        onFinished: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear History?',
          style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all blocked calls history?',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('CLEAR ALL', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.controller.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blocked history cleared')),
        );
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year} at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final history = widget.controller.history;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _onBackPressed();
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: _onBackPressed,
              ),
              title: Text(
                'Blocked Calls (${history.length})',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                if (history.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep, color: AppColors.error),
                    onPressed: _showClearHistoryDialog,
                  ),
              ],
            ),
            body: history.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final title = item.name ?? item.blockedNumber;
                      final subtitle = item.name != null ? item.blockedNumber : null;
                      final reason = item.reason ?? 'Blocked by rule';
                      final timeStr = _formatTimestamp(item.timestamp);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: theme.cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.error.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.call_end,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle != null) ...[
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                ],
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        reason,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_end_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Blocked Calls Yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calls intercepted and blocked by your active rules will appear here.',
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
}
