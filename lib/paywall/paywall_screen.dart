import 'package:flutter/material.dart';
import 'package:apphud/models/apphud_models/apphud_product.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/apphud_service.dart';
import '../core/widgets/gradient_background.dart';
import '../core/widgets/main_shell.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0;
  List<_PlanData> _plans = [];
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  bool _hasLoadedProducts = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedProducts) {
      _hasLoadedProducts = true;
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paywall = await ApphudService.instance.getMainPaywall();
      final products = await ApphudService.instance.getProducts();
      if (paywall != null) {
        ApphudService.instance.paywallShown(paywall);
      }
      final plans = _buildPlansFromProducts(products, l10n);
      if (mounted) {
        setState(() {
          _plans = plans;
          _selectedPlan = plans.length > 1 ? 1 : 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plans = _buildFallbackPlans(l10n);
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  List<_PlanData> _buildPlansFromProducts(
    List<ApphudProduct> products,
    AppLocalizations l10n,
  ) {
    if (products.isEmpty) return _buildFallbackPlans(l10n);
    final order = ['weekly', 'monthly', 'yearly'];
    final sorted = List<ApphudProduct>.from(products)
      ..sort((a, b) {
        final ai = order.indexWhere((s) => a.productId.toLowerCase().contains(s));
        final bi = order.indexWhere((s) => b.productId.toLowerCase().contains(s));
        return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
      });
    const accents = [
      Color(0xFFCBA7FF),
      Color(0xFF7ACBFF),
      Color(0xFF77C97E),
    ];
    return sorted.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      final id = p.productId.toLowerCase();
      String label, period;
      String? badge;
      Color? badgeBgColor, badgeTextColor;
      if (id.contains('weekly')) {
        label = l10n.t('weekly');
        period = l10n.t('week');
        badge = l10n.t('trial_3_days');
        badgeBgColor = const Color(0x1ACBA7FF);
        badgeTextColor = const Color(0xFFCBA7FF);
      } else if (id.contains('monthly')) {
        label = l10n.t('monthly');
        period = l10n.t('month');
      } else if (id.contains('yearly') || id.contains('annual')) {
        label = l10n.t('yearly');
        period = l10n.t('year');
        badge = l10n.t('save_75');
        badgeBgColor = const Color(0xFF77C97E);
        badgeTextColor = const Color(0xFFFFFFFF);
      } else {
        label = p.name ?? p.productId;
        period = l10n.t('month');
      }
      return _PlanData(
        label: label,
        price: formatApphudProductPrice(p),
        period: period,
        accentColor: accents[i % accents.length],
        badge: badge,
        badgeBgColor: badgeBgColor,
        badgeTextColor: badgeTextColor,
        product: p,
      );
    }).toList();
  }

  List<_PlanData> _buildFallbackPlans(AppLocalizations l10n) {
    return [
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
  }

  void _navigateToMain() {
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

  Future<void> _onSubscribe() async {
    if (_purchasing || _plans.isEmpty) return;
    final product = _plans[_selectedPlan].product;
    if (product == null) {
      _navigateToMain();
      return;
    }
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final success = await ApphudService.instance.purchase(product);
      if (mounted) {
        setState(() => _purchasing = false);
        if (success) {
          _navigateToMain();
        } else {
          setState(() => _error = 'Purchase failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _onRestore() async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final hasAccess = await ApphudService.instance.restorePurchases();
      if (mounted) {
        setState(() => _purchasing = false);
        if (hasAccess) {
          _navigateToMain();
        } else {
          setState(() => _error = 'No purchases to restore');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final plans = _loading ? _buildFallbackPlans(l10n) : _plans;
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
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SubscribeButton(
                    onPressed: _onSubscribe,
                    loading: _purchasing,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _purchasing ? null : _onRestore,
                    child: Text(
                      l10n.t('restore'),
                      style: const TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7B7E89),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
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
    this.product,
  });

  final String label;
  final String price;
  final String period;
  final Color accentColor;
  final String? badge;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final ApphudProduct? product;
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

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                children: [
                  const SizedBox(width: 56),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).t('next'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
