part of '../shape_sorting_game.dart';

/// 3D 프리미엄 원목/글로시 토이 블록 페인터
/// (입체 베벨 + 새틴 그라데이션 + 도형별 아기자기한 디테일 + 반짝이는 표정 + 하이라이트)
class _ChunkyBlockPainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final Color shadowColor;
  final Color lightColor;
  final bool isDragging;
  final bool isHappy;
  final bool isHinted;

  _ChunkyBlockPainter({
    required this.type,
    required this.color,
    required this.shadowColor,
    required this.lightColor,
    this.isDragging = false,
    this.isHappy = false,
    this.isHinted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.83;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 0. 힌트 강조 시 황금빛 후광 또는 드래그 시 부드러운 플로팅 그림자
    if (isHinted) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(path, glowPaint);
    }

    final dropShadowPaint = Paint()
      ..color = shadowColor.withValues(alpha: isDragging ? 0.38 : 0.24)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragging ? 8.0 : 4.0);
    canvas.save();
    canvas.translate(0, isDragging ? 7.5 : 5.0);
    canvas.drawPath(path, dropShadowPaint);
    canvas.restore();

    // 1. 하단 3D 원목 두께 음영 (입체 블록 옆면)
    final deepShadowColor = Color.lerp(shadowColor, const Color(0xFF26140C), 0.28)!;
    final sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [shadowColor, deepShadowColor],
      ).createShader(Rect.fromCircle(center: const Offset(0, 4), radius: r))
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(0, isDragging ? 5.2 : 4.2);
    canvas.drawPath(path, sidePaint);
    canvas.restore();

    // 2. 블록 전면 새틴 그라데이션 (고급스러운 입체 볼륨감)
    final rect = Rect.fromCircle(center: Offset.zero, radius: r * 1.15);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.8, -0.9),
        end: const Alignment(0.8, 0.9),
        colors: [
          lightColor,
          color,
          Color.lerp(color, shadowColor, 0.22)!,
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. 도형 내부 클리핑 후 도형별 아기자기한 커스텀 디테일 & 상단 소프트 광택
    canvas.save();
    canvas.clipPath(path);

    _drawShapeCustomAccents(canvas, type, r);

    // 상단 부드러운 젤리/우드 광택 벨벳 레이어
    final topSheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(-r, -r, r, r * 0.2));
    canvas.drawRect(Rect.fromLTRB(-r * 1.3, -r * 1.3, r * 1.3, 0), topSheenPaint);

    // 내부 화이트 인셋 테두리 (클립 안쪽을 따라 그리는 고급 베벨 라인)
    final innerBevelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2;
    canvas.drawPath(path, innerBevelPaint);

    canvas.restore();

    // 4. 외곽 선명한 테두리
    final borderPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);

    // 5. 도형 중심에 맞춘 아기자기한 캐릭터 표정
    final faceCenter = _getFaceCenter(type, r);
    final faceScale = _getFaceScale(type);
    canvas.save();
    canvas.translate(faceCenter.dx, faceCenter.dy);
    canvas.scale(faceScale, faceScale);
    _drawCuteFace(canvas, r);
    canvas.restore();

    // 6. 좌상단 뽀얀 물방울 하이라이트 글린트
    final glintOffset = _getGlintOffset(type, r);
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(glintOffset.dx, glintOffset.dy);
    canvas.rotate(-0.45);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 0.26, height: r * 0.14),
      glossPaint,
    );
    canvas.restore();

    canvas.restore();
  }

  /// 도형별 아기자기한 포인트 장식 (속귀, 꽃술, 창문, 나무줄기, 성 깃발 등)
  void _drawShapeCustomAccents(Canvas canvas, ShapeType type, double r) {
    final softPink = Paint()
      ..color = const Color(0xFFFFCDD2).withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    final warmCream = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    switch (type) {
      case ShapeType.bear:
        // 곰돌이 분홍 속귀 & 코 주변 크림색 주둥이
        canvas.drawCircle(Offset(-r * 0.55, -r * 0.55), r * 0.18, softPink);
        canvas.drawCircle(Offset(r * 0.55, -r * 0.55), r * 0.18, softPink);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, r * 0.30), width: r * 0.46, height: r * 0.32),
          warmCream,
        );
        break;
      case ShapeType.rabbit:
        // 토끼 분홍 속귀
        canvas.drawOval(
          Rect.fromCenter(center: Offset(-r * 0.35, -r * 0.46), width: r * 0.16, height: r * 0.72),
          softPink,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(r * 0.35, -r * 0.46), width: r * 0.16, height: r * 0.72),
          softPink,
        );
        break;
      case ShapeType.cat:
        // 고양이 분홍 속귀 & 귀여운 수염
        final leftEar = Path()
          ..moveTo(-r * 0.62, -r * 0.25)
          ..lineTo(-r * 0.74, -r * 0.72)
          ..lineTo(-r * 0.26, -r * 0.46)
          ..close();
        final rightEar = Path()
          ..moveTo(r * 0.62, -r * 0.25)
          ..lineTo(r * 0.74, -r * 0.72)
          ..lineTo(r * 0.26, -r * 0.46)
          ..close();
        canvas.drawPath(leftEar, softPink);
        canvas.drawPath(rightEar, softPink);
        final whiskerPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.65)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(-r * 0.42, r * 0.22), Offset(-r * 0.66, r * 0.18), whiskerPaint);
        canvas.drawLine(Offset(-r * 0.42, r * 0.30), Offset(-r * 0.66, r * 0.33), whiskerPaint);
        canvas.drawLine(Offset(r * 0.42, r * 0.22), Offset(r * 0.66, r * 0.18), whiskerPaint);
        canvas.drawLine(Offset(r * 0.42, r * 0.30), Offset(r * 0.66, r * 0.33), whiskerPaint);
        break;
      case ShapeType.flower:
        // 꽃 중앙 노란 꽃술 링
        final centerRing = Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.75)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset.zero, r * 0.48, centerRing);
        break;
      case ShapeType.tree:
        // 나무 아래 따뜻한 원목 기둥 색상
        final trunkPaint = Paint()
          ..color = const Color(0xFF8D6E63).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(0, r * 0.62), width: r * 0.36, height: r * 0.75),
            Radius.circular(r * 0.08),
          ),
          trunkPaint,
        );
        break;
      case ShapeType.car:
        // 자동차 귀여운 창문 & 바퀴 휠
        final windowPaint = Paint()
          ..color = const Color(0xFFE1F5FE).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(-r * 0.08, -r * 0.28), width: r * 0.82, height: r * 0.34),
            Radius.circular(r * 0.14),
          ),
          windowPaint,
        );
        final wheelPaint = Paint()
          ..color = const Color(0xFF37474F)
          ..style = PaintingStyle.fill;
        final hubPaint = Paint()
          ..color = const Color(0xFFFFF59D)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(-r * 0.55, r * 0.55), r * 0.24, wheelPaint);
        canvas.drawCircle(Offset(r * 0.55, r * 0.55), r * 0.24, wheelPaint);
        canvas.drawCircle(Offset(-r * 0.55, r * 0.55), r * 0.11, hubPaint);
        canvas.drawCircle(Offset(r * 0.55, r * 0.55), r * 0.11, hubPaint);
        break;
      case ShapeType.boat:
        // 돛단배 흰색 돛 하이라이트
        final sailPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill;
        final sailPath = Path()
          ..moveTo(r * 0.10, -r * 0.78)
          ..lineTo(r * 0.66, -r * 0.12)
          ..lineTo(r * 0.10, -r * 0.12)
          ..close();
        canvas.drawPath(sailPath, sailPaint);
        break;
      case ShapeType.house:
        // 집 지붕 코랄 포인트 & 아치형 문
        final roofPaint = Paint()
          ..color = const Color(0xFFFF7043).withValues(alpha: 0.75)
          ..style = PaintingStyle.fill;
        final roofPath = Path()
          ..moveTo(-r * 0.88, -r * 0.08)
          ..lineTo(r * 0.88, -r * 0.08)
          ..lineTo(0, -r * 0.92)
          ..close();
        canvas.drawPath(roofPath, roofPaint);
        break;
      case ShapeType.castle:
        // 성 지붕 골드/핑크 포인트
        final roofPaint = Paint()
          ..color = const Color(0xFFFF80AB).withValues(alpha: 0.75)
          ..style = PaintingStyle.fill;
        canvas.drawRect(Rect.fromLTRB(-r, -r * 1.35, r, -r * 0.65), roofPaint);
        break;
      default:
        break;
    }
  }

  Offset _getFaceCenter(ShapeType type, double r) {
    switch (type) {
      case ShapeType.moon:
        return Offset(-r * 0.34, r * 0.02);
      case ShapeType.rabbit:
        return Offset(0, r * 0.36);
      case ShapeType.bear:
        return Offset(0, r * 0.10);
      case ShapeType.cat:
        return Offset(0, r * 0.18);
      case ShapeType.fish:
        return Offset(r * 0.18, 0);
      case ShapeType.bird:
        return Offset(-r * 0.04, r * 0.14);
      case ShapeType.tree:
        return Offset(0, -r * 0.25);
      case ShapeType.cloud:
        return Offset(0, r * 0.08);
      case ShapeType.car:
        return Offset(0, r * 0.16);
      case ShapeType.boat:
        return Offset(0, r * 0.38);
      case ShapeType.house:
        return Offset(0, r * 0.32);
      case ShapeType.castle:
        return Offset(0, r * 0.35);
      case ShapeType.triangle:
        return Offset(0, r * 0.18);
      case ShapeType.heart:
        return Offset(0, -r * 0.15);
      default:
        return Offset.zero;
    }
  }

  double _getFaceScale(ShapeType type) {
    switch (type) {
      case ShapeType.moon:
      case ShapeType.boat:
      case ShapeType.car:
        return 0.78;
      case ShapeType.cross:
      case ShapeType.tree:
      case ShapeType.bird:
        return 0.85;
      default:
        return 1.0;
    }
  }

  Offset _getGlintOffset(ShapeType type, double r) {
    switch (type) {
      case ShapeType.moon:
        return Offset(-r * 0.42, -r * 0.45);
      case ShapeType.rabbit:
        return Offset(-r * 0.32, r * 0.02);
      case ShapeType.triangle:
        return Offset(-r * 0.18, -r * 0.35);
      case ShapeType.heart:
        return Offset(-r * 0.42, -r * 0.52);
      default:
        return Offset(-r * 0.34, -r * 0.36);
    }
  }

  void _drawCuteFace(Canvas canvas, double r) {
    final eyeColor = const Color(0xFF2D1E18);
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;

    final whiteGlint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    final eyeSpacing = r * 0.27;
    final eyeY = -r * 0.05;
    final eyeRadius = r * 0.095;

    // 핑크빛 발그레 볼터치 + 작은 하이라이트
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-eyeSpacing * 1.38, eyeY + r * 0.16), width: r * 0.24, height: r * 0.14),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeSpacing * 1.38, eyeY + r * 0.16), width: r * 0.24, height: r * 0.14),
      blushPaint,
    );

    if (isHappy) {
      // 쏙 들어갔을 때 방긋 눈웃음 (^ ◡ ^)
      final happyEyePaint = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      final leftArc = Path()
        ..moveTo(-eyeSpacing - eyeRadius, eyeY + 2)
        ..quadraticBezierTo(-eyeSpacing, eyeY - eyeRadius * 1.35, -eyeSpacing + eyeRadius, eyeY + 2);
      final rightArc = Path()
        ..moveTo(eyeSpacing - eyeRadius, eyeY + 2)
        ..quadraticBezierTo(eyeSpacing, eyeY - eyeRadius * 1.35, eyeSpacing + eyeRadius, eyeY + 2);
      canvas.drawPath(leftArc, happyEyePaint);
      canvas.drawPath(rightArc, happyEyePaint);
    } else {
      // 초롱초롱한 큰 눈 + 더블 반짝이 하이라이트
      canvas.drawCircle(Offset(-eyeSpacing, eyeY), eyeRadius, eyePaint);
      canvas.drawCircle(Offset(eyeSpacing, eyeY), eyeRadius, eyePaint);

      canvas.drawCircle(
        Offset(-eyeSpacing - eyeRadius * 0.28, eyeY - eyeRadius * 0.28),
        eyeRadius * 0.42,
        whiteGlint,
      );
      canvas.drawCircle(
        Offset(eyeSpacing - eyeRadius * 0.28, eyeY - eyeRadius * 0.28),
        eyeRadius * 0.42,
        whiteGlint,
      );
      canvas.drawCircle(
        Offset(-eyeSpacing + eyeRadius * 0.25, eyeY + eyeRadius * 0.25),
        eyeRadius * 0.18,
        whiteGlint,
      );
      canvas.drawCircle(
        Offset(eyeSpacing + eyeRadius * 0.25, eyeY + eyeRadius * 0.25),
        eyeRadius * 0.18,
        whiteGlint,
      );
    }

    // 입 모양
    if (isDragging) {
      // 신나서 '우와~' 입을 벌린 모양
      final openMouth = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.fill;
      final mouthRect = Rect.fromCenter(
        center: Offset(0, r * 0.18),
        width: r * 0.22,
        height: r * 0.25,
      );
      canvas.drawOval(mouthRect, openMouth);

      final tonguePaint = Paint()
        ..color = const Color(0xFFFF80AB)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, r * 0.23), width: r * 0.14, height: r * 0.10),
        tonguePaint,
      );
    } else if (isHappy) {
      // 함박웃음 입 (속에 귀여운 분홍 혀)
      final mouthPath = Path()
        ..moveTo(-r * 0.17, r * 0.12)
        ..lineTo(r * 0.17, r * 0.12)
        ..quadraticBezierTo(0, r * 0.36, -r * 0.17, r * 0.12)
        ..close();
      canvas.drawPath(mouthPath, eyePaint);

      final tonguePaint = Paint()
        ..color = const Color(0xFFFF80AB)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, r * 0.20), width: r * 0.16, height: r * 0.09),
        tonguePaint,
      );
    } else {
      // 따뜻한 미소
      final smilePaint = Paint()
        ..color = eyeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(-r * 0.14, r * 0.13)
        ..quadraticBezierTo(0, r * 0.27, r * 0.14, r * 0.13);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChunkyBlockPainter old) =>
      old.type != type ||
      old.color != color ||
      old.isDragging != isDragging ||
      old.isHappy != isHappy ||
      old.isHinted != isHinted;
}

/// 원목 보드 음각 구멍 페인터 (깊이감 있는 나무 홈 + 나뭇결 + 마법 힌트 링)
class _SlotHolePainter extends CustomPainter {
  final ShapeType type;
  final Color accentColor;
  final bool isHovering;
  final bool isHinted;

  _SlotHolePainter({
    required this.type,
    required this.accentColor,
    required this.isHovering,
    this.isHinted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.83;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 0. 하단 밝은 원목 베벨 림 (음각 홈의 아랫면 빛 반사)
    final bottomHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(0, 2.0);
    canvas.drawPath(path, bottomHighlightPaint);
    canvas.restore();

    // 1. 음각 원목 홈 베이스 컬러
    final cavityBaseColor = isHovering || isHinted
        ? Color.lerp(const Color(0xFFF3E5D0), accentColor, 0.25)!
        : Color.lerp(const Color(0xFFEBD9C0), accentColor, 0.12)!;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(cavityBaseColor, const Color(0xFF8D6E63), 0.18)!,
          cavityBaseColor,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 2. 홈 내부 상단 이너 섀도우 & 은은한 나뭇결
    canvas.save();
    canvas.clipPath(path);

    // 나뭇결 결무늬
    final grainPaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = -2; i <= 2; i++) {
      final gy = i * (r * 0.35);
      final grainPath = Path()
        ..moveTo(-r, gy)
        ..quadraticBezierTo(0, gy + 5, r, gy - 2);
      canvas.drawPath(grainPath, grainPaint);
    }

    // 중앙 반투명 가이드 실루엣
    final silhouettePaint = Paint()
      ..color = accentColor.withValues(alpha: isHovering || isHinted ? 0.28 : 0.16)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_getShapePath(type, r * 0.56), silhouettePaint);

