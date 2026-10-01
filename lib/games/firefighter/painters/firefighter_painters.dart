part of '../firefighter_game.dart';

class _BuildingScenePainter extends CustomPainter {
  final String type;
  final List<FireSpot> spots;

  _BuildingScenePainter({
    required this.type,
    this.spots = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 'apartment') {
      _drawApartment(canvas, size);
    } else if (type == 'forest') {
      _drawForest(canvas, size);
    } else if (type == 'castle') {
      _drawCastle(canvas, size);
    } else if (type == 'bakery') {
      _drawBakery(canvas, size);
    } else if (type == 'space') {
      _drawSpaceStation(canvas, size);
    } else if (type == 'ship') {
      _drawPirateShip(canvas, size);
    } else if (type == 'lighthouse') {
      _drawLighthouse(canvas, size);
    } else if (type == 'airport') {
      _drawAirportTower(canvas, size);
    } else {
      _drawApartment(canvas, size);
    }

    _drawFireInteractions(canvas, size);
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 공통 실시간 화재/소화 동적 인터랙션 (Dynamic Soot, Heat Glow & Water Streaks)
  // ═════════════════════════════════════════════════════════════════════════════
  void _drawFireInteractions(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (final spot in spots) {
      final sx = spot.relativePos.dx * w;
      final sy = spot.relativePos.dy * h;
      final sr = spot.radius;

      if (!spot.isExtinguished) {
        // 1. 화재 그을음 (창틀 상단으로 피어오르는 검은 연기 그을음)
        final sootPath = Path()
          ..addOval(Rect.fromCenter(
            center: Offset(sx, sy - sr * 0.35),
            width: sr * 2.4,
            height: sr * 2.0,
          ));
        final sootPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.black.withValues(alpha: 0.35),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(sx, sy - sr * 0.35), radius: sr * 1.5));
        canvas.drawPath(sootPath, sootPaint);

        // 2. 화염 반사광 (벽면을 붉게 물들이는 동적 앰버/오렌지 빛)
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF5722).withValues(alpha: 0.45),
              const Color(0xFFFF9800).withValues(alpha: 0.22),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(sx, sy), radius: sr * 2.2));
        canvas.drawCircle(Offset(sx, sy), sr * 2.2, glowPaint);
      } else {
        // 소화 완료: 식어버린 검은 그을음 흔적 + 물줄기 자국
        final coldSootPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFF1E293B).withValues(alpha: 0.45),
              const Color(0xFF334155).withValues(alpha: 0.20),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: Offset(sx, sy - sr * 0.2), radius: sr * 1.3));
        canvas.drawCircle(Offset(sx, sy - sr * 0.2), sr * 1.3, coldSootPaint);

        // 촉촉하게 흘러내리는 소화수(Water Runoff Streaks)
        final waterPaint = Paint()
          ..color = const Color(0xFF60A5FA).withValues(alpha: 0.35)
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(sx - sr * 0.35, sy + sr * 0.3), Offset(sx - sr * 0.35, sy + sr * 1.1), waterPaint);
        canvas.drawLine(Offset(sx + sr * 0.25, sy + sr * 0.4), Offset(sx + sr * 0.25, sy + sr * 1.3), waterPaint);
        canvas.drawLine(Offset(sx, sy + sr * 0.5), Offset(sx, sy + sr * 1.2), waterPaint);
      }
    }
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. 도심 아파트 (Realistic Urban High-Rise Building with Fire Escape & Street)
  // ═════════════════════════════════════════════════════════════════════════════
  void _drawApartment(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ─────────────────────────────────────────────────────────────────────────
    // 1-1. 원경 도심 고층 빌딩 스카이라인 (Distant City Skyline)
    // ─────────────────────────────────────────────────────────────────────────
    final skylinePaint1 = Paint()..color = const Color(0xFF475569).withValues(alpha: 0.35);
    final skylinePaint2 = Paint()..color = const Color(0xFF334155).withValues(alpha: 0.55);

    // 원경 실루엣 1 (먼 빌딩들)
    canvas.drawRect(Rect.fromLTWH(w * 0.02, h * 0.16, w * 0.16, h * 0.58), skylinePaint1);
    canvas.drawRect(Rect.fromLTWH(w * 0.82, h * 0.14, w * 0.16, h * 0.60), skylinePaint1);
    // 안테나 & 항공장애등
    canvas.drawLine(Offset(w * 0.10, h * 0.16), Offset(w * 0.10, h * 0.11), Paint()..color = Colors.white54..strokeWidth = 2);
    canvas.drawCircle(Offset(w * 0.10, h * 0.11), 2.5, Paint()..color = const Color(0xFFEF4444));

    // 원경 실루엣 2 (가까운 빌딩들)
    canvas.drawRect(Rect.fromLTWH(w * 0.06, h * 0.20, w * 0.14, h * 0.54), skylinePaint2);
    canvas.drawRect(Rect.fromLTWH(w * 0.80, h * 0.19, w * 0.15, h * 0.55), skylinePaint2);
    // 창문 불빛 그리드
    final winDotPaint = Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.4);
    for (double by = h * 0.22; by < h * 0.65; by += 16) {
      canvas.drawRect(Rect.fromLTWH(w * 0.08, by, 6, 8), winDotPaint);
      canvas.drawRect(Rect.fromLTWH(w * 0.84, by, 6, 8), winDotPaint);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1-2. 거리 및 인도 인프라 (Street Asphalt, Sidewalk, Fire Hydrant & Lamp)
    // ─────────────────────────────────────────────────────────────────────────
    // 아스팔트 차도 (Street Roadway)
    final roadRect = Rect.fromLTRB(0, h * 0.74, w, h * 0.82);
    final roadPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(roadRect);
    canvas.drawRect(roadRect, roadPaint);

    // 노란색 도로 차선 (Road Marking Lines)
    final dashPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.8)
      ..strokeWidth = 4;
    for (double x = 20; x < w; x += 40) {
      canvas.drawLine(Offset(x, h * 0.78), Offset(x + 24, h * 0.78), dashPaint);
    }

    // 보도블록 인도 (Paved Sidewalk with Granite Curb)
    final walkRect = Rect.fromLTRB(0, h * 0.705, w, h * 0.74);
    final walkPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      ).createShader(walkRect);
    canvas.drawRect(walkRect, walkPaint);

    // 보도블록 이음매 (Pavement Texture Lines)
    final paveLinePaint = Paint()..color = const Color(0xFF94A3B8).withValues(alpha: 0.5)..strokeWidth = 1.2;
    for (double x = 15; x < w; x += 30) {
      canvas.drawLine(Offset(x, h * 0.705), Offset(x, h * 0.74), paveLinePaint);
    }

    // 화강석 연석 (Granite Curb Stone Border)
    canvas.drawLine(
      Offset(0, h * 0.74),
      Offset(w, h * 0.74),
      Paint()..color = const Color(0xFF64748B)..strokeWidth = 3,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // 1-3. 도로변 리얼 소화전 (Realistic Fire Hydrant) at left
    // ─────────────────────────────────────────────────────────────────────────
    final hyX = w * 0.08;
    final hyY = h * 0.708;

    // 소화전 그림자
    canvas.drawOval(Rect.fromCenter(center: Offset(hyX, hyY + 14), width: 26, height: 8), Paint()..color = Colors.black38);
    // 소화전 몸통 (Bright Fire Red Cylinder)
    final hydPath = Path()
      ..moveTo(hyX - 7, hyY + 14)
      ..lineTo(hyX - 7, hyY - 10)
      ..quadraticBezierTo(hyX, hyY - 20, hyX + 7, hyY - 10)
      ..lineTo(hyX + 7, hyY + 14)
      ..close();
    canvas.drawPath(hydPath, Paint()..color = const Color(0xFFDC2626));
    // 상단 조작 밸브 너트 (Operating Nut)
    canvas.drawRect(Rect.fromLTWH(hyX - 3, hyY - 22, 6, 4), Paint()..color = const Color(0xFFB91C1C));
    // 좌우 황동/은색 소화 호스 체결구 (Side Nozzles & Caps)
    canvas.drawRect(Rect.fromLTWH(hyX - 11, hyY - 4, 4, 7), Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRect(Rect.fromLTWH(hyX + 7, hyY - 4, 4, 7), Paint()..color = const Color(0xFFE2E8F0));

    // ─────────────────────────────────────────────────────────────────────────
    // 1-4. 도로변 모던 가로등 (Modern Streetlamp) at right
    // ─────────────────────────────────────────────────────────────────────────
    final lampX = w * 0.92;
    final lampY = h * 0.71;
    final lampPolePaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(lampX, lampY + 12), Offset(lampX, h * 0.52), lampPolePaint);
    // 곡선 암
    final lampArm = Path()
      ..moveTo(lampX, h * 0.52)
      ..quadraticBezierTo(lampX - 14, h * 0.50, lampX - 20, h * 0.53);
    canvas.drawPath(lampArm, Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.stroke..strokeWidth = 3.5);
    // 전등 갓 & 빛
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lampX - 25, h * 0.525, 10, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF334155));
    canvas.drawCircle(Offset(lampX - 20, h * 0.532), 4, Paint()..color = const Color(0xFFFEF08A));

    // ─────────────────────────────────────────────────────────────────────────
    // 1-5. 메인 아파트 건축 외벽 (Modern Terracotta & Stone Facade)
    // ─────────────────────────────────────────────────────────────────────────
    final bLeft = w * 0.13;
    final bRight = w * 0.87;
    final bTop = h * 0.22;
    final bBottom = h * 0.71;
    final bWidth = bRight - bLeft;

    // 건물 입체 그림자
    final buildShadow = RRect.fromRectAndRadius(
      Rect.fromLTRB(bLeft - 4, bTop - 2, bRight + 12, bBottom + 4),
      const Radius.circular(16),
    );
    canvas.drawRRect(buildShadow, Paint()..color = Colors.black.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // 메인 벽체 (클래식 모던 적벽돌 & 샌드스톤)
    final wallRRect = RRect.fromRectAndRadius(Rect.fromLTRB(bLeft, bTop, bRight, bBottom), const Radius.circular(14));
    final wallGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFC2410C), Color(0xFF9A3412), Color(0xFF7C2D12)],
    ).createShader(Rect.fromLTRB(bLeft, bTop, bRight, bBottom));
    canvas.drawRRect(wallRRect, Paint()..shader = wallGrad);

    // 정교한 벽돌 줄눈 텍스처 (Architectural Brick Course Lines)
    final mortarPaint = Paint()..color = const Color(0xFF431407).withValues(alpha: 0.25)..strokeWidth = 1.0;
    for (double y = bTop + 8; y < bBottom; y += 10) {
      canvas.drawLine(Offset(bLeft + 6, y), Offset(bRight - 6, y), mortarPaint);
    }

    // 1층 중후한 화강석/대리석 석재 베이스 (Rusticated Stone Base for 1F)
    final stoneBaseRRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(bLeft, h * 0.56, bRight, bBottom),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );
    final stoneGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF475569), Color(0xFF334155), Color(0xFF1E293B)],
    ).createShader(Rect.fromLTRB(bLeft, h * 0.56, bRight, bBottom));
    canvas.drawRRect(stoneBaseRRect, Paint()..shader = stoneGrad);

    // ─────────────────────────────────────────────────────────────────────────
    // 1-6. 층별 입체 석재 몰딩 (Cornice & Floor Belt Courses)
    // ─────────────────────────────────────────────────────────────────────────
    final cornicePaint = Paint()..color = const Color(0xFFE2E8F0);
    final corniceShadow = Paint()..color = Colors.black38..strokeWidth = 2;

    // 1F와 2F 분할 몰딩 (Divider above 1F)
    final belt1 = Rect.fromLTRB(bLeft - 4, h * 0.555, bRight + 4, h * 0.565);
    canvas.drawRRect(RRect.fromRectAndRadius(belt1, const Radius.circular(2)), cornicePaint);
    canvas.drawLine(Offset(bLeft - 4, h * 0.566), Offset(bRight + 4, h * 0.566), corniceShadow);

    // 2F와 3F 분할 몰딩 (Divider above 2F)
    final belt2 = Rect.fromLTRB(bLeft - 3, h * 0.385, bRight + 3, h * 0.395);
    canvas.drawRRect(RRect.fromRectAndRadius(belt2, const Radius.circular(2)), cornicePaint);
    canvas.drawLine(Offset(bLeft - 3, h * 0.396), Offset(bRight + 3, h * 0.396), corniceShadow);

    // 옥상 메인 파라펫 상단 코니스 (Grand Roof Entablature & Parapet)
    final roofEntablature = Rect.fromLTRB(bLeft - 8, bTop - 12, bRight + 8, bTop + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(roofEntablature, const Radius.circular(5)), Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawLine(Offset(bLeft - 8, bTop + 4), Offset(bRight + 8, bTop + 4), corniceShadow);

    // ─────────────────────────────────────────────────────────────────────────
    // 1-7. 옥상 리얼 건축 설비 (물탱크, 공조기, 피뢰침, 루프탑 테라스) - Spot 1 연계
    // ─────────────────────────────────────────────────────────────────────────
    // Spot 1: 3층 옥상 (0.50, 0.30)
    // 옥상 중앙 펜트하우스 스튜디오 & 가든 테라스 (Penthouse Loft & Pergola)
    final pentRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.36, bTop - 2, w * 0.64, h * 0.36),
      const Radius.circular(8),
    );
    canvas.drawRRect(pentRect, Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(pentRect, Paint()..color = const Color(0xFFE2E8F0)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // 펜트하우스 대형 파노라마 통유리 창 (Rooftop Panorama Glass)
    final pentGlass = Rect.fromLTRB(w * 0.39, bTop + 8, w * 0.61, h * 0.34);
    final pentGlassGrad = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
    ).createShader(pentGlass);
    canvas.drawRect(pentGlass, Paint()..shader = pentGlassGrad);
    // 유리창 반사광
    final shinePath = Path()
      ..moveTo(w * 0.42, bTop + 8)
      ..lineTo(w * 0.48, bTop + 8)
      ..lineTo(w * 0.40, h * 0.34)
      ..lineTo(w * 0.39, h * 0.34)
      ..close();
    canvas.drawPath(shinePath, Paint()..color = Colors.white.withValues(alpha: 0.35));

    // 루프탑 목재 테라스 파골라 (Wood Pergola Slats)
    final slatPaint = Paint()..color = const Color(0xFF78350F)..strokeWidth = 3;
    for (double sx = w * 0.35; sx <= w * 0.65; sx += 12) {
      canvas.drawLine(Offset(sx, bTop - 12), Offset(sx, bTop - 2), slatPaint);
    }

    // 옥상 좌측: 스테인리스 원통형 물탱크 타워 (Stainless Steel Water Tank)
    final tankX = w * 0.22;
    final tankY = bTop - 10;
    // 지지 트러스 철골
    final stiltPaint = Paint()..color = const Color(0xFF64748B)..strokeWidth = 2;
    canvas.drawLine(Offset(tankX - 16, tankY), Offset(tankX - 12, bTop - 12), stiltPaint);
    canvas.drawLine(Offset(tankX + 16, tankY), Offset(tankX + 12, bTop - 12), stiltPaint);
    canvas.drawLine(Offset(tankX, tankY), Offset(tankX, bTop - 12), stiltPaint);
    // 원통형 물탱크 본체
    final tankRRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(tankX, tankY - 14), width: 34, height: 26), const Radius.circular(4));
    final tankGrad = const LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(tankRRect.outerRect);
    canvas.drawRRect(tankRRect, Paint()..shader = tankGrad);
    canvas.drawRRect(tankRRect, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // 물탱크 돔 뚜껑
    canvas.drawArc(Rect.fromCenter(center: Offset(tankX, tankY - 26), width: 34, height: 12), 3.14, 3.14, true, Paint()..color = const Color(0xFF94A3B8));

    // 옥상 우측: 환기 공조기 (HVAC Cooling Unit with Grill)
    final hvacX = w * 0.76;
    final hvacY = bTop - 12;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hvacX - 18, hvacY - 18, 36, 18), const Radius.circular(3)), Paint()..color = const Color(0xFF475569));
    canvas.drawCircle(Offset(hvacX, hvacY - 9), 6, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(hvacX, hvacY - 9), 6, Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // 옥상 중앙 피뢰침 & 항공장애등 (Communications Mast & Beacon)
    canvas.drawLine(Offset(w * 0.50, bTop - 12), Offset(w * 0.50, bTop - 42), Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 2.5);
    canvas.drawCircle(Offset(w * 0.50, bTop - 42), 4, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(w * 0.50, bTop - 42), 7, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.35));

    // ─────────────────────────────────────────────────────────────────────────
    // 1-8. 2층 주거 구역 창문 & 발코니 (Spots 2 & 3 연계)
    // ─────────────────────────────────────────────────────────────────────────
    // Spot 2: (0.30, 0.46) | Spot 3: (0.70, 0.46)
    _drawRealisticBalconyWindow(canvas, Offset(w * 0.30, h * 0.46), bWidth * 0.32, (h * 0.56 - h * 0.39) * 0.78);
    _drawRealisticBalconyWindow(canvas, Offset(w * 0.70, h * 0.46), bWidth * 0.32, (h * 0.56 - h * 0.39) * 0.78);

    // ─────────────────────────────────────────────────────────────────────────
    // 1-9. 1층 상가 & 메인 로비 출입구 (Spots 4 & 5 연계)
    // ─────────────────────────────────────────────────────────────────────────
    // Spot 4: 1층 왼쪽 상가 창문 (0.30, 0.63)
    _drawCommercialShopWindow(canvas, Offset(w * 0.30, h * 0.63), bWidth * 0.32, (bBottom - h * 0.56) * 0.76);

    // Spot 5: 1층 오른쪽 메인 로비 출입구 (0.70, 0.63)
    _drawGrandLobbyEntrance(canvas, Offset(w * 0.70, h * 0.63), bWidth * 0.34, (bBottom - h * 0.56) * 0.88, bBottom);

    // ─────────────────────────────────────────────────────────────────────────
    // 1-10. 현실감의 상징: 측면 철제 비상탈출 계단 (Industrial Fire Escape Stairs)
    // ─────────────────────────────────────────────────────────────────────────
    final escLeft = bLeft - 2;
    final escRight = bLeft + 22;
    final escPaint = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2.5;

    // 3층 테라스, 2층 발코니, 1층 상단 비상 발판 (Platforms)
    final pY3 = h * 0.36;
    final pY2 = h * 0.53;
    final pY1 = h * 0.69;

    for (final py in [pY3, pY2, pY1]) {
      // 발판 격자
      canvas.drawRect(Rect.fromLTRB(escLeft - 6, py, escRight, py + 5), Paint()..color = const Color(0xFF1E293B));
      // 안전 난간 (Safety Handrail)
      canvas.drawLine(Offset(escLeft - 6, py - 14), Offset(escRight, py - 14), escPaint);
      canvas.drawLine(Offset(escLeft - 6, py), Offset(escLeft - 6, py - 14), escPaint);
      canvas.drawLine(Offset(escRight, py), Offset(escRight, py - 14), escPaint);
    }
    // 지그재그 사선 사다리 (Diagonal Ladders)
    canvas.drawLine(Offset(escRight - 4, pY3 + 5), Offset(escLeft, pY2 - 14), escPaint);
    canvas.drawLine(Offset(escLeft, pY2 + 5), Offset(escRight - 4, pY1 - 14), escPaint);
    // 1층 비상 낙하 사다리
    canvas.drawLine(Offset(escLeft + 6, pY1 + 5), Offset(escLeft + 6, h * 0.73), escPaint);
  }

  // 2층 현실적인 발코니 이중창 (Balcony Window with Aluminum Frame, Tinted Glass & Railing)
  void _drawRealisticBalconyWindow(Canvas canvas, Offset center, double width, double height) {
    final winRect = Rect.fromCenter(center: center, width: width, height: height);

    // 석재 상인방 및 하부 창틀 턱 (Stone Header & Sill)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(winRect.left - 4, winRect.top - 5, width + 8, 5), const Radius.circular(2)), Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(winRect.left - 6, winRect.bottom, width + 12, 6), const Radius.circular(2)), Paint()..color = const Color(0xFFCBD5E1));

    // 외곽 알루미늄 샷시 프레임 (Aluminum Window Frame)
    final frameRRect = RRect.fromRectAndRadius(winRect, const Radius.circular(6));
    canvas.drawRRect(frameRRect, Paint()..color = const Color(0xFF1E293B));

    // 반사 유리창 (Reflective Solar Tinted Glass)
    final innerRRect = RRect.fromRectAndRadius(winRect.deflate(3.5), const Radius.circular(4));
    final glassGrad = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0C4A6E)],
    ).createShader(winRect);
    canvas.drawRRect(innerRRect, Paint()..shader = glassGrad);

    // 유리 반사광 (Gloss Shine)
    final shinePath = Path()
      ..moveTo(winRect.left + 8, winRect.top + 4)
      ..lineTo(winRect.left + width * 0.45, winRect.top + 4)
      ..lineTo(winRect.left + width * 0.15, winRect.bottom - 4)
      ..lineTo(winRect.left + 4, winRect.bottom - 4)
      ..close();
    canvas.drawPath(shinePath, Paint()..color = Colors.white.withValues(alpha: 0.3));

    // 창문 중앙 분할 프레임 (Mullion Bar)
    canvas.drawLine(Offset(center.dx, winRect.top + 3), Offset(center.dx, winRect.bottom - 3), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2.5);

    // 모던 블랙 스틸 발코니 난간 (Contemporary Metal Balcony Railing)
    final railBottom = winRect.bottom;
    final railTop = winRect.bottom - height * 0.36;
    final railRect = Rect.fromLTRB(winRect.left - 4, railTop, winRect.right + 4, railBottom);

    // 발코니 화분 상자 (Flower Planter)
    final boxRect = RRect.fromRectAndRadius(Rect.fromLTWH(winRect.left + 2, railBottom - 8, width - 4, 10), const Radius.circular(3));
    canvas.drawRRect(boxRect, Paint()..color = const Color(0xFF78350F));
    // 화분 싱그러운 식물 잎사귀
    for (double fx = winRect.left + 8; fx < winRect.right - 6; fx += 10) {
      canvas.drawCircle(Offset(fx, railBottom - 9), 4, Paint()..color = const Color(0xFF22C55E));
      canvas.drawCircle(Offset(fx + 3, railBottom - 11), 3.5, Paint()..color = const Color(0xFF4ADE80));
    }

    // 난간 핸드레일 & 버티컬 바
    final railPaint = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2;
    canvas.drawLine(Offset(railRect.left, railTop), Offset(railRect.right, railTop), railPaint..strokeWidth = 3);
    for (double rx = railRect.left + 8; rx <= railRect.right - 6; rx += 11) {
      canvas.drawLine(Offset(rx, railTop), Offset(rx, railBottom), railPaint..strokeWidth = 1.8);
    }
  }

  // 1층 상업 쇼룸 윈도우 (Commercial Storefront with Striped Fabric Awning)
  void _drawCommercialShopWindow(Canvas canvas, Offset center, double width, double height) {
    final winRect = Rect.fromCenter(center: center, width: width, height: height);

    // 따뜻한 실내 조명이 비치는 쇼윈도
    canvas.drawRRect(RRect.fromRectAndRadius(winRect, const Radius.circular(6)), Paint()..color = const Color(0xFF1E293B));
    final shopGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A), Color(0xFFF59E0B)],
    ).createShader(winRect.deflate(3));
    canvas.drawRRect(RRect.fromRectAndRadius(winRect.deflate(3), const Radius.circular(4)), Paint()..shader = shopGrad);

    // 쇼윈도 진열대 & 실루엣
    canvas.drawRect(Rect.fromLTRB(winRect.left + 6, winRect.bottom - 16, winRect.right - 6, winRect.bottom - 4), Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(Offset(center.dx - 12, winRect.bottom - 20), 6, Paint()..color = const Color(0xFFB45309));
    canvas.drawCircle(Offset(center.dx + 12, winRect.bottom - 22), 7, Paint()..color = const Color(0xFFB45309));

    // 상점 클래식 어닝 차양 (French Scalloped Awning)
    final awnTop = winRect.top - 6;
    final awnBottom = winRect.top + height * 0.32;
    final awnWidth = width + 10;
    final awnLeft = winRect.left - 5;
    final segWidth = awnWidth / 5;

    for (int i = 0; i < 5; i++) {
      final segColor = i.isEven ? const Color(0xFF047857) : Colors.white;
      final segRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(awnLeft + i * segWidth, awnTop, segWidth, awnBottom - awnTop),
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      );
      canvas.drawRRect(segRect, Paint()..color = segColor);
    }
  }

  // 1층 메인 로비 현관 (Grand Glass Lobby Entrance with Canopy & Address Plaque)
  void _drawGrandLobbyEntrance(Canvas canvas, Offset center, double width, double height, double groundY) {
    final doorRect = Rect.fromCenter(center: center, width: width, height: height);

    // 입구 캐노피 어닝 (Glass & Steel Entrance Canopy)
    final canoRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(doorRect.left - 10, doorRect.top - 8, doorRect.right + 10, doorRect.top + 2),
      const Radius.circular(3),
    );
    canvas.drawRRect(canoRect, Paint()..color = const Color(0xFFE2E8F0));
    // 다운라이트 조명
    canvas.drawCircle(Offset(center.dx - 16, doorRect.top), 2.5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(center.dx + 16, doorRect.top), 2.5, Paint()..color = const Color(0xFFFEF08A));

    // 빌딩 명판 (Brushed Gold Address Signboard)
    final signRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center.dx, doorRect.top - 16), width: 68, height: 12), const Radius.circular(3));
    canvas.drawRRect(signRect, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawRRect(signRect, Paint()..color = const Color(0xFFB45309)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    // 유리 자동문 프레임 (Dark Anodized Aluminum Double Door)
    final doorBody = RRect.fromRectAndCorners(
      Rect.fromLTRB(doorRect.left, doorRect.top, doorRect.right, groundY),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    canvas.drawRRect(doorBody, Paint()..color = const Color(0xFF0F172A));

    // 이중 강화 유리창
    final doorGlass1 = Rect.fromLTRB(doorRect.left + 4, doorRect.top + 4, center.dx - 2, groundY - 4);
    final doorGlass2 = Rect.fromLTRB(center.dx + 2, doorRect.top + 4, doorRect.right - 4, groundY - 4);
    final glassShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF67E8F9), Color(0xFF06B6D4), Color(0xFF0E7490)],
    );
    canvas.drawRect(doorGlass1, Paint()..shader = glassShader.createShader(doorGlass1));
    canvas.drawRect(doorGlass2, Paint()..shader = glassShader.createShader(doorGlass2));

    // 스테인리스 손잡이 바 (Stainless Steel Vertical Push Bars)
    final barPaint = Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 7, doorRect.top + 20), Offset(center.dx - 7, groundY - 14), barPaint);
    canvas.drawLine(Offset(center.dx + 7, doorRect.top + 20), Offset(center.dx + 7, groundY - 14), barPaint);

    // 현관 대리석 디딤돌 (Granite Welcome Step)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(doorRect.left - 14, groundY - 3, doorRect.right + 14, groundY + 4), const Radius.circular(3)),
      Paint()..color = const Color(0xFF64748B),
    );
  }

  // 2. 동화 속 숲속 오두막 (Cozy Forest Cabin with Giant Trees & Wildflowers)
  void _drawForest(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 2-1. 숲속 맑은 언덕 잔디 (Rolling Green Hills)
    final hillPath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.35, h * 0.65, w * 0.65, h * 0.72)
      ..quadraticBezierTo(w * 0.85, h * 0.76, w, h * 0.70)
      ..lineTo(w, h * 0.80)
      ..lineTo(0, h * 0.80)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF15803D));

    // 2-2. 좌측 울창한 단풍 참나무 (Giant Oak Tree)
    final trunkPaint = Paint()..color = const Color(0xFF78350F);
    final trunkPath1 = Path()
      ..moveTo(w * 0.18, h * 0.74)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.34, h * 0.42)
      ..lineTo(w * 0.38, h * 0.74)
      ..close();
    canvas.drawPath(trunkPath1, trunkPaint);

    // 참나무 3중 풍성한 볼륨 잎사귀
    canvas.drawCircle(Offset(w * 0.28, h * 0.38), w * 0.20, Paint()..color = const Color(0xFF166534));
    canvas.drawCircle(Offset(w * 0.22, h * 0.34), w * 0.16, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(w * 0.32, h * 0.30), w * 0.15, Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(Offset(w * 0.28, h * 0.28), w * 0.12, Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.6));

    // 2-3. 우측 단풍나무 (Golden Orange Autumn Tree)
    final trunkPath2 = Path()
      ..moveTo(w * 0.64, h * 0.74)
      ..lineTo(w * 0.68, h * 0.44)
      ..lineTo(w * 0.76, h * 0.44)
      ..lineTo(w * 0.80, h * 0.74)
      ..close();
    canvas.drawPath(trunkPath2, trunkPaint);

    canvas.drawCircle(Offset(w * 0.72, h * 0.40), w * 0.18, Paint()..color = const Color(0xFFC2410C));
    canvas.drawCircle(Offset(w * 0.76, h * 0.34), w * 0.15, Paint()..color = const Color(0xFFEA580C));
    canvas.drawCircle(Offset(w * 0.68, h * 0.32), w * 0.14, Paint()..color = const Color(0xFFF97316));
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), w * 0.10, Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.7));

    // 2-4. 중앙 아늑한 통나무 오두막 (Cozy Log Cabin)
    final cabinLeft = w * 0.34;
    final cabinRight = w * 0.66;
    final cabinTop = h * 0.46;
    final cabinBottom = h * 0.74;

    // 통나무 벽체
    final cabinRRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinLeft, cabinTop, cabinRight, cabinBottom), const Radius.circular(12));
    canvas.drawRRect(cabinRRect, Paint()..color = const Color(0xFFB45309));

    // 통나무 결 라인
    for (double y = cabinTop + 10; y < cabinBottom; y += 12) {
      canvas.drawLine(Offset(cabinLeft, y), Offset(cabinRight, y), Paint()..color = const Color(0xFF78350F)..strokeWidth = 2);
    }

    // 벽돌 굴뚝 & 모락모락 연기 (Chimney & Puffs)
    canvas.drawRect(Rect.fromLTWH(cabinRight - 22, cabinTop - 28, 14, 28), Paint()..color = const Color(0xFF991B1B));
    canvas.drawCircle(Offset(cabinRight - 15, cabinTop - 34), 6, Paint()..color = Colors.white70);
    canvas.drawCircle(Offset(cabinRight - 10, cabinTop - 44), 9, Paint()..color = Colors.white54);

    // 오두막 삼각형 삼나무 지붕 (Cedar Shingle Roof)
    final roofCabin = Path()
      ..moveTo(cabinLeft - 14, cabinTop)
      ..lineTo(w * 0.50, cabinTop - 36)
      ..lineTo(cabinRight + 14, cabinTop)
      ..close();
    final cabinRoofGrad = const LinearGradient(
      colors: [Color(0xFF991B1B), Color(0xFFB91C1C), Color(0xFF7F1D1D)],
    ).createShader(Rect.fromLTRB(cabinLeft - 14, cabinTop - 36, cabinRight + 14, cabinTop));
    canvas.drawPath(roofCabin, Paint()..shader = cabinRoofGrad);

    // 따스한 창문 & 현관문
    final winRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinLeft + 12, cabinTop + 14, cabinLeft + 36, cabinTop + 36), const Radius.circular(6));
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFF78350F)..style = PaintingStyle.stroke..strokeWidth = 2);

    final doorRRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinRight - 36, cabinBottom - 36, cabinRight - 12, cabinBottom), const Radius.circular(6));
    canvas.drawRRect(doorRRect, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(Offset(cabinRight - 30, cabinBottom - 18), 2.5, Paint()..color = const Color(0xFFFBBF24));

    // 2-5. 숲속 꽃 & 버섯 디테일 (🍄 🌸)
    canvas.drawCircle(Offset(w * 0.20, h * 0.72), 6, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(w * 0.20, h * 0.70), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.82, h * 0.73), 5, Paint()..color = const Color(0xFFF43F5E));
  }

  // 3. 판타지 마법 성 (Grand Magic Castle with Spire Turrets & Royal Banners)
  void _drawCastle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 3-1. 성채 돌벽 베이스
    final stoneGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
    );

    final turretGrad = const LinearGradient(
      colors: [Color(0xFFC084FC), Color(0xFFA855F7), Color(0xFF9333EA)],
    );

    final roofGrad = const LinearGradient(
      colors: [Color(0xFFFB7185), Color(0xFFF43F5E), Color(0xFFE11D48)],
    );

    // 3-2. 중앙 거대 마법 본탑 (Grand Keep)
    final keepLeft = w * 0.32;
    final keepRight = w * 0.68;
    final keepTop = h * 0.24;
    final keepBottom = h * 0.75;

    final keepRect = RRect.fromRectAndRadius(Rect.fromLTRB(keepLeft, keepTop, keepRight, keepBottom), const Radius.circular(14));
    canvas.drawRRect(keepRect, Paint()..shader = stoneGrad.createShader(Rect.fromLTRB(keepLeft, keepTop, keepRight, keepBottom)));

    // 중앙 크레넬레이션 성벽 배틀먼트 (Crenellations)
    for (double x = keepLeft; x < keepRight - 10; x += 16) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x, keepTop - 8, x + 10, keepTop), const Radius.circular(3)), Paint()..color = const Color(0xFFDDD6FE));
    }

    // 중앙 원뿔 고딕 첨탑 (Gothic Spire Roof)
    final centerRoof = Path()
      ..moveTo(keepLeft - 8, keepTop - 8)
      ..lineTo(w * 0.50, h * 0.10) // 뾰족한 첨탑
      ..lineTo(keepRight + 8, keepTop - 8)
      ..close();
    canvas.drawPath(centerRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(keepLeft - 8, h * 0.10, keepRight + 8, keepTop)));

    // 첨탑 꼭대기 황금 마법 구슬 & 펄럭이는 깃발 (Golden Orb & Royal Banner)
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), 6, Paint()..color = const Color(0xFFFFD700));
    final bannerPath = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.50 + 22, h * 0.10 + 6)
      ..lineTo(w * 0.50, h * 0.10 + 14)
      ..close();
    canvas.drawPath(bannerPath, Paint()..color = const Color(0xFFFBBF24));

    // 3-3. 좌우 사이드 마법 타워 (Left & Right Turrets)
    final leftTurretRect = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.10, h * 0.36, w * 0.30, keepBottom), const Radius.circular(12));
    canvas.drawRRect(leftTurretRect, Paint()..shader = turretGrad.createShader(Rect.fromLTRB(w * 0.10, h * 0.36, w * 0.30, keepBottom)));

    final leftRoof = Path()
      ..moveTo(w * 0.08, h * 0.36)
      ..lineTo(w * 0.20, h * 0.22)
      ..lineTo(w * 0.32, h * 0.36)
      ..close();
    canvas.drawPath(leftRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(w * 0.08, h * 0.22, w * 0.32, h * 0.36)));

    final rightTurretRect = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.70, h * 0.36, w * 0.90, keepBottom), const Radius.circular(12));
    canvas.drawRRect(rightTurretRect, Paint()..shader = turretGrad.createShader(Rect.fromLTRB(w * 0.70, h * 0.36, w * 0.90, keepBottom)));

    final rightRoof = Path()
      ..moveTo(w * 0.68, h * 0.36)
      ..lineTo(w * 0.80, h * 0.22)
      ..lineTo(w * 0.92, h * 0.36)
      ..close();
    canvas.drawPath(rightRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(w * 0.68, h * 0.22, w * 0.92, h * 0.36)));

    // 3-4. 아치형 골드 스테인드글라스 창문들 (Arched Windows)
    _drawArchedWindow(canvas, Offset(w * 0.50, h * 0.32), 28, 44);
    _drawArchedWindow(canvas, Offset(w * 0.20, h * 0.44), 20, 32);
    _drawArchedWindow(canvas, Offset(w * 0.80, h * 0.44), 20, 32);

    // 3-5. 성문 거대 도개교 (Royal Castle Gate & Portcullis)
    final gatePath = Path()
      ..moveTo(w * 0.42, keepBottom)
      ..lineTo(w * 0.42, keepBottom - 38)
      ..quadraticBezierTo(w * 0.50, keepBottom - 50, w * 0.58, keepBottom - 38)
      ..lineTo(w * 0.58, keepBottom)
      ..close();
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFF475569));
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  void _drawArchedWindow(Canvas canvas, Offset center, double width, double height) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + width * 0.5)
      ..arcToPoint(Offset(rect.right, rect.top + width * 0.5), radius: Radius.circular(width * 0.5))
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  // 4. 달콤한 디저트 베이커리 (Sweet Strawberry Bakery with Cupcake Rooftop & Awning)
  void _drawBakery(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final left = w * 0.12;
    final right = w * 0.88;
    final top = h * 0.26;
    final bottom = h * 0.75;

    // 4-1. 생크림 핑크 벽체
    final wallRRect = RRect.fromRectAndRadius(Rect.fromLTRB(left, top, right, bottom), const Radius.circular(20));
    final wallGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
    ).createShader(Rect.fromLTRB(left, top, right, bottom));
    canvas.drawRRect(wallRRect, Paint()..shader = wallGrad);
    canvas.drawRRect(wallRRect, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 3);

    // 4-2. 옥상 초대형 딸기 컵케이크 조형물 (Giant Strawberry Cupcake Signboard)
    final cupcakeX = w * 0.5;
    final cupcakeY = top - 20;

    // 컵케이크 컵 베이스
    final cupPath = Path()
      ..moveTo(cupcakeX - 32, cupcakeY + 16)
      ..lineTo(cupcakeX - 24, cupcakeY + 36)
      ..lineTo(cupcakeX + 24, cupcakeY + 36)
      ..lineTo(cupcakeX + 32, cupcakeY + 16)
      ..close();
    canvas.drawPath(cupPath, Paint()..color = const Color(0xFFF59E0B));

    // 폭신한 핑크 크림 돔
    canvas.drawCircle(Offset(cupcakeX - 18, cupcakeY + 8), 20, Paint()..color = const Color(0xFFFF69B4));
    canvas.drawCircle(Offset(cupcakeX + 18, cupcakeY + 8), 20, Paint()..color = const Color(0xFFFF69B4));
    canvas.drawCircle(Offset(cupcakeX, cupcakeY - 4), 26, Paint()..color = const Color(0xFFFF1493));

    // 꼭대기 빨간 체리 (Glossy Red Cherry)
    canvas.drawCircle(Offset(cupcakeX, cupcakeY - 26), 11, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(cupcakeX - 3, cupcakeY - 29), 3, Paint()..color = Colors.white70);

    // 4-3. 캔디 스트라이프 어닝 (Pink & White Ruffled Awning)
    final awningWidth = (right - left) / 7;
    for (int i = 0; i < 7; i++) {
      final awLeft = left + (i * awningWidth);
      final awColor = i.isEven ? const Color(0xFFF43F5E) : Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(awLeft, top + 14, awLeft + awningWidth, top + 42), const Radius.circular(8)),
        Paint()..color = awColor,
      );
    }

    // 4-4. 디저트 진열 파노라마 쇼케이스 창문
    final winRRect1 = RRect.fromRectAndRadius(Rect.fromLTRB(left + 16, top + 52, w * 0.46, bottom - 18), const Radius.circular(12));
    final winRRect2 = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.54, top + 52, right - 16, bottom - 18), const Radius.circular(12));
    final showcasePaint = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.85);

    canvas.drawRRect(winRRect1, showcasePaint);
    canvas.drawRRect(winRRect2, showcasePaint);
    canvas.drawRRect(winRRect1, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRRect(winRRect2, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  // 5. 미래형 우주 런치패드 기지 (Cybernetic Space Launch Station)
  void _drawSpaceStation(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // 5-1. 발사대 트러스 타워 구조물 (Launch Gantry Towers)
    final gantryPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(centerX - 100, h * 0.28, 28, h * 0.48), gantryPaint);
    canvas.drawRect(Rect.fromLTWH(centerX + 72, h * 0.28, 28, h * 0.48), gantryPaint);

    // 트러스 X 크로스 브레이스
    for (double y = h * 0.28; y < h * 0.74; y += 24) {
      canvas.drawLine(Offset(centerX - 100, y), Offset(centerX - 72, y + 24), gantryPaint);
      canvas.drawLine(Offset(centerX + 72, y), Offset(centerX + 100, y + 24), gantryPaint);
    }

    // 5-2. 푸른 태양광 솔라 윙 (Solar Panel Wings)
    final solarPaint = Paint()..color = const Color(0xFF1E3A8A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX - 135, h * 0.44, centerX - 50, h * 0.56), const Radius.circular(8)), solarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX + 50, h * 0.44, centerX + 135, h * 0.56), const Radius.circular(8)), solarPaint);

    // 5-3. 메인 우주선 동체 (Aerospace Shuttle Body)
    final rocketPath = Path()
      ..moveTo(centerX, h * 0.16) // Sharp Nose Cone
      ..lineTo(centerX + 40, h * 0.30)
      ..lineTo(centerX + 40, h * 0.72)
      ..lineTo(centerX - 40, h * 0.72)
      ..lineTo(centerX - 40, h * 0.30)
      ..close();
    final rocketGrad = const LinearGradient(
      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ).createShader(Rect.fromLTWH(centerX - 40, h * 0.16, 80, h * 0.56));
    canvas.drawPath(rocketPath, Paint()..shader = rocketGrad);
    canvas.drawPath(rocketPath, Paint()..color = const Color(0xFF00F2FE)..style = PaintingStyle.stroke..strokeWidth = 3);

    // 미래형 원형 돔 콕핏 윈도우 (Neon Cockpit Window)
    canvas.drawCircle(Offset(centerX, h * 0.36), 18, Paint()..color = const Color(0xFF0284C7));
    canvas.drawCircle(Offset(centerX, h * 0.36), 18, Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  // 6. 모험의 해적 범선 (Legendary Pirate Galleon Ship)
  void _drawPirateShip(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // 6-1. 넘실거리는 바다 파도 (Ocean Waves with Foam)
    final wavePath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.50, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.66, w, h * 0.70)
      ..lineTo(w, h * 0.80)
      ..lineTo(0, h * 0.80)
      ..close();
    canvas.drawPath(wavePath, Paint()..color = const Color(0xFF0284C7));

    // 6-2. 묵직한 목조 선체 (Heavy Wooden Ship Hull)
    final hullPath = Path()
      ..moveTo(w * 0.12, h * 0.50) // 높은 선수 (Bow)
      ..lineTo(w * 0.88, h * 0.48) // 높은 선미 (Stern)
      ..lineTo(w * 0.78, h * 0.72)
      ..lineTo(w * 0.22, h * 0.72)
      ..close();
    final woodGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9A3412), Color(0xFF78350F), Color(0xFF451A03)],
    ).createShader(Rect.fromLTRB(w * 0.12, h * 0.48, w * 0.88, h * 0.72));
    canvas.drawPath(hullPath, Paint()..shader = woodGrad);

    // 황금 포문 라인 (Gold Cannon Ports)
    for (double x = w * 0.28; x <= w * 0.72; x += 32) {
      canvas.drawCircle(Offset(x, h * 0.58), 6, Paint()..color = const Color(0xFF1E293B));
      canvas.drawCircle(Offset(x, h * 0.58), 6, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // 6-3. 웅장한 중앙 돛대 & 펄럭이는 메인 돛 (Grand Ship Mast & Billowing Sail)
    canvas.drawRect(Rect.fromLTWH(centerX - 7, h * 0.18, 14, h * 0.38), Paint()..color = const Color(0xFF451A03));

    // 메인 돛 (Billowing Canvas Sail)
    final sailPath = Path()
      ..moveTo(centerX - 65, h * 0.24)
      ..quadraticBezierTo(centerX, h * 0.28, centerX + 65, h * 0.24)
      ..lineTo(centerX + 75, h * 0.44)
      ..quadraticBezierTo(centerX, h * 0.49, centerX - 75, h * 0.44)
      ..close();
    final sailGrad = const LinearGradient(
      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    ).createShader(Rect.fromLTRB(centerX - 75, h * 0.24, centerX + 75, h * 0.49));
    canvas.drawPath(sailPath, Paint()..shader = sailGrad);

    // 돛 위 해적 엠블럼 (Skull Decal)
    canvas.drawCircle(Offset(centerX, h * 0.34), 9, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(centerX, h * 0.34), 6, Paint()..color = Colors.white);

    // 꼭대기 망루 (Crow's Nest & Pirate Flag)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX - 18, h * 0.18, centerX + 18, h * 0.23), const Radius.circular(4)), Paint()..color = const Color(0xFF78350F));
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 7. 바닷가 절벽 등대 & 등대지기 오두막 (Coastal Lighthouse & Keeper's Cottage)
  // ═════════════════════════════════════════════════════════════════════════════
  void _drawLighthouse(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 7-1. 넘실거리는 바다 & 갈매기
    final oceanPath = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.50, h * 0.66)
      ..quadraticBezierTo(w * 0.75, h * 0.63, w, h * 0.65)
      ..lineTo(w, h * 0.82)
      ..lineTo(0, h * 0.82)
      ..close();
    final oceanGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0284C7), Color(0xFF0369A1), Color(0xFF075985)],
    ).createShader(oceanPath.getBounds());
    canvas.drawPath(oceanPath, Paint()..shader = oceanGrad);

    // 하얀 파도 포말
    final foamPaint = Paint()..color = Colors.white60..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * 0.05, h * 0.66, 60, 16), 0, 3.14, false, foamPaint);
    canvas.drawArc(Rect.fromLTWH(w * 0.70, h * 0.67, 80, 18), 0, 3.14, false, foamPaint);

    // 날아가는 갈매기들
    final gullPaint = Paint()..color = Colors.white70..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (final off in [Offset(w * 0.15, h * 0.22), Offset(w * 0.22, h * 0.18), Offset(w * 0.82, h * 0.25)]) {
      final gp = Path()
        ..moveTo(off.dx - 10, off.dy + 3)
        ..quadraticBezierTo(off.dx - 5, off.dy - 4, off.dx, off.dy)
        ..quadraticBezierTo(off.dx + 5, off.dy - 4, off.dx + 10, off.dy + 3);
      canvas.drawPath(gp, gullPaint);
    }

    // 7-2. 거친 바위섬 절벽 (Rocky Granite Cliff)
    final rockPath = Path()
      ..moveTo(w * 0.16, h * 0.74)
      ..lineTo(w * 0.22, h * 0.65)
      ..lineTo(w * 0.40, h * 0.64)
      ..lineTo(w * 0.58, h * 0.65)
      ..lineTo(w * 0.84, h * 0.66)
      ..lineTo(w * 0.88, h * 0.74)
      ..lineTo(w * 0.16, h * 0.74)
      ..close();
    final rockGrad = const LinearGradient(
      colors: [Color(0xFF64748B), Color(0xFF475569), Color(0xFF334155)],
    ).createShader(rockPath.getBounds());
    canvas.drawPath(rockPath, Paint()..shader = rockGrad);

    // 7-3. 우측 등대지기 오두막 (Keeper's Cottage) - Spots 3 & 5
    final cotLeft = w * 0.52;
    final cotRight = w * 0.84;
    final cotTop = h * 0.46;
    final cotBottom = h * 0.68;

    // 석재 벽체
    final cotRect = RRect.fromRectAndRadius(Rect.fromLTRB(cotLeft, cotTop + 24, cotRight, cotBottom), const Radius.circular(8));
    canvas.drawRRect(cotRect, Paint()..color = const Color(0xFFCBD5E1));

    // 박공 지붕 (Gable Roof)
    final cotRoof = Path()
      ..moveTo(cotLeft - 10, cotTop + 26)
      ..lineTo(w * 0.68, cotTop)
      ..lineTo(cotRight + 10, cotTop + 26)
      ..close();
    final cotRoofGrad = const LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFB91C1C), Color(0xFF991B1B)],
    ).createShader(cotRoof.getBounds());
    canvas.drawPath(cotRoof, Paint()..shader = cotRoofGrad);

    // Spot 3: 2층 지붕 채광창 (Dormer Window with Cute Seal) (0.68, 0.44)
    final dormerRect = Rect.fromCenter(center: Offset(w * 0.68, h * 0.44), width: 32, height: 30);
    canvas.drawRRect(RRect.fromRectAndRadius(dormerRect, const Radius.circular(4)), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(RRect.fromRectAndRadius(dormerRect.deflate(2.5), const Radius.circular(3)), Paint()..color = const Color(0xFF38BDF8));
    canvas.drawLine(Offset(w * 0.68, dormerRect.top), Offset(w * 0.68, dormerRect.bottom), Paint()..color = Colors.white70..strokeWidth = 2);

    // Spot 5: 1층 보급 창고 목조 문 (0.70, 0.63)
    final cotDoor = Rect.fromCenter(center: Offset(w * 0.70, h * 0.63), width: 34, height: 44);
    canvas.drawRRect(RRect.fromRectAndRadius(cotDoor, const Radius.circular(4)), Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(Offset(w * 0.70 + 8, h * 0.63), 2.5, Paint()..color = const Color(0xFFFBBF24));
    // 벽에 걸린 구명환 (Lifebuoy)
    canvas.drawCircle(Offset(cotLeft + 20, cotTop + 48), 9, Paint()..color = const Color(0xFFDC2626));
    canvas.drawCircle(Offset(cotLeft + 20, cotTop + 48), 5, Paint()..color = Colors.white);

    // 7-4. 좌측 메인 등대 타워 (Tapered Lighthouse Tower) - Spots 1, 2, 4
    final lhCenter = w * 0.38;
    final lhTopY = h * 0.28;
    final lhBottomY = h * 0.68;
    final topHalfW = 24.0;
    final botHalfW = 38.0;

    // 타워 본체 패스
    final lhTower = Path()
      ..moveTo(lhCenter - topHalfW, lhTopY)
      ..lineTo(lhCenter + topHalfW, lhTopY)
      ..lineTo(lhCenter + botHalfW, lhBottomY)
      ..lineTo(lhCenter - botHalfW, lhBottomY)
      ..close();

    // 4단 빨강/하양 줄무늬 (Stripes)
    final stripeHeight = (lhBottomY - lhTopY) / 4;
    canvas.save();
    canvas.clipPath(lhTower);
    for (int i = 0; i < 4; i++) {
      final sY = lhTopY + i * stripeHeight;
      final sColor = i.isEven ? const Color(0xFFDC2626) : Colors.white;
      canvas.drawRect(Rect.fromLTWH(lhCenter - 50, sY, 100, stripeHeight + 1), Paint()..color = sColor);
    }
    // 등대 입체 음영
    final lhShadeGrad = const LinearGradient(
      colors: [Colors.black12, Colors.transparent, Colors.black26],
    ).createShader(Rect.fromLTWH(lhCenter - botHalfW, lhTopY, botHalfW * 2, lhBottomY - lhTopY));
    canvas.drawRect(Rect.fromLTWH(lhCenter - botHalfW, lhTopY, botHalfW * 2, lhBottomY - lhTopY), Paint()..shader = lhShadeGrad);
    canvas.restore();

    canvas.drawPath(lhTower, Paint()..color = const Color(0xFF334155)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Spot 2: 등대 나선창 (0.38, 0.44)
    final lWin = Rect.fromCenter(center: Offset(lhCenter, h * 0.44), width: 22, height: 28);
    canvas.drawRRect(RRect.fromRectAndRadius(lWin, const Radius.circular(5)), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(RRect.fromRectAndRadius(lWin.deflate(2), const Radius.circular(4)), Paint()..color = const Color(0xFF38BDF8));

    // Spot 4: 등대 1층 정문 (0.38, 0.63)
    final lDoor = Rect.fromCenter(center: Offset(lhCenter, h * 0.63), width: 26, height: 38);
    canvas.drawRRect(RRect.fromRectAndRadius(lDoor, const Radius.circular(6)), Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(lhCenter + 6, h * 0.63), 2.5, Paint()..color = const Color(0xFFFBBF24));

    // 7-5. 등대 꼭대기 조명실 & 프레넬 렌즈 빔 (Lantern Room & Beacon) - Spot 1 (0.50, 0.25)
    // 발코니 갤러리 난간
    final galY = lhTopY;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(lhCenter, galY), width: 62, height: 8), const Radius.circular(3)), Paint()..color = const Color(0xFF475569));
    canvas.drawLine(Offset(lhCenter - 30, galY - 10), Offset(lhCenter + 30, galY - 10), Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2);

    // 유리 등롱 (Lantern Room Glass)
    final lanternRect = Rect.fromCenter(center: Offset(lhCenter, galY - 18), width: 44, height: 26);
    canvas.drawRect(lanternRect, Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.8));
    canvas.drawRect(lanternRect, Paint()..color = const Color(0xFF1E293B)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 황금 프레넬 렌즈 회전 조명 & 빔 (Rotating Fresnel Lens & Light Beams)
    canvas.drawCircle(Offset(lhCenter, galY - 18), 7, Paint()..color = const Color(0xFFFBBF24));
    final beamPath = Path()
      ..moveTo(lhCenter, galY - 18)
      ..lineTo(w, galY - 45)
      ..lineTo(w, galY + 15)
      ..close();
    final beamGrad = const LinearGradient(
      colors: [Color(0x80FEF08A), Colors.transparent],
    ).createShader(beamPath.getBounds());
    canvas.drawPath(beamPath, Paint()..shader = beamGrad);

    // 돔 지붕 & 피뢰침
    final lhDome = Path()
      ..moveTo(lhCenter - 26, galY - 30)
      ..quadraticBezierTo(lhCenter, galY - 50, lhCenter + 26, galY - 30)
      ..close();
    canvas.drawPath(lhDome, Paint()..color = const Color(0xFFB45309));
    canvas.drawCircle(Offset(lhCenter, galY - 50), 3.5, Paint()..color = const Color(0xFFFBBF24));
    canvas.drawLine(Offset(lhCenter, galY - 50), Offset(lhCenter, galY - 60), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2);
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 8. 하늘공항 관제탑 & 격납고 (Airport Control Tower & Hangar)
  // ═════════════════════════════════════════════════════════════════════════════
  void _drawAirportTower(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 8-1. 활주로 타맥 도로 (Airport Runway Tarmac)
    final tarmacRect = Rect.fromLTRB(0, h * 0.72, w, h * 0.82);
    final tarmacPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF0F172A)],
      ).createShader(tarmacRect);
    canvas.drawRect(tarmacRect, tarmacPaint);

    // 활주로 중앙 흰색 차선 & 노란 유도로
    final runMarkPaint = Paint()..color = Colors.white..strokeWidth = 4;
    for (double x = 15; x < w; x += 40) {
      canvas.drawLine(Offset(x, h * 0.77), Offset(x + 22, h * 0.77), runMarkPaint);
    }
    // 활주로 녹색 유도등 (Green Threshold Lights)
    for (double x = 20; x < w; x += 30) {
      canvas.drawCircle(Offset(x, h * 0.725), 3, Paint()..color = const Color(0xFF22C55E));
    }

    // 8-2. 좌측 1층 비행기 격납고 (Airplane Hangar) - Spot 4 (0.30, 0.63)
    final hangLeft = w * 0.10;
    final hangRight = w * 0.42;
    final hangBottom = h * 0.72;
    final hangTop = h * 0.54;

    // 둥근 아치형 지붕 격납고 (Curved Hangar Roof)
    final hangarRoof = Path()
      ..moveTo(hangLeft, hangBottom)
      ..lineTo(hangLeft, hangTop + 20)
      ..quadraticBezierTo(w * 0.26, hangTop - 12, hangRight, hangTop + 20)
      ..lineTo(hangRight, hangBottom)
      ..close();
    final hangGrad = const LinearGradient(
      colors: [Color(0xFF64748B), Color(0xFF475569), Color(0xFF334155)],
    ).createShader(hangarRoof.getBounds());
    canvas.drawPath(hangarRoof, Paint()..shader = hangGrad);

    // 격납고 롤업 셔터 문
    final shutRect = Rect.fromCenter(center: Offset(w * 0.26, h * 0.63), width: w * 0.24, height: 42);
    canvas.drawRect(shutRect, Paint()..color = const Color(0xFF0F172A));
    for (double y = shutRect.top + 4; y < shutRect.bottom; y += 6) {
      canvas.drawLine(Offset(shutRect.left + 2, y), Offset(shutRect.right - 2, y), Paint()..color = const Color(0xFF334155)..strokeWidth = 1.2);
    }
    // 격납고 안의 비행기 기두 실루엣 (Airplane Nose)
    final planeNose = Path()
      ..moveTo(w * 0.22, shutRect.bottom)
      ..quadraticBezierTo(w * 0.26, shutRect.top + 8, w * 0.30, shutRect.bottom)
      ..close();
    canvas.drawPath(planeNose, Paint()..color = Colors.white70);
    canvas.drawCircle(Offset(w * 0.26, shutRect.top + 16), 3, Paint()..color = const Color(0xFF0284C7));

    // 8-3. 우측 1층 지상 유도실 & 출동로 (Ground Operations Annex) - Spot 5 (0.70, 0.63)
    final annexLeft = w * 0.58;
    final annexRight = w * 0.90;
    final annexTop = h * 0.56;
    final annexBottom = h * 0.72;

    final annexRect = RRect.fromRectAndRadius(Rect.fromLTRB(annexLeft, annexTop, annexRight, annexBottom), const Radius.circular(8));
    canvas.drawRRect(annexRect, Paint()..color = const Color(0xFFE2E8F0));
    canvas.drawRRect(annexRect, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 비상 게이트 (Yellow/Black Hazard Stripes)
    final gateRect = Rect.fromCenter(center: Offset(w * 0.74, h * 0.64), width: 44, height: 34);
    canvas.drawRect(gateRect, Paint()..color = const Color(0xFF0F172A));
    final stripeP = Paint()..color = const Color(0xFFFBBF24)..strokeWidth = 2.5;
    for (double d = -20; d < 50; d += 8) {
      canvas.drawLine(Offset(gateRect.left + d, gateRect.top), Offset(gateRect.left + d - 10, gateRect.bottom), stripeP);
    }
    // 지상 지원 통신 안테나 디시
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.82, annexTop - 8), width: 18, height: 18), 3.14, 3.14, false, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // 8-4. 중앙 메인 관제탑 샤프트 (Main Concrete Control Tower Stem)
    final stemLeft = w * 0.42;
    final stemRight = w * 0.58;
    final stemTop = h * 0.38;
    final stemBottom = h * 0.72;

    final stemRect = Rect.fromLTRB(stemLeft, stemTop, stemRight, stemBottom);
    final stemGrad = const LinearGradient(
      colors: [Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(stemRect);
    canvas.drawRect(stemRect, Paint()..shader = stemGrad);
    canvas.drawRect(stemRect, Paint()..color = const Color(0xFF475569)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 중앙 유리 엘리베이터 샤프트 (Glass Elevator Track)
    final elvRect = Rect.fromLTRB(w * 0.48, stemTop + 10, w * 0.52, stemBottom - 10);
    canvas.drawRect(elvRect, Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.5));

    // 8-5. 관제탑 360도 캔틸레버 유리 조종실 (Visual Control Room Cab) - Spots 2 & 3
    final cabBottom = stemTop + 8;
    final cabTop = h * 0.28;
    final cabWidthTop = w * 0.54;
    final cabWidthBot = w * 0.36;
    final cX = w * 0.50;

    // 조종실 외곽 구조 (역사다리꼴 형태)
    final cabPath = Path()
      ..moveTo(cX - cabWidthTop * 0.5, cabTop)
      ..lineTo(cX + cabWidthTop * 0.5, cabTop)
      ..lineTo(cX + cabWidthBot * 0.5, cabBottom)
      ..lineTo(cX - cabWidthBot * 0.5, cabBottom)
      ..close();
    canvas.drawPath(cabPath, Paint()..color = const Color(0xFF0F172A));

    // 파노라마 통유리창 (Solar Green-Blue Glass)
    final glassPath = Path()
      ..moveTo(cX - cabWidthTop * 0.48, cabTop + 4)
      ..lineTo(cX + cabWidthTop * 0.48, cabTop + 4)
      ..lineTo(cX + cabWidthBot * 0.48, cabBottom - 4)
      ..lineTo(cX - cabWidthBot * 0.48, cabBottom - 4)
      ..close();
    final glassShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38BDF8), Color(0xFF0284C7), Color(0xFF0369A1)],
    ).createShader(glassPath.getBounds());
    canvas.drawPath(glassPath, Paint()..shader = glassShader);

    // 창문 프레임 분할선들
    final frameP = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 2.5;
    canvas.drawLine(Offset(cX - 35, cabTop + 4), Offset(cX - 22, cabBottom - 4), frameP);
    canvas.drawLine(Offset(cX, cabTop + 4), Offset(cX, cabBottom - 4), frameP);
    canvas.drawLine(Offset(cX + 35, cabTop + 4), Offset(cX + 22, cabBottom - 4), frameP);

    // 하부 유지보수 캣워크 난간 (Maintenance Gallery Railing)
    canvas.drawRect(Rect.fromLTWH(cX - cabWidthBot * 0.54, cabBottom, cabWidthBot * 1.08, 6), Paint()..color = const Color(0xFFEF4444));

    // 8-6. 옥상 레이더 돔 & 항공장애등 (Doppler Radome & Antenna) - Spot 1 (0.50, 0.24)
    final roofY = cabTop;
    // 옥상 슬래브
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cX, roofY), width: cabWidthTop * 1.05, height: 8), const Radius.circular(3)), Paint()..color = const Color(0xFFE2E8F0));

    // 레이더 돔 (White Spherical Radome)
    canvas.drawCircle(Offset(cX, roofY - 14), 16, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cX, roofY - 14), 16, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // 회전 레이더 바
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cX - 24, roofY - 36, 48, 6), const Radius.circular(2)), Paint()..color = const Color(0xFFEF4444));
    canvas.drawLine(Offset(cX, roofY - 14), Offset(cX, roofY - 33), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2.5);

    // 피뢰침 & 고광도 빨간 스트로브 항공장애등
    canvas.drawLine(Offset(cX, roofY - 36), Offset(cX, roofY - 50), Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2);
    canvas.drawCircle(Offset(cX, roofY - 50), 3.5, Paint()..color = const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(covariant _BuildingScenePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REALISTIC FLAME & CONTINUOUS HIGH-PRESSURE WATER JET PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _FireAndWaterEffectsPainter extends CustomPainter {
  final List<FireSpot> spots;
  final List<_EmberParticle> embers;
  final List<_SmokeParticle> smokes;
  final List<_WaterSplash> splashes;
  final List<_SteamParticle> steamParticles;
  final List<_ConfettiParticle> confetti;
  final bool isSpraying;
  final Offset? touchPos;
  final Size screenSize;

  _FireAndWaterEffectsPainter({
    required this.spots,
    required this.embers,
    required this.smokes,
    required this.splashes,
    required this.steamParticles,
    required this.confetti,
    required this.isSpraying,
    required this.touchPos,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Billowing Smoke Clouds
    for (final smoke in smokes) {
      final smokePaint = Paint()
        ..color = const Color(0xFF334155).withValues(alpha: (smoke.life / smoke.maxLife) * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(smoke.pos, smoke.radius, smokePaint);
    }

    // 2. REALISTIC ROARING MULTI-TONGUE FLAMES at each FireSpot
    for (final spot in spots) {
      if (!spot.isExtinguished && spot.hp > 0) {
        final center = Offset(
          spot.relativePos.dx * size.width,
          spot.relativePos.dy * size.height,
        );
        final scale = (0.35 + (spot.hp / 100.0) * 0.65);
        _drawRealisticFire(canvas, center, spot.radius * scale, spot.flamePhase);
      }
    }

    // 3. Flying Glowing Embers (Sparks)
    for (final ember in embers) {
      final emberPaint = Paint()
        ..color = ember.color.withValues(alpha: ember.life)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(ember.pos, ember.radius, emberPaint);
    }

    // 4. REALISTIC CONTINUOUS HIGH-PRESSURE WATER JET STREAM
    if (isSpraying && touchPos != null) {
      final nozzleBaseX = size.width * 0.5;
      final nozzleBaseY = size.height - 65;
      final dx = touchPos!.dx - nozzleBaseX;
      final dy = touchPos!.dy - nozzleBaseY;
      final angle = atan2(dy, dx).clamp(-pi * 0.85, -pi * 0.15);
      final nozzleTip = Offset(nozzleBaseX + cos(angle) * 54, nozzleBaseY + sin(angle) * 54);
      _drawWaterJetStream(canvas, nozzleTip, touchPos!);
    }

    // 5. Water Splashes at Impact Point
    for (final s in splashes) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, s.radius, paint);

      final shinePaint = Paint()..color = Colors.white.withValues(alpha: s.life * 0.75);
      canvas.drawCircle(s.pos - Offset(s.radius * 0.3, s.radius * 0.3), s.radius * 0.35, shinePaint);
    }

    // 6. Steam Sizzling Puffs
    for (final steam in steamParticles) {
      final steamPaint = Paint()
        ..color = Colors.white.withValues(alpha: (steam.life / steam.maxLife) * 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(steam.pos, steam.radius, steamPaint);
    }

    // 7. Confetti
    for (final c in confetti) {
      canvas.save();
      canvas.translate(c.pos.dx, c.pos.dy);
      canvas.rotate(c.rotation);
      final cPaint = Paint()..color = c.color;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6), cPaint);
      canvas.restore();
    }
  }

  void _drawWaterJetStream(Canvas canvas, Offset origin, Offset target) {
    // Parabolic Midpoint for realistic water arc gravity curve
    final midX = (origin.dx + target.dx) * 0.5;
    final midY = min(origin.dy, target.dy) - (origin.dx - target.dx).abs() * 0.08 - 15;
    final ctrlPoint = Offset(midX, midY);

    // Outer Foaming Blue Water Aura
    final outerWaterPath = Path();
    outerWaterPath.moveTo(origin.dx - 8, origin.dy);
    outerWaterPath.quadraticBezierTo(ctrlPoint.dx - 12, ctrlPoint.dy, target.dx - 14, target.dy);
    outerWaterPath.lineTo(target.dx + 14, target.dy);
    outerWaterPath.quadraticBezierTo(ctrlPoint.dx + 12, ctrlPoint.dy, origin.dx + 8, origin.dy);
    outerWaterPath.close();

    final outerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(outerWaterPath, outerPaint);

    // Inner High-Pressure White-Cyan Core Beam
    final innerWaterPath = Path();
    innerWaterPath.moveTo(origin.dx - 4, origin.dy);
    innerWaterPath.quadraticBezierTo(ctrlPoint.dx - 5, ctrlPoint.dy, target.dx - 6, target.dy);
    innerWaterPath.lineTo(target.dx + 6, target.dy);
    innerWaterPath.quadraticBezierTo(ctrlPoint.dx + 5, ctrlPoint.dy, origin.dx + 4, origin.dy);
    innerWaterPath.close();

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white,
          const Color(0xFFE0F2FE),
          const Color(0xFF38BDF8),
        ],
      ).createShader(Rect.fromPoints(origin, target));
    canvas.drawPath(innerWaterPath, innerPaint);

    // Water Splash Shockwave Dome at Target
    final domePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(target, 16, domePaint);

    final cyanDomePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(target, 24, cyanDomePaint);
  }

  void _drawRealisticFire(Canvas canvas, Offset center, double r, double phase) {
    // 1. Fiery Heat Aura / Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.38)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.75);
    canvas.drawCircle(center, r * 1.35, glowPaint);

    // 2. Base Red Fire Outer Boundary
    final outerRedPaint = Paint()..color = const Color(0xFFDC2626);
    _drawFlameShape(canvas, center, r * 1.25, phase, outerRedPaint, tallFactor: 1.35);

    // 3. Middle Dancing Orange Flame Body
    final orangePaint = Paint()..color = const Color(0xFFFF7A00);
    _drawFlameShape(canvas, center + const Offset(0, 3), r * 0.92, phase + 1.3, orangePaint, tallFactor: 1.15);

    // 4. Inner Golden-Yellow Core
    final yellowPaint = Paint()..color = const Color(0xFFFFD500);
    _drawFlameShape(canvas, center + const Offset(0, 6), r * 0.62, phase + 2.6, yellowPaint, tallFactor: 0.95);

    // 5. Incandescent White-Hot Heart
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    _drawFlameShape(canvas, center + const Offset(0, 8), r * 0.32, phase + 3.8, whitePaint, tallFactor: 0.70);
  }

  void _drawFlameShape(Canvas canvas, Offset center, double r, double phase, Paint paint, {required double tallFactor}) {
    final path = Path();
    
    final leftTipX = center.dx - r * 0.62 + sin(phase * 3.2) * (r * 0.18);
    final leftTipY = center.dy - r * (0.85 * tallFactor) + cos(phase * 2.8) * (r * 0.15);

    final centerTipX = center.dx + sin(phase * 4.1) * (r * 0.22);
    final centerTipY = center.dy - r * (1.30 * tallFactor) + cos(phase * 3.5) * (r * 0.20);

    final rightTipX = center.dx + r * 0.62 + sin(phase * 3.6) * (r * 0.18);
    final rightTipY = center.dy - r * (0.90 * tallFactor) + cos(phase * 3.1) * (r * 0.15);

    final bottomY = center.dy + r * 0.55;
    final leftBaseX = center.dx - r * 0.75;
    final rightBaseX = center.dx + r * 0.75;

    path.moveTo(center.dx, bottomY);
    path.cubicTo(leftBaseX, bottomY, leftBaseX - r * 0.1, center.dy, leftTipX, leftTipY);
    path.cubicTo(leftTipX + r * 0.2, leftTipY + r * 0.3, center.dx - r * 0.3, center.dy - r * 0.5, centerTipX, centerTipY);
    path.cubicTo(centerTipX + r * 0.3, centerTipY + r * 0.5, rightTipX - r * 0.2, rightTipY + r * 0.3, rightTipX, rightTipY);
    path.cubicTo(rightBaseX + r * 0.1, center.dy, rightBaseX, bottomY, center.dx, bottomY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FireAndWaterEffectsPainter oldDelegate) => true;
}

