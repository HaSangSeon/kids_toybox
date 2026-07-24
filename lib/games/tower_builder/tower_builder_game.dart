import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 모델 정의 (블록, 배경 비행기, 새, 구름, 파티클)
// ══════════════════════════════════════════════════════════════════════════════

class _Block {
  double x, y, width;
  final double height;
  final Color color;
  final String emoji;
  final int level;

  _Block({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
    required this.emoji,
    required this.level,
  });

  Rect get rect => Rect.fromLTWH(x, y, width, height);
}

// 🛩️ 배경 비행기 모델
class _Airplane {
  double x, y, speed, scale;
  final String emoji;
  _Airplane({required this.x, required this.y, required this.speed, required this.scale, required this.emoji});
}

// 🕊️ 배경 새 모델
class _Bird {
  double x, y, speed, wingPhase;
  final String emoji;
  _Bird({required this.x, required this.y, required this.speed, required this.wingPhase, required this.emoji});
}

// ☁️ 배경 구름 모델
class _Cloud {
  double x, y, speed, scale;
  _Cloud({required this.x, required this.y, required this.speed, required this.scale});
}

// 🎆 이펙트 파티클
class _Particle {
  double x, y, vx, vy, life, size;
  Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.life,
    required this.size,
  });
}

// 💬 점수 팝업
class _ScorePopup {
  double x, y, life;
  String text;
  Color color;
  _ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    required this.life,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// 메인 게임 위젯
// ══════════════════════════════════════════════════════════════════════════════

class TowerBuilderGame extends StatefulWidget {
  const TowerBuilderGame({super.key});

