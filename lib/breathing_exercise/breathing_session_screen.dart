import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/history_service.dart';
import '../core/services/appsflyer_service.dart';
import 'breathing_complete_sheet.dart';

class BreathingSessionScreen extends StatefulWidget {
  const BreathingSessionScreen({
    super.key,
    required this.mood,
    required this.duration,
    this.inhaleSeconds = 4,
    this.hold1Seconds = 4,
    this.exhaleSeconds = 4,
    this.hold2Seconds = 4,
    this.cycles = 6,
  });

  final String mood;
  final String duration;
  final int inhaleSeconds;
  final int hold1Seconds;
  final int exhaleSeconds;
  final int hold2Seconds;
  final int cycles;

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _countdownController;
  late final Animation<double> _breathAnimation;

  final FlutterTts _tts = FlutterTts();
  bool _voiceEnabled = true;

  bool _isCountdown = true;
  int _countdownValue = 3;
  String _phase = 'Inhale';

  late int _cycleDuration;
  int _elapsedCycles = 0;
  late int _totalCycles;

  @override
  void initState() {
    super.initState();

    _cycleDuration = widget.inhaleSeconds +
        widget.hold1Seconds +
        widget.exhaleSeconds +
        widget.hold2Seconds;
    if (_cycleDuration <= 0) _cycleDuration = 16;

    _totalCycles = widget.cycles;

    _initTts();

    _countdownController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _breathController = AnimationController(
      duration: Duration(seconds: _cycleDuration),
      vsync: this,
    );

    _breathAnimation = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    );

    final inhaleEnd = widget.inhaleSeconds / _cycleDuration;
    final hold1End = (widget.inhaleSeconds + widget.hold1Seconds) / _cycleDuration;
    final exhaleEnd = (widget.inhaleSeconds + widget.hold1Seconds + widget.exhaleSeconds) / _cycleDuration;

    _breathController.addListener(() {
      final l10n = AppLocalizations.of(context);
      final v = _breathController.value;
      String newPhase;
      if (v < inhaleEnd) {
        newPhase = l10n.t('inhale');
      } else if (v < hold1End) {
        newPhase = l10n.t('hold');
      } else if (v < exhaleEnd) {
        newPhase = l10n.t('exhale');
      } else {
        newPhase = l10n.t('hold');
      }
      if (newPhase != _phase) {
        setState(() => _phase = newPhase);
        _speakPhase(newPhase);
      }
    });

    _breathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _elapsedCycles++;
        if (_elapsedCycles >= _totalCycles) {
          _onComplete();
        } else {
          _breathController.forward(from: 0);
        }
      }
    });

    _startCountdown();
  }

  void _initTts() {
    final langCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final lang = langCode == 'ru' ? 'ru-RU' : 'en-US';
    _tts.setLanguage(lang);
    _tts.setSpeechRate(0.45);
    _tts.setPitch(1.0);
    _tts.setVolume(1.0);
  }

  void _speakPhase(String phase) {
    if (!_voiceEnabled) return;
    _tts.speak(phase);
  }

  void _toggleVoice() {
    setState(() => _voiceEnabled = !_voiceEnabled);
    if (!_voiceEnabled) _tts.stop();
  }

  void _startCountdown() {
    _countdownController.forward();
    _countdownController.addListener(() {
      final val = 3 - (_countdownController.value * 3).floor();
      if (val != _countdownValue && val >= 0) {
        setState(() => _countdownValue = val.clamp(1, 3));
      }
    });
    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final l10n = AppLocalizations.of(context);
        final inhaleText = l10n.t('inhale');
        setState(() {
          _isCountdown = false;
          _phase = inhaleText;
        });
        _speakPhase(inhaleText);
        _breathController.forward();
      }
    });
  }

  void _onComplete() {
    final digits = widget.duration.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(digits) ?? 1;
    HistoryService.instance.addBreathingEntry(HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: AppLocalizations.of(context).t('breathing_exercise_title'),
      goal: widget.mood,
      durationMinutes: minutes,
      date: DateTime.now(),
      type: 'breathing',
    ));
    AppsFlyerService.instance.logBreathingCompleted(
      mood: widget.mood,
      duration: widget.duration,
    );

    Navigator.of(context).pop();
    BreathingCompleteSheet.show(context);
  }

  void _restart() {
    _tts.stop();
    _breathController.reset();
    _elapsedCycles = 0;
    setState(() {
      _isCountdown = true;
      _countdownValue = 3;
      _phase = AppLocalizations.of(context).t('inhale');
    });
    _countdownController.reset();
    _startCountdown();
  }

  @override
  void dispose() {
    _tts.stop();
    _breathController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEAF4FC),
              Color(0xFFF0F8FF),
              Color(0xFFF5FBFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: _isCountdown
                  ? _buildCountdown()
                  : _buildBreathingCircle(),
            ),
            Positioned(
              top: topPadding + 12,
              left: 24,
              child: _CircleButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (_isCountdown)
              Positioned(
                top: topPadding + 12,
                right: 24,
                child: _CircleButton(
                  svgAsset: 'assets/images/reload.svg',
                  onTap: _restart,
                ),
              ),
            Positioned(
              bottom: bottomPadding + 24,
              left: 24,
              child: _CircleButton(
                icon: _voiceEnabled
                    ? Icons.volume_up_outlined
                    : Icons.volume_off_outlined,
                onTap: _toggleVoice,
              ),
            ),
            Positioned(
              bottom: bottomPadding + 24,
              right: 24,
              child: _CircleButton(
                svgAsset: 'assets/images/reload.svg',
                onTap: _restart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return _coreCircle('$_countdownValue');
  }

  Widget _coreCircle(String text) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF7ACBFF),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FFFFFF),
            blurRadius: 14,
            offset: Offset(0, 4),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'FunnelDisplay',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 32 / 24,
          letterSpacing: -1.5,
        ),
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _breathAnimation,
      builder: (context, _) {
        final t = _breathAnimation.value;
        final ringScale = t < 0.5
            ? 0.5 + (t / 0.5) * 0.5
            : 1.0 - ((t - 0.5) / 0.5) * 0.5;

        return SizedBox(
          width: 360,
          height: 360,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 4; i >= 0; i--)
                Transform.scale(
                  scale: ringScale * (1.0 + i * 0.3),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(
                        122, 203, 255,
                        0.12 - i * 0.015,
                      ),
                    ),
                  ),
                ),
              _coreCircle(_phase),
            ],
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({this.icon, this.svgAsset, required this.onTap});

  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        child: Center(
          child: svgAsset != null
              ? SvgPicture.asset(
                  svgAsset!,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFAAAEBA),
                    BlendMode.srcIn,
                  ),
                )
              : Icon(icon, size: 20, color: const Color(0xFFAAAEBA)),
        ),
      ),
    );
  }
}
