part of '../tooth_brushing_game.dart';

class _FoamAndParticlePainter extends CustomPainter {
  final List<_FoamParticle> foams;
  final List<_Sparkle> sparkles;

  _FoamAndParticlePainter({required this.foams, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Foams (Extra Glossy Iridescent Bubbles)
    for (final foam in foams) {
      final paint = Paint()
        ..color = foam.color.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(foam.pos, foam.radius, paint);

      // Outer rim shine
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(foam.pos, foam.radius, rimPaint);

      // Specular shine dot
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(foam.pos - Offset(foam.radius * 0.35, foam.radius * 0.35), foam.radius * 0.28, shinePaint);
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
    // 1. Soft Pastel Ceramic Bathroom Wall Tiles (Subtle Grid)
    final tilePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const tileSize = 44.0;
    for (double y = 0; y < size.height - 70; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), tilePaint);
    }
    for (double x = 0; x < size.width; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height - 70), tilePaint);
    }

    // 2. Soft Morning Sunbeam Rays (Warm Golden Ambient Light)
    final sunbeamPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.1, 0),
        Offset(size.width * 0.9, size.height * 0.8),
        [
          Colors.amber.withValues(alpha: 0.12),
          Colors.orange.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    final sunbeamPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.45, 0)
      ..lineTo(size.width, size.height * 0.6)
      ..lineTo(size.width * 0.3, size.height * 0.8)
      ..close();
    canvas.drawPath(sunbeamPath, sunbeamPaint);

    // 3. Cute Mint & Wood Vanity Shelf (세면대 선반) at Bottom
    final shelfPaint = Paint()
      ..color = const Color(0xFFE0F2F1).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final shelfPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 65)
      ..quadraticBezierTo(size.width * 0.5, size.height - 85, size.width, size.height - 65)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(shelfPath, shelfPaint);

    // Shelf top highlight rim
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final rimPath = Path()
      ..moveTo(0, size.height - 65)
      ..quadraticBezierTo(size.width * 0.5, size.height - 85, size.width, size.height - 65);
    canvas.drawPath(rimPath, rimPaint);

    // 4. Floating Soap Bubbles with Iridescent Reflections
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
      final alpha = (sin(t * pi)).clamp(0.0, 1.0) * 0.65;

      // Bubble Body (Soft Pastel Tint)
      final bubbleColor = HSVColor.fromAHSV(alpha, hue, 0.35, 0.98).toColor();
      final bodyPaint = Paint()
        ..color = bubbleColor.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, bodyPaint);

      // Bubble Ring Stroke
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
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

class _TridentPainter extends CustomPainter {
  const _TridentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final goldFill = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.fill;

    // Staff
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.35), Offset(size.width * 0.5, size.height), goldPaint);

    // Prongs arch
    final prongsPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.38, size.width * 0.5, size.height * 0.38)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.38, size.width * 0.85, size.height * 0.1);
    canvas.drawPath(prongsPath, goldPaint);

    // Center prong
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height * 0.38), goldPaint);

    // Tips
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.08), 1.5, goldFill);
    canvas.drawCircle(Offset(size.width * 0.5, 0), 1.5, goldFill);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.08), 1.5, goldFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BunnySmileArcPainter extends CustomPainter {
  final bool isLeft;
  const _BunnySmileArcPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isLeft) {
      path.moveTo(size.width, 2);
      path.quadraticBezierTo(size.width * 0.4, size.height, 0, size.height * 0.35);
    } else {
      path.moveTo(0, 2);
      path.quadraticBezierTo(size.width * 0.6, size.height, size.width, size.height * 0.35);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



