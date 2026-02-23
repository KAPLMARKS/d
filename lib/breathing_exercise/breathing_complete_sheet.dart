import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/ai_service.dart';
import '../generate_meditation/meditation_detail_sheet.dart';
import 'breathing_session_screen.dart';

class BreathingCompleteSheet extends StatefulWidget {
  const BreathingCompleteSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreathingCompleteSheet(),
    );
  }

  @override
  State<BreathingCompleteSheet> createState() => _BreathingCompleteSheetState();
}

class _BreathingCompleteSheetState extends State<BreathingCompleteSheet> {
  static const _sessions = [
    _Session('stress_relief', 'assets/images/grass.jpg', '5 min', _Type.meditation, 'Reduce stress'),
    _Session('calm_breath', 'assets/images/nature.jpg', '3 min', _Type.breathing, 'Calm'),
    _Session('deep_sleep', 'assets/images/foggy.jpg', '10 min', _Type.meditation, 'Improve sleep'),
    _Session('body_scan', 'assets/images/tree.jpg', '5 min', _Type.breathing, 'Neutral'),
  ];

  void _launchSession(_Session session) {
    Navigator.of(context).pop();
    if (session.type == _Type.breathing) {
      _launchBreathing(session);
    } else {
      _launchMeditation(session);
    }
  }

  void _launchMeditation(_Session session) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final lang = Localizations.localeOf(context).languageCode;
    final result = await AiService.instance.generateMeditation(
      goal: session.goal,
      duration: session.duration,
      voiceStyle: 'Soft',
      backgroundSound: 'Nature',
      languageCode: lang,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    MeditationDetailSheet.show(
      context,
      title: result.title,
      description: result.description,
      duration: session.duration,
      sound: 'Nature',
      script: result.script,
      voiceStyle: 'Soft',
    );
  }

  void _launchBreathing(_Session session) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final lang = Localizations.localeOf(context).languageCode;
    final result = await AiService.instance.generateBreathingExercise(
      mood: session.goal,
      duration: session.duration,
      languageCode: lang,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BreathingSessionScreen(
          mood: session.goal,
          duration: session.duration,
          inhaleSeconds: result.inhaleSeconds,
          hold1Seconds: result.hold1Seconds,
          exhaleSeconds: result.exhaleSeconds,
          hold2Seconds: result.hold2Seconds,
          cycles: result.cycles,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                        children: [
                          const SizedBox(height: 24),
                          Image.asset(
                            'assets/images/breathing_intro.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.t('congrats'),
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              l10n.t('recommended_sessions'),
                              style: const TextStyle(
                                fontFamily: 'FunnelDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111111),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _sessions.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) => _SessionCard(
                                session: _sessions[i],
                                onTap: () => _launchSession(_sessions[i]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
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
                    Icons.close,
                    size: 20,
                    color: Color(0xFFAAAEBA),
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                AppLocalizations.of(context).t('breathing_exercise_title'),
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

enum _Type { meditation, breathing }

class _Session {
  const _Session(this.titleKey, this.image, this.duration, this.type, this.goal);
  final String titleKey;
  final String image;
  final String duration;
  final _Type type;
  final String goal;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final _Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMeditation = session.type == _Type.meditation;
    final typeLabel = isMeditation
        ? l10n.t('meditation_type')
        : l10n.t('breathing_type');
    final typeIcon = isMeditation
        ? 'assets/images/generate_meditation.svg'
        : 'assets/images/breathing_exercise.svg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFFE8E4EC),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              session.image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x29111111),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          typeIcon,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            typeLabel,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 15 / 11,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 68,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x52111111),
                          Color(0x00111111),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          session.duration.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 20 / 12,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t(session.titleKey),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 18 / 13,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