    canvas.restore();

    // 3. 점선 가이드 테두리
    final dashPaint = Paint()
      ..color = (isHovering || isHinted)
          ? accentColor
          : accentColor.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isHovering || isHinted) ? 3.0 : 2.2
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, dashPaint);

    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final dashLen = min(6.0, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + dashLen);
        canvas.drawPath(extractPath, paint);
        distance += 10.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlotHolePainter old) =>
      old.type != type ||
      old.accentColor != accentColor ||
      old.isHovering != isHovering ||
      old.isHinted != isHinted;
}

/// 스냅 성공 시 화면에 팡! 터지는 별·하트·반짝이 파티클 오버레이 페인터
class _SparkleOverlayPainter extends CustomPainter {
  final List<_SparkleParticle> particles;

  _SparkleOverlayPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = p.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      final r = p.size * (0.5 + 0.5 * alpha);
      if (p.kind == 0) {
        // 별 파티클
        canvas.drawPath(_starPath(r), paint);
      } else if (p.kind == 1) {
        // 하트 파티클
        canvas.drawPath(_heartPath(r * 1.15), paint);
      } else {
        // 반짝이 구슬 파티클
        canvas.drawCircle(Offset.zero, r * 0.7, paint);
        final whiteCore = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.85);
        canvas.drawCircle(Offset(-r * 0.2, -r * 0.2), r * 0.25, whiteCore);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleOverlayPainter oldDelegate) => true;
}

