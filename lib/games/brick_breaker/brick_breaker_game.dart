import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class Ball {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  bool isFireball; // 불공: 벽돌을 관통

  Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = 14,
    this.isFireball = false,
  });

  Rect get rect => Rect.fromCircle(center: Offset(x, y), radius: radius);
}

class Paddle {
  double x;
  double y;
  double width;
  double height;

  Paddle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: width, height: height);
}

/// 벽돌 타입: HP 1~2 & 특수 연쇄 폭탄 벽돌
enum BrickType { normal, tough, bomb }

class Brick {
  double left;
  double top;
  double width;
  double height;
  int hp;         // 남은 체력 (최대 2방으로 시원함 유지)
  int maxHp;      // 최대 체력
  bool isDestroyed;
  Color color;
  String emoji;
  BrickType type;
  // 깨질 때 아이템 드롭 확률 (0~1), 0이면 드롭 없음
  double dropChance;
  // 깨질 때 떨어트릴 아이템 타입
  ItemType? dropItem;

  Brick({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.hp,
    required this.color,
    required this.emoji,
    required this.type,
    this.isDestroyed = false,
    this.dropChance = 0.0,
    this.dropItem,
  }) : maxHp = hp;

  Rect get rect => Rect.fromLTWH(left, top, width, height);
}

// ─────────────────────────────────────────────────────────────────────────────
// 아이템
// ─────────────────────────────────────────────────────────────────────────────

enum ItemType { multiBall, widePaddle, slowBall, fireball }

class DroppedItem {
  double x;
  double y;
  double vy;
  ItemType type;
  bool collected;
  bool missed;
  final double size = 36.0;

  DroppedItem({
    required this.x,
    required this.y,
    required this.type,
    this.vy = 160,
    this.collected = false,
    this.missed = false,
  });

  String get emoji => switch (type) {
    ItemType.multiBall  => '🎱',
    ItemType.widePaddle => '↔️',
    ItemType.slowBall   => '🐢',
    ItemType.fireball   => '🔥',
  };

  String get label => switch (type) {
    ItemType.multiBall  => '멀티볼!',
    ItemType.widePaddle => '패들확장!',
    ItemType.slowBall   => '슬로우!',
    ItemType.fireball   => '파이어볼!',
  };

  Color get color => switch (type) {
    ItemType.multiBall  => const Color(0xFF7C4DFF),
    ItemType.widePaddle => const Color(0xFF00BCD4),
    ItemType.slowBall   => const Color(0xFF4CAF50),
    ItemType.fireball   => const Color(0xFFFF5722),
  };

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: size, height: size);
}

// ─────────────────────────────────────────────────────────────────────────────
// 파티클
// ─────────────────────────────────────────────────────────────────────────────

class BrickParticle {
  double x, y;
  double vx, vy;
  double size;
  double opacity;
  Color color;

  BrickParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  void update(double dt) {
    x  += vx * dt;
    y  += vy * dt;
    vy += 400 * dt; // gravity
    opacity -= 2.2 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 팝업 텍스트
// ─────────────────────────────────────────────────────────────────────────────

class ScorePopup {
  double x, y;
  double vy;
  double opacity;
  String text;
  Color color;

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.vy = -80,
    this.opacity = 1.0,
  });

