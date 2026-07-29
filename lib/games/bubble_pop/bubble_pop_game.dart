import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

class WaveTheme {
  final String title;
  final List<String> emojis;
  final String targetEmoji;
  final int targetCount;

  WaveTheme({
    required this.title,
    required this.emojis,
    required this.targetEmoji,
    required this.targetCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble model
// ─────────────────────────────────────────────────────────────────────────────

class Bubble {
  final String id;
  double x;
  double y;
  final double size;
  final double speed;
  final double phase;
  final double amplitude;
  final Color color;
  final String emoji; // 안에 이모지
  bool isPopped;

  Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.amplitude,
    required this.color,
    required this.emoji,
    this.isPopped = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Pop particle model
// ─────────────────────────────────────────────────────────────────────────────

class PopParticle {
  double x, y;
  double vx, vy;
  double radius;
  Color color;
  double opacity;

  PopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    this.opacity = 1.0,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 180 * dt;
    opacity -= 2.4 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score popup
// ─────────────────────────────────────────────────────────────────────────────

class ScorePopup {
  double x, y;
  double vy;
  double opacity;
  final String text;

  ScorePopup({required this.x, required this.y, required this.text, this.vy = -70, this.opacity = 1.0});

  void update(double dt) {
    y += vy * dt;
    opacity -= 1.6 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game state
// ─────────────────────────────────────────────────────────────────────────────

class _BubblePopGameState extends State<BubblePopGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  final List<Bubble> _bubbles = [];
  final List<PopParticle> _particles = [];
  final List<ScorePopup> _popups = [];
  final Random _random = Random();

  int _score = 0;
  int _wave = 1;
  int _level = 1;
  bool _showLevelSelect = true; // 게임 첫 진입 시 레벨 선택 창 바로 팝업!
  int _wavePopped = 0;
  
  WaveTheme? _currentTheme;
  WaveTheme get _theme => _currentTheme ??= _getThemeForWave(_wave);
  int get _waveTarget => _theme.targetCount;

  void _selectLevel(int level) {
    setState(() {
      _level = level;
      _wave = level;
      _score = 0;
      _wavePopped = 0;
      _bubbles.clear();
      _particles.clear();
      _popups.clear();
      _currentTheme = _getThemeForWave(level);
      _showLevelSelect = false;
      _waveClear = false;
      _waiting = true;
      _waitTimer = 0;
    });
  }

  WaveTheme _getThemeForWave(int wave) {
    final List<List<String>> emojiSets = [
      ['🍎', '🍌', '🍇', '🍓', '🍒', '🍉'], // Fruit
      ['🦁', '🐰', '🐼', '🦊', '🐱', '🐶'], // Animal
      ['🐠', '🐙', '🦀', '🐳', '🐢', '🐬'], // Sea Friends
      ['🍭', '🍬', '🍩', '🧁', '🍪', '🍫'], // Sweets
      ['🚀', '🛸', '✈️', '🚁', '🚕', '🚒'], // Vehicles
    ];

    final titles = [
      '1단계: 새콤달콤 과일 사냥! 🍎',
      '2단계: 귀여운 동물 친구들! 🐰',
      '3단계: 바다 속 친구들! 🐠',
      '4단계: 달콤한 과자 파티! 🍭',
      '5단계: 빵빵 탈것 모으기! 🚀',
    ];

    final targetCounts = [8, 12, 18, 25, 35];

    final setIndex = (wave - 1) % emojiSets.length;
    final emojis = emojiSets[setIndex];
    
    final random = Random(wave + 123);
    final targetEmoji = emojis[random.nextInt(emojis.length)];
    final targetCount = targetCounts[setIndex];

    return WaveTheme(
      title: titles[setIndex],
      emojis: emojis,
      targetEmoji: targetEmoji,
      targetCount: targetCount,
    );
  }

  Size _screenSize = Size.zero;
  double _timeCounter = 0;

  // 웨이브 진행
  bool _waveClear = false;     // 웨이브 클리어 연출 중
  double _waveClearTimer = 0;  // 클리어 표시 타이머
  bool _waiting = false;       // 다음 웨이브 대기 중
  double _waitTimer = 0;       // 대기 타이머

  // 스폰 쿨다운 (단계별 스피드 조율)
  double _spawnCooldown = 0;
  double get _spawnInterval {
    switch (_wave) {
      case 1: return 2.0;
      case 2: return 1.5;
      case 3: return 1.1;
      case 4: return 0.7;
      case 5: default: return 0.45; // 5단계: 초고속 펑펑 버블 폭풍 스폰!
    }
  }

  // 화면에 띄울 최대 동시 비눗방울 수
  int get _maxBubbles {
    switch (_wave) {
      case 1: return 5;
      case 2: return 6;
      case 3: return 8;
      case 4: return 10;
      case 5: default: return 14; // 5단계: 화면에 14개 버블 가득!
    }
  }

  // 버블 색상 (반투명 무지개)
  static const List<Color> _bubbleColors = [
    Color(0xFFFF8A80), Color(0xFFFFD180), Color(0xFFFFFF8D),
    Color(0xFFB9F6CA), Color(0xFF80D8FF), Color(0xFFB388FF),
    Color(0xFFFF80AB),
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

  // ── Tick ─────────────────────────────────────────────────────────────────

  void _onTick(Duration elapsed) {
    if (_screenSize == Size.zero || _showLevelSelect) return;
    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final double dt = ((elapsed - _lastTime).inMicroseconds / 1000000.0).clamp(0.0, 0.05);
    _lastTime = elapsed;
    _timeCounter += dt;

    setState(() {
      // 파티클 & 팝업 업데이트
      for (final p in _particles) p.update(dt);
      _particles.removeWhere((p) => p.opacity <= 0);
      for (final p in _popups) p.update(dt);
      _popups.removeWhere((p) => p.opacity <= 0);

      // 웨이브 클리어 연출 대기 중
      if (_waveClear) {
        _waveClearTimer += dt;
        if (_waveClearTimer > 2.5) {
          _waveClear = false;
          _waveClearTimer = 0;
          _startNextWave();
        }
        return;
      }

      // 웨이브 스타트 대기 중
      if (_waiting) {
        _waitTimer += dt;
        if (_waitTimer > 1.2) {
          _waiting = false;
          _waitTimer = 0;
        }
        return;
      }

      // 버블 이동
      for (final b in _bubbles) {
        if (b.isPopped) continue;
        b.y -= b.speed * dt;
        b.x += sin(_timeCounter * 1.8 + b.phase) * b.amplitude * dt;
        // 화면 가장자리 반사
        b.x = b.x.clamp(0, _screenSize.width - b.size);
      }

      // 버블 간 쫀득한 물리 충돌 효과
      for (int i = 0; i < _bubbles.length; i++) {
        final b1 = _bubbles[i];
        if (b1.isPopped) continue;
        for (int j = i + 1; j < _bubbles.length; j++) {
          final b2 = _bubbles[j];
          if (b2.isPopped) continue;

          final c1x = b1.x + b1.size / 2;
          final c1y = b1.y + b1.size / 2;
          final c2x = b2.x + b2.size / 2;
          final c2y = b2.y + b2.size / 2;

          final dx = c2x - c1x;
          final dy = c2y - c1y;
          final dist = sqrt(dx * dx + dy * dy);
          final minDist = (b1.size / 2) + (b2.size / 2);

          if (dist < minDist && dist > 0) {
            final overlap = minDist - dist;
            final nx = dx / dist;
            final ny = dy / dist;

            // 두 버블을 반대 방향으로 밀어냄 (쫀득한 튕김)
            b1.x -= nx * overlap * 0.5;
            b1.y -= ny * overlap * 0.5;
            b2.x += nx * overlap * 0.5;
            b2.y += ny * overlap * 0.5;

            // 화면 가두기
            b1.x = b1.x.clamp(0.0, _screenSize.width - b1.size);
            b2.x = b2.x.clamp(0.0, _screenSize.width - b2.size);
          }
        }
      }

      // 화면 밖 버블 제거
      _bubbles.removeWhere((b) => b.y + b.size < -10 || b.isPopped);

      // 스폰 로직 (목표 수 미달 & 쿨다운 완료)
      _spawnCooldown -= dt;
      final int active = _bubbles.where((b) => !b.isPopped).length;
      if (_spawnCooldown <= 0 && active < _maxBubbles && !_waveClear) {
        _spawnBubble();
        _spawnCooldown = _spawnInterval * (0.7 + _random.nextDouble() * 0.6);
      }
    });
  }

  // ── Spawn ─────────────────────────────────────────────────────────────────

  void _spawnBubble() {
    if (_screenSize == Size.zero) return;

    final double minSize, maxSize, minSpeed, maxSpeed, amplitude;

    switch (_wave) {
      case 1:
        minSize = 85.0; maxSize = 125.0;
        minSpeed = 80.0; maxSpeed = 130.0;
        amplitude = 14.0;
        break;
      case 2:
        minSize = 75.0; maxSize = 115.0;
        minSpeed = 110.0; maxSpeed = 170.0;
        amplitude = 18.0;
        break;
      case 3:
        minSize = 65.0; maxSize = 105.0;
        minSpeed = 140.0; maxSpeed = 220.0;
        amplitude = 24.0;
        break;
      case 4:
        minSize = 55.0; maxSize = 95.0;
        minSpeed = 180.0; maxSpeed = 280.0;
        amplitude = 30.0;
        break;
      case 5:
      default:
        minSize = 45.0; maxSize = 85.0; // 5단계: 민첩한 소형 스피드 버블!
        minSpeed = 230.0; maxSpeed = 360.0; // 5단계: 초고속 솟구침!
        amplitude = 38.0; // 5단계: 역동적인 지그재그 흔들림!
        break;
    }

    final size = minSize + _random.nextDouble() * (maxSize - minSize);
    final x = _random.nextDouble() * (_screenSize.width - size);
    final color = _bubbleColors[_random.nextInt(_bubbleColors.length)];
    
    final String emoji;
    // 목표 수집 이모지가 스폰될 확률 40%
    if (_random.nextDouble() < 0.40) {
      emoji = _theme.targetEmoji;
    } else {
      final nonTargets = _theme.emojis.where((e) => e != _theme.targetEmoji).toList();
      emoji = nonTargets.isNotEmpty
          ? nonTargets[_random.nextInt(nonTargets.length)]
          : _theme.targetEmoji;
    }

    final speed = minSpeed + _random.nextDouble() * (maxSpeed - minSpeed);

    _bubbles.add(Bubble(
      id: '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(999)}',
      x: x,
      y: _screenSize.height + size,
      size: size,
      speed: speed,
      phase: _random.nextDouble() * pi * 2,
      amplitude: amplitude,
      color: color,
      emoji: emoji,
    ));
  }

  // ── Pop ───────────────────────────────────────────────────────────────────

  void _popBubble(Bubble bubble) {
    if (bubble.isPopped) return;

    bubble.isPopped = true;
    final isTarget = bubble.emoji == _theme.targetEmoji;

    if (isTarget) {
      _score += 15 * _wave;
      _wavePopped++;
    }

    // 팝 파티클
    final cx = bubble.x + bubble.size / 2;
    final cy = bubble.y + bubble.size / 2;
    
    final particleCount = isTarget ? 14 : 10;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * 2 * pi + _random.nextDouble() * 0.4;
      final speed = 70 + _random.nextDouble() * (isTarget ? 200 : 140);
      _particles.add(PopParticle(
        x: cx, y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 40,
        radius: isTarget
            ? 3.5 + _random.nextDouble() * 8
            : 2.5 + _random.nextDouble() * 5,
        color: bubble.color.withOpacity(isTarget ? 0.95 : 0.6),
      ));
    }

    _popups.add(ScorePopup(
      x: cx, y: cy - bubble.size / 2,
      text: isTarget ? '+${15 * _wave}' : '💨',
      vy: isTarget ? -70 : -40,
      opacity: isTarget ? 1.0 : 0.7,
    ));

    if (isTarget) {
      final pitch = 1.0 + _random.nextDouble() * 0.4;
      AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: pitch);
    } else {
      AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: 0.65);
    }
    HapticFeedback.lightImpact();

    // 웨이브 클리어 체크
    if (_wavePopped >= _waveTarget) {
      _waveClear = true;
      _waveClearTimer = 0;
      _bubbles.clear();
      AudioManager.instance.playSuccess();
      HapticFeedback.heavyImpact();
    }
  }

  // ── Wave management ───────────────────────────────────────────────────────

  void _startNextWave() {
    _wave++;
    _level = _wave;
    _currentTheme = _getThemeForWave(_wave);
    _wavePopped = 0;
    _waiting = true;
    _waitTimer = 0;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_screenSize.width != constraints.maxWidth ||
              _screenSize.height != constraints.maxHeight) {
            _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
            if (!_ticker.isTicking) _ticker.start();
          }

          return Stack(
            children: [
              // ── Animated Background ────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyBgPainter(time: _timeCounter),
                ),
              ),

              // ── Pop particles ──────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    popups: _popups,
                  ),
                ),
              ),

              // ── Bubbles ────────────────────────────────────────────────
              ..._bubbles.where((b) => !b.isPopped).map(_buildBubble),

              // ── Wave clear overlay ─────────────────────────────────────
              if (_waveClear) _buildWaveClearOverlay(),

              // ── Waiting overlay ────────────────────────────────────────
              if (_waiting) _buildWaitingOverlay(),

              // ── Header & progress ─────────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      _buildWaveProgress(),
                    ],
                  ),
                ),
              ),

              // ── Level Select Overlay ───────────────────────────────────
              if (_showLevelSelect) _buildLevelSelectOverlay(),
            ],
          );
        },
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // 뒤로가기
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF5C6BC0), size: 20),
            ),
          ),
          const SizedBox(width: 8),

          // 타이틀
          Expanded(
            child: Text(
              '비눗방울 톡톡 🫧',
              style: GoogleFonts.jua(
                fontSize: 22,
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),

          // 레벨 선택 배지
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() => _showLevelSelect = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFFB388FF)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🫧 $_level단계 ▾',
                    style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Wave progress bar ──────────────────────────────────────────────────────

  Widget _buildWaveProgress() {
    final progress = (_wavePopped / _waveTarget).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🎯 미션: ${_theme.targetEmoji} 를 $_waveTarget개 모으세요!',
                  style: GoogleFonts.jua(fontSize: 13, color: Colors.purple.shade700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🫧 수집: $_wavePopped / $_waveTarget',
                  style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF5C6BC0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.lerp(const Color(0xFF7C4DFF), const Color(0xFFFF6B9D), progress)!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bubble widget ──────────────────────────────────────────────────────────

  Widget _buildBubble(Bubble bubble) {
    return Positioned(
      left: bubble.x,
      top:  bubble.y,
      width:  bubble.size,
      height: bubble.size,
      child: GestureDetector(
        onTapDown: (_) => _popBubble(bubble),
        behavior: HitTestBehavior.opaque,
        child: _BubbleWidget(bubble: bubble, time: _timeCounter),
      ),
    );
  }

  // ── Level Select Overlay ───────────────────────────────────────────────────

  Widget _buildLevelSelectOverlay() {
    final levels = [
      {'level': 1, 'name': '1단계', 'desc': '🍎 과일 동산 (느긋하고 크게! 8개)', 'emoji': '🍎', 'color': Colors.pink.shade400},
      {'level': 2, 'name': '2단계', 'desc': '🐰 동물 농장 (통통 신나게! 12개)', 'emoji': '🐰', 'color': Colors.orange.shade400},
      {'level': 3, 'name': '3단계', 'desc': '🐠 바다 탐험 (빠르고 넘치게! 18개)', 'emoji': '🐠', 'color': Colors.blue.shade400},
      {'level': 4, 'name': '4단계', 'desc': '🍭 과자 나라 (스피드 버블! 25개)', 'emoji': '🍭', 'color': Colors.purple.shade400},
      {'level': 5, 'name': '5단계', 'desc': '🚀 우주 여행 (초고속 마스터! 35개⚡)', 'emoji': '🚀', 'color': Colors.deepOrange.shade400},
    ];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Container(
            width: 330,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🗺️ 난이도 레벨 선택',
                      style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFF333333)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 26),
                      onPressed: () {
                        setState(() {
                          _showLevelSelect = false;
                          if (_bubbles.isEmpty && !_waiting) {
                            _selectLevel(1);
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: levels.map((lvl) {
                    final isSelected = _level == lvl['level'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          _selectLevel(lvl['level'] as int);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [lvl['color'] as Color, (lvl['color'] as Color).withOpacity(0.8)],
                                  )
                                : null,
                            color: isSelected ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (lvl['color'] as Color).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Text(lvl['emoji'] as String, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lvl['name'] as String,
                                      style: GoogleFonts.jua(
                                        fontSize: 17,
                                        color: isSelected ? Colors.white : const Color(0xFF333333),
                                      ),
                                    ),
                                    Text(
                                      lvl['desc'] as String,
                                      style: GoogleFonts.jua(
                                        fontSize: 12,
                                        color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wave clear overlay ─────────────────────────────────────────────────────

  Widget _buildWaveClearOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.3), blurRadius: 16),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(
                  '$_level단계 미션 성공! 🌟',
                  style: GoogleFonts.jua(fontSize: 28, color: const Color(0xFF5C6BC0)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() => _showLevelSelect = true);
                      },
                      child: Text(
                        '🗺️ 레벨 선택',
                        style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        AudioManager.instance.playClick();
                        _waveClear = false;
                        _waveClearTimer = 0;
                        _startNextWave();
                      },
                      child: Text(
                        '🎮 다음 단계',
                        style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
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

  Widget _buildWaitingOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 14)],
            border: Border.all(color: Colors.blue.shade100, width: 3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🫧 레벨 $_level',
                style: GoogleFonts.jua(fontSize: 22, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 6),
              Text(
                _theme.title,
                style: GoogleFonts.jua(fontSize: 24, color: Colors.purple.shade700),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '🎯 미션: ${_theme.targetEmoji} 를 $_waveTarget개 모으기!',
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.purple.shade800),
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
// Bubble Widget — 무지개 글로우 + 이모지
// ─────────────────────────────────────────────────────────────────────────────

class _BubbleWidget extends StatelessWidget {
  final Bubble bubble;
  final double time;

  const _BubbleWidget({required this.bubble, required this.time});

  @override
  Widget build(BuildContext context) {
    final shimmerAngle = time * 1.5 + bubble.phase;
    final shimmerOpacity = (sin(shimmerAngle) * 0.15 + 0.25).clamp(0.1, 0.4);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.85,
          colors: [
            Colors.white.withOpacity(0.55),
            bubble.color.withOpacity(0.35),
            bubble.color.withOpacity(0.55),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bubble.color.withOpacity(0.45),
            blurRadius: bubble.size * 0.4,
            spreadRadius: bubble.size * 0.05,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(shimmerOpacity),
            blurRadius: bubble.size * 0.25,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 이모지 (중앙)
          Center(
            child: Text(
              bubble.emoji,
              style: TextStyle(fontSize: bubble.size * 0.38),
            ),
          ),
          // 왼쪽 상단 하이라이트
          Positioned(
            top: bubble.size * 0.12,
            left: bubble.size * 0.14,
            child: Container(
              width: bubble.size * 0.28,
              height: bubble.size * 0.18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(bubble.size),
              ),
            ),
          ),
          // 오른쪽 하단 작은 반짝임
          Positioned(
            bottom: bubble.size * 0.18,
            right: bubble.size * 0.18,
            child: Container(
              width: bubble.size * 0.10,
              height: bubble.size * 0.10,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Painter — 하늘, 구름, 무지개, 풀밭
// ─────────────────────────────────────────────────────────────────────────────

class _SkyBgPainter extends CustomPainter {
  final double time;
  _SkyBgPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 하늘 그라데이션
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4FC3F7), // 하늘색
          Color(0xFF81D4FA),
          Color(0xFFB3E5FC),
          Color(0xFFE1F5FE),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. 무지개 (가운데 살짝 위)
    _drawRainbow(canvas, Offset(w * 0.5, h * 0.55), w * 0.65);

    // 3. 구름들 (천천히 흘러감)
    _drawCloud(canvas, Offset((w * 0.15 + time * 12) % (w + 120) - 60, h * 0.10), 1.1);
    _drawCloud(canvas, Offset((w * 0.6 + time * 8) % (w + 120) - 60, h * 0.05), 0.8);
    _drawCloud(canvas, Offset((w * 1.1 + time * 15) % (w + 120) - 60, h * 0.18), 0.95);
    _drawCloud(canvas, Offset((w * 0.35 + time * 10) % (w + 200) - 100, h * 0.28), 0.65);

    // 4. 반짝이는 비눗방울 (배경 장식)
    final rng = Random(77);
    for (int i = 0; i < 12; i++) {
      final bx = rng.nextDouble() * w;
      final by = rng.nextDouble() * h * 0.7;
      final br = 6.0 + rng.nextDouble() * 10;
      final pulse = (sin(time * 1.5 + i * 0.9) * 0.5 + 0.5);
      final bColor = [
        const Color(0xFFFF6B9D),
        const Color(0xFF7C4DFF),
        const Color(0xFF2979FF),
        const Color(0xFF00BCD4),
      ][i % 4];
      canvas.drawCircle(
        Offset(bx, by),
        br * (0.7 + pulse * 0.4),
        Paint()..color = bColor.withOpacity(0.08 + pulse * 0.10),
      );
    }

    // 5. 풀밭 (하단)
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
      ).createShader(Rect.fromLTRB(0, h * 0.84, w, h));
    final grassPath = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.25, h * 0.84, w * 0.5, h * 0.87)
      ..quadraticBezierTo(w * 0.75, h * 0.90, w, h * 0.85)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grassPath, grassPaint);

    // 풀잎들 (물결)
    _drawGrassBlades(canvas, size, time);

    // 6. 꽃들
    _drawFlowers(canvas, size, time);
  }

  void _drawRainbow(Canvas canvas, Offset center, double radius) {
    final colors = [
      const Color(0xFFFF5252),
      const Color(0xFFFF9800),
      const Color(0xFFFFEB3B),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFF9C27B0),
    ];
    for (int i = 0; i < colors.length; i++) {
      final r = radius - i * 12;
      if (r <= 0) continue;
      final paint = Paint()
        ..color = colors[i].withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawArc(
        Rect.fromCenter(center: center, width: r * 2, height: r * 1.1),
        pi, pi,
        false,
        paint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withOpacity(0.88);
    final offsets = [
      Offset.zero,
      Offset(-28 * scale, 10 * scale),
      Offset(26 * scale, 8 * scale),
      Offset(-52 * scale, 16 * scale),
      Offset(48 * scale, 16 * scale),
    ];
    final radii = [22.0, 16.0, 18.0, 12.0, 14.0];
    for (int i = 0; i < offsets.length; i++) {
      canvas.drawCircle(center + offsets[i], radii[i] * scale, paint);
    }
  }

  void _drawGrassBlades(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rng = Random(55);
    for (int i = 0; i < 30; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = size.height * 0.84 + rng.nextDouble() * size.height * 0.06;
      final h = 14 + rng.nextDouble() * 20;
      final sway = sin(time * 2.0 + i * 0.5) * 5;
      final path = Path()
        ..moveTo(bx, by)
        ..quadraticBezierTo(bx + sway, by - h * 0.6, bx + sway * 1.4, by - h);
      canvas.drawPath(path, paint);
    }
  }

  void _drawFlowers(Canvas canvas, Size size, double time) {
    final rng = Random(33);
    const flowerEmojis = ['🌸', '🌼', '🌺', '💐'];
    for (int i = 0; i < 8; i++) {
      final fx = rng.nextDouble() * size.width;
      final fy = size.height * 0.86 + rng.nextDouble() * size.height * 0.08;
      final bob = sin(time * 1.8 + i) * 2;
      // TextPainter로 이모지 그리기
      final tp = TextPainter(
        text: TextSpan(
          text: flowerEmojis[i % flowerEmojis.length],
          style: const TextStyle(fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(fx, fy + bob);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SkyBgPainter old) => old.time != time;
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle + popup painter
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<PopParticle> particles;
  final List<ScorePopup> popups;

  _ParticlePainter({required this.particles, required this.popups});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()..color = p.color.withOpacity(p.opacity.clamp(0.0, 1.0)),
      );
    }
    for (final p in popups) {
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: Colors.white.withOpacity(p.opacity.clamp(0.0, 1.0)),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 4)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget entry point
// ─────────────────────────────────────────────────────────────────────────────

class BubblePopGame extends StatefulWidget {
  const BubblePopGame({super.key});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}
