import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/ai_service.dart';
import '../generate_meditation/generate_meditation_sheet.dart';
import '../breathing_exercise/breathing_exercise_sheet.dart';

class RoutineDetailSheet extends StatefulWidget {
  const RoutineDetailSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RoutineDetailSheet(),
    );
  }

  @override
  State<RoutineDetailSheet> createState() => _RoutineDetailSheetState();
}

class _RoutineDetailSheetState extends State<RoutineDetailSheet> {
  DailyRoutineResult? _routine;
  bool _isLoading = true;
  final Set<int> _completedIndices = {};
  bool _loadRequested = false;

  static const _meditationImages = [
    'assets/images/nature.jpg',
    'assets/images/meditation_background.jpg',
    'assets/images/ambient_music.jpg',
    'assets/images/rain.jpg',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadRequested) {
      _loadRequested = true;
      _loadRoutine();
    }
  }

  Future<void> _loadRoutine() async {
    setState(() => _isLoading = true);
    final languageCode = Localizations.localeOf(context).languageCode;
    final result = await AiService.instance.generateDailyRoutine(
      languageCode: languageCode,
    );
    if (mounted) {
      setState(() {
        _routine = result;
        _isLoading = false;
        _completedIndices.clear();
      });
    }
  }

  void _onCardTap(RoutinePractice practice, int index) {
    if (_completedIndices.contains(index)) return;

    final isBreathing = _isBreathingType(practice);
    Navigator.of(context).pop();

    if (isBreathing) {
      BreathingExerciseSheet.show(context);
    } else {
      GenerateMeditationSheet.show(context);
    }
  }

  void _startFirstUncompleted() {
    if (_routine == null) return;
    for (int i = 0; i < _routine!.practices.length; i++) {
      if (!_completedIndices.contains(i)) {
        _onCardTap(_routine!.practices[i], i);
        return;
      }
    }
  }

  bool _isBreathingType(RoutinePractice practice) {
    final t = practice.title.toLowerCase();
    final d = practice.description.toLowerCase();
    return t.contains('breath') ||
        t.contains('дыхан') ||
        t.contains('relax') ||
        t.contains('расслаб') ||
        d.contains('breath') ||
        d.contains('дыхан') ||
        practice.timeOfDay.toLowerCase() == 'afternoon' ||
        practice.timeOfDay.toLowerCase() == 'день';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF111111),
                            ),
                          )
                        : SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                            child: Column(
                              children: [
                                for (int i = 0;
                                    i < (_routine?.practices.length ?? 0);
                                    i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _buildPracticeSection(
                                      _routine!.practices[i], i),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: _ActionButton(
                      label: l10n.t('start'),
                      onPressed: _startFirstUncompleted,
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          for (int i = 0;
                              i < (_routine?.practices.length ?? 0);
                              i++) {
                            _completedIndices.add(i);
                          }
                        });
                        Future.delayed(const Duration(milliseconds: 400), () {
                          if (mounted) Navigator.of(context).pop();
                        });
                      },
                      child: Text(
                        l10n.t('mark_as_done'),
                        style: const TextStyle(
                          fontFamily: 'FunnelDisplay',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                          letterSpacing: -0.5,
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

  Widget _buildPracticeSection(RoutinePractice practice, int index) {
    final isDone = _completedIndices.contains(index);
    final isBreathing = _isBreathingType(practice);

    return GestureDetector(
      onTap: () => _onCardTap(practice, index),
      child: Opacity(
        opacity: isDone ? 0.5 : 1.0,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${practice.timeOfDay} ${isBreathing ? AppLocalizations.of(context).t('breathing_type').toLowerCase() : AppLocalizations.of(context).t('meditation_type').toLowerCase()}',
                    style: const TextStyle(
                      fontFamily: 'FunnelDisplay',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                      height: 24 / 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isDone) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle,
                        size: 18, color: Color(0xFF77C97E)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            isBreathing
                ? _BreathingCard(
                    title: practice.title.toUpperCase(),
                    subtitle: practice.description,
                  )
                : _MeditationCard(
                    title: practice.title.toUpperCase(),
                    subtitle: practice.description,
                    duration: practice.duration,
                    imageAsset: _meditationImages[index % _meditationImages.length],
                  ),
          ],
        ),
      ),
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
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
                AppLocalizations.of(context).t('routine'),
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
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  _HeaderSvgIcon(
                    asset: 'assets/images/reload.svg',
                    onTap: () {
                      _loadRequested = false;
                      _loadRoutine();
                    },
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

class _MeditationCard extends StatelessWidget {
  const _MeditationCard({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imageAsset,
  });

  final String title;
  final String subtitle;
  final String duration;
  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    imageAsset,
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
                            duration.toUpperCase(),
                            style: const TextStyle(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
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
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'FunnelDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFAAAEBA),
                    height: 20 / 14,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingCard extends StatelessWidget {
  const _BreathingCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 88,
              height: 88,
              color: const Color(0xFFF0F8F0),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/breathing_exercise.svg',
                  width: 40,
                  height: 40,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF77C97E),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
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
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'FunnelDisplay',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFAAAEBA),
                    height: 20 / 14,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'FunnelDisplay',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF90939F),
                      height: 18 / 13,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      TextSpan(text: '${l10n.t('inhale')} '),
                      const TextSpan(
                        text: '4',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                      ),
                      TextSpan(text: ' ${l10n.t('sec')}  ${l10n.t('exhale')} '),
                      const TextSpan(
                        text: '6',
                        style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                      ),
                      TextSpan(text: ' ${l10n.t('sec')}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSvgIcon extends StatelessWidget {
  const _HeaderSvgIcon({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFFAAAEBA),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
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
