import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/history_service.dart';
import '../core/services/appsflyer_service.dart';
import '../core/services/audio_service.dart';
import '../core/services/tts_service.dart';
import '../core/services/favorites_service.dart';
import 'player_background_sounds_sheet.dart';

part 'meditation_player_logic.dart';
part 'meditation_player_controls.dart';

class MeditationPlayerScreen extends StatefulWidget {
  const MeditationPlayerScreen({
    super.key,
    required this.duration,
    required this.sound,
    this.title = 'Meditation',
    this.goal = '',
    this.script = '',
    this.voiceStyle = '',
    this.description = '',
  });

  final String duration;
  final String sound;
  final String title;
  final String goal;
  final String script;
  final String voiceStyle;
  final String description;

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen> {
  bool _isPlaying = false;
  late int _totalSeconds;
  int _currentSeconds = 0;
  Timer? _timer;
  late String _currentSound;

  bool _ttsLoading = false;
  String? _ttsFilePath;
  bool _voiceStarted = false;
  bool _bgSoundStarted = false;
  bool _fallbackTts = false;
  bool _fallbackStarted = false;

  bool _isFavorite = false;
  bool _savedToHistory = false;
  late String _meditationId;

  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final digits = widget.duration.replaceAll(RegExp(r'[^0-9]'), '');
    _totalSeconds = (int.tryParse(digits) ?? 3) * 60;
    _currentSound = widget.sound;
    _meditationId =
        'med_${DateTime.now().millisecondsSinceEpoch}';
    _isFavorite = false;

    _prepareTts();
  }

  @override
  void dispose() {
    _cleanupPlayback();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: RepaintBoundary(
        key: _repaintKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox.expand(
              child: Image.asset(
                'assets/images/meditation_background.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
            Container(color: Colors.black.withValues(alpha: 0.12)),

            // Close button
            Positioned(
              top: topPadding + 12,
              left: 24,
              child: _GlassCircleButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // Favorite button
            Positioned(
              top: topPadding + 12,
              right: 24,
              child: _GlassCircleButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                onTap: _toggleFavorite,
              ),
            ),

            // Loading or playback controls
            if (_ttsLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).t('generating_voice'),
                      style: const TextStyle(
                        fontFamily: 'FunnelDisplay',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GlassPlayerButton(
                      svgAsset: 'assets/images/skip_back.svg',
                      onTap: _seekBackward,
                    ),
                    const SizedBox(width: 24),
                    _GlassPlayPauseButton(
                      isPlaying: _isPlaying,
                      onTap: _togglePlay,
                    ),
                    const SizedBox(width: 24),
                    _GlassPlayerButton(
                      svgAsset: 'assets/images/skip_forward.svg',
                      onTap: _seekForward,
                    ),
                  ],
                ),
              ),

            // Slider + time
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomPadding + 90,
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Colors.white,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: _currentSeconds.toDouble(),
                      max: _totalSeconds.toDouble(),
                      onChanged: (v) {
                        setState(() => _currentSeconds = v.toInt());
                        if (_ttsFilePath != null) {
                          AudioService.instance
                              .seekVoice(Duration(seconds: v.toInt()));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentSeconds),
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _formatTime(_totalSeconds),
                          style: const TextStyle(
                            fontFamily: 'FunnelDisplay',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom bar: background sounds + share
            Positioned(
              left: 24,
              right: 24,
              bottom: bottomPadding + 24,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _changeSound,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.fromLTRB(4, 4, 24, 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0x52111111),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/background_sounds.svg',
                                    width: 18,
                                    height: 18,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)
                                        .t('background_sounds'),
                                    style: TextStyle(
                                      fontFamily: 'FunnelDisplay',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  Text(
                                    _localizedSound(context),
                                    style: const TextStyle(
                                      fontFamily: 'FunnelDisplay',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.4,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _GlassCircleButton(
                    icon: Icons.ios_share,
                    onTap: _shareScreenshot,
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