/// 아기자기하고 고급스러운 파스텔 플레이룸 배경 페인터
class _CharmingPlayroomBackgroundPainter extends CustomPainter {
  final double animValue;

  _CharmingPlayroomBackgroundPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 0. 상단 따뜻한 햇살 보케 서클
    _drawWarmBokeh(canvas, size);

    // 1. 은은한 파스텔 도트 패턴
    _drawPolkaDots(canvas, size);

    // 2. 하단 동화풍 언덕 & 미니 꽃/나무 풍경
    _drawBottomHills(canvas, size);

    // 3. 둥실둥실 떠다니는 귀여운 표정 구름들
    _drawCuteClouds(canvas, size);

    // 4. 공간을 채우는 반짝이 별 & 비눗방울
    _drawFloatingAccents(canvas, size);

    // 5. 상단 삼각 가랜드 (Bunting Flags)
    _drawTopGarland(canvas, size);
  }

  void _drawWarmBokeh(Canvas canvas, Size size) {
    final bokeh1 = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final bokeh2 = Paint()
      ..color = const Color(0xFFFFCCBC).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15 + sin(animValue * 2 * pi) * 8),
      72,
      bokeh1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.35 + cos(animValue * 2 * pi) * 8),
      58,
      bokeh2,
    );
  }

  void _drawPolkaDots(Canvas canvas, Size size) {
    final dotColors = [
      const Color(0x1CFF8A80),
      const Color(0x1C80D8FF),
      const Color(0x1CFFD180),
      const Color(0x1CB9F6CA),
      const Color(0x1CEA80FC),
    ];
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const step = 44.0;
    int idx = 0;
    for (double y = 50; y < size.height - 40; y += step) {
      final isOdd = (idx % 2 == 1);
      for (double x = isOdd ? step : step / 2; x < size.width; x += step) {
        dotPaint.color = dotColors[(idx + (x ~/ step)) % dotColors.length];
        canvas.drawCircle(Offset(x, y), 2.3, dotPaint);
      }
      idx++;
    }
  }

  void _drawBottomHills(Canvas canvas, Size size) {
    final hillPaint1 = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.42)
      ..style = PaintingStyle.fill;

    final hillPath1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 82)
      ..quadraticBezierTo(
          size.width * 0.35, size.height - 118, size.width * 0.75, size.height - 70)
      ..quadraticBezierTo(
          size.width * 0.9, size.height - 48, size.width, size.height - 60)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;

    final hillPath2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 44)
      ..quadraticBezierTo(
          size.width * 0.25, size.height - 66, size.width * 0.55, size.height - 38)
      ..quadraticBezierTo(
          size.width * 0.8, size.height - 18, size.width, size.height - 34)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath2, hillPaint2);
  }

  void _drawCuteClouds(Canvas canvas, Size size) {
    final c1Y = 78 + sin(animValue * 2 * pi) * 5;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.16, c1Y),
      width: 88,
      height: 48,
      hasHappyFace: true,
    );

    final c2Y = 115 + cos(animValue * 2 * pi) * 6;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.86, c2Y),
      width: 76,
      height: 42,
      hasHappyFace: true,
    );

    final c3Y = size.height * 0.52 + sin(animValue * 2 * pi + 1.5) * 4;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.08, c3Y),
      width: 60,
      height: 34,
      hasHappyFace: false,
      alpha: 0.55,
    );

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

    final r = height / 2;
    void drawPuffs(Paint p) {
      canvas.drawCircle(Offset(-width * 0.22, 0), r * 0.85, p);
      canvas.drawCircle(Offset(0, -r * 0.28), r * 1.05, p);
      canvas.drawCircle(Offset(width * 0.24, 0), r * 0.8, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, r * 0.2), width: width * 0.85, height: r * 0.85),
          Radius.circular(r * 0.5),
        ),
        p,
      );
    }

    canvas.save();
    canvas.translate(0, 3.5);
    drawPuffs(shadowPaint);
    canvas.restore();

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

      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 4), width: 7, height: 4.5),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(14, 4), width: 7, height: 4.5),
        blushPaint,
      );

      final eyePath1 = Path()
        ..moveTo(-12, 1)
        ..quadraticBezierTo(-9, -3.5, -6, 1);
      final eyePath2 = Path()
        ..moveTo(6, 1)
        ..quadraticBezierTo(9, -3.5, 12, 1);
      canvas.drawPath(eyePath1, eyePaint);
      canvas.drawPath(eyePath2, eyePaint);

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

  void _drawSparkleStar(Canvas canvas, Offset center,
      {required double size, required Color color}) {
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

    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, r * 0.28, whitePaint);

    canvas.restore();
  }

  void _drawPastelBubble(Canvas canvas, Offset center,
      {required double radius, required Color color}) {
    final bubblePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bubblePaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(center.dx - radius * 0.32, center.dy - radius * 0.32),
        radius * 0.28,
        glintPaint);
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

      canvas.save();
      canvas.translate(0, 2);
      canvas.drawPath(flagPath, flagShadow);
      canvas.restore();

      canvas.drawPath(flagPath, flagPaint);

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
// Shared Shape Path Helpers (모든 도형이 끊김 없는 닫힌 유니온 실루엣을 갖도록 구성)
// ─────────────────────────────────────────────────────────────────────────────

