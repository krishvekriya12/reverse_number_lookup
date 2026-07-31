import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../lookup/presentation/lookup_screen.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../contacts/presentation/call_logs_screen.dart';
import '../../block/presentation/block_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 2});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  DateTime? _lastPressedTime;

  final List<Widget> _screens = const [
    CallLogsScreen(),
    ContactsScreen(),
    LookupScreen(),
    BlockScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 2) {
      setState(() {
        _currentIndex = 2;
      });
      return false;
    }

    final now = DateTime.now();
    if (_lastPressedTime == null || now.difference(_lastPressedTime!) > const Duration(seconds: 2)) {
      _lastPressedTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        final currentTheme = isDark ? AppThemes.darkTheme : AppThemes.lightTheme;

        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: AnimatedTheme(
            data: currentTheme,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: Builder(
              builder: (animatedContext) {
                final theme = Theme.of(animatedContext);
                final isKeyboardOpen = MediaQuery.of(animatedContext).viewInsets.bottom > 0;

                return Scaffold(
                  resizeToAvoidBottomInset: false,
                  extendBody: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isKeyboardOpen ? 0 : 108),
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                        ),
                      ),
                      if (!isKeyboardOpen)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.transparent,
                            child: _buildFloatingBottomBar(theme),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBottomBar(ThemeData theme) {
    final isDark = ThemeController.instance.isDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      height: 76,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.history_toggle_off_rounded,
            activeIcon: Icons.history_rounded,
            label: 'Logs',
            theme: theme,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.contacts_outlined,
            activeIcon: Icons.contacts_rounded,
            label: 'Contacts',
            theme: theme,
          ),
          _buildCenterLookupItem(theme),
          _buildNavItem(
            index: 3,
            icon: Icons.shield_outlined,
            activeIcon: Icons.shield_rounded,
            label: 'Block',
            theme: theme,
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.tune_rounded,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        width: 62,
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.12 : 1.0,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterLookupItem(ThemeData theme) {
    final isSelected = _currentIndex == 2;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
      },
      child: SizedBox(
        width: 68,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -20,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                scale: isSelected ? 1.08 : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: isSelected ? 0.4 : 0.2),
                        blurRadius: isSelected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
                child: const Text('Lookup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}