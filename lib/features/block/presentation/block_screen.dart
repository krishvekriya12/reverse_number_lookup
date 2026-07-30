import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../lookup/logic/caller_id_controller.dart';
import '../../lookup/presentation/activate_caller_id_screen.dart';
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
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = BlockController.instance;
    _callerIdController = CallerIdController.instance;
    _callerIdController.refresh();

    if (widget.initialNumber != null && widget.initialNumber!.isNotEmpty) {
      _controller.setChipIndex(0);
      _inputController.text = widget.initialNumber!;
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
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _onAddRule() async {
    final success = await _controller.addRule(_inputController.text);
    if (success) {
      _inputController.clear();
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rule saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DASHBOARD',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Block Numbers',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_callerIdController.isInitialized &&
                      _callerIdController.state != CallerIdState.healthy) ...[
                    _buildCallerIdCard(),
                    const SizedBox(height: 16),
                  ],

                  _buildCountersRow(),

                  const SizedBox(height: 20),

                  _buildFilterChips(),

                  const SizedBox(height: 14),

                  _buildAddRuleCard(),

                  const SizedBox(height: 14),

                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallerIdCard() {
    final theme = Theme.of(context);
    final isSetupRequired =
        _callerIdController.state == CallerIdState.setupRequired;

    final title =
        isSetupRequired ? 'Activate Caller ID' : 'Enable Caller ID';
    final desc = isSetupRequired
        ? 'Enable Caller ID pop-up overlay to identify spam & unknown callers in real-time.'
        : 'Caller ID is configured. Tap to enable it now.';
    final btnText = isSetupRequired ? 'ACTIVATE NOW' : 'ENABLE NOW';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              if (isSetupRequired) {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ActivateCallerIdScreen(),
                ));
                _callerIdController.refresh();
              } else {
                await _callerIdController.setEnabled(true);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caller ID enabled!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(btnText,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCountersRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlockListScreen(controller: _controller),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.shield,
                              color: theme.colorScheme.primary, size: 22),
                        ),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_controller.rulesCount} Active Rules',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View blocklist',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlockedCallsScreen(controller: _controller),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.call_end,
                              color: AppColors.error, size: 22),
                        ),
                        Icon(Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_controller.historyCount} Blocked Calls',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View blocked history',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final theme = Theme.of(context);
    final chips = ['Exact Number', 'Starts With', 'Country Code', 'Caller Name'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(chips.length, (index) {
          final isSelected = _controller.selectedChipIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                chips[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                ),
              ),
              onSelected: (_) {
                _inputController.clear();
                _controller.setChipIndex(index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddRuleCard() {
    final theme = Theme.of(context);
    final hasError = _controller.errorMessage != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _controller.infoTitle.toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: TextField(
              controller: _inputController,
              keyboardType: _controller.inputType,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_controller.maxLength),
              ],
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
              onChanged: (_) => _controller.clearError(),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onAddRule(),
              decoration: InputDecoration(
                hintText: _controller.hintText,
                hintStyle:
                    TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 18,
              child: Visibility(
                visible: hasError,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Text(
                  _controller.errorMessage ?? ' ',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _onAddRule,
              icon: const Icon(Icons.add_moderator, size: 20),
              label: const Text(
                'ADD TO BLOCKLIST',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.infoTitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.infoDesc,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}