part of '../balloon_pop_game.dart';

class _GamePainter extends CustomPainter {
  final GameEngine engine;

  _GamePainter({required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    // Draw Balloons
    for (var balloon in engine.balloons) {
      if (balloon.isPopped) continue;
      final centerX = balloon.currentX * size.width;
      final centerY = balloon.y * size.height;
      _drawBalloon(canvas, centerX, centerY, balloon.size, balloon.color, balloon.type);
    }

    // Draw Freeze Overlay if frozen
    if (engine.freezeTimer > 0) {
      final freezePaint = Paint()
        ..color = const Color(0x3340C4FF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, freezePaint);

      // Draw thin frosty frame
      final framePaint = Paint()
        ..color = const Color(0x8080DEEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawRect(Offset.zero & size, framePaint);
      
      // Draw snowflake indicator at the top
      final textSpan = TextSpan(
        text: '❄️ 시간 천천히! (${engine.freezeTimer.toStringAsFixed(1)}초)',
        style: GoogleFonts.jua(fontSize: 20, color: Colors.blue.shade800),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 210));
    }

    // Draw Particles
    for (var p in engine.particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size / 2, paint);
    }

    // Draw Floating Texts
    for (var t in engine.floatingTexts) {
      final tx = t.x * size.width;
      final ty = t.y * size.height;
      
      final textSpan = TextSpan(
        text: t.text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: KidsTheme.orange.withValues(alpha: t.life.clamp(0.0, 1.0)),
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: t.life.clamp(0.0, 1.0)), blurRadius: 4, offset: const Offset(0, 0)),
            Shadow(color: Colors.white.withValues(alpha: t.life.clamp(0.0, 1.0)), blurRadius: 4, offset: const Offset(1, 1)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(tx - (textPainter.width / 2), ty - (textPainter.height / 2)));
    }
  }

  void _drawBalloon(Canvas canvas, double cx, double cy, double bSize, Color color, BalloonType type) {
    final width = bSize;
    final height = bSize * 1.3;
    final top = cy - height / 2;
    final left = cx - width / 2;

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    
    // Borders based on type
    Color borderColor = KidsTheme.borderDark;
    double borderWidth = 3;
    if (type == BalloonType.fast) {
      borderColor = const Color(0xFFFFA000);
      borderWidth = 5;
    } else if (type == BalloonType.bomb) {
      borderColor = const Color(0xFFD50000);
      borderWidth = 4.5;
    } else if (type == BalloonType.freeze) {
      borderColor = const Color(0xFF00B0FF);
      borderWidth = 4;
    } else if (type == BalloonType.spiky) {
      borderColor = const Color(0xFF4A148C);
      borderWidth = 4;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.fill;

    // Glowing auras
    if (type == BalloonType.fast) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9;
      canvas.drawOval(Rect.fromLTWH(left - 2, top - 2, width + 4, (width * 1.1) + 4), glowPaint);
    } else if (type == BalloonType.bomb) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawOval(Rect.fromLTWH(left - 1, top - 1, width + 2, (width * 1.1) + 2), glowPaint);
    } else if (type == BalloonType.freeze) {
      final glowPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawOval(Rect.fromLTWH(left - 1, top - 1, width + 2, (width * 1.1) + 2), glowPaint);
    }

    final rect = Rect.fromLTWH(left, top, width, width * 1.1);
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, borderPaint);

    final highlightRect = Rect.fromLTWH(left + width * 0.2, top + width * 0.15, width * 0.25, width * 0.35);
    canvas.drawOval(highlightRect, highlightPaint);

    // Knot
    final path = Path();
    final knotY = top + width * 1.1;
    final knotWidth = width * 0.15;
    path.moveTo(cx, knotY);
    path.lineTo(cx - knotWidth, knotY + width * 0.1);
    path.lineTo(cx + knotWidth, knotY + width * 0.1);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // String
    final stringPaint = Paint()..color = KidsTheme.borderDark..style = PaintingStyle.stroke..strokeWidth = 2;
    final stringPath = Path();
    stringPath.moveTo(cx, knotY + width * 0.1);
    stringPath.cubicTo(cx - 10, knotY + width * 0.3, cx + 10, knotY + width * 0.5, cx, cy + height / 2);
    canvas.drawPath(stringPath, stringPaint);

    // Draw indicators inside balloon
    if (type == BalloonType.fast) {
      final lightningPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final lp = Path();
      final double lx = cx;
      final double ly = cy - 3;
      lp.moveTo(lx + 2, ly - 12);
      lp.lineTo(lx - 8, ly + 2);
      lp.lineTo(lx - 2, ly + 2);
      lp.lineTo(lx - 4, ly + 12);
      lp.lineTo(lx + 8, ly - 2);
      lp.lineTo(lx + 2, ly - 2);
      lp.close();
      canvas.drawPath(lp, lightningPaint);
      canvas.drawPath(lp, Paint()..color = const Color(0xFFFFA000)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    } else if (type == BalloonType.bomb) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '💣', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    } else if (type == BalloonType.freeze) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '❄️', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    } else if (type == BalloonType.spiky) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '🌟', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Engine dictates repaint

  void _drawBackground(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rainbow
    final rainbowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final colors = [
      const Color(0xFFFF8A80),
      const Color(0xFFFFD180),
      const Color(0xFFFFFF8D),
      const Color(0xFFA7FFEB),
      const Color(0xFF80D8FF),
      const Color(0xFFEA80FC),
    ];
    final center = Offset(w * 0.5, h * 0.6);
    for (int i = 0; i < colors.length; i++) {
      final r = w * 0.45 - i * 8;
      if (r > 0) {
        rainbowPaint.color = colors[i].withValues(alpha: 0.15);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: r * 2, height: r * 1.1),
          pi,
          pi,
          false,
          rainbowPaint,
        );
      }
    }

    // 2. Smiling Sun ☀️
    final double sunScale = 1.0 + sin(engine.timeCounter * 1.5) * 0.05;
    final double sunX = w * 0.85;
    final double sunY = 160;
    
    // Draw sun rays/glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 45 * sunScale, glowPaint);

    final sunPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 30 * sunScale, sunPaint);
    
    // Sun smiley face (eye, eye, smile)
    final facePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX - 8 * sunScale, sunY - 5 * sunScale), 3, facePaint);
    canvas.drawCircle(Offset(sunX + 8 * sunScale, sunY - 5 * sunScale), 3, facePaint);
    
    final smilePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(sunX, sunY + 3 * sunScale), width: 14 * sunScale, height: 10 * sunScale),
      0,
      pi,
      false,
      smilePaint,
    );

    // 3. Clouds moving horizontally
    _drawCloud(canvas, Offset((w * 0.15 + engine.timeCounter * 10) % (w + 160) - 80, 240), 1.0);
    _drawCloud(canvas, Offset((w * 0.65 + engine.timeCounter * 6) % (w + 180) - 90, 310), 0.85);

    // 4. Flying Birds
    final double bird1X = (w * 0.9 - engine.timeCounter * 22) % (w + 80) - 40;
    final double bird1Y = 220 + sin(engine.timeCounter * 2.5) * 12;
    canvas.save();
    canvas.translate(bird1X, bird1Y);
    canvas.scale(1.0, 0.70 + sin(engine.timeCounter * 16) * 0.30); // 쫀득한 날개짓 물리
    _drawText(canvas, '🕊️', Offset.zero, 26);
    canvas.restore();

    final double bird2X = (w * 0.3 - engine.timeCounter * 16) % (w + 80) - 40;
    final double bird2Y = 280 + cos(engine.timeCounter * 1.8) * 10;
    canvas.save();
    canvas.translate(bird2X, bird2Y);
    canvas.scale(1.0, 0.70 + cos(engine.timeCounter * 12) * 0.30);
    _drawText(canvas, '🕊️', Offset.zero, 20);
    canvas.restore();

    // 5. Cute Green Grass at the Bottom
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
      ).createShader(Rect.fromLTRB(0, h * 0.88, w, h));
    final grassPath = Path()
      ..moveTo(0, h * 0.90)
      ..quadraticBezierTo(w * 0.25, h * 0.87, w * 0.5, h * 0.89)
      ..quadraticBezierTo(w * 0.75, h * 0.91, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grassPath, grassPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    final double r = 24 * scale;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(Offset(center.dx - r * 0.7, center.dy + r * 0.2), r * 0.75, paint);
    canvas.drawCircle(Offset(center.dx + r * 0.7, center.dy + r * 0.2), r * 0.75, paint);
    canvas.drawCircle(Offset(center.dx - r * 1.2, center.dy + r * 0.4), r * 0.5, paint);
    canvas.drawCircle(Offset(center.dx + r * 1.2, center.dy + r * 0.4), r * 0.5, paint);
    // flat bottom
    canvas.drawRect(
      Rect.fromLTRB(center.dx - r * 1.2, center.dy + r * 0.1, center.dx + r * 1.2, center.dy + r * 0.9),
      paint,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
  }
}