Path _unionShapePaths(List<Path> parts) {
  if (parts.isEmpty) return Path();
  Path combined = parts.first;
  for (int i = 1; i < parts.length; i++) {
    combined = Path.combine(PathOperation.union, combined, parts[i]);
  }
  return combined;
}

Path _getShapePath(ShapeType type, double r) {
  switch (type) {
    case ShapeType.circle:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    case ShapeType.square:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.72, height: r * 1.72),
          Radius.circular(r * 0.26),
        ));
    case ShapeType.triangle:
      return Path()
        ..moveTo(0, -r * 0.96)
        ..lineTo(-r * 0.96, r * 0.78)
        ..lineTo(r * 0.96, r * 0.78)
        ..close();
    case ShapeType.star:
      return _starPath(r);
    case ShapeType.heart:
      return _heartPath(r);
    case ShapeType.diamond:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.78, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.78, 0)
        ..close();
    case ShapeType.hexagon:
      return _polygonPath(6, r);
    case ShapeType.pentagon:
      return _polygonPath(5, r);
    case ShapeType.cross:
      return _crossPath(r);
    case ShapeType.moon:
      return _moonPath(r);
    case ShapeType.bear:
      return _bearPath(r);
    case ShapeType.rabbit:
      return _rabbitPath(r);
    case ShapeType.cat:
      return _catPath(r);
    case ShapeType.fish:
      return _fishPath(r);
    case ShapeType.bird:
      return _birdPath(r);
    case ShapeType.flower:
      return _flowerPath(r);
    case ShapeType.tree:
      return _treePath(r);
    case ShapeType.cloud:
      return _cloudPath(r);
    case ShapeType.car:
      return _carPath(r);
    case ShapeType.boat:
      return _boatPath(r);
    case ShapeType.house:
      return _housePath(r);
    case ShapeType.castle:
      return _castlePath(r);
  }
}

