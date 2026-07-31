import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../lookup/logic/caller_id_controller.dart';
import '../logic/block_controller.dart';
import 'block_list_screen.dart';
import 'block_history_screen.dart';

class BlockScreen extends StatefulWidget {
  final String? initialNumber;

  const BlockScreen({super.key, this.initialNumber});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> with WidgetsBindingObserver {
  late final BlockController _controller;
  late final CallerIdController _callerIdController;

  int _selectedOptionIndex = 0;
  final TextEditingController _numberInputController = TextEditingController();
  final TextEditingController _prefixInputController = TextEditingController();
  final TextEditingController _nameInputController = TextEditingController();

  String _selectedCountry = 'United States (+1)';
  String _selectedSpamCategory = 'Telemarketer & Sales';
  bool _blockUnknownNumbers = false;

  final List<String> _countriesList = const [
    'United States (+1)',
    'India (+91)',
    'United Kingdom (+44)',
    'Canada (+1)',
    'Australia (+61)',
    'Germany (+49)',
    'International / Any',
  ];

  final List<String> _spamCategoriesList = const [
    'Telemarketer & Sales',
    'Robocalls & Scams',
    'Financial Fraud & Debt Collector',
    'Spam SMS & Promotions',
    'High Risk Unknown Calls',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = BlockController.instance;
    _callerIdController = CallerIdController.instance;
    _callerIdController.refresh();

    if (widget.initialNumber != null && widget.initialNumber!.isNotEmpty) {
      _selectedOptionIndex = 0;
      _numberInputController.text = widget.initialNumber!;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _callerIdController.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _numberInputController.dispose();
    _prefixInputController.dispose();
    _nameInputController.dispose();
    super.dispose();
  }

  Future<void> _pickContactForBlock() async {
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null && contact.phones.isNotEmpty) {
        setState(() {
          _numberInputController.text = contact.phones.first.number;
        });
      }
    } catch (_) {}
  }

