part of '../car_wash_game.dart';

class _CarMaskedPainter extends CustomPainter {
  final _Vehicle vehicle;
  final _WashStep step;
  final List<double> dirtGrid;
  final List<double> soapGrid;
  final List<double> wetGrid;
  final List<double> shineGrid;
  final int gridN;

  _CarMaskedPainter({
    required this.vehicle,
    required this.step,
    required this.dirtGrid,
    required this.soapGrid,
    required this.wetGrid,
    required this.shineGrid,
    required this.gridN,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Master Layer for Car Masking
    canvas.saveLayer(bounds, Paint());

    // Step A: Draw Car Emoji Graphic (Enlarged to 0.94 scale for bigger presence)
    final fontSize = min(size.width * 0.94, size.height * 0.94);
    final textPainter = TextPainter(
      text: TextSpan(
        text: vehicle.emoji,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textPos = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textPos);

    // Step B: Draw Dirt, Wet Drops, Soap Foam, Gloss ONLY inside Car Emoji Silhouette (srcATop)
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcATop);

    // B-1: Mud Layer (only rendered if there is dirt in dirtGrid)
    _drawMudLayer(canvas, size);

    // B-2: Wet Water Film & Droplets Layer (visible during rinse and dry)
    _drawWetLayer(canvas, size);

    // B-3: Soap Foam Layer (rendered above car and water film)
    _drawSoapLayer(canvas, size);

    // B-4: Dry Shine Layer (Diamond gloss and sparkles)
    if (step == _WashStep.dry || step == _WashStep.sticker || step == _WashStep.driving) {
      _drawShineLayer(canvas, size);
    }

    canvas.restore(); // End Effects Layer
    canvas.restore(); // End Master Layer
  }

  void _drawMudLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final mudColor = const Color(0xFF5D4037);
    final darkMud = const Color(0xFF3E2723);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final darkPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final dirtVal = dirtGrid[y * gridN + x]; // 1.0 = dirty, 0.0 = clean
        if (dirtVal <= 0.02) continue;

        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        final baseR = cw * 0.92 * dirtVal;
        paint.color = mudColor.withValues(alpha: (dirtVal * 0.95).clamp(0.0, 0.95));

        canvas.drawCircle(center, baseR, paint);

        // Organic mud splatter specks
        final rng = Random((y * 31 + x * 17) & 0x7FFFFFFF);
        darkPaint.color = darkMud.withValues(alpha: (dirtVal * 0.85).clamp(0.0, 0.85));
        for (int k = 0; k < 3; k++) {
          final ox = (rng.nextDouble() - 0.5) * cw * 0.75;
          final oy = (rng.nextDouble() - 0.5) * ch * 0.75;
          final subR = baseR * (0.25 + rng.nextDouble() * 0.35);
          canvas.drawCircle(center + Offset(ox, oy), subR, darkPaint);
        }
      }
    }
  }

  void _drawSoapLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final foamPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final bubbleStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.9);
    final shimmerPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = soapGrid[y * gridN + x];
        if (v <= 0.01) continue;
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        final r = cw * 0.75 * v;

        // 1. Base fluffy foam body
        foamPaint.color = Colors.white.withValues(alpha: (v * 0.92).clamp(0.0, 0.92));
        canvas.drawCircle(center, r, foamPaint);

        // 2. Multi-cluster bubbly bumps (fluffy foam shape)
        final rng = Random((y * 43 + x * 19) & 0x7FFFFFFF);
        for (int k = 0; k < 3; k++) {
          final angle = (k * 2 * pi / 3) + rng.nextDouble() * 0.4;
          final dist = r * 0.45;
          final subCenter = center + Offset(cos(angle) * dist, sin(angle) * dist);
          final subR = r * (0.45 + rng.nextDouble() * 0.25);
          canvas.drawCircle(subCenter, subR, foamPaint);
        }

        // 3. Iridescent pastel shimmer (lavender & cyan reflection)
        shimmerPaint.color = const Color(0xFFE1BEE7).withValues(alpha: v * 0.35);
        canvas.drawCircle(center - Offset(r * 0.15, r * 0.15), r * 0.45, shimmerPaint);

        // 4. Popping bubble ring highlight
        canvas.drawCircle(center - Offset(r * 0.2, r * 0.2), r * 0.25, bubbleStrokePaint);
      }
    }
  }

  void _drawWetLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;

    final sheenPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final dropBasePaint = Paint()..style = PaintingStyle.fill;
    final dropHighlightPaint = Paint()..style = PaintingStyle.fill;
    final dropShadowPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = wetGrid[y * gridN + x];
        if (v <= 0.02) continue;

        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);

        // 1. Soft glistening wet sheen across the car body
        sheenPaint.color = const Color(0xFF81D4FA).withValues(alpha: (v * 0.28).clamp(0.0, 0.28));
        canvas.drawCircle(center, cw * 0.70 * v, sheenPaint);

        // 2. Realistic water droplets resting on the surface
        final rng = Random((y * 67 + x * 23) & 0x7FFFFFFF);
        dropBasePaint.color = const Color(0xFFB3E5FC).withValues(alpha: (v * 0.85).clamp(0.0, 0.85));
        dropHighlightPaint.color = Colors.white.withValues(alpha: (v * 0.95).clamp(0.0, 0.95));
        dropShadowPaint.color = const Color(0xFF01579B).withValues(alpha: (v * 0.35).clamp(0.0, 0.35));

        // Draw 3 water drops of various sizes per wet cell
        for (int k = 0; k < 3; k++) {
          final ox = (rng.nextDouble() - 0.5) * cw * 0.75;
          final oy = (rng.nextDouble() - 0.5) * ch * 0.75;
          final dropPos = center + Offset(ox, oy);
          final dropR = (cw * 0.12 * (0.7 + rng.nextDouble() * 0.6) * v).clamp(1.5, cw * 0.22);

          // Subtle shadow under droplet
          canvas.drawCircle(dropPos + const Offset(0.5, 1.0), dropR, dropShadowPaint);
          // Droplet body
          canvas.drawCircle(dropPos, dropR, dropBasePaint);
          // Tiny specular light reflection dot
          canvas.drawCircle(dropPos - Offset(dropR * 0.35, dropR * 0.35), dropR * 0.35, dropHighlightPaint);
        }
      }
    }
  }

  void _drawShineLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final glossPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final starPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = shineGrid[y * gridN + x];
        if (v <= 0.05) continue;
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);

        // Mirror glossy highlight
        glossPaint.color = Colors.white.withValues(alpha: (v * 0.35).clamp(0.0, 0.35));
        canvas.drawCircle(center, cw * 0.65 * v, glossPaint);

        // Twinkling 4-point star on polished spots
        if (v > 0.4) {
          final rng = Random((y * 53 + x * 29) & 0x7FFFFFFF);
          if (rng.nextDouble() < 0.40) {
            final starPos = center + Offset((rng.nextDouble() - 0.5) * cw * 0.4, (rng.nextDouble() - 0.5) * ch * 0.4);
            final starSize = (cw * 0.38 * v).clamp(3.0, 16.0);
            starPaint.color = Colors.white.withValues(alpha: (v * 0.95).clamp(0.0, 0.95));
            _drawDiamondSparkle(canvas, starPos, starSize, starPaint);
          }
        }
      }
    }
  }

  void _drawDiamondSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size);
    canvas.drawPath(path, paint);
    // Center brilliant core
    canvas.drawCircle(center, size * 0.28, paint);
  }

  @override
  bool shouldRepaint(covariant _CarMaskedPainter oldDelegate) => true;
}