// 💧 실감나는 중장비 소방 호스 & 황동/크롬 관창 노즐 & 소방관 캐릭터
class _FireHosePainter extends CustomPainter {
  final double nozzleAngle;
  final bool isSpraying;
  final double screenWidth;

  _FireHosePainter({
    required this.nozzleAngle,
    required this.isSpraying,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width * 0.5;
    final baseY = size.height - 40.0;

    // 분사 중일 때의 사실적인 수압 반동 진동 (High-Pressure Recoil Shake)
    final recoilJitterX = isSpraying ? (sin(DateTime.now().millisecondsSinceEpoch * 0.08) * 2.0) : 0.0;
    final recoilJitterY = isSpraying ? (cos(DateTime.now().millisecondsSinceEpoch * 0.09) * 1.5) : 0.0;

    final nozzlePivotX = centerX + recoilJitterX;
    final nozzlePivotY = baseY - 25.0 + recoilJitterY;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 묵직한 고압 소방 호스 (Heavy Fabric/Rubber Fire Hose from Bottom)
    // ─────────────────────────────────────────────────────────────────────────
    // 호스 시작점: 노즐 뒷단 커플러
    final hoseStartOffset = Offset(
      nozzlePivotX - cos(nozzleAngle) * 22,
      nozzlePivotY - sin(nozzleAngle) * 22,
    );

    // 호스 끝점: 화면 아래쪽 바닥 (소방차 펌프 연결부)
    final hoseEndOffset = Offset(centerX + 35, size.height + 25);

    final cp1 = Offset(hoseStartOffset.dx - cos(nozzleAngle) * 45, hoseStartOffset.dy - sin(nozzleAngle) * 45 + 30);
    final cp2 = Offset(centerX + 15, size.height - 5);

    final hosePath = Path()
      ..moveTo(hoseStartOffset.dx, hoseStartOffset.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, hoseEndOffset.dx, hoseEndOffset.dy);

    // 1-1. 호스 바닥 깊은 그림자 (Ground Drop Shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(hosePath, shadowPaint);

    // 1-2. 호스 외피 바디 (진한 소방 레드 캔버스 패브릭 질감)
    final hoseBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFEF4444), // Fire Red
          Color(0xFFB91C1C),
          Color(0xFF7F1D1D),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(hosePath, hoseBodyPaint);

    // 1-3. 호스 안전 반사 스트라이프 라인 (High-Vis Safety Yellow Stripe)
    final stripePaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, stripePaint);

