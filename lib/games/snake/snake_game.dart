import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';

// ─── Data & Constants ───────────────────────────────────────────────────────
const double kBoardCols = 15.0;
const double kBoardRows = 20.0;

enum Direction { up, down, left, right }

class SmoothFood {
  Offset pos;
  String emoji;
  int points;
  bool isStar;

  SmoothFood({
    required this.pos,
    required this.emoji,
    required this.points,
    this.isStar = false,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.size = 8.0,
    this.opacity = 1.0,
  });
}

class Firefly {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double phase;

  Firefly({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.phase,
  });
}

// ─── 60FPS Fluid Physics High-UX Snake Game ──────────────────────────────────
class SnakeGame extends StatefulWidget {
  final String playerSkin;

  const SnakeGame({
    super.key,
    this.playerSkin = '🐛',
  });

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late ConfettiController _confettiController;

  int _level = 1;
  int _score = 0;
  int _highScore = 0;
  int _targetScore = 150;
  bool _isGameOver = false;
  bool _isGameClear = false;
  bool _isPaused = false;

  // 60FPS Smooth Snake Physics State
  Offset _headPos = const Offset(7.5, 12.0);
  double _currentAngle = -pi / 2; // Face UP initially
  double _targetAngle = -pi / 2;
  double _speed = 4.2; // Grid units / sec

  int _targetSegmentCount = 6;
  final List<Offset> _pathHistory = [];
  final List<Offset> _segmentPositions = [];

  // Foods
  SmoothFood? _normalFood;
  SmoothFood? _starFood;
  double _starTimer = 0.0;
  double _bounceAnim = 0.0;

  // Effects & Magical Fireflies
  final List<Particle> _particles = [];
  final List<Firefly> _fireflies = [];
  final Random _rng = Random();
  double _lastTickTime = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Generate subtle glowing ambient background fireflies
    for (int i = 0; i < 14; i++) {
      _fireflies.add(Firefly(
        x: _rng.nextDouble() * kBoardCols,
        y: _rng.nextDouble() * kBoardRows,
        vx: (_rng.nextDouble() - 0.5) * 0.3,
        vy: (_rng.nextDouble() - 0.5) * 0.3,
        radius: _rng.nextDouble() * 2.5 + 1.5,
        phase: _rng.nextDouble() * 2 * pi,
      ));
    }

    _initLevel(_level);

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initLevel(int level) {
    _targetScore = 120 + (level - 1) * 80;
    _speed = 4.2 + (level - 1) * 0.4;
    _targetSegmentCount = 6;

    _headPos = const Offset(7.5, 14.0);
    _currentAngle = -pi / 2;
    _targetAngle = -pi / 2;

    _pathHistory.clear();
    for (int i = 0; i < 300; i++) {
      _pathHistory.add(Offset(7.5, 14.0 + (i * 0.05)));
    }
    _updateSegmentPositions();

    _isGameOver = false;
    _isGameClear = false;
    _isPaused = false;
    _starFood = null;
    _starTimer = 0.0;

    _spawnNormalFood();
  }

  void _spawnNormalFood() {
    final margin = 1.5;
    final rx = margin + _rng.nextDouble() * (kBoardCols - 2 * margin);
    final ry = margin + _rng.nextDouble() * (kBoardRows - 2 * margin);

    final fruitEmojis = ['🍎', '🍓', '🍇', '🍉', '🍊', '🍌', '🍒'];
    final emoji = fruitEmojis[_rng.nextInt(fruitEmojis.length)];

    _normalFood = SmoothFood(
      pos: Offset(rx, ry),
      emoji: emoji,
      points: 10,
    );
  }

  void _spawnStarFood() {
    final margin = 1.8;
    final rx = margin + _rng.nextDouble() * (kBoardCols - 2 * margin);
    final ry = margin + _rng.nextDouble() * (kBoardRows - 2 * margin);

    _starFood = SmoothFood(
      pos: Offset(rx, ry),
      emoji: '⭐',
      points: 50,
      isStar: true,
    );
    _starTimer = 6.0;
  }

  // ── 60FPS Main Physics & FX Loop ─────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (_isGameOver || _isGameClear || _isPaused) return;

