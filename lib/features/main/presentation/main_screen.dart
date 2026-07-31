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
                return Scaffold(
                  extendBody: true,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 108),
                          child: IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                        ),
                      ),
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
          color: (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.phone_in_talk_outlined,
            activeIcon: Icons.phone_in_talk,
            label: 'Logs',
            theme: theme,
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Contacts',
            theme: theme,
          ),
          _buildCenterLookupItem(theme),
          _buildNavItem(
            index: 3,
            icon: Icons.shield_outlined,
            activeIcon: Icons.shield,
            label: 'Block',
            theme: theme,
          ),
          _buildNavItem(
            index: 4,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
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
        duration: const Duration(milliseconds: 200),
        width: 62,
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: isSelected ? 0.2 : 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterLookupItem(ThemeData theme) {
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
              top: -18,
              child: Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: ThemeController.instance.isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              child: Text(
                'Lookup',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}