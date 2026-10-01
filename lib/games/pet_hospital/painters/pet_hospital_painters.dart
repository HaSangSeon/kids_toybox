part of '../pet_hospital_game.dart';

// ── 🌟 Nordic Vector Animal Master Painter (완벽한 동물별 실루엣 일러스트) ──────

class _NordicAnimalIllustrationPainter extends CustomPainter {
  final _PatientData patient;
  final double idleProgress;
  final bool isHappy;
  final bool isFever;
  final bool isSad;
  final bool isOpenMouth;

  _NordicAnimalIllustrationPainter({
    required this.patient,
    required this.idleProgress,
    required this.isHappy,
    required this.isFever,
    required this.isSad,
    required this.isOpenMouth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final breathe = sin(idleProgress * 2 * pi) * 2.5;

    switch (patient.id) {
      case 'rabbit':
        _drawBunny(canvas, size, cx, cy, breathe);
        break;
      case 'bear':
        _drawBear(canvas, size, cx, cy, breathe);
        break;
      case 'dog':
        _drawDog(canvas, size, cx, cy, breathe);
        break;
      case 'panda':
        _drawPanda(canvas, size, cx, cy, breathe);
        break;
      case 'fox':
        _drawFox(canvas, size, cx, cy, breathe);
        break;
      case 'tiger':
        _drawTiger(canvas, size, cx, cy, breathe);
        break;
      case 'penguin':
        _drawPenguin(canvas, size, cx, cy, breathe);
        break;
      case 'lion':
        _drawLion(canvas, size, cx, cy, breathe);
        break;
      case 'koala':
        _drawKoala(canvas, size, cx, cy, breathe);
        break;
      case 'cat':
      default:
        _drawCat(canvas, size, cx, cy, breathe);
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐰 1. BUNNY (하늘빛 조약돌 바디 + 쫑긋한 롱 토끼 귀 + 앙증맞은 앞발)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawBunny(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ── 1. Long Bunny Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 45, 95);
    leftEarPath.cubicTo(cx - 50, 45, cx - 48, 12, cx - 35, 12);
    leftEarPath.cubicTo(cx - 22, 12, cx - 22, 45, cx - 18, 90);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    // Left Ear Inner White
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 40, 90);
    leftEarInner.cubicTo(cx - 44, 48, cx - 42, 20, cx - 35, 20);
    leftEarInner.cubicTo(cx - 28, 20, cx - 28, 48, cx - 24, 85);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, whitePaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 18, 90);
    rightEarPath.cubicTo(cx + 22, 45, cx + 22, 12, cx + 35, 12);
    rightEarPath.cubicTo(cx + 48, 12, cx + 50, 45, cx + 45, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    // Right Ear Inner White
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 24, 85);
    rightEarInner.cubicTo(cx + 28, 48, cx + 28, 20, cx + 35, 20);
    rightEarInner.cubicTo(cx + 42, 20, cx + 44, 48, cx + 40, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, whitePaint);

    // ── 2. Little Feet at Bottom ──
    final leftFoot = Path()
      ..moveTo(cx - 65, 290)
      ..cubicTo(cx - 85, 305, cx - 45, 310, cx - 40, 295)
      ..close();
    canvas.drawPath(leftFoot, bodyPaint);

    final rightFoot = Path()
      ..moveTo(cx + 40, 295)
      ..cubicTo(cx + 45, 310, cx + 85, 305, cx + 65, 290)
      ..close();
    canvas.drawPath(rightFoot, bodyPaint);

    // ── 3. Smooth Pear/Teardrop Body ──
    final bodyPath = Path();
    bodyPath.moveTo(cx - 48, 92 - breathe);
    bodyPath.cubicTo(cx - 65, 130, cx - 72, 180, cx - 80, 240);
    bodyPath.cubicTo(cx - 85, 285, cx + 85, 285, cx + 80, 240);
    bodyPath.cubicTo(cx + 72, 180, cx + 65, 130, cx + 48, 92 - breathe);
    bodyPath.cubicTo(cx + 30, 72 - breathe, cx - 30, 72 - breathe, cx - 48, 92 - breathe);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Crisp outline for high visibility
    final outlinePaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftEarPath, outlinePaint);
    canvas.drawPath(rightEarPath, outlinePaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // ── 4. Front Tucked Paws ──
    final leftPaw = Path()
      ..moveTo(cx - 28, 175)
      ..cubicTo(cx - 40, 185, cx - 32, 200, cx - 22, 192);
    canvas.drawPath(leftPaw, strokePaint);

    final rightPaw = Path()
      ..moveTo(cx + 28, 175)
      ..cubicTo(cx + 40, 185, cx + 32, 200, cx + 22, 192);
    canvas.drawPath(rightPaw, strokePaint);

    // ── 5. Facial Features (Eyes, Nose, Mouth) ──
    _drawBeadEyes(canvas, cx - 30, 135, cx + 30, 135, 6.5);
    _drawNordicNoseMouth(canvas, cx, 145, const Color(0xFF263238), isTiny: true);
    _drawCheekBlush(canvas, cx - 48, 146, cx + 48, 146, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐻 2. BEAR (듬직하고 둥근 갈색 체형 + 동그란 곰 귀 + 밝은 머즐)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawBear(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final muzzlePaint = Paint()..color = const Color(0xFFD7CCC8)..style = PaintingStyle.fill;
    final earInnerPaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.fill;

    // ── 1. Round Bear Ears ──
    canvas.drawCircle(Offset(cx - 68, 88), 24, bodyPaint);
    canvas.drawCircle(Offset(cx - 68, 88), 13, earInnerPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 24, bodyPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 13, earInnerPaint);

    // ── 2. Stout Bear Feet ──
    final leftFoot = Path()
      ..moveTo(cx - 60, 280)
      ..cubicTo(cx - 75, 315, cx - 35, 318, cx - 30, 285)
      ..close();
    canvas.drawPath(leftFoot, bodyPaint);

    final rightFoot = Path()
      ..moveTo(cx + 30, 285)
      ..cubicTo(cx + 35, 318, cx + 75, 315, cx + 60, 280)
      ..close();
    canvas.drawPath(rightFoot, bodyPaint);

    // ── 3. Stubby Side Arms ──
    final leftArm = Path()
      ..moveTo(cx - 75, 145)
      ..cubicTo(cx - 110, 160, cx - 112, 190, cx - 78, 195)
      ..close();
    canvas.drawPath(leftArm, bodyPaint);

    final rightArm = Path()
      ..moveTo(cx + 75, 145)
      ..cubicTo(cx + 110, 160, cx + 112, 190, cx + 78, 195)
      ..close();
    canvas.drawPath(rightArm, bodyPaint);

    // ── 4. Chunky Rounded Bear Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 180, height: 210),
      const Radius.circular(85),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 5. Muzzle & Face ──
    // Cream Snout
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 148), width: 48, height: 36),
      muzzlePaint,
    );

