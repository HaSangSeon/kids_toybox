import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';

// ══════════════════════════════════════════════════════════════════════════════
// 슬라이드 퍼즐 – 캐릭터 일러스트 테마 정의
// ══════════════════════════════════════════════════════════════════════════════

class _PuzzleTheme {
  final String name;
  final String titleEmoji;
  final List<Color> bg;
  final Color emptyColor;

  const _PuzzleTheme({
    required this.name,
    required this.titleEmoji,
    required this.bg,
    required this.emptyColor,
  });
}

const _themes = [
  _PuzzleTheme(
    name: '사자왕 🦁',
    titleEmoji: '🦁',
    bg: [Color(0xFFFFB74D), Color(0xFFFF9800)],
    emptyColor: Color(0xFFFFE0B2),
  ),
  _PuzzleTheme(
    name: '아기 곰 🐻',
    titleEmoji: '🐻',
    bg: [Color(0xFFA1887F), Color(0xFF6D4C41)],
    emptyColor: Color(0xDDF5F5F5),
  ),
  _PuzzleTheme(
    name: '분홍 고양이 🐱',
    titleEmoji: '🐱',
    bg: [Color(0xFFF48FB1), Color(0xFFC2185B)],
    emptyColor: Color(0xFFFCE4EC),
  ),
  _PuzzleTheme(
    name: '남극 펭귄 🐧',
    titleEmoji: '🐧',
    bg: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
    emptyColor: Color(0xFFE0F7FA),
  ),
  _PuzzleTheme(
    name: '아기 공룡 🦖',
    titleEmoji: '🦖',
    bg: [Color(0xFF81C784), Color(0xFF388E3C)],
    emptyColor: Color(0xFFE8F5E9),
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// 메인 게임 위젯
// ══════════════════════════════════════════════════════════════════════════════

class SlidePuzzleGame extends StatefulWidget {
  const SlidePuzzleGame({super.key});

  @override
  State<SlidePuzzleGame> createState() => _SlidePuzzleGameState();
}

class _SlidePuzzleGameState extends State<SlidePuzzleGame>
    with TickerProviderStateMixin {
  // ── 레벨 & 상태 변수 ────────────────────────────────────────────────────────
  int _currentLevel = 1; // 1단계 ~ 4단계
  int _themeIndex = 0;
  int _gridSize = 2; // Level 1: 2x2, Level 2: 3x3, Level 3: 3x3, Level 4: 4x4
  late List<int> _tiles;
  int _moves = 0;
  bool _solved = false;
  bool _showPreview = false;
  bool _showNumbers = true;
  int _coinsEarned = 0;

  // ── 애니메이션 ─────────────────────────────────────────────────────────────
  late ConfettiController _confetti;
  late AnimationController _solvedCtrl;
  late Animation<double> _solvedScale;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;
  late AnimationController _cloudFloatCtrl;

  Offset _tileDragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _solvedCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _solvedScale = CurvedAnimation(parent: _solvedCtrl, curve: Curves.elasticOut);
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0.02, 0))
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _cloudFloatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _applyLevelConfig();
    _initPuzzle();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _solvedCtrl.dispose();
    _shakeCtrl.dispose();
    _cloudFloatCtrl.dispose();
    super.dispose();
  }

  void _applyLevelConfig() {
    switch (_currentLevel) {
      case 1:
        _gridSize = 2; // 1단계: 2x2 (블록 3개, 입문)
        _showNumbers = true;
        break;
      case 2:
        _gridSize = 3; // 2단계: 3x3 (블록 8개, 보통)
        _showNumbers = true;
        break;
      case 3:
        _gridSize = 3; // 3단계: 3x3 (숫자 없이 그림 집중)
        _showNumbers = false;
        break;
      case 4:
      default:
        _gridSize = 4; // 4단계: 4x4 (블록 15개, 마스터)
        _showNumbers = true;
        break;
    }
  }

  void _initPuzzle() {
    final n = _gridSize * _gridSize;
    // 정답 상태: 1, 2, 3, ..., N-1, 0 (0이 맨 마지막 빈칸)
    _tiles = List.generate(n, (i) => (i + 1) % n);
    _moves = 0;
    _solved = false;
    _solvedCtrl.reset();
    _shuffle();
  }

  void _shuffle() {
    final rng = Random();
    int blank = _tiles.indexOf(0);
    final shuffleSteps = _gridSize == 2 ? 20 : (_gridSize == 3 ? 120 : 250);
    for (int i = 0; i < shuffleSteps; i++) {
      final neighbors = _getNeighbors(blank);
      final next = neighbors[rng.nextInt(neighbors.length)];
      _tiles[blank] = _tiles[next];
      _tiles[next] = 0;
      blank = next;
    }
    if (_isSolved()) _shuffle();
  }

  List<int> _getNeighbors(int idx) {
    final n = _gridSize;
    final row = idx ~/ n;
    final col = idx % n;
    final neighbors = <int>[];
    if (row > 0) neighbors.add(idx - n);
    if (row < n - 1) neighbors.add(idx + n);
    if (col > 0) neighbors.add(idx - 1);
    if (col < n - 1) neighbors.add(idx + 1);
    return neighbors;
  }

  void _onTileTap(int tileIdx) {
    if (_solved) return;
    final blank = _tiles.indexOf(0);
    final neighbors = _getNeighbors(blank);
    if (!neighbors.contains(tileIdx)) {
      _shakeCtrl.forward(from: 0);
      return;
    }
    HapticFeedback.lightImpact();
    AudioManager.instance.playClick();
    setState(() {
      _tiles[blank] = _tiles[tileIdx];
      _tiles[tileIdx] = 0;
      _moves++;
    });
    if (_isSolved()) _onSolved();
  }

  bool _isSolved() {
    for (int i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  bool _showSolvedDialog = false; // 완성 팝업 지연 표시 유무

  void _onSolved() {
    setState(() {
      _solved = true;
      _showSolvedDialog = false; // 맞춘 직후에는 팝업을 띄우지 않음
    });
    _confetti.play();
    
    // 별 코인 보상 밸런스 조정 (1단계: +1⭐, 2단계: +2⭐, 3단계: +3⭐, 4단계: +5⭐)
    final coins = _currentLevel == 1 ? 1 : (_currentLevel == 2 ? 2 : (_currentLevel == 3 ? 3 : 5));
    _coinsEarned = coins;
    PlayerDataManager.instance.addStarCoin(coins);

    // 완성된 동물 일러스트 그림을 2.5초 동안 여유롭게 감상할 시간 제공!
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted && _solved) {
        setState(() => _showSolvedDialog = true);
        _solvedCtrl.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_themeIndex];
    return Scaffold(
      body: Stack(
        children: [
          // ── 배경 그라디언트 ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.bg,
              ),
            ),
          ),

          // ── ☁️ 몽실몽실 아기자기 키즈 배경 장식 ──────────────────────
          AnimatedBuilder(
            animation: _cloudFloatCtrl,
            builder: (context, _) {
              final floatVal = sin(_cloudFloatCtrl.value * pi * 2) * 8;
              return Stack(
                children: [
                  // 상단 무지개 구름 1
                  Positioned(
                    left: -20,
                    top: 40 + floatVal,
                    child: _buildCloudWidget(110, Colors.white.withValues(alpha: 0.25)),
                  ),
                  // 상단 오른쪽 무지개 구름 2
                  Positioned(
                    right: -30,
                    top: 100 - floatVal,
                    child: _buildCloudWidget(130, Colors.white.withValues(alpha: 0.2)),
                  ),
                  // 반짝이는 별 🌟
                  Positioned(
                    left: 40,
                    top: 160 + floatVal * 0.5,
                    child: const Text('✨', style: TextStyle(fontSize: 22)),
                  ),
                  Positioned(
                    right: 50,
                    top: 220 - floatVal * 0.5,
                    child: const Text('🌟', style: TextStyle(fontSize: 26)),
                  ),
                  Positioned(
                    left: 70,
                    bottom: 120 + floatVal,
                    child: const Text('💖', style: TextStyle(fontSize: 20)),
                  ),
                  Positioned(
                    right: 40,
                    bottom: 180 - floatVal,
                    child: const Text('🎈', style: TextStyle(fontSize: 24)),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                const SizedBox(height: 4),
                _buildStats(theme),
                const SizedBox(height: 6),
                _buildLevelBar(theme),
                const SizedBox(height: 6),
                _buildThemeSelector(),
                const SizedBox(height: 8),
                // 🖼️ 퍼즐 판 바로 위에 배치된 큼직하고 예쁜 완성본 액자 카드!
                _buildTargetPreviewCard(theme),
                const SizedBox(height: 8),
                Expanded(child: _buildPuzzleArea(theme)),
                const SizedBox(height: 10),
              ],
            ),
          ),

          if (_solved && _showSolvedDialog) _buildSolvedOverlay(theme),
          if (_showPreview) _buildPreviewOverlay(theme),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 35,
              gravity: 0.3,
              colors: const [
                Colors.pink, Colors.yellow, Colors.cyan,
                Colors.orange, Colors.purple, Colors.green,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 구름 커스텀 쉐입
  Widget _buildCloudWidget(double width, Color color) {
    return Container(
      width: width,
      height: width * 0.6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }

  // ── 상단 헤더 ────────────────────────────────────────────────────────────
  Widget _buildHeader(_PuzzleTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); Navigator.pop(context); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          Text(
            '${theme.titleEmoji} 슬라이드 퍼즐',
            style: GoogleFonts.jua(
              fontSize: 22,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44), // 균형을 위한 여백
        ],
      ),
    );
  }

  // ── 통계 칩 ────────────────────────────────────────────────────────────
  Widget _buildStats(_PuzzleTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statChip(Icons.touch_app_rounded, '$_moves번 이동', Colors.white),
          const SizedBox(width: 8),
          ValueListenableBuilder<int>(
            valueListenable: PlayerDataManager.instance.starCoinsNotifier,
            builder: (_, coins, _) =>
              _statChip(Icons.star_rounded, '$coins ⭐', const Color(0xFFFFD700)),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.jua(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }

  // ── 🖼️ 큼직한 완성본 액자 카드 ─────────────────────────────────────────
  Widget _buildTargetPreviewCard(_PuzzleTheme theme) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playClick();
        setState(() => _showPreview = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showPreview = false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.shade400, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 큼직한 완성 그림 액자 (105 x 105)
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.bg.first, width: 2.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: CustomPaint(
                  painter: _FullIllustrationPainter(themeIndex: _themeIndex),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '🖼️ 완성 그림 목표',
                    style: GoogleFonts.jua(fontSize: 12, color: Colors.brown.shade900),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theme.name,
                  style: GoogleFonts.jua(fontSize: 16, color: theme.bg.last),
                ),
                const SizedBox(height: 2),
                Text(
                  '🔍 터치하면 크게 확대',
                  style: GoogleFonts.jua(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── ⭐️ 1~4 단계 레벨 선택 바 ─────────────────────────────────────────────
  Widget _buildLevelBar(_PuzzleTheme theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          _levelTab(1, '1단계 (2×2)', '⭐ 아주 쉬움'),
          _levelTab(2, '2단계 (3×3)', '⭐⭐ 보통'),
          _levelTab(3, '3단계 (그림)', '⭐⭐⭐ 집중'),
          _levelTab(4, '4단계 (4×4)', '👑 도전'),
        ],
      ),
    );
  }

  Widget _levelTab(int level, String title, String subtitle) {
    final selected = _currentLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentLevel == level) return;
          AudioManager.instance.playClick();
          setState(() {
            _currentLevel = level;
            _applyLevelConfig();
            _initPuzzle();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.jua(
                  fontSize: 12,
                  color: selected ? Colors.orange.shade900 : Colors.white,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.jua(
                  fontSize: 9,
                  color: selected ? Colors.deepOrange : Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 테마 선택 ─────────────────────────────────────────────────────────────
  Widget _buildThemeSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _themes.length,
        itemBuilder: (context, i) {
          final selected = i == _themeIndex;
          final t = _themes[i];
          return GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() { _themeIndex = i; _initPuzzle(); });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: selected ? 1 : 0.4), width: 2),
              ),
              child: Center(
                child: Text(
                  t.name,
                  style: GoogleFonts.jua(
                    fontSize: 13,
                    color: selected ? t.bg.last : Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 퍼즐 판 ─────────────────────────────────────────────────────────────
  Widget _buildPuzzleArea(_PuzzleTheme theme) {
    return Center(
      child: SlideTransition(
        position: _shakeAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // 🖼️ 은은한 완성본 가이드 워터마크 (상시 배경)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.22,
                        child: CustomPaint(
                          painter: _FullIllustrationPainter(themeIndex: _themeIndex),
                        ),
                      ),
                    ),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _gridSize,
                        mainAxisSpacing: _solved ? 0 : 5,
                        crossAxisSpacing: _solved ? 0 : 5,
                      ),
                      itemCount: _gridSize * _gridSize,
                      itemBuilder: (context, i) => _buildTile(i, theme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int idx, _PuzzleTheme theme) {
    final value = _tiles[idx];
    final isEmpty = value == 0 && !_solved;

    final blank = _tiles.indexOf(0);
    final isMovable = !isEmpty && _getNeighbors(blank).contains(idx);

    return GestureDetector(
      onTap: () => _onTileTap(idx),
      onPanStart: (_) {
        _tileDragOffset = Offset.zero;
      },
      onPanUpdate: (details) {
        _tileDragOffset += details.delta;
      },
      onPanEnd: (_) {
        if (_tileDragOffset.distance > 8) {
          final dx = _tileDragOffset.dx;
          final dy = _tileDragOffset.dy;

          if (isMovable) {
            final row = idx ~/ _gridSize;
            final col = idx % _gridSize;
            final blankRow = blank ~/ _gridSize;
            final blankCol = blank % _gridSize;

            bool isDraggingTowardsBlank = false;
            if (dx.abs() > dy.abs()) {
              if (dx > 0 && blankCol > col) isDraggingTowardsBlank = true;
              if (dx < 0 && blankCol < col) isDraggingTowardsBlank = true;
            } else {
              if (dy > 0 && blankRow > row) isDraggingTowardsBlank = true;
              if (dy < 0 && blankRow < row) isDraggingTowardsBlank = true;
            }

            if (isDraggingTowardsBlank || _tileDragOffset.distance > 15) {
              _onTileTap(idx);
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isEmpty
              ? theme.emptyColor.withValues(alpha: 0.4)
              : Colors.white,
          borderRadius: BorderRadius.circular(_solved ? 0 : (_gridSize == 2 ? 18 : (_gridSize == 3 ? 12 : 8))),
          border: isEmpty
              ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2)
              : _solved
                  ? null
                  : Border.all(
                      color: isMovable ? Colors.amber : Colors.white,
                      width: isMovable ? 3 : 1,
                    ),
        ),
        child: isEmpty
            ? Center(
                child: Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: _gridSize == 2 ? 38 : (_gridSize == 3 ? 28 : 20),
                ),
              )
            : Stack(
                children: [
                  // 🎨 일러스트 조각 렌더러
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_solved ? 0 : (_gridSize == 2 ? 15 : (_gridSize == 3 ? 10 : 6))),
                      child: CustomPaint(
                        painter: _TilePiecePainter(
                          themeIndex: _themeIndex,
                          targetValue: value,
                          gridSize: _gridSize,
                        ),
                      ),
                    ),
                  ),
                  // 숫자 힌트 뱃지 (좌상단)
                  if (_showNumbers && !_solved)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$value',
                          style: GoogleFonts.jua(
                            fontSize: _gridSize == 2 ? 14 : (_gridSize == 3 ? 12 : 10),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  // ── 완성 오버레이 ─────────────────────────────────────────────────────────
  Widget _buildSolvedOverlay(_PuzzleTheme theme) {
    final hasNextLevel = _currentLevel < 4;
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: ScaleTransition(
          scale: _solvedScale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: theme.bg.last.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉 성공! 대단해요! 🎉', style: GoogleFonts.jua(fontSize: 26, color: theme.bg.last)),
                const SizedBox(height: 6),
                Text(
                  '$_currentLevel단계 (${theme.name}) 완성!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 14),
                // 완성본 썸네일
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.bg.first, width: 3.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: _FullIllustrationPainter(themeIndex: _themeIndex),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('보상: ', style: GoogleFonts.jua(fontSize: 16)),
                    Text('+$_coinsEarned ⭐', style: GoogleFonts.jua(fontSize: 20, color: Colors.amber.shade800)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (hasNextLevel)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            AudioManager.instance.playClick();
                            setState(() {
                              _currentLevel++;
                              _applyLevelConfig();
                              _initPuzzle();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('${_currentLevel + 1}단계 도전! 🚀', style: GoogleFonts.jua(fontSize: 15)),
                        ),
                      ),
                    if (hasNextLevel) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            if (hasNextLevel) {
                              _initPuzzle(); // 동일 동물 동일 레벨 다시하기
                            } else {
                              _currentLevel = 1; // 4단계 완료 시 다음 동물 1단계로
                              _themeIndex = (_themeIndex + 1) % _themes.length;
                              _applyLevelConfig();
                              _initPuzzle();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.bg.first,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(hasNextLevel ? '다시하기 🔄' : '다음 동물 도전! ➡️', style: GoogleFonts.jua(fontSize: 15)),
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

  // ── 미리보기 오버레이 ─────────────────────────────────────────────────────
  Widget _buildPreviewOverlay(_PuzzleTheme theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🖼️ 완성될 그림 미리보기', style: GoogleFonts.jua(fontSize: 20, color: theme.bg.last)),
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    painter: _FullIllustrationPainter(themeIndex: _themeIndex),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('이 모양으로 맞춰보세요!', style: GoogleFonts.jua(fontSize: 14, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 캐릭터 조각 & 전체 일러스트 CustomPainter 구현
// ══════════════════════════════════════════════════════════════════════════════

class _TilePiecePainter extends CustomPainter {
  final int themeIndex;
  final int targetValue; // 1 ~ gridSize*gridSize - 1
  final int gridSize;

  _TilePiecePainter({
    required this.themeIndex,
    required this.targetValue,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (targetValue == 0) return;

    final origIndex = targetValue - 1;
    final origRow = origIndex ~/ gridSize;
    final origCol = origIndex % gridSize;

    canvas.save();
    canvas.translate(-origCol * size.width, -origRow * size.height);

    final totalSize = Size(size.width * gridSize, size.height * gridSize);
    _drawFullIllustration(canvas, totalSize, themeIndex);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TilePiecePainter oldDelegate) {
    return oldDelegate.themeIndex != themeIndex ||
        oldDelegate.targetValue != targetValue ||
        oldDelegate.gridSize != gridSize;
  }
}

class _FullIllustrationPainter extends CustomPainter {
  final int themeIndex;
  _FullIllustrationPainter({required this.themeIndex});

  @override
  void paint(Canvas canvas, Size size) {
    _drawFullIllustration(canvas, size, themeIndex);
  }

  @override
  bool shouldRepaint(covariant _FullIllustrationPainter oldDelegate) =>
      oldDelegate.themeIndex != themeIndex;
}

// ══════════════════════════════════════════════════════════════════════════════
// 동물 일러스트 그래픽 드로잉 함수
// ══════════════════════════════════════════════════════════════════════════════

void _drawFullIllustration(Canvas canvas, Size size, int themeIndex) {
  final w = size.width;
  final h = size.height;
  final center = Offset(w / 2, h / 2);

  switch (themeIndex) {
    case 0:
      _drawLionIllustration(canvas, size, center);
      break;
    case 1:
      _drawBearIllustration(canvas, size, center);
      break;
    case 2:
      _drawCatIllustration(canvas, size, center);
      break;
    case 3:
      _drawPenguinIllustration(canvas, size, center);
      break;
    case 4:
      _drawDinoIllustration(canvas, size, center);
      break;
  }
}

// 1. 🦁 사자왕 일러스트
void _drawLionIllustration(Canvas canvas, Size size, Offset center) {
  final w = size.width;
  final h = size.height;

  final bgPaint = Paint()..color = const Color(0xFFFFF8E1);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  final grassPaint = Paint()..color = const Color(0xFFAED581);
  canvas.drawOval(Rect.fromLTWH(-w * 0.2, h * 0.7, w * 1.4, h * 0.5), grassPaint);

  final manePaint = Paint()..color = const Color(0xFFE65100);
  canvas.drawCircle(center, w * 0.38, manePaint);

  final maneOrange = Paint()..color = const Color(0xFFF57C00);
  for (int i = 0; i < 12; i++) {
    final angle = (i * 30) * pi / 180;
    final pos = center + Offset(cos(angle) * w * 0.35, sin(angle) * w * 0.35);
    canvas.drawCircle(pos, w * 0.08, maneOrange);
  }

  final facePaint = Paint()..color = const Color(0xFFFFB74D);
  canvas.drawCircle(center, w * 0.28, facePaint);

  final earPaint = Paint()..color = const Color(0xFFFFB74D);
  final earInner = Paint()..color = const Color(0xFFFFE0B2);
  canvas.drawCircle(center + Offset(-w * 0.22, -h * 0.2), w * 0.07, earPaint);
  canvas.drawCircle(center + Offset(-w * 0.22, -h * 0.2), w * 0.04, earInner);
  canvas.drawCircle(center + Offset(w * 0.22, -h * 0.2), w * 0.07, earPaint);
  canvas.drawCircle(center + Offset(w * 0.22, -h * 0.2), w * 0.04, earInner);

  final eyeWhite = Paint()..color = Colors.white;
  final eyeBlack = Paint()..color = Colors.black;
  final eyePupil = Paint()..color = Colors.white;

  final leftEye = center + Offset(-w * 0.1, -h * 0.04);
  final rightEye = center + Offset(w * 0.1, -h * 0.04);

  canvas.drawCircle(leftEye, w * 0.05, eyeWhite);
  canvas.drawCircle(leftEye, w * 0.035, eyeBlack);
  canvas.drawCircle(leftEye + const Offset(-2, -2), w * 0.012, eyePupil);

  canvas.drawCircle(rightEye, w * 0.05, eyeWhite);
  canvas.drawCircle(rightEye, w * 0.035, eyeBlack);
  canvas.drawCircle(rightEye + const Offset(-2, -2), w * 0.012, eyePupil);

  final blush = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.6);
  canvas.drawCircle(center + Offset(-w * 0.16, h * 0.04), w * 0.04, blush);
  canvas.drawCircle(center + Offset(w * 0.16, h * 0.04), w * 0.04, blush);

  final muzzlePaint = Paint()..color = Colors.white;
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.08), width: w * 0.2, height: h * 0.12), muzzlePaint);

  final nosePaint = Paint()..color = const Color(0xFF5D4037);
  final nosePath = Path()
    ..moveTo(center.dx - w * 0.04, center.dy + h * 0.04)
    ..lineTo(center.dx + w * 0.04, center.dy + h * 0.04)
    ..lineTo(center.dx, center.dy + h * 0.08)
    ..close();
  canvas.drawPath(nosePath, nosePaint);

  final mouthStroke = Paint()
    ..color = const Color(0xFF5D4037)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(Rect.fromCircle(center: center + Offset(-w * 0.035, h * 0.09), radius: w * 0.035), 0, pi, false, mouthStroke);
  canvas.drawArc(Rect.fromCircle(center: center + Offset(w * 0.035, h * 0.09), radius: w * 0.035), 0, pi, false, mouthStroke);

  final crownPaint = Paint()..color = const Color(0xFFFFD54F);
  final crownPath = Path()
    ..moveTo(center.dx - w * 0.12, center.dy - h * 0.28)
    ..lineTo(center.dx - w * 0.14, center.dy - h * 0.38)
    ..lineTo(center.dx - w * 0.06, center.dy - h * 0.32)
    ..lineTo(center.dx, center.dy - h * 0.40)
    ..lineTo(center.dx + w * 0.06, center.dy - h * 0.32)
    ..lineTo(center.dx + w * 0.14, center.dy - h * 0.38)
    ..lineTo(center.dx + w * 0.12, center.dy - h * 0.28)
    ..close();
  canvas.drawPath(crownPath, crownPaint);
}

// 2. 🐻 아기 곰 일러스트
void _drawBearIllustration(Canvas canvas, Size size, Offset center) {
  final w = size.width;
  final h = size.height;

  final bgPaint = Paint()..color = const Color(0xFFEFEBE9);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  final bodyPaint = Paint()..color = const Color(0xFF795548);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.25), width: w * 0.7, height: h * 0.6), bodyPaint);

  final bellyPaint = Paint()..color = const Color(0xDDF5F5F5);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.3), width: w * 0.45, height: h * 0.35), bellyPaint);

  canvas.drawCircle(center + Offset(-w * 0.25, -h * 0.22), w * 0.1, bodyPaint);
  canvas.drawCircle(center + Offset(w * 0.25, -h * 0.22), w * 0.1, bodyPaint);
  final earIn = Paint()..color = const Color(0xFFFFCCBC);
  canvas.drawCircle(center + Offset(-w * 0.25, -h * 0.22), w * 0.05, earIn);
  canvas.drawCircle(center + Offset(w * 0.25, -h * 0.22), w * 0.05, earIn);

  canvas.drawCircle(center + Offset(0, -h * 0.05), w * 0.3, bodyPaint);

  final snoutPaint = Paint()..color = const Color(0xFFD7CCC8);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, 0), width: w * 0.26, height: h * 0.2), snoutPaint);

  final eyePaint = Paint()..color = Colors.black;
  canvas.drawCircle(center + Offset(-w * 0.12, -h * 0.08), w * 0.035, eyePaint);
  canvas.drawCircle(center + Offset(w * 0.12, -h * 0.08), w * 0.035, eyePaint);

  final nosePaint = Paint()..color = const Color(0xFF3E2723);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, -h * 0.03), width: w * 0.09, height: h * 0.06), nosePaint);

  final mouthStroke = Paint()
    ..color = const Color(0xFF3E2723)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(center + Offset(0, 0), center + Offset(0, h * 0.04), mouthStroke);
  canvas.drawArc(Rect.fromCircle(center: center + Offset(-w * 0.04, h * 0.04), radius: w * 0.04), 0, pi, false, mouthStroke);
  canvas.drawArc(Rect.fromCircle(center: center + Offset(w * 0.04, h * 0.04), radius: w * 0.04), 0, pi, false, mouthStroke);

  final honeyJar = Paint()..color = const Color(0xFFFFB300);
  canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.6, h * 0.6, w * 0.25, h * 0.25), const Radius.circular(12)), honeyJar);
  final honeyText = Paint()..color = const Color(0xFFE65100);
  canvas.drawRect(Rect.fromLTWH(w * 0.62, h * 0.68, w * 0.21, h * 0.08), honeyText);
}

// 3. 🐱 분홍 고양이 일러스트
void _drawCatIllustration(Canvas canvas, Size size, Offset center) {
  final w = size.width;
  final h = size.height;

  final bgPaint = Paint()..color = const Color(0xFFFCE4EC);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  final catColor = Paint()..color = const Color(0xFFEC407A);
  final earIn = Paint()..color = const Color(0xFFFF80AB);

  final leftEar = Path()
    ..moveTo(center.dx - w * 0.32, center.dy - h * 0.08)
    ..lineTo(center.dx - w * 0.22, center.dy - h * 0.32)
    ..lineTo(center.dx - w * 0.06, center.dy - h * 0.22)
    ..close();
  canvas.drawPath(leftEar, catColor);

  final rightEar = Path()
    ..moveTo(center.dx + w * 0.32, center.dy - h * 0.08)
    ..lineTo(center.dx + w * 0.22, center.dy - h * 0.32)
    ..lineTo(center.dx + w * 0.06, center.dy - h * 0.22)
    ..close();
  canvas.drawPath(rightEar, catColor);

  final leftEarIn = Path()
    ..moveTo(center.dx - w * 0.28, center.dy - h * 0.10)
    ..lineTo(center.dx - w * 0.21, center.dy - h * 0.28)
    ..lineTo(center.dx - w * 0.10, center.dy - h * 0.20)
    ..close();
  canvas.drawPath(leftEarIn, earIn);

  final rightEarIn = Path()
    ..moveTo(center.dx + w * 0.28, center.dy - h * 0.10)
    ..lineTo(center.dx + w * 0.21, center.dy - h * 0.28)
    ..lineTo(center.dx + w * 0.10, center.dy - h * 0.20)
    ..close();
  canvas.drawPath(rightEarIn, earIn);

  canvas.drawCircle(center, w * 0.32, catColor);

  final eyeWhite = Paint()..color = Colors.white;
  final eyeGreen = Paint()..color = const Color(0xFF00E676);
  final pupil = Paint()..color = Colors.black;

  final leftE = center + Offset(-w * 0.12, -h * 0.06);
  final rightE = center + Offset(w * 0.12, -h * 0.06);

  canvas.drawCircle(leftE, w * 0.07, eyeWhite);
  canvas.drawCircle(leftE, w * 0.055, eyeGreen);
  canvas.drawOval(Rect.fromCenter(center: leftE, width: w * 0.025, height: h * 0.08), pupil);

  canvas.drawCircle(rightE, w * 0.07, eyeWhite);
  canvas.drawCircle(rightE, w * 0.055, eyeGreen);
  canvas.drawOval(Rect.fromCenter(center: rightE, width: w * 0.025, height: h * 0.08), pupil);

  final noseP = Paint()..color = const Color(0xFFC2185B);
  final nose = Path()
    ..moveTo(center.dx - w * 0.03, center.dy + h * 0.04)
    ..lineTo(center.dx + w * 0.03, center.dy + h * 0.04)
    ..lineTo(center.dx, center.dy + h * 0.07)
    ..close();
  canvas.drawPath(nose, noseP);

  final whisker = Paint()
    ..color = Colors.white
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(center + Offset(-w * 0.18, h * 0.03), center + Offset(-w * 0.38, 0), whisker);
  canvas.drawLine(center + Offset(-w * 0.18, h * 0.08), center + Offset(-w * 0.38, h * 0.10), whisker);
  canvas.drawLine(center + Offset(w * 0.18, h * 0.03), center + Offset(w * 0.38, 0), whisker);
  canvas.drawLine(center + Offset(w * 0.18, h * 0.08), center + Offset(w * 0.38, h * 0.10), whisker);
}

// 4. 🐧 남극 펭귄 일러스트
void _drawPenguinIllustration(Canvas canvas, Size size, Offset center) {
  final w = size.width;
  final h = size.height;

  final bg = Paint()..color = const Color(0xFFE0F7FA);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

  final pBody = Paint()..color = const Color(0xFF263238);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.05), width: w * 0.65, height: h * 0.75), pBody);

  final pBelly = Paint()..color = Colors.white;
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.12), width: w * 0.48, height: h * 0.58), pBelly);

  canvas.drawOval(Rect.fromCenter(center: center + Offset(-w * 0.32, h * 0.15), width: w * 0.12, height: h * 0.35), pBody);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(w * 0.32, h * 0.15), width: w * 0.12, height: h * 0.35), pBody);

  final eyeB = Paint()..color = Colors.black;
  final eyeW = Paint()..color = Colors.white;

  canvas.drawCircle(center + Offset(-w * 0.1, -h * 0.12), w * 0.05, eyeW);
  canvas.drawCircle(center + Offset(-w * 0.1, -h * 0.12), w * 0.03, eyeB);
  canvas.drawCircle(center + Offset(-w * 0.11, -h * 0.13), w * 0.01, eyeW);

  canvas.drawCircle(center + Offset(w * 0.1, -h * 0.12), w * 0.05, eyeW);
  canvas.drawCircle(center + Offset(w * 0.1, -h * 0.12), w * 0.03, eyeB);
  canvas.drawCircle(center + Offset(w * 0.09, -h * 0.13), w * 0.01, eyeW);

  final beak = Paint()..color = const Color(0xFFFF9800);
  final beakPath = Path()
    ..moveTo(center.dx - w * 0.06, center.dy - h * 0.05)
    ..lineTo(center.dx + w * 0.06, center.dy - h * 0.05)
    ..lineTo(center.dx, center.dy + h * 0.03)
    ..close();
  canvas.drawPath(beakPath, beak);

  final headset = Paint()
    ..color = const Color(0xFFFF4081)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawArc(Rect.fromCircle(center: center + Offset(0, -h * 0.18), radius: w * 0.22), pi, pi, false, headset);
  final pad = Paint()..color = const Color(0xFFFF4081);
  canvas.drawCircle(center + Offset(-w * 0.22, -h * 0.18), w * 0.06, pad);
  canvas.drawCircle(center + Offset(w * 0.22, -h * 0.18), w * 0.06, pad);
}

// 5. 🦖 아기 공룡 일러스트
void _drawDinoIllustration(Canvas canvas, Size size, Offset center) {
  final w = size.width;
  final h = size.height;

  final bg = Paint()..color = const Color(0xFFE8F5E9);
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

  final dinoG = Paint()..color = const Color(0xFF4CAF50);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.1), width: w * 0.65, height: h * 0.6), dinoG);

  canvas.drawCircle(center + Offset(0, -h * 0.15), w * 0.28, dinoG);

  final spike = Paint()..color = const Color(0xFFFF7043);
  for (int i = 0; i < 4; i++) {
    final path = Path()
      ..moveTo(center.dx - w * 0.26 + (i * w * 0.12), center.dy - h * 0.36)
      ..lineTo(center.dx - w * 0.20 + (i * w * 0.12), center.dy - h * 0.26)
      ..lineTo(center.dx - w * 0.32 + (i * w * 0.12), center.dy - h * 0.26)
      ..close();
    canvas.drawPath(path, spike);
  }

  final eyeW = Paint()..color = Colors.white;
  final eyeB = Paint()..color = Colors.black;

  final eyePos = center + Offset(-w * 0.08, -h * 0.2);
  canvas.drawCircle(eyePos, w * 0.06, eyeW);
  canvas.drawCircle(eyePos, w * 0.038, eyeB);
  canvas.drawCircle(eyePos + const Offset(-2, -2), w * 0.012, eyeW);

  final eyePos2 = center + Offset(w * 0.08, -h * 0.2);
  canvas.drawCircle(eyePos2, w * 0.06, eyeW);
  canvas.drawCircle(eyePos2, w * 0.038, eyeB);
  canvas.drawCircle(eyePos2 + const Offset(-2, -2), w * 0.012, eyeW);

  final nostril = Paint()..color = const Color(0xFF2E7D32);
  canvas.drawCircle(center + Offset(-w * 0.05, -h * 0.1), w * 0.015, nostril);
  canvas.drawCircle(center + Offset(w * 0.05, -h * 0.1), w * 0.015, nostril);

  final belly = Paint()..color = const Color(0xFFFFF59D);
  canvas.drawOval(Rect.fromCenter(center: center + Offset(0, h * 0.18), width: w * 0.35, height: h * 0.35), belly);
}
