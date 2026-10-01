part of '../tooth_brushing_game.dart';

class _FoamAndParticlePainter extends CustomPainter {
  final List<_FoamParticle> foams;
  final List<_Sparkle> sparkles;

  _FoamAndParticlePainter({required this.foams, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Foams
    for (final foam in foams) {
      final paint = Paint()
        ..color = foam.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(foam.pos, foam.radius, paint);

      // Bubble shine
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(foam.pos - Offset(foam.radius * 0.3, foam.radius * 0.3), foam.radius * 0.25, shinePaint);
    }

    // Draw Sparkles
    for (final sp in sparkles) {
      final paint = Paint()..color = sp.color.withValues(alpha: sp.opacity);
      canvas.save();
      canvas.translate(sp.pos.dx, sp.pos.dy);
      canvas.rotate(sp.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sp.size, height: sp.size * 0.3), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sp.size * 0.3, height: sp.size), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RinsePainter extends CustomPainter {
  final List<_FoamParticle> foams;
  final List<_WaterParticle> waterDrops;

  _RinsePainter({required this.foams, required this.waterDrops});

  @override
  void paint(Canvas canvas, Size size) {
    // Foams
    for (final foam in foams) {
      final paint = Paint()..color = foam.color.withValues(alpha: 0.5);
      canvas.drawCircle(foam.pos, foam.radius, paint);
    }

    // Water Drops
    for (final drop in waterDrops) {
      final paint = Paint()..color = drop.color;
      canvas.drawOval(
        Rect.fromCenter(center: drop.pos, width: drop.radius * 1.5, height: drop.radius * 2.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CelebrationSparklePainter extends CustomPainter {
  final double progress;
  _CelebrationSparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 12;

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi / count) + (progress * 2 * pi);
      final r = 120 + sin(progress * pi * 4 + i) * 20;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r;

      final paint = Paint()..color = Colors.amber.withValues(alpha: (0.5 + sin(progress * pi * 2 + i) * 0.5).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Dynamic Animated Pastel Background with Floating Soap Bubbles & Sparkles
class _AmbientBubblePainter extends CustomPainter {
  final double progress;
  _AmbientBubblePainter({required this.progress});

  // Deterministic bubble seeds (xRatio, size, speedFactor, phaseOffset, hue)
  static final List<List<double>> _bubbleSeeds = [
    [0.10, 32.0, 1.0, 0.1, 180.0],
    [0.22, 18.0, 1.3, 0.4, 210.0],
    [0.35, 42.0, 0.8, 0.7, 320.0],
    [0.48, 24.0, 1.1, 0.2, 160.0],
    [0.62, 38.0, 0.9, 0.8, 280.0],
    [0.75, 20.0, 1.4, 0.3, 190.0],
    [0.88, 48.0, 0.7, 0.5, 330.0],
    [0.05, 26.0, 1.2, 0.9, 200.0],
    [0.55, 16.0, 1.5, 0.6, 290.0],
    [0.92, 28.0, 1.0, 0.0, 170.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft Bottom Cloud Waves
    final wavePaint = Paint()
      ..color = const Color(0xFFF3E5F5).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(0, size.height);
    wavePath.lineTo(0, size.height - 80);
    wavePath.quadraticBezierTo(size.width * 0.25, size.height - 110, size.width * 0.5, size.height - 80);
    wavePath.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 75);
    wavePath.lineTo(size.width, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. Floating Soap Bubbles with Reflections
    for (int i = 0; i < _bubbleSeeds.length; i++) {
      final seed = _bubbleSeeds[i];
      final xBase = seed[0] * size.width;
      final radius = seed[1];
      final speed = seed[2];
      final phase = seed[3];
      final hue = seed[4];

      // Vertical floating progress (Bottom to Top loop)
      final t = (progress * speed + phase) % 1.0;
      final y = size.height - (t * (size.height + radius * 3)) + radius;

      // Gentle horizontal sway
      final x = xBase + sin(progress * pi * 2 * speed + phase * 10) * 22;

      // Alpha fade in from bottom, fade out at very top
      final alpha = (sin(t * pi)).clamp(0.0, 1.0) * 0.55;

      // Bubble Body (Soft Pastel Tint)
      final bubbleColor = HSVColor.fromAHSV(alpha, hue, 0.35, 0.98).toColor();
      final bodyPaint = Paint()
        ..color = bubbleColor.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, bodyPaint);

      // Bubble Ring Stroke
      final strokePaint = Paint()
        ..color = bubbleColor.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(x, y), radius, strokePaint);

      // Cute Bubble Crescent Highlight (Top-Left 3D Shine)
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - radius * 0.35, y - radius * 0.38),
          width: radius * 0.45,
          height: radius * 0.28,
        ),
        shinePaint,
      );

      // Small secondary shine dot (Bottom-Right)
      canvas.drawCircle(
        Offset(x + radius * 0.4, y + radius * 0.4),
        radius * 0.12,
        shinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


