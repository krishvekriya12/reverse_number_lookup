import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../logic/block_controller.dart';

class BlockListScreen extends StatefulWidget {
  final BlockController controller;

  const BlockListScreen({super.key, required this.controller});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  void _onBackPressed() {
    if (widget.controller.rules.isNotEmpty) {
      InterstitialAdManager.instance.showWithoutDialog(
        onFinished: () {
          if (mounted) Navigator.of(context).pop();
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  IconData _getRuleIcon(int ruleType) {
    switch (ruleType) {
      case 0:
        return Icons.phone_disabled;
      case 1:
        return Icons.format_list_numbered;
      case 2:
        return Icons.flag_outlined;
      case 3:
        return Icons.person_off_outlined;
      default:
        return Icons.block;
    }
  }

  Color _getBadgeColor(BuildContext context, int ruleType) {
    final theme = Theme.of(context);
    switch (ruleType) {
      case 0:
        return theme.colorScheme.primary;
      case 1:
        return Colors.orangeAccent;
      case 2:
        return Colors.greenAccent;
      case 3:
        return Colors.purpleAccent;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final rules = widget.controller.rules;

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
                'Active Block Rules (${rules.length})',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: rules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rules.length,
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      final badgeColor = _getBadgeColor(context, rule.ruleType);

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
                            backgroundColor: badgeColor.withValues(alpha: 0.15),
                            child: Icon(
                              _getRuleIcon(rule.ruleType),
                              color: badgeColor,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            rule.ruleValue,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rule.ruleTypeName,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 22),
                            onPressed: () {
                              widget.controller.deleteRule(rule.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rule deleted'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
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
            Icon(Icons.shield_outlined,
                size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Active Block Rules',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Added spam block rules will be listed here.',
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
