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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Searching Directory...',
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REVERSE NUMBER LOOKUP',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search Directory',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Identify unknown callers, phone numbers and spam scores in real-time.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_callerIdController.isInitialized &&
                      _callerIdController.state != CallerIdState.healthy)
                    _buildCallerIdCard(),

                  const SizedBox(height: 14),

                  if (_controller.isInitialized && _controller.coinBalance == 0)
                    _buildNoCoinCard()
                  else
                    _buildSearchCard(),

                  const SizedBox(height: 24),

                  _buildRecentActivityHeader(),
                  const SizedBox(height: 12),

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
    final isSetupRequired =
        _callerIdController.state == CallerIdState.setupRequired;

    final title = isSetupRequired ? 'Activate Caller ID' : 'Enable Caller ID';
    final desc = isSetupRequired
        ? 'Enable Caller ID pop-up overlay to identify spam & unknown callers in real-time.'
        : 'Caller ID is configured. Tap to enable it now.';
    final btnText = isSetupRequired ? 'ACTIVATE NOW' : 'ENABLE NOW';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052FF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052FF).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
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
              foregroundColor: const Color(0xFF0052FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              btnText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Lottie.asset(
            AppAssets.coinAnimation,
            width: 64,
            height: 64,
            errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Colors.amber, size: 64),
          ),
          const SizedBox(height: 12),
          Text(
            'Out of Coins!',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Watch a short ad to earn 5 free lookup coins.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _controller.rewardUserWithCoins(),
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            label: const Text('WATCH AD (+5 COINS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
        ),
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
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    Lottie.asset(
                      AppAssets.coinAnimation,
                      width: 22,
                      height: 22,
                      errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_controller.coinBalance} Coins',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                    borderRadius: BorderRadius.circular(14),
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
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurfaceVariant, size: 20),
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
                    onSubmitted: (_) => _controller.searchNumber(_inputController.text),
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      suffixIcon: _inputController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant, size: 18),
                              onPressed: () {
                                _inputController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 6),
            Text(
              _controller.errorMessage ?? '',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _controller.searchNumber(_inputController.text),
              icon: const Icon(Icons.search, color: Colors.white, size: 22),
              label: const Text(
                'SEARCH NUMBER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
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
          'Recent Searches',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
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
            'VIEW ALL',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryCard() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No Recent Searches',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Numbers searched by you will be listed here.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13.5),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                item.phoneNumber,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13.5,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 22,
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => LookupResultScreen(result: item),
                ));
              },
            ),
          ),
        );
      },
    );
  }
}