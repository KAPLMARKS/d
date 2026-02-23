import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      _controller.forward();
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), _navigateToOnboarding);
      }
    });
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const OnboardingScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        'assets/images/half_stones.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _fillAnimation,
                      builder: (context, child) {
                        return ClipRect(
                          clipper: _BottomUpClipper(_fillAnimation.value),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        'assets/images/half_stones.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.t('app_title').split(' ').take(2).join(' '),
                style: TextStyle(
                  fontFamily: 'Amstelvar',
                  fontSize: 48,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                  height: 52 / 48,
                  letterSpacing: -1.5,
                ),
              ),
              Text(
                l10n.t('app_title').split(' ').skip(2).join(' '),
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 52 / 48,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomUpClipper extends CustomClipper<Rect> {
  _BottomUpClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) {
    final top = size.height * (1.0 - progress);
    return Rect.fromLTRB(0, top, size.width, size.height);
  }

  @override
  bool shouldReclip(_BottomUpClipper oldClipper) =>
      oldClipper.progress != progress;
}
