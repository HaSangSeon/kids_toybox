import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

// ── 블록 모델 ──
class _Block {
  double x, y, width;
  final double height;
  final Color color;
  final String emoji;

  _Block({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.emoji,
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

// ── 파티클 ──
class _Particle {
  double x, y, vx, vy, life, size;
  Color color;
  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life, required this.size});
}

// ── 점수 팝업 ──
class _ScorePopup {
  double x, y, life;
  String text;
  Color color;
  _ScorePopup({required this.x, required this.y, required this.text, required this.color, required this.life});
}

// ════════════════════════════════════════════
class TowerBuilderGame extends StatefulWidget {
  const TowerBuilderGame({super.key});
  @override
  State<TowerBuilderGame> createState() => _TowerBuilderGameState();
}

class _TowerBuilderGameState extends State<TowerBuilderGame>
    with TickerProviderStateMixin {
  // 물리
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // 게임 상태
  bool _started = false;
  bool _isGameOver = false;
  int _score = 0;
  int _combo = 0;
  int _level = 1;
  int _bestScore = 0;
  Size _screenSize = Size.zero;

  // 블록
  static const double _blockH = 44.0;
  static const double _baseW = 200.0;
  late double _blockW;

  final List<_Block> _tower = [];
  _Block? _movingBlock;

  // 스윙
  double _swingX = 0.0;   // 현재 X (픽셀)
  double _swingDir = 1.0;
  double _swingSpeed = 170.0;

  // 이펙트
  final List<_Particle> _particles = [];
  final List<_ScorePopup> _popups = [];


  // 블록 이모지
  static const _emojis = ['🍎','⭐','🌸','🎈','🍭','🎯','🏆','🦄','🌈','💎'];
  final _rng = Random();

  // 배경 그라데이션 (레벨별)
  static const _bgColors = [
    [Color(0xFF74b9ff), Color(0xFFdfe6e9)],  // 하늘
    [Color(0xFF55efc4), Color(0xFF74b9ff)],  // 민트
    [Color(0xFFfdcb6e), Color(0xFFe17055)],  // 노을
    [Color(0xFFa29bfe), Color(0xFF6c5ce7)],  // 보라
    [Color(0xFFfd79a8), Color(0xFFe84393)],  // 핑크
  ];

  List<Color> get _bg => _bgColors[(_level - 1).clamp(0, _bgColors.length - 1)];

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

  // ── 게임 시작 ──
  void _startGame() {
    if (_screenSize == Size.zero) return;
    _blockW = _baseW;
    _score = 0;
    _combo = 0;
    _level = 1;
    _isGameOver = false;
    _started = true;
    _swingSpeed = 170.0;
    _tower.clear();
    _particles.clear();
    _popups.clear();

    // 베이스 블록
    _tower.add(_Block(
      x: _screenSize.width / 2 - _baseW * 0.75,
      y: _screenSize.height - _blockH - 30,
      width: _baseW * 1.5,
      height: _blockH,
      color: const Color(0xFF636e72),
      emoji: '🏠',
    ));

    _spawnMovingBlock();
    if (!_ticker.isTicking) _ticker.start();
    setState(() {});
  }

  void _spawnMovingBlock() {
    // 이동 블록은 화면 왼쪽 밖에서 시작, 탑 바로 위 높이
    final topBlock = _tower.last;
    final blockY = topBlock.y - _blockH;
    _swingX = -_blockW;
    _swingDir = 1.0;
    _movingBlock = _Block(
      x: _swingX,
      y: blockY,
      width: _blockW,
      height: _blockH,
      color: _randomColor(),
      emoji: _emojis[_rng.nextInt(_emojis.length)],
    );
  }

  Color _randomColor() {
    const colors = [
      Color(0xFFe17055), Color(0xFFfdcb6e), Color(0xFF00b894),
      Color(0xFF0984e3), Color(0xFF6c5ce7), Color(0xFFe84393),
      Color(0xFF00cec9), Color(0xFFd63031),
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  // ── 탭 → 블록 놓기 ──
  void _onTap() {
    if (_isGameOver || !_started) return;
    if (_movingBlock == null) return;

    final moving = _movingBlock!;
    final top = _tower.last;

    // 겹침 계산
    final leftOverlap = max(moving.x, top.x);
    final rightOverlap = min(moving.x + moving.width, top.x + top.width);
    final overlapW = rightOverlap - leftOverlap;

    if (overlapW <= 0) {
      // 완전 미스 → 라이프 없는 버전: 그냥 게임오버
      _onMiss();
      return;
    }

    // 퍼펙트 판정 (80% 이상 겹침)
    final perfectThreshold = min(moving.width, top.width) * 0.80;
    final isPerfect = overlapW >= perfectThreshold;

    // 블록 크기 줄이기 (삐져나온 부분 잘라냄)
    final newWidth = isPerfect ? min(moving.width, top.width) : overlapW;
    final newX = leftOverlap;

    // 탑에 추가
    _tower.add(_Block(
      x: newX,
      y: moving.y,
      width: newWidth,
      height: _blockH,
      color: moving.color,
      emoji: moving.emoji,
    ));
    _movingBlock = null;

    // 점수
    _combo++;
    int earned = 10;
    String popText = '+10';
    Color popColor = KidsTheme.blue;

    if (isPerfect) {
      earned = 30 + _combo * 2;
      popText = '✨ 퍼펙트! +$earned';
      popColor = const Color(0xFFfdcb6e);
      AudioManager.instance.playSuccess();
      HapticFeedback.mediumImpact();
      _spawnParticles(newX + newWidth / 2, moving.y, 20, moving.color);
    } else {
      earned = 10 + _combo;
      popText = '+$earned';
      popColor = KidsTheme.green;
      AudioManager.instance.playThud();
      HapticFeedback.selectionClick();
      _spawnParticles(newX + newWidth / 2, moving.y, 8, moving.color);
    }

    setState(() {
      _score += earned;
      _blockW = newWidth; // 다음 블록도 같은 너비

      // 레벨업 (5개마다 조금씩 어려워짐)
      if (_tower.length % 5 == 0) {
        _level++;
        _swingSpeed = min(_swingSpeed + 40, 500);
        _blockW = max(_blockW * 0.9, 80.0); // 블록도 조금씩 좁아짐
      }

      _popups.add(_ScorePopup(
        x: newX + newWidth / 2 - 40,
        y: moving.y - 30,
        text: popText,
        color: popColor,
        life: 1.0,
      ));

      // 탑이 너무 높으면 전체를 아래로 밀기
      final topY = _tower.last.y;
      if (topY < _screenSize.height * 0.35) {
        final shift = _screenSize.height * 0.15;
        for (final b in _tower) { b.y += shift; }
      }
    });


    // 다음 블록 예약
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !_isGameOver) {
        setState(() => _spawnMovingBlock());
      }
    });
  }

