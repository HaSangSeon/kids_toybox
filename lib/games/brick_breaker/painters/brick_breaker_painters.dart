part of '../brick_breaker_game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background Painter — 아케이드 스타 & 파동 배경
// ─────────────────────────────────────────────────────────────────────────────

class _ArcadeBgPainter extends CustomPainter {
  final double time;
  _ArcadeBgPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 격자 (Grid) — subtle
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 0.8;
    const step = 36.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. 별빛 반짝임
    final starRng = Random(42);
    for (int i = 0; i < 55; i++) {
      final sx = starRng.nextDouble() * w;
      final sy = starRng.nextDouble() * h;
      final twinkle = (sin(time * (1.5 + i * 0.12) + i) * 0.5 + 0.5);
      final r = 1.0 + twinkle * 2.0;
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()..color = Colors.white.withValues(alpha: 0.2 + twinkle * 0.5),
      );
    }

    // 3. 무지개 파동 링 (중앙 아래)
    for (int i = 0; i < 4; i++) {
      final radius = 40.0 + i * 55.0 + (time * 30) % 55;
      final colors = [
        const Color(0xFF7C4DFF),
        const Color(0xFF2979FF),
        const Color(0xFF00BCD4),
        const Color(0xFF00E676),
      ];
      final opacity = (1.0 - (radius / 280)).clamp(0.0, 1.0) * 0.18;
      canvas.drawCircle(
        Offset(w / 2, h * 0.6),
        radius,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // 4. 반짝이 파티클 (느리게 떠다니는 빛)
    final floatRng = Random(99);
    for (int i = 0; i < 18; i++) {
      final baseX = floatRng.nextDouble() * w;
      final baseY = floatRng.nextDouble() * h;
      final ox = sin(time * 0.5 + i) * 12;
      final oy = cos(time * 0.4 + i * 1.3) * 12;
      final bright = (sin(time * 1.2 + i * 2.1) * 0.5 + 0.5);
      final floatColors = [
        const Color(0xFFFFB300),
        const Color(0xFFFF6B9D),
        const Color(0xFF7C4DFF),
        const Color(0xFF00E5FF),
      ];
      canvas.drawCircle(
        Offset(baseX + ox, baseY + oy),
        2.5 + bright * 2.5,
        Paint()..color = floatColors[i % floatColors.length].withValues(alpha: 0.15 + bright * 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_ArcadeBgPainter old) => old.time != time;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle + Score Popup Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<BrickParticle> particles;
  final List<ScorePopup> popups;

  _ParticlePainter({required this.particles, required this.popups});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }

    // Score popups — draw text
    for (final pop in popups) {
      final tp = TextPainter(
        text: TextSpan(
          text: pop.text,
          style: TextStyle(
            color: pop.color.withValues(alpha: pop.opacity.clamp(0.0, 1.0)),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pop.x - tp.width / 2, pop.y));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
