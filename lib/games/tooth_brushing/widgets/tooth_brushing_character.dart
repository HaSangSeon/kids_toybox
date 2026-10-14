part of '../tooth_brushing_game.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOOTH BRUSHING ANIMAL CHARACTER RENDERING EXTENSION (280x280 Canvas)
// ═══════════════════════════════════════════════════════════════════════════════

extension _ToothBrushingCharacterExtension on _ToothBrushingGameState {
  Widget _buildAnimalHeadWidget({required bool showDirty, required bool openWide, bool isShining = false}) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ambientBubbleCtrl,
        _blinkCtrl,
        _chewCtrl,
        _mascotJumpCtrl,
        _swishCtrl,
      ]),
      builder: (context, child) {
        // Natural Living Animations
        final breathY = sin(_ambientBubbleCtrl.value * pi * 2) * 3.5;
        final jumpY = _step == BrushStep.complete ? (-sin(_mascotJumpCtrl.value * pi) * 24.0) : 0.0;
        final chewY = _isEating ? (sin(_chewCtrl.value * pi) * 14.0) : 0.0;

        final translateY = jumpY + breathY + (chewY * 0.4);
        final scaleX = _step == BrushStep.complete
            ? (1.0 + (sin(_mascotJumpCtrl.value * pi) * -0.05))
            : (_step == BrushStep.rinsing ? (1.0 + (sin(_swishCtrl.value * pi) * 0.04)) : 1.0);
        final scaleY = _step == BrushStep.complete
            ? (1.0 + (sin(_mascotJumpCtrl.value * pi) * 0.08))
            : (_step == BrushStep.eating && _isEating ? (1.0 + (sin(_chewCtrl.value * pi) * 0.06)) : 1.0);

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 0. Character Body & Pajama Bib with Paws
                  _buildCharacterBodyAndPaws(isShining),

                  // 1. Back Features: Ears / Mane / Dino Spikes
                  _buildBackFeatures(isShining),

                  // 2. Main Cute Head & Face Body
                  _buildHeadAndFaceBody(isShining),

                  // 3. Cute Happy Open Mouth Cavity vs Adorable Closed Smile
                  if (openWide) ...[
                    _buildCuteOpenMouth(chewY: chewY),
                    ..._teeth.map((tooth) => _buildSingleTooth(tooth, showDirty, isShining, chewY: chewY)),
                    _buildCuteMuzzle(),
                  ] else ...[
                    _buildCuteClosedMouth(),
                  ],

                  // 4. Sparkling Cute Eyes, Brows & Cheeks
                  _buildCuteEyesAndCheeks(isShining),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 0. Adorable Closed Smile for All Characters (Before eating/brushing) ────

  Widget _buildCuteClosedMouth() {
    switch (_animal.id) {
      case 'rabbit':
        return Positioned(
          top: 130,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 15,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.pink.withValues(alpha: 0.35), blurRadius: 4),
                  ],
                ),
                alignment: Alignment.topLeft,
                padding: const EdgeInsets.only(top: 2, left: 3),
                child: Container(
                  width: 5,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CustomPaint(
                    size: Size(18, 12),
                    painter: _BunnySmileArcPainter(isLeft: true),
                  ),
                  CustomPaint(
                    size: Size(18, 12),
                    painter: _BunnySmileArcPainter(isLeft: false),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('— —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(width: 22),
                  Text('— —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        );

      case 'dog':
        return Positioned(
          top: 116,
          child: Container(
            width: 76,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E2723),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Container(
                    width: 6,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: true)),
                        CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: false)),
                      ],
                    ),
                    Positioned(
                      top: 4,
                      child: Container(
                        width: 14,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4081),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case 'bear':
        return Positioned(
          top: 116,
          child: Container(
            width: 74,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E),
                    borderRadius: BorderRadius.circular(7.5),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: true)),
                    CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: false)),
                  ],
                ),
              ],
            ),
          ),
        );

      case 'lion':
      case 'tiger':
        return Positioned(
          top: 116,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: true)),
                  CustomPaint(size: Size(16, 10), painter: _BunnySmileArcPainter(isLeft: false)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('— —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(width: 18),
                  Text('— —', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        );

      case 'croco':
        return Positioned(
          top: 124,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                    const SizedBox(width: 24),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );

      case 'hippo':
        return Positioned(
          top: 116,
          child: Container(
            width: 88,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFCE93D8),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
                    const SizedBox(width: 28),
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── Character Body & Dental Pajama Bib with Paws ───────────────────────────

  Widget _buildCharacterBodyAndPaws(bool isShining) {
    final primaryColor = _animal.primaryColor;
    final faceColor = _animal.faceColor;

    return Positioned(
      top: 212,
      child: SizedBox(
        width: 260,
        height: 90,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 220,
              height: 85,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE0F2F1),
                    Color(0xFFB2DFDB),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(55),
                  bottom: Radius.circular(20),
                ),
                border: Border.all(color: const Color(0xFF80CBC4), width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 25,
                    left: 30,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    top: 45,
                    left: 60,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    top: 28,
                    right: 35,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    top: 48,
                    right: 65,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), shape: BoxShape.circle)),
                  ),
                  Positioned(
                    top: 2,
                    child: Container(
                      width: 104,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('🦷', style: TextStyle(fontSize: 18)),
                          SizedBox(width: 2),
                          Text('✨', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              top: 24,
              child: _buildCutePaw(faceColor, primaryColor, isLeft: true),
            ),
            Positioned(
              right: 20,
              top: 24,
              child: _buildCutePaw(faceColor, primaryColor, isLeft: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCutePaw(Color faceColor, Color primaryColor, {required bool isLeft}) {
    return Transform.rotate(
      angle: isLeft ? 0.35 : -0.35,
      child: Container(
        width: 44,
        height: 38,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.45), shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.45), shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Container(width: 7, height: 7, decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.45), shape: BoxShape.circle)),
                ],
              ),
            ),
            Positioned(
              bottom: 5,
              child: Container(
                width: 14,
                height: 11,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. Back Features (Mane, Ears, Spikes) ──────────────────────────────────

  Widget _buildBackFeatures(bool isShining) {
    switch (_animal.id) {
      case 'lion':
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ...List.generate(12, (i) {
              final angle = i * (2 * pi / 12);
              return Positioned(
                left: 140 + cos(angle) * 105 - 28,
                top: 140 + sin(angle) * 105 - 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            Positioned(top: 32, left: 55, child: _buildCuteRoundEar(const Color(0xFFFFB74D), const Color(0xFFFFF3E0))),
            Positioned(top: 32, right: 55, child: _buildCuteRoundEar(const Color(0xFFFFB74D), const Color(0xFFFFF3E0))),
          ],
        );

      case 'rabbit':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 8,
              left: 60,
              child: Transform.rotate(
                angle: -0.1,
                child: Container(
                  width: 44,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF06292), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 60,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 44,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF06292), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'croco':
        return Positioned(
          top: 32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 16,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              );
            }),
          ),
        );

      case 'tiger':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 26, left: 45, child: _buildCuteRoundEar(const Color(0xFFFB8C00), const Color(0xFFFFF8E1), isTiger: true)),
            Positioned(top: 26, right: 45, child: _buildCuteRoundEar(const Color(0xFFFB8C00), const Color(0xFFFFF8E1), isTiger: true)),
          ],
        );

      case 'bear':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 28, left: 42, child: _buildCuteRoundEar(const Color(0xFF8D6E63), const Color(0xFFD7CCC8))),
            Positioned(top: 28, right: 42, child: _buildCuteRoundEar(const Color(0xFF8D6E63), const Color(0xFFD7CCC8))),
          ],
        );

      case 'hippo':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 35, left: 52, child: _buildCuteRoundEar(const Color(0xFFAB47BC), const Color(0xFFF8BBD0), size: 36)),
            Positioned(top: 35, right: 52, child: _buildCuteRoundEar(const Color(0xFFAB47BC), const Color(0xFFF8BBD0), size: 36)),
          ],
        );

      case 'dog':
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 22,
              left: 44,
              child: Transform.rotate(
                angle: -0.25,
                child: Container(
                  width: 52,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE082),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              right: 44,
              child: Transform.rotate(
                angle: 0.25,
                child: Container(
                  width: 52,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(35),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 28,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE082),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(22),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCuteRoundEar(Color outerColor, Color innerColor, {double size = 48, bool isTiger = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.52,
        height: size * 0.52,
        decoration: BoxDecoration(color: innerColor, shape: BoxShape.circle),
      ),
    );
  }

  // ── 2. Head & Face Body ───────────────────────────────────────────────────

  Widget _buildHeadAndFaceBody(bool isShining) {
    final faceColor = _animal.faceColor;
    final primaryColor = _animal.primaryColor;

    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_animal.id == 'bear' || _animal.id == 'rabbit' || _animal.id == 'tiger' || _animal.id == 'dog') ...[
            Positioned(
              left: 4,
              top: 105,
              child: Container(
                width: 32,
                height: 38,
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 105,
              child: Container(
                width: 32,
                height: 38,
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
          Container(
            width: 220,
            height: 220,
            margin: const EdgeInsets.only(top: 40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.25, -0.35),
                radius: 0.88,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  faceColor,
                  primaryColor.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(color: primaryColor, width: 4.5),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 28,
                  child: Container(
                    width: 75,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. Cute Happy Open Mouth (Deep 3D Oral Cavity + Pink Gums) ────────────

  Widget _buildCuteOpenMouth({double chewY = 0.0}) {
    final mouthH = 90.0 + chewY;
    final mouthTop = 134.0 - (chewY * 0.3);

    return Positioned(
      top: mouthTop,
      child: Container(
        width: 168.0 + (chewY * 0.35),
        height: mouthH,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3E000F),
              Color(0xFF880E4F),
            ],
          ),
          borderRadius: BorderRadius.circular(44 + (chewY * 0.2)),
          border: Border.all(color: const Color(0xFFFF4081), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              left: 12,
              right: 12,
              child: Container(
                height: 12,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 12,
              right: 12,
              child: Container(
                height: 12,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF4081), Color(0xFFFF80AB)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ),
            ),
            Positioned(
              bottom: 1,
              child: Container(
                width: 86.0 + (chewY * 0.4),
                height: 36.0 + (chewY * 0.3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: const Color(0xFFC2185B), width: 1.5),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Teeth Items (Chunky, Puffy, Cute Baby Teeth) ───────────────────────

  Widget _buildSingleTooth(_ToothState tooth, bool showDirty, bool isShining, {double chewY = 0.0}) {
    const canvasW = 280.0;
    const canvasH = 280.0;

    final leftPos = tooth.xRatio * canvasW;
    final topPos = tooth.isTop ? (tooth.yRatio * canvasH) : ((tooth.yRatio * canvasH) + (chewY * 0.7));

    final cleanRatio = showDirty ? tooth.cleanliness : 1.0;
    final dirtyRatio = 1.0 - cleanRatio;

    final isRabbitBuck = _animal.id == 'rabbit' && tooth.isTop && (tooth.index == 1 || tooth.index == 2);
    final toothW = isRabbitBuck ? (tooth.width + 2.0) : tooth.width;
    final toothH = isRabbitBuck ? (tooth.height + 4.0) : tooth.height;

    final isPoked = _pokedToothIndex == tooth.index;

    return Positioned(
      left: leftPos - (toothW / 2),
      top: topPos - (toothH / 2),
      child: GestureDetector(
        onTap: () => _onPokeTooth(tooth.index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isPoked ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: toothW,
                height: toothH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isShining
                        ? [const Color(0xFFFFFDE7), const Color(0xFFFFE082)]
                        : (dirtyRatio > 0.05
                            ? [Colors.white, const Color(0xFFD7CCC8)]
                            : [Colors.white, const Color(0xFFECEFF1)]),
                  ),
                  borderRadius: BorderRadius.circular(isRabbitBuck ? 8 : 11),
                  border: Border.all(
                    color: isShining
                        ? Colors.amber
                        : (dirtyRatio > 0.05 ? const Color(0xFF8D6E63) : const Color(0xFFCFD8DC)),
                    width: isShining ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isShining ? Colors.amber.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.12),
                      blurRadius: isShining ? 8 : 2.5,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 3.5,
                      top: 3.0,
                      child: Container(
                        width: 7.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: dirtyRatio > 0.4 ? 0.2 : 0.85),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),
                    if (dirtyRatio > 0.05)
                      Center(
                        child: Container(
                          width: toothW * 0.72 * dirtyRatio,
                          height: toothH * 0.72 * dirtyRatio,
                          decoration: BoxDecoration(
                            color: tooth.stainColor.withValues(alpha: 0.85 * dirtyRatio),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    if (isShining)
                      const Center(child: Text('✨', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),
            if (showDirty && tooth.hasMonster && dirtyRatio > 0.3)
              Positioned(
                top: tooth.isTop ? (isPoked ? -20 : -12) : null,
                bottom: tooth.isTop ? null : (isPoked ? -20 : -12),
                child: AnimatedBuilder(
                  animation: _ambientBubbleCtrl,
                  builder: (context, child) {
                    final wiggle = sin((_ambientBubbleCtrl.value * pi * 6) + tooth.index) * 0.18;
                    final breathe = sin((_ambientBubbleCtrl.value * pi * 4) + (tooth.index * 1.5)) * 0.1;
                    return Transform.rotate(
                      angle: isPoked ? 0.3 : wiggle,
                      child: Transform.scale(
                        scale: (isPoked ? 1.45 : 1.0) + breathe,
                        child: child,
                      ),
                    );
                  },
                  child: _CavityMonsterWidget(
                    toothIndex: tooth.index,
                    isPoked: isPoked,
                    dirtyRatio: dirtyRatio,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 5. Cute Muzzle / Nose / Whiskers ──────────────────────────────────────

  Widget _buildCuteMuzzle() {
    switch (_animal.id) {
      case 'lion':
      case 'tiger':
        return Positioned(
          top: 116,
          child: Column(
            children: [
              Container(
                width: 26,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('— —', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(width: 16),
                  Text('— —', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
        );

      case 'rabbit':
        return Positioned(
          top: 120,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        );

      case 'croco':
        return Positioned(
          top: 124,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                const SizedBox(width: 20),
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
              ],
            ),
          ),
        );

      case 'bear':
        return Positioned(
          top: 115,
          child: Container(
            width: 58,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: 22,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        );

      case 'hippo':
        return Positioned(
          top: 114,
          child: Container(
            width: 78,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFCE93D8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
              ],
            ),
          ),
        );

      case 'dog':
        return Positioned(
          top: 112,
          child: Container(
            width: 68,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1.5)),
              ],
            ),
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              width: 24,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── 6. Sparkling Cute Expressive Eyes & Cheeks ────────────────────────────

  Widget _buildCuteEyesAndCheeks(bool isShining) {
    final isBlinking = _blinkCtrl.value > 0.93;
    final isToothache = _hasDecayed && (_step == BrushStep.selectPaste || (_step == BrushStep.eating && _customDialogue != null));
    final isJoyful = _step == BrushStep.brushing || _isEating;
    final isRinsing = _step == BrushStep.rinsing;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        if (_animal.id == 'tiger')
          Positioned(
            top: 55,
            child: Column(
              children: [
                Container(width: 32, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 3),
                Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),

        if (isToothache) ...[
          Positioned(
            top: 68,
            left: 66,
            child: Transform.rotate(
              angle: 0.28,
              child: Container(width: 22, height: 4, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2))),
            ),
          ),
          Positioned(
            top: 68,
            right: 66,
            child: Transform.rotate(
              angle: -0.28,
              child: Container(width: 22, height: 4, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(2))),
            ),
          ),
        ],

        Positioned(
          top: 76,
          left: 68,
          child: _buildExpressiveEye(
            isShining: isShining,
            isBlinking: isBlinking,
            isToothache: isToothache,
            isJoyful: isJoyful,
            isLeft: true,
          ),
        ),

        Positioned(
          top: 76,
          right: 68,
          child: _buildExpressiveEye(
            isShining: isShining,
            isBlinking: isBlinking,
            isToothache: isToothache,
            isJoyful: isJoyful,
            isLeft: false,
          ),
        ),

        if (isToothache)
          Positioned(
            top: 112,
            right: 52,
            child: Container(
              width: 10,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF4FC3F7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
            ),
          ),

        _buildDynamicCheeks(isRinsing: isRinsing, isJoyful: isJoyful || isShining),
      ],
    );
  }

  Widget _buildDynamicCheeks({required bool isRinsing, required bool isJoyful}) {
    final swish = isRinsing ? (sin(_swishCtrl.value * pi) * 6.0) : 0.0;
    final cheekW = 28.0 + (isRinsing ? 8.0 : 0.0);
    final cheekH = 18.0 + (isRinsing ? 6.0 : 0.0);

    return Positioned(
      top: 128,
      child: SizedBox(
        width: 220,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: (cheekW + swish).clamp(16.0, 44.0),
              height: cheekH,
              decoration: BoxDecoration(
                color: (isJoyful ? const Color(0xFFFF4081) : Colors.pinkAccent).withValues(alpha: isJoyful ? 0.55 : 0.4),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isJoyful
                    ? [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.3), blurRadius: 6)]
                    : null,
              ),
            ),
            Container(
              width: (cheekW - swish).clamp(16.0, 44.0),
              height: cheekH,
              decoration: BoxDecoration(
                color: (isJoyful ? const Color(0xFFFF4081) : Colors.pinkAccent).withValues(alpha: isJoyful ? 0.55 : 0.4),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isJoyful
                    ? [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.3), blurRadius: 6)]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressiveEye({
    required bool isShining,
    required bool isBlinking,
    required bool isToothache,
    required bool isJoyful,
    required bool isLeft,
  }) {
    if (isShining) {
      return Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 32),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ],
        ),
      );
    }

    if (isJoyful) {
      return Container(
        width: 28,
        height: 16,
        margin: const EdgeInsets.only(top: 8),
        child: CustomPaint(
          painter: _HappyArcEyePainter(),
        ),
      );
    }

    if (isBlinking) {
      return Container(
        width: 26,
        height: 4,
        margin: const EdgeInsets.only(top: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    if (isToothache) {
      return Container(
        width: 26,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFF263238),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF37474F), width: 1.5),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 2,
              left: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 5,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 26,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            left: 5,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _HappyArcEyePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(2, size.height - 2)
      ..quadraticBezierTo(size.width / 2, 0, size.width - 2, size.height - 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// BESPOKE 3D ILLUSTRATED KIDS TOOTHBRUSH WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _BespokeToothbrushWidget extends StatelessWidget {
  final Color pasteColor;
  final double wiggleProgress;

  const _BespokeToothbrushWidget({
    required this.pasteColor,
    required this.wiggleProgress,
  });

  @override
  Widget build(BuildContext context) {
    final wiggleAngle = sin(wiggleProgress * pi * 2) * 0.22;
    return Transform.rotate(
      angle: -0.32 + wiggleAngle,
      child: SizedBox(
        width: 80,
        height: 140,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              child: Container(
                width: 32,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
                  boxShadow: [
                    BoxShadow(color: pasteColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (i) {
                        return Container(
                          width: 20,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i % 2 == 0 ? pasteColor : const Color(0xFF81D4FA),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                    Positioned(
                      top: 4,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: pasteColor.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              child: Container(
                width: 14,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              top: 60,
              child: Container(
                width: 24,
                height: 75,
                decoration: BoxDecoration(
                  color: pasteColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Positioned(
              top: -8,
              right: -6,
              child: Text('🫧', style: TextStyle(fontSize: 18)),
            ),
            const Positioned(
              top: -4,
              left: -8,
              child: Text('✨', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED CAVITY MONSTER WIDGET (충치 세균맨)
// ═══════════════════════════════════════════════════════════════════════════════

class _CavityMonsterWidget extends StatelessWidget {
  final int toothIndex;
  final bool isPoked;
  final double dirtyRatio;

  const _CavityMonsterWidget({
    required this.toothIndex,
    required this.isPoked,
    required this.dirtyRatio,
  });

  @override
  Widget build(BuildContext context) {
    final isPurple = toothIndex % 2 == 0;
    final bodyColor1 = isPurple ? const Color(0xFF8E24AA) : const Color(0xFF43A047);
    final bodyColor2 = isPurple ? const Color(0xFF5E35B1) : const Color(0xFF1B5E20);
    final isDizzy = dirtyRatio < 0.6;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -4,
            top: 6,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 9,
                height: 11,
                decoration: BoxDecoration(
                  color: bodyColor2.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: 6,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 9,
                height: 11,
                decoration: BoxDecoration(
                  color: bodyColor2.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                radius: 0.8,
                colors: [
                  isPurple ? const Color(0xFFBA68C8) : const Color(0xFF81C784),
                  bodyColor1,
                  bodyColor2,
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: bodyColor2.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -2,
                  left: 4,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: bodyColor2,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: 4,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: bodyColor2,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMonsterEye(isDizzy: isDizzy, isPoked: isPoked),
                      const SizedBox(width: 2),
                      _buildMonsterEye(isDizzy: isDizzy, isPoked: isPoked),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 3.5,
                  child: isDizzy
                      ? Container(
                          width: 8,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF212121),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 2.5, height: 3, color: Colors.white),
                            const SizedBox(width: 1),
                            Container(width: 2.5, height: 3, color: Colors.white),
                          ],
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -6,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.4,
              child: const SizedBox(
                width: 10,
                height: 16,
                child: CustomPaint(painter: _TridentPainter()),
              ),
            ),
          ),
          if (isDizzy)
            const Positioned(
              top: -6,
              right: -3,
              child: Text('💦', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildMonsterEye({required bool isDizzy, required bool isPoked}) {
    if (isDizzy) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('@', style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, height: 0.9, color: Color(0xFF311B92))),
      );
    }
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFF1A237E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
