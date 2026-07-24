import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

// ── 귀여운 파스텔 테마 정의 (세로 비율 최적화) ──────────────────────────────────
class MazeTheme {
  final String title;
  final int rows;
  final int cols;
  final String playerEmoji;
  final String goalEmoji;
  final Color wallColor;
  final Color wallBorderColor;
  final Color floorColor;
  final Color visitedColor;
  final List<Color> backgroundGradient;
  final String bgEmoji;
  final String stepEmoji;

  const MazeTheme({
    required this.title,
    required this.rows,
    required this.cols,
    required this.playerEmoji,
    required this.goalEmoji,
    required this.wallColor,
    required this.wallBorderColor,
    required this.floorColor,
    required this.visitedColor,
    required this.backgroundGradient,
    required this.bgEmoji,
    required this.stepEmoji,
  });
}

const _kThemes = <MazeTheme>[
  MazeTheme(
    title: '동물 농장 🐭', rows: 11, cols: 7,
    playerEmoji: '🐭', goalEmoji: '🧀',
    wallColor: Color(0xFFFFB74D), wallBorderColor: Color(0xFFFFA726),
    floorColor: Color(0xFFFFFDF9), visitedColor: Color(0xFFFFE0B2),
    backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    bgEmoji: '☁️', stepEmoji: '✨',
  ),
  MazeTheme(
    title: '바다 탐험 🐠', rows: 11, cols: 7,
    playerEmoji: '🐠', goalEmoji: '🐚',
    wallColor: Color(0xFF4FC3F7), wallBorderColor: Color(0xFF29B6F6),
    floorColor: Color(0xFFF4FCFE), visitedColor: Color(0xFFB2EBF2),
    backgroundGradient: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
    bgEmoji: '🫧', stepEmoji: '💧',
  ),
  MazeTheme(
    title: '꽃밭 나들이 🐝', rows: 13, cols: 7,
    playerEmoji: '🐝', goalEmoji: '🌻',
    wallColor: Color(0xFF81C784), wallBorderColor: Color(0xFF66BB6A),
    floorColor: Color(0xFFF9FBF7), visitedColor: Color(0xFFC8E6C9),
    backgroundGradient: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    bgEmoji: '✨', stepEmoji: '🌸',
  ),
  MazeTheme(
    title: '우주 비행 🚀', rows: 13, cols: 9,
    playerEmoji: '🚀', goalEmoji: '🌎',
    wallColor: Color(0xFFB39DDB), wallBorderColor: Color(0xFF9575CD),
    floorColor: Color(0xFFFAF8FF), visitedColor: Color(0xFFD1C4E9),
    backgroundGradient: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    bgEmoji: '⭐', stepEmoji: '✨',
  ),
  MazeTheme(
    title: '공룡 시대 🦕', rows: 15, cols: 9,
    playerEmoji: '🦕', goalEmoji: '🍖',
    wallColor: Color(0xFFFF8A65), wallBorderColor: Color(0xFFFF7043),
    floorColor: Color(0xFFFFFDF8), visitedColor: Color(0xFFFFCCBC),
    backgroundGradient: [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
    bgEmoji: '🌴', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '겨울 왕국 🐧', rows: 15, cols: 9,
    playerEmoji: '🐧', goalEmoji: '🧊',
    wallColor: Color(0xFF4DD0E1), wallBorderColor: Color(0xFF26C6DA),
    floorColor: Color(0xFFF7FCFC), visitedColor: Color(0xFFB2DFDB),
    backgroundGradient: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
    bgEmoji: '❄️', stepEmoji: '❄️',
  ),
  MazeTheme(
    title: '마법의 성 🦄', rows: 17, cols: 9,
    playerEmoji: '🦄', goalEmoji: '🏰',
    wallColor: Color(0xFFF06292), wallBorderColor: Color(0xFFEC407A),
    floorColor: Color(0xFFFDF7F9), visitedColor: Color(0xFFF8BBD0),
    backgroundGradient: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    bgEmoji: '🌟', stepEmoji: '💖',
  ),
];

// ── 미로 생성 (DFS – 100% 시작~끝 연결 보장) ─────────────────────────────────
List<List<int>> generateMaze(int rows, int cols, {int seed = 0}) {
  final maze = List.generate(rows, (_) => List.filled(cols, 1));
  final rng = Random(seed);

  void carve(int r, int c) {
    maze[r][c] = 0;
    final dirs = [[0, 2], [2, 0], [0, -2], [-2, 0]]..shuffle(rng);
    for (final d in dirs) {
      final nr = r + d[0], nc = c + d[1];
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && maze[nr][nc] == 1) {
        maze[r + d[0] ~/ 2][c + d[1] ~/ 2] = 0;
        carve(nr, nc);
      }
    }
  }

  // (0,0)부터 탐색 시작
  carve(0, 0);

  // 입구 및 출구 연결 보장
  maze[0][0] = 0;
  maze[rows - 1][cols - 1] = 0;

  if (rows > 1 && maze[rows - 2][cols - 1] == 1 && cols > 1 && maze[rows - 1][cols - 2] == 1) {
    maze[rows - 1][cols - 2] = 0;
  }

  return maze;
}

