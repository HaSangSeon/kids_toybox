import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/data/player_data_manager.dart';

class DinoJumpGame extends StatefulWidget {
  final String playerEmoji;
  const DinoJumpGame({super.key, this.playerEmoji = '🦖'});

  @override
  State<DinoJumpGame> createState() => _DinoJumpGameState();
}

class Obstacle {
  double x; // 0.0 to 1.0 (screen relative)
  final String emoji;
  final double size;
  bool passed = false;
  final double yOffset; // For flying obstacles like Pterodactyls

  Obstacle({
    required this.x,
    required this.emoji,
    required this.size,
    this.yOffset = 0.0,
  });
}

// ── 달릴 때 일어나는 먼지 파티클 ──────────────────────────────────────────
class DustParticle {
  double x; // offset from dino
  double y;
  double vx;
  double vy;
  double size;
  double opacity = 1.0;

  DustParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    opacity -= 2.0 * dt;
    if (opacity < 0) opacity = 0;
  }
}

class _DinoJumpGameState extends State<DinoJumpGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  int _bestScore = 0;

  // Dino state
  double _dinoY = 0; // 0 is ground, negative is up
  double _dinoVy = 0;
  final double _gravity = 2.8; // Snappier gravity
  final double _jumpForce = -0.80; // 초기 점프 impulse (짧게 탭)
  final double _jumpHoldForce = -1.8; // 길게 누를 때 추가 추진력 (초당)
  final double _jumpMaxHoldTime = 0.38; // 최대 홀드 시간 (초)
  bool _isJumping = false;
  bool _canDoubleJump = false; // 2단 점프 가능 여부
  bool _isPressing = false; // 현재 누르고 있는지
  double _pressHeldTime = 0.0; // 누른 시간 누적
  double _runningTime = 0.0;
  double _dinoScaleX = 1.0;
  double _dinoScaleY = 1.0;
  // 점프 파워 게이지 표시용
  double _jumpChargeDisplay = 0.0;

  // Scrolling offset for Parallax Background
  double _worldDistance = 0.0;

  // Obstacles
  final List<Obstacle> _obstacles = [];
  double _obstacleSpeed = 0.75;
  double _spawnTimer = 0;
  final Random _random = Random();

  // Particle list
  final List<DustParticle> _dustParticles = [];

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

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _dinoY = 0;
      _dinoVy = 0;
      _isJumping = false;
      _canDoubleJump = false;
      _isPressing = false;
      _pressHeldTime = 0.0;
      _jumpChargeDisplay = 0.0;
      _runningTime = 0.0;
      _worldDistance = 0.0;
      _obstacles.clear();
      _dustParticles.clear();
      _obstacleSpeed = 0.72;
      _spawnTimer = 0;
    });
    _lastElapsed = Duration.zero;
    _ticker.stop();
    _ticker.start();
  }

  void _onPressDown() {
    if (_isGameOver) return;
    if (!_isPlaying) {
      _startGame();
      return;
    }

    if (!_isJumping) {
      // 지상에서 점프 시작
      _dinoVy = _jumpForce;
      _isJumping = true;
      _canDoubleJump = true;
      _isPressing = true;
      _pressHeldTime = 0.0;
      _dinoScaleX = 1.2;
      _dinoScaleY = 0.7;
      AudioManager.instance.playJump();
      HapticFeedback.lightImpact();
    } else if (_canDoubleJump) {
      // 공중에서 2단 점프 (더 약한 힘)
      _dinoVy = _jumpForce * 0.72;
      _canDoubleJump = false;
      _isPressing = true;
      _pressHeldTime = 0.0;
      _dinoScaleX = 1.15;
      _dinoScaleY = 0.85;
      AudioManager.instance.playJump();
      HapticFeedback.mediumImpact();
      // 2단 점프 파티클 (공중 폭발)
      for (int i = 0; i < 6; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        _dustParticles.add(DustParticle(
          x: 0,
          y: -_dinoY * 200,
          vx: cos(angle) * (80 + _random.nextDouble() * 60),
          vy: sin(angle) * (80 + _random.nextDouble() * 60),
          size: 5 + _random.nextDouble() * 6,
        ));
      }
    }
  }

  void _onPressUp() {
    _isPressing = false;
  }

  void _onTick(Duration elapsed) {
    if (_isGameOver || !_isPlaying) return;

    final double dt =
        ((elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0)
            .clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    setState(() {
      _runningTime += dt;
      _worldDistance += _obstacleSpeed * dt;

      // Restoring scales gradually (squash and stretch)
      _dinoScaleX += (1.0 - _dinoScaleX) * 0.1;
      _dinoScaleY += (1.0 - _dinoScaleY) * 0.1;

      // 홀드 점프: 누르고 있는 동안 추가 위쪽 힘 적용 (시간이 지날수록 감소)
      if (_isPressing && _isJumping && _pressHeldTime < _jumpMaxHoldTime) {
        _pressHeldTime += dt;
        final holdRatio = 1.0 - (_pressHeldTime / _jumpMaxHoldTime);
        _dinoVy += _jumpHoldForce * holdRatio * dt;
        _jumpChargeDisplay = (_pressHeldTime / _jumpMaxHoldTime).clamp(0.0, 1.0);
      } else if (!_isPressing || _pressHeldTime >= _jumpMaxHoldTime) {
        _jumpChargeDisplay = 0.0;
      }

      // Update Dino physics
      _dinoY += _dinoVy * dt;
      _dinoVy += _gravity * dt;

      if (_dinoY >= 0) {
        if (_isJumping) {
          // Landing effect (squash)
          _dinoScaleX = 1.25;
          _dinoScaleY = 0.75;
          HapticFeedback.selectionClick();
        }
        _dinoY = 0;
        _dinoVy = 0;
        _isJumping = false;
        _canDoubleJump = false;
        _isPressing = false;
        _pressHeldTime = 0.0;
        _jumpChargeDisplay = 0.0;
      }

      // Stretch during mid-air jump
      if (_isJumping) {
        _dinoScaleX = 0.85;
        _dinoScaleY = 1.15;
      }

      // Speed scale
      _obstacleSpeed += 0.008 * dt;

      // Dust effect generation when on ground
      if (!_isJumping && _isPlaying) {
        if (_random.nextDouble() < 0.25) {
          _dustParticles.add(DustParticle(
            x: 0,
            y: 0,
            vx: -150 - _random.nextDouble() * 100,
            vy: -40 - _random.nextDouble() * 60,
            size: 6 + _random.nextDouble() * 8,
          ));
        }
      }

      // Update particles
      for (final p in _dustParticles) {
        p.update(dt);
      }
      _dustParticles.removeWhere((p) => p.opacity <= 0);

      // Spawn Obstacles
      _spawnTimer += dt;
      if (_spawnTimer > (2.0 / _obstacleSpeed) + _random.nextDouble() * 0.9) {
        _spawnTimer = 0;
        final r = _random.nextDouble();
        String emoji = '🌵';
        double size = 56;
        double yOffset = 0.0;

        if (r < 0.38) {
          emoji = '🌵'; // Cactus
          size = 58;
        } else if (r < 0.65) {
          emoji = '🪵'; // Fossil wood
          size = 54;
        } else if (r < 0.82) {
          emoji = '🥚'; // Dino egg!
          size = 48;
        } else {
          emoji = '🦅'; // Pterodactyl flying
          size = 50;
          yOffset = 50.0 + _random.nextDouble() * 40.0; // flies above ground
        }

        _obstacles.add(Obstacle(
          x: 1.2,
          emoji: emoji,
          size: size,
          yOffset: yOffset,
        ));
      }

      // Update Obstacles & Check Pass
      for (final obs in _obstacles) {
        obs.x -= _obstacleSpeed * dt;

        if (obs.x < 0.20 && !obs.passed) {
          obs.passed = true;
          _score += 10;
          if (_score > _bestScore) {
            _bestScore = _score;
          }
          AudioManager.instance.playChime();
          HapticFeedback.selectionClick();
        }
      }

      _obstacles.removeWhere((obs) => obs.x < -0.2);

      // Collision Detection
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;
      final double gameHeight = (screenHeight - 160).clamp(100.0, 1000.0);

      final double dinoCenterX = screenWidth * 0.22;
      final double dinoYBottom = -_dinoY * gameHeight;

      // Dino hitbox
      final double dinoMinX = dinoCenterX - 18.0;
      final double dinoMaxX = dinoCenterX + 18.0;
      final double dinoMinY = dinoYBottom;
      final double dinoMaxY = dinoYBottom + 58.0;

      for (final obs in _obstacles) {
        final double obsCenterX = obs.x * screenWidth;
        final double obsMinX = obsCenterX - 14.0;
        final double obsMaxX = obsCenterX + 14.0;
        final double obsMinY = obs.yOffset;
        final double obsMaxY = obs.yOffset + 44.0;

        final bool xOverlap = (dinoMinX < obsMaxX) && (dinoMaxX > obsMinX);
        final bool yOverlap = (dinoMinY < obsMaxY) && (dinoMaxY > obsMinY);

        if (xOverlap && yOverlap) {
          _gameOver();
          break;
        }
      }
    });
  }

  void _gameOver() {
    _ticker.stop();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });
    AudioManager.instance.playGameOver();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final String playerEmoji = widget.playerEmoji;

    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => _onPressDown(),
        onTapUp: (_) => _onPressUp(),
        onTapCancel: () => _onPressUp(),
        onPanStart: (_) => _onPressDown(),
        onPanEnd: (_) => _onPressUp(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Parallax Prehistoric Background ─────────────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _PrehistoricBackgroundPainter(
                  scrollOffset: _worldDistance,
                  time: _runningTime,
                  isGameOver: _isGameOver,
                ),
              ),
            ),

            // ── HUD: Score Board (Top Bar) ─────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
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
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: KidsTheme.borderDark, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0xFFCCB030),
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 5),
                            Text(
                              '$_score',
                              style: GoogleFonts.jua(
                                fontSize: 20,
                                color: KidsTheme.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Best Score Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB39DDB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KidsTheme.borderDark, width: 2.5),
                        ),
                        child: Text(
                          '🏆 최고: $_bestScore',
                          style: GoogleFonts.jua(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Dust Particles ───────────────────────────────────────────
            if (_isPlaying)
              Positioned(
                left: screenWidth * 0.22,
                bottom: 152,
                child: CustomPaint(
                  painter: _DustParticlePainter(_dustParticles),
                ),
              ),

            // ── Jump Charge Indicator ─────────────────────────────────────
            if (_isPlaying && _isJumping && _jumpChargeDisplay > 0.0)
              Positioned(
                left: screenWidth * 0.22 - 26,
                bottom: 210,
                child: SizedBox(
                  width: 52,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _canDoubleJump ? '💨' : '⚡',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _jumpChargeDisplay,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(
                              const Color(0xFF69F0AE),
                              const Color(0xFFFF6B6B),
                              _jumpChargeDisplay,
                            )!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Dino Character ───────────────────────────────────────────
            Positioned.fill(
              bottom: 145, // sits above ground line
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dinoLeft = constraints.maxWidth * 0.22 - 40;
                  final dinoBottom = -_dinoY * constraints.maxHeight - 10;
                  
                  // Running bounce animation
                  final double runBounce = (!_isJumping && _isPlaying && !_isGameOver)
                      ? (sin(_runningTime * 24).abs() * 7.0)
                      : (_isGameOver ? -14 : 0);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Dynamic Ground Shadow (shrinks & fades as dino jumps high)
                      Positioned(
                        left: dinoLeft + 10,
                        bottom: -4,
                        child: Opacity(
                          opacity: (1.0 - (-_dinoY * 2.5)).clamp(0.1, 0.7),
                          child: Transform.scale(
                            scaleX: (1.0 - (-_dinoY * 2.0)).clamp(0.3, 1.0),
                            scaleY: (1.0 - (-_dinoY * 2.0)).clamp(0.3, 1.0),
                            child: Container(
                              width: 60,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: const BorderRadius.all(Radius.elliptical(30, 7)),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Motion Ghost Trails (Speed Afterimages when running fast)
                      if (_isPlaying && !_isGameOver)
                        ...List.generate(2, (index) {
                          final trailOffset = (index + 1) * 16.0;
                          final trailOpacity = 0.25 - (index * 0.1);
                          return Positioned(
                            left: dinoLeft - trailOffset,
                            bottom: dinoBottom + runBounce,
                            child: Opacity(
                              opacity: trailOpacity.clamp(0.0, 1.0),
                              child: Transform.scale(
                                scaleX: _dinoScaleX * -0.9,
                                scaleY: _dinoScaleY * 0.9,
                                alignment: Alignment.center,
                                child: Text(
                                  playerEmoji,
                                  style: const TextStyle(fontSize: 78),
                                ),
                              ),
                            ),
                          );
                        }),

                      // Dynamic Main Dino Character
                      Positioned(
                        left: dinoLeft,
                        bottom: dinoBottom + runBounce,
                        child: Transform.scale(
                          scaleX: _dinoScaleX * -1.0 * (1.0 + (!_isJumping && _isPlaying ? sin(_runningTime * 28) * 0.06 : 0)), // Running elastic squash
                          scaleY: _dinoScaleY * (1.0 - (!_isJumping && _isPlaying ? sin(_runningTime * 28) * 0.06 : 0)),
                          alignment: Alignment.center,
                          child: Transform.rotate(
                            angle: _isGameOver
                                ? -1.35
                                : (_isJumping
                                    ? (_dinoVy * 0.35).clamp(-0.4, 0.4) // Leans up on launch, down on fall
                                    : (_isPlaying ? sin(_runningTime * 28) * 0.12 : 0)),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                Text(
                                  playerEmoji,
                                  style: const TextStyle(fontSize: 78),
                                ),
                                // Speed Wind Lines behind feet when running
                                if (!_isJumping && _isPlaying && !_isGameOver)
                                  const Positioned(
                                    bottom: 0,
                                    left: -18,
                                    child: Text('💨', style: TextStyle(fontSize: 28)),
                                  ),
                                // Rocket Booster / Air burst when jumping
                                if (_isJumping && _isPlaying)
                                  Positioned(
                                    bottom: -22,
                                    child: Text(
                                      _canDoubleJump ? '🔥' : '✨',
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                                // Double Jump Air Aura Burst
                                if (_isJumping && !_canDoubleJump)
                                  const Positioned(
                                    top: -10,
                                    child: Text('🌟', style: TextStyle(fontSize: 36)),
                                  ),
                                // Sweat drop when high speed
                                if (!_isJumping && _isPlaying && _obstacleSpeed > 0.85)
                                  const Positioned(
                                    top: -12,
                                    right: -10,
                                    child: Text('💦', style: TextStyle(fontSize: 26)),
                                  ),
                                // Game Over dizzy stars
                                if (_isGameOver)
                                  const Positioned(
                                    top: -28,
                                    right: -10,
                                    child: Text('💥', style: TextStyle(fontSize: 44)),
                                  ),
                                if (_isGameOver)
                                  const Positioned(
                                    top: -46,
                                    left: 8,
                                    child: Text('💫', style: TextStyle(fontSize: 34)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Obstacles
                      ..._obstacles.map((obs) {
                        // Flapping rotation for Pterodactyls
                        final double rotation = (obs.emoji == '🦅' && _isPlaying)
                            ? sin(_runningTime * 22) * 0.2
                            : 0.0;

                        return Positioned(
                          left: obs.x * constraints.maxWidth - (obs.size / 2),
                          bottom: obs.yOffset,
                          child: Transform.rotate(
                            angle: rotation,
                            child: Text(
                              obs.emoji,
                              style: TextStyle(fontSize: obs.size),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),

            // ── Tap to Start Overlay ──────────────────────────────────────
            if (!_isPlaying && !_isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.35),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: KidsTheme.borderDark, width: 3),
                          ),
                          child: Text(playerEmoji, style: const TextStyle(fontSize: 70)),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: KidsTheme.borderDark, width: 3),
                          ),
                          child: Text(
                            '화면을 터치해서 점프!',
                            style: GoogleFonts.jua(
                              fontSize: 26,
                              color: KidsTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Game Over Overlay ──────────────────────────────────────────
            if (_isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(color: Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9F1C).withValues(alpha: 0.25),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Crying Dino Header Icon Badge
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFFB74D), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text('😭', style: TextStyle(fontSize: 46)),
                          ),
                          const SizedBox(height: 12),
                          
                          // 3D Styled Title Text
                          Text(
                            '쿵! 부딪혔어요!',
                            style: GoogleFonts.jua(
                              fontSize: 30,
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

                          // Score Pastel Card Box
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
                                    '최종 점수',
                                    style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFE65100)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('⭐', style: TextStyle(fontSize: 26)),
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
                                if (_score >= _bestScore && _score > 0) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '🏆 최고 기록 달성! 🎉',
                                      style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 3D Glossy Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Exit Button (Red/Coral Glossy 3D)
                              GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                                      const SizedBox(width: 4),
                                      Text(
                                        '메인으로',
                                        style: GoogleFonts.jua(
                                          fontSize: 17,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Restart Button (Green Emerald Glossy 3D)
                              GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  _startGame();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '다시 달리기 🏃',
                                        style: GoogleFonts.jua(
                                          fontSize: 17,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 2),
                                          ],
                                        ),
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
          ],
        ),
      ),
    );
  }
}

// ── Parallax Prehistoric World Painter ───────────────────────────────────
class _PrehistoricBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final double time;
  final bool isGameOver;

  _PrehistoricBackgroundPainter({
    required this.scrollOffset,
    required this.time,
    required this.isGameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h - 150;

    // 1. Sky Gradient (Prehistoric sunrise vibe)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE1BEE7), // Purple sky
          Color(0xFFFFCC80), // Warm orange
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Glowing Sun
    final sunCenter = Offset(w * 0.78, h * 0.15);
    canvas.drawCircle(sunCenter, 44, Paint()..color = const Color(0xFFFFE082).withOpacity(0.4));
    canvas.drawCircle(sunCenter, 34, Paint()..color = const Color(0xFFFFD54F));

    // 3. Clouds (Layer 1 Parallax - Very Slow)
    final double cloudScroll = (scrollOffset * 25) % (w + 200);
    _drawCloud(canvas, Offset(w - cloudScroll, h * 0.08), 1.0);
    _drawCloud(canvas, Offset(w * 1.5 - cloudScroll, h * 0.14), 0.75);
    _drawCloud(canvas, Offset(w * 0.4 - cloudScroll, h * 0.05), 0.85);

    // 4. Distant Volcanoes (Layer 2 Parallax - Slow)
    final double volcanoScroll = (scrollOffset * 65) % (w * 1.5);
    _drawVolcano(canvas, Offset(w * 0.5 - volcanoScroll, groundY), 160, 150, true);
    _drawVolcano(canvas, Offset(w * 1.2 - volcanoScroll, groundY), 130, 110, false);

    // 5. Midground Hills and giant ferns (Layer 3 Parallax - Medium)
    final double hillScroll = (scrollOffset * 150) % (w * 1.2);
    _drawHill(canvas, Offset(w * 0.3 - hillScroll, groundY), 180, const Color(0xFF81C784));
    _drawHill(canvas, Offset(w * 0.9 - hillScroll, groundY), 240, const Color(0xFF66BB6A));
    _drawHill(canvas, Offset(w * 1.5 - hillScroll, groundY), 200, const Color(0xFF81C784));

    // Giant Prehistoric plants on midground
    _drawPalmTree(canvas, Offset(w * 0.15 - hillScroll, groundY), 1.1);
    _drawPalmTree(canvas, Offset(w * 0.75 - hillScroll, groundY), 0.95);
    _drawPalmTree(canvas, Offset(w * 1.35 - hillScroll, groundY), 1.25);

    // 6. Ground Area (Foreground - Direct scroll matching speed)
    final groundPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRect(Rect.fromLTRB(0, groundY, w, h), groundPaint);

    // Ground grass strip top
    final grassStripPaint = Paint()..color = const Color(0xFF7CB342);
    canvas.drawRect(Rect.fromLTRB(0, groundY, w, groundY + 12), grassStripPaint);

    // Stone texture / lines scrolling on the ground
    final double groundScroll = (scrollOffset * w) % 80.0;
    final linePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (double x = -80; x < w + 80; x += 80) {
      final curX = x - groundScroll;
      canvas.drawLine(Offset(curX, groundY + 25), Offset(curX - 15, groundY + 50), linePaint);
      canvas.drawCircle(Offset(curX + 30, groundY + 80), 4, Paint()..color = const Color(0xFF5D4037));
      canvas.drawCircle(Offset(curX + 60, groundY + 45), 3, Paint()..color = const Color(0xFF5D4037));
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    final radii = [24.0, 16.0, 18.0, 14.0];
    final offsets = [
      Offset.zero,
      const Offset(-28, 8),
      const Offset(26, 6),
      const Offset(-48, 14),
    ];
    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(
          center + offsets[i] * scale, radii[i] * scale, paint);
    }
  }

  void _drawVolcano(Canvas canvas, Offset base, double width, double height, bool active) {
    final peakY = base.dy - height;
    final leftX = base.dx - width / 2;
    final rightX = base.dx + width / 2;

    final path = Path()
      ..moveTo(leftX, base.dy)
      ..quadraticBezierTo(base.dx - width * 0.15, base.dy - height * 0.6, base.dx - width * 0.1, peakY)
      ..lineTo(base.dx + width * 0.1, peakY)
      ..quadraticBezierTo(base.dx + width * 0.15, base.dy - height * 0.6, rightX, base.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = const Color(0xFF78909C));

    // Lava crater top
    final craterPath = Path()
      ..moveTo(base.dx - width * 0.1, peakY)
      ..lineTo(base.dx + width * 0.1, peakY)
      ..quadraticBezierTo(base.dx, peakY + 12, base.dx - width * 0.1, peakY)
      ..close();
    canvas.drawPath(craterPath, Paint()..color = const Color(0xFFFF5722));

    // Flowing Lava
    if (active) {
      final lavaFlow = Path()
        ..moveTo(base.dx - 4, peakY + 2)
        ..lineTo(base.dx + 4, peakY + 2)
        ..lineTo(base.dx + 8, peakY + height * 0.45)
        ..quadraticBezierTo(base.dx, peakY + height * 0.52, base.dx - 8, peakY + height * 0.45)
        ..close();
      canvas.drawPath(lavaFlow, Paint()..color = const Color(0xFFFFB300));
      
      // Animated puffing smoke
      final double puffRadius = 15.0 + sin(time * 6.0).abs() * 5.0;
      canvas.drawCircle(
        Offset(base.dx, peakY - 20 - (time * 15.0) % 30.0),
        puffRadius * 0.7,
        Paint()..color = const Color(0xFFCFD8DC).withOpacity(0.4),
      );
    }
  }

  void _drawHill(Canvas canvas, Offset base, double width, Color color) {
    final path = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..quadraticBezierTo(base.dx, base.dy - width * 0.4, base.dx + width / 2, base.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawPalmTree(Canvas canvas, Offset base, double scale) {
    final trunkHeight = 90.0 * scale;
    final startX = base.dx;
    final startY = base.dy;
    final endX = base.dx - 12.0 * scale;
    final endY = base.dy - trunkHeight;

    // Curved trunk
    final trunkPath = Path()
      ..moveTo(startX - 6 * scale, startY)
      ..quadraticBezierTo(startX - 2 * scale, startY - trunkHeight * 0.5, endX - 4 * scale, endY)
      ..lineTo(endX + 4 * scale, endY)
      ..quadraticBezierTo(startX + 6 * scale, startY - trunkHeight * 0.5, startX + 6 * scale, startY)
      ..close();
    canvas.drawPath(trunkPath, Paint()..color = const Color(0xFF8D6E63));

    // Palm leaves (fern style)
    final leafPaint = Paint()..color = const Color(0xFF2E7D32);
    final center = Offset(endX, endY);
    for (int i = 0; i < 5; i++) {
      final angle = (i * pi / 4) - pi * 0.25;
      final leafEndX = center.dx + cos(angle) * 36 * scale;
      final leafEndY = center.dy + sin(angle) * 24 * scale;

      final leafPath = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
            (center.dx + leafEndX) / 2 - 8 * scale, (center.dy + leafEndY) / 2 + 10 * scale, leafEndX, leafEndY)
        ..quadraticBezierTo(
            (center.dx + leafEndX) / 2 + 8 * scale, (center.dy + leafEndY) / 2 - 8 * scale, center.dx, center.dy)
        ..close();
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(_PrehistoricBackgroundPainter old) =>
      old.scrollOffset != scrollOffset || old.time != time || old.isGameOver != isGameOver;
}

// ── Dust Particle Painter ──────────────────────────────────────────────
class _DustParticlePainter extends CustomPainter {
  final List<DustParticle> particles;

  _DustParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = const Color(0xFFD7CCC8).withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_DustParticlePainter old) => true;
}