    _drawBeadEyes(canvas, cx - 38, 122, cx + 38, 122, 7.0);
    _drawNordicNoseMouth(canvas, cx, 142, const Color(0xFF212121), isTiny: false);
    _drawCheekBlush(canvas, cx - 55, 138, cx + 55, 138, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐶 3. DOG (카라멜 바디 + 축 늘어진 초코색 귀 + 앙증맞은 말린 꼬리 + 앞다리)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawDog(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final earPaint = Paint()..color = const Color(0xFF6D4C41)..style = PaintingStyle.fill;
    final legStrokePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // ── 1. Curled-up Puppy Tail on the Left ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx - 70, 240)
      ..cubicTo(cx - 105, 245, cx - 118, 205, cx - 95, 190);
    canvas.drawPath(tailPath, tailPaint);

    // ── 2. Floppy Chocolate Puppy Ears ──
    // Left Ear: starts near head top, curves outward and droops down with rounded lobe
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 55, 95);
    leftEarPath.cubicTo(cx - 100, 85, cx - 105, 145, cx - 88, 155);
    leftEarPath.cubicTo(cx - 72, 162, cx - 68, 125, cx - 50, 115);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, earPaint);

    // Right Ear: mirrors to the right
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 55, 95);
    rightEarPath.cubicTo(cx + 100, 85, cx + 105, 145, cx + 88, 155);
    rightEarPath.cubicTo(cx + 72, 162, cx + 68, 125, cx + 50, 115);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, earPaint);

    // ── 3. Smooth Rounded Dog Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 165, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Two Vertical Front Legs ──
    canvas.drawLine(Offset(cx - 24, 215), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 24, 215), Offset(cx + 24, 285), legStrokePaint);
    // Paw arches
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 22, height: 16), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 24, 285), width: 22, height: 16), 0, pi, false, legStrokePaint);

    // ── 5. Facial Features ──
    _drawBeadEyes(canvas, cx - 34, 125, cx + 34, 125, 7.0);
    _drawNordicNoseMouth(canvas, cx, 140, const Color(0xFF212121), isTiny: false);
    _drawCheekBlush(canvas, cx - 50, 138, cx + 50, 138, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐱 4. CAT (세련된 그레이 바디 + 뾰족 냥이 귀 + 우아한 꼬리 + 양볼 수염)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawCat(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final earInnerPaint = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;
    final whiskerPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final legStrokePaint = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // ── 1. Elegant Cat Tail on the Right ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 65, 240)
      ..cubicTo(cx + 105, 245, cx + 115, 200, cx + 98, 175);
    canvas.drawPath(tailPath, tailPaint);

    // ── 2. Triangular Pointy Cat Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 62, 95);
    leftEarPath.lineTo(cx - 68, 48); // sharp tip
    leftEarPath.lineTo(cx - 24, 82);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    // Left Ear Inner
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 58, 90);
    leftEarInner.lineTo(cx - 63, 58);
    leftEarInner.lineTo(cx - 32, 82);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 24, 82);
    rightEarPath.lineTo(cx + 68, 48); // sharp tip
    rightEarPath.lineTo(cx + 62, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    // Right Ear Inner
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 32, 82);
    rightEarInner.lineTo(cx + 63, 58);
    rightEarInner.lineTo(cx + 58, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    // ── 3. Smooth Cylindrical Cat Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 4, 185 - (breathe * 0.5)), width: 160, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Two Neat Front Paws ──
    canvas.drawLine(Offset(cx - 24, 220), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 16, 220), Offset(cx + 16, 285), legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 16, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);

    // ── 5. Whiskers (3 lines on each side) ──
    // Left whiskers
    canvas.drawLine(Offset(cx - 38, 134), Offset(cx - 68, 128), whiskerPaint);
    canvas.drawLine(Offset(cx - 40, 140), Offset(cx - 72, 140), whiskerPaint);
    canvas.drawLine(Offset(cx - 38, 146), Offset(cx - 68, 152), whiskerPaint);
    // Right whiskers
    canvas.drawLine(Offset(cx + 30, 134), Offset(cx + 60, 128), whiskerPaint);
    canvas.drawLine(Offset(cx + 32, 140), Offset(cx + 64, 140), whiskerPaint);
    canvas.drawLine(Offset(cx + 30, 146), Offset(cx + 60, 152), whiskerPaint);

    // ── 6. Facial Features ──
    _drawBeadEyes(canvas, cx - 28, 125, cx + 20, 125, 6.5);
    _drawNordicNoseMouth(canvas, cx - 4, 138, const Color(0xFF37474F), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 140, cx + 36, 140, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐼 5. PANDA (새하얀 둥근 바디 + 까만 판다 귀 & 눈가 패치 + 까만 팔다리)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPanda(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
    final eyePatchPaint = Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.fill;

    // ── 1. Round Dark Charcoal Panda Ears ──
    canvas.drawCircle(Offset(cx - 68, 88), 24, darkPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 24, darkPaint);

    // ── 2. Stout Black Feet ──
    final leftFoot = Path()
      ..moveTo(cx - 60, 280)
      ..cubicTo(cx - 75, 315, cx - 35, 318, cx - 30, 285)
      ..close();
    canvas.drawPath(leftFoot, darkPaint);

    final rightFoot = Path()
      ..moveTo(cx + 30, 285)
      ..cubicTo(cx + 35, 318, cx + 75, 315, cx + 60, 280)
      ..close();
    canvas.drawPath(rightFoot, darkPaint);

    // ── 3. Black Panda Side Arms ──
    final leftArm = Path()
      ..moveTo(cx - 75, 145)
      ..cubicTo(cx - 110, 160, cx - 112, 190, cx - 78, 195)
      ..close();
    canvas.drawPath(leftArm, darkPaint);

    final rightArm = Path()
      ..moveTo(cx + 75, 145)
      ..cubicTo(cx + 110, 160, cx + 112, 190, cx + 78, 195)
      ..close();
    canvas.drawPath(rightArm, darkPaint);

    // ── 4. Chunky Soft White Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 180, height: 210),
      const Radius.circular(85),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Soft contour outline for high visibility
    final contourPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRRect, contourPaint);

    // Subtle dark shoulder band
    final vestPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 190), width: 155, height: 45), vestPaint);

    // ── 5. Iconic Tilted Panda Eye Patches ──
    // Left eye patch
    canvas.save();
    canvas.translate(cx - 36, 125);
    canvas.rotate(-0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 34, height: 26), eyePatchPaint);
    canvas.restore();

    // Right eye patch
    canvas.save();
    canvas.translate(cx + 36, 125);
    canvas.rotate(0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 34, height: 26), eyePatchPaint);
    canvas.restore();

    // ── 6. Eyes, Nose & Blush ──
    _drawBeadEyes(canvas, cx - 36, 124, cx + 36, 124, 6.0);
    _drawNordicNoseMouth(canvas, cx, 142, const Color(0xFF212121), isTiny: true);
    _drawCheekBlush(canvas, cx - 55, 145, cx + 55, 145, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🦊 6. FOX (따뜻한 코랄 오렌지 바디 + 뾰족 귀 & 초코 팁 + 풍성한 하얀 꼬리 끝)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawFox(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = const Color(0xFFFFF8E1)..style = PaintingStyle.fill;
    final darkTipPaint = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.fill;
    final legStrokePaint = Paint()
      ..color = const Color(0xFFBF360C)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    // ── 1. Big Bushy Fox Tail with White Tip on the Right ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 60, 240)
      ..cubicTo(cx + 115, 245, cx + 125, 185, cx + 98, 160);
    canvas.drawPath(tailPath, tailPaint);

    // Bushy white tail tip
    final tipPaint = Paint()
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tipPath = Path()
      ..moveTo(cx + 110, 185)
      ..quadraticBezierTo(cx + 108, 170, cx + 98, 160);
    canvas.drawPath(tipPath, tipPaint);

    // ── 2. Triangular Pointed Fox Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 64, 95);
    leftEarPath.lineTo(cx - 72, 42); // sharp tip
    leftEarPath.lineTo(cx - 22, 80);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);

    // Left Ear Dark Tip
    final leftTip = Path();
    leftTip.moveTo(cx - 68, 62);
    leftTip.lineTo(cx - 72, 42);
    leftTip.lineTo(cx - 52, 58);
    leftTip.close();
    canvas.drawPath(leftTip, darkTipPaint);

    // Left Ear Inner Cream
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 60, 90);
    leftEarInner.lineTo(cx - 65, 62);
    leftEarInner.lineTo(cx - 30, 80);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, whitePaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 22, 80);
    rightEarPath.lineTo(cx + 72, 42); // sharp tip
    rightEarPath.lineTo(cx + 64, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);

    // Right Ear Dark Tip
    final rightTip = Path();
    rightTip.moveTo(cx + 52, 58);
    rightTip.lineTo(cx + 72, 42);
    rightTip.lineTo(cx + 68, 62);
    rightTip.close();
    canvas.drawPath(rightTip, darkTipPaint);

    // Right Ear Inner Cream
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 30, 80);
    rightEarInner.lineTo(cx + 65, 62);
    rightEarInner.lineTo(cx + 60, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, whitePaint);

    // ── 3. Smooth Cylindrical Fox Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 2, 185 - (breathe * 0.5)), width: 165, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Fluffy White Muzzle / Bib ──
    final bibPath = Path();
    bibPath.moveTo(cx - 2, 140);
    bibPath.quadraticBezierTo(cx - 38, 148, cx - 25, 175);
    bibPath.quadraticBezierTo(cx - 2, 205, cx + 25, 175);
    bibPath.quadraticBezierTo(cx + 38, 148, cx - 2, 140);
    bibPath.close();
    canvas.drawPath(bibPath, whitePaint);

    // ── 5. Front Paws ──
    canvas.drawLine(Offset(cx - 24, 220), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 18, 220), Offset(cx + 18, 285), legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 18, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);

    // ── 6. Facial Features ──
    _drawBeadEyes(canvas, cx - 28, 124, cx + 24, 124, 6.5);
    _drawNordicNoseMouth(canvas, cx - 2, 138, const Color(0xFF212121), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 142, cx + 40, 142, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐯 7. TIGER (비비드 오렌지 바디 + 이마 王 줄무늬 + 하얀 머즐 & 줄무늬 꼬리)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawTiger(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = patient.darkColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = const Color(0xFFFFF8E1)..style = PaintingStyle.fill;
    final stripePaint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 1. Striped Tail on the Right
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 60, 240)
      ..cubicTo(cx + 115, 245, cx + 125, 185, cx + 98, 160);
    canvas.drawPath(tailPath, tailPaint);
    // Tail stripes
    canvas.drawLine(Offset(cx + 90, 215), Offset(cx + 102, 205), stripePaint);
    canvas.drawLine(Offset(cx + 105, 185), Offset(cx + 115, 175), stripePaint);

    // 2. Round Ears with Dark Edges
    canvas.drawCircle(Offset(cx - 55, 92), 22, darkPaint);
    canvas.drawCircle(Offset(cx - 55, 92), 15, bodyPaint);
    canvas.drawCircle(Offset(cx - 55, 92), 9, whitePaint);

    canvas.drawCircle(Offset(cx + 55, 92), 22, darkPaint);
    canvas.drawCircle(Offset(cx + 55, 92), 15, bodyPaint);
    canvas.drawCircle(Offset(cx + 55, 92), 9, whitePaint);

    // 3. Smooth Pear Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 170, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 4. White Belly / Bib
    final bibPath = Path();
    bibPath.moveTo(cx, 150);
    bibPath.quadraticBezierTo(cx - 36, 160, cx - 28, 220);
    bibPath.quadraticBezierTo(cx, 245, cx + 28, 220);
    bibPath.quadraticBezierTo(cx + 36, 160, cx, 150);
    bibPath.close();
    canvas.drawPath(bibPath, whitePaint);

    // 5. Forehead '王' Stripes & Cheek Stripes
    canvas.drawLine(Offset(cx - 14, 88), Offset(cx + 14, 88), stripePaint);
    canvas.drawLine(Offset(cx - 10, 96), Offset(cx + 10, 96), stripePaint);
    canvas.drawLine(Offset(cx, 84), Offset(cx, 102), stripePaint);

    // Cheek stripes
    canvas.drawLine(Offset(cx - 68, 128), Offset(cx - 48, 132), stripePaint);
    canvas.drawLine(Offset(cx - 65, 140), Offset(cx - 48, 142), stripePaint);
    canvas.drawLine(Offset(cx + 68, 128), Offset(cx + 48, 132), stripePaint);
    canvas.drawLine(Offset(cx + 65, 140), Offset(cx + 48, 142), stripePaint);

    // 6. Front Paws
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 28, 265), width: 34, height: 26), whitePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 28, 265), width: 34, height: 26), whitePaint);

    // 7. Facial Features
    _drawBeadEyes(canvas, cx - 28, 124, cx + 28, 124, 6.5);
    _drawNordicNoseMouth(canvas, cx, 142, const Color(0xFFD84315), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 144, cx + 44, 144, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐧 8. PENGUIN (딥네이비 조약돌 바디 + 턱시도 화이트 배 + 노란 부리 & 플리퍼)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPenguin(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final beakPaint = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.fill;
    final footPaint = Paint()..color = const Color(0xFFFF8F00)..style = PaintingStyle.fill;

    // 1. Orange Webbed Feet
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 32, 285), width: 36, height: 20), footPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 32, 285), width: 36, height: 20), footPaint);

    // 2. Wings (Flippers)
    final leftWing = Path()
      ..moveTo(cx - 68, 150)
      ..quadraticBezierTo(cx - 100, 185, cx - 82, 225)
      ..quadraticBezierTo(cx - 60, 205, cx - 60, 160)
      ..close();
    canvas.drawPath(leftWing, bodyPaint);

    final rightWing = Path()
      ..moveTo(cx + 68, 150)
      ..quadraticBezierTo(cx + 100, 185, cx + 82, 225)
      ..quadraticBezierTo(cx + 60, 205, cx + 60, 160)
      ..close();
    canvas.drawPath(rightWing, bodyPaint);

    // 3. Smooth Pear Penguin Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 180 - (breathe * 0.5)), width: 155, height: 215),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 4. White Tuxedo Belly & Face Mask
    final bellyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 195 - (breathe * 0.5)), width: 115, height: 165),
      const Radius.circular(55),
    );
    canvas.drawRRect(bellyRRect, whitePaint);

    // Eye surround mask
    canvas.drawCircle(Offset(cx - 24, 122), 20, whitePaint);
    canvas.drawCircle(Offset(cx + 24, 122), 20, whitePaint);

    // 5. Golden Triangle Beak
    final beakPath = Path()
      ..moveTo(cx - 14, 134)
      ..lineTo(cx, 148)
      ..lineTo(cx + 14, 134)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // 6. Eyes & Blush
    _drawBeadEyes(canvas, cx - 22, 120, cx + 22, 120, 6.0);
    _drawCheekBlush(canvas, cx - 42, 138, cx + 42, 138, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🦁 9. LION (풍성한 오렌지 갈기 + 골든 옐로우 바디 + 크림 머즐 & 꼬리 술)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawLion(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final manePaint = Paint()..color = patient.darkColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = const Color(0xFFFFF8E1)..style = PaintingStyle.fill;

    // 1. Lion Tufted Tail on the Right
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 60, 240)
      ..cubicTo(cx + 115, 245, cx + 125, 185, cx + 98, 160);
    canvas.drawPath(tailPath, tailPaint);
    canvas.drawCircle(Offset(cx + 98, 160), 16, manePaint); // Tuft

    // 2. Sunflower Styled Full Mane (풍성한 갈기)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * pi / 12);
      final mx = cx + cos(angle) * 72;
      final my = 135 + sin(angle) * 72;
      canvas.drawCircle(Offset(mx, my), 28, manePaint);
    }

    // 3. Round Ears Behind Head
    canvas.drawCircle(Offset(cx - 56, 82), 18, bodyPaint);
    canvas.drawCircle(Offset(cx - 56, 82), 10, whitePaint);
    canvas.drawCircle(Offset(cx + 56, 82), 18, bodyPaint);
    canvas.drawCircle(Offset(cx + 56, 82), 10, whitePaint);

    // 4. Smooth Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 195 - (breathe * 0.5)), width: 155, height: 185),
      const Radius.circular(70),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 5. Cream Belly & Face Circle
    canvas.drawCircle(Offset(cx, 135), 62, bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 215), width: 85, height: 95), whitePaint);

    // 6. Cream Snout Muzzle
    final snoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 145), width: 52, height: 38),
      const Radius.circular(18),
    );
    canvas.drawRRect(snoutRect, whitePaint);

    // 7. Front Paws
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 28, 270), width: 34, height: 24), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 28, 270), width: 34, height: 24), bodyPaint);

    // 8. Eyes, Nose & Blush
    _drawBeadEyes(canvas, cx - 26, 122, cx + 26, 122, 6.5);
    _drawNordicNoseMouth(canvas, cx, 138, const Color(0xFF3E2723), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 142, cx + 44, 142, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐨 10. KOALA (복슬복슬 큰 회색 귀 + 둥근 조약돌 바디 + 큼직한 흑색 고무 코)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawKoala(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = patient.darkColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = const Color(0xFFECEFF1)..style = PaintingStyle.fill;

    // 1. Giant Fluffy Koala Ears
    // Left ear with tufts
    canvas.drawCircle(Offset(cx - 68, 92), 34, bodyPaint);
    canvas.drawCircle(Offset(cx - 68, 92), 22, whitePaint);
    canvas.drawCircle(Offset(cx - 82, 85), 14, whitePaint); // Fluff

    // Right ear with tufts
    canvas.drawCircle(Offset(cx + 68, 92), 34, bodyPaint);
    canvas.drawCircle(Offset(cx + 68, 92), 22, whitePaint);
    canvas.drawCircle(Offset(cx + 82, 85), 14, whitePaint); // Fluff

    // 2. Smooth Pear Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 165, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // 3. Soft Light Chest / Belly
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 205), width: 95, height: 115), whitePaint);

    // 4. Round Head
    canvas.drawCircle(Offset(cx, 130), 65, bodyPaint);

    // 5. Iconic Big Oval Rubber Koala Nose
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 136), width: 34, height: 48), darkPaint);
    // Nose highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 4, 126), width: 10, height: 14),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    // 6. Front Paws
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 32, 268), width: 32, height: 24), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 32, 268), width: 32, height: 24), bodyPaint);

    // 7. Eyes & Blush
    _drawBeadEyes(canvas, cx - 34, 122, cx + 34, 122, 6.0);
    _drawCheekBlush(canvas, cx - 48, 144, cx + 48, 144, isFever: isFever);
  }

  // ── Helper: Cute Glossy Bead Eyes (초롱초롱 구슬 눈) ──────────────────────
  void _drawBeadEyes(Canvas canvas, double leftX, double leftY, double rightX, double rightY, double radius) {
    if (isHappy) {
      final happyPaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // Left happy eye
      final leftPath = Path()..moveTo(leftX - radius, leftY + 2)..quadraticBezierTo(leftX, leftY - radius, leftX + radius, leftY + 2);
      canvas.drawPath(leftPath, happyPaint);
      // Right happy eye
      final rightPath = Path()..moveTo(rightX - radius, rightY + 2)..quadraticBezierTo(rightX, rightY - radius, rightX + radius, rightY + 2);
      canvas.drawPath(rightPath, happyPaint);
      return;
    }

    final eyePaint = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final shinePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Left Eye
    canvas.drawCircle(Offset(leftX, leftY), radius, eyePaint);
    canvas.drawCircle(Offset(leftX - (radius * 0.3), leftY - (radius * 0.3)), radius * 0.4, shinePaint);
    canvas.drawCircle(Offset(leftX + (radius * 0.35), leftY + (radius * 0.35)), radius * 0.2, shinePaint);

    // Right Eye
    canvas.drawCircle(Offset(rightX, rightY), radius, eyePaint);
    canvas.drawCircle(Offset(rightX - (radius * 0.3), rightY - (radius * 0.3)), radius * 0.4, shinePaint);
    canvas.drawCircle(Offset(rightX + (radius * 0.35), rightY + (radius * 0.35)), radius * 0.2, shinePaint);
  }

  // ── Helper: Nordic Dainty Nose & 'ㅅ' Mouth (심플 앙증 코 & 입) ──────────
  void _drawNordicNoseMouth(Canvas canvas, double cx, double cy, Color color, {required bool isTiny}) {
    if (isOpenMouth) {
      // Big open mouth for syrup
      final openMouthPaint = Paint()..color = const Color(0xFF880E4F)..style = PaintingStyle.fill;
      final mouthPath = Path()
        ..moveTo(cx - 10, cy + 2)
        ..quadraticBezierTo(cx, cy + 18, cx + 10, cy + 2)
        ..close();
      canvas.drawPath(mouthPath, openMouthPaint);
      final tonguePaint = Paint()..color = const Color(0xFFFF4081)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 12, height: 7), tonguePaint);
      return;
    }

    final nosePaint = Paint()..color = color..style = PaintingStyle.fill;
    final mouthPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final nw = isTiny ? 7.0 : 11.0;
    final nh = isTiny ? 5.0 : 7.5;

    // Small rounded nose
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: nw * 2, height: nh * 2), Radius.circular(nh)),
      nosePaint,
    );

    // 'ㅅ' mouth
    final mouthY = cy + nh;
    canvas.drawLine(Offset(cx, mouthY), Offset(cx, mouthY + 3.5), mouthPaint);

    final mouthPath = Path();
    if (isHappy) {
      mouthPath.moveTo(cx - 7, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx - 3.5, mouthY + 8, cx, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx + 3.5, mouthY + 8, cx + 7, mouthY + 3.5);
    } else if (isSad) {
      mouthPath.moveTo(cx - 6, mouthY + 7);
      mouthPath.quadraticBezierTo(cx - 3, mouthY + 3, cx, mouthY + 5.5);
      mouthPath.quadraticBezierTo(cx + 3, mouthY + 3, cx + 6, mouthY + 7);
    } else {
      mouthPath.moveTo(cx - 6, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx - 3, mouthY + 7, cx, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx + 3, mouthY + 7, cx + 6, mouthY + 3.5);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  // ── Helper: Soft Cheek Blush (발그레 볼터치) ──────────────────────────────
  void _drawCheekBlush(Canvas canvas, double leftX, double leftY, double rightX, double rightY, {required bool isFever}) {
    final blushColor = (isFever ? const Color(0xFFFF5252) : const Color(0xFFFF8DA1)).withValues(alpha: isFever ? 0.75 : 0.45);
    final blushPaint = Paint()..color = blushColor..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: Offset(leftX, leftY), width: 22, height: 14), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(rightX, rightY), width: 22, height: 14), blushPaint);
  }

  @override
  bool shouldRepaint(covariant _NordicAnimalIllustrationPainter oldDelegate) =>
      oldDelegate.patient.id != patient.id ||
      oldDelegate.idleProgress != idleProgress ||
      oldDelegate.isHappy != isHappy ||
      oldDelegate.isFever != isFever ||
      oldDelegate.isSad != isSad ||
      oldDelegate.isOpenMouth != isOpenMouth;
}

