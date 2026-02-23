import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFFF5F2F7)),
        const _GradientBlob(
          alignment: Alignment(-1.2, -0.8),
          radius: 0.7,
          color: Color(0xFFD4C4F0),
        ),
        const _GradientBlob(
          alignment: Alignment(1.2, -0.4),
          radius: 0.6,
          color: Color(0xFFB8E8D8),
        ),
        const _GradientBlob(
          alignment: Alignment(0.8, 1.0),
          radius: 0.6,
          color: Color(0xFFF0D8C8),
        ),
        const _GradientBlob(
          alignment: Alignment(-0.5, 0.3),
          radius: 0.4,
          color: Color(0xFFD0E0F0),
        ),
        child,
      ],
    );
  }
}

class _GradientBlob extends StatelessWidget {
  const _GradientBlob({
    required this.alignment,
    required this.radius,
    required this.color,
  });

  final Alignment alignment;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: alignment,
          radius: radius,
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