// ── Particles Painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Droplet> drops;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  _ParticlePainter({required this.drops, required this.bubbles, required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final d in drops) {
      p.color = d.color.withValues(alpha: d.life.clamp(0.0, 1.0));
      canvas.drawCircle(d.pos, d.radius, p);
    }

    for (final b in bubbles) {
      p.color = Colors.white.withValues(alpha: (b.life * 0.8).clamp(0.0, 0.8));
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 1.5;
      canvas.drawCircle(b.pos, b.radius, p);
    }

    for (final s in sparks) {
      p.color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0));
      p.style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, 3 * s.life, p);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Exhaust Smoke Painter ──────────────────────────────────────────────────────
class _SmokePainter extends CustomPainter {
  final List<_Smoke> smokes;
  _SmokePainter(this.smokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (final s in smokes) {
      paint.color = Colors.grey.shade400.withValues(alpha: (s.life * 0.6).clamp(0.0, 0.6));
      canvas.drawCircle(s.pos, s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => true;
}

// ── Confetti Painter ───────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_Spark> confetti;
  _ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final c in confetti) {
      p.color = c.color.withValues(alpha: c.life.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromLTWH(c.pos.dx, c.pos.dy, 8, 8), p);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Step Banner ────────────────────────────────────────────────────────────────
class _WashToolPainter extends CustomPainter {
  final _WashStep step;
  final Offset? toolPos;
  final bool isActive;
  final double idlePhase;

  _WashToolPainter({
    required this.step,
    required this.toolPos,
    required this.isActive,
    required this.idlePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center;
    if (toolPos != null) {
      center = toolPos!;
    } else {
      final ox = size.width * 0.5 + sin(idlePhase) * (size.width * 0.25);
      final oy = size.height * 0.45 + cos(idlePhase * 1.3) * 16;
      center = Offset(ox, oy);
    }

    switch (step) {
      case _WashStep.water:
        _drawPremiumHoseGun(canvas, size, center);
        break;
      case _WashStep.soap:
        _drawPremiumScrubBrush(canvas, size, center);
        break;
      case _WashStep.rinse:
        _drawPremiumShowerHead(canvas, size, center);
        break;
      case _WashStep.dry:
        _drawPremiumMicrofiberMitt(canvas, size, center);
        break;
      default:
        break;
    }

    if (!isActive && toolPos == null) {
      _drawGuidePrompt(canvas, center);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🔧 HELPER: Draw metallic gradient rounded rect (3D raised panel look)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawMetalPanel(Canvas canvas, Rect rect, double radius, Color base) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // Shadow
    canvas.drawRRect(
      rr.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Base gradient (top-light metallic)
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.55)!,
            base,
            Color.lerp(base, Colors.black, 0.32)!,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect),
    );
    // Specular shine streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 4, rect.top + 3, rect.width * 0.45, rect.height * 0.35), Radius.circular(radius * 0.7)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🌊 1. HIGH-PRESSURE WATER GUN + BRAIDED RUBBER HOSE
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumHoseGun(Canvas canvas, Size size, Offset target) {
    final gunOrigin = target;
    final hoseAttach = target + const Offset(48, -28);
    final hoseEnd = Offset(size.width + 20, -20);

    // ── Braided rubber hose (3 layered strokes = thick + mid + highlight) ──
    final hosePath = Path()
      ..moveTo(hoseAttach.dx, hoseAttach.dy)
      ..cubicTo(
        hoseAttach.dx + 55, hoseAttach.dy - 38,
        hoseEnd.dx - 60, hoseEnd.dy + 65,
        hoseEnd.dx, hoseEnd.dy,
      );

    // Hose shadow
    canvas.drawPath(hosePath, Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Hose body (dark rubber core)
    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose mid highlight
    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose glint streak (top shine)
    canvas.drawPath(hosePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose coil rings (braid texture dots)
    for (int i = 0; i <= 8; i++) {
      final t = i / 8.0;
      final cx2 = hoseAttach.dx + t * (hoseEnd.dx - hoseAttach.dx);
      final cy2 = hoseAttach.dy + t * (hoseEnd.dy - hoseAttach.dy) - sin(t * pi) * 38;
      canvas.drawCircle(Offset(cx2, cy2), 2.5, Paint()..color = const Color(0xFF0D47A1).withValues(alpha: 0.65));
    }

    // ── Water jet spray (active) ──
    if (isActive) {
      final sprayOrigin = target + const Offset(-2, 4);
      final sprayDir = const Offset(-0.65, 0.75);
      for (int j = 0; j < 5; j++) {
        final spread = (j - 2) * 0.12;
        final dir = Offset(sprayDir.dx + spread, sprayDir.dy - spread.abs() * 0.3).normalize();
        final tipEnd = sprayOrigin + dir * (40.0 + j * 8);

        canvas.drawLine(
          sprayOrigin,
          tipEnd,
          Paint()
            ..color = Color.lerp(const Color(0xEE00B0FF), const Color(0x3380D8FF), j / 4.0)!
            ..strokeWidth = (3.5 - j * 0.4).clamp(1.0, 4.0)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, j * 0.6),
        );
      }

      // Mist splash at spray end
      for (int k = 0; k < 4; k++) {
        final ang = k * pi / 2 + idlePhase * 3;
        final sx = sprayOrigin.dx - 22 + cos(ang) * 14;
        final sy = sprayOrigin.dy + 38 + sin(ang) * 8;
        canvas.drawCircle(Offset(sx, sy), 5.0 - k * 0.5, Paint()
          ..color = const Color(0x8040C4FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }

    // ── Gun body (metallic dark grey) ──
    canvas.save();
    canvas.translate(gunOrigin.dx, gunOrigin.dy);
    canvas.rotate(0.62);

    // Main body
    _drawMetalPanel(canvas, const Rect.fromLTWH(24, -11, 38, 26), 5, const Color(0xFF37474F));

    // Nozzle tube
    _drawMetalPanel(canvas, const Rect.fromLTWH(-4, -7, 30, 14), 4, const Color(0xFF78909C));

    // Nozzle tip ring (brass)
    canvas.drawCircle(Offset.zero, 7, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFBF360C)],
      ).createShader(const Rect.fromLTWH(-7, -7, 14, 14)));
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFF212121));

    // Trigger guard
    final triggerPath = Path()
      ..moveTo(36, 0)
      ..lineTo(36, 18)
      ..quadraticBezierTo(44, 22, 50, 15)
      ..lineTo(50, 10)
      ..close();
    canvas.drawPath(triggerPath, Paint()..color = const Color(0xFF263238));

    // Trigger lever (red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(34, 4, 6, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFFEF5350),
    );

    // Grip handle ergonomic wrap
    final gripPath = Path()
      ..moveTo(48, 15)
      ..lineTo(44, 40)
      ..quadraticBezierTo(38, 46, 34, 42)
      ..lineTo(38, 18);
    canvas.drawPath(gripPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF455A64), const Color(0xFF1C313A)],
      ).createShader(const Rect.fromLTWH(34, 15, 14, 31)));

