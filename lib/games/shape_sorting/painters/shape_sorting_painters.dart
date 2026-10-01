part of '../shape_sorting_game.dart';

/// 3D 원목/플라스틱 블록 페인터 (도형 본체 + 입체 두께 + 귀여운 표정 + 광택)
class _ChunkyBlockPainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final Color shadowColor;
  final bool isDragging;
  final bool isHappy;

  _ChunkyBlockPainter({
    required this.type,
    required this.color,
    required this.shadowColor,
    this.isDragging = false,
    this.isHappy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.84;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 1. 하단 3D 두께 음영 (아래로 4px 이동)
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(0, 4.0);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. 블록 전면 메인 색상
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. 테두리 외곽선
    final borderPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // 4. 귀여운 표정 (동글동글 큰 눈 + 볼터치 + 입)
    final eyePaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;

    final whiteGlint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final eyeSpacing = r * 0.28;
    final eyeY = -r * 0.04;
    final eyeRadius = r * 0.09;

    // 왼쪽/오른쪽 눈
    canvas.drawCircle(Offset(-eyeSpacing, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(eyeSpacing, eyeY), eyeRadius, eyePaint);

    // 눈 반짝임 하이라이트
    canvas.drawCircle(Offset(-eyeSpacing - 1.5, eyeY - 1.5), eyeRadius * 0.4, whiteGlint);
    canvas.drawCircle(Offset(eyeSpacing - 1.5, eyeY - 1.5), eyeRadius * 0.4, whiteGlint);

    // 핑크빛 볼터치
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-eyeSpacing * 1.4, eyeY + 6), width: 10, height: 6),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeSpacing * 1.4, eyeY + 6), width: 10, height: 6),
      blushPaint,
    );

    // 입 모양 (드래그 중이거나 완료 시 활짝 웃음)
    if (isDragging) {
      // 신나서 입을 벌린 모양 ':O'
      final openMouth = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, r * 0.22), width: 9, height: 11),
        openMouth,
      );
    } else {
      // 방긋 웃는 입
      final smilePaint = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(-r * 0.16, r * 0.16)
        ..quadraticBezierTo(0, r * (isHappy ? 0.38 : 0.30), r * 0.16, r * 0.16);
      canvas.drawPath(smilePath, smilePaint);
    }

    // 5. 좌상단 글래스 하이라이트 (산뜻한 광택감)
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.35), r * 0.16, glossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChunkyBlockPainter old) =>
      old.type != type || old.color != color || old.isDragging != isDragging || old.isHappy != isHappy;
}

/// 슬롯 구멍 페인터 (부드러운 음각 홈 + 은은한 점선 테두리)
class _SlotHolePainter extends CustomPainter {
  final ShapeType type;
  final Color accentColor;
  final bool isHovering;

  _SlotHolePainter({
    required this.type,
    required this.accentColor,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.84;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 1. 홈 내부 은은한 색상
    final bgPaint = Paint()
      ..color = isHovering
          ? accentColor.withValues(alpha: 0.2)
          : accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 2. 점선 아웃라인
    final dashPaint = Paint()
      ..color = isHovering ? accentColor : accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovering ? 2.8 : 2.0;

    _drawDashedPath(canvas, path, dashPaint);

    // 3. 중앙에 반투명 미니 실루엣
    final silhouettePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_getShapePath(type, r * 0.6), silhouettePaint);

    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final dashLen = min(5.5, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + dashLen);
        canvas.drawPath(extractPath, paint);
        distance += 9.5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlotHolePainter old) =>
      old.type != type || old.accentColor != accentColor || old.isHovering != isHovering;
}

/// 아기자기한 감성 플레이룸 배경 페인터 (가랜드, 둥실둥실 구름, 반짝이 별, 파스텔 힐)
class _CharmingPlayroomBackgroundPainter extends CustomPainter {
  final double animValue;

  _CharmingPlayroomBackgroundPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 은은한 도트 패턴
    _drawPolkaDots(canvas, size);

    // 2. 하단 둥근 언덕 (부드러운 파스텔 힐)
    _drawBottomHills(canvas, size);

    // 3. 둥실둥실 떠다니는 귀여운 표정 구름들
    _drawCuteClouds(canvas, size);

    // 4. 공간을 채우는 아기자기한 미니 도형 & 반짝이 별 & 비눗방울
    _drawFloatingAccents(canvas, size);

