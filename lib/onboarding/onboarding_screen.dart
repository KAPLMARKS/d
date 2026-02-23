import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../paywall/paywall_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const PaywallScreen(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);
    final pages = [
      _OnboardingPageData(
        image: 'assets/images/onboarding1.png',
        italicText: l10n.t('onboarding_1_italic'),
        boldText: l10n.t('onboarding_1_bold'),
      ),
      _OnboardingPageData(
        image: 'assets/images/onboarding2.png',
        italicText: l10n.t('onboarding_2_italic'),
        boldText: l10n.t('onboarding_2_bold'),
      ),
      _OnboardingPageData(
        image: 'assets/images/onboarding3.png',
        italicText: l10n.t('onboarding_3_italic'),
        boldText: l10n.t('onboarding_3_bold'),
      ),
      _OnboardingPageData(
        image: 'assets/images/onboarding4.png',
        italicText: l10n.t('onboarding_4_italic'),
        boldText: l10n.t('onboarding_4_bold'),
        buttonLabel: l10n.t('start_now'),
      ),
    ];

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _OnboardingPage(data: pages[i]),
              ),
            ),
            _PageIndicator(
              count: pages.length,
              current: _currentPage,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 16),
              child: _NextButton(
                label: pages[_currentPage].buttonLabel ?? l10n.t('next'),
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.image,
    required this.italicText,
    required this.boldText,
    this.buttonLabel,
  });

  final String image;
  final String italicText;
  final String boldText;
  final String? buttonLabel;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Image.asset(
            data.image,
            height: 256,
            width: 256,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            data.italicText,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            data.boldText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'FunnelDisplay',
              fontSize: 48,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 52 / 48,
              letterSpacing: -1.5,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final isActive = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
            width: isActive ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF111111)
                  : const Color(0xFFF6F7FA),
              borderRadius: BorderRadius.circular(100),
            ),
          );
        }),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0x14F6F7FA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
