import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';

class BackgroundSoundSheet extends StatelessWidget {
  const BackgroundSoundSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BackgroundSoundSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const sounds = ['Nature', 'Ambient music', 'Rain', 'None'];
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: GradientBackground(child: const SizedBox.expand()),
                ),
              ),
              Column(
                children: [
                  _buildHandle(),
                  _buildHeader(context),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: sounds
                              .map((s) {
                                final display = switch (s) {
                                  'Nature' => l10n.t('nature'),
                                  'Ambient music' => l10n.t('ambient_music'),
                                  'Rain' => l10n.t('rain'),
                                  'None' => l10n.t('none'),
                                  _ => s,
                                };
                                return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _Option(
                                      label: display,
                                      onTap: () =>
                                          Navigator.of(context).pop(s),
                                    ),
                                  );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        height: 40,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: Color(0xFFAAAEBA),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                AppLocalizations.of(context).t('background_sound'),
                style: const TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(100),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'FunnelDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
