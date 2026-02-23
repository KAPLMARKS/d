import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/ai_service.dart';
import 'mood_selection_sheet.dart';
import 'duration_selection_sheet.dart';
import 'breathing_session_screen.dart';

class BreathingExerciseSheet extends StatefulWidget {
  const BreathingExerciseSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BreathingExerciseSheet(),
    );
  }

  @override
  State<BreathingExerciseSheet> createState() => _BreathingExerciseSheetState();
}

class _BreathingExerciseSheetState extends State<BreathingExerciseSheet> {
  String? _selectedMood;
  String? _selectedDuration;

  bool get _isReady => _selectedMood != null && _selectedDuration != null;

  void _openMoodSelection() async {
    final result = await MoodSelectionSheet.show(context);
    if (result != null) setState(() => _selectedMood = result);
  }

  void _openDurationSelection() async {
    final result = await DurationSelectionSheet.show(context);
    if (result != null) setState(() => _selectedDuration = result);
  }

  bool _isGenerating = false;

  void _startSession() async {
    if (!_isReady || _isGenerating) return;
    setState(() => _isGenerating = true);

    final result = await AiService.instance.generateBreathingExercise(
      mood: _selectedMood!,
      duration: _selectedDuration!,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() => _isGenerating = false);

    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BreathingSessionScreen(
          mood: _selectedMood!,
          duration: _selectedDuration!,
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
                        children: [
                          const SizedBox(height: 16),
                          Image.asset(
                            'assets/images/breathing_intro.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.t('fill_generate_breathing'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'FunnelDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                              height: 28 / 20,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _OptionTile(
                            svgAsset: 'assets/images/target.svg',
                            label: l10n.t('mood_check_in'),
                            value: _selectedMood,
                            onTap: _openMoodSelection,
                          ),
                          const SizedBox(height: 8),
                          _OptionTile(
                            svgAsset: 'assets/images/duration.svg',
                            label: l10n.t('duration'),
                            value: _selectedDuration,
                            onTap: _openDurationSelection,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
                    child: _StartButton(
                      enabled: _isReady,
                      onPressed: _startSession,
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.svgAsset,
    required this.label,
    this.value,
    required this.onTap,
  });

  final String svgAsset;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 24, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value != null
                    ? const Color(0xFF111111)
                    : const Color(0xFFF6F7FA),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: SvgPicture.asset(
                  svgAsset,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    value != null
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFAAAEBA),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: value != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF90939F),
                            height: 18 / 13,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          value!,
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 24 / 16,
                            color: Color(0xFF111111),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF90939F),
                        height: 24 / 16,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFAAAEBA),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? const Color(0xFF111111) : Colors.white,
          foregroundColor: enabled ? Colors.white : const Color(0xFFAAAEBA),
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFFAAAEBA),
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
                AppLocalizations.of(context).t('start_session'),
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
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0x14F6F7FA)
                    : const Color(0xFFF6F7FA),
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