    // 5. 상단 삼각 가랜드 (Bunting Flags)
    _drawTopGarland(canvas, size);
  }

  void _drawPolkaDots(Canvas canvas, Size size) {
    final dotColors = [
      const Color(0x18FF8A80),
      const Color(0x1880D8FF),
      const Color(0x18FFD180),
      const Color(0x18B9F6CA),
      const Color(0x18EA80FC),
    ];
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const step = 44.0;
    int idx = 0;
    for (double y = 50; y < size.height - 40; y += step) {
      final isOdd = (idx % 2 == 1);
      for (double x = isOdd ? step : step / 2; x < size.width; x += step) {
        dotPaint.color = dotColors[(idx + (x ~/ step)) % dotColors.length];
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
      idx++;
    }
  }

  void _drawBottomHills(Canvas canvas, Size size) {
    final hillPaint1 = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final hillPath1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 75)
      ..quadraticBezierTo(size.width * 0.35, size.height - 110, size.width * 0.75, size.height - 65)
      ..quadraticBezierTo(size.width * 0.9, size.height - 45, size.width, size.height - 55)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final hillPath2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width * 0.25, size.height - 60, size.width * 0.55, size.height - 35)
      ..quadraticBezierTo(size.width * 0.8, size.height - 15, size.width, size.height - 30)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath2, hillPaint2);
  }

  void _drawCuteClouds(Canvas canvas, Size size) {
    // 좌상단 구름
    final c1Y = 78 + sin(animValue * 2 * pi) * 5;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.16, c1Y),
      width: 88,
      height: 48,
      hasHappyFace: true,
    );

    // 우상단 구름
    final c2Y = 115 + cos(animValue * 2 * pi) * 6;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.86, c2Y),
      width: 76,
      height: 42,
      hasHappyFace: true,
    );

    // 좌하단 은은한 작은 구름
    final c3Y = size.height * 0.52 + sin(animValue * 2 * pi + 1.5) * 4;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.08, c3Y),
      width: 60,
      height: 34,
      hasHappyFace: false,
      alpha: 0.55,
    );

    // 우하단 은은한 작은 구름
    final c4Y = size.height * 0.62 + cos(animValue * 2 * pi + 2.0) * 4;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.92, c4Y),
      width: 66,
      height: 36,
      hasHappyFace: false,
      alpha: 0.55,
    );
  }

  void _drawCloud({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required bool hasHappyFace,
    double alpha = 0.92,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: alpha * 0.25)
      ..style = PaintingStyle.fill;

    // 구름 몽실몽실 원들
    final r = height / 2;
    void drawPuffs(Paint p) {
      canvas.drawCircle(Offset(-width * 0.22, 0), r * 0.85, p);
      canvas.drawCircle(Offset(0, -r * 0.28), r * 1.05, p);
      canvas.drawCircle(Offset(width * 0.24, 0), r * 0.8, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, r * 0.2), width: width * 0.85, height: r * 0.85),
          Radius.circular(r * 0.5),
        ),
        p,
      );
    }

    // 부드러운 하단 음영
    canvas.save();
    canvas.translate(0, 3.5);
    drawPuffs(shadowPaint);
    canvas.restore();

    // 메인 화이트 구름
    drawPuffs(cloudPaint);

    if (hasHappyFace) {
      final eyePaint = Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final blushPaint = Paint()
        ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      // 볼터치
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 4), width: 7, height: 4.5),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(14, 4), width: 7, height: 4.5),
        blushPaint,
      );

      // 눈 웃음 ^ ^
      final eyePath1 = Path()
        ..moveTo(-12, 1)
        ..quadraticBezierTo(-9, -3.5, -6, 1);
      final eyePath2 = Path()
        ..moveTo(6, 1)
        ..quadraticBezierTo(9, -3.5, 12, 1);
      canvas.drawPath(eyePath1, eyePaint);
      canvas.drawPath(eyePath2, eyePaint);

      // 미소
      final smilePaint = Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(-3.5, 3.5)
        ..quadraticBezierTo(0, 7.0, 3.5, 3.5);
      canvas.drawPath(smilePath, smilePaint);
    }

    canvas.restore();
  }

  void _drawFloatingAccents(Canvas canvas, Size size) {
    // 반짝이 4포인트 별들
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.11, size.height * 0.28 + sin(animValue * 2 * pi + 0.5) * 6),
      size: 14 + sin(animValue * 2 * pi) * 2,
      color: const Color(0xFFFFCA28),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.89, size.height * 0.26 + cos(animValue * 2 * pi + 1.2) * 6),
      size: 13 + cos(animValue * 2 * pi) * 2,
      color: const Color(0xFFFF80AB),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.88, size.height * 0.72 + sin(animValue * 2 * pi + 2.0) * 5),
      size: 12,
      color: const Color(0xFF40C4FF),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.12, size.height * 0.76 + cos(animValue * 2 * pi + 3.0) * 5),
      size: 11,
      color: const Color(0xFFB388FF),
    );

    // 파스텔 미니 비눗방울 / 원목 구슬
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.07, size.height * 0.42 + cos(animValue * 2 * pi + 2.5) * 5),
      radius: 9,
      color: const Color(0xFFFF8A80),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.93, size.height * 0.46 + sin(animValue * 2 * pi + 1.8) * 5),
      radius: 11,
      color: const Color(0xFF80D8FF),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.20, size.height * 0.86 + sin(animValue * 2 * pi + 4.0) * 4),
      radius: 7,
      color: const Color(0xFFFFD180),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.82, size.height * 0.88 + cos(animValue * 2 * pi + 4.5) * 4),
      radius: 8,
      color: const Color(0xFFA7FFEB),
    );
  }

  void _drawSparkleStar(Canvas canvas, Offset center, {required double size, required Color color}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = size / 2;
    path.moveTo(0, -r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.quadraticBezierTo(0, 0, -r, 0);
    path.quadraticBezierTo(0, 0, 0, -r);
    canvas.drawPath(path, paint);

    // 중앙 작은 화이트 반짝임
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, r * 0.28, whitePaint);

    canvas.restore();
  }

  void _drawPastelBubble(Canvas canvas, Offset center, {required double radius, required Color color}) {
    final bubblePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bubblePaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 하이라이트 글린트
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - radius * 0.32, center.dy - radius * 0.32), radius * 0.28, glintPaint);
  }

  void _drawTopGarland(Canvas canvas, Size size) {
    const flagColors = [
      Color(0xFFFF8DA1),
      Color(0xFFFFD54F),
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
      Color(0xFFFFB74D),
      Color(0xFF4DD0E1),
      Color(0xFFFF80AB),
      Color(0xFFAED581),
    ];

    final stringPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final stringPath = Path()
      ..moveTo(-10, 8)
      ..quadraticBezierTo(size.width * 0.5, 30, size.width + 10, 8);
    canvas.drawPath(stringPath, stringPaint);

    const int flagCount = 9;
    final flagWidth = size.width / (flagCount + 0.6);
    final flagHeight = flagWidth * 0.95;

    for (int i = 0; i < flagCount; i++) {
      final t = (i + 0.8) / (flagCount + 0.6);
      final x = t * size.width;
      final y = (1 - t) * (1 - t) * 8 + 2 * (1 - t) * t * 30 + t * t * 8;

      // 미세한 가랜드 살랑거림 애니메이션
      final sway = sin(animValue * 2 * pi + i * 0.8) * 2.5;

      final flagPaint = Paint()
        ..color = flagColors[i % flagColors.length].withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;

      final flagShadow = Paint()
        ..color = const Color(0x18000000)
        ..style = PaintingStyle.fill;

      final flagPath = Path()
        ..moveTo(x - flagWidth * 0.45, y)
        ..lineTo(x + flagWidth * 0.45, y)
        ..lineTo(x + sway, y + flagHeight)
        ..close();

      // 그림자
      canvas.save();
      canvas.translate(0, 2);
      canvas.drawPath(flagPath, flagShadow);
      canvas.restore();

      // 깃발
      canvas.drawPath(flagPath, flagPaint);

      // 깃발 꼭대기 작은 고정 방울 핀
      final pinPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2.2, pinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CharmingPlayroomBackgroundPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Shape Path Helpers
// ─────────────────────────────────────────────────────────────────────────────

Path _getShapePath(ShapeType type, double r) {
  switch (type) {
    case ShapeType.circle:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    case ShapeType.square:
      return Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 1.7),
        Radius.circular(r * 0.22),
      ));
    case ShapeType.triangle:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(-r * 0.95, r * 0.75)
        ..lineTo(r * 0.95, r * 0.75)
        ..close();
    case ShapeType.star: return _starPath(r);
    case ShapeType.heart: return _heartPath(r);
    case ShapeType.diamond:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.75, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.75, 0)
        ..close();
    case ShapeType.hexagon: return _polygonPath(6, r);
    case ShapeType.pentagon: return _polygonPath(5, r);
    case ShapeType.cross: return _crossPath(r);
    case ShapeType.moon: return _moonPath(r);
    
    // 추가된 다양한 형태들
    case ShapeType.bear: return _bearPath(r);
    case ShapeType.rabbit: return _rabbitPath(r);
    case ShapeType.cat: return _catPath(r);
    case ShapeType.fish: return _fishPath(r);
    case ShapeType.bird: return _birdPath(r);
    case ShapeType.flower: return _flowerPath(r);
    case ShapeType.tree: return _treePath(r);
    case ShapeType.cloud: return _cloudPath(r);
    case ShapeType.car: return _carPath(r);
    case ShapeType.boat: return _boatPath(r);
    case ShapeType.house: return _housePath(r);
    case ShapeType.castle: return _castlePath(r);
  }
}