    final double currentTime = elapsed.inMilliseconds / 1000.0;
    if (_lastTickTime == 0) {
      _lastTickTime = currentTime;
      return;
    }
    final double dt = (currentTime - _lastTickTime).clamp(0.001, 0.05);
    _lastTickTime = currentTime;

    setState(() {
      _bounceAnim += dt * 4.0;
      _updateFireflies(dt);
      _updatePhysics(dt);
      _updateParticles(dt);
    });
  }

  void _updateFireflies(double dt) {
    for (var f in _fireflies) {
      f.x += f.vx * dt;
      f.y += f.vy * dt;
      f.phase += dt * 2.0;

      if (f.x < 0) f.x = kBoardCols;
      if (f.x > kBoardCols) f.x = 0;
      if (f.y < 0) f.y = kBoardRows;
      if (f.y > kBoardRows) f.y = 0;
    }
  }

  void _updatePhysics(double dt) {
    // 1. Smooth Steer Turning (Lerp angle)
    double diff = _targetAngle - _currentAngle;
    while (diff < -pi) {
      diff += 2 * pi;
    }
    while (diff > pi) {
      diff -= 2 * pi;
    }
    _currentAngle += diff * min(1.0, 12.0 * dt);

    // 2. Advance Head Position
    final dx = cos(_currentAngle) * _speed * dt;
    final dy = sin(_currentAngle) * _speed * dt;
    _headPos = Offset(_headPos.dx + dx, _headPos.dy + dy);

    // Record Path History
    _pathHistory.insert(0, _headPos);
    if (_pathHistory.length > 500) {
      _pathHistory.removeLast();
    }

    // 3. Compute Segment Positions Along Path History
    _updateSegmentPositions();

    // 4. Particle Trail behind tail
    if (_segmentPositions.isNotEmpty && _rng.nextDouble() < 0.4) {
      final tail = _segmentPositions.last;
      _particles.add(Particle(
        x: tail.dx,
        y: tail.dy,
        vx: (_rng.nextDouble() - 0.5) * 0.8,
        vy: (_rng.nextDouble() - 0.5) * 0.8,
        color: const Color(0xFF6EE7B7),
        size: _rng.nextDouble() * 4 + 2,
        opacity: 0.8,
      ));
    }

    // 5. Star Timer Update
    if (_starFood != null) {
      _starTimer -= dt;
      if (_starTimer <= 0) {
        _starFood = null;
      }
    }

    // 6. Check Wall Collision
    const wallMargin = 0.35;
    if (_headPos.dx < wallMargin ||
        _headPos.dx > (kBoardCols - wallMargin) ||
        _headPos.dy < wallMargin ||
        _headPos.dy > (kBoardRows - wallMargin)) {
      _handleGameOver();
      return;
    }

    // 7. Check Self Collision (Head to Body Segments)
    for (int i = 4; i < _segmentPositions.length; i++) {
      final dist = (_headPos - _segmentPositions[i]).distance;
      if (dist < 0.55) {
        _handleGameOver();
        return;
      }
    }

    // 8. Check Food Collisions
    if (_normalFood != null) {
      final dist = (_headPos - _normalFood!.pos).distance;
      if (dist < 0.85) {
        _score += _normalFood!.points;
        if (_score > _highScore) _highScore = _score;
        _targetSegmentCount += 2;
        AudioManager.instance.playPop();
        _spawnParticles(_normalFood!.pos.dx, _normalFood!.pos.dy, const Color(0xFFFDE047), 14);
        _spawnNormalFood();

        if (_starFood == null && _rng.nextDouble() < 0.3) {
          _spawnStarFood();
        }
        _checkVictory();
      }
    }

    if (_starFood != null) {
      final dist = (_headPos - _starFood!.pos).distance;
      if (dist < 0.95) {
        _score += _starFood!.points;
        if (_score > _highScore) _highScore = _score;
        _targetSegmentCount += 3;
        AudioManager.instance.playSuccess();
        _spawnParticles(_starFood!.pos.dx, _starFood!.pos.dy, const Color(0xFFFFD700), 22);
        _starFood = null;
        _checkVictory();
      }
    }
  }

  void _updateSegmentPositions() {
    _segmentPositions.clear();
    if (_pathHistory.isEmpty) return;

    const double segmentSpacing = 0.5;
    double currentDistAccum = 0.0;
    _segmentPositions.add(_pathHistory.first);

    for (int i = 1; i < _pathHistory.length; i++) {
      final stepDist = (_pathHistory[i] - _pathHistory[i - 1]).distance;
      currentDistAccum += stepDist;

      if (currentDistAccum >= segmentSpacing) {
        _segmentPositions.add(_pathHistory[i]);
        currentDistAccum -= segmentSpacing;
        if (_segmentPositions.length >= _targetSegmentCount) break;
      }
    }
  }

  void _handleGameOver() {
    _isGameOver = true;
    AudioManager.instance.playDamage();
    _spawnParticles(_headPos.dx, _headPos.dy, const Color(0xFFEF4444), 24);
  }

  void _checkVictory() {
    if (_score >= _targetScore) {
      _isGameClear = true;
      _confettiController.play();
      AudioManager.instance.playSuccess();
      PlayerDataManager.instance.addStarCoin(2);
    }
  }

  void _steerTowardsTarget(Offset targetPos, double boardWidth, double boardHeight) {
    final cellW = boardWidth / kBoardCols;
    final cellH = boardHeight / kBoardRows;

    final targetGridX = targetPos.dx / cellW;
    final targetGridY = targetPos.dy / cellH;

    final dx = targetGridX - _headPos.dx;
    final dy = targetGridY - _headPos.dy;

    if (dx.abs() + dy.abs() > 0.3) {
      _targetAngle = atan2(dy, dx);
      AudioManager.instance.playClick();
    }
  }

  void _setDirection(Direction d) {
    double angle = 0;
    switch (d) {
      case Direction.right: angle = 0; break;
      case Direction.down:  angle = pi / 2; break;
      case Direction.left:  angle = pi; break;
      case Direction.up:    angle = -pi / 2; break;
    }

    double diff = angle - _currentAngle;
    while (diff < -pi) {
      diff += 2 * pi;
    }
    while (diff > pi) {
      diff -= 2 * pi;
    }
    if (diff.abs() > 2.8) return;

    AudioManager.instance.playClick();
    _targetAngle = angle;
  }

  void _spawnParticles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 4 + 1;
      _particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        size: _rng.nextDouble() * 6 + 4,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.opacity -= dt * 1.5;
      if (p.opacity <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  // ── UI Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
            _setDirection(Direction.up);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
            _setDirection(Direction.down);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            _setDirection(Direction.left);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            _setDirection(Direction.right);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF06231A), // Deep Garden Night
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF043428),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: const Color(0xFF34D399), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.5),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Builder(
                          builder: (boardContext) {
                            return GestureDetector(
                              onTapDown: (details) {
                                final RenderBox? box = boardContext.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                _steerTowardsTarget(box.globalToLocal(details.globalPosition), box.size.width, box.size.height);
                              },
                              onPanUpdate: (details) {
                                final RenderBox? box = boardContext.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                _steerTowardsTarget(box.globalToLocal(details.globalPosition), box.size.width, box.size.height);
                              },
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _CleanHighUXBoardPainter(
                                  headPos: _headPos,
                                  angle: _currentAngle,
                                  segments: _segmentPositions,
                                  playerSkin: widget.playerSkin,
                                  normalFood: _normalFood,
                                  starFood: _starFood,
                                  particles: _particles,
                                  fireflies: _fireflies,
                                  bounceAnim: _bounceAnim,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Confetti Overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.green, Colors.yellow, Colors.pink, Colors.cyan],
                ),
              ),

              // Pause Overlay
              if (_isPaused) _buildPauseModal(),

              // Victory Modal
              if (_isGameClear) _buildVictoryModal(),

              // Game Over Modal
              if (_isGameOver) _buildGameOverModal(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Bar ───────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  AudioManager.instance.playClick();
                  Navigator.pop(context);
                },
              ),
              Text(
                '✨ 꿈틀꿈틀 지렁이 ✨',
                style: GoogleFonts.jua(
                  fontSize: 22,
                  color: const Color(0xFF6EE7B7),
                ),
              ),
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() => _isPaused = !_isPaused);
                },
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('점수: $_score점', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('STAGE $_level (목표: $_targetScore)', style: GoogleFonts.jua(fontSize: 13, color: Colors.white)),
                ),
                Text('길이: ${_segmentPositions.length}', style: GoogleFonts.jua(fontSize: 16, color: const Color(0xFF6EE7B7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Modals ───────────────────────────────────────────────────────────────
  Widget _buildPauseModal() {
    return Container(
      color: const Color(0xB3000000),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸️ 일시 정지', style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KidsTheme.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => setState(() => _isPaused = false),
                child: Text('계속하기 ▶️', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryModal() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              Text('STAGE $_level 클리어!', style: GoogleFonts.jua(fontSize: 32, color: KidsTheme.orange)),
              const SizedBox(height: 8),
              Text('과일을 맛있게 찾아 먹었어요! 🎯+5', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidsTheme.yellow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => setState(() => _initLevel(_level)),
                    child: Text('다시하기 🔄', style: GoogleFonts.jua(color: KidsTheme.textDark)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidsTheme.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      setState(() {
                        _level++;
                        _initLevel(_level);
                      });
                    },
                    child: Text('다음 단계 ▶️', style: GoogleFonts.jua(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverModal() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥', style: TextStyle(fontSize: 60)),
              Text('아쉬워요!', style: GoogleFonts.jua(fontSize: 30, color: Colors.purple)),
              const SizedBox(height: 8),
              Text('최종 점수: $_score점 (최대 길이: ${_segmentPositions.length})', style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      AudioManager.instance.playClick();
                      Navigator.pop(context);
                    },
                    child: Text('나가기 🏠', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KidsTheme.purple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () => setState(() => _initLevel(_level)),
                    child: Text('다시 도전 🚀', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Clean High-UX Board Painter (Zero Confusion) ─────────────────────────────
class _CleanHighUXBoardPainter extends CustomPainter {
  final Offset headPos;
  final double angle;
  final List<Offset> segments;
  final String playerSkin;
  final SmoothFood? normalFood;
  final SmoothFood? starFood;
  final List<Particle> particles;
  final List<Firefly> fireflies;
  final double bounceAnim;

  _CleanHighUXBoardPainter({
    required this.headPos,
    required this.angle,
    required this.segments,
    required this.playerSkin,
    required this.normalFood,
    required this.starFood,
    required this.particles,
    required this.fireflies,
    required this.bounceAnim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / kBoardCols;
    final cellH = size.height / kBoardRows;

    // 1. Clean Lawn Background (No confusing background emojis!)
    final bgGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF09362A), Color(0xFF032219)],
    ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, Paint()..shader = bgGradient);

    // Subtle lawn tiles
    final tilePaint1 = Paint()..color = const Color(0xFF0B4636).withValues(alpha: 0.35);
    final tilePaint2 = Paint()..color = const Color(0xFF052F24).withValues(alpha: 0.25);

    for (int r = 0; r < kBoardRows.toInt(); r++) {
      for (int c = 0; c < kBoardCols.toInt(); c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        final rRect = RRect.fromRectAndRadius(rect.deflate(1.2), const Radius.circular(8));
        if ((r + c) % 2 == 1) {
          canvas.drawRRect(rRect, tilePaint1);
        } else {
          canvas.drawRRect(rRect, tilePaint2);
        }
      }
    }

    // 2. Subtle Ambient Glow Fireflies
    for (var f in fireflies) {
      final fx = f.x * cellW;
      final fy = f.y * cellH;
      final opacity = 0.25 + 0.25 * sin(f.phase);

      canvas.drawCircle(
        Offset(fx, fy),
        f.radius + 3,
        Paint()..color = const Color(0xFF34D399).withValues(alpha: opacity * 0.3),
      );
      canvas.drawCircle(
        Offset(fx, fy),
        f.radius,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }

    // 3. Draw Particles
    for (var p in particles) {
      final pPaint = Paint()..color = p.color.withValues(alpha: p.opacity);
      canvas.drawCircle(Offset(p.x * cellW, p.y * cellH), p.size, pPaint);
    }

    // 4. Highly Highlighted Food Items (THE ONLY EMOJIS ON THE BOARD!)
    if (normalFood != null) {
      final fx = normalFood!.pos.dx * cellW;
      final fy = (normalFood!.pos.dy + 0.08 * sin(bounceAnim * 2.5)) * cellH;

      // Bright Golden Target Spotlight Pedestal Ring
      final double ringRadius = min(cellW, cellH) * (0.55 + 0.05 * sin(bounceAnim * 3.0));
      canvas.drawCircle(
        Offset(fx, fy),
        ringRadius + 4,
        Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        Offset(fx, fy),
        ringRadius,
        Paint()
          ..color = const Color(0xFFFDE047).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Target Emoji
      final textPainter = TextPainter(
        text: TextSpan(text: normalFood!.emoji, style: TextStyle(fontSize: min(cellW, cellH) * 0.95)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(fx - textPainter.width / 2, fy - textPainter.height / 2));
    }

    if (starFood != null) {
      final fx = starFood!.pos.dx * cellW;
      final fy = (starFood!.pos.dy + 0.1 * sin(bounceAnim * 3.5)) * cellH;

      // Golden Star Glowing Target Pedestal
      canvas.drawCircle(
        Offset(fx, fy),
        min(cellW, cellH) * (0.65 + 0.08 * sin(bounceAnim * 4.0)),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.45),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: starFood!.emoji, style: TextStyle(fontSize: min(cellW, cellH) * 1.05)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(fx - textPainter.width / 2, fy - textPainter.height / 2));
    }

    // 5. Draw Smooth Fluid Snake Body Segments
    if (segments.isNotEmpty) {
      final int n = segments.length;
      for (int i = n - 1; i >= 1; i--) {
        final seg = segments[i];
        final sx = seg.dx * cellW;
        final sy = seg.dy * cellH;

        final double ratio = i / n;
        final double radius = min(cellW, cellH) * (0.42 - (ratio * 0.12));

        // Body segment fill & border
        final segPaint = Paint()
          ..color = Color.lerp(const Color(0xFF10B981), const Color(0xFF047857), ratio)!;
        final borderPaint = Paint()
          ..color = const Color(0xFFA7F3D0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(Offset(sx, sy), radius + 2, Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.3));
        canvas.drawCircle(Offset(sx, sy), radius, segPaint);
        canvas.drawCircle(Offset(sx, sy), radius, borderPaint);
      }
    }

    // 6. Draw Smooth Fluid Snake Head
    final hx = headPos.dx * cellW;
    final hy = headPos.dy * cellH;
    final headRadius = min(cellW, cellH) * 0.46;

    if (playerSkin == '🐛' || playerSkin == '🐍') {
      canvas.drawCircle(
        Offset(hx, hy),
        headRadius + 3.5,
        Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.45),
      );

      final headPaint = Paint()..color = const Color(0xFF059669);
      final borderPaint = Paint()..color = const Color(0xFFA7F3D0)..style = PaintingStyle.stroke..strokeWidth = 2.5;

      canvas.drawCircle(Offset(hx, hy), headRadius, headPaint);
      canvas.drawCircle(Offset(hx, hy), headRadius, borderPaint);

      // Rotating Eyes
      final eyeOffsetDistance = headRadius * 0.45;
      final eyeR = headRadius * 0.3;
      final pupilR = eyeR * 0.5;

      final eyeAngleLeft = angle - 0.4;
      final eyeAngleRight = angle + 0.4;

      final leftEye = Offset(hx + cos(eyeAngleLeft) * eyeOffsetDistance, hy + sin(eyeAngleLeft) * eyeOffsetDistance);
      final rightEye = Offset(hx + cos(eyeAngleRight) * eyeOffsetDistance, hy + sin(eyeAngleRight) * eyeOffsetDistance);

      final whitePaint = Paint()..color = Colors.white;
      final pupilPaint = Paint()..color = const Color(0xFF064E3B);

      canvas.drawCircle(leftEye, eyeR, whitePaint);
      canvas.drawCircle(rightEye, eyeR, whitePaint);

      final pupilDx = cos(angle) * (eyeR * 0.3);
      final pupilDy = sin(angle) * (eyeR * 0.3);

      canvas.drawCircle(leftEye + Offset(pupilDx, pupilDy), pupilR, pupilPaint);
      canvas.drawCircle(rightEye + Offset(pupilDx, pupilDy), pupilR, pupilPaint);
    } else {
      _drawEmojiCell(canvas, headPos, playerSkin, cellW, cellH);
    }
  }

  void _drawEmojiCell(Canvas canvas, Offset pos, String emoji, double cellW, double cellH) {
    final cx = pos.dx * cellW;
    final cy = pos.dy * cellH;
    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: min(cellW, cellH) * 0.9)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(_CleanHighUXBoardPainter old) => true;
}
