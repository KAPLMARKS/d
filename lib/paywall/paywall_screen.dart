import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/widgets/main_shell.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1;

  void _onNext() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final plans = [
      _PlanData(
        label: l10n.t('weekly'),
        price: '\$3.99',
        period: l10n.t('week'),
        accentColor: const Color(0xFFCBA7FF),
        badge: l10n.t('trial_3_days'),
        badgeBgColor: const Color(0x1ACBA7FF),
        badgeTextColor: const Color(0xFFCBA7FF),
      ),
      _PlanData(
        label: l10n.t('monthly'),
        price: '\$11.99',
        period: l10n.t('month'),
        accentColor: const Color(0xFF7ACBFF),
      ),
      _PlanData(
        label: l10n.t('yearly'),
        price: '\$49.99',
        period: l10n.t('year'),
        accentColor: const Color(0xFF77C97E),
        badge: l10n.t('save_75'),
        badgeBgColor: const Color(0xFF77C97E),
        badgeTextColor: const Color(0xFFFFFFFF),
      ),
    ];
    final features = [
      l10n.t('feature_personalized_sessions'),
      l10n.t('feature_sleep_relaxation'),
      l10n.t('feature_focus_energy'),
      l10n.t('feature_mindfulness_tracking'),
      l10n.t('feature_nature_music'),
    ];

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/onboarding1.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('unlock_full'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Amstelvar',
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1A1A1A),
                        height: 40 / 32,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      l10n.t('ai_meditation_power'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 40 / 32,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.t('paywall_description'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7B7E89),
                        height: 24 / 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FeaturesCard(features: features),
                    const SizedBox(height: 16),
                    ...List.generate(plans.length, (i) {
                      return Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                        child: _PlanTile(
                          data: plans[i],
                          selected: _selectedPlan == i,
                          onTap: () => setState(() => _selectedPlan = i),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 16),
              child: _NextButton(onPressed: _onNext),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.features});

  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: features.map((f) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A0A0A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  f,
                  style: const TextStyle(
                    fontFamily: 'FunnelDisplay',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                    height: 24 / 16,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlanData {
  const _PlanData({
    required this.label,
    required this.price,
    required this.period,
    required this.accentColor,
    this.badge,
    this.badgeBgColor,
    this.badgeTextColor,
  });

  final String label;
  final String price;
  final String period;
  final Color accentColor;
  final String? badge;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _PlanData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 32),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(width: 4, color: data.accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: const TextStyle(
                          fontFamily: 'FunnelDisplay',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFAAAEBA),
                          height: 18 / 13,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            data.price,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                              height: 28 / 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            ' / ${data.period}',
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAAEBA),
                              height: 28 / 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (data.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: data.badgeBgColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                data.badge!,
                                style: TextStyle(
                                  fontFamily: 'FunnelDisplay',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: data.badgeTextColor,
                                  height: 20 / 14,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFF111111)
                      : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.circle, color: Colors.white, size: 10)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Expanded(
              child: Text(
                AppLocalizations.of(context).t('next'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
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
