import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../data/lookup_model.dart';
import '../logic/lookup_controller.dart';
import '../logic/caller_id_controller.dart';
import 'lookup_result_screen.dart';
import 'activate_caller_id_screen.dart';
import 'lookup_history_screen.dart';

class LookupScreen extends StatefulWidget {
  const LookupScreen({super.key});

  @override
  State<LookupScreen> createState() => _LookupScreenState();
}

class _LookupScreenState extends State<LookupScreen> with WidgetsBindingObserver {
  late final LookupController _controller;
  late final CallerIdController _callerIdController;
  final TextEditingController _inputController = TextEditingController();
  bool _isLoadingShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LookupController.instance;
    _callerIdController = CallerIdController.instance;
    _callerIdController.refresh();
    _controller.addListener(_onControllerChange);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _callerIdController.refresh();
    }
  }

  void _onControllerChange() {
    if (!mounted) return;

    switch (_controller.status) {
      case LookupStatus.loading:
        _showLoadingDialog(true);
        break;

      case LookupStatus.success:
        _showLoadingDialog(false);
        if (_controller.lastResult != null) {
          final result = _controller.lastResult!;
          _controller.status = LookupStatus.initial;
          _inputController.clear();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LookupResultScreen(result: result),
            ),
          );
        }
        break;

      case LookupStatus.error:
        _showLoadingDialog(false);
        break;

      case LookupStatus.outOfCoins:
        _showLoadingDialog(false);
        break;

      case LookupStatus.initial:
        break;
    }
  }

  void _showLoadingDialog(bool show) {
    final theme = Theme.of(context);
    if (show && !_isLoadingShowing) {
      _isLoadingShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Searching...',
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ).then((_) {
        _isLoadingShowing = false;
      });
    } else if (!show && _isLoadingShowing) {
      _isLoadingShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _callerIdController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _callerIdController]),
      builder: (context, _) {
        final recentHistory = _controller.history
            .where((e) => e.isManualSearch)
            .take(5)
            .toList();

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
                    'Reverse Number Lookup',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_callerIdController.isInitialized &&
                      _callerIdController.state != CallerIdState.healthy)
                    _buildCallerIdCard(),

                  const SizedBox(height: 12),

                  if (_controller.isInitialized && _controller.coinBalance == 0)
                    _buildNoCoinCard()
                  else
                    _buildSearchCard(),

                  const SizedBox(height: 20),

                  _buildRecentActivityHeader(),
                  const SizedBox(height: 8),

                  if (!_controller.isInitialized)
                    const SizedBox(height: 100)
                  else if (recentHistory.isEmpty)
                    _buildEmptyHistoryCard()
                  else
                    _buildHistoryList(recentHistory),
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

  Widget _buildNoCoinCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Lottie.asset(
            AppAssets.coinAnimation,
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.monetization_on, color: Colors.amber, size: 60),
          ),
          const SizedBox(height: 10),
          Text(
            'Out of Coins!',
            style: TextStyle(
                color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Watch a short ad to earn 5 free lookup coins.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _controller.rewardUserWithCoins(),
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('WATCH AD (+5 COINS)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENTER PHONE NUMBER',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Lottie.asset(
                      AppAssets.coinAnimation,
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.coinBalance}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: true,
                    onSelect: (Country country) {
                      _controller.updateCountry(
                          country.phoneCode, country.countryCode, country.name);
                    },
                  );
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${_controller.selectedCountryCode}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            fontSize: 15),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurfaceVariant, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                    onChanged: (_) => _controller.clearError(),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) =>
                        _controller.searchNumber(_inputController.text),
                    decoration: InputDecoration(
                      hintText: 'Phone number',
                      hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 14),
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
                        borderSide: BorderSide(
                            color: theme.colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                    ),
                  ),
                ),
              ),
            ],
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
              onPressed: () =>
                  _controller.searchNumber(_inputController.text),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('SEARCH NUMBER',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LookupHistoryScreen(controller: _controller),
              ),
            );
          },
          child: Text(
            'VIEW HISTORY',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history,
              size: 40, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            'No Recent Activity Yet',
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Searched numbers will appear here',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<LookupResultModel> history) {
    final theme = Theme.of(context);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final initials = (item.name?.isNotEmpty == true)
            ? item.name![0].toUpperCase()
            : '?';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: theme.cardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(initials,
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            title: Text(
              item.name ?? 'Unknown Caller',
              style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
            subtitle: Text(
              item.phoneNumber,
              style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            trailing: Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6), size: 20),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LookupResultScreen(result: item),
              ));
            },
          ),
        );
      },
    );
  }
}