// ── Nordic Cartoon Thorn Painter (아기자기한 동화풍 가시) ───────────────────

class _NordicThornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 선명하고 굵은 카툰 외곽선 & 짙은 나무결 가시 본체
    final thornGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF8D6E63), Color(0xFF5D4037), Color(0xFF3E2723)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    final strokePaint = Paint()
      ..color = const Color(0xFF1B0000)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(w * 0.5, 0); // 날카로운 가시 끝
    path.quadraticBezierTo(w * 0.82, h * 0.55, w * 0.90, h);
    path.quadraticBezierTo(w * 0.5, h * 0.82, w * 0.10, h);
    path.quadraticBezierTo(w * 0.18, h * 0.55, w * 0.5, 0);
    path.close();

    // 그림자 및 본체 채우기
    canvas.drawPath(path, Paint()..shader = thornGrad);
    canvas.drawPath(path, strokePaint);

    // 하얀 반사광 하이라이트 (Glossy Shine)
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final shinePath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..quadraticBezierTo(w * 0.28, h * 0.55, w * 0.25, h * 0.75);
    canvas.drawPath(shinePath, shinePaint);

    // 싱그러운 초록 새싹 잎사귀 2개 (Bright Green Leaves)
    final leafPaint = Paint()..color = const Color(0xFF4CAF50);
    final leafOutline = Paint()..color = const Color(0xFF1B5E20)..strokeWidth = 1.5..style = PaintingStyle.stroke;

    // 우측 잎
    final leafPath1 = Path()
      ..moveTo(w * 0.75, h * 0.45)
      ..quadraticBezierTo(w * 1.35, h * 0.30, w * 1.30, h * 0.60)
      ..quadraticBezierTo(w * 0.90, h * 0.65, w * 0.75, h * 0.45)
      ..close();
    canvas.drawPath(leafPath1, leafPaint);
    canvas.drawPath(leafPath1, leafOutline);

    // 좌측 잎
    final leafPath2 = Path()
      ..moveTo(w * 0.25, h * 0.60)
      ..quadraticBezierTo(w * -0.30, h * 0.45, w * -0.25, h * 0.75)
      ..quadraticBezierTo(w * 0.10, h * 0.80, w * 0.25, h * 0.60)
      ..close();
    canvas.drawPath(leafPath2, leafPaint);
    canvas.drawPath(leafPath2, leafOutline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Nordic Cartoon Scratch Painter (동화책 느낌의 깔끔한 상처) ───────────────

class _NordicScratchPainter extends CustomPainter {
  final double healProgress;
  final bool isHighlight;

  _NordicScratchPainter({required this.healProgress, required this.isHighlight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final opacity = (1.0 - healProgress).clamp(0.0, 1.0);

    if (opacity <= 0) return;

    // Soft warm blush under scratch
    final glowPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.35 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.1, w * 0.9, h * 0.8), glowPaint);

    // 3 Cute cartoon scratch arcs
    final scratchPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(w * 0.2, h * 0.35)
      ..quadraticBezierTo(w * 0.5, h * 0.25, w * 0.8, h * 0.4);
    canvas.drawPath(path1, scratchPaint);

    final path2 = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.48, w * 0.75, h * 0.6);
    canvas.drawPath(path2, scratchPaint);

    final path3 = Path()
      ..moveTo(w * 0.35, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.7, w * 0.65, h * 0.78);
    canvas.drawPath(path3, scratchPaint);

    // Soothing blue ointment gel when healing
    if (healProgress > 0.0) {
      final gelPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.55 * healProgress)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.6), gelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NordicScratchPainter oldDelegate) =>
      oldDelegate.healProgress != healProgress || oldDelegate.isHighlight != isHighlight;
}

