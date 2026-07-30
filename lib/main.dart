import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_controller.dart';
import 'core/constants/app_strings.dart';
import 'core/utils/coin_utils.dart';
import 'features/lookup/logic/lookup_controller.dart';
import 'features/lookup/logic/caller_id_controller.dart';
import 'features/block/logic/block_controller.dart';
import 'features/contacts/logic/contacts_controller.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/main/presentation/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCMdyfZygpNR40vV47JFs6L3xqg_D8xgbM',
          appId: '1:165975715562:android:a4cf39bb8c1bd72185b193',
          messagingSenderId: '165975715562',
          projectId: 'reverse-number-lookup-5bc84',
          storageBucket: 'reverse-number-lookup-5bc84.firebasestorage.app',
        ),
      );
    } catch (_) {}
  }

  await ThemeController.instance.init();
  await CoinUtils.initialize();
  await LookupController.instance.init();
  await CallerIdController.instance.refresh();
  await BlockController.instance.init();
  await ContactsController.instance.init();

  runApp(const ReverseNumberLookupApp());
}

class ReverseNumberLookupApp extends StatelessWidget {
  const ReverseNumberLookupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeController.instance.themeMode,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Builder(
            builder: (childContext) {
              return SplashScreen(
                onNavigateHome: () {
                  Navigator.of(childContext).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}