import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/ai_service.dart';
import 'meditation_goal_sheet.dart';
import 'meditation_duration_sheet.dart';
import 'voice_style_sheet.dart';
import 'background_sound_sheet.dart';
import 'meditation_detail_sheet.dart';

class GenerateMeditationSheet extends StatefulWidget {
  const GenerateMeditationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GenerateMeditationSheet(),
    );
  }

  @override
  State<GenerateMeditationSheet> createState() =>
      _GenerateMeditationSheetState();
}

class _GenerateMeditationSheetState extends State<GenerateMeditationSheet> {
  String? _selectedGoal;
  String? _selectedDuration;
  String? _selectedVoice;
  String? _selectedSound;

  bool get _isReady =>
      _selectedGoal != null &&
      _selectedDuration != null &&
      _selectedVoice != null &&
      _selectedSound != null;

  void _openGoalSelection() async {
    final result = await MeditationGoalSheet.show(context);
    if (result != null) setState(() => _selectedGoal = result);
  }

  void _openDurationSelection() async {
    final result = await MeditationDurationSheet.show(context);
    if (result != null) setState(() => _selectedDuration = result);
  }

  void _openVoiceSelection() async {
    final result = await VoiceStyleSheet.show(context);
    if (result != null) setState(() => _selectedVoice = result);
  }

  void _openSoundSelection() async {
    final result = await BackgroundSoundSheet.show(context);
    if (result != null) setState(() => _selectedSound = result);
  }

  String? _localizedSound(AppLocalizations l10n) {
    if (_selectedSound == null) return null;
    return switch (_selectedSound!) {
      'None' => l10n.t('none'),
      'Nature' => l10n.t('nature'),
      'Ambient music' => l10n.t('ambient_music'),
      'Rain' => l10n.t('rain'),
      _ => _selectedSound!,
    };
  }

  bool _isGenerating = false;

  void _generate() async {
    if (!_isReady || _isGenerating) return;
    setState(() => _isGenerating = true);

    final result = await AiService.instance.generateMeditation(
      goal: _selectedGoal!,
      duration: _selectedDuration!,
      voiceStyle: _selectedVoice!,
      backgroundSound: _selectedSound!,
      languageCode: Localizations.localeOf(context).languageCode,
    );

    if (!mounted) return;
    setState(() => _isGenerating = false);

    Navigator.of(context).pop();
    MeditationDetailSheet.show(
      context,
      title: result.title,
      description: result.description,
      duration: _selectedDuration!,
      sound: _selectedSound!,
      script: result.script,
      voiceStyle: _selectedVoice!,
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
                            'assets/images/generate_meditation_intro.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.t('fill_generate_meditation'),
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
                            label: l10n.t('meditation_goal'),
                            value: _selectedGoal,
                            onTap: _openGoalSelection,
                          ),
                          const SizedBox(height: 8),
                          _OptionTile(
                            svgAsset: 'assets/images/duration.svg',
                            label: l10n.t('duration'),
                            value: _selectedDuration,
                            onTap: _openDurationSelection,
                          ),
                          const SizedBox(height: 8),
                          _OptionTile(
                            icon: Icons.equalizer,
                            label: l10n.t('voice_style'),
                            value: _selectedVoice,
                            onTap: _openVoiceSelection,
                          ),
                          const SizedBox(height: 8),
                          _OptionTile(
                            icon: Icons.music_note_outlined,
                            label: l10n.t('background_sound'),
                            value: _localizedSound(l10n),
                            onTap: _openSoundSelection,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
                    child: _GenerateButton(
                      enabled: _isReady,
                      onPressed: _generate,
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
                AppLocalizations.of(context).t('generate_meditation_title'),
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
    this.svgAsset,
    this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  final String? svgAsset;
  final IconData? icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSvg = svgAsset != null;

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
              child: Center(
                child: hasSvg
                    ? SvgPicture.asset(
                        svgAsset!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          value != null
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFAAAEBA),
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 20,
                        color: value != null
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFAAAEBA),
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

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.enabled, required this.onPressed});

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
                AppLocalizations.of(context).t('generate'),
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