Path _starPath(double r) {
  final path = Path();
  for (int i = 0; i < 5; i++) {
    final outerAngle = -pi / 2 + (2 * pi * i / 5);
    final innerAngle = outerAngle + pi / 5;
    final outer = Offset(cos(outerAngle) * r, sin(outerAngle) * r);
    final inner = Offset(cos(innerAngle) * r * 0.50, sin(innerAngle) * r * 0.50);
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
  path.moveTo(0, r * 0.82);
  path.cubicTo(-r * 1.15, r * 0.12, -r * 0.95, -r * 0.88, 0, -r * 0.35);
  path.cubicTo(r * 0.95, -r * 0.88, r * 1.15, r * 0.12, 0, r * 0.82);
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
  return _unionShapePaths([
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 2, height: r * 1.9),
        Radius.circular(r * 0.14),
      )),
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.9, height: w * 2),
        Radius.circular(r * 0.14),
      )),
  ]);
}

Path _moonPath(double r) {
  final path = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
  final cutPath = Path()
    ..addOval(Rect.fromCircle(center: Offset(r * 0.48, -r * 0.12), radius: r * 0.74));
  return Path.combine(PathOperation.difference, path, cutPath);
}

Path _bearPath(double r) {
  return _unionShapePaths([
    Path()..addOval(Rect.fromCircle(center: Offset(-r * 0.55, -r * 0.55), radius: r * 0.36)),
    Path()..addOval(Rect.fromCircle(center: Offset(r * 0.55, -r * 0.55), radius: r * 0.36)),
    Path()..addOval(Rect.fromCircle(center: Offset(0, r * 0.10), radius: r * 0.84)),
  ]);
}