// ── 게임 위젯 ─────────────────────────────────────────────────────────────────
class MazeEscapeGame extends StatefulWidget {
  const MazeEscapeGame({super.key});
  @override
  State<MazeEscapeGame> createState() => _MazeEscapeGameState();
}

class _MazeEscapeGameState extends State<MazeEscapeGame>
    with TickerProviderStateMixin {
  int _totalScore = 0;
  int _levelIdx = 0;
  bool _isLevelClear = false;

  late List<List<int>> _maze;
  MazeTheme get _theme => _kThemes[_levelIdx % _kThemes.length];

  // 플레이어 위치 (픽셀 단위 float)
  double _px = 0, _py = 0;
  double _cellSize = 40;

  // 지나온 발자국 셀 기록 (row, col)
  final Set<String> _visitedCells = {};

  // 이동 효과음 타이머용
  int _stepSoundCounter = 0;

  // 애니메이션 컨트롤러
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _goalGlowCtrl;
  late AnimationController _floatingBgCtrl;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();

    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(_bounceCtrl);

    _goalGlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);

    // 은은하게 둥둥 떠다니는 배경 애니메이션
    _floatingBgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _loadLevel();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _bounceCtrl.dispose();
    _goalGlowCtrl.dispose();
    _floatingBgCtrl.dispose();
    super.dispose();
  }

  void _loadLevel() {
    _isLevelClear = false;
    _visitedCells.clear();

    final t = _theme;
    final rows = t.rows.isEven ? t.rows + 1 : t.rows;
    final cols = t.cols.isEven ? t.cols + 1 : t.cols;
    _maze = generateMaze(rows, cols, seed: _levelIdx * 37 + 13);

    // (0,0) 좌표에서 시작
    _px = 0;
    _py = 0;
    _visitedCells.add("0,0");

    setState(() {});
  }

  // ── 부드러운 연속 이동 & 벽 슬라이딩 처리 ─────────────────────────────────────
  void _movePlayer(double dx, double dy) {
    if (_isLevelClear) return;

    final cs = _cellSize;
    final rows = _maze.length;
    final cols = _maze[0].length;
    final boardW = cols * cs;
    final boardH = rows * cs;

    final maxDelta = max(dx.abs(), dy.abs());
    if (maxDelta == 0) return;

    // 큰 이동은 3픽셀 단위로 나누어 벽 뚫림 방지
    final steps = (maxDelta / 3.0).ceil().clamp(1, 20);
    final stepDx = dx / steps;
    final stepDy = dy / steps;

    bool moved = false;

    for (int i = 0; i < steps; i++) {
      // X축 이동 시도
      final nextX = (_px + stepDx).clamp(0.0, boardW - cs);
      if (!_isWallAt(nextX, _py, rows, cols, cs)) {
        _px = nextX;
        moved = true;
      }

      // Y축 이동 시도
      final nextY = (_py + stepDy).clamp(0.0, boardH - cs);
      if (!_isWallAt(_px, nextY, rows, cols, cs)) {
        _py = nextY;
        moved = true;
      }
    }

    if (moved) {
      // 현재 지난 타일 기록 (아기자기한 발자국 밝히기)
      final col = ((_px + cs / 2) / cs).floor().clamp(0, cols - 1);
      final row = ((_py + cs / 2) / cs).floor().clamp(0, rows - 1);
      _visitedCells.add("$row,$col");

      // 이동 소리
      _stepSoundCounter++;
      if (_stepSoundCounter % 8 == 0) {
        AudioManager.instance.playMazeMove();
      }

      if (!_bounceCtrl.isAnimating) {
        _bounceCtrl.forward(from: 0);
      }

      _checkGoal();
      setState(() {});
    }
  }

  // 충돌 박스 검사
  bool _isWallAt(double x, double y, int rows, int cols, double cs) {
    final margin = cs * 0.12; // 플레이어 충돌체 여백
    final l = x + margin;
    final r = x + cs - margin;
    final t = y + margin;
    final b = y + cs - margin;

    final minCol = (l / cs).floor().clamp(0, cols - 1);
    final maxCol = (r / cs).floor().clamp(0, cols - 1);
    final minRow = (t / cs).floor().clamp(0, rows - 1);
    final maxRow = (b / cs).floor().clamp(0, rows - 1);

    for (int rIdx = minRow; rIdx <= maxRow; rIdx++) {
      for (int cIdx = minCol; cIdx <= maxCol; cIdx++) {
        if (_maze[rIdx][cIdx] == 1) {
          return true; // 벽 충돌!
        }
      }
    }
    return false;
  }

  void _checkGoal() {
    final rows = _maze.length;
    final cols = _maze[0].length;
    final gx = (cols - 1) * _cellSize;
    final gy = (rows - 1) * _cellSize;

    if ((_px - gx).abs() < _cellSize * 0.6 && (_py - gy).abs() < _cellSize * 0.6) {
      _isLevelClear = true;
      _totalScore += 50;
      _confetti.play();
      AudioManager.instance.playMazeClear();
      HapticFeedback.heavyImpact();

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _levelIdx++;
            _loadLevel();
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final isDark = theme.backgroundGradient[0].computeLuminance() < 0.3;
    final textColor = isDark ? Colors.white : KidsTheme.textDark;
    final rows = _maze.length;
    final cols = _maze[0].length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── 둥둥 떠다니는 감성 배경 아이콘 ──
            AnimatedBuilder(
              animation: _floatingBgCtrl,
              builder: (_, child) {
                final offsetY = sin(_floatingBgCtrl.value * pi) * 10;
                return Stack(
                  children: [
                    for (int i = 0; i < 14; i++)
                      Positioned(
                        left: (15 + i * 65.0) % (MediaQuery.of(context).size.width - 40),
                        top: (50 + i * 85.0 + (i.isEven ? offsetY : -offsetY)) % (MediaQuery.of(context).size.height - 50),
                        child: Opacity(
                          opacity: 0.22,
                          child: Text(theme.bgEmoji, style: TextStyle(fontSize: 26 + (i % 3) * 8.0)),
                        ),
                      ),
                  ],
                );
              },
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(textColor, isDark),
                  const SizedBox(height: 6),

                  // ── 미로 보드 (세로 영역을 시원하게 채움) ──
                  Expanded(
                    child: LayoutBuilder(builder: (ctx, cst) {
                      final avW = cst.maxWidth - 20;
                      final avH = cst.maxHeight - 10;
                      _cellSize = min(avW / cols, avH / rows);
                      _cellSize = _cellSize.clamp(24.0, 64.0);
                      final bw = _cellSize * cols;
                      final bh = _cellSize * rows;

                      return Center(
                        child: _buildBoard(bw, bh, rows, cols, theme, isDark),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // ── 축하 폭죽 ──
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 40,
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.pink],
              ),
            ),

            // ── 클리어 배너 ──
            if (_isLevelClear)
              Positioned.fill(
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (_, v, child) => Transform.scale(
                      scale: v,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('도착했어요! 🎉', style: GoogleFonts.jua(fontSize: 44, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('🎯 +50점 획득!', style: GoogleFonts.jua(fontSize: 24, color: Colors.yellowAccent)),
                          ],
                        ),
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

  // ── 상단 헤더 ─────────────────────────────────────────────────────────────
  Widget _buildHeader(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(220),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: Colors.white.withAlpha(150), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () { AudioManager.instance.playClick(); Navigator.pop(context); },
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(40) : KidsTheme.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            Expanded(
              child: Text(
                _theme.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(fontSize: 22, color: textColor),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withAlpha(50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('🎯 $_totalScore', style: GoogleFonts.jua(fontSize: 18, color: isDark ? const Color(0xFFFFD700) : KidsTheme.orange)),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── 미로 보드 & 아기자기한 그리드 ───────────────────────────────────────────
  Widget _buildBoard(double bw, double bh, int rows, int cols, MazeTheme theme, bool isDark) {
    final cs = _cellSize;
    final gx = (cols - 1) * cs;
    final gy = (rows - 1) * cs;

    return GestureDetector(
      onPanStart: (details) {
        final touchCenter = details.localPosition;
        final playerCenter = Offset(_px + cs / 2, _py + cs / 2);
        final diff = touchCenter - playerCenter;
        if (diff.distance > 5) {
          _movePlayer(diff.dx.clamp(-cs, cs), diff.dy.clamp(-cs, cs));
        }
      },
      onPanUpdate: (details) {
        _movePlayer(details.delta.dx, details.delta.dy);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: bw + 10,
        height: bh + 10,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.floorColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(color: theme.wallBorderColor.withAlpha(90), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // ── 바닥 격자 ──
              Positioned.fill(
                child: Container(color: theme.floorColor),
              ),

              // ── 지나온 타일 발자국 밝히기 ──
              for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                  if (_visitedCells.contains("$r,$c") && _maze[r][c] == 0)
                    Positioned(
                      left: c * cs,
                      top: r * cs,
                      width: cs,
                      height: cs,
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: theme.visitedColor.withAlpha(160),
                          borderRadius: BorderRadius.circular(cs * 0.25),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: 0.4,
                            child: Text(theme.stepEmoji, style: TextStyle(fontSize: cs * 0.35)),
                          ),
                        ),
                      ),
                    ),

              // ── 파스텔 둥근 벽 ──
              for (int r = 0; r < rows; r++)
                for (int c = 0; c < cols; c++)
                  if (_maze[r][c] == 1)
                    Positioned(
                      left: c * cs,
                      top: r * cs,
                      width: cs,
                      height: cs,
                      child: Container(
                        margin: const EdgeInsets.all(1.2),
                        decoration: BoxDecoration(
                          color: theme.wallColor,
                          borderRadius: BorderRadius.circular(cs * 0.25),
                          border: Border.all(color: theme.wallBorderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: theme.wallBorderColor.withAlpha(60),
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getWallChar(r, c, rows, cols),
                            style: TextStyle(fontSize: cs * 0.45),
                          ),
                        ),
                      ),
                    ),

              // ── 출발점 ──
              Positioned(
                left: 0, top: 0, width: cs, height: cs,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.lightGreen.withAlpha(80),
                    borderRadius: BorderRadius.circular(cs * 0.3),
                    border: Border.all(color: Colors.green, width: 1.5),
                  ),
                  child: Center(child: Text('START', style: GoogleFonts.jua(fontSize: cs * 0.2, color: Colors.green[800], fontWeight: FontWeight.bold))),
                ),
              ),

              // ── 목표점 (부드러운 펄스) ──
              Positioned(
                left: gx, top: gy, width: cs, height: cs,
                child: AnimatedBuilder(
                  animation: _goalGlowCtrl,
                  builder: (_, child) {
                    final glow = 0.6 + 0.4 * _goalGlowCtrl.value;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha((glow * 100).round()),
                        borderRadius: BorderRadius.circular(cs * 0.3),
                        border: Border.all(color: Colors.orangeAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withAlpha((glow * 140).round()),
                            blurRadius: 10 * glow,
                            spreadRadius: 2 * glow,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(theme.goalEmoji, style: TextStyle(fontSize: cs * 0.65)),
                      ),
                    );
                  },
                ),
              ),

              // ── 플레이어 ──
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (_, child) {
                  return Positioned(
                    left: _px,
                    top: _py,
                    width: cs,
                    height: cs,
                    child: Transform.scale(
                      scale: _isLevelClear ? 1.5 : _bounceAnim.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(230),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: Text(theme.playerEmoji, style: TextStyle(fontSize: cs * 0.65)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getWallChar(int r, int c, int rows, int cols) {
    final t = _theme;
    if (t.title.contains('농장')) return '🧱';
    if (t.title.contains('바다')) return '🪸';
    if (t.title.contains('꽃밭')) return '🌿';
    if (t.title.contains('우주')) return '☄️';
    if (t.title.contains('공룡')) return '🌋';
    if (t.title.contains('겨울')) return '⛄';
    if (t.title.contains('마법')) return '🔮';
    return '🧱';
  }
}