  void _onMiss() {
    AudioManager.instance.playDamage();
    HapticFeedback.heavyImpact();
    setState(() {
      _isGameOver = true;
      if (_score > _bestScore) _bestScore = _score;
      _combo = 0;
    });
  }

  void _spawnParticles(double cx, double cy, int count, Color color) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = _rng.nextDouble() * 160 + 60;
      _particles.add(_Particle(
        x: cx, y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 60,
        color: color,
        size: _rng.nextDouble() * 8 + 4,
        life: _rng.nextDouble() * 0.5 + 0.5,
      ));
    }
  }

  // ── 게임 루프 ──
  void _onTick(Duration elapsed) {
    if (!_started || _isGameOver || _screenSize == Size.zero) return;
    if (_lastTime == Duration.zero) { _lastTime = elapsed; return; }

    final dt = (elapsed - _lastTime).inMicroseconds / 1_000_000.0;
    _lastTime = elapsed;
    if (dt > 0.1) return;

    setState(() {
      // 이동 블록 스윙
      if (_movingBlock != null) {
        _swingX += _swingSpeed * _swingDir * dt;
        // 화면 끝에 닿으면 방향 반전
        if (_swingX + _movingBlock!.width > _screenSize.width + 20) {
          _swingDir = -1.0;
        } else if (_swingX < -20) {
          _swingDir = 1.0;
        }
        _movingBlock!.x = _swingX;
      }

      // 파티클
      for (final p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 250 * dt;
        p.life -= dt * 1.5;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // 점수 팝업
      for (final p in _popups) {
        p.y -= 55 * dt;
        p.life -= dt * 1.2;
      }
      _popups.removeWhere((p) => p.life <= 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) => _started ? _onTap() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _bg,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // 배경 구름 장식
                _buildBgDecorations(),

                Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildGameArea()),
                  ],
                ),

                if (!_started) _buildStartOverlay(),
                if (_isGameOver) _buildGameOverOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 배경 장식 ──
  Widget _buildBgDecorations() {
    return const Stack(
      children: [
        Positioned(top: 80, left: 20, child: Text('☁️', style: TextStyle(fontSize: 40, color: Colors.white70))),
        Positioned(top: 120, right: 30, child: Text('☁️', style: TextStyle(fontSize: 28, color: Colors.white60))),
        Positioned(top: 200, left: 80, child: Text('⭐', style: TextStyle(fontSize: 20, color: Colors.white54))),
        Positioned(top: 60, right: 100, child: Text('✨', style: TextStyle(fontSize: 18, color: Colors.white60))),
      ],
    );
  }

  // ── 헤더 ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); Navigator.of(context).pop(); },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
              ),
              child: const Icon(Icons.close, color: KidsTheme.textDark, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Text('탑 쌓기 🏗️',
            style: GoogleFonts.jua(
              fontSize: 26,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.black26, blurRadius: 6)],
            )),
          const Spacer(),
          if (_combo >= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFfdcb6e), borderRadius: BorderRadius.circular(12)),
              child: Text('🔥 $_combo콤보', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⭐ $_score', style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark)),
                Text('Lv.$_level', style: GoogleFonts.jua(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 게임 영역 ──
  Widget _buildGameArea() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (_screenSize != Size(constraints.maxWidth, constraints.maxHeight)) {
          _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (!_started) {
            // 처음에는 시작 화면
          }
        }

        return ClipRect(
          child: Stack(
            children: [
              // 쌓인 블록들
              ..._tower.map((b) => Positioned(
                left: b.x,
                top: b.y,
                width: b.width,
                height: b.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: b.color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: b.color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(b.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )),

              // 이동 중인 블록
              if (_movingBlock != null)
                Positioned(
                  left: _movingBlock!.x,
                  top: _movingBlock!.y,
                  width: _movingBlock!.width,
                  height: _movingBlock!.height,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _movingBlock!.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _movingBlock!.color.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(_movingBlock!.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),

              // 파티클
              ..._particles.map((p) => Positioned(
                left: p.x - p.size / 2,
                top: p.y - p.size / 2,
                child: Opacity(
                  opacity: p.life.clamp(0.0, 1.0),
                  child: Container(
                    width: p.size,
                    height: p.size,
                    decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                  ),
                ),
              )),

              // 점수 팝업
              ..._popups.map((p) => Positioned(
                left: p.x,
                top: p.y,
                child: Opacity(
                  opacity: p.life.clamp(0.0, 1.0),
                  child: Text(
                    p.text,
                    style: GoogleFonts.jua(
                      fontSize: 18,
                      color: p.color,
                      shadows: [const Shadow(color: Colors.white, blurRadius: 4)],
                    ),
                  ),
                ),
              )),

              // 높이 표시 (탑 블록 수)
              if (_started && !_isGameOver)
                Positioned(
                  top: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🏗️ ${_tower.length - 1}층',
                      style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.textDark),
                    ),
                  ),
                ),

              // 힌트 텍스트
              if (_started && !_isGameOver && _movingBlock != null)
                Positioned(
                  bottom: 16,
                  left: 0, right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '화면을 탭해서 블록을 내려요! 👇',
                        style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.textDark),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── 시작 화면 ──
  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏗️', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text('탑 쌓기',
                style: GoogleFonts.jua(fontSize: 52, color: Colors.white,
                  shadows: [const Shadow(color: Colors.black38, blurRadius: 8)])),
              const SizedBox(height: 8),
              Text('화면을 탭해서 블록을 쌓아요!',
                style: GoogleFonts.jua(fontSize: 22, color: Colors.white70)),
              Text('퍼펙트 타이밍이면 보너스 점수!',
                style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFFfdcb6e))),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    color: KidsTheme.orange,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.4), blurRadius: 12)],
                  ),
                  child: Text('시작하기 🚀', style: GoogleFonts.jua(fontSize: 28, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 게임 오버 ──
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.orange, width: 5),
              boxShadow: [BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.3), blurRadius: 16)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😢', style: TextStyle(fontSize: 64)),
                Text('무너졌다!', style: GoogleFonts.jua(fontSize: 38, color: KidsTheme.red)),
                const SizedBox(height: 8),
                Text('🏗️ ${_tower.length - 1}층 쌓음',
                  style: GoogleFonts.jua(fontSize: 24, color: Colors.grey.shade700)),
                Text('⭐ 점수: $_score',
                  style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark)),
                if (_score >= _bestScore && _score > 0)
                  Text('🏆 최고 기록!',
                    style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.orange)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFFFF6B6B), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 4),
                            Text('나가기', style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _startGame,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: KidsTheme.green, borderRadius: BorderRadius.circular(20)),
                        child: Text('다시 하기 🔄', style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
