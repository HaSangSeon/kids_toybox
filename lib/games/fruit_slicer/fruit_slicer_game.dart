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

class _FruitSlicerGameState extends State<FruitSlicerGame> with TickerProviderStateMixin {
  late Ticker _ticker;
  late AnimationController _bgAnimCtrl;
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
  int _currentLevel = 1;
  bool _showStageSelect = true; // 진입 시 바로 레벨 선택 화면 노출
  bool _isGameOver = false;
  int _currentStrokeSlices = 0; // For Combo tracking
  double _freezeTimer = 0.0;

  void _resetGame() {
    setState(() {
      _score = 0;
      _lives = 3;
      _fruits.clear();
      _particles.clear();
      _slicedPieces.clear();
      _floatingTexts.clear();
      _bladeTrail.clear();
      _spawnTimer = 0;
      _freezeTimer = 0.0;
      _isGameOver = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bgAnimCtrl.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_isGameOver || _showStageSelect) return;
    
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
      double spawnInterval = 1.8;
      if (_currentLevel == 1) spawnInterval = 2.0;
      else if (_currentLevel == 2) spawnInterval = 1.6;
      else if (_currentLevel == 3) spawnInterval = 1.3;
      else if (_currentLevel == 4) spawnInterval = 1.0;
      else spawnInterval = 0.8;

      if (_spawnTimer > spawnInterval) {
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
    // 폭탄 등장 확률 (1단계는 폭탄 완전히 없음!)
    double bombChance = 0.0;
    if (_currentLevel == 1) {
      bombChance = 0.0;
    } else if (_currentLevel == 2) {
      bombChance = 0.05;
    } else if (_currentLevel == 3) {
      bombChance = 0.07;
    } else if (_currentLevel == 4) {
      bombChance = 0.09;
    } else {
      bombChance = 0.12;
    }

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
      AudioManager.instance.playSwordSlice(rate: 1.1);
      HapticFeedback.mediumImpact();

      _floatingTexts.add(FloatingText(
        x: fruit.x, y: fruit.y,
        text: '싹둑! (${fruit.hp}번 남음)',
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
        AudioManager.instance.playSwordSlice(rate: 0.95 + _random.nextDouble() * 0.25);
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
        AudioManager.instance.playSwordSlice(rate: 1.25);
        HapticFeedback.lightImpact();
        break;
      case FruitType.freeze:
        gainedScore = 10;
        _score += gainedScore;
        color = const Color(0xFF80DEEA);
        floatTextStr = '빙결 ❄️';
        floatColor = const Color(0xFF00B0FF);
        _freezeTimer = 4.0;
        AudioManager.instance.playSwordSlice(rate: 0.85);
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
        AudioManager.instance.playSwordSlice(rate: 0.8);
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

  Widget _buildWhimsicalBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF3E0), // Soft cream sunrise
            Color(0xFFFFCC80), // Warm peach
            Color(0xFFFFAB91), // Coral sunset
            Color(0xFFE64A19), // Deep orchard orange
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Rotating Sunburst Rays
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              return CustomPaint(
                painter: _SunburstPainter(animationValue: _bgAnimCtrl.value),
              );
            },
          ),

          // Floating Whimsical Clouds & Sky Particles
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              final val = _bgAnimCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    left: (val * 400) % 450 - 80,
                    top: 60,
                    child: const Opacity(opacity: 0.7, child: Text('☁️', style: TextStyle(fontSize: 54))),
                  ),
                  Positioned(
                    right: (val * 350) % 420 - 60,
                    top: 130,
                    child: const Opacity(opacity: 0.6, child: Text('☁️', style: TextStyle(fontSize: 42))),
                  ),
                  Positioned(
                    left: 40 + sin(val * 2 * pi) * 20,
                    top: 200,
                    child: const Opacity(opacity: 0.8, child: Text('✨', style: TextStyle(fontSize: 28))),
                  ),
                  Positioned(
                    right: 50 + cos(val * 2 * pi) * 25,
                    top: 240,
                    child: const Opacity(opacity: 0.7, child: Text('⭐', style: TextStyle(fontSize: 24))),
                  ),
                  Positioned(
                    left: 180 + sin(val * 4 * pi) * 30,
                    top: 110,
                    child: const Opacity(opacity: 0.75, child: Text('🌸', style: TextStyle(fontSize: 22))),
                  ),
                  Positioned(
                    right: 140 + cos(val * 3 * pi) * 20,
                    top: 170,
                    child: const Opacity(opacity: 0.7, child: Text('🍃', style: TextStyle(fontSize: 26))),
                  ),
                ],
              );
            },
          ),

          // Bottom Orchard Hills Silhouette
          Positioned(
            bottom: -10,
            left: -20,
            right: -20,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                borderRadius: const BorderRadius.vertical(top: Radius.elliptical(300, 60)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('🌱', style: TextStyle(fontSize: 24)),
                  Text('🌸', style: TextStyle(fontSize: 22)),
                  Text('🌾', style: TextStyle(fontSize: 26)),
                  Text('🍓', style: TextStyle(fontSize: 24)),
                  Text('🌱', style: TextStyle(fontSize: 22)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 뒤로가기 버튼
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),

              // 3D Fruit Score Pill (Center - Watermelon Icon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '$_score점',
                      style: GoogleFonts.jua(
                        fontSize: 18,
                        color: Colors.white,
                        shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
                      ),
                    ),
                  ],
                ),
              ),

              // 상단 우측 레벨 선택 버튼 (아기자기하고 고급스러운 3D 뱃지)
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  setState(() {
                    _showStageSelect = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8E24AA).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🗺️', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$_currentLevel단계',
                        style: GoogleFonts.jua(
                          fontSize: 15,
                          color: Colors.white,
                          shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2)],
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // 드래그 슬라이스로 인한 의도치 않은 뒤로가기/앱 이탈 방지
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 동화 속 과일 동산 배경
            Positioned.fill(
              child: _buildWhimsicalBackground(),
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

          // 프리미엄 3D 헤더 (Glassmorphism)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              child: _buildPremiumHeader(),
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
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5964).withValues(alpha: 0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.9),
                              blurRadius: 6,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            // Fruity Header Avatar Badge
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFF8A80), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5964).withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text('🍉', style: TextStyle(fontSize: 46)),
                            ),
                            const SizedBox(height: 12),

                            // 3D Title Text
                            Text(
                              '아쉬워요! 과일 싹둑!',
                              style: GoogleFonts.jua(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.fill
                                  ..color = const Color(0xFFFF5964),
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFFFFB74D),
                                    offset: Offset(1.5, 1.5),
                                    blurRadius: 0,
                                  ),
                                  Shadow(
                                    color: Colors.black12,
                                    offset: Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Score Card Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFFFE0B2), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF9F1C).withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE082),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '최종 득점',
                                      style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFE65100)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🍉', style: TextStyle(fontSize: 28)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$_score',
                                        style: GoogleFonts.jua(
                                          fontSize: 42,
                                          color: const Color(0xFF2D3748),
                                          shadows: const [
                                            Shadow(color: Colors.black12, offset: Offset(0, 2), blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        ' 점',
                                        style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFF718096)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 3D Glossy Action Buttons
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Exit Button
                                GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playClick();
                                    Navigator.of(context).pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '메인으로',
                                          style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Stage Select Button
                                GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playClick();
                                    setState(() {
                                      _showStageSelect = true;
                                      _isGameOver = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [KidsTheme.purple, Color(0xFFAB47BC)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: KidsTheme.purple.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('🗺️', style: TextStyle(fontSize: 16)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '레벨 선택',
                                          style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Restart Button
                                GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playClick();
                                    _resetGame();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '다시 하기 🔄',
                                          style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Stage Select Overlay
            if (_showStageSelect)
              _buildStageSelectOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Stage Select Overlay ──────────────────────────────────────────────────
  Widget _buildStageSelectOverlay() {
    final stagesInfo = [
      (stage: 1, name: '1단계: 과일 동산', desc: '쉬움 🍉 - 폭탄 없음! 느긋하고 편안하게', color: const Color(0xFF4ADE80), icon: '🍉'),
      (stage: 2, name: '2단계: 과일 잔치', desc: '보통 🍊 - 황금 과일과 하트! 폭탄 찔끔', color: const Color(0xFF60A5FA), icon: '🍊'),
      (stage: 3, name: '3단계: 수박 파티', desc: '신남 🍍 - 3번 베는 대왕 수박 & 빙결 아이템', color: const Color(0xFFF59E0B), icon: '🍍'),
      (stage: 4, name: '4단계: 과일 폭풍', desc: '매운맛 🍓 - 빠른 과일 쏟아짐 & 폭탄 주의', color: const Color(0xFFEC4899), icon: '🍓'),
      (stage: 5, name: '5단계: 싹둑 마스터', desc: '달인 🏆 - 초고속 마스터 콤보 모드!', color: const Color(0xFFA855F7), icon: '🏆'),
    ];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.70),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 580),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _showStageSelect = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: KidsTheme.textDark),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('⚔️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 6),
                          Text(
                            '레벨 선택',
                            style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '하고 싶은 레벨을 골라 신나게 싹둑 해보세요!',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: stagesInfo.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final info = stagesInfo[index];
                      final bool isCurrent = _currentLevel == info.stage;

                      return GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _currentLevel = info.stage;
                            _showStageSelect = false;
                            _resetGame();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [info.color.withValues(alpha: 0.88), info.color],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: isCurrent ? Border.all(color: Colors.yellowAccent, width: 3.5) : Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: info.color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(info.icon, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          info.name,
                                          style: GoogleFonts.jua(fontSize: 17, color: Colors.white),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.yellowAccent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '선택됨',
                                              style: GoogleFonts.jua(fontSize: 11, color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      info.desc,
                                      style: GoogleFonts.jua(fontSize: 12, color: Colors.white.withValues(alpha: 0.95)),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _SunburstPainter extends CustomPainter {
  final double animationValue;
  _SunburstPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final radius = max(size.width, size.height) * 1.2;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const numRays = 16;
    final angleStep = (2 * pi) / numRays;
    final rotation = animationValue * 2 * pi;

    for (int i = 0; i < numRays; i += 2) {
      final startAngle = rotation + i * angleStep;
      final sweepAngle = angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunburstPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
