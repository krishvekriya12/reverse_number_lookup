import 'package:flutter/material.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../lookup/presentation/lookup_screen.dart';
import '../../contacts/presentation/contacts_screen.dart';
import '../../block/presentation/block_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  DateTime? _lastPressedTime;

  final List<Widget> _screens = const [
    LookupScreen(),
    ContactsScreen(),
    BlockScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
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
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                  bottomNavigationBar: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    color: theme.cardColor,
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: theme.cardColor,
                      selectedItemColor: theme.colorScheme.primary,
                      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.search),
                          label: 'Lookup',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.contacts),
                          label: 'Contacts',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.block),
                          label: 'Block',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
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
}