  void update(double dt) {
    y += vy * dt;
    opacity -= 1.8 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Game Widget
// ─────────────────────────────────────────────────────────────────────────────

class BrickBreakerGame extends StatefulWidget {
  const BrickBreakerGame({super.key});

  @override
  State<BrickBreakerGame> createState() => _BrickBreakerGameState();
}

class _BrickBreakerGameState extends State<BrickBreakerGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  double _bgTime = 0; // 배경 애니메이션 시간

  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isGameClear = false;

  int _score = 0;
  int _bestScore = 0;
  int _lives = 3;
  int _level = 1;

  int _comboCount = 0; // 연속 블록 파괴 콤보
  double _paddleScale = 1.0; // 패들 바운스 스케일

  List<Ball> _balls = [];
  Paddle? _paddle;
  List<Brick> _bricks = [];
  List<DroppedItem> _items = [];
  List<BrickParticle> _particles = [];
  List<ScorePopup> _popups = [];

  Size _screenSize = Size.zero;
  double _paddleWidth = 130.0;
  final double _paddleHeight = 22.0;
  final double _ballRadius = 14.0;
  double _baseSpeed = 410.0;

  // 아이템 활성 시간
  double _widePaddleTimer = 0;
  double _slowBallTimer   = 0;
  double _fireballTimer   = 0;

  // 활성 아이템 플래그
  bool get _isWidePaddle => _widePaddleTimer > 0;
  bool get _isSlowBall   => _slowBallTimer > 0;
  bool get _isFireball   => _fireballTimer > 0;

  final Random _random = Random();

  static const List<String> _brickEmojis = ['🍬', '🍭', '🍫', '🍩', '🍪', '🍰', '🧁', '🎂'];
  static const List<Color> _brickBaseColors = [
    Color(0xFFFF6B9D), // pink
    Color(0xFF7C4DFF), // purple
    Color(0xFFFFB300), // amber
    Color(0xFF00C853), // green
    Color(0xFF2979FF), // blue
    Color(0xFFFF5722), // deep orange
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ── Game init ──────────────────────────────────────────────────────────────

  void _startGame(Size size) {
    _screenSize = size;
    _score = 0;
    _lives = 3;
    _level = 1;
    _isGameOver = false;
    _isGameClear = false;
    _baseSpeed = 410.0;
    _paddleWidth = 130.0;
    _widePaddleTimer = 0;
    _slowBallTimer   = 0;
    _fireballTimer   = 0;
    _items.clear();
    _particles.clear();
    _popups.clear();
    _initLevel();
  }

  void _nextLevel() {
    _level++;
    _baseSpeed = (410.0 + (_level - 1) * 15.0).clamp(410.0, 580.0);
    _initLevel();
  }

  void _initLevel() {
    _isGameClear = false;
    _isPlaying = false;

    // 레벨별 패들 크기 및 기본 공 속도 뚜렷하게 차별화!
    switch (_level) {
      case 1:
        _paddleWidth = 165.0; // 1단계: 크고 편안한 패들
        _baseSpeed = 320.0;   // 천천히 튀는 공
        break;
      case 2:
        _paddleWidth = 135.0; // 2단계: 표준 패들
        _baseSpeed = 400.0;   // 적당한 속도
        break;
      case 3:
        _paddleWidth = 115.0; // 3단계: 슬림 패들
        _baseSpeed = 470.0;   // 빠른 스피드
        break;
      case 4:
      default:
        _paddleWidth = 98.0;  // 4단계: 도전 슬림 패들
        _baseSpeed = 540.0;   // 박진감 넘치는 하이스피드
        break;
    }

    _paddle = Paddle(
      x: _screenSize.width / 2,
      y: _screenSize.height - 80,
      width: _paddleWidth,
      height: _paddleHeight,
    );

    _balls = [
      Ball(
        x: _paddle!.x,
        y: _paddle!.y - _paddleHeight / 2 - _ballRadius - 1,
        vx: 0,
        vy: 0,
        radius: _ballRadius,
      )
    ];

    _items.clear();
    _particles.clear();
    _popups.clear();
    _generateBricks();

    if (!_ticker.isTicking) _ticker.start();
    setState(() {});
  }

  void _generateBricks() {
    _bricks.clear();
    final int cols = 6;
    // 레벨 1: 3행, 레벨 2: 4행, 레벨 3: 5행, 레벨 4: 6행
    final int rows = (2 + _level).clamp(3, 6);

    const double padding = 7.0;
    final double totalPadding = padding * (cols + 1);
    final double brickWidth  = (_screenSize.width - totalPadding) / cols;
    const double brickHeight = 36.0;
    const double topOffset   = 100.0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        // 무늬 구멍 패턴 (레벨 2 이상부터)
        if (_level >= 2 && (r + c) % 2 == 1 && _random.nextDouble() < 0.15) {
          continue;
        }

        final left = padding + c * (brickWidth + padding);
        final top  = topOffset + r * (brickHeight + padding);

        final rng = _random.nextDouble();
        BrickType type;
        int hp;
        Color baseColor = _brickBaseColors[(r + _level) % _brickBaseColors.length];
        String emoji = _brickEmojis[(r + c + _level) % _brickEmojis.length];

        if (_level == 1) {
          // 1단계: 1방 터치 쉬운 사탕 100%
          type = BrickType.normal;
          hp = 1;
        } else if (_level == 2) {
          // 2단계: 1방 (85%), 폭탄 💣 (8%), 2방 (7%)
          if (rng < 0.08) {
            type = BrickType.bomb;
            hp = 1;
            emoji = '💣';
            baseColor = const Color(0xFFFF3D00);
          } else if (rng < 0.22) {
            type = BrickType.tough;
            hp = 2;
          } else {
            type = BrickType.normal;
            hp = 1;
          }
        } else if (_level == 3) {
          // 3단계: 1방 (65%), 폭탄 💣 (15%), 2방 (20%)
          if (rng < 0.15) {
            type = BrickType.bomb;
            hp = 1;
            emoji = '💣';
            baseColor = const Color(0xFFFF3D00);
          } else if (rng < 0.35) {
            type = BrickType.tough;
            hp = 2;
          } else {
            type = BrickType.normal;
            hp = 1;
          }
        } else {
          // 4단계 (대폭발 캔디 파티!): 폭탄 💣 (22% 우수수 배치!), 1방 (50%), 2방 (28%)
          if (rng < 0.22) {
            type = BrickType.bomb;
            hp = 1;
            emoji = '💣';
            baseColor = const Color(0xFFFF1744);
          } else if (rng < 0.50) {
            type = BrickType.tough;
            hp = 2;
          } else {
            type = BrickType.normal;
            hp = 1;
          }
        }

        // 레벨별 아이템 드롭률 (1단계일수록 아이템 우수수 드롭!)
        final double itemDropChance = switch (_level) {
          1 => 0.55,
          2 => 0.45,
          3 => 0.40,
          _ => 0.38,
        };

        ItemType? dropItem;
        double dropChance = 0.0;
        if (_random.nextDouble() < itemDropChance) {
          dropChance = 1.0;
          final items = ItemType.values;
          dropItem = items[_random.nextInt(items.length)];
        }

        _bricks.add(Brick(
          left: left,
          top:  top,
          width:  brickWidth,
          height: brickHeight,
          hp:   hp,
          color: baseColor,
          emoji: emoji,
          type:  type,
          dropChance: dropChance,
          dropItem:   dropItem,
        ));
      }
    }
  }

