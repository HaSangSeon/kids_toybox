part of '../hidden_object_game.dart';

class _ForestBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _ForestBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Glowing Sun
    final Paint sunPaint = Paint()
      ..color = const Color(0xFFFFF176).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final double sunBreathing = sin(ambientVal * 3.14159 * 2) * 5;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 60 + sunBreathing, sunPaint);

    // Soft Hills
    final Paint hillPaint1 = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final Path hill1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.32, size.width * 0.6, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.48, size.width, size.height * 0.38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill1, hillPaint1);

    final Paint hillPaint2 = Paint()
      ..color = const Color(0xFF66BB6A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final Path hill2 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.48, size.width * 0.75, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.62, size.width, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill2, hillPaint2);

    // Fireflies (Floating Particles)
    final Paint fireflyPaint = Paint()
      ..color = const Color(0xFFFFF59D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (int i = 0; i < 15; i++) {
      double px = (i * 0.23 + ambientVal * (i % 2 == 0 ? 1 : -1)) % 1.0;
      double py = (i * 0.37 - ambientVal * 0.5) % 1.0;
      if (px < 0) px += 1.0;
      if (py < 0) py += 1.0;
      
      double wave = sin(ambientVal * 3.14159 * 4 + i) * 15.0;
      canvas.drawCircle(Offset(size.width * px + wave, size.height * (0.3 + py * 0.7)), 3 + (i % 3).toDouble(), fireflyPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _ForestBackgroundPainter oldDelegate) => true;
}

// 🌊 Level 2: 바닷속 모험 배경 렌더러 (에메랄드 해저와 빛 내림, 비눗방울)
class _OceanBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _OceanBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF80DEEA), Color(0xFF26C6DA), Color(0xFF0097A7), Color(0xFF006064)],
      ).createShader(rect);
    canvas.drawRect(rect, oceanPaint);

    // Swaying Sunlight Rays
    final double raySway = sin(ambientVal * 3.14159 * 2) * 30;
    final Paint rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final Path ray = Path()
      ..moveTo(size.width * 0.1 + raySway, 0)
      ..lineTo(size.width * 0.35 + raySway, 0)
      ..lineTo(size.width * 0.65 - raySway, size.height)
      ..lineTo(size.width * 0.2 - raySway, size.height)
      ..close();
    canvas.drawPath(ray, rayPaint);

    // Sea floor
    final Paint floorPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85);
    final Path floor = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width, size.height * 0.88)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, floorPaint);

    // Floating Bubbles
    final Paint bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      double px = (i * 0.31) % 1.0;
      double py = (1.0 - (ambientVal + i * 0.1) % 1.0);
      double wave = sin(ambientVal * 3.14159 * 6 + i) * 20.0;
      canvas.drawCircle(Offset(size.width * px + wave, size.height * py), 5 + (i % 4) * 2, bubblePaint);
    }
  }
  @override
  bool shouldRepaint(covariant _OceanBackgroundPainter oldDelegate) => true;
}

// 🚀 Level 3: 우주 탐사 배경 렌더러 (오로라 성운 & 은하수)
class _SpaceBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _SpaceBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint spacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C), Color(0xFF0D47A1)],
      ).createShader(rect);
    canvas.drawRect(rect, spacePaint);

    // Nebula Glow (Breathing)
    final double nebulaBreath = sin(ambientVal * 3.14159 * 2) * 20;
    final Paint nebula = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 120 + nebulaBreath, nebula);
    
    final Paint nebula2 = Paint()
      ..color = const Color(0xFF42A5F5).withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 150 - nebulaBreath, nebula2);

    // Twinkling Stars
    final Paint starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 30; i++) {
      double px = (i * 0.17) % 1.0;
      double py = (i * 0.23) % 1.0;
      double twinkle = (sin(ambientVal * 3.14159 * 8 + i) + 1) / 2;
      starPaint.color = Colors.white.withValues(alpha: 0.2 + 0.8 * twinkle);
      canvas.drawCircle(Offset(size.width * px, size.height * py), 1.5 + (i % 2), starPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _SpaceBackgroundPainter oldDelegate) => true;
}
// ─────────────────────────────────────────────
// Hidden Item Widget with Wiggle & Hint Glow
// ─────────────────────────────────────────────

