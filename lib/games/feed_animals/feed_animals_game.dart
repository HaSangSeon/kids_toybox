import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

class FeedAnimalsGame extends StatefulWidget {
  const FeedAnimalsGame({super.key});

  @override
  State<FeedAnimalsGame> createState() => _FeedAnimalsGameState();
}

class AnimalMatch {
  final String animal;
  final String food;
  final String animalName;
  bool isFed = false;

  AnimalMatch(this.animal, this.food, this.animalName);
}

class _FeedAnimalsGameState extends State<FeedAnimalsGame>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  List<AnimalMatch> _matches = [];
  List<String> _foodsToFeed = [];

  // 12종 다양한 동물 풀 — 매 라운드 3마리 랜덤 선택
  final List<AnimalMatch> _allPossibleMatches = [
    AnimalMatch('🐶', '🦴', 'dog'),       // 강아지 → 뼈다귀
    AnimalMatch('🐱', '🐟', 'cat'),       // 고양이 → 물고기
    AnimalMatch('🐰', '🥕', 'rabbit'),    // 토끼 → 당근
    AnimalMatch('🐻', '🍯', 'bear'),      // 곰 → 꿀
    AnimalMatch('🐒', '🍌', 'monkey'),    // 원숭이 → 바나나
    AnimalMatch('🐼', '🎋', 'panda'),     // 판다 → 대나무
    AnimalMatch('🦊', '🍎', 'fox'),       // 여우 → 사과
    AnimalMatch('🦁', '🥩', 'lion'),      // 사자 → 고기
    AnimalMatch('🐘', '🥜', 'elephant'),  // 코끼리 → 땅콩
    AnimalMatch('🐸', '🐛', 'frog'),      // 개구리 → 벌레
    AnimalMatch('🦜', '🌽', 'parrot'),    // 앵무새 → 옥수수
    AnimalMatch('🐧', '🦐', 'penguin'),   // 펭귄 → 새우
  ];

  // 직전 라운드에 나온 동물 추적 (반복 방지)
  Set<String> _lastRoundAnimals = {};

  int _score = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _startRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _startRound() {
    // 직전 라운드 동물을 제외하고 우선 선택 → 반복 최소화
    final preferred = _allPossibleMatches
        .where((m) => !_lastRoundAnimals.contains(m.animal))
        .toList();
    final pool = preferred.length >= 3 ? preferred : _allPossibleMatches;
    pool.shuffle();
    _matches = pool
        .take(3)
        .map((m) => AnimalMatch(m.animal, m.food, m.animalName))
        .toList();
    _lastRoundAnimals = _matches.map((m) => m.animal).toSet();
    _foodsToFeed = _matches.map((m) => m.food).toList()..shuffle();
    setState(() {});
  }

  void _onFoodDropped(String food, AnimalMatch match) {
    if (match.food == food && !match.isFed) {
      // playEmojiSound 는 내부적으로 올바른 경로('audio/jigsaw_sound_XXX.wav')를
      // 직접 사용하므로 경로 조작 없이 그대로 호출
      AudioManager.instance.playEmojiSound(match.animal).then((_) {
        // 해당 이모지 매핑이 없는 동물은 munch 소리로 대체
      });
      // 매핑 없는 동물(곰·사자·코끼리 등)은 추가로 munch
      const noSoundAnimals = {'🐒', '🐼', '🦊', '🦁', '🐘', '🐸', '🦜', '🐧'};
      if (noSoundAnimals.contains(match.animal)) {
        AudioManager.instance.playMunch();
      }
      HapticFeedback.lightImpact();
      setState(() {
        match.isFed = true;
        _foodsToFeed.remove(food);
        _score += 10;

        if (_foodsToFeed.isEmpty) {
          _confettiController.play();
          Future.delayed(const Duration(milliseconds: 400), () {
            AudioManager.instance.playSuccess();
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) _startRound();
          });
        }
      });
    } else if (!match.isFed) {
      AudioManager.instance.playDamage();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Nature Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _NatureBackgroundPainter(_floatAnimation.value),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),
                _buildInstructionBanner(),
                const Spacer(flex: 1),
                _buildAnimalsRow(),
                const Spacer(flex: 2),
                _buildFoodTray(),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              colors: const [
                Color(0xFFFF6B6B),
                Color(0xFF4ECDC4),
                Color(0xFFFFE66D),
                Color(0xFF95E1D3),
                Color(0xFFF38181),
                Color(0xFF6BCB77),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFCC4444),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          // Score badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE66D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KidsTheme.borderDark, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFCCB030),
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: GoogleFonts.jua(
                    fontSize: 22,
                    color: KidsTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Sound toggle
          GestureDetector(
            onTap: () {
              setState(() => AudioManager.instance.toggleSound());
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF95E1D3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF5BB5A8),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                AudioManager.instance.soundEnabled
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidsTheme.borderDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '알맞은 맘마를 드래그해서 줘요!',
            style: GoogleFonts.jua(
              fontSize: 18,
              color: KidsTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _matches.map((match) => _buildAnimalTarget(match)).toList(),
    );
  }

  Widget _buildAnimalTarget(AnimalMatch match) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !match.isFed,
      onAcceptWithDetails: (details) => _onFoodDropped(details.data, match),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.elasticOut,
          transform: Matrix4.identity()
            ..scale(isHovering ? 1.15 : 1.0)
            ..translate(0.0, isHovering ? -8.0 : 0.0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 105,
                height: 125,
                decoration: BoxDecoration(
                  color: match.isFed
                      ? const Color(0xFFE8FFE8)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: match.isFed
                        ? const Color(0xFF4CAF50)
                        : isHovering
                            ? KidsTheme.green
                            : KidsTheme.borderDark,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: match.isFed
                          ? const Color(0xFF4CAF50)
                          : isHovering
                              ? KidsTheme.green
                              : KidsTheme.borderDark,
                      offset: const Offset(0, 5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    match.animal,
                    style: const TextStyle(fontSize: 62),
                  ),
                ),
              ),
              if (match.isFed)
                Positioned(
                  top: -22,
                  child: AnimatedScale(
                    scale: match.isFed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    child: const Text(
                      '❤️',
                      style: TextStyle(fontSize: 36),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFoodTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: KidsTheme.borderDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF5A3A1A),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA0714F), Color(0xFF7A4F2D)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '🍱  맘마 쟁반',
              style: GoogleFonts.jua(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: _foodsToFeed.isEmpty
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceEvenly,
            children: _foodsToFeed.isEmpty
                ? [
                    Text(
                      '🎉 다 줬어요!',
                      style: GoogleFonts.jua(
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                  ]
                : _foodsToFeed
                    .map((food) => _buildDraggableFood(food))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableFood(String food) {
    return Draggable<String>(
      data: food,
      feedback: Transform.scale(
        scale: 1.3,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            food,
            style: const TextStyle(
                fontSize: 52, decoration: TextDecoration.none),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Text(food, style: const TextStyle(fontSize: 52)),
        ),
      ),
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * 0.4),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(food, style: const TextStyle(fontSize: 52)),
        ),
      ),
    );
  }
}