  @override
  State<TowerBuilderGame> createState() => _TowerBuilderGameState();
}

class _TowerBuilderGameState extends State<TowerBuilderGame>
    with TickerProviderStateMixin {
  // 물리 애니메이션 틱
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

  // 블록 크기 & 위치
  static const double _blockH = 46.0;
  static const double _baseW = 210.0;
  late double _blockW;

  final List<_Block> _tower = [];
  _Block? _movingBlock;

  // 좌우 스윙 물리
  double _swingX = 0.0;
  double _swingDir = 1.0;
  double _swingSpeed = 180.0;

  // 스무스 카메라 스크롤
  double _cameraOffsetY = 0.0;
  double _targetCameraOffsetY = 0.0;

  // 이펙트 파티클 & 팝업
  final List<_Particle> _particles = [];
  final List<_ScorePopup> _popups = [];
  late ConfettiController _confetti;

  // 🛩️ 🕊️ ☁️ 배경 객체들
  final List<_Airplane> _airplanes = [];
  final List<_Bird> _birds = [];
  final List<_Cloud> _clouds = [];

  final _rng = Random();

  // 아기자기한 이모티콘 뱃지
  static const _emojis = ['🏠', '🏫', '🏰', '💒', '🏢', '🎡', '🚀', '🎁', '🍰', '⭐'];

  // 파스텔 테마 색상 튜플
  static const _blockPalette = [
    Color(0xFFFF8A80), Color(0xFFFFD54F), Color(0xFF81C784),
    Color(0xFF4FC3F7), Color(0xFFBA68C8), Color(0xFFFFB74D),
    Color(0xFF4DD0E1), Color(0xFFF06292), Color(0xFFAED581),
  ];

  // 레벨별 화사한 하늘 배경 그라디언트
  static const _bgColors = [
    [Color(0xFF81D4FA), Color(0xFFE0F7FA)], // 상쾌한 아침 하늘 ☀️
    [Color(0xFFA5D6A7), Color(0xFFE8F5E9)], // 아기자기 초원 하늘 🌿
    [Color(0xFFFFCC80), Color(0xFFFFF3E0)], // 노을빛 하늘 🌇
    [Color(0xFFCE93D8), Color(0xFFF3E5F5)], // 로맨틱 핑크 하늘 🌸
    [Color(0xFF9FA8DA), Color(0xFFE8EAF6)], // 은은한 별빛 밤하늘 🌙
  ];

  List<Color> get _bg => _bgColors[(_level - 1).clamp(0, _bgColors.length - 1)];

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _initBackgroundObjects();

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  // 🛩️ 🕊️ 배경 비행기와 새, 구름 초기화
  void _initBackgroundObjects() {
    _clouds.clear();
    _airplanes.clear();
    _birds.clear();

    // 구름 생성
    for (int i = 0; i < 5; i++) {
      _clouds.add(_Cloud(
        x: _rng.nextDouble() * 400,
        y: 60 + _rng.nextDouble() * 250,
        speed: 15 + _rng.nextDouble() * 20,
        scale: 0.8 + _rng.nextDouble() * 0.6,
      ));
    }

    // 비행기 생성
    _airplanes.add(_Airplane(
      x: -100,
      y: 120,
      speed: 65,
      scale: 1.0,
      emoji: '🛩️',
    ));

    // 새 모둠 생성
    for (int i = 0; i < 3; i++) {
      _birds.add(_Bird(
        x: -50 - (i * 35),
        y: 180 + (i * 20),
        speed: 45 + _rng.nextDouble() * 15,
        wingPhase: i * 0.5,
        emoji: i % 2 == 0 ? '🕊️' : '🐦',
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }
    final dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;

    if (dt <= 0 || dt > 0.1) return;

    if (mounted) {
      setState(() {
        _updateGame(dt);
      });
    }
  }

  void _updateGame(double dt) {
    // 🛩️ 🕊️ ☁️ 배경 객체 물리 이동
    for (final c in _clouds) {
      c.x += c.speed * dt;
      if (c.x > (_screenSize.width + 100)) {
        c.x = -120;
        c.y = 50 + _rng.nextDouble() * 300;
      }
    }

    for (final plane in _airplanes) {
      plane.x += plane.speed * dt;
      if (plane.x > (_screenSize.width + 120)) {
        plane.x = -150;
        plane.y = 80 + _rng.nextDouble() * 200;
      }
    }

    for (final bird in _birds) {
      bird.x += bird.speed * dt;
      bird.wingPhase += dt * 6.0;
      if (bird.x > (_screenSize.width + 80)) {
        bird.x = -80 - _rng.nextDouble() * 100;
        bird.y = 150 + _rng.nextDouble() * 250;
      }
    }

    // 카메라 부드러운 스크롤 lerp (탑이 쌓일 때 스르륵 내림)
    _cameraOffsetY += (_targetCameraOffsetY - _cameraOffsetY) * (dt * 7.5);

    if (!_started || _isGameOver) return;

    // 움직이는 블록 스윙
    if (_movingBlock != null) {
      _swingX += _swingDir * _swingSpeed * dt;
      final maxSwing = (_screenSize.width - _movingBlock!.width) / 2;
      if (_swingX > maxSwing) {
        _swingX = maxSwing;
        _swingDir = -1.0;
      } else if (_swingX < -maxSwing) {
        _swingX = -maxSwing;
        _swingDir = 1.0;
      }
      _movingBlock!.x = (_screenSize.width / 2) + _swingX - (_movingBlock!.width / 2);
    }

    // 파티클 물리
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 220 * dt; // gravity
      p.life -= dt;
      if (p.life <= 0) _particles.removeAt(i);
    }

    // 점수 팝업 물리
    for (int i = _popups.length - 1; i >= 0; i--) {
      final pop = _popups[i];
      pop.y -= 40 * dt;
      pop.life -= dt;
      if (pop.life <= 0) _popups.removeAt(i);
    }
  }

  void _startGame() {
    _started = true;
    _isGameOver = false;
    _score = 0;
    _combo = 0;
    _level = 1;
    _blockW = _baseW;
    _cameraOffsetY = 0.0;
    _targetCameraOffsetY = 0.0;

    _tower.clear();
    _particles.clear();
    _popups.clear();

    final centerX = (_screenSize.width - _blockW) / 2;
    final baseY = _screenSize.height - 100;

    // 기반 1단 블록 생성
    _tower.add(_Block(
      x: centerX,
      y: baseY,
      width: _blockW,
      height: _blockH,
      color: const Color(0xFF4FC3F7),
      emoji: '🏠',
      level: 1,
    ));

    _spawnMovingBlock();
  }

  void _spawnMovingBlock() {
    final topY = _tower.last.y - _blockH;
    final color = _blockPalette[_tower.length % _blockPalette.length];
    final emoji = _emojis[_tower.length % _emojis.length];

    _swingX = (_rng.nextDouble() - 0.5) * 100;
    _swingDir = _rng.nextBool() ? 1.0 : -1.0;
    _swingSpeed = 160.0 + (_level * 22.0);

    _movingBlock = _Block(
      x: (_screenSize.width - _blockW) / 2 + _swingX,
      y: topY,
      width: _blockW,
      height: _blockH,
      color: color,
      emoji: emoji,
      level: _level,
    );
  }

  // 🏗️ 블록 착지 터치 처리
  void _dropBlock() {
    if (!_started || _isGameOver || _movingBlock == null) {
      if (!_started || _isGameOver) _startGame();
      return;
    }

    final prev = _tower.last;
    final curr = _movingBlock!;

    final diff = curr.x - prev.x;
    final absDiff = diff.abs();

    HapticFeedback.mediumImpact();

    // 퍼펙트 판정 (차이 8px 미만)
    if (absDiff < 8.0) {
      _combo++;
      _score += 10 + (_combo * 5);

      // 🔊 실감나는 맑은 퍼펙트 콤보 벨 사운드!
      AudioManager.instance.playTowerPerfect(combo: _combo);

      curr.x = prev.x; // 정밀 스냅
      _spawnSparkles(curr.x + curr.width / 2, curr.y + curr.height / 2, Colors.amberAccent, 18);
      _addPopup(curr.x + curr.width / 2, curr.y - 10, 'PERFECT! +${10 + _combo * 5}', Colors.amber.shade800);

      if (_combo >= 3 && _combo % 3 == 0) {
        _blockW = (_blockW + 12).clamp(60, _baseW);
        _addPopup(curr.x + curr.width / 2, curr.y - 30, '블록 보너스 혜택! 🎁', Colors.pinkAccent);
      }
    } else {
      // 일반 착지
      _combo = 0;

      final overlap = curr.width - absDiff;
      if (overlap <= 0) {
        // 탑 무너짐 (게임 오버)
        _isGameOver = true;
        _movingBlock = null;
        AudioManager.instance.playCrash();
        _spawnSparkles(curr.x + curr.width / 2, curr.y, curr.color, 30);

        if (_score > _bestScore) _bestScore = _score;
        final earnedCoins = (_score / 20).floor().clamp(0, 10);
        if (earnedCoins > 0) {
          PlayerDataManager.instance.addStarCoin(earnedCoins);
        }
        return;
      }

      // 🔊 묵직하고 실감나는 블록 건축 쿵 사운드!
      AudioManager.instance.playTowerBlockDrop();

      _score += 5;
      _blockW = overlap;
      if (diff > 0) {
        curr.width = overlap;
      } else {
        curr.x = prev.x;
        curr.width = overlap;
      }

      _spawnSparkles(curr.x + curr.width / 2, curr.y + curr.height, curr.color, 10);
      _addPopup(curr.x + curr.width / 2, curr.y - 10, '+5', Colors.blue.shade800);
    }

    _tower.add(curr);

    // 레벨 업 체크 (10층 단위)
    if (_tower.length % 10 == 0) {
      _level = (_level < 5) ? _level + 1 : 5;
      _confetti.play();
      _addPopup(_screenSize.width / 2, _screenSize.height / 3, 'LEVEL UP! 레벨 $_level 🎉', Colors.purpleAccent);
    }

    // 부드러운 스무스 카메라 스크롤 (탑이 5층 이상 높게 올라가면 스르륵 내림)
    if (_tower.length > 5) {
      _targetCameraOffsetY += _blockH;
    }

    _spawnMovingBlock();
  }

  void _spawnSparkles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = 40 + _rng.nextDouble() * 140;
      _particles.add(_Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 50,
        color: color,
        life: 0.6 + _rng.nextDouble() * 0.4,
        size: 4 + _rng.nextDouble() * 6,
      ));
    }
  }

  void _addPopup(double x, double y, String text, Color color) {
    _popups.add(_ScorePopup(
      x: x,
      y: y,
      text: text,
      color: color,
      life: 0.9,
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI 렌더링
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🎨 동적 파스텔 하늘 배경 & 비행기/새 페인터
          Positioned.fill(
            child: CustomPaint(
              painter: _SkyBackgroundPainter(
                bgColors: _bg,
                clouds: _clouds,
                airplanes: _airplanes,
                birds: _birds,
              ),
            ),
          ),

          // 🏰 3D 건물 블록 CustomPainter (플레이 영역 터치 감지)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => _dropBlock(),
              child: CustomPaint(
                painter: _TowerPainter(
                  tower: _tower,
                  movingBlock: _movingBlock,
                  particles: _particles,
                  cameraOffsetY: _cameraOffsetY,
                ),
              ),
            ),
          ),

          // 점수 팝업 텍스트
          ..._popups.map((pop) => Positioned(
            left: pop.x - 70,
            top: pop.y + _cameraOffsetY,
            child: IgnorePointer(
              child: SizedBox(
                width: 140,
                child: Text(
                  pop.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jua(
                    fontSize: 20,
                    color: pop.color,
                    shadows: const [
                      Shadow(color: Colors.white, blurRadius: 4),
                      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          )),

          // 💎 고급스러운 3D 상단 헤더 & 은은한 가이드 자막
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 6),
                _buildStatsBar(),
                const SizedBox(height: 6),
                // 탑을 가리지 않는 은은하고 고급스러운 터치 가이드 뱃지 (4층 미만 시 표출)
                if (_started && !_isGameOver && _tower.length <= 4)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade400, width: 1.5),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      '👇 화면 아무 곳이나 터치하여 챡! 쌓으세요 🏗️',
                      style: GoogleFonts.jua(fontSize: 12, color: Colors.brown.shade800),
                    ),
                  ),
              ],
            ),
          ),

          // 시작 / 게임오버 안내 오버레이
          if (!_started) _buildStartOverlay(),
          if (_isGameOver) _buildGameOverOverlay(),

          // 컨페티 폭죽
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 35,
            ),
          ),
        ],
      ),
    );
  }

  // ── 상단 헤더 ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // 고급 3D 젤리 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.orange.shade900, size: 20),
            ),
          ),
          const Spacer(),
          // 고급스러운 3D 젤리 타이틀
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: Row(
              children: [
                const Text('🏰 ', style: TextStyle(fontSize: 18)),
                Text(
                  '알록달록 탑 쌓기',
                  style: GoogleFonts.jua(
                    fontSize: 20,
                    color: Colors.brown.shade900,
                    shadows: const [Shadow(color: Colors.white54, blurRadius: 2)],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── 스코어 & 레벨 뱃지 바 ───────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _jellyBadge('🏰 ${_tower.length}층', Colors.pink.shade400),
          const SizedBox(width: 8),
          _jellyBadge('🎯 $_score점', Colors.amber.shade900),
          const SizedBox(width: 8),
          if (_combo > 1) _jellyBadge('🔥 $_combo 콤보!', Colors.deepOrangeAccent),
        ],
      ),
    );
  }

  Widget _jellyBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Text(
        text,
        style: GoogleFonts.jua(fontSize: 14, color: color),
      ),
    );
  }

  // 시작 오버레이
  Widget _buildStartOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏰', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text('알록달록 탑 쌓기!', style: GoogleFonts.jua(fontSize: 26, color: Colors.orange.shade900)),
              const SizedBox(height: 8),
              Text(
                '화면을 터치해서 높이높이\n멋진 건물을 쌓아보세요!',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade500,
                  foregroundColor: Colors.brown.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('게임 시작! 🚀', style: GoogleFonts.jua(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 게임오버 오버레이
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 36),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('탑이 무너졌어요!', style: GoogleFonts.jua(fontSize: 24, color: Colors.deepOrange)),
              const SizedBox(height: 12),
              Text('최종 높이: ${_tower.length}층', style: GoogleFonts.jua(fontSize: 18, color: Colors.grey.shade800)),
              Text('획득 점수: $_score점', style: GoogleFonts.jua(fontSize: 16, color: Colors.amber.shade900)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text('다시 도전! 🔄', style: GoogleFonts.jua(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 🛩️ 🕊️ 동적 하늘 배경 CustomPainter (비행기, 새, 구름)
// ══════════════════════════════════════════════════════════════════════════════

class _SkyBackgroundPainter extends CustomPainter {
  final List<Color> bgColors;
  final List<_Cloud> clouds;
  final List<_Airplane> airplanes;
  final List<_Bird> birds;

  _SkyBackgroundPainter({
    required this.bgColors,
    required this.clouds,
    required this.airplanes,
    required this.birds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 하늘 배경 그라디언트
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bgColors,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // ☁️ 몽실몽실 구름 렌더링
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (final c in clouds) {
      final r = 25.0 * c.scale;
      canvas.drawCircle(Offset(c.x, c.y), r, cloudPaint);
      canvas.drawCircle(Offset(c.x + r * 0.8, c.y - r * 0.3), r * 0.8, cloudPaint);
      canvas.drawCircle(Offset(c.x - r * 0.8, c.y - r * 0.2), r * 0.75, cloudPaint);
      canvas.drawCircle(Offset(c.x + r * 1.4, c.y + r * 0.1), r * 0.6, cloudPaint);
    }

    // 🛩️ 비행기 렌더링 (이모지 & 하얀 구름 연기 구름선)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (final plane in airplanes) {
      // 비행기 연기 트레일
      final trailPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(Offset(plane.x - (i * 12) - 10, plane.y + 10), 6 - (i * 1.0), trailPaint);
      }

      textPainter.text = TextSpan(
        text: plane.emoji,
        style: TextStyle(fontSize: 32 * plane.scale),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(plane.x, plane.y - 12));
    }

    // 🕊️ 섬세한 곡선 날갯짓(Smooth Wing Flapping) 실감나는 새 렌더링
    for (final b in birds) {
      final double wingAngle = sin(b.wingPhase) * 14.0; // 날개 펄럭임 각도 파동
      final double bodyY = sin(b.wingPhase) * 2.5;     // 몸통의 미세한 둥실 오르내림
      final cx = b.x;
      final cy = b.y + bodyY;

      // 1. 새 몸통 & 꼬리 (아기자기한 흰색/파스텔 피치 톤)
      final birdPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;

      final birdOutline = Paint()
        ..color = const Color(0xFF42A5F5).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // 꼬리 깃털
      final tailPath = Path()
        ..moveTo(cx - 8, cy + 2)
        ..lineTo(cx - 16, cy - 2)
        ..lineTo(cx - 14, cy + 5)
        ..close();
      canvas.drawPath(tailPath, birdPaint);

      // 몸통 통통한 원
      canvas.drawCircle(Offset(cx, cy), 6.5, birdPaint);
      canvas.drawCircle(Offset(cx, cy), 6.5, birdOutline);

      // 노란 아기자기 부리
      final beakPaint = Paint()..color = const Color(0xFFFFB300);
      final beakPath = Path()
        ..moveTo(cx + 6, cy - 1)
        ..lineTo(cx + 12, cy + 1)
        ..lineTo(cx + 6, cy + 3)
        ..close();
      canvas.drawPath(beakPath, beakPaint);

      // 귀여운 까만 눈
      canvas.drawCircle(Offset(cx + 3, cy - 2), 1.2, Paint()..color = Colors.black87);

      // 2. 🪽 부드럽게 펄럭이는 곡선 베지어 날개 (Left & Right Wings)
      final wingPath = Path();

      // 왼쪽 날개 (뒤쪽)
      wingPath.moveTo(cx - 2, cy - 1);
      wingPath.quadraticBezierTo(
        cx - 8, cy - 14 - wingAngle,  // 조종점 (날개가 위아래로 펄럭임)
        cx - 16, cy - 4 - wingAngle * 0.4, // 날개 끝
      );
      wingPath.quadraticBezierTo(
        cx - 8, cy - 3,
        cx - 2, cy - 1,
      );

      // 오른쪽 날개 (앞쪽)
      wingPath.moveTo(cx + 1, cy - 1);
      wingPath.quadraticBezierTo(
        cx + 8, cy - 14 - wingAngle,
        cx + 16, cy - 4 - wingAngle * 0.4,
      );
      wingPath.quadraticBezierTo(
        cx + 7, cy - 3,
        cx + 1, cy - 1,
      );

      canvas.drawPath(wingPath, birdPaint);
      canvas.drawPath(wingPath, birdOutline);
    }
  }

  @override
  bool shouldRepaint(covariant _SkyBackgroundPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 🏰 3D 건물 / 케이크 블록 CustomPainter
// ══════════════════════════════════════════════════════════════════════════════

class _TowerPainter extends CustomPainter {
  final List<_Block> tower;
  final _Block? movingBlock;
  final List<_Particle> particles;
  final double cameraOffsetY;

  _TowerPainter({
    required this.tower,
    required this.movingBlock,
    required this.particles,
    required this.cameraOffsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(0, cameraOffsetY);

    // 1. 쌓여있는 블록들 그리기
    for (int i = 0; i < tower.length; i++) {
      _draw3DBlock(canvas, tower[i], isBottom: i == 0);
    }

    // 2. 움직이는 블록 그리기
    if (movingBlock != null) {
      _draw3DBlock(canvas, movingBlock!, isBottom: false);
    }

    // 3. 파티클 이펙트 그리기
    for (final p in particles) {
      final particlePaint = Paint()..color = p.color.withValues(alpha: (p.life).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(p.x, p.y), p.size, particlePaint);
    }

    canvas.restore();
  }

  // 🎨 입체감 넘치는 3D 블록 드로잉
  void _draw3DBlock(Canvas canvas, _Block block, {required bool isBottom}) {
    final r = RRect.fromRectAndRadius(block.rect, const Radius.circular(10));

    // 메인 바디
    final bodyPaint = Paint()..color = block.color;
    canvas.drawRRect(r, bodyPaint);

    // 상단 3D 하이라이트 베벨
    final topHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(r, topHighlight);

    // 하단 3D 그림자 베벨
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
    final bottomRect = Rect.fromLTWH(block.x, block.y + block.height - 8, block.width, 8);
    canvas.drawRRect(RRect.fromRectAndRadius(bottomRect, const Radius.circular(8)), shadowPaint);

    // 아기자기 창문 / 건물 디테일 (창문 3개)
    if (block.width > 70 && !isBottom) {
      final winPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final winCount = (block.width / 45).floor().clamp(1, 4);
      final winSpacing = block.width / (winCount + 1);

      for (int k = 1; k <= winCount; k++) {
        final winX = block.x + (winSpacing * k) - 7;
        final winY = block.y + 12;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(winX, winY, 14, 14), const Radius.circular(4)), winPaint);
      }
    }

    // 이모티콘 뱃지 (중앙)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: block.emoji,
      style: const TextStyle(fontSize: 22),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        block.x + (block.width - textPainter.width) / 2,
        block.y + (block.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _TowerPainter oldDelegate) => true;
}
