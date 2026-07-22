import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

class FruitSlicerGame extends StatefulWidget {
  const FruitSlicerGame({super.key});

  @override
  State<FruitSlicerGame> createState() => _FruitSlicerGameState();
}

enum FruitType { normal, golden, bomb, freeze, heart, giant }

class Fruit {
  final int id;
  final String emoji;
  final FruitType type;
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double angle;
  double vAngle;
  bool isSliced = false;
  int hp;
  final int maxHp;
  double hitCooldown = 0;

  Fruit({
    required this.id,
    required this.emoji,
    required this.type,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.angle,
    required this.vAngle,
    this.hp = 1,
    this.maxHp = 1,
  });
}

class JuiceParticle {
  double x, y;
  double vx, vy;
  Color color;
  double life = 1.0;
  final double size;
  final bool isSparkle;

  JuiceParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.isSparkle = false,
  });
}

class SlicedFruit {
  final String emoji;
  double x, y;
  double vx, vy;
  double size;
  double angle;
  double vAngle;
  final bool isLeft;
  final bool isGolden;

  SlicedFruit({
    required this.emoji,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.angle,
    required this.vAngle,
    required this.isLeft,
    required this.isGolden,
  });
}

class FloatingText {
  double x, y;
  String text;
  Color color;
  double size;
  double life = 1.0;

  FloatingText({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.size,
  });
}

class _FruitSlicerGameState extends State<FruitSlicerGame> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  final List<String> _fruitPool = ['🍉', '🍎', '🍌', '🍇', '🍓', '🥝', '🥭', '🍍'];
  final Map<String, Color> _fruitColors = {
    '🍉': Colors.red,
    '🍎': Colors.redAccent,
    '🍌': Colors.yellow,
    '🍇': Colors.purple,
    '🍓': Colors.red,
    '🥝': Colors.green,
    '🥭': Colors.orange,
    '🍍': Colors.yellowAccent,
  };

  List<Fruit> _fruits = [];
  List<JuiceParticle> _particles = [];
  List<SlicedFruit> _slicedPieces = [];
  List<FloatingText> _floatingTexts = [];
  List<Offset> _bladeTrail = [];

  int _score = 0;
  int _lives = 3;
  int _fruitIdCounter = 0;
  double _spawnTimer = 0;
  Duration _lastElapsed = Duration.zero;
  bool _isGameOver = false;
  int _currentStrokeSlices = 0; // For Combo tracking
  double _freezeTimer = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_isGameOver) return;
    
    final double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
    _lastElapsed = elapsed;
    final deltaTime = dt.clamp(0.0, 0.05);

    setState(() {
      if (_freezeTimer > 0) {
        _freezeTimer -= deltaTime;
        if (_freezeTimer < 0) _freezeTimer = 0;
      }

      final double slowFactor = _freezeTimer > 0 ? 0.35 : 1.0;
      final double movementDelta = deltaTime * slowFactor;

      _spawnTimer += deltaTime;
      final double currentSpawnInterval = (2.2 - (_score / 150) * 0.3).clamp(1.3, 2.2);
      if (_spawnTimer > currentSpawnInterval) {
        _spawnTimer = 0;
        _spawnFruit();
      }

      // Update Fruits (중력 대폭 낮춰서 공중에 오래 머물도록 설정)
      for (var fruit in _fruits) {
        if (fruit.hitCooldown > 0) {
          fruit.hitCooldown -= deltaTime;
        }
        fruit.x += fruit.vx * movementDelta;
        fruit.y += fruit.vy * movementDelta;
        fruit.vy += 0.75 * movementDelta;
        fruit.angle += fruit.vAngle * movementDelta;
      }

      _fruits.removeWhere((f) {
        if (f.y > 1.2 && !f.isSliced) {
          if (f.type == FruitType.normal || f.type == FruitType.giant) {
            _loseLife();
          }
          return true;
        }
        return f.isSliced;
      });

      // Update Sliced Pieces (잘린 조각 중력도 하향)
      for (var piece in _slicedPieces) {
        piece.x += piece.vx * movementDelta;
        piece.y += piece.vy * movementDelta;
        piece.vy += 1.0 * movementDelta;
        piece.angle += piece.vAngle * movementDelta;
      }
      _slicedPieces.removeWhere((p) => p.y > 1.3);

      // Update Particles
      for (var p in _particles) {
        p.x += p.vx * deltaTime;
        p.y += p.vy * deltaTime;
        p.vy += 1.2 * deltaTime;
        p.life -= deltaTime * 1.5;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // Update Floating Texts
      for (var text in _floatingTexts) {
        text.y -= 0.2 * deltaTime; // Float up
        text.life -= deltaTime * 1.0;
      }
      _floatingTexts.removeWhere((t) => t.life <= 0);

      // Blade Trail Fade
      if (_bladeTrail.isNotEmpty) {
        if (_bladeTrail.length > 8) {
          _bladeTrail.removeAt(0);
        }
      }
    });
  }

  void _spawnFruit() {
    // 점수가 낮을 때는 웨이브 발생 확률과 개수를 줄여서 아이들이 다치지 않게 조절
    final double waveChance = (0.10 + (_score / 300) * 0.15).clamp(0.10, 0.25);
    if (_random.nextDouble() < waveChance) {
      int waveCount = _score < 100 ? 2 : (2 + _random.nextInt(2)); // 초반엔 2개, 이후 2~3개
      double commonVy = -1.1 - _random.nextDouble() * 0.15; // 낮아진 발사 속도
      
      for (int i = 0; i < waveCount; i++) {
        double xPos = 0.2 + (0.6 * (i / (waveCount - 1)));
        _spawnSingleFruit(overrideX: xPos, overrideVy: commonVy, overrideVx: (_random.nextDouble() - 0.5) * 0.08);
      }
    } else {
      _spawnSingleFruit();
    }
  }

  void _spawnSingleFruit({double? overrideX, double? overrideVy, double? overrideVx}) {
    // 폭탄 등장 확률도 점수에 따라 점진적으로 증가 (초반엔 5%로 아주 낮음)
    final double bombChance = (0.05 + (_score / 400) * 0.07).clamp(0.05, 0.12);
    final double rand = _random.nextDouble();

    FruitType type = FruitType.normal;
    String emoji = '';

    if (rand < bombChance) {
      type = FruitType.bomb;
      emoji = '💣';
    } else if (rand < bombChance + 0.06 && _lives < 3) {
      type = FruitType.heart;
      emoji = '❤️';
    } else if (rand < bombChance + (_lives < 3 ? 0.11 : 0.05)) {
      type = FruitType.freeze;
      emoji = '❄️';
    } else if (rand < bombChance + (_lives < 3 ? 0.18 : 0.12)) {
      type = FruitType.giant;
      emoji = '🍉'; // Giant melon
    } else if (rand < bombChance + (_lives < 3 ? 0.28 : 0.22)) {
      type = FruitType.golden;
      emoji = '🌟';
    } else {
      type = FruitType.normal;
      emoji = _fruitPool[_random.nextInt(_fruitPool.length)];
    }

    double finalSize = 60 + _random.nextDouble() * 20;
    if (type == FruitType.giant) {
      finalSize = 135.0; // Giant size!
    } else if (type == FruitType.bomb) {
      finalSize = 65.0;
    } else if (type == FruitType.heart || type == FruitType.freeze) {
      finalSize = 55.0; // Slightly smaller and cute
    }

    int fruitHp = (type == FruitType.giant) ? 3 : 1;

    _fruits.add(Fruit(
      id: _fruitIdCounter++,
      emoji: emoji,
      type: type,
      x: overrideX ?? (0.15 + _random.nextDouble() * 0.7),
      y: 1.05,
      vx: overrideVx ?? ((_random.nextDouble() - 0.5) * 0.20), // 가로 이동 속도 하향 (화면 밖 튕김 방지)
      vy: overrideVy ?? (-1.1 - _random.nextDouble() * 0.25), // 느긋하게 솟구침
      size: finalSize,
      angle: 0,
      vAngle: (_random.nextDouble() - 0.5) * 3.0,
      hp: fruitHp,
      maxHp: fruitHp,
    ));
  }

  void _loseLife() {
    if (_isGameOver) return;
    _lives--;
    AudioManager.instance.playDamage();
    HapticFeedback.heavyImpact();

    // 화면 진동 효과를 위해 추가 이펙트를 줄 수도 있음
    if (_lives <= 0) {
      _isGameOver = true;
      AudioManager.instance.playGameOver();
    }
  }

  void _sliceFruit(Fruit fruit) {
    if (fruit.isSliced) return;
    
    // 다단 베기(Multi-hit) 지원: HP가 남아있는 경우 1만 차감하고 파티클/텍스트 출력
    if (fruit.hp > 1) {
      fruit.hp--;
      fruit.hitCooldown = 0.12; // 연속 베기 쿨타임
      fruit.size *= 0.92; // 살짝 축소
      _score += 5;
      AudioManager.instance.playPop();
      HapticFeedback.mediumImpact();

      _floatingTexts.add(FloatingText(
        x: fruit.x, y: fruit.y,
        text: '탁! (${fruit.hp}번 남음)',
        color: Colors.redAccent,
        size: 26,
      ));

      for (int i = 0; i < 15; i++) {
        _particles.add(JuiceParticle(
          x: fruit.x, y: fruit.y,
          vx: (_random.nextDouble() - 0.5) * 2.0,
          vy: (_random.nextDouble() - 0.5) * 2.0,
          color: Colors.redAccent,
          size: 6 + _random.nextDouble() * 8,
        ));
      }
      return;
    }

    fruit.isSliced = true;
    _currentStrokeSlices++;

    int gainedScore = 0;
    Color color = Colors.orange;
    String floatTextStr = '';
    Color floatColor = Colors.orange;
    int pCount = 15;
    bool isGolden = false;

    switch (fruit.type) {
      case FruitType.bomb:
        AudioManager.instance.playBoing();
        _createExplosion(fruit.x, fruit.y);
        _loseLife();
        _floatingTexts.add(FloatingText(
          x: fruit.x, y: fruit.y, text: '앗!', color: Colors.red, size: 40
        ));
        return;
      case FruitType.normal:
        gainedScore = 10;
        _score += gainedScore;
        color = _fruitColors[fruit.emoji] ?? Colors.orange;
        AudioManager.instance.playPop();
        HapticFeedback.lightImpact();
        break;
      case FruitType.golden:
        gainedScore = 50;
        _score += gainedScore;
        color = Colors.yellow;
        floatTextStr = '+50';
        floatColor = Colors.yellow;
        isGolden = true;
        pCount = 25;
        AudioManager.instance.playPop();
        HapticFeedback.lightImpact();
        break;
      case FruitType.freeze:
        gainedScore = 10;
        _score += gainedScore;
        color = const Color(0xFF80DEEA);
        floatTextStr = '빙결 ❄️';
        floatColor = const Color(0xFF00B0FF);
        _freezeTimer = 4.0;
        AudioManager.instance.playPop();
        HapticFeedback.mediumImpact();
        break;
      case FruitType.heart:
        _lives = min(3, _lives + 1);
        color = Colors.pinkAccent;
        floatTextStr = '+1 하트 ❤️';
        floatColor = Colors.pinkAccent;
        pCount = 25;
        AudioManager.instance.playSuccess();
        HapticFeedback.mediumImpact();
        break;
      case FruitType.giant:
        gainedScore = 30;
        _score += gainedScore;
        color = Colors.redAccent;
        floatTextStr = 'GREAT! +30 🍉';
        floatColor = Colors.redAccent;
        pCount = 45; // 거대한 파티클 분수
        AudioManager.instance.playPop();
        HapticFeedback.heavyImpact();
        break;
    }

    // 파티클 생성
    for (int i = 0; i < pCount; i++) {
      _particles.add(JuiceParticle(
        x: fruit.x, y: fruit.y,
        vx: (_random.nextDouble() - 0.5) * (fruit.type == FruitType.giant ? 2.5 : 1.5),
        vy: (_random.nextDouble() - 0.5) * (fruit.type == FruitType.giant ? 2.5 : 1.5),
        color: color,
        size: 5 + _random.nextDouble() * (fruit.type == FruitType.giant ? 14 : 10),
        isSparkle: isGolden || fruit.type == FruitType.heart,
      ));
    }

    if (floatTextStr.isNotEmpty) {
      _floatingTexts.add(FloatingText(
        x: fruit.x, y: fruit.y, text: floatTextStr, color: floatColor, size: fruit.type == FruitType.giant ? 34 : 28
      ));
    }

    // 2개의 조각 생성
    _slicedPieces.add(SlicedFruit(
      emoji: fruit.emoji, x: fruit.x - 0.05, y: fruit.y,
      vx: fruit.vx - 0.3, vy: fruit.vy - 0.2,
      size: fruit.size, angle: fruit.angle, vAngle: fruit.vAngle - 2.0,
      isLeft: true, isGolden: fruit.type == FruitType.golden,
    ));
    _slicedPieces.add(SlicedFruit(
      emoji: fruit.emoji, x: fruit.x + 0.05, y: fruit.y,
      vx: fruit.vx + 0.3, vy: fruit.vy - 0.2,
      size: fruit.size, angle: fruit.angle, vAngle: fruit.vAngle + 2.0,
      isLeft: false, isGolden: fruit.type == FruitType.golden,
    ));
  }

  void _createExplosion(double x, double y) {
    for (int i = 0; i < 30; i++) {
      _particles.add(JuiceParticle(
        x: x, y: y,
        vx: (_random.nextDouble() - 0.5) * 2.5,
        vy: (_random.nextDouble() - 0.5) * 2.5,
        color: _random.nextBool() ? Colors.red : Colors.orangeAccent,
        size: 8 + _random.nextDouble() * 15,
      ));
    }
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    _currentStrokeSlices = 0;
    _bladeTrail.clear();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_isGameOver) return;
    final double relX = details.localPosition.dx / size.width;
    final double relY = details.localPosition.dy / size.height;
    
    setState(() {
      _bladeTrail.add(Offset(relX, relY));
      
      // 충돌 검사
      for (var fruit in _fruits) {
        if (fruit.isSliced || fruit.hitCooldown > 0) continue;
        final double dx = fruit.x - relX;
        final double dy = fruit.y - relY;
        final double hitRadiusSq = fruit.type == FruitType.giant ? 0.025 : 0.015;
        if (dx * dx + dy * dy < hitRadiusSq) {
          _sliceFruit(fruit);
        }
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    // 콤보 체크
    if (_currentStrokeSlices >= 3) {
      int comboBonus = (_currentStrokeSlices * 5);
      _score += comboBonus;
      
      // 화면 중앙 쪽에 콤보 텍스트 생성
      _floatingTexts.add(FloatingText(
        x: 0.5, y: 0.3,
        text: '$_currentStrokeSlices COMBO!\n+$comboBonus',
        color: KidsTheme.orange,
        size: 48,
      ));
      
      AudioManager.instance.playSuccess(); // 콤보 사운드
    }

    setState(() {
      _bladeTrail.clear();
      _currentStrokeSlices = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 고급스러운 배경
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.orange.shade100,
                    Colors.orange.shade300,
                    Colors.deepOrange.shade400,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  // 희미한 빗살무늬나 파티클을 배경에 깔아 깊이감 추가
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.05,
                      child: GridPaper(
                        color: Colors.white,
                        divisions: 2,
                        subdivisions: 2,
                        interval: 100,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // 게임 영역
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (details) => _handlePanStart(details, Size(constraints.maxWidth, constraints.maxHeight)),
                  onPanUpdate: (details) => _handlePanUpdate(details, Size(constraints.maxWidth, constraints.maxHeight)),
                  onPanEnd: _handlePanEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 파티클
                      ..._particles.map((p) => Positioned(
                        left: p.x * constraints.maxWidth - (p.size/2),
                        top: p.y * constraints.maxHeight - (p.size/2),
                        child: Opacity(
                          opacity: p.life.clamp(0.0, 1.0),
                          child: Container(
                            width: p.size, height: p.size,
                            decoration: BoxDecoration(
                              color: p.color,
                              shape: p.isSparkle ? BoxShape.rectangle : BoxShape.circle,
                              borderRadius: p.isSparkle ? BorderRadius.circular(4) : null,
                              boxShadow: p.isSparkle ? [BoxShadow(color: p.color.withValues(alpha: 0.8), blurRadius: 8)] : [],
                            ),
                          ),
                        ),
                      )),

                      // 잘린 조각들
                      ..._slicedPieces.map((p) => Positioned(
                        left: p.x * constraints.maxWidth - (p.size/2),
                        top: p.y * constraints.maxHeight - (p.size/2),
                        child: Transform.rotate(
                          angle: p.angle,
                          child: Opacity(
                            opacity: 0.85,
                            child: ClipRect(
                              clipper: HalfClipper(isLeft: p.isLeft),
                              child: Text(p.emoji, style: TextStyle(fontSize: p.size, shadows: p.isGolden ? [const Shadow(color: Colors.yellow, blurRadius: 15)] : null)),
                            ),
                          ),
                        ),
                      )),

                      // 과일들
                      ..._fruits.map((f) => Positioned(
                        left: f.x * constraints.maxWidth - (f.size/2),
                        top: f.y * constraints.maxHeight - (f.size/2),
                        child: Transform.rotate(
                          angle: f.angle,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Text(f.emoji, style: TextStyle(
                                fontSize: f.size,
                                shadows: f.type == FruitType.golden 
                                    ? [const Shadow(color: Colors.yellowAccent, blurRadius: 20)] 
                                    : null,
                              )),
                              if (f.maxHp > 1)
                                Positioned(
                                  top: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                    ),
                                    child: Text(
                                      '⚡ x${f.hp}',
                                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )),

                      // 부유 텍스트 (콤보 등)
                      ..._floatingTexts.map((t) => Positioned(
                        left: t.x * constraints.maxWidth - 50,
                        top: t.y * constraints.maxHeight - 20,
                        child: Opacity(
                          opacity: (t.life * 1.5).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 1.0 + (1.0 - t.life) * 0.5, // 커지면서 사라짐
                            child: Text(
                              t.text,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jua(
                                fontSize: t.size,
                                color: t.color,
                                shadows: const [Shadow(color: Colors.white, blurRadius: 8), Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 2))]
                              ),
                            ),
                          ),
                        ),
                      )),

                      // 칼날 궤적 (CustomPaint)
                      if (_bladeTrail.isNotEmpty)
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _BladePainter(trail: _bladeTrail, score: _score),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 프리미엄 헤더 (Glassmorphism)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () { AudioManager.instance.playClick(); Navigator.of(context).pop(); },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: KidsTheme.textDark, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 점수 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: KidsTheme.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: Text('점수: $_score', style: GoogleFonts.jua(fontSize: 24, color: Colors.white)),
                        ),
                        
                        const Spacer(),
                        
                        // 아기자기한 하트(목숨)
                        Row(
                          children: List.generate(3, (index) {
                            final isActive = index < _lives;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedScale(
                                scale: isActive ? 1.0 : 0.6,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  isActive ? Icons.favorite : Icons.favorite_border,
                                  color: isActive ? KidsTheme.red : Colors.white.withValues(alpha: 0.8),
                                  size: 32,
                                  shadows: isActive ? const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))] : [],
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Slow Motion Frost Overlay ──
          if (_freezeTimer > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xAA80DEEA), width: 10),
                    color: const Color(0x2240C4FF),
                  ),
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 140),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00B0FF), width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                      ),
                      child: Text(
                        '❄️ 시간 천천히! (${_freezeTimer.toStringAsFixed(1)}초)',
                        style: GoogleFonts.jua(fontSize: 22, color: Colors.blue.shade800),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Game Over Overlay
          if (_isGameOver)
            Positioned.fill(
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: KidsTheme.orange, width: 4),
                          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('😭', style: TextStyle(fontSize: 64)),
                            Text('게임 오버!', style: GoogleFonts.jua(fontSize: 48, color: KidsTheme.orange)),
                            const SizedBox(height: 16),
                            Text('최종 점수: $_score ⭐', style: GoogleFonts.jua(fontSize: 32, color: KidsTheme.textDark)),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                setState(() {
                                  _score = 0;
                                  _lives = 3;
                                  _fruits.clear();
                                  _slicedPieces.clear();
                                  _particles.clear();
                                  _floatingTexts.clear();
                                  _freezeTimer = 0.0;
                                  _isGameOver = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                decoration: BoxDecoration(
                                  color: KidsTheme.green,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                                ),
                                child: Text('다시 하기 🔄', style: GoogleFonts.jua(fontSize: 28, color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BladePainter extends CustomPainter {
  final List<Offset> trail;
  final int score;
  _BladePainter({required this.trail, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;
    final path = Path();
    path.moveTo(trail[0].dx * size.width, trail[0].dy * size.height);
    for (int i = 1; i < trail.length; i++) {
      path.lineTo(trail[i].dx * size.width, trail[i].dy * size.height);
    }
    
    Color glowColor = Colors.cyanAccent;
    Color coreColor = Colors.white;
    double strokeWidth = 14;

    if (score < 20) {
      glowColor = Colors.cyanAccent.withValues(alpha: 0.6);
      coreColor = Colors.white;
    } else if (score < 50) {
      glowColor = Colors.orangeAccent.withValues(alpha: 0.7);
      coreColor = Colors.yellow.shade100;
      strokeWidth = 16;
    } else {
      // 50점 이상: 무지개/우주 칼날
      glowColor = Colors.purpleAccent.withValues(alpha: 0.7);
      coreColor = Colors.yellowAccent;
      strokeWidth = 18;
    }

    final outerGlow = Paint()
      ..color = glowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerCore = Paint()
      ..color = coreColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (score >= 50) {
      final rect = path.getBounds();
      outerGlow.shader = const LinearGradient(
        colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple],
      ).createShader(rect);
    }

    canvas.drawPath(path, outerGlow);
    canvas.drawPath(path, innerCore);
  }

  @override
  bool shouldRepaint(covariant _BladePainter oldDelegate) => true;
}

class HalfClipper extends CustomClipper<Rect> {
  final bool isLeft;
  HalfClipper({required this.isLeft});

  @override
  Rect getClip(Size size) {
    if (isLeft) {
      return Rect.fromLTWH(0, 0, size.width / 2, size.height);
    } else {
      return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
    }
  }

  @override
  bool shouldReclip(covariant HalfClipper oldClipper) => oldClipper.isLeft != isLeft;
}
