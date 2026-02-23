import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../localization/app_localizations.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(26, 0, 26, bottomPadding + 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(296),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(296),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCCFFFFFF),
                  Color(0x80FFFFFF),
                  Color(0x1AFFFFFF),
                ],
              ),
              border: Border.all(
                color: const Color(0x30FFFFFF),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _NavItem(
                  iconAsset: 'assets/images/home.svg',
                  label: l10n.t('nav_home'),
                  active: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  iconAsset: 'assets/images/history.svg',
                  label: l10n.t('nav_history'),
                  active: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconAsset,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF111111) : const Color(0xFFAAAEBA);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: color,
                height: 12 / 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