  Future<void> _onAddBlockRule() async {
    String input = '';
    if (_selectedOptionIndex == 0) {
      input = _numberInputController.text.trim();
    } else if (_selectedOptionIndex == 1) {
      input = _prefixInputController.text.trim();
    } else if (_selectedOptionIndex == 2) {
      input = _nameInputController.text.trim();
    } else if (_selectedOptionIndex == 3) {
      input = _selectedCountry;
    } else if (_selectedOptionIndex == 4) {
      input = _selectedSpamCategory;
    } else if (_selectedOptionIndex == 5) {
      input = 'Hidden/Unknown Numbers';
    }

    if (input.isEmpty && _selectedOptionIndex < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a number, prefix, or name to block'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _controller.setChipIndex(_selectedOptionIndex);
    final success = await _controller.addRule(input);

    if (!mounted) return;

    if (success) {
      _numberInputController.clear();
      _prefixInputController.clear();
      _nameInputController.clear();
      FocusScope.of(context).unfocus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$input" added to Blocklist successfully'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW RULES',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BlockListScreen(controller: _controller)),
              );
            },
          ),
        ),
      );
    } else {
      final msg = _controller.errorMessage ?? 'Failed to add block rule';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHowItWorksDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'How Blocking Works',
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Select your blocking method below. Any incoming call or SMS matching full numbers, series prefixes, spam categories, or hidden caller IDs will be automatically intercepted and rejected.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _callerIdController]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CALL PROTECTION',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add to Blocklist',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _showHowItWorksDialog,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.help_outline, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 5),
                              Text(
                                'How it works',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Blocking Method',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select an option below to block unwanted calls and messages.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildOptionCard0(theme),
                  const SizedBox(height: 12),
                  _buildOptionCard1(theme),
                  const SizedBox(height: 12),
                  _buildOptionCard2(theme),
                  const SizedBox(height: 12),
                  _buildOptionCard3(theme),
                  const SizedBox(height: 12),
                  _buildOptionCard4(theme),
                  const SizedBox(height: 12),
                  _buildOptionCard5(theme),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pro Protection Tip',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Calls from blocked numbers will be automatically rejected. You can manage active rules and view blocked call history anytime below.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                      ),
                      onPressed: _onAddBlockRule,
                      icon: const Icon(Icons.add_moderator, color: Colors.white, size: 22),
                      label: const Text(
                        'Add to Blocklist',
                        style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => BlockListScreen(controller: _controller)),
                            );
                          },
                          icon: Icon(Icons.list_alt, color: theme.colorScheme.primary, size: 18),
                          label: Text(
                            'Active Rules (${_controller.rules.length})',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => BlockedCallsScreen(controller: _controller)),
                            );
                          },
                          icon: Icon(Icons.history, color: theme.colorScheme.primary, size: 18),
                          label: Text(
                            'Blocked History',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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
    );
  }

  Widget _buildOptionCard0(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 0;
    return _buildCardBase(
      theme: theme,
      index: 0,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0EEFF),
        ),
        child: const Icon(Icons.phone_outlined, color: Color(0xFF0066FF), size: 22),
      ),
      title: 'Block Full Number',
      subtitle: 'Block any specific phone number.',
      child: isSelected
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: TextField(
                        controller: _numberInputController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.person_add_alt_1_outlined, color: theme.colorScheme.primary, size: 20),
                      onPressed: _pickContactForBlock,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard1(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 1;
    return _buildCardBase(
      theme: theme,
      index: 1,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE6F7ED),
        ),
        child: const Center(
          child: Text(
            '123',
            style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
      title: 'Block Series / Prefix',
      subtitle: 'Block numbers starting with certain digits.',
      child: isSelected
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _prefixInputController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Enter prefix (e.g. 9876, 140)',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Example: 9876* will block all numbers starting with 9876',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard2(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 2;
    return _buildCardBase(
      theme: theme,
      index: 2,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFF3E0),
        ),
        child: const Icon(Icons.person_search_outlined, color: Color(0xFFF97316), size: 22),
      ),
      title: 'Block by Name',
      subtitle: 'Block calls from numbers saved with a specific name.',
      child: isSelected
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _nameInputController,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter name (e.g. Telemarketer, Insurance)',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard3(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 3;
    return _buildCardBase(
      theme: theme,
      index: 3,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF3E8FF),
        ),
        child: const Icon(Icons.public_outlined, color: Color(0xFFA855F7), size: 22),
      ),
      title: 'Block by Country',
      subtitle: 'Block calls from unwanted countries.',
      child: isSelected
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.5),
                    items: _countriesList.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCountry = val);
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard4(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 4;
    return _buildCardBase(
      theme: theme,
      index: 4,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFEE2E2),
        ),
        child: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 22),
      ),
      title: 'Block Spam Category',
      subtitle: 'Block numbers identified as spam or scam.',
      child: isSelected
          ? Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSpamCategory,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14.5),
                    items: _spamCategoriesList.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSpamCategory = val);
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOptionCard5(ThemeData theme) {
    final isSelected = _selectedOptionIndex == 5;
    return _buildCardBase(
      theme: theme,
      index: 5,
      isSelected: isSelected,
      iconBadge: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0F2FE),
        ),
        child: const Center(
          child: Text(
            '#',
            style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
      title: 'Block Hidden or Unknown Numbers',
      subtitle: 'Block all calls from hidden or unknown numbers.',
      trailingWidget: Switch(
        value: _blockUnknownNumbers,
        activeTrackColor: theme.colorScheme.primary,
        onChanged: (val) {
          setState(() {
            _selectedOptionIndex = 5;
            _blockUnknownNumbers = val;
          });
        },
      ),
    );
  }

  Widget _buildCardBase({
    required ThemeData theme,
    required int index,
    required bool isSelected,
    required Widget iconBadge,
    required String title,
    required String subtitle,
    Widget? trailingWidget,
    Widget? child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedOptionIndex = index;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    iconBadge,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailingWidget ??
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              width: isSelected ? 6.5 : 1.5,
                            ),
                          ),
                        ),
                  ],
                ),
                if (child != null) child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}