class _NatureBackgroundPainter extends CustomPainter {
  final double floatOffset;

  _NatureBackgroundPainter(this.floatOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB8E4FF),
          Color(0xFFD4F0C0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    _drawSun(canvas, Offset(w * 0.85, h * 0.10), floatOffset);

    _drawCloud(canvas, Offset(w * 0.15, h * 0.07 + floatOffset * 0.4), 0.85);
    _drawCloud(canvas, Offset(w * 0.55, h * 0.04 + floatOffset * 0.25), 1.1);
    _drawCloud(canvas, Offset(w * 0.75, h * 0.12 + floatOffset * 0.3), 0.7);

    _drawHill(canvas, size,
        yCenter: h * 0.65, width: w * 1.3, color: const Color(0xFF8BC34A));
    _drawHill(canvas, size,
        xOffset: w * 0.3,
        yCenter: h * 0.70,
        width: w * 1.1,
        color: const Color(0xFF7CB342));

    final groundPaint = Paint()..color = const Color(0xFF558B2F);
    final groundPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.76, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    final grassPaint = Paint()..color = const Color(0xFF66BB6A);
    final grassPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.76, w, h * 0.72)
      ..lineTo(w, h * 0.77)
      ..quadraticBezierTo(w * 0.75, h * 0.81, w * 0.5, h * 0.77)
      ..quadraticBezierTo(w * 0.25, h * 0.73, 0, h * 0.77)
      ..close();
    canvas.drawPath(grassPath, grassPaint);

    _drawTree(canvas, Offset(w * 0.05, h * 0.70));
    _drawTree(canvas, Offset(w * 0.93, h * 0.69));
    _drawTree(canvas, Offset(w * 0.18, h * 0.73), scale: 0.75);
    _drawTree(canvas, Offset(w * 0.82, h * 0.72), scale: 0.8);

    final flowers = [
      Offset(w * 0.12, h * 0.78),
      Offset(w * 0.28, h * 0.82),
      Offset(w * 0.45, h * 0.80),
      Offset(w * 0.60, h * 0.83),
      Offset(w * 0.75, h * 0.79),
      Offset(w * 0.88, h * 0.81),
    ];
    final flowerColors = [
      const Color(0xFFFFEB3B),
      const Color(0xFFFF80AB),
      const Color(0xFF80DEEA),
      const Color(0xFFFFA726),
      const Color(0xFFCE93D8),
      const Color(0xFF80CBC4),
    ];
    for (int i = 0; i < flowers.length; i++) {
      _drawFlower(
        canvas,
        flowers[i].translate(0, floatOffset * (i.isEven ? 0.3 : -0.2)),
        flowerColors[i % flowerColors.length],
      );
    }

    _drawMushroom(canvas, Offset(w * 0.35, h * 0.75));
    _drawMushroom(canvas, Offset(w * 0.68, h * 0.77), small: true);
  }

  void _drawSun(Canvas canvas, Offset center, double pulse) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + pulse * 0.02;
      final start =
          Offset(center.dx + cos(angle) * 22, center.dy + sin(angle) * 22);
      final end =
          Offset(center.dx + cos(angle) * 38, center.dy + sin(angle) * 38);
      canvas.drawLine(start, end, rayPaint);
    }
    canvas.drawCircle(center, 20, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(
        center.translate(-5, -5), 8, Paint()..color = const Color(0xFFFFF9C4));
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withOpacity(0.92);
    final radii = [22.0, 16.0, 18.0, 14.0];
    final offsets = [
      Offset.zero,
      const Offset(-28, 8),
      const Offset(26, 6),
      const Offset(-50, 14),
    ];
    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(
          center + offsets[i] * scale, radii[i] * scale, paint);
    }
  }

  void _drawHill(Canvas canvas, Size size,
      {double xOffset = 0,
      required double yCenter,
      required double width,
      required Color color}) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(xOffset, size.height)
      ..quadraticBezierTo(xOffset + width / 2, yCenter - width * 0.25,
          xOffset + width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTree(Canvas canvas, Offset base, {double scale = 1.0}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: base.translate(0, -20 * scale),
            width: 12 * scale,
            height: 40 * scale),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(
        base.translate(0, -55 * scale), 28 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(-10 * scale, -45 * scale), 20 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(10 * scale, -45 * scale), 22 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(0, -65 * scale), 18 * scale, Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawFlower(Canvas canvas, Offset center, Color color) {
    final petalPaint = Paint()..color = color;
    final centerPaint = Paint()..color = const Color(0xFFFFEB3B);
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawCircle(
          center + Offset(cos(angle) * 7, sin(angle) * 7), 5, petalPaint);
    }
    canvas.drawCircle(center, 5, centerPaint);
    canvas.drawLine(center, center.translate(0, 12),
        Paint()
          ..color = const Color(0xFF66BB6A)
          ..strokeWidth = 2);
  }

  void _drawMushroom(Canvas canvas, Offset base, {bool small = false}) {
    final s = small ? 0.7 : 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: base.translate(0, -8 * s),
            width: 14 * s,
            height: 16 * s),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    final capPath = Path()
      ..moveTo(base.dx - 18 * s, base.dy - 14 * s)
      ..quadraticBezierTo(
          base.dx, base.dy - 36 * s, base.dx + 18 * s, base.dy - 14 * s)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFFE53935));
    final spotPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(base.translate(-5 * s, -22 * s), 3.5 * s, spotPaint);
    canvas.drawCircle(base.translate(5 * s, -25 * s), 2.5 * s, spotPaint);
    canvas.drawCircle(base.translate(0, -19 * s), 2 * s, spotPaint);
  }

  @override
  bool shouldRepaint(_NatureBackgroundPainter old) =>
      old.floatOffset != floatOffset;
}