Path _rabbitPath(double r) {
  return _unionShapePaths([
    Path()
      ..addOval(Rect.fromCenter(
          center: Offset(-r * 0.35, -r * 0.42), width: r * 0.38, height: r * 1.15)),
    Path()
      ..addOval(Rect.fromCenter(
          center: Offset(r * 0.35, -r * 0.42), width: r * 0.38, height: r * 1.15)),
    Path()..addOval(Rect.fromCircle(center: Offset(0, r * 0.34), radius: r * 0.68)),
  ]);
}

Path _catPath(double r) {
  final leftEar = Path()
    ..moveTo(-r * 0.72, -r * 0.05)
    ..lineTo(-r * 0.84, -r * 0.88)
    ..lineTo(-r * 0.12, -r * 0.48)
    ..close();
  final rightEar = Path()
    ..moveTo(r * 0.72, -r * 0.05)
    ..lineTo(r * 0.84, -r * 0.88)
    ..lineTo(r * 0.12, -r * 0.48)
    ..close();
  final head = Path()..addOval(Rect.fromCircle(center: Offset(0, r * 0.16), radius: r * 0.78));
  return _unionShapePaths([head, leftEar, rightEar]);
}

Path _fishPath(double r) {
  final tail = Path()
    ..moveTo(-r * 0.35, 0)
    ..lineTo(-r * 1.02, -r * 0.58)
    ..lineTo(-r * 1.02, r * 0.58)
    ..close();
  final body = Path()
    ..addOval(Rect.fromCenter(center: Offset(r * 0.14, 0), width: r * 1.48, height: r * 1.06));
  return _unionShapePaths([body, tail]);
}

Path _birdPath(double r) {
  final beak = Path()
    ..moveTo(r * 0.52, -r * 0.38)
    ..lineTo(r * 1.02, -r * 0.20)
    ..lineTo(r * 0.52, -r * 0.02)
    ..close();
  final tail = Path()
    ..moveTo(-r * 0.45, r * 0.15)
    ..lineTo(-r * 1.05, r * 0.52)
    ..lineTo(-r * 0.92, -r * 0.08)
    ..close();
  final head = Path()..addOval(Rect.fromCircle(center: Offset(r * 0.34, -r * 0.25), radius: r * 0.42));
  final body = Path()..addOval(Rect.fromCircle(center: Offset(-r * 0.08, r * 0.18), radius: r * 0.62));
  return _unionShapePaths([body, head, beak, tail]);
}

Path _flowerPath(double r) {
  final parts = <Path>[
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.45)),
  ];
  const int petals = 6;
  for (int i = 0; i < petals; i++) {
    final angle = 2 * pi * i / petals;
    final cx = cos(angle) * r * 0.52;
    final cy = sin(angle) * r * 0.52;
    parts.add(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.44)));
  }
  return _unionShapePaths(parts);
}