class _OwlPainter extends CustomPainter {
  final double timeMs;
  _OwlPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.32;

    // Body Paint
    final Paint bodyPaint = Paint()..color = const Color(0xFF8D6E63);
    final Paint bellyPaint = Paint()..color = const Color(0xFFFFF8E1);
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black87;
    final Paint beakPaint = Paint()..color = const Color(0xFFFFB300);
    final Paint wingPaint = Paint()..color = const Color(0xFF6D4C41);

    // 1. Wings (Flapping Wings)
    final double flap = sin(timeMs * 16.0) * 0.45; // Wing flap angle

    // Left Wing
    canvas.save();
    canvas.translate(cx - r * 0.7, cy - r * 0.2);
    canvas.rotate(-0.3 - flap);
    final Path leftWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(-r * 1.1, -r * 0.4, -r * 1.2, r * 0.8, 0, r * 0.6)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    canvas.restore();

    // Right Wing
    canvas.save();
    canvas.translate(cx + r * 0.7, cy - r * 0.2);
    canvas.rotate(0.3 + flap);
    final Path rightWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(r * 1.1, -r * 0.4, r * 1.2, r * 0.8, 0, r * 0.6)
      ..close();
    canvas.drawPath(rightWing, wingPaint);
    canvas.restore();

    // 2. Main Body
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);
    canvas.drawCircle(Offset(cx, cy + r * 0.2), r * 0.65, bellyPaint);

    // 3. Feet
    final Paint feetPaint = Paint()..color = const Color(0xFFFF8F00)..strokeWidth = 3;
    canvas.drawLine(Offset(cx - r * 0.3, cy + r), Offset(cx - r * 0.3, cy + r * 1.25), feetPaint);
    canvas.drawLine(Offset(cx + r * 0.3, cy + r), Offset(cx + r * 0.3, cy + r * 1.25), feetPaint);

    // 4. Big Eyes
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.25), r * 0.38, eyeWhite);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.25), r * 0.38, eyeWhite);
    canvas.drawCircle(Offset(cx - r * 0.32, cy - r * 0.25), r * 0.18, eyePupil);
    canvas.drawCircle(Offset(cx + r * 0.38, cy - r * 0.25), r * 0.18, eyePupil);

    // Eye shines
    canvas.drawCircle(Offset(cx - r * 0.38, cy - r * 0.32), r * 0.06, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.32, cy - r * 0.32), r * 0.06, Paint()..color = Colors.white);

    // 5. Beak
    final Path beak = Path()
      ..moveTo(cx - r * 0.15, cy - r * 0.05)
      ..lineTo(cx + r * 0.15, cy - r * 0.05)
      ..lineTo(cx, cy + r * 0.22)
      ..close();
    canvas.drawPath(beak, beakPaint);
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) => true;
}

// ── 🐰 Rabbit Painter (Full Body + 4 Hopping Legs + Long Ears + Tail) ───────
class _RabbitPainter extends CustomPainter {
  final double timeMs;
  _RabbitPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.25;

    final Paint bodyPaint = Paint()..color = const Color(0xFFFAFAFA);
    final Paint earInner = Paint()..color = const Color(0xFFFF80AB);
    final Paint eyePaint = Paint()..color = const Color(0xFF37474F);
    final Paint pinkNose = Paint()..color = const Color(0xFFFF4081);

    final double hop = (sin(timeMs * 10.0)).abs() * r * 0.25;
    final double legAngle = sin(timeMs * 10.0) * 0.4;

    // 1. Long Ears (Ear Wiggle)
    final double earWiggle = sin(timeMs * 8.0) * 0.15;
    
    // Left Ear
    canvas.save();
    canvas.translate(cx - r * 0.35, cy - r * 0.6);
    canvas.rotate(-0.15 + earWiggle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, -r * 1.5, r * 0.4, r * 1.6), Radius.circular(r * 0.2)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.1, -r * 1.3, r * 0.2, r * 1.2), Radius.circular(r * 0.1)), earInner);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(cx + r * 0.35, cy - r * 0.6);
    canvas.rotate(0.15 - earWiggle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, -r * 1.5, r * 0.4, r * 1.6), Radius.circular(r * 0.2)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.1, -r * 1.3, r * 0.2, r * 1.2), Radius.circular(r * 0.1)), earInner);
    canvas.restore();

    // 2. Fluffy Tail
    canvas.drawCircle(Offset(cx + r * 0.9, cy + r * 0.4), r * 0.3, bodyPaint);

    // 3. 4 Hopping Legs (Animated Legs)
    final Paint legPaint = Paint()..color = const Color(0xFFF5F5F5);
    
    // Front Legs
    canvas.save();
    canvas.translate(cx - r * 0.4, cy + r * 0.6);
    canvas.rotate(legAngle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.15, 0, r * 0.3, r * 0.7), Radius.circular(r * 0.15)), legPaint);
    canvas.restore();

    // Back Legs
    canvas.save();
    canvas.translate(cx + r * 0.4, cy + r * 0.6);
    canvas.rotate(-legAngle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, 0, r * 0.4, r * 0.7), Radius.circular(r * 0.2)), legPaint);
    canvas.restore();

    // 4. Body & Head
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.3 - hop), width: r * 1.5, height: r * 1.3), bodyPaint);
    canvas.drawCircle(Offset(cx, cy - r * 0.2 - hop), r * 0.85, bodyPaint);

    // 5. Cute Eyes & Nose
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3 - hop), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.3 - hop), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx, cy - r * 0.15 - hop), r * 0.09, pinkNose);
  }

  @override
  bool shouldRepaint(covariant _RabbitPainter oldDelegate) => true;
}

// ── 🦊 Fox Painter (Full Body + 4 Walking Legs + Fluffy Tail) ───────────────
class _FoxPainter extends CustomPainter {
  final double timeMs;
  _FoxPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.25;

    final Paint foxOrange = Paint()..color = const Color(0xFFFF6D00);
    final Paint foxWhite = Paint()..color = Colors.white;
    final Paint foxBlack = Paint()..color = const Color(0xFF263238);

    final double legAngle = sin(timeMs * 12.0) * 0.35;
    final double tailWiggle = sin(timeMs * 6.0) * 0.3;

    // 1. Fluffy Tail
    canvas.save();
    canvas.translate(cx + r * 0.8, cy + r * 0.2);
    canvas.rotate(0.3 + tailWiggle);
    final Path tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(r * 1.2, -r * 0.5, r * 1.4, r * 0.6)
      ..quadraticBezierTo(r * 0.6, r * 1.1, 0, 0)
      ..close();
    canvas.drawPath(tailPath, foxOrange);
    canvas.drawCircle(Offset(r * 1.2, r * 0.2), r * 0.35, foxWhite);
    canvas.restore();

    // 2. 4 Walking Legs
    canvas.save();
    canvas.translate(cx - r * 0.4, cy + r * 0.5);
    canvas.rotate(legAngle);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, 0, r * 0.2, r * 0.8), foxOrange);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, r * 0.5, r * 0.2, r * 0.3), foxBlack);
    canvas.restore();

    canvas.save();
    canvas.translate(cx + r * 0.4, cy + r * 0.5);
    canvas.rotate(-legAngle);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, 0, r * 0.2, r * 0.8), foxOrange);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, r * 0.5, r * 0.2, r * 0.3), foxBlack);
    canvas.restore();

    // 3. Body & Head
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.2), width: r * 1.6, height: r * 1.1), foxOrange);

    // Fox Triangular Face
    final Path face = Path()
      ..moveTo(cx - r * 0.8, cy - r * 0.5)
      ..lineTo(cx + r * 0.8, cy - r * 0.5)
      ..lineTo(cx, cy + r * 0.4)
      ..close();
    canvas.drawPath(face, foxOrange);

    // White Cheeks
    final Path cheeks = Path()
      ..moveTo(cx - r * 0.7, cy - r * 0.2)
      ..lineTo(cx + r * 0.7, cy - r * 0.2)
      ..lineTo(cx, cy + r * 0.4)
      ..close();
    canvas.drawPath(cheeks, foxWhite);

    // Ears
    canvas.drawCircle(Offset(cx - r * 0.6, cy - r * 0.7), r * 0.3, foxBlack);
    canvas.drawCircle(Offset(cx + r * 0.6, cy - r * 0.7), r * 0.3, foxBlack);

    // Nose & Eyes
    canvas.drawCircle(Offset(cx, cy + r * 0.35), r * 0.12, foxBlack);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.2), r * 0.1, foxBlack);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.2), r * 0.1, foxBlack);
  }

  @override
  bool shouldRepaint(covariant _FoxPainter oldDelegate) => true;
}

