import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ── 레벨 설정 ──────────────────────────────────────────────────────────────
class _LevelConfig {
  final int level;
  final String label;
  final String emoji;
  final Color color;
  final int spawnIntervalMs;   // 두더지 등장 간격
  final int maxUp;             // 동시에 나올 수 있는 최대 두더지 수
  final int upDurationMs;      // 두더지가 올라와 있는 시간
  final int timeLimit;         // 라운드 제한시간(초)
  final double goldenChance;   // 황금두더지 확률
  final double spikyChance;    // 가시두더지 확률

  const _LevelConfig({
    required this.level,
    required this.label,
    required this.emoji,
    required this.color,
    required this.spawnIntervalMs,
    required this.maxUp,
    required this.upDurationMs,
    required this.timeLimit,
    required this.goldenChance,
    required this.spikyChance,
  });
}

const _levels = [
  _LevelConfig(
    level: 1, label: '아기', emoji: '🌱',
    color: Color(0xFF66BB6A),
    spawnIntervalMs: 1600, maxUp: 1, upDurationMs: 2200,
    timeLimit: 30, goldenChance: 0.0, spikyChance: 0.0,
  ),
  _LevelConfig(
    level: 2, label: '어린이', emoji: '🌼',
    color: Color(0xFFFFA726),
    spawnIntervalMs: 1100, maxUp: 2, upDurationMs: 1700,
    timeLimit: 35, goldenChance: 0.1, spikyChance: 0.0,
  ),
  _LevelConfig(
    level: 3, label: '전문가', emoji: '🌟',
    color: Color(0xFFEF5350),
    spawnIntervalMs: 700, maxUp: 3, upDurationMs: 1200,
    timeLimit: 40, goldenChance: 0.15, spikyChance: 0.12,
  ),
];

// ── 두더지 데이터 ────────────────────────────────────────────────────────────
enum MoleType { normal, golden, spikey }

class Mole {
  bool isUp = false;
  bool isWhacked = false;
  MoleType type = MoleType.normal;
  Timer? _autoRetractTimer;

  String get emoji {
    if (isWhacked) return '💥';
    switch (type) {
      case MoleType.normal: return '🐹';
      case MoleType.golden: return '⭐';
      case MoleType.spikey: return '🦔';
    }
  }

  void scheduleRetract(int ms, VoidCallback onRetract) {
    _autoRetractTimer?.cancel();
    _autoRetractTimer = Timer(Duration(milliseconds: ms), onRetract);
  }

  void cancelRetract() => _autoRetractTimer?.cancel();
}

// ── 떠다니는 점수 텍스트 ─────────────────────────────────────────────────────
class TapEffect {
  final Offset position;
  final String text;
  final Color color;
  double opacity = 1.0;
  double yOffset = 0.0;
  TapEffect({required this.position, required this.text, required this.color});
}

// ── 메인 게임 위젯 ───────────────────────────────────────────────────────────
class WhackAMoleGame extends StatefulWidget {
  const WhackAMoleGame({super.key});

  @override
  State<WhackAMoleGame> createState() => _WhackAMoleGameState();
}