Path _starPath(double r) {
  final path = Path();
  for (int i = 0; i < 5; i++) {
    final outerAngle = -pi / 2 + (2 * pi * i / 5);
    final innerAngle = outerAngle + pi / 5;
    final outer = Offset(cos(outerAngle) * r, sin(outerAngle) * r);
    final inner = Offset(cos(innerAngle) * r * 0.48, sin(innerAngle) * r * 0.48);
    if (i == 0) {
      path.moveTo(outer.dx, outer.dy);
    } else {
      path.lineTo(outer.dx, outer.dy);
    }
    path.lineTo(inner.dx, inner.dy);
  }
  path.close();
  return path;
}

Path _heartPath(double r) {
  final path = Path();
  path.moveTo(0, r * 0.3);
  path.cubicTo(-r * 0.1, -r * 0.1, -r, -r * 0.3, -r * 0.5, -r * 0.7);
  path.cubicTo(-r * 0.2, -r, 0, -r * 0.7, 0, -r * 0.4);
  path.cubicTo(0, -r * 0.7, r * 0.2, -r, r * 0.5, -r * 0.7);
  path.cubicTo(r, -r * 0.3, r * 0.1, -r * 0.1, 0, r * 0.3);
  path.close();
  return path;
}

Path _polygonPath(int sides, double r) {
  final path = Path();
  for (int i = 0; i < sides; i++) {
    final angle = -pi / 2 + (2 * pi * i / sides);
    final p = Offset(cos(angle) * r, sin(angle) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

Path _crossPath(double r) {
  final w = r * 0.38;
  final path = Path();
  path.moveTo(-w, -r);
  path.lineTo(w, -r);
  path.lineTo(w, -w);
  path.lineTo(r, -w);
  path.lineTo(r, w);
  path.lineTo(w, w);
  path.lineTo(w, r);
  path.lineTo(-w, r);
  path.lineTo(-w, w);
  path.lineTo(-r, w);
  path.lineTo(-r, -w);
  path.lineTo(-w, -w);
  path.close();
  return path;
}

Path _moonPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
  final cutPath = Path()
    ..addOval(Rect.fromCircle(center: Offset(r * 0.5, -r * 0.15), radius: r * 0.75));
  return Path.combine(PathOperation.difference, path, cutPath);
}

// ── 추가된 형태 (동물, 건물, 등등) ──────────────────────────────────────────────────────────

Path _bearPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.55, -r * 0.55), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.55, -r * 0.55), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.1), radius: r * 0.85));
  return path;
}