    // 1-4. 호스 상단 빛 반사 하이라이트 (Glossy Specular)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, highlightPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 든든한 소방관 캐릭터 상체 (Firefighter Body & Helmet)
    // ─────────────────────────────────────────────────────────────────────────
    // 소방관 방화복 상체 (Yellow/Black Turnout Gear)
    final coatRect = Rect.fromCenter(center: Offset(centerX, baseY + 15), width: 84, height: 50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(coatRect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF1E293B),
    );
    // 방화복 반사 띠 (Neon Reflective Band)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY + 8), width: 80, height: 10), const Radius.circular(4)),
      Paint()..color = const Color(0xFFFACC15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY + 8), width: 78, height: 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE2E8F0),
    );

    // 소방관 헬멧 (Fire Helmet)
    canvas.drawCircle(Offset(centerX, baseY - 12), 22, Paint()..color = const Color(0xFFDC2626));
    // 헬멧 챙 (Brim)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY - 2), width: 56, height: 8), const Radius.circular(4)),
      Paint()..color = const Color(0xFF991B1B),
    );
    // 헬멧 골드 뱃지 (Shield Emblem)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY - 16), width: 14, height: 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(Offset(centerX, baseY - 16), 3.5, Paint()..color = const Color(0xFF78350F));

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 정밀 회전 조준 황동/크롬 고압 관창 노즐 (Rotational Brass Pistol Nozzle)
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(nozzlePivotX, nozzlePivotY);
    canvas.rotate(nozzleAngle + pi / 2); // 노즐 진행 방향 정렬

    // 3-1. 황동 호스 결합 커플러 (Brass Coupler Collar)
    final couplerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 22), width: 28, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(couplerRect, Paint()..color = const Color(0xFFD97706));
    canvas.drawRRect(couplerRect, Paint()..color = Colors.black.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 3-2. 노즐 본체 메인 배럴 (Chrome & Solid Brass Heavy Barrel)
    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 22, height: 38),
      const Radius.circular(5),
    );
    final barrelGradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF92400E),
        Color(0xFFFBBF24),
        Color(0xFFFDE68A),
        Color(0xFFB45309),
      ],
    ).createShader(Rect.fromCenter(center: Offset.zero, width: 22, height: 38));
    canvas.drawRRect(barrelRect, Paint()..shader = barrelGradient);

    // 3-3. 듀얼 인체공학 피스톨 손잡이 (Pistol Grip Handle)
    final handlePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 26), const Radius.circular(5)),
      handlePaint,
    );
    // 손잡이 미끄럼 방지 홈 (Grip Grooves)
    final gripLine = Paint()..color = const Color(0xFF475569)..strokeWidth = 2;
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), gripLine);
    canvas.drawLine(const Offset(-6, 6), const Offset(6, 6), gripLine);
    canvas.drawLine(const Offset(-6, 12), const Offset(6, 12), gripLine);

    // 3-4. 수압 조절 밸브 레버 (Shut-off Ball Valve Lever)
    final leverPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(14, 2), width: 8, height: 22), const Radius.circular(3)),
      leverPaint,
    );
    canvas.drawCircle(const Offset(14, -8), 4.5, Paint()..color = const Color(0xFFB91C1C));

    // 3-5. 노즐 헤드 팁 & 분사 조절 고무 링 (Rubber Bumper Nozzle Tip)
    final tipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -22), width: 26, height: 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(tipRect, Paint()..color = const Color(0xFF1E293B));

    // 황동 방수구 구멍 (Water Orifice Nozzle Hole)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 16, height: 6),
      Paint()..color = const Color(0xFF0284C7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 10, height: 4),
      Paint()..color = const Color(0xFFE0F2FE),
    );

    // 3-6. 분사 시 노즐 끝 고압 수압 아우라 글로우 (Water Jet Muzzle Glow)
    if (isSpraying) {
      canvas.drawCircle(
        const Offset(0, -32),
        16,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        const Offset(0, -32),
        8,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // 3-7. 소방관 방수 장갑 손 (Gloves Holding the Nozzle firmly)
    final glovePaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(const Offset(-13, 6), 9, glovePaint);
    canvas.drawCircle(const Offset(13, 6), 9, glovePaint);
    canvas.drawCircle(const Offset(-13, 6), 7, Paint()..color = const Color(0xFFC2410C));
    canvas.drawCircle(const Offset(13, 6), 7, Paint()..color = const Color(0xFFC2410C));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FireHosePainter oldDelegate) => true;
}
