import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import 'meditation_player_screen.dart';

class MeditationDetailSheet extends StatelessWidget {
  const MeditationDetailSheet({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.sound,
    required this.script,
    required this.voiceStyle,
  });

  final String title;
  final String description;
  final String duration;
  final String sound;
  final String script;
  final String voiceStyle;

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required String duration,
    required String sound,
    String script = '',
    String voiceStyle = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MeditationDetailSheet(
        title: title,
        description: description,
        duration: duration,
        sound: sound,
        script: script,
        voiceStyle: voiceStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 220,
                              child: Image.asset(
                                'assets/images/meditation_background.jpg',
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAAEBA),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            duration,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAAEBA),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
                    child: _StartButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => MeditationPlayerScreen(
                              duration: duration,
                              sound: sound,
                              title: title,
                              goal: description,
                              script: script,
                              voiceStyle: voiceStyle,
                              description: description,
                            ),
                          ),
                        );
                      },
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
                    Icons.close,
                    size: 20,
                    color: Color(0xFFAAAEBA),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                AppLocalizations.of(context).t('meditation'),
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

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
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
                AppLocalizations.of(context).t('start'),
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
              child: const Icon(Icons.arrow_forward, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
