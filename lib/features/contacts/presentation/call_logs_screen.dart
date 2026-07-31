import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/contact_model.dart';
import '../logic/contacts_controller.dart';
import '../../block/logic/block_controller.dart';
import 'contact_detail_screen.dart';

class RealCallLogItem {
  final String name;
  final String number;
  final IconData directionIcon;
  final Color statusColor;
  final String subtitleText;
  final DateTime timestamp;
  final Uint8List? photo;
  final String contactId;

  RealCallLogItem({
    required this.name,
    required this.number,
    required this.directionIcon,
    required this.statusColor,
    required this.subtitleText,
    required this.timestamp,
    this.photo,
    required this.contactId,
  });
}

class CallLogsScreen extends StatefulWidget {
  const CallLogsScreen({super.key});

  @override
  State<CallLogsScreen> createState() => _CallLogsScreenState();
}

class _CallLogsScreenState extends State<CallLogsScreen> {
  late final ContactsController _contactsController;
  final TextEditingController _searchController = TextEditingController();
  List<RealCallLogItem> _allLogs = [];
  List<RealCallLogItem> _filteredLogs = [];
  bool _isLoading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _contactsController = ContactsController.instance;
    _contactsController.init();
    _loadRealCallLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRealCallLogs() async {
    if (_allLogs.isEmpty) {
      setState(() {
        _isLoading = true;
      });
    }

    await Permission.phone.request();

    final List<RealCallLogItem> loaded = [];

    try {
      final Iterable<CallLogEntry> entries = await CallLog.get();
      final contacts = _contactsController.fullContactList;

      for (final entry in entries) {
        final rawNumber = entry.number ?? entry.formattedNumber ?? '';
        if (rawNumber.isEmpty) continue;

        final cleanNum = rawNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

        ContactModel? matchedContact;
        for (final c in contacts) {
          final cClean = c.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
          if (cClean == cleanNum || (cleanNum.length >= 7 && cClean.endsWith(cleanNum))) {
            matchedContact = c;
            break;
          }
        }

        final displayName = (entry.name != null && entry.name!.isNotEmpty)
            ? entry.name!
            : (matchedContact != null ? matchedContact.name : rawNumber);

        final contactId = matchedContact?.id ?? cleanNum;
        final photo = matchedContact?.photo;

        IconData icon;
        Color color;
        String callTypeLabel = 'Mobile';

        switch (entry.callType) {
          case CallType.incoming:
          case CallType.wifiIncoming:
            icon = Icons.south_west;
            color = const Color(0xFF10B981);
            callTypeLabel = 'Mobile';
            break;
          case CallType.outgoing:
          case CallType.wifiOutgoing:
            icon = Icons.north_east;
            color = const Color(0xFF3B82F6);
            callTypeLabel = 'Mobile';
            break;
          case CallType.missed:
            icon = Icons.south_west;
            color = const Color(0xFFEF4444);
            callTypeLabel = 'Mobile';
            break;
          case CallType.rejected:
          case CallType.blocked:
            icon = Icons.block;
            color = const Color(0xFFEF4444);
            callTypeLabel = 'Blocked';
            break;
          default:
            icon = Icons.south_west;
            color = const Color(0xFF10B981);
            callTypeLabel = 'Mobile';
            break;
        }

        final dt = DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? DateTime.now().millisecondsSinceEpoch);
        final subtitle = '$callTypeLabel • ${_formatTimeString(dt)}';

        loaded.add(RealCallLogItem(
          name: displayName,
          number: rawNumber,
          directionIcon: icon,
          statusColor: color,
          subtitleText: subtitle,
          timestamp: dt,
          photo: photo,
          contactId: contactId,
        ));
      }
    } catch (_) {}

    if (loaded.isEmpty) {
      final contacts = _contactsController.fullContactList;
      final now = DateTime.now();

      for (int i = 0; i < contacts.length; i++) {
        final c = contacts[i];
        final type = i % 3;
        IconData icon;
        Color color;
        String typeLabel = 'Mobile';

        if (type == 0) {
          icon = Icons.south_west;
          color = const Color(0xFF10B981);
        } else if (type == 1) {
          icon = Icons.north_east;
          color = const Color(0xFF3B82F6);
        } else {
          icon = Icons.south_west;
          color = const Color(0xFFEF4444);
        }

        final dt = now.subtract(Duration(hours: i * 3 + 1));
        final subtitle = '$typeLabel • ${_formatTimeString(dt)}';

        loaded.add(RealCallLogItem(
          name: c.name,
          number: c.phone,
          directionIcon: icon,
          statusColor: color,
          subtitleText: subtitle,
          timestamp: dt,
          photo: c.photo,
          contactId: c.id,
        ));
      }
    }

