import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/ai_service.dart';
import '../breathing_exercise/breathing_exercise_sheet.dart';
import '../breathing_exercise/breathing_session_screen.dart';
import '../daily_routine/daily_routine_intro_sheet.dart';
import '../generate_meditation/generate_meditation_sheet.dart';
import '../generate_meditation/meditation_detail_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCategory = 0;
  String? _aiRecommendation;
  bool _aiRequested = false;
  late AnimationController _shimmerController;

  MeditationResult? _todayMeditation;
  bool _todayReady = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_aiRequested) {
      _aiRequested = true;
      _loadAiRecommendation();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAiRecommendation() async {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    final futures = await Future.wait([
      AiService.instance.generateDailyRecommendation(
        languageCode: languageCode,
      ),
      AiService.instance.generateMeditation(
        goal: 'Reduce stress',
        duration: '2 min',
        voiceStyle: 'Soft',
        backgroundSound: 'Nature',
        languageCode: languageCode,
      ),
    ]);

    if (!mounted) return;
    setState(() {
      _aiRecommendation = futures[0] as String;
      _todayMeditation = futures[1] as MeditationResult;
      _todayReady = true;
    });
  }

  void _openTodayMeditation() {
    if (_todayReady && _todayMeditation != null) {
      MeditationDetailSheet.show(
        context,
        title: _todayMeditation!.title,
        description: _todayMeditation!.description,
        duration: '2 min',
        sound: 'Nature',
        script: _todayMeditation!.script,
        voiceStyle: 'Soft',
      );
    } else {
      _launchMeditation('Reduce stress', '2 min', 'Soft', 'Nature');
    }
  }

  void _launchSession(_Session session) {
    if (session.type == _SessionType.breathing) {
      _launchBreathing(session);
    } else {
      _launchMeditation(session.goal, session.duration, 'Soft', 'Nature');
    }
  }

  void _launchMeditation(String goal, String duration, String voice, String sound) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final lang = Localizations.localeOf(context).languageCode;
    final result = await AiService.instance.generateMeditation(
      goal: goal,
      duration: duration,
      voiceStyle: voice,
      backgroundSound: sound,
      languageCode: lang,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    MeditationDetailSheet.show(
      context,
      title: result.title,
      description: result.description,
      duration: duration,
      sound: sound,
      script: result.script,
      voiceStyle: voice,
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
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final categories = [
      l10n.t('sleep'),
      l10n.t('stress_anxiety'),
      l10n.t('daily_meditation'),
    ];

    return GradientBackground(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 32, 24, 28),
              child: _buildHeader(),
            ),
            _ContentPanel(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(l10n),
                    const SizedBox(height: 32),
                    _buildTodaySection(l10n),
                    const SizedBox(height: 32),
                    _buildRecommendedSection(l10n, categories),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: l10n.t('hello'),
                style: TextStyle(
                  fontFamily: 'Amstelvar',
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 32 / 24,
                  color: Color(0xFF111111),
                  letterSpacing: -1.5,
                ),
              ),
              TextSpan(
                text: 'Vitalii',
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                  height: 32 / 24,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Amstelvar',
              fontSize: 48,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
              height: 52 / 48,
              letterSpacing: -1.5,
            ),
            children: [
              TextSpan(
                text: l10n.t('how_are_you'),
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              TextSpan(
                text: l10n.t('feeling'),
                style: TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                  height: 52 / 48,
                  letterSpacing: -1.5,
                ),
              ),
              TextSpan(
                text: l10n.t('today'),
                style: TextStyle(
                  fontFamily: 'Amstelvar',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        _ActionButton(
          iconAsset: 'assets/images/generate_meditation.svg',
          label: l10n.t('generate_meditation'),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          onTap: () => GenerateMeditationSheet.show(context),
        ),
        const SizedBox(height: 4),
        _ActionButton(
          iconAsset: 'assets/images/breathing_exercise.svg',
          label: l10n.t('breathing_exercise'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => BreathingExerciseSheet.show(context),
        ),
        const SizedBox(height: 4),
        _ActionButton(
          iconAsset: 'assets/images/daily_routine.svg',
          label: l10n.t('daily_routine'),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          onTap: () => DailyRoutineIntroSheet.show(context),
        ),
      ],
    );
  }

  Widget _buildTodaySection(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.t('todays_meditation'),
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
                height: 24 / 16,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              DateFormat(
                'EEEE, d MMM',
                Localizations.localeOf(context).toLanguageTag(),
              ).format(DateTime.now()),
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF90939F),
                height: 20 / 14,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openTodayMeditation,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/grass.jpg',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 36,
                        child: ClipRRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
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
                              alignment: Alignment.center,
                              child: Text(
                                l10n.t('minutes_short'),
                                style: TextStyle(
                                  fontFamily: 'FunnelDisplay',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 20 / 12,
                                  letterSpacing: -0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _aiRecommendation == null
                    ? _buildTodayShimmer()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('minutes_long'),
                            style: TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                              height: 24 / 16,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _aiRecommendation!,
                            style: TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAAAEBA),
                              height: 20 / 14,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/images/daily_routine.svg',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.t('daily_routine'),
                                style: TextStyle(
                                  fontFamily: 'FunnelDisplay',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF77C97E),
                                  height: 15 / 12,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _buildTodayShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final v = _shimmerController.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBar(width: 100, height: 16, animationValue: v),
            const SizedBox(height: 8),
            _ShimmerBar(width: 180, height: 12, animationValue: v),
            const SizedBox(height: 4),
            _ShimmerBar(width: 140, height: 12, animationValue: v),
            const SizedBox(height: 10),
            _ShimmerBar(width: 90, height: 12, animationValue: v),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedSection(
    AppLocalizations l10n,
    List<String> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('recommended_sessions'),
          style: TextStyle(
            fontFamily: 'FunnelDisplay',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
            height: 24 / 16,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isActive = i == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF111111)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    categories[i],
                    style: TextStyle(
                      fontFamily: 'FunnelDisplay',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFFAAAEBA),
                      height: 20 / 13,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sessionData[_selectedCategory].length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final session = _sessionData[_selectedCategory][i];
              return _SessionCard(
                session: session,
                onTap: () => _launchSession(session),
              );
            },
          ),
        ),
      ],
    );
  }

  static final _sessionData = <List<_Session>>[
    // Sleep
    [
      _Session('deep_sleep', 'assets/images/foggy.jpg', '10 min', _SessionType.meditation, 'Improve sleep'),
      _Session('sleep_breath', 'assets/images/tree.jpg', '5 min', _SessionType.breathing, 'Calm'),
      _Session('night_calm', 'assets/images/nature.jpg', '15 min', _SessionType.meditation, 'Improve sleep'),
      _Session('dream_prep', 'assets/images/grass.jpg', '5 min', _SessionType.meditation, 'Improve sleep'),
      _Session('bedtime_breath', 'assets/images/rain.jpg', '3 min', _SessionType.breathing, 'Calm'),
    ],
    // Stress & Anxiety
    [
      _Session('stress_relief', 'assets/images/grass.jpg', '5 min', _SessionType.meditation, 'Reduce stress'),
      _Session('calm_breath', 'assets/images/nature.jpg', '3 min', _SessionType.breathing, 'Stressed'),
      _Session('anxiety_ease', 'assets/images/foggy.jpg', '10 min', _SessionType.meditation, 'Calm anxiety'),
      _Session('panic_relief', 'assets/images/tree.jpg', '1 min', _SessionType.breathing, 'Anxious'),
      _Session('inner_peace', 'assets/images/meditation_background.jpg', '15 min', _SessionType.meditation, 'Calm anxiety'),
      _Session('tension_release', 'assets/images/rain.jpg', '5 min', _SessionType.breathing, 'Stressed'),
    ],
    // Daily Meditation
    [
      _Session('morning_focus', 'assets/images/tree.jpg', '5 min', _SessionType.meditation, 'Increase focus'),
      _Session('midday_reset', 'assets/images/grass.jpg', '3 min', _SessionType.breathing, 'Neutral'),
      _Session('gratitude', 'assets/images/nature.jpg', '10 min', _SessionType.meditation, 'Reduce stress'),
      _Session('energy_boost', 'assets/images/foggy.jpg', '5 min', _SessionType.meditation, 'Boost energy'),
      _Session('evening_wind', 'assets/images/ambient_music.jpg', '10 min', _SessionType.meditation, 'Improve sleep'),
      _Session('body_scan', 'assets/images/rain.jpg', '5 min', _SessionType.breathing, 'Calm'),
    ],
  ];
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconAsset,
    required this.label,
    required this.borderRadius,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, width: 24, height: 24),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'FunnelDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                  height: 24 / 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}

enum _SessionType { meditation, breathing }

class _Session {
  const _Session(this.titleKey, this.image, this.duration, this.type, this.goal);
  final String titleKey;
  final String image;
  final String duration;
  final _SessionType type;
  final String goal;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final _Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMeditation = session.type == _SessionType.meditation;
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

class _ContentPanel extends StatelessWidget {
  const _ContentPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradientBorderPainter(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0x7AFFFFFF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: child,
      ),
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromLTRBAndCorners(
      0.5,
      0.5,
      size.width - 0.5,
      size.height,
      topLeft: const Radius.circular(40),
      topRight: const Radius.circular(40),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x52FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({
    required this.width,
    required this.height,
    required this.animationValue,
  });

  final double width;
  final double height;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * animationValue, 0),
          end: Alignment(1.0 + 2.0 * animationValue, 0),
          colors: const [
            Color(0xFFEEEEEE),
            Color(0xFFF8F8F8),
            Color(0xFFEEEEEE),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