// ── 🐠 Fish Painter (Wiggling Tail Fin + Body + Eye) ────────────────────────
class _FishPainter extends CustomPainter {
  final double timeMs;
  final String emoji;
  _FishPainter({required this.timeMs, required this.emoji});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.3;

    final Color fishColor = emoji == '🐬'
        ? const Color(0xFF29B6F6)
        : emoji == '🐳'
            ? const Color(0xFF0288D1)
            : const Color(0xFFFF7043);

    final Paint bodyPaint = Paint()..color = fishColor;
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black87;

    final double tailWiggle = sin(timeMs * 14.0) * 0.35; // Wiggling tail angle

    // 1. Wiggling Tail Fin
    canvas.save();
    canvas.translate(cx + r * 0.8, cy);
    canvas.rotate(tailWiggle);
    final Path tail = Path()
      ..moveTo(0, 0)
      ..lineTo(r * 0.8, -r * 0.6)
      ..quadraticBezierTo(r * 0.5, 0, r * 0.8, r * 0.6)
      ..close();
    canvas.drawPath(tail, bodyPaint);
    canvas.restore();

    // 2. Fish Body
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 1.3), bodyPaint);

    // 3. Eye
    canvas.drawCircle(Offset(cx - r * 0.4, cy - r * 0.2), r * 0.22, eyeWhite);
    canvas.drawCircle(Offset(cx - r * 0.45, cy - r * 0.2), r * 0.11, eyePupil);
  }

  @override
  bool shouldRepaint(covariant _FishPainter oldDelegate) => true;
}

// 🦕 Theme 4: 공룡 섬 배경 렌더러
class _DinoBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _DinoBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF66BB6A)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Volcano Silhouette in background (Breathing Glow)
    final double heatWobble = sin(ambientVal * 3.14159 * 4) * 5;
    final Paint volcanoPaint = Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.5);
    final Path vPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.45)
      ..lineTo(size.width * 0.55 + heatWobble, size.height * 0.28)
      ..lineTo(size.width * 0.65 - heatWobble, size.height * 0.28)
      ..lineTo(size.width * 0.8, size.height * 0.45)
      ..close();
    canvas.drawPath(vPath, volcanoPaint);
    
    // Volcano Magma Glow
    final Paint magmaGlow = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.4 + 0.2 * sin(ambientVal * 3.14159 * 6))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.28), 30, magmaGlow);

    // Jungle Hills
    final Paint hillPaint = Paint()..color = const Color(0xFF2E7D32);
    final Path hill = Path()
      ..moveTo(0, size.height * 0.50)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.42, size.width * 0.7, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.56, size.width, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, hillPaint);
    
    // Ash particles
    final Paint ashPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    for (int i = 0; i < 20; i++) {
      double px = (i * 0.41 - ambientVal * 0.3) % 1.0;
      double py = (i * 0.17 + ambientVal * 0.2) % 1.0;
      if (px < 0) px += 1.0;
      if (py < 0) py += 1.0;
      canvas.drawCircle(Offset(size.width * px, size.height * py), 2 + (i % 3).toDouble(), ashPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _DinoBackgroundPainter oldDelegate) => true;
}

// 🍭 Theme 5: 과자 나라 배경 렌더러
class _CandyBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _CandyBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFF48FB1)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Candy Cotton Hills (Breathing)
    final double breath = sin(ambientVal * 3.14159 * 2) * 10;
    final Paint hill1 = Paint()
      ..color = const Color(0xFFEC407A).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.55), 180 + breath, hill1);

    final Paint hill2 = Paint()
      ..color = const Color(0xFFD81B60).withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.58), 200 - breath, hill2);
    
    // Sparkles
    final Paint sparkle = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 15; i++) {
      double px = (i * 0.27) % 1.0;
      double py = (i * 0.39) % 1.0;
      double twinkle = (sin(ambientVal * 3.14159 * 6 + i) + 1) / 2;
      sparkle.color = Colors.white.withValues(alpha: 0.2 + 0.6 * twinkle);
      canvas.drawCircle(Offset(size.width * px, size.height * py), 3 + (i % 3), sparkle);
    }
  }
  @override
  bool shouldRepaint(covariant _CandyBackgroundPainter oldDelegate) => true;
}

