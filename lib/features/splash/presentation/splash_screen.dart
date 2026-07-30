import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_assets.dart';
import '../logic/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onNavigateHome;

  const SplashScreen({super.key, required this.onNavigateHome});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initSplash(context, onNavigateNext: widget.onNavigateHome);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ValueListenableBuilder<SplashState>(
          valueListenable: _controller,
          builder: (context, state, _) {
            return Stack(
              children: [
                Center(
                  child: Lottie.asset(
                    AppAssets.splashAnimation,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                if (state == SplashState.noInternet)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        AppStrings.noInternet,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (state == SplashState.loadingAds)
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.loadingAds,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
