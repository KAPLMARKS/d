import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/localization/app_localizations.dart';
import '../core/widgets/gradient_background.dart';
import '../core/services/audio_service.dart';

class PlayerBackgroundSoundsSheet extends StatefulWidget {
  const PlayerBackgroundSoundsSheet({super.key, this.currentSound});

  final String? currentSound;

  static Future<String?> show(BuildContext context, {String? currentSound}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          PlayerBackgroundSoundsSheet(currentSound: currentSound),
    );
  }

  @override
  State<PlayerBackgroundSoundsSheet> createState() =>
      _PlayerBackgroundSoundsSheetState();
}

class _PlayerBackgroundSoundsSheetState
    extends State<PlayerBackgroundSoundsSheet> {
  String? _selected;
  late double _volume;

  static const _sounds = [
    _SoundOption(label: 'None', image: null, svgIcon: 'assets/images/none.svg'),
    _SoundOption(label: 'Nature', image: 'assets/images/nature.jpg'),
    _SoundOption(label: 'Ambient music', image: 'assets/images/ambient_music.jpg'),
    _SoundOption(label: 'Rain', image: 'assets/images/rain.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSound;
    _volume = AudioService.instance.volume;
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
                        children: [
                          const SizedBox(height: 24),
                          _buildGrid(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildVolumeSection(bottomPadding),
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
                onTap: () => Navigator.of(context).pop(_selected),
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
                AppLocalizations.of(context).t('background_sounds'),
                style: TextStyle(
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

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 166 / 196,
      ),
      itemCount: _sounds.length,
      itemBuilder: (context, index) {
        final sound = _sounds[index];
        final isSelected = _selected == sound.label;
        final l10n = AppLocalizations.of(context);
        final displayLabel = switch (sound.label) {
          'None' => l10n.t('none'),
          'Nature' => l10n.t('nature'),
          'Ambient music' => l10n.t('ambient_music'),
          'Rain' => l10n.t('rain'),
          _ => sound.label,
        };
        return _SoundCard(
          label: displayLabel,
          image: sound.image,
          svgIcon: sound.svgIcon,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selected = sound.label);
            Navigator.of(context).pop(sound.label);
          },
        );
      },
    );
  }

  Widget _buildVolumeSection(double bottomPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0x8FFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: const Border(
          top: BorderSide(
            color: Color(0x52FFFFFF),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).t('background_volume'),
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                activeTrackColor: const Color(0xFF111111),
                inactiveTrackColor: Colors.white,
                thumbColor: Colors.white,
                thumbShape: const _CustomThumbShape(),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 20),
                overlayColor: const Color(0x10111111),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: _volume,
                onChanged: (v) {
                  setState(() => _volume = v);
                  AudioService.instance.setVolume(v);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomThumbShape extends SliderComponentShape {
  const _CustomThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(30, 30);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    final borderPaint = Paint()
      ..color = const Color(0x29111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, 7, borderPaint);

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, fillPaint);
  }
}

class _SoundOption {
  const _SoundOption({required this.label, this.image, this.svgIcon});

  final String label;
  final String? image;
  final String? svgIcon;
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({
    required this.label,
    this.image,
    this.svgIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? image;
  final String? svgIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFF6F7FA),
                border: isSelected
                    ? Border.all(color: const Color(0xFF111111), width: 2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: image != null
                    ? Image.asset(
                        image!,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: SvgPicture.asset(
                          svgIcon!,
                          width: 48,
                          height: 48,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFD9D9D9),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'FunnelDisplay',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