// 🚜 Theme 6: 신나는 농장 배경 렌더러
class _FarmBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _FarmBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFD54F)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Golden Farm Hills
    final Paint hill = Paint()..color = const Color(0xFFF57C00);
    final Path path = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.44, size.width * 0.8, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);
    
    // Dandelions (Pollen) floating in wind
    final Paint pollenPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    for (int i = 0; i < 20; i++) {
      double px = (i * 0.33 + ambientVal * 0.4) % 1.0;
      double py = (i * 0.21 - ambientVal * 0.1) % 1.0;
      double wave = sin(ambientVal * 3.14159 * 4 + i) * 10.0;
      canvas.drawCircle(Offset(size.width * px + wave, size.height * py), 2 + (i % 2).toDouble(), pollenPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _FarmBackgroundPainter oldDelegate) => true;
}

// 🏰 Theme 7: 장난감 성 배경 렌더러
class _CastleBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _CastleBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9), Color(0xFF9FA8DA)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Castle Silhouette with Glow
    final Paint castle = Paint()
      ..color = const Color(0xFF3F51B5).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, size.height * 0.35, size.width * 0.3, size.height * 0.3), castle);
    
    // Magical Aurora / Glow
    final double breath = sin(ambientVal * 3.14159 * 2) * 10;
    final Paint aurora = Paint()
      ..color = const Color(0xFF7E57C2).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 100 + breath, aurora);
    
    // Fireworks/Sparkles
    final Paint spark = Paint()..color = const Color(0xFFFFEB3B);
    for (int i = 0; i < 12; i++) {
      double px = (i * 0.47) % 1.0;
      double py = (i * 0.13) % 1.0;
      double twinkle = (sin(ambientVal * 3.14159 * 10 + i) + 1) / 2;
      spark.color = const Color(0xFFFFEB3B).withValues(alpha: 0.2 + 0.8 * twinkle);
      canvas.drawCircle(Offset(size.width * px, size.height * py), 2 + (i % 3), spark);
    }
  }
  @override
  bool shouldRepaint(covariant _CastleBackgroundPainter oldDelegate) => true;
}

// 🎠 Theme 8: 놀이공원 배경 렌더러
class _ParkBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _ParkBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7), Color(0xFFCE93D8)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Ferris Wheel Silhouette
    final double rotation = ambientVal * 3.14159 * 2;
    final Paint park = Paint()
      ..color = const Color(0xFF8E24AA).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
    canvas.save();
    canvas.translate(size.width * 0.8, size.height * 0.4);
    canvas.rotate(rotation);
    canvas.drawCircle(Offset.zero, 80, park);
    // spokes
    for(int i=0; i<6; i++) {
      canvas.drawLine(Offset.zero, Offset(80 * cos(i * 3.14159 / 3), 80 * sin(i * 3.14159 / 3)), park);
    }
    canvas.restore();
    
    // Floating Balloons
    final Paint balloon = Paint()..color = const Color(0xFFFF4081).withValues(alpha: 0.6);
    for (int i = 0; i < 8; i++) {
      double px = (i * 0.29) % 1.0;
      double py = (1.0 - (ambientVal * 0.5 + i * 0.1) % 1.0);
      double wave = sin(ambientVal * 3.14159 * 4 + i) * 15.0;
      
      balloon.color = i % 2 == 0 ? const Color(0xFFFF4081).withValues(alpha: 0.6) : const Color(0xFF03A9F4).withValues(alpha: 0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset(size.width * px + wave, size.height * py), width: 16, height: 22), balloon);
    }
  }
  @override
  bool shouldRepaint(covariant _ParkBackgroundPainter oldDelegate) => true;
}