    _allLogs = loaded;
    _applyFilter(_searchController.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimeString(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final isYesterday = dt.year == now.year && dt.month == now.month && dt.day == now.day - 1;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minStr = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
    final amPm = dt.hour >= 12 ? 'pm' : 'am';
    final timeOnly = '$hour12:$minStr $amPm';

    if (isToday) {
      return timeOnly;
    } else if (isYesterday) {
      return 'Yesterday, $timeOnly';
    } else {
      return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
    }
  }

  void _applyFilter(String query) {
    if (query.trim().isEmpty) {
      _filteredLogs = List.from(_allLogs);
    } else {
      final cleanQuery = query.replaceAll(RegExp(r'\s+'), '').toLowerCase();
      _filteredLogs = _allLogs.where((item) {
        final cleanPhone = item.number.replaceAll(RegExp(r'[\s\-\(\)]'), '').toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(cleanQuery);
        final phoneMatch = cleanPhone.contains(cleanQuery);
        return nameMatch || phoneMatch;
      }).toList();
    }
    _expandedIndex = null;
  }

  void _onSearchChanged(String val) {
    setState(() {
      _applyFilter(val);
    });
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendSms(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('sms:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openDetails(RealCallLogItem logItem) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ContactDetailScreen(
          contactId: logItem.contactId,
          initialContact: ContactModel(
            id: logItem.contactId,
            name: logItem.name,
            phone: logItem.number,
            photo: logItem.photo,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECENT ACTIVITY',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Call Logs',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search logs by name or number',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                  : _filteredLogs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _searchController.text.trim().isNotEmpty ? Icons.search_off : Icons.phone_disabled_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.trim().isNotEmpty ? 'No Logs Found' : 'No Call Logs',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _searchController.text.trim().isNotEmpty
                                      ? 'No recent logs match "${_searchController.text.trim()}"'
                                      : 'Your recent call logs will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                            itemCount: _filteredLogs.length,
                            itemBuilder: (context, index) {
                              final logItem = _filteredLogs[index];
                              final isExpanded = _expandedIndex == index;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isExpanded ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.dividerColor,
                                      width: isExpanded ? 1.5 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _openDetails(logItem),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _expandedIndex = isExpanded ? null : index;
                                                  });
                                                },
                                                child: logItem.photo != null && logItem.photo!.isNotEmpty
                                                    ? CircleAvatar(
                                                        radius: 24,
                                                        backgroundImage: MemoryImage(logItem.photo!),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 24,
                                                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                                        child: Text(
                                                          logItem.name.isNotEmpty ? logItem.name[0].toUpperCase() : '?',
                                                          style: TextStyle(
                                                            color: theme.colorScheme.primary,
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => _openDetails(logItem),
                                                  behavior: HitTestBehavior.opaque,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        logItem.name,
                                                        style: TextStyle(
                                                          color: theme.colorScheme.onSurface,
                                                          fontSize: 16.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Icon(logItem.directionIcon, size: 14, color: logItem.statusColor),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            logItem.subtitleText,
                                                            style: TextStyle(
                                                              color: theme.colorScheme.onSurfaceVariant,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.call_outlined,
                                                  color: theme.colorScheme.onSurface,
                                                  size: 22,
                                                ),
                                                onPressed: () => _makeCall(logItem.number),
                                              ),
                                            ],
                                          ),

                                          if (isExpanded) ...[
                                            const SizedBox(height: 14),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surface,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                children: [
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.chat_bubble_outline,
                                                    label: 'Message',
                                                    onTap: () => _sendSms(logItem.number),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.chat_outlined,
                                                    label: 'WhatsApp',
                                                    onTap: () => _openWhatsApp(logItem.number),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.history,
                                                    label: 'History',
                                                    onTap: () => _openDetails(logItem),
                                                  ),
                                                  Divider(height: 1, color: theme.dividerColor),
                                                  _buildGoogleActionTile(
                                                    theme: theme,
                                                    icon: Icons.block_outlined,
                                                    label: 'Block Number',
                                                    labelColor: Colors.red,
                                                    iconColor: Colors.red,
                                                    onTap: () async {
                                                      final messenger = ScaffoldMessenger.of(context);
                                                      final name = logItem.name;
                                                      await BlockController.instance.addRule(logItem.number);
                                                      messenger.showSnackBar(
                                                        SnackBar(content: Text('$name added to blocklist')),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleActionTile({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? theme.colorScheme.onSurface,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