class _WhackAMoleGameState extends State<WhackAMoleGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  final List<Mole> _moles = List.generate(9, (_) => Mole());
  final List<TapEffect> _effects = [];
  final Random _random = Random();

  Timer? _gameTimer;
  Timer? _spawnTimer;

  int _score = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _showLevelSelect = true;  // 처음엔 레벨 선택 화면

  int _selectedLevel = 0; // index into _levels
  _LevelConfig get _cfg => _levels[_selectedLevel];

  int? _activeHammerIndex;
  int _combo = 0;
  double _skyTime = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    for (final m in _moles) m.cancelRetract();
    super.dispose();
  }

  // ── Ticker: 배경 애니메이션 & 떠다니는 텍스트 ──────────────────────────────
  void _onTick(Duration elapsed) {
    final dt = ((elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1e6)
        .clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    setState(() {
      _skyTime += dt;
      if (_isPlaying && !_isGameOver) {
        for (final e in _effects) {
          e.yOffset -= 65.0 * dt;
          e.opacity -= 1.6 * dt;
        }
        _effects.removeWhere((e) => e.opacity <= 0);
      }
    });
  }

  // ── 게임 시작 ─────────────────────────────────────────────────────────────
  void _startGame() {
    for (final m in _moles) {
      m.cancelRetract();
      m.isUp = false;
      m.isWhacked = false;
    }
    setState(() {
      _score = 0;
      _combo = 0;
      _timeLeft = _cfg.timeLimit;
      _isPlaying = true;
      _isGameOver = false;
      _showLevelSelect = false;
      _activeHammerIndex = null;
      _effects.clear();
    });

    _lastElapsed = Duration.zero;
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _endGame();
      }
    });

    _startSpawning();
  }

  // ── 게임 종료 ─────────────────────────────────────────────────────────────
  void _endGame() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    for (final m in _moles) {
      m.cancelRetract();
      m.isUp = false;
    }
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
    AudioManager.instance.playGameOver();
  }

  // ── 두더지 스폰 루프 ──────────────────────────────────────────────────────
  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: _cfg.spawnIntervalMs),
      (_) {
        if (!_isPlaying || _isGameOver) return;
        _trySpawnMole();
      },
    );
  }

  void _trySpawnMole() {
    // 현재 올라와 있는 두더지 수
    final upCount = _moles.where((m) => m.isUp).length;
    if (upCount >= _cfg.maxUp) return;

    // 비어있는 구멍 중 랜덤 선택
    final empty = [
      for (int i = 0; i < _moles.length; i++)
        if (!_moles[i].isUp) i
    ];
    if (empty.isEmpty) return;

    final idx = empty[_random.nextInt(empty.length)];
    final mole = _moles[idx];

    // 타입 결정
    final r = _random.nextDouble();
    if (r < _cfg.goldenChance) {
      mole.type = MoleType.golden;
    } else if (r < _cfg.goldenChance + _cfg.spikyChance) {
      mole.type = MoleType.spikey;
    } else {
      mole.type = MoleType.normal;
    }

    setState(() {
      mole.isUp = true;
      mole.isWhacked = false;
    });

    // 일정 시간 후 자동 내려감
    mole.scheduleRetract(_cfg.upDurationMs, () {
      if (mounted) {
        setState(() {
          mole.isUp = false;
          mole.isWhacked = false;
        });
        // 놓쳤을 때 콤보 리셋
        if (!mole.isWhacked) _combo = 0;
      }
    });
  }

  // ── 두더지 탭 처리 ────────────────────────────────────────────────────────
  void _whackMole(int index, TapDownDetails details) {
    if (!_isPlaying) return;
    final mole = _moles[index];

    if (!mole.isUp || mole.isWhacked) return;

    mole.cancelRetract();
    mole.isWhacked = true;
    _combo++;

    setState(() {
      _activeHammerIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted && _activeHammerIndex == index) {
        setState(() {
          _activeHammerIndex = null;
          mole.isUp = false;
          mole.isWhacked = false;
        });
      }
    });

    String popText;
    Color popColor;
    int pts;

    final comboBonus = _combo >= 3 ? ' 🔥×$_combo' : '';

    switch (mole.type) {
      case MoleType.normal:
        pts = 10 + (_combo >= 3 ? (_combo - 2) * 5 : 0);
        popText = '+$pts$comboBonus';
        popColor = KidsTheme.yellow;
        _score += pts;
        AudioManager.instance.playHammerWhack();
        HapticFeedback.lightImpact();
        break;
      case MoleType.golden:
        pts = 30 + (_combo >= 3 ? (_combo - 2) * 10 : 0);
        popText = '+$pts ✨$comboBonus';
        popColor = Colors.amberAccent;
        _score += pts;
        AudioManager.instance.playHammerWhack();
        AudioManager.instance.playChime();
        HapticFeedback.mediumImpact();
        break;
      case MoleType.spikey:
        pts = -10;
        _score = max(0, _score - 10);
        _timeLeft = max(0, _timeLeft - 2);
        _combo = 0;
        popText = '-10 😖';
        popColor = KidsTheme.red;
        AudioManager.instance.playDamage();
        HapticFeedback.heavyImpact();
        break;
    }

    _effects.add(TapEffect(
      position: details.globalPosition,
      text: popText,
      color: popColor,
    ));

    setState(() {});
  }

  // ── 빌드 ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 아기자기한 동적 60fps 배경
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _FarmBackgroundPainter(_skyTime),
              ),
            ),
          ),

          if (_showLevelSelect)
            _buildLevelSelect(context)
          else ...[
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  if (_cfg.level >= 2) _buildLevelBadge(),
                  const Spacer(),
                  _buildGrid(),
                  const Spacer(),
                  if (_cfg.level == 1) _buildHintBanner(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // 떠다니는 점수 텍스트
            ..._effects.map((e) => Positioned(
              left: e.position.dx - 50,
              top: e.position.dy - 60 + e.yOffset,
              child: Opacity(
                opacity: e.opacity.clamp(0.0, 1.0),
                child: Text(
                  e.text,
                  style: GoogleFonts.jua(
                    fontSize: 28,
                    color: e.color,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                ),
              ),
            )),

            if (_isGameOver) _buildGameOver(),
          ],
        ],
      ),
    );
  }

  // ── 레벨 선택 화면 (아기자기하고 고급스러운 3D 디자인) ────────────────────────────────
  Widget _buildLevelSelect(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 뒤로가기
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF6B6B), width: 2.5),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFF6B6B), size: 28),
                ),
              ),
            ),
          ),
          const Spacer(),
          // 3D 글래스모피즘 타이틀
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0,8))],
            ),
            child: Column(
              children: [
                Text(
                  '🔨 두더지 잡기',
                  style: GoogleFonts.jua(fontSize: 38, color: KidsTheme.purple),
                ),
                const SizedBox(height: 4),
                Text(
                  '난이도를 선택하세요!',
                  style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFF636E72)),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 레벨 카드들
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(_levels.length, (i) {
                final cfg = _levels[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      HapticFeedback.lightImpact();
                      setState(() => _selectedLevel = i);
                      _startGame();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cfg.color,
                            HSLColor.fromColor(cfg.color).withLightness((HSLColor.fromColor(cfg.color).lightness - 0.08).clamp(0,1)).toColor(),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: HSLColor.fromColor(cfg.color).withLightness((HSLColor.fromColor(cfg.color).lightness - 0.2).clamp(0, 1)).toColor(),
                            offset: const Offset(0, 6),
                            blurRadius: 0,
                          ),
                          const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Text(cfg.emoji, style: const TextStyle(fontSize: 34)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lv${cfg.level} · ${cfg.label}',
                                  style: GoogleFonts.jua(fontSize: 24, color: Colors.white),
                                ),
                                Text(
                                  _levelDescription(cfg),
                                  style: GoogleFonts.jua(fontSize: 14, color: Colors.white.withOpacity(0.85)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  String _levelDescription(_LevelConfig cfg) {
    switch (cfg.level) {
      case 1: return '두더지 1마리씩, 천천히 등장해요 🐹';
      case 2: return '두더지 2마리, 황금두더지 등장 ✨';
      case 3: return '빠르게! 가시두더지 조심! 🦔';
      default: return '';
    }
  }

  // ── 헤더 (3D Glassmorphic 60fps 최적화 헤더) ──────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // 🏠 뒤로가기 / 레벨선택 버튼
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                _gameTimer?.cancel();
                _spawnTimer?.cancel();
                _ticker.stop();
                setState(() => _showLevelSelect = true);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 26),
              ),
            ),
            const SizedBox(width: 8),

            // 🎯 점수 뱃지 (별코인과 명확히 구분되는 타겟 아이콘)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '$_score점',
                    style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 🔥 콤보 뱃지
            if (_combo >= 3) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '🔥×$_combo',
                  style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // ⏰ 타이머 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _timeLeft <= 5
                      ? [const Color(0xFFFF4757), const Color(0xFFFF6B6B)]
                      : [const Color(0xFF2979FF), const Color(0xFF29B6F6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_timeLeft}초',
                    style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 레벨 뱃지 ─────────────────────────────────────────────────────────────
  Widget _buildLevelBadge() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: _cfg.color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Text(
          '${_cfg.emoji} Lv${_cfg.level} · ${_cfg.label}',
          style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  // ── 힌트 배너 (Lv1 전용) ─────────────────────────────────────────────────
  Widget _buildHintBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            '두더지를 쏙쏙! 누르세요!',
            style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark),
          ),
        ],
      ),
    );
  }

  // ── 두더지 그리드 ─────────────────────────────────────────────────────────
  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6D4C41),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF3E2723), width: 5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 8)),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 9,
        itemBuilder: (ctx, i) => _buildHole(i),
      ),
    );
  }

  Widget _buildHole(int index) {
    final mole = _moles[index];
    final showHammer = _activeHammerIndex == index;

    return GestureDetector(
      onTapDown: (d) => _whackMole(index, d),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 구멍
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A0A00),
              border: Border.all(color: const Color(0xFF3E2723), width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x88000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 구멍 내부 원형 그라데이션
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [const Color(0xFF3E2723), Colors.black],
                          radius: 0.8,
                        ),
                      ),
                    ),
                  ),
                  // 두더지 슬라이드 업/다운
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 130),
                    curve: Curves.easeOutBack,
                    bottom: mole.isUp ? 0 : -100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        mole.emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 망치 타격 애니메이션
          if (showHammer)
            Positioned(
              top: -38,
              right: -14,
              child: Transform.rotate(
                angle: -0.45,
                child: const Text('🔨', style: TextStyle(fontSize: 62)),
              ),
            ),
        ],
      ),
    );
  }

  // ── 게임 완주 팝업 (깔끔한 3D 디자인 및 메인 이동 버튼) ───────────────────
  Widget _buildGameOver() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 🔨 🏆', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 10),
              Text(
                '두더지 잡기 완료!',
                style: GoogleFonts.jua(fontSize: 26, color: KidsTheme.purple),
              ),
              const SizedBox(height: 4),
              Text(
                'Lv${_cfg.level} 미션 완료!',
                style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFF10AC84)),
              ),
              const SizedBox(height: 16),
              
              // 점수 & 보상 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('획득 점수: ', style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark)),
                        Text('$_score 점', style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFFFF6B6B))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('⭐ 별코인 +1 획득!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 버튼 영역: [🏠 메인으로] [🔄 다시하기]
              Row(
                children: [
                  // 🏠 메인으로
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '메인으로',
                                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 🔄 다시하기
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        HapticFeedback.mediumImpact();
                        setState(() => _isGameOver = false);
                        _startGame();
                      },
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '다시하기 🔄',
                                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

// ── 동적 배경 페인터 (농장/정원 테마 + 움직이는 구름/새) ─────────────────────────────────────────────
class _FarmBackgroundPainter extends CustomPainter {
  final double time;
  _FarmBackgroundPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 하늘
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBBDEFB), Color(0xFFE8F5E9)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 태양
    canvas.drawCircle(
      Offset(w * 0.88, h * 0.08),
      26,
      Paint()..color = const Color(0xFFFFD54F),
    );
    canvas.drawCircle(
      Offset(w * 0.88 - 7, h * 0.08 - 7),
      10,
      Paint()..color = const Color(0xFFFFF9C4),
    );

    // 구름들 (시간에 따라 이동)
    final cloudOffset1 = (time * 15) % (w + 200) - 100;
    final cloudOffset2 = (time * 10 + 200) % (w + 200) - 100;
    final cloudOffset3 = (time * 22 + 400) % (w + 200) - 100;

    _cloud(canvas, Offset(cloudOffset1, h * 0.06), 0.9);
    _cloud(canvas, Offset(w - cloudOffset2, h * 0.04), 1.2);
    _cloud(canvas, Offset(cloudOffset3, h * 0.10), 0.7);

    // 새들 (v 모양으로 날아감)
    final birdOffset1 = (time * 40) % (w + 100) - 50;
    final birdOffset2 = (time * 50 + 300) % (w + 100) - 50;
    _bird(canvas, Offset(birdOffset1, h * 0.15 + sin(time * 3) * 10), 1.0);
    _bird(canvas, Offset(w - birdOffset2, h * 0.2 + cos(time * 4) * 15), 0.7);

    // 뒷 언덕
    _hill(canvas, size, xOff: 0, yCenter: h * 0.60, width: w * 1.4,
        color: const Color(0xFF81C784));
    _hill(canvas, size, xOff: w * 0.35, yCenter: h * 0.65, width: w * 1.1,
        color: const Color(0xFF66BB6A));

    // 땅
    final groundPath = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.5, h * 0.64, w, h * 0.68)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, Paint()..color = const Color(0xFF558B2F));

    // 나무 울타리
    _fence(canvas, size);

    // 나무들
    _tree(canvas, Offset(w * 0.04, h * 0.66));
    _tree(canvas, Offset(w * 0.94, h * 0.65));
    _tree(canvas, Offset(w * 0.16, h * 0.70), scale: 0.72);
    _tree(canvas, Offset(w * 0.84, h * 0.69), scale: 0.78);

    // 꽃
    const flowerColors = [
      Color(0xFFFF80AB), Color(0xFFFFEB3B), Color(0xFF80DEEA),
      Color(0xFFFFA726), Color(0xFFCE93D8), Color(0xFF80CBC4),
    ];
    final flowerPos = [
      Offset(w * 0.10, h * 0.77), Offset(w * 0.24, h * 0.81),
      Offset(w * 0.40, h * 0.79), Offset(w * 0.58, h * 0.82),
      Offset(w * 0.72, h * 0.78), Offset(w * 0.88, h * 0.80),
    ];
    for (int i = 0; i < flowerPos.length; i++) {
      _flower(canvas, flowerPos[i], flowerColors[i % flowerColors.length]);
    }

    // 허수아비
    _scarecrow(canvas, Offset(w * 0.5, h * 0.58));
  }

  void _bird(Canvas canvas, Offset center, double scale) {
    final path = Path()
      ..moveTo(center.dx - 12 * scale, center.dy - 8 * scale)
      ..quadraticBezierTo(center.dx - 6 * scale, center.dy, center.dx, center.dy + 4 * scale)
      ..quadraticBezierTo(center.dx + 6 * scale, center.dy, center.dx + 12 * scale, center.dy - 8 * scale);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF78909C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _cloud(Canvas canvas, Offset c, double s) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (final pair in [
      [0.0, 0.0, 22.0], [-28.0, 8.0, 16.0],
      [26.0, 6.0, 18.0], [-50.0, 14.0, 13.0],
    ]) {
      canvas.drawCircle(c + Offset(pair[0] * s, pair[1] * s), pair[2] * s, p);
    }
  }

  void _hill(Canvas canvas, Size size,
      {required double xOff, required double yCenter,
       required double width, required Color color}) {
    final path = Path()
      ..moveTo(xOff, size.height)
      ..quadraticBezierTo(
          xOff + width / 2, yCenter - width * 0.22, xOff + width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _tree(Canvas canvas, Offset base, {double scale = 1.0}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base.translate(0, -18 * scale),
            width: 11 * scale, height: 36 * scale),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(base.translate(0, -50 * scale), 26 * scale,
        Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(base.translate(-9 * scale, -42 * scale), 18 * scale,
        Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(base.translate(9 * scale, -42 * scale), 20 * scale,
        Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(base.translate(0, -60 * scale), 16 * scale,
        Paint()..color = const Color(0xFF4CAF50));
  }

  void _flower(Canvas canvas, Offset c, Color color) {
    final pp = Paint()..color = color;
    final cp = Paint()..color = const Color(0xFFFFEB3B);
    for (int i = 0; i < 6; i++) {
      final a = i * pi / 3;
      canvas.drawCircle(c + Offset(cos(a) * 7, sin(a) * 7), 5, pp);
    }
    canvas.drawCircle(c, 5, cp);
    canvas.drawLine(c, c.translate(0, 12),
        Paint()..color = const Color(0xFF66BB6A)..strokeWidth = 2);
  }

  void _fence(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 3;
    final postPaint = Paint()
      ..color = const Color(0xFFA1887F)
      ..strokeWidth = 6;
    // 수평 막대
    canvas.drawLine(Offset(0, h * 0.73), Offset(w, h * 0.73), paint);
    canvas.drawLine(Offset(0, h * 0.77), Offset(w, h * 0.77), paint);
    // 기둥들
    for (double x = 0; x <= w; x += w / 6) {
      canvas.drawLine(Offset(x, h * 0.71), Offset(x, h * 0.79), postPaint);
    }
  }

  void _scarecrow(Canvas canvas, Offset base) {
    // 몸통
    canvas.drawLine(base, base.translate(0, -40),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 5);
    // 팔
    canvas.drawLine(base.translate(-28, -25), base.translate(28, -25),
        Paint()..color = const Color(0xFF795548)..strokeWidth = 4);
    // 머리
    canvas.drawCircle(base.translate(0, -50), 14,
        Paint()..color = const Color(0xFFFFCC80));
    // 모자
    final hatPath = Path()
      ..moveTo(base.dx - 16, base.dy - 62)
      ..lineTo(base.dx + 16, base.dy - 62)
      ..lineTo(base.dx + 10, base.dy - 80)
      ..lineTo(base.dx - 10, base.dy - 80)
      ..close();
    canvas.drawPath(hatPath, Paint()..color = const Color(0xFF5D4037));
    // 얼굴
    canvas.drawCircle(base.translate(-5, -52), 2.5,
        Paint()..color = const Color(0xFF4E342E));
    canvas.drawCircle(base.translate(5, -52), 2.5,
        Paint()..color = const Color(0xFF4E342E));
    // 웃음
    final smilePath = Path()
      ..moveTo(base.dx - 5, base.dy - 45)
      ..quadraticBezierTo(base.dx, base.dy - 41, base.dx + 5, base.dy - 45);
    canvas.drawPath(
        smilePath, Paint()..color = const Color(0xFF4E342E)..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _FarmBackgroundPainter oldDelegate) => true;
}