// ⛄ Theme 9: 눈송이 마을 배경 렌더러
class _WinterBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _WinterBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE1F5FE), Color(0xFF81D4FA), Color(0xFF03A9F4)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Snow Hills
    final Paint hill = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final Path path = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.44, size.width * 0.6, size.height * 0.54)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.60, size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, hill);
    
    // Falling Snowflakes
    final Paint snowPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 25; i++) {
      double px = (i * 0.23 + ambientVal * 0.1) % 1.0;
      double py = (i * 0.37 + ambientVal * 0.4) % 1.0;
      double wave = sin(ambientVal * 3.14159 * 4 + i) * 10.0;
      canvas.drawCircle(Offset(size.width * px + wave, size.height * py), 1.5 + (i % 3), snowPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _WinterBackgroundPainter oldDelegate) => true;
}

// 👻 Theme 10: 유령의 집 배경 렌더러
class _SpookyBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _SpookyBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF311B92), Color(0xFF4527A0), Color(0xFF1B5E20)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Glowing Moon
    final Paint moon = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 50, moon);

    // Creepy Fog
    final double fogBreath = sin(ambientVal * 3.14159 * 2) * 10;
    final Paint fog = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), 150 + fogBreath, fog);
    
    // Floating Ghost Particles
    final Paint ghost = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (int i = 0; i < 8; i++) {
      double px = (i * 0.41) % 1.0;
      double py = (i * 0.17 + ambientVal * 0.2) % 1.0;
      double wave = sin(ambientVal * 3.14159 * 6 + i) * 15.0;
      canvas.drawCircle(Offset(size.width * px + wave, size.height * py), 4 + (i % 3), ghost);
    }
  }
  @override
  bool shouldRepaint(covariant _SpookyBackgroundPainter oldDelegate) => true;
}

// 🦁 Theme 11: 정글 사파리 배경 렌더러
class _JungleBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _JungleBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC8E6C9), Color(0xFFAED581), Color(0xFF689F38)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Lush Canopy
    final double canopySway = sin(ambientVal * 3.14159 * 2) * 8;
    final Paint canopy = Paint()
      ..color = const Color(0xFF33691E).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(size.width * 0.1 + canopySway, 0), 120, canopy);
    canvas.drawCircle(Offset(size.width * 0.9 - canopySway, 0), 150, canopy);

    // Falling Tropical Leaves
    final Paint leaf = Paint()..color = const Color(0xFF558B2F).withValues(alpha: 0.8);
    for (int i = 0; i < 15; i++) {
      double px = (i * 0.29 + ambientVal * 0.3) % 1.0;
      double py = (i * 0.11 + ambientVal * 0.5) % 1.0;
      double rot = (ambientVal * 10 + i) % (3.14159 * 2);
      
      canvas.save();
      canvas.translate(size.width * px, size.height * py);
      canvas.rotate(rot);
      canvas.drawOval(const Rect.fromLTWH(-5, -2, 10, 4), leaf);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant _JungleBackgroundPainter oldDelegate) => true;
}

// 🧚 Theme 12: 마법의 숲 배경 렌더러
class _MagicForestBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _MagicForestBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8BBD0), Color(0xFFF06292), Color(0xFFAD1457)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Magical Mushroom Glow
    final double magicPulse = sin(ambientVal * 3.14159 * 4) * 10;
    final Paint mushroomGlow = Paint()
      ..color = const Color(0xFFCE93D8).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 60 + magicPulse, mushroomGlow);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.6), 80 - magicPulse, mushroomGlow);

    // Pixie Dust
    final Paint dust = Paint()..color = const Color(0xFFFFFF8D);
    for (int i = 0; i < 30; i++) {
      double px = (i * 0.13 + ambientVal * 0.2) % 1.0;
      double py = (i * 0.37 - ambientVal * 0.3) % 1.0;
      if (px < 0) px += 1.0;
      if (py < 0) py += 1.0;
      double wave = sin(ambientVal * 3.14159 * 8 + i) * 15.0;
      double twinkle = (sin(ambientVal * 3.14159 * 12 + i) + 1) / 2;
      
      dust.color = const Color(0xFFFFFF8D).withValues(alpha: 0.3 + 0.7 * twinkle);
      canvas.drawCircle(Offset(size.width * px + wave, size.height * py), 1 + (i % 2).toDouble(), dust);
    }
  }
  @override
  bool shouldRepaint(covariant _MagicForestBackgroundPainter oldDelegate) => true;
}