Path _rabbitPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCenter(center: Offset(-r * 0.35, -r * 0.4), width: r * 0.35, height: r * 1.4));
  path.addOval(Rect.fromCenter(center: Offset(r * 0.35, -r * 0.4), width: r * 0.35, height: r * 1.4));
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.4), radius: r * 0.75));
  return path;
}

Path _catPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.7, -r * 0.1);
  path.lineTo(-r * 0.85, -r * 0.9);
  path.lineTo(-r * 0.1, -r * 0.5);
  path.moveTo(r * 0.7, -r * 0.1);
  path.lineTo(r * 0.85, -r * 0.9);
  path.lineTo(r * 0.1, -r * 0.5);
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 0.8));
  return path;
}

Path _fishPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.4, 0);
  path.lineTo(-r * 1.1, -r * 0.6);
  path.lineTo(-r * 1.1, r * 0.6);
  path.addOval(Rect.fromCenter(center: Offset(r * 0.1, 0), width: r * 1.6, height: r * 1.1));
  return path;
}

Path _birdPath(double r) {
  final path = Path();
  path.moveTo(r * 0.6, -r * 0.4);
  path.lineTo(r * 1.1, -r * 0.2);
  path.lineTo(r * 0.6, 0);
  path.moveTo(-r * 0.6, r * 0.2);
  path.lineTo(-r * 1.2, r * 0.6);
  path.lineTo(-r * 1.0, -r * 0.1);
  path.addOval(Rect.fromCircle(center: Offset(r * 0.4, -r * 0.3), radius: r * 0.4));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.1, r * 0.2), radius: r * 0.65));
  return path;
}