  // ── Launch ─────────────────────────────────────────────────────────────────

  void _launchBall() {
    if (_isPlaying || _isGameOver || _isGameClear) return;
    setState(() {
      _isPlaying = true;
      _lastTime = Duration.zero;
      final double angle = -pi / 2 + (_random.nextDouble() * 0.5 - 0.25);
      _balls[0].vx = cos(angle) * _baseSpeed;
      _balls[0].vy = sin(angle) * _baseSpeed;
    });
  }

  // ── Tick ───────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
    }
    final double dt = ((elapsed - _lastTime).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTime = elapsed;

    _bgTime += dt;
    if (_paddleScale > 1.0) {
      _paddleScale = (_paddleScale - dt * 1.5).clamp(1.0, 2.0);
    }

    // Update particles & popups always (even when not playing, for visual continuity)
    for (final p in _particles) p.update(dt);
    _particles.removeWhere((p) => p.opacity <= 0);
    for (final p in _popups) p.update(dt);
    _popups.removeWhere((p) => p.opacity <= 0);

    if (!_isPlaying || _isGameOver || _isGameClear) {
      setState(() {});
      return;
    }

    _updatePhysics(dt);
    setState(() {});
  }

  void _updatePhysics(double dt) {
    // ── Active item timers ──────────────────────────────────────────────────
    if (_widePaddleTimer > 0) {
      _widePaddleTimer -= dt;
      if (_widePaddleTimer <= 0) {
        _widePaddleTimer = 0;
        _paddle!.width = _paddleWidth;
      }
    }
    if (_slowBallTimer > 0) {
      _slowBallTimer -= dt;
      if (_slowBallTimer <= 0) {
        _slowBallTimer = 0;
        // restore speed
        for (final b in _balls) {
          final spd = sqrt(b.vx * b.vx + b.vy * b.vy);
          if (spd > 0) {
            b.vx = b.vx / spd * _baseSpeed;
            b.vy = b.vy / spd * _baseSpeed;
          }
        }
      }
    }
    if (_fireballTimer > 0) {
      _fireballTimer -= dt;
      if (_fireballTimer <= 0) {
        _fireballTimer = 0;
        for (final b in _balls) b.isFireball = false;
      }
    }

    // ── Dropped items fall ─────────────────────────────────────────────────
    for (final item in _items) {
      if (item.collected || item.missed) continue;
      item.y += item.vy * dt;

      // Paddle catch
      if (item.rect.overlaps(_paddle!.rect)) {
        item.collected = true;
        _applyItem(item.type);
        AudioManager.instance.playChime();
        HapticFeedback.mediumImpact();
        _popups.add(ScorePopup(
          x: item.x, y: item.y - 20,
          text: item.label, color: item.color,
        ));
      }

      // Miss
      if (item.y > _screenSize.height + 40) item.missed = true;
    }
    _items.removeWhere((i) => i.collected || i.missed);

    // ── Balls ──────────────────────────────────────────────────────────────
    final List<Ball> toAdd = [];
    for (final ball in _balls) {
      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;

      // Wall collisions
      if (ball.x - ball.radius <= 0) {
        ball.x = ball.radius;
        ball.vx = ball.vx.abs();
        AudioManager.instance.playSnap();
      } else if (ball.x + ball.radius >= _screenSize.width) {
        ball.x = _screenSize.width - ball.radius;
        ball.vx = -ball.vx.abs();
        AudioManager.instance.playSnap();
      }
      if (ball.y - ball.radius <= 0) {
        ball.y = ball.radius;
        ball.vy = ball.vy.abs();
        AudioManager.instance.playSnap();
      }

      // Paddle collision
      if (ball.vy > 0 && ball.rect.overlaps(_paddle!.rect)) {
        ball.vy = -ball.vy.abs();
        final hitFactor = (ball.x - _paddle!.x) / (_paddle!.width / 2);
        ball.vx = hitFactor * _baseSpeed * 0.85;
        final spd = sqrt(ball.vx * ball.vx + ball.vy * ball.vy);
        final targetSpd = _isSlowBall ? _baseSpeed * 0.55 : _baseSpeed;
        ball.vx = ball.vx / spd * targetSpd;
        ball.vy = ball.vy / spd * targetSpd;
        ball.y = _paddle!.rect.top - ball.radius;

        // 띠용 패들 바운스 스케일 + 파티클 팡팡!
        _paddleScale = 1.25;
        _comboCount = 0; // 패들 터치 시 콤보 리셋
        _spawnPaddleParticles(ball.x, _paddle!.rect.top);

        AudioManager.instance.playBoing();
        HapticFeedback.lightImpact();
      }

      // Bottom miss
      if (ball.y - ball.radius > _screenSize.height) {
        ball.vy = -9999; // mark for removal
      }
    }

    // Remove missed balls
    _balls.removeWhere((b) => b.vy == -9999);
    if (_balls.isEmpty) {
      _lives--;
      HapticFeedback.heavyImpact();
      AudioManager.instance.playDamage();
      if (_lives <= 0) {
        _isGameOver = true;
        _isPlaying = false;
        AudioManager.instance.playGameOver();
        if (_score > _bestScore) _bestScore = _score;
      } else {
        _isPlaying = false;
        _balls = [
          Ball(
            x: _paddle!.x,
            y: _paddle!.y - _paddleHeight / 2 - _ballRadius - 1,
            vx: 0, vy: 0, radius: _ballRadius,
          )
        ];
      }
      return;
    }

    // Add split balls
    _balls.addAll(toAdd);

    // ── Brick collisions ───────────────────────────────────────────────────
    for (final ball in _balls) {
      for (final brick in _bricks) {
        if (brick.isDestroyed) continue;
        if (!ball.rect.overlaps(brick.rect)) continue;



        brick.hp--;
        if (brick.hp <= 0) {
          _destroyBrick(brick, ball);
        } else {
          // Damaged but not destroyed
          _spawnDamageParticles(brick);
          AudioManager.instance.playThud();
          HapticFeedback.selectionClick();
          _score += 5;
        }

        // Only fireball penetrates; normal ball reflects
        if (!ball.isFireball) {
          _reflectBall(ball, brick);
          break;
        }
        break; // only one brick per ball per frame
      }
    }

    // ── Level clear ────────────────────────────────────────────────────────
    if (_bricks.isNotEmpty && _bricks.every((b) => b.isDestroyed)) {
      _isGameClear = true;
      _isPlaying = false;
      AudioManager.instance.playSuccess();
    }
  }

  void _reflectBall(Ball ball, Brick brick) {
    final overlapLeft   = ball.x - brick.rect.left;
    final overlapRight  = brick.rect.right  - ball.x;
    final overlapTop    = ball.y - brick.rect.top;
    final overlapBottom = brick.rect.bottom - ball.y;
    final minOverlap = [overlapLeft, overlapRight, overlapTop, overlapBottom].reduce(min);
    if (minOverlap == overlapTop || minOverlap == overlapBottom) {
      ball.vy = -ball.vy;
    } else {
      ball.vx = -ball.vx;
    }
  }

  void _destroyBrick(Brick brick, Ball ball) {
    if (brick.isDestroyed) return;
    brick.isDestroyed = true;
    _comboCount++;

    final pts = switch (brick.type) {
      BrickType.normal => 10,
      BrickType.tough  => 20,
      BrickType.bomb   => 30,
    };
    _score += pts;
    if (_score > _bestScore) _bestScore = _score;

    // Sound: 콤보에 맞춰 신나는 피치 조절 사운드
    final rate = (0.9 + (_comboCount * 0.12)).clamp(0.9, 2.2);
    AudioManager.instance.playEffect('audio/crash.wav', rate: rate);
    HapticFeedback.mediumImpact();

    // Particles
    _spawnDestroyParticles(brick);

    // 💣 폭탄 연쇄 폭발 처리!
    if (brick.type == BrickType.bomb) {
      _triggerBombExplosion(brick, ball);
    }

    // 콤보 팡팡 팝업 이펙트!
    if (_comboCount >= 2) {
      final comboText = _comboCount >= 5
          ? '🔥 FEVER X$_comboCount!'
          : _comboCount >= 3
              ? '🌟 $_comboCount COMBO!'
              : '💥 2 COMBO!';
      final comboColor = _comboCount >= 5
          ? const Color(0xFFFF3D00)
          : _comboCount >= 3
              ? const Color(0xFFFFD600)
              : const Color(0xFF00E676);

      _popups.add(ScorePopup(
        x: brick.left + brick.width / 2,
        y: brick.top - 16,
        text: comboText,
        color: comboColor,
      ));
    }

    // Item drop
    if (brick.dropItem != null && _random.nextDouble() < brick.dropChance) {
      _items.add(DroppedItem(
        x: brick.left + brick.width / 2,
        y: brick.top + brick.height / 2,
        type: brick.dropItem!,
      ));
    }
  }

  /// 💣 폭탄 사탕 주변 연쇄 폭발!
  void _triggerBombExplosion(Brick bombBrick, Ball ball) {
    final bx = bombBrick.left + bombBrick.width / 2;
    final by = bombBrick.top + bombBrick.height / 2;

    _popups.add(ScorePopup(
      x: bx,
      y: by - 24,
      text: '💥 콰콰쾅!!',
      color: const Color(0xFFFF1744),
    ));

    // 주위 100px 이내의 아직 안 깨진 벽돌들 연쇄 파괴!
    for (final other in List<Brick>.from(_bricks)) {
      if (other.isDestroyed || other == bombBrick) continue;
      final ox = other.left + other.width / 2;
      final oy = other.top + other.height / 2;
      final dist = sqrt((ox - bx) * (ox - bx) + (oy - by) * (oy - by));

      if (dist <= 105.0) {
        _destroyBrick(other, ball);
      }
    }
  }

  void _spawnPaddleParticles(double px, double py) {
    for (int i = 0; i < 8; i++) {
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 1.6;
      final speed = 80 + _random.nextDouble() * 120;
      _particles.add(BrickParticle(
        x: px, y: py,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 4 + _random.nextDouble() * 6,
        color: const Color(0xFFFFD54F),
      ));
    }
  }

  void _spawnDestroyParticles(Brick brick) {
    final cx = brick.left + brick.width / 2;
    final cy = brick.top  + brick.height / 2;
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 120 + _random.nextDouble() * 200;
      _particles.add(BrickParticle(
        x: cx, y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 60,
        size: 4 + _random.nextDouble() * 8,
        color: brick.color,
      ));
    }
  }

  void _spawnDamageParticles(Brick brick) {
    final cx = brick.left + brick.width / 2;
    final cy = brick.top  + brick.height / 2;
    for (int i = 0; i < 5; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60 + _random.nextDouble() * 100;
      _particles.add(BrickParticle(
        x: cx, y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 30,
        size: 3 + _random.nextDouble() * 5,
        color: brick.color.withOpacity(0.7),
      ));
    }
  }

  void _applyItem(ItemType type) {
    switch (type) {
      case ItemType.multiBall:
        // 멀티볼 아이템 먹었을 때 공이 펑펑 2~3개씩 복제 (최대 12개)
        final List<Ball> newBalls = [];
        for (final b in _balls) {
          if (_balls.length + newBalls.length >= 12) break;
          for (int i = 0; i < 2; i++) {
            if (_balls.length + newBalls.length >= 12) break;
            final spread = (_random.nextDouble() - 0.5) * 1.5;
            newBalls.add(Ball(
              x: b.x, y: b.y,
              vx: b.vx * cos(spread) - b.vy * sin(spread),
              vy: b.vx * sin(spread) + b.vy * cos(spread),
              radius: b.radius,
              isFireball: b.isFireball,
            ));
          }
        }
        _balls.addAll(newBalls);

      case ItemType.widePaddle:
        _widePaddleTimer = 12.0;
        _paddle!.width = _paddleWidth * 1.8;

      case ItemType.slowBall:
        _slowBallTimer = 8.0;
        for (final b in _balls) {
          final spd = sqrt(b.vx * b.vx + b.vy * b.vy);
          if (spd > 0) {
            b.vx = b.vx / spd * _baseSpeed * 0.6;
            b.vy = b.vy / spd * _baseSpeed * 0.6;
          }
        }

      case ItemType.fireball:
        _fireballTimer = 9.0;
        for (final b in _balls) {
          b.isFireball = true;
        }
    }
  }

  // ── Paddle drag ────────────────────────────────────────────────────────────

  void _onPanUpdate(DragUpdateDetails details) {
    if (_paddle == null || _isGameOver || _isGameClear) return;
    setState(() {
      _paddle!.x = (_paddle!.x + details.delta.dx)
          .clamp(_paddle!.width / 2, _screenSize.width - _paddle!.width / 2);
      if (!_isPlaying) _balls[0].x = _paddle!.x;
    });
  }



  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C194D), // 몽환적인 딥 캔디 퍼플
              Color(0xFF4A154B), // 아기자기 파스텔 퍼플
              Color(0xFF1F1135),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // Active item indicators
              if (_isWidePaddle || _isSlowBall || _isFireball)
                _buildItemStatus(),
              // Game Area
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (_screenSize.width != constraints.maxWidth ||
                        _screenSize.height != constraints.maxHeight) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_balls.isEmpty && mounted) {
                          _startGame(Size(constraints.maxWidth, constraints.maxHeight));
                        }
                      });
                    }
                    return GestureDetector(
                      onPanUpdate: _onPanUpdate,
                      onTapDown: (_) => _launchBall(),
                      behavior: HitTestBehavior.opaque,
                      child: ClipRect(
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Stack(
                            children: [
                              // ── Animated background ──────────────────────
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ArcadeBgPainter(time: _bgTime),
                                ),
                              ),

                              // ── Bricks ───────────────────────────────────
                              ..._bricks.where((b) => !b.isDestroyed).map(_buildBrick),

                              // ── Particles ────────────────────────────────
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ParticlePainter(
                                    particles: _particles,
                                    popups: _popups,
                                  ),
                                ),
                              ),

                              // ── Dropped items ─────────────────────────────
                              ..._items.map((item) => Positioned(
                                left: item.x - item.size / 2,
                                top:  item.y  - item.size / 2,
                                child: _buildItem(item),
                              )),

                              // ── Paddle ────────────────────────────────────
                              if (_paddle != null) _buildPaddle(),

                              // ── Balls ─────────────────────────────────────
                              ..._balls.map(_buildBall),

                              // ── Overlays ──────────────────────────────────
                              if (!_isPlaying && !_isGameOver && !_isGameClear && _balls.isNotEmpty)
                                _buildStartHint(),
                              if (_isGameOver)   _buildGameOverOverlay(),
                              if (_isGameClear)  _buildGameClearOverlay(),
                            ],
                          ),
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
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A8A), Color(0xFFFF5252)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFC62828),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // 중앙 아기자기한 게임 타이틀 뱃지
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍬', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '레벨 $_level',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jua(
                        fontSize: 17,
                        color: KidsTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 목숨 (하트 ❤️)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: KidsTheme.borderDark, width: 2.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedOpacity(
                  opacity: i < _lives ? 1.0 : 0.25,
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    '❤️',
                    style: TextStyle(fontSize: i < _lives ? 16 : 13),
                  ),
                ),
              )),
            ),
          ),
          const SizedBox(width: 8),
          // ⭐ 몇 단계? (레벨 선택) 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _showLevelSelectDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE65100),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '몇 단계?',
                    style: GoogleFonts.jua(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 레벨(단계) 선택 모달 다이얼로그
  void _showLevelSelectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⭐ 몇 단계로 할까요? 🍬',
                    style: GoogleFonts.jua(
                      fontSize: 22,
                      color: KidsTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      _dialogLevelBtn(setModalState, 1, '1단계\n(쉬운 사탕)', '⭐'),
                      const SizedBox(width: 8),
                      _dialogLevelBtn(setModalState, 2, '2단계\n(달콤 사탕)', '⭐⭐'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dialogLevelBtn(setModalState, 3, '3단계\n(무지개 사탕)', '⭐⭐⭐'),
                      const SizedBox(width: 8),
                      _dialogLevelBtn(setModalState, 4, '4단계\n(도전 캔디)', '⭐⭐⭐⭐'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: KidsTheme.borderDark, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          '확인 👍',
                          style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogLevelBtn(
    StateSetter setModalState,
    int targetLevel,
    String label,
    String stars,
  ) {
    final bool isSelected = _level == targetLevel;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          setState(() {
            _level = targetLevel;
            _lives = 3;
            _score = 0;
            _initLevel();
          });
          setModalState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF3E0) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey.shade300,
              width: isSelected ? 3 : 1.5,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0xFFFFE0B2),
                      offset: Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(stars, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(
                  fontSize: 14,
                  color: isSelected ? const Color(0xFFE65100) : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          if (_isFireball)
            _ActiveItemChip(label: '🔥 파이어볼', secs: _fireballTimer, color: const Color(0xFFFF5722)),
          if (_isSlowBall)
            _ActiveItemChip(label: '🐢 슬로우', secs: _slowBallTimer, color: const Color(0xFF4CAF50)),
          if (_isWidePaddle)
            _ActiveItemChip(label: '↔️ 넓은패들', secs: _widePaddleTimer, color: const Color(0xFF00BCD4)),
        ],
      ),
    );
  }

  // ── Bricks ─────────────────────────────────────────────────────────────────

  Widget _buildBrick(Brick brick) {
    final hpRatio = brick.maxHp > 1 ? brick.hp / brick.maxHp : 1.0;
    final darken  = 1.0 - (1.0 - hpRatio) * 0.45;

    return Positioned(
      left:   brick.left,
      top:    brick.top,
      width:  brick.width,
      height: brick.height,
      child: Container(
        decoration: BoxDecoration(
          color: HSLColor.fromColor(brick.color)
              .withLightness((HSLColor.fromColor(brick.color).lightness * darken).clamp(0.0, 1.0))
              .toColor(),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: brick.color.withOpacity(0.6),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.25),
              Colors.transparent,
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(brick.emoji, style: const TextStyle(fontSize: 18)),
            ),
            // HP crack indicator
            if (brick.maxHp > 1)
              Positioned(
                right: 4, top: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(brick.maxHp, (i) => Container(
                    width: 5, height: 5,
                    margin: const EdgeInsets.only(left: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < brick.hp
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.2),
                    ),
                  )),
                ),
              ),
            // 아이템 드롭 예정 표시
            if (brick.dropItem != null && brick.hp <= 1)
              Positioned(
                left: 4, top: 4,
                child: Text(
                  DroppedItem(x: 0, y: 0, type: brick.dropItem!).emoji,
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Paddle ─────────────────────────────────────────────────────────────────

  Widget _buildPaddle() {
    final Color paddleColor = _isFireball
        ? const Color(0xFFFF5722)
        : _isSlowBall
            ? const Color(0xFF4CAF50)
            : _isWidePaddle
                ? const Color(0xFF00BCD4)
                : const Color(0xFFFFB300);

    return Positioned(
      left: _paddle!.x - _paddle!.width / 2,
      top:  _paddle!.y - _paddle!.height / 2,
      width:  _paddle!.width,
      height: _paddle!.height,
      child: Transform.scale(
        scale: _paddleScale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                paddleColor,
                paddleColor.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: paddleColor.withValues(alpha: 0.7),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Text('✨', style: TextStyle(fontSize: 12)),
          ),
        ),
      ),
    );
  }

  // ── Ball ───────────────────────────────────────────────────────────────────

  Widget _buildBall(Ball ball) {
    final String emoji = ball.isFireball ? '🔥' : '⚪';
    final Color glowColor = ball.isFireball
        ? const Color(0xFFFF5722)
        : Colors.lightBlueAccent;

    return Positioned(
      left: ball.x - ball.radius,
      top:  ball.y - ball.radius,
      width:  ball.radius * 2,
      height: ball.radius * 2,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.8),
              blurRadius: ball.isFireball ? 20 : 12,
              spreadRadius: ball.isFireball ? 4 : 2,
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: ball.radius * 1.4)),
        ),
      ),
    );
  }

  // ── Dropped item widget ────────────────────────────────────────────────────

  Widget _buildItem(DroppedItem item) {
    return Container(
      width: item.size,
      height: item.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: item.color.withOpacity(0.85),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(0.6),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  // ── Start hint ─────────────────────────────────────────────────────────────

  Widget _buildStartHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  'LEVEL $_level',
                  style: AppFonts.jua(fontSize: 30, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '화면을 터치해서 발사! 🎳',
                  style: AppFonts.jua(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overlays ───────────────────────────────────────────────────────────────

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3F2B96), Color(0xFFA8C0FF)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('💔', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 10),
              Text(
                '아쉬워요!',
                style: AppFonts.jua(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '다시 한 번 도전해볼까요? 💪',
                textAlign: TextAlign.center,
                style: AppFonts.jua(fontSize: 16, color: Colors.white.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  _startGame(_screenSize);
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: KidsTheme.borderDark, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFC62828),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔄', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          '다시 하기',
                          style: AppFonts.jua(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameClearOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1), Color(0xFFE8EAF6)],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(
                '참 잘했어요!',
                style: AppFonts.jua(
                  fontSize: 32,
                  color: const Color(0xFF8338EC),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '레벨 $_level 완성! 🌟',
                  style: AppFonts.jua(
                    fontSize: 16,
                    color: const Color(0xFFD81B60),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // 별 3개 반짝반짝
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('⭐', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 8),
                  Text('🌟', style: TextStyle(fontSize: 38)),
                  SizedBox(width: 8),
                  Text('⭐', style: TextStyle(fontSize: 28)),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  _nextLevel();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8338EC), Color(0xFFFF4081)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: KidsTheme.borderDark, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF4A148C),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🚀', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          '다음 레벨로!',
                          style: AppFonts.jua(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────



class _ActiveItemChip extends StatelessWidget {
  final String label;
  final double secs;
  final Color color;

  const _ActiveItemChip({required this.label, required this.secs, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        '$label ${secs.toStringAsFixed(1)}s',
        style: GoogleFonts.jua(fontSize: 11, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Painter — 아케이드 스타 & 파동 배경
// ─────────────────────────────────────────────────────────────────────────────

class _ArcadeBgPainter extends CustomPainter {
  final double time;
  _ArcadeBgPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 격자 (Grid) — subtle
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.8;
    const step = 36.0;
    for (double x = 0; x < w; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += step) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. 별빛 반짝임
    final starRng = Random(42);
    for (int i = 0; i < 55; i++) {
      final sx = starRng.nextDouble() * w;
      final sy = starRng.nextDouble() * h;
      final twinkle = (sin(time * (1.5 + i * 0.12) + i) * 0.5 + 0.5);
      final r = 1.0 + twinkle * 2.0;
      canvas.drawCircle(
        Offset(sx, sy),
        r,
        Paint()..color = Colors.white.withOpacity(0.2 + twinkle * 0.5),
      );
    }

    // 3. 무지개 파동 링 (중앙 아래)
    for (int i = 0; i < 4; i++) {
      final radius = 40.0 + i * 55.0 + (time * 30) % 55;
      final colors = [
        const Color(0xFF7C4DFF),
        const Color(0xFF2979FF),
        const Color(0xFF00BCD4),
        const Color(0xFF00E676),
      ];
      final opacity = (1.0 - (radius / 280)).clamp(0.0, 1.0) * 0.18;
      canvas.drawCircle(
        Offset(w / 2, h * 0.6),
        radius,
        Paint()
          ..color = colors[i % colors.length].withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // 4. 반짝이 파티클 (느리게 떠다니는 빛)
    final floatRng = Random(99);
    for (int i = 0; i < 18; i++) {
      final baseX = floatRng.nextDouble() * w;
      final baseY = floatRng.nextDouble() * h;
      final ox = sin(time * 0.5 + i) * 12;
      final oy = cos(time * 0.4 + i * 1.3) * 12;
      final bright = (sin(time * 1.2 + i * 2.1) * 0.5 + 0.5);
      final floatColors = [
        const Color(0xFFFFB300),
        const Color(0xFFFF6B9D),
        const Color(0xFF7C4DFF),
        const Color(0xFF00E5FF),
      ];
      canvas.drawCircle(
        Offset(baseX + ox, baseY + oy),
        2.5 + bright * 2.5,
        Paint()..color = floatColors[i % floatColors.length].withOpacity(0.15 + bright * 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_ArcadeBgPainter old) => old.time != time;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle + Score Popup Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<BrickParticle> particles;
  final List<ScorePopup> popups;

  _ParticlePainter({required this.particles, required this.popups});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }

    // Score popups — draw text
    for (final pop in popups) {
      final tp = TextPainter(
        text: TextSpan(
          text: pop.text,
          style: TextStyle(
            color: pop.color.withOpacity(pop.opacity.clamp(0.0, 1.0)),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pop.x - tp.width / 2, pop.y));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}
