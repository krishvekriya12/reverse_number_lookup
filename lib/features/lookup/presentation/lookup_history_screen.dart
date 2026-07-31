import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../logic/lookup_controller.dart';
import 'lookup_result_screen.dart';

class LookupHistoryScreen extends StatefulWidget {
  final LookupController controller;

  const LookupHistoryScreen({super.key, required this.controller});

  @override
  State<LookupHistoryScreen> createState() => _LookupHistoryScreenState();
}

class _LookupHistoryScreenState extends State<LookupHistoryScreen> {
  final Set<String> _selectedPhones = {};

  bool get _isSelectionMode => _selectedPhones.isNotEmpty;

  void _toggleSelection(String phone) {
    setState(() {
      if (_selectedPhones.contains(phone)) {
        _selectedPhones.remove(phone);
      } else {
        _selectedPhones.add(phone);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedPhones.clear();
    });
  }

  Future<void> _showDeleteDialog() async {
    final theme = Theme.of(context);
    final count = _selectedPhones.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Selected?', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete $count selected history ${count == 1 ? 'item' : 'items'}?',
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
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final listToDelete = _selectedPhones.toList();
      _exitSelectionMode();
      await widget.controller.deleteMultipleEntries(listToDelete);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final history = widget.controller.history
            .where((e) => e.isManualSearch)
            .toList();

        return PopScope(
          canPop: !_isSelectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_isSelectionMode) {
              _exitSelectionMode();
            }
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back, color: theme.colorScheme.onSurface),
                onPressed: () {
                  if (_isSelectionMode) {
                    _exitSelectionMode();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                _isSelectionMode
                    ? '${_selectedPhones.length} selected'
                    : 'Recent Activity',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                if (_isSelectionMode)
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: _showDeleteDialog,
                  ),
              ],
            ),
            body: Stack(
              children: [
                if (history.isEmpty)
                  _buildEmptyState()
                else
                  ListView.builder(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: _isSelectionMode ? 80 : 16,
                    ),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isSelected = _selectedPhones.contains(item.phoneNumber);
                      final initials = (item.name?.isNotEmpty == true)
                          ? item.name![0].toUpperCase()
                          : '?';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.2)
                            : theme.cardColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  activeColor: theme.colorScheme.primary,
                                  onChanged: (_) => _toggleSelection(item.phoneNumber),
                                )
                              : CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    initials,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                          title: Text(
                            item.name ?? 'Unknown Caller',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            item.phoneNumber,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          onLongPress: () {
                            _toggleSelection(item.phoneNumber);
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(item.phoneNumber);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LookupResultScreen(result: item),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),

                if (_isSelectionMode)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _showDeleteDialog,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'DELETE SELECTED (${_selectedPhones.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
              ],
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
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off,
                size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'No Recent Activity Yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your search history will appear here once you start looking up numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