Path _flowerPath(double r) {
  final path = Path();
  final int petals = 6;
  for (int i = 0; i < petals; i++) {
    final angle = 2 * pi * i / petals;
    final cx = cos(angle) * r * 0.55;
    final cy = sin(angle) * r * 0.55;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.45));
  }
  path.addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.4));
  return path;
}

Path _treePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.5), width: r * 0.35, height: r));
  path.addOval(Rect.fromCircle(center: Offset(0, -r * 0.4), radius: r * 0.65));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.45, -r * 0.1), radius: r * 0.45));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.45, -r * 0.1), radius: r * 0.45));
  return path;
}

Path _cloudPath(double r) {
  final path = Path();
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 1.8, height: r * 0.8),
    Radius.circular(r * 0.4),
  ));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.4, -r * 0.1), radius: r * 0.5));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.3, -r * 0.2), radius: r * 0.6));
  return path;
}

Path _carPath(double r) {
  final path = Path();
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 2.0, height: r * 0.7),
    Radius.circular(r * 0.2),
  ));
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(-r * 0.1, -r * 0.3), width: r * 1.2, height: r * 0.6),
    Radius.circular(r * 0.3),
  ));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.6, r * 0.6), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.6, r * 0.6), radius: r * 0.35));
  return path;
}

Path _boatPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.8, r * 0.2);
  path.lineTo(r * 0.8, r * 0.2);
  path.lineTo(r * 0.5, r * 0.7);
  path.lineTo(-r * 0.5, r * 0.7);
  path.close();
  path.addRect(Rect.fromCenter(center: Offset(r * 0.1, -r * 0.4), width: r * 0.1, height: r * 1.2));
  path.moveTo(r * 0.15, -r * 0.9);
  path.lineTo(r * 0.8, -r * 0.1);
  path.lineTo(r * 0.15, -r * 0.1);
  path.close();
  return path;
}

Path _housePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.4), width: r * 1.2, height: r * 1.0));
  path.moveTo(-r * 0.8, -r * 0.1);
  path.lineTo(r * 0.8, -r * 0.1);
  path.lineTo(0, -r * 0.9);
  path.close();
  path.addRect(Rect.fromCenter(center: Offset(r * 0.5, -r * 0.5), width: r * 0.25, height: r * 0.7));
  return path;
}

Path _castlePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.4), width: r * 1.4, height: r * 1.0));
  path.addRect(Rect.fromCenter(center: Offset(0, -r * 0.3), width: r * 0.4, height: r * 0.8));
  path.addRect(Rect.fromCenter(center: Offset(-r * 0.7, 0), width: r * 0.4, height: r * 1.8));
  path.addRect(Rect.fromCenter(center: Offset(r * 0.7, 0), width: r * 0.4, height: r * 1.8));
  
  path.moveTo(-r * 0.9, -r * 0.9);
  path.lineTo(-r * 0.5, -r * 0.9);
  path.lineTo(-r * 0.7, -r * 1.3);
  path.close();

  path.moveTo(r * 0.9, -r * 0.9);
  path.lineTo(r * 0.5, -r * 0.9);
  path.lineTo(r * 0.7, -r * 1.3);
  path.close();

  path.moveTo(-r * 0.2, -r * 0.7);
  path.lineTo(r * 0.2, -r * 0.7);
  path.lineTo(0, -r * 1.1);
  path.close();
  return path;
}