Path _treePath(double r) {
  return _unionShapePaths([
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, r * 0.48), width: r * 0.38, height: r * 0.96),
        Radius.circular(r * 0.08),
      )),
    Path()..addOval(Rect.fromCircle(center: Offset(0, -r * 0.38), radius: r * 0.62)),
    Path()..addOval(Rect.fromCircle(center: Offset(-r * 0.42, -r * 0.08), radius: r * 0.45)),
    Path()..addOval(Rect.fromCircle(center: Offset(r * 0.42, -r * 0.08), radius: r * 0.45)),
  ]);
}

Path _cloudPath(double r) {
  return _unionShapePaths([
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, r * 0.20), width: r * 1.72, height: r * 0.78),
        Radius.circular(r * 0.38),
      )),
    Path()..addOval(Rect.fromCircle(center: Offset(-r * 0.38, -r * 0.08), radius: r * 0.48)),
    Path()..addOval(Rect.fromCircle(center: Offset(r * 0.26, -r * 0.18), radius: r * 0.56)),
  ]);
}

Path _carPath(double r) {
  return _unionShapePaths([
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, r * 0.18), width: r * 1.86, height: r * 0.68),
        Radius.circular(r * 0.22),
      )),
    Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-r * 0.08, -r * 0.28), width: r * 1.15, height: r * 0.58),
        Radius.circular(r * 0.26),
      )),
    Path()..addOval(Rect.fromCircle(center: Offset(-r * 0.55, r * 0.55), radius: r * 0.32)),
    Path()..addOval(Rect.fromCircle(center: Offset(r * 0.55, r * 0.55), radius: r * 0.32)),
  ]);
}

Path _boatPath(double r) {
  final hull = Path()
    ..moveTo(-r * 0.88, r * 0.18)
    ..lineTo(r * 0.88, r * 0.18)
    ..lineTo(r * 0.54, r * 0.74)
    ..lineTo(-r * 0.54, r * 0.74)
    ..close();
  final mast = Path()
    ..addRect(Rect.fromCenter(center: Offset(r * 0.06, -r * 0.32), width: r * 0.14, height: r * 1.12));
  final sail = Path()
    ..moveTo(r * 0.06, -r * 0.88)
    ..lineTo(r * 0.78, -r * 0.06)
    ..lineTo(r * 0.06, -r * 0.06)
    ..close();
  return _unionShapePaths([hull, mast, sail]);
}

Path _housePath(double r) {
  final body = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, r * 0.36), width: r * 1.24, height: r * 0.96),
      Radius.circular(r * 0.12),
    ));
  final roof = Path()
    ..moveTo(-r * 0.86, -r * 0.06)
    ..lineTo(r * 0.86, -r * 0.06)
    ..lineTo(0, -r * 0.90)
    ..close();
  final chimney = Path()
    ..addRect(Rect.fromCenter(center: Offset(r * 0.46, -r * 0.48), width: r * 0.24, height: r * 0.58));
  return _unionShapePaths([body, roof, chimney]);
}

Path _castlePath(double r) {
  final base = Path()
    ..addRect(Rect.fromCenter(center: Offset(0, r * 0.36), width: r * 1.36, height: r * 0.92));
  final midTower = Path()
    ..addRect(Rect.fromCenter(center: Offset(0, -r * 0.24), width: r * 0.44, height: r * 0.82));
  final leftTower = Path()
    ..addRect(Rect.fromCenter(center: Offset(-r * 0.62, 0), width: r * 0.38, height: r * 1.62));
  final rightTower = Path()
    ..addRect(Rect.fromCenter(center: Offset(r * 0.62, 0), width: r * 0.38, height: r * 1.62));
  final leftRoof = Path()
    ..moveTo(-r * 0.86, -r * 0.78)
    ..lineTo(-r * 0.38, -r * 0.78)
    ..lineTo(-r * 0.62, -r * 1.18)
    ..close();
  final rightRoof = Path()
    ..moveTo(r * 0.86, -r * 0.78)
    ..lineTo(r * 0.38, -r * 0.78)
    ..lineTo(r * 0.62, -r * 1.18)
    ..close();
  final midRoof = Path()
    ..moveTo(-r * 0.26, -r * 0.62)
    ..lineTo(r * 0.26, -r * 0.62)
    ..lineTo(0, -r * 1.02)
    ..close();
  return _unionShapePaths([base, midTower, leftTower, rightTower, leftRoof, rightRoof, midRoof]);
}