    // Grip texture knurling lines
    final knurlPaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(36 + i * 2.0, 22.0), Offset(36 + i * 2.0, 38.0), knurlPaint);
    }

    // Water connector elbow (back of gun)
    canvas.drawCircle(const Offset(58, 5), 6, Paint()
      ..color = const Color(0xFF78909C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🧽 2. PREMIUM CAR WASH BRUSH (Long-handle ergonomic + Dense bristles + Foam)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumScrubBrush(Canvas canvas, Size size, Offset target) {
    final jiggle = isActive ? sin(idlePhase * 14) * 0.10 : sin(idlePhase * 1.8) * 0.04;

    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(jiggle - 0.5);

    // ── Shadow of entire brush ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-28, -78, 56, 110), const Radius.circular(12)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── BRUSH BRISTLE HEAD (dense rows, yellow + white foam) ──
    // Bristle backing plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-28, 18, 56, 26), const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFCA28), const Color(0xFFF57F17)],
        ).createShader(const Rect.fromLTWH(-28, 18, 56, 26)),
    );

    // Bristle rows (white/cream tight rows)
    final bristlePaint = Paint()..strokeWidth = 1.8..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (int col = -10; col <= 10; col += 2) {
      for (int row = 0; row < 3; row++) {
        final bx = col * 2.5;
        final byTop = 44.0 + row * 2.5;
        final byBot = byTop + 14.0;
        final wobble = sin(idlePhase * 12 + col * 0.4) * (isActive ? 2.5 : 0.5);
        bristlePaint.color = row == 0 ? Colors.white : const Color(0xFFFFF9C4);
        canvas.drawLine(Offset(bx, byTop), Offset(bx + wobble, byBot), bristlePaint);
      }
    }

    // Foam froth at bristle base (3D puffy look)
    final foamPaints = [
      Paint()..color = Colors.white.withValues(alpha: 0.98),
      Paint()..color = const Color(0xFFE3F2FD).withValues(alpha: 0.9),
    ];
    final foamBubbles = [
      [-22.0, 44.0, 8.0], [-8.0, 42.0, 10.0], [6.0, 43.0, 9.0], [20.0, 44.0, 7.5],
      [-15.0, 52.0, 7.0], [-2.0, 53.0, 9.0], [12.0, 51.0, 7.0],
    ];
    for (int f = 0; f < foamBubbles.length; f++) {
      final b = foamBubbles[f];
      final shimmer = isActive ? sin(idlePhase * 8 + f) * 1.5 : 0.0;
      canvas.drawCircle(Offset(b[0], b[1] + shimmer), b[2], foamPaints[f % 2]);
      // Glint on each bubble
      canvas.drawCircle(Offset(b[0] - b[2] * 0.35, b[1] - b[2] * 0.3 + shimmer), b[2] * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Flying bubbles when active
    if (isActive) {
      for (int i = 0; i < 7; i++) {
        final ang = i * (pi * 2 / 7) + idlePhase * 5;
        final d = 38.0 + sin(idlePhase * 4 + i * 1.1) * 10;
        final bx = cos(ang) * d;
        final by = sin(ang) * d + 10;
        final r = 5.0 + (i % 3) * 2.5;
        canvas.drawCircle(Offset(bx, by), r, Paint()
          ..color = const Color(0xCCB3E5FC)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
        canvas.drawCircle(Offset(bx - r * 0.3, by - r * 0.3), r * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
    }

    // ── CONNECTOR COLLAR (chrome ring) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-22, 12, 44, 10), const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFECEFF1), const Color(0xFF90A4AE), const Color(0xFF37474F)],
        ).createShader(const Rect.fromLTWH(-22, 12, 44, 10)),
    );

    // ── HANDLE (ergonomic rubberized with grip texture) ──
    // Handle shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -78, 22, 96), const Radius.circular(10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.fill,
    );

    // Handle body gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -76, 20, 92), const Radius.circular(9)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF00838F), const Color(0xFF00BCD4), const Color(0xFF006064)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(const Rect.fromLTWH(-10, -76, 20, 92)),
    );

    // Handle specular
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -70, 6, 70), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Grip knurling indents
    for (int g = 0; g < 8; g++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-9, -56 + g * 9.0, 18, 5), const Radius.circular(2)),
        Paint()..color = const Color(0xFF00BFA5).withValues(alpha: 0.55),
      );
    }

    // Handle top cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -80, 24, 10), const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFECEFF1), const Color(0xFF78909C)],
        ).createShader(const Rect.fromLTWH(-12, -80, 24, 10)),
    );

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🚿 3. PREMIUM CHROME SHOWER RINSE HEAD + STAINLESS HOSE
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumShowerHead(Canvas canvas, Size size, Offset target) {
    final hoseEnd = Offset(size.width + 20, -25);

    // ── STAINLESS STEEL HOSE (twisted metallic) ──
    final hp1 = target + const Offset(32, -22);
    final hosePath = Path()
      ..moveTo(hp1.dx, hp1.dy)
      ..cubicTo(
        hp1.dx + 60, hp1.dy - 42,
        hoseEnd.dx - 55, hoseEnd.dy + 72,
        hoseEnd.dx, hoseEnd.dy,
      );

    canvas.drawPath(hosePath, Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(hosePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Stainless coil rings
    for (int i = 0; i <= 10; i++) {
      final t = i / 10.0;
      final cx2 = hp1.dx + t * (hoseEnd.dx - hp1.dx);
      final cy2 = hp1.dy + t * (hoseEnd.dy - hp1.dy) - sin(t * pi) * 42;
      canvas.drawCircle(Offset(cx2, cy2), 2.0, Paint()
        ..color = const Color(0xFF37474F).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill);
    }

    // ── Water streams (active) ──
    if (isActive) {
      final nozzleBase = target + const Offset(0, 12);
      for (int i = -4; i <= 4; i++) {
        final sx = nozzleBase.dx + i * 7.5;
        final curveFactor = sin(idlePhase * 8 + i * 0.5) * 6;
        final streamPath = Path()
          ..moveTo(sx, nozzleBase.dy)
          ..quadraticBezierTo(sx + curveFactor - 10, nozzleBase.dy + 28, sx - 12 + i * 4.0, nozzleBase.dy + 58);

        canvas.drawPath(streamPath, Paint()
          ..color = Color.lerp(const Color(0xDD29B6F6), const Color(0x6681D4FA), i.abs() / 4.0)!
          ..strokeWidth = (2.5 - i.abs() * 0.18).clamp(1.0, 2.8)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
      }
      // Splash pool at ground
      canvas.drawOval(
        Rect.fromCenter(center: target + const Offset(-12, 65), width: 55, height: 14),
        Paint()
          ..color = const Color(0x5529B6F6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // ── CHROME SHOWER HEAD BODY ──
    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(0.45);

    // Head shadow
    canvas.drawOval(
      const Rect.fromLTWH(-28, -10, 56, 20),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Disc face (chrome gradient)
    canvas.drawOval(
      const Rect.fromLTWH(-26, -9, 52, 18),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFECEFF1),
            const Color(0xFFB0BEC5),
            const Color(0xFF546E7A),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(const Rect.fromLTWH(-26, -9, 52, 18)),
    );

    // Spray holes grid
    final holePaint = Paint()..color = const Color(0xFF263238);
    for (int hx = -3; hx <= 3; hx++) {
      canvas.drawCircle(Offset(hx * 6.5, 0), 1.8, holePaint);
    }
    for (int hx = -2; hx <= 2; hx++) {
      canvas.drawCircle(Offset(hx * 6.5, 6.0), 1.8, holePaint);
      canvas.drawCircle(Offset(hx * 6.5, -6.0), 1.8, holePaint);
    }

    // Chrome rim ring
    canvas.drawOval(
      const Rect.fromLTWH(-26, -9, 52, 18),
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Specular glint
    canvas.drawOval(
      const Rect.fromLTWH(-18, -6, 18, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Handle neck (connector stem)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -30, 18, 22), const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFFB0BEC5), const Color(0xFF78909C), const Color(0xFF37474F)],
        ).createShader(const Rect.fromLTWH(-9, -30, 18, 22)),
    );
    // Neck ring accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -18, 20, 5), const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFECEFF1), const Color(0xFF78909C)],
        ).createShader(const Rect.fromLTWH(-10, -18, 20, 5)),
    );

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🧤 4. PREMIUM MICROFIBER WASH MITT (3D plush, stitching, gradient)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumMicrofiberMitt(Canvas canvas, Size size, Offset target) {
    final tilt = isActive ? sin(idlePhase * 11) * 0.13 : sin(idlePhase * 1.7) * 0.05;

    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(tilt - 0.15);

    // ── Shadow ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-38, -32, 72, 66), const Radius.circular(25)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── MITT THUMB (left side) ──
    final thumbPath = Path()
      ..moveTo(-38, -10)
      ..quadraticBezierTo(-55, -18, -52, -4)
      ..quadraticBezierTo(-50, 8, -38, 14);
    thumbPath.close();
    canvas.drawPath(thumbPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF40C4FF), const Color(0xFF0288D1)],
      ).createShader(const Rect.fromLTWH(-56, -20, 22, 38)));

    // ── MAIN MITT BODY ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-36, -30, 72, 62), const Radius.circular(22)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF81D4FA),
            const Color(0xFF29B6F6),
            const Color(0xFF0288D1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(const Rect.fromLTWH(-36, -30, 72, 62)),
    );

    // ── MICROFIBER SURFACE TEXTURE (plush waffle grid) ──
    final meshPaint = Paint()
      ..color = const Color(0xFF0277BD).withValues(alpha: 0.35)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    // Horizontal mesh lines
    for (int row = -3; row <= 3; row++) {
      canvas.drawLine(Offset(-32, row * 8.0), Offset(32, row * 8.0), meshPaint);
    }
    // Vertical mesh lines
    for (int col = -3; col <= 3; col++) {
      canvas.drawLine(Offset(col * 10.0, -26), Offset(col * 10.0, 26), meshPaint);
    }
    // Diagonal stitch lines
    final stitchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-30, -24), const Offset(28, 26), stitchPaint);
    canvas.drawLine(const Offset(-30, 0), const Offset(28, -26), stitchPaint);
    canvas.drawLine(const Offset(-14, -28), const Offset(28, 14), stitchPaint);

    // ── Specular highlight band ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -24, 28, 36), const Radius.circular(14)),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    // ── PLUSH LOOPS texture (tiny raised fiber dots) ──
    final loopPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final loopPositions = [
      const Offset(-20, -14), const Offset(8, -18), const Offset(-4, 4),
      const Offset(18, 8), const Offset(-16, 16), const Offset(10, -4),
      const Offset(24, -10), const Offset(-26, 2), const Offset(4, 20),
    ];
    for (final lp in loopPositions) {
      canvas.drawCircle(lp, 2.5, loopPaint);
    }

    // ── WRIST CUFF (elastic terry cloth band) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-30, 26, 60, 16), const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, const Color(0xFFE1F5FE), const Color(0xFF81D4FA)],
        ).createShader(const Rect.fromLTWH(-30, 26, 60, 16)),
    );

    // Elastic rib lines on cuff
    final ribPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int r = 0; r < 5; r++) {
      canvas.drawLine(Offset(-28, 28 + r * 2.8), Offset(28, 28 + r * 2.8), ribPaint);
    }

    // Cuff logo dot
    canvas.drawCircle(const Offset(18, 34), 4, Paint()..color = const Color(0xFF0288D1));
    canvas.drawCircle(const Offset(18, 34), 2.5, Paint()..color = Colors.white);

    // ── SPARKLE STARS when actively drying ──
    if (isActive) {
      final starPositions = [
        [const Offset(-48, -22), 10.0, const Color(0xFFFFD700)],
        [const Offset(44, -16), 12.0, const Color(0xFFE0F7FA)],
        [const Offset(-30, 40), 9.0, Colors.white],
        [const Offset(36, 36), 11.0, const Color(0xFFFF4081)],
        [const Offset(0, -40), 8.0, const Color(0xFFFFFF00)],
      ];
      for (final s in starPositions) {
        _drawSparkleStar(canvas, s[0] as Offset, (s[1] as double) * (0.8 + 0.2 * sin(idlePhase * 6)), s[2] as Color);
      }
    }

    canvas.restore();
  }

  // ── Helper: Premium 4-Point Sparkle Star ──
  void _drawSparkleStar(Canvas canvas, Offset center, double radius, Color color) {
    // Outer glow
    canvas.drawCircle(center, radius * 1.2, Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final path = Path();
    final shortR = radius * 0.38;
    for (int i = 0; i < 8; i++) {
      final ang = i * pi / 4;
      final r = (i % 2 == 0) ? radius : shortR;
      final p = center + Offset(cos(ang) * r, sin(ang) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(center, radius * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // ── Helper: Guide Prompt ──
  void _drawGuidePrompt(Canvas canvas, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: '👆 쓱싹 문질러요!',
        style: GoogleFonts.jua(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, 42));
  }

  @override
  bool shouldRepaint(_WashToolPainter oldDelegate) => true;
}

// ── Offset normalize helper ──
extension _OffsetNormalize on Offset {
  Offset normalize() {
    final len = distance;
    return len > 0 ? this / len : const Offset(0, 1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🌟 1. CAR WASH BAY BACKGROUND (Canopy, Sign, Pipes, Brushes, Tiles, Floor)
// ═══════════════════════════════════════════════════════════════════════════════

class _CarWashBayPainter extends CustomPainter {
  final _WashStep step;
  final double idlePhase;
  final double groundH;

  _CarWashBayPainter({
    required this.step,
    required this.idlePhase,
    required this.groundH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wallH = h - groundH;

    // 1. Tiled Back Wall
    _drawTiledWall(canvas, w, wallH);

    // 2. Overhead Water Pipes & Pressure Gauge
    _drawOverheadPipes(canvas, w);

    // 3. Rotating Soft-Wash Cylinder Brushes on Left & Right
    _drawSideBrushes(canvas, w, wallH);

    // 4. Soap Foam Tank
    _drawSoapTank(canvas);

    // 5. Floating Iridescent Bubbles
    _drawFloatingBubbles(canvas, w, wallH);

    // 6. Top Canopy Awning & Glowing Signboard
    _drawTopCanopyAndSign(canvas, w);

    // 7. Modern Wash Bay Floor with Hazard Stripes & Drainage Grates
    _drawBayFloor(canvas, w, h, groundH);
  }

  void _drawTiledWall(Canvas canvas, double w, double wallH) {
    final rect = Rect.fromLTWH(0, 0, w, wallH);
    final wallShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = wallShader);

    // Ceramic tile grid
    final gridPaint = Paint()
      ..color = const Color(0xFF4DD0E1).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const tileSize = 38.0;
    for (double y = 0; y < wallH; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (double x = 0; x < w; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, wallH), gridPaint);
    }

    // Sparkle glints on tiles
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (int i = 0; i < 6; i++) {
      final gx = (i * 65.0 + 24.0) % w;
      final gy = (i * 48.0 + 35.0) % wallH;
      canvas.drawCircle(Offset(gx, gy), 2.0, glintPaint);
    }
  }

  void _drawOverheadPipes(Canvas canvas, double w) {
    final pipeY = 48.0;
    // Pipe shadow
    canvas.drawLine(
      Offset(0, pipeY + 2), Offset(w, pipeY + 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Silver pipe body
    canvas.drawLine(
      Offset(0, pipeY), Offset(w, pipeY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE), Color(0xFF546E7A)],
        ).createShader(Rect.fromLTWH(0, pipeY - 5, w, 10))
        ..strokeWidth = 9,
    );
    // Pipe highlight
    canvas.drawLine(
      Offset(0, pipeY - 2), Offset(w, pipeY - 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2,
    );

    // Brass joints along pipe
    final brassPaint = Paint()..color = const Color(0xFFFFA000);
    for (double jx = w * 0.2; jx < w * 0.9; jx += w * 0.25) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(jx - 4, pipeY - 7, 8, 14), const Radius.circular(3)),
        brassPaint,
      );
      // Spray nozzles hanging down
      canvas.drawRect(
        Rect.fromLTWH(jx - 2, pipeY + 6, 4, 8),
        Paint()..color = const Color(0xFF78909C),
      );
      canvas.drawCircle(Offset(jx, pipeY + 15), 3, Paint()..color = const Color(0xFF37474F));
    }

    // Pressure gauge at top right
    final gaugeCenter = Offset(w * 0.82, pipeY);
    canvas.drawCircle(gaugeCenter, 14, Paint()..color = const Color(0xFFFFB300));
    canvas.drawCircle(gaugeCenter, 11, Paint()..color = Colors.white);
    // Needle twitching
    final needleAngle = -pi * 0.2 + sin(idlePhase * 4) * 0.25;
    canvas.drawLine(
      gaugeCenter,
      gaugeCenter + Offset(cos(needleAngle) * 8, sin(needleAngle) * 8),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(gaugeCenter, 2.5, Paint()..color = Colors.black);
  }

  void _drawSideBrushes(Canvas canvas, double w, double wallH) {
    const brushW = 32.0;
    final brushTop = 75.0;
    final brushBottom = wallH - 12.0;
    final brushH = brushBottom - brushTop;

    // Left rotating roller brush
    _drawCylinderBrush(canvas, 12, brushTop, brushW, brushH, idlePhase * 35);

    // Right rotating roller brush
    _drawCylinderBrush(canvas, w - 12 - brushW, brushTop, brushW, brushH, -idlePhase * 35);
  }

  void _drawCylinderBrush(Canvas canvas, double left, double top, double width, double height, double spinPhase) {
    final centerX = left + width / 2;
    // Central steel rod
    canvas.drawLine(
      Offset(centerX, top - 6),
      Offset(centerX, top + height + 6),
      Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Clip to brush bounds
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, width, height), const Radius.circular(16)));

    // Brush background
    canvas.drawRect(
      Rect.fromLTWH(left, top, width, height),
      Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.2),
    );

    // Alternating spiral bristle stripes (Sky Blue & Candy Pink)
    const stripeSpacing = 28.0;
    final offset = spinPhase % stripeSpacing;

    final paintBlue = Paint()
      ..color = const Color(0xFF29B6F6)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintPink = Paint()
      ..color = const Color(0xFFF06292)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    for (double y = top - stripeSpacing; y < top + height + stripeSpacing * 2; y += stripeSpacing) {
      final sy = y + offset;
      final isBlue = ((y / stripeSpacing).floor() % 2 == 0);
      final p = isBlue ? paintBlue : paintPink;
      canvas.drawLine(Offset(left - 4, sy - 8), Offset(left + width + 4, sy + 8), p);
    }

    // Shadow on sides to give 3D cylinder depth
    canvas.drawRect(
      Rect.fromLTWH(left, top, 6, height),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTWH(left + width - 6, top, 6, height),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Center specular shine
    canvas.drawRect(
      Rect.fromLTWH(left + width * 0.35, top, width * 0.3, height),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    canvas.restore();
  }

  void _drawSoapTank(Canvas canvas) {
    // Soap dispenser on left wall
    const tankRect = Rect.fromLTWH(48, 85, 30, 48);
    final rrect = RRect.fromRectAndRadius(tankRect, const Radius.circular(8));
    // Tank shadow
    canvas.drawRRect(rrect.shift(const Offset(2, 2)), Paint()..color = Colors.black.withValues(alpha: 0.15));
    // Glass body
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF80DEEA)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Liquid inside (Bubbly turquoise)
    final liquidH = 32.0 + sin(idlePhase * 2) * 2;
    final liquidRect = Rect.fromLTWH(50, 85 + (48 - liquidH), 26, liquidH - 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(liquidRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF26A69A).withValues(alpha: 0.75),
    );

    // Foam bubbles on top of liquid
    canvas.drawCircle(Offset(56, 85 + (48 - liquidH)), 3.5, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(64, 85 + (48 - liquidH) - 1), 4.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(Offset(71, 85 + (48 - liquidH)), 3.0, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  void _drawFloatingBubbles(Canvas canvas, double w, double wallH) {
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 9; i++) {
      final t = (idlePhase * 0.08 + i * 0.11) % 1.0;
      final bx = (w * (0.12 + (i * 0.09))) + sin(idlePhase * 1.6 + i * 1.5) * 18;
      final by = wallH * (0.90 - t * 0.85);
      final r = 6.0 + (i % 3) * 3.5;

      bubblePaint.color = Colors.white.withValues(alpha: (1.0 - t * 0.6).clamp(0.2, 0.7));
      canvas.drawCircle(Offset(bx, by), r, bubblePaint);

      // Inner rainbow tint
      canvas.drawCircle(
        Offset(bx, by), r * 0.85,
        Paint()..color = const Color(0xFFE1BEE7).withValues(alpha: 0.15),
      );
      // Glint highlight
      canvas.drawCircle(
        Offset(bx - r * 0.35, by - r * 0.35), r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  void _drawTopCanopyAndSign(Canvas canvas, double w) {
    const canopyH = 26.0;
    const scallopW = 28.0;
    final count = (w / scallopW).ceil() + 1;

    // Scalloped canopy awning
    for (int i = 0; i < count; i++) {
      final sx = i * scallopW;
      final isBlue = (i % 2 == 0);
      final color = isBlue ? const Color(0xFF0288D1) : const Color(0xFFFFCA28);

      final path = Path()
        ..moveTo(sx, 0)
        ..lineTo(sx + scallopW, 0)
        ..lineTo(sx + scallopW, canopyH)
        ..arcToPoint(
          Offset(sx, canopyH),
          radius: const Radius.circular(scallopW / 2),
          clockwise: true,
        )
        ..close();

      canvas.drawPath(path, Paint()..color = color);
    }

    // Dropshadow under canopy
    canvas.drawRect(
      Rect.fromLTWH(0, canopyH + scallopW / 2 - 4, w, 4),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Cheerful Signboard plaque
    final signW = 190.0;
    final signH = 30.0;
    final signX = (w - signW) / 2;
    final signY = 14.0;
    final signRect = Rect.fromLTWH(signX, signY, signW, signH);
    final signRRect = RRect.fromRectAndRadius(signRect, const Radius.circular(16));

    // Sign background
    canvas.drawRRect(signRRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawRRect(
      signRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFA000), Color(0xFFFF6F00)],
        ).createShader(signRect),
    );
    canvas.drawRRect(
      signRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Text on sign
    final tp = TextPainter(
      text: TextSpan(
        text: '🫧 뽀득뽀득 키즈 세차장 🧽',
        style: GoogleFonts.jua(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(signX + (signW - tp.width) / 2, signY + (signH - tp.height) / 2));

    // Blinking lights around sign
    final bulbColors = [const Color(0xFFFFEB3B), const Color(0xFFFF1744), const Color(0xFF00E676), const Color(0xFF00E5FF)];
    for (int i = 0; i < 4; i++) {
      final bx = signX + 16 + i * (signW - 32) / 3;
      final pulse = (sin(idlePhase * 4 + i) * 0.4 + 0.6).clamp(0.2, 1.0);
      final bColor = bulbColors[i % bulbColors.length].withValues(alpha: pulse);
      canvas.drawCircle(Offset(bx, signY + 3), 3, Paint()..color = bColor);
      canvas.drawCircle(Offset(bx, signY + signH - 3), 3, Paint()..color = bColor);
    }
  }

  void _drawBayFloor(Canvas canvas, double w, double h, double groundH) {
    final floorTop = h - groundH;
    final floorRect = Rect.fromLTWH(0, floorTop, w, groundH);

    // Sleek wet slate floor
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF455A64), Color(0xFF263238), Color(0xFF1E272C)],
        ).createShader(floorRect),
    );

    // Yellow & black safety hazard caution stripe curb along top of floor
    const curbH = 10.0;
    const stripeW = 16.0;
    final curbRect = Rect.fromLTWH(0, floorTop, w, curbH);
    canvas.drawRect(curbRect, Paint()..color = const Color(0xFFFFCA28));

    final hazardPaint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = stripeW * 0.5
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(curbRect);
    for (double sx = -curbH; sx < w + curbH * 2; sx += stripeW) {
      canvas.drawLine(Offset(sx, floorTop + curbH), Offset(sx + curbH, floorTop), hazardPaint);
    }
    canvas.restore();

    // Central drainage grate
    final grateRect = Rect.fromCenter(
      center: Offset(w / 2, floorTop + groundH * 0.52),
      width: w * 0.72,
      height: 18,
    );
    final grateRRect = RRect.fromRectAndRadius(grateRect, const Radius.circular(5));
    // Grate pit glow
    canvas.drawRRect(grateRRect, Paint()..color = const Color(0xFF102027));
    // Water puddle sheen
    canvas.drawRRect(
      grateRRect,
      Paint()
        ..color = const Color(0xFF4DD0E1).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Grate bars
    final barPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 2.0;
    for (double bx = grateRect.left + 8; bx < grateRect.right - 8; bx += 8) {
      canvas.drawLine(Offset(bx, grateRect.top + 2), Offset(bx, grateRect.bottom - 2), barPaint);
    }

    // Tire guide stripes
    final tirePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final leftTrackX = w * 0.22;
    final rightTrackX = w * 0.78;
    canvas.drawLine(Offset(leftTrackX, floorTop + 14), Offset(leftTrackX, h - 8), tirePaint);
    canvas.drawLine(Offset(rightTrackX, floorTop + 14), Offset(rightTrackX, h - 8), tirePaint);
  }

  @override
  bool shouldRepaint(covariant _CarWashBayPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🚗 2. ROAD DRIVING SCENERY PAINTER (Parallax, Animals, Town, Car, Booster)
// ═══════════════════════════════════════════════════════════════════════════════

class _RoadDrivingSceneryPainter extends CustomPainter {
  final double scrollX;
  final double bouncePhase;
  final bool isBoosting;
  final _Vehicle vehicle;
  final List<_Sticker> stickers;
  final double jumpOffset;
  final List<_DrivingSpark> drivingSparks;
  final String? honkBubbleText;

  _RoadDrivingSceneryPainter({
    required this.scrollX,
    required this.bouncePhase,
    required this.isBoosting,
    required this.vehicle,
    required this.stickers,
    required this.jumpOffset,
    required this.drivingSparks,
    required this.honkBubbleText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sunny Sky, Smiling Sun, Clouds & Hot Air Balloon
    _drawSkyAndSun(canvas, w, h);

    // 2. Rolling Green Hills & Wind Turbines
    _drawHillsAndTurbines(canvas, w, h);

    // 3. Cheerful Roadside Scenery (Houses, Apple Trees, Cheering Animals)
    _drawRoadsideScenery(canvas, w, h);

    // 4. Asphalt Highway Road & Moving Center Stripes
    _drawHighway(canvas, w, h);

    // 5. Clean & Decorated Player Car
    _drawPlayerCar(canvas, w, h);

    // 6. Driving Particles (Sparkles, Stars, Booster Flame)
    _drawParticles(canvas);
  }

  void _drawSkyAndSun(Canvas canvas, double w, double h) {
    final skyH = h * 0.62;
    final skyRect = Rect.fromLTWH(0, 0, w, skyH);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF29B6F6), Color(0xFF81D4FA), Color(0xFFE1F5FE)],
        ).createShader(skyRect),
    );

    // Smiling Sun at top right
    final sunCenter = Offset(w * 0.82, h * 0.12);
    final rayCount = 12;
    final rayPaint = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final ang = i * (2 * pi / rayCount) + bouncePhase * 0.25;
      final p1 = sunCenter + Offset(cos(ang) * 25, sin(ang) * 25);
      final p2 = sunCenter + Offset(cos(ang) * 35, sin(ang) * 35);
      canvas.drawLine(p1, p2, rayPaint);
    }
    // Sun body
    canvas.drawCircle(sunCenter, 22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(sunCenter, 19, Paint()..color = const Color(0xFFFFEE58));

    // Sun cute smiling eyes & blush
    canvas.drawCircle(sunCenter + const Offset(-6, -2), 2.5, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(sunCenter + const Offset(6, -2), 2.5, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(sunCenter + const Offset(-9, 4), 2.8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7));
    canvas.drawCircle(sunCenter + const Offset(9, 4), 2.8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7));
    // Smile mouth
    canvas.drawArc(
      Rect.fromCenter(center: sunCenter + const Offset(0, 3), width: 10, height: 8),
      0, pi, false,
      Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1.8..style = PaintingStyle.stroke,
    );

    // Floating Clouds
    final cloudConfigs = [
      [w * 0.15, h * 0.08, 22.0],
      [w * 0.55, h * 0.16, 26.0],
      [w * 0.90, h * 0.22, 20.0],
    ];
    for (int i = 0; i < cloudConfigs.length; i++) {
      final cfg = cloudConfigs[i];
      final cx = (cfg[0] - scrollX * (0.10 + i * 0.03)) % (w + 120) - 60;
      final cy = cfg[1];
      final cr = cfg[2];
      _drawFluffyCloud(canvas, Offset(cx, cy), cr);
    }

    // Distant hot air balloon
    final balloonX = (w * 0.38 - scrollX * 0.06) % (w + 100) - 50;
    _drawHotAirBalloon(canvas, Offset(balloonX, h * 0.18));
  }

  void _drawFluffyCloud(Canvas canvas, Offset pos, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(pos, r, p);
    canvas.drawCircle(pos + Offset(-r * 0.6, r * 0.2), r * 0.75, p);
    canvas.drawCircle(pos + Offset(r * 0.6, r * 0.2), r * 0.75, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - r * 0.8, pos.dy, r * 1.6, r * 0.6), Radius.circular(r * 0.3)),
      p,
    );
  }

  void _drawHotAirBalloon(Canvas canvas, Offset pos) {
    // Balloon envelope
    final balloonRect = Rect.fromCenter(center: pos, width: 24, height: 30);
    canvas.drawOval(
      balloonRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFFD740), Color(0xFF40C4FF)],
        ).createShader(balloonRect),
    );
    // Basket
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - 3, pos.dy + 18, 6, 5),
      Paint()..color = const Color(0xFF8D6E63),
    );
  }

  void _drawHillsAndTurbines(Canvas canvas, double w, double h) {
    // Distant soft mountain ridge
    final hillPath1 = Path()..moveTo(0, h * 0.44);
    for (double x = 0; x <= w; x += 25) {
      final y = h * 0.44 + sin((x + scrollX * 0.15) * 0.012) * 16;
      hillPath1.lineTo(x, y);
    }
    // Seamlessly finish at exact right edge to prevent broken cut-off edge
    final endY1 = h * 0.44 + sin((w + scrollX * 0.15) * 0.012) * 16;
    hillPath1.lineTo(w, endY1);
    hillPath1.lineTo(w, h * 0.65);
    hillPath1.lineTo(0, h * 0.65);
    hillPath1.close();
    canvas.drawPath(hillPath1, Paint()..color = const Color(0xFFA5D6A7));

    // Foreground rolling green hills
    final hillPath2 = Path()..moveTo(0, h * 0.50);
    for (double x = 0; x <= w; x += 20) {
      final y = h * 0.50 + sin((x + scrollX * 0.35) * 0.016) * 14;
      hillPath2.lineTo(x, y);
    }
    // Seamlessly finish at exact right edge
    final endY2 = h * 0.50 + sin((w + scrollX * 0.35) * 0.016) * 14;
    hillPath2.lineTo(w, endY2);
    hillPath2.lineTo(w, h * 0.65);
    hillPath2.lineTo(0, h * 0.65);
    hillPath2.close();
    canvas.drawPath(hillPath2, Paint()..color = const Color(0xFF66BB6A));

    // Wind turbines on hills
    final turbineX1 = (w * 0.25 - scrollX * 0.25) % (w + 80) - 40;
    final turbineX2 = (w * 0.72 - scrollX * 0.25) % (w + 80) - 40;
    _drawWindTurbine(canvas, Offset(turbineX1, h * 0.42));
    _drawWindTurbine(canvas, Offset(turbineX2, h * 0.44));
  }

  void _drawWindTurbine(Canvas canvas, Offset base) {
    final polePaint = Paint()..color = Colors.white..strokeWidth = 2.5;
    final hubY = base.dy - 32;
    canvas.drawLine(base, Offset(base.dx, hubY), polePaint);
    canvas.drawCircle(Offset(base.dx, hubY), 3.5, Paint()..color = const Color(0xFFCFD8DC));

    // 3 spinning blades
    final bladePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final ang = i * (2 * pi / 3) + bouncePhase * 2.8;
      canvas.drawLine(
        Offset(base.dx, hubY),
        Offset(base.dx + cos(ang) * 18, hubY + sin(ang) * 18),
        bladePaint,
      );
    }
  }

  void _drawRoadsideScenery(Canvas canvas, double w, double h) {
    // Roadside grass strip
    final grassRect = Rect.fromLTWH(0, h * 0.54, w, h * 0.11);
    canvas.drawRect(grassRect, Paint()..color = const Color(0xFF4CAF50));

    // Clean, spacious single-item storybook elements (spaced at 240dp)
    const itemSpacing = 240.0;
    final items = [
      ('🏡', 38.0, -12.0, false), // Cozy House
      ('🐰', 34.0, -8.0, true),   // Cute Bunny
      ('🌳', 38.0, -12.0, false), // Green Apple Tree
      ('🐶', 34.0, -8.0, true),   // Cheering Puppy
      ('🌸', 32.0, -6.0, false),  // Beautiful Flower
      ('🐻', 34.0, -8.0, true),   // Friendly Bear
      ('🌲', 38.0, -12.0, false), // Tall Pine Tree
      ('🐱', 34.0, -8.0, true),   // Smiling Cat
    ];

    final totalW = items.length * itemSpacing;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final ix = (i * itemSpacing - scrollX * 0.85) % totalW - 50;
      if (ix < -70 || ix > w + 70) continue; // Skip off-screen

      final isAnimal = item.$4;
      final hop = isAnimal ? sin(bouncePhase * 1.5 + i) * 4.0 : 0.0;
      final iy = h * 0.53 + item.$3 + hop;

      final tp = TextPainter(
        text: TextSpan(text: item.$1, style: TextStyle(fontSize: item.$2)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(ix, iy));
    }
  }

  void _drawHighway(Canvas canvas, double w, double h) {
    final roadTop = h * 0.64;
    final roadH = h - roadTop;
    final roadRect = Rect.fromLTWH(0, roadTop, w, roadH);

    // Asphalt highway surface extending completely to the bottom
    canvas.drawRect(
      roadRect,
      Paint()..color = const Color(0xFF263238),
    );

    // Top and bottom yellow kerb boundary lines
    final linePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(0, roadTop + 2), Offset(w, roadTop + 2), linePaint);
    canvas.drawLine(Offset(0, h - 2), Offset(w, h - 2), linePaint);

    // Center white dashed stripes (Rapidly moving right to left)
    const dashSpacing = 80.0;
    const dashLen = 42.0;
    final dashY = roadTop + roadH * 0.40;
    final dashOffset = (scrollX * 1.6) % dashSpacing;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (double dx = -dashSpacing; dx < w + dashSpacing; dx += dashSpacing) {
      final sx = dx - dashOffset;
      canvas.drawLine(Offset(sx, dashY), Offset(sx + dashLen, dashY), dashPaint);
    }
  }

  void _drawPlayerCar(Canvas canvas, double w, double h) {
    final roadTop = h * 0.64;
    final roadH = h - roadTop;
    final carW = (w * 0.60).clamp(220.0, 360.0);
    final carH = carW * 0.62;
    final carX = w * 0.28;
    final carY = roadTop + roadH * 0.38 - jumpOffset + sin(bouncePhase) * 3.5;

    canvas.save();
    canvas.translate(carX, carY);

    // Tilt forward slightly when boosting
    if (isBoosting) {
      canvas.rotate(0.04);
    }

    // ── Exhaust Booster Fire & Rainbow Wind Streaks (When boosting) ──
    if (isBoosting) {
      // Booster fire
      final fireX = -carW * 0.46;
      final fireY = carH * 0.16;
      final flameLen = 42.0 + sin(bouncePhase * 8) * 12.0;

      final flamePath = Path()
        ..moveTo(fireX, fireY - 6)
        ..lineTo(fireX - flameLen, fireY)
        ..lineTo(fireX, fireY + 6)
        ..close();

      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF1744));
      canvas.drawPath(
        Path()
          ..moveTo(fireX, fireY - 3)
          ..lineTo(fireX - flameLen * 0.65, fireY)
          ..lineTo(fireX, fireY + 3)
          ..close(),
        Paint()..color = const Color(0xFFFFEA00),
      );

      // Rainbow wind streaks
      final streakColors = [Colors.red, Colors.orange, Colors.yellow, Colors.cyanAccent];
      for (int s = 0; s < 4; s++) {
        final sy = -carH * 0.2 + s * 14.0;
        final sx1 = -carW * 0.5 - s * 15.0;
        final sx2 = sx1 - 40.0;
        canvas.drawLine(
          Offset(sx1, sy), Offset(sx2, sy),
          Paint()
            ..color = streakColors[s].withValues(alpha: 0.75)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Clean Car Body Emoji (Flipped horizontally so Unicode vehicles face forward to the RIGHT 👉) ──
    final tpCar = TextPainter(
      text: TextSpan(
        text: vehicle.emoji,
        style: TextStyle(fontSize: carW * 0.92),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final carTopLeft = Offset(-tpCar.width / 2, -tpCar.height / 2);

    canvas.save();
    canvas.scale(-1.0, 1.0);
    tpCar.paint(canvas, carTopLeft);
    canvas.restore();

    // ── Decorated Stickers ──
    // In wash bay, car faced left (rel.dx = 0 at front).
    // Now car faces right (front is at +width/2, rear at -width/2).
    for (final s in stickers) {
      final sx = (0.5 - s.rel.dx) * tpCar.width;
      final sy = (s.rel.dy - 0.5) * tpCar.height;
      final tpSticker = TextPainter(
        text: TextSpan(
          text: s.emoji,
          style: const TextStyle(fontSize: 26),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpSticker.paint(canvas, Offset(sx - tpSticker.width / 2, sy - tpSticker.height / 2));
    }

    // ── Continuous Sparkles around clean car ──
    final sparklePhase = bouncePhase * 3;
    final starGlints = [
      Offset(-carW * 0.35, -carH * 0.28),
      Offset(carW * 0.28, -carH * 0.25),
      Offset(carW * 0.05, -carH * 0.38),
    ];
    for (int g = 0; g < starGlints.length; g++) {
      final sp = starGlints[g];
      final scale = (sin(sparklePhase + g * 2) * 0.35 + 0.65).clamp(0.2, 1.0);
      _drawGlintStar(canvas, sp, 7.0 * scale, Colors.white);
    }

    // ── Speech Bubble (Honk 빵빵!) ──
    if (honkBubbleText != null) {
      final bubbleW = 120.0;
      final bubbleH = 34.0;
      final bubbleX = -bubbleW / 2;
      final bubbleY = -carH * 0.5 - 46.0;

      final bubbleRect = Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH);
      final bubbleRRect = RRect.fromRectAndRadius(bubbleRect, const Radius.circular(16));

      // Pointer
      final pointerPath = Path()
        ..moveTo(0, bubbleY + bubbleH)
        ..lineTo(-8, bubbleY + bubbleH + 8)
        ..lineTo(8, bubbleY + bubbleH)
        ..close();

      canvas.drawRRect(bubbleRRect.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawRRect(bubbleRRect, Paint()..color = Colors.white);
      canvas.drawPath(pointerPath, Paint()..color = Colors.white);
      canvas.drawRRect(
        bubbleRRect,
        Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 2.5,
      );

      final tpHonk = TextPainter(
        text: TextSpan(
          text: honkBubbleText!,
          style: GoogleFonts.jua(
            fontSize: 14,
            color: const Color(0xFFD84315),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpHonk.paint(canvas, Offset(bubbleX + (bubbleW - tpHonk.width) / 2, bubbleY + (bubbleH - tpHonk.height) / 2));
    }

    canvas.restore();
  }

  void _drawGlintStar(Canvas canvas, Offset center, double r, Color c) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final ang = i * pi / 4;
      final rad = (i % 2 == 0) ? r : r * 0.35;
      final pt = center + Offset(cos(ang) * rad, sin(ang) * rad);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c);
  }

  void _drawParticles(Canvas canvas) {
    for (final s in drivingSparks) {
      final alpha = s.life.clamp(0.0, 1.0);
      if (s.isStar) {
        _drawGlintStar(canvas, s.pos, s.size * alpha, s.color.withValues(alpha: alpha));
      } else {
        canvas.drawCircle(
          s.pos,
          s.size * alpha,
          Paint()..color = s.color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadDrivingSceneryPainter oldDelegate) => true;
}


