import 'dart:async';
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
    bgEmoji: '☁️', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '멍멍이 마을 🐶', rows: 11, cols: 7,
    playerEmoji: '🐶', goalEmoji: '🦴',
    wallColor: Color(0xFFFFCC80), wallBorderColor: Color(0xFFFFB74D),
    floorColor: Color(0xFFFFFDF8), visitedColor: Color(0xFFFFE0B2),
    backgroundGradient: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    bgEmoji: '🐾', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '야옹이 숲 🐱', rows: 11, cols: 7,
    playerEmoji: '🐱', goalEmoji: '🐟',
    wallColor: Color(0xFFFFAB91), wallBorderColor: Color(0xFFFF8A65),
    floorColor: Color(0xFFFFFBF9), visitedColor: Color(0xFFFFCCBC),
    backgroundGradient: [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
    bgEmoji: '🧶', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '당근 농장 🐰', rows: 13, cols: 7,
    playerEmoji: '🐰', goalEmoji: '🥕',
    wallColor: Color(0xFFFF8A65), wallBorderColor: Color(0xFFFF7043),
    floorColor: Color(0xFFFFFDF9), visitedColor: Color(0xFFFFCCBC),
    backgroundGradient: [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
    bgEmoji: '🥕', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '병아리 유치원 🐥', rows: 13, cols: 7,
    playerEmoji: '🐥', goalEmoji: '🌻',
    wallColor: Color(0xFFFFEE58), wallBorderColor: Color(0xFFFDD835),
    floorColor: Color(0xFFFFFFF9), visitedColor: Color(0xFFFFF9C4),
    backgroundGradient: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
    bgEmoji: '✨', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '연못 나들이 🐸', rows: 13, cols: 7,
    playerEmoji: '🐸', goalEmoji: '🪷',
    wallColor: Color(0xFF81C784), wallBorderColor: Color(0xFF66BB6A),
    floorColor: Color(0xFFF9FBF7), visitedColor: Color(0xFFC8E6C9),
    backgroundGradient: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    bgEmoji: '🌿', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '사파리 탐험 🐘', rows: 15, cols: 9,
    playerEmoji: '🐘', goalEmoji: '🥜',
    wallColor: Color(0xFF90CAF9), wallBorderColor: Color(0xFF64B5F6),
    floorColor: Color(0xFFF9FCFF), visitedColor: Color(0xFFBBDEFB),
    backgroundGradient: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    bgEmoji: '🌴', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '꿀꿀이 들판 🐷', rows: 15, cols: 9,
    playerEmoji: '🐷', goalEmoji: '🍎',
    wallColor: Color(0xFFF48FB1), wallBorderColor: Color(0xFFF06292),
    floorColor: Color(0xFFFFF8FA), visitedColor: Color(0xFFF8BBD0),
    backgroundGradient: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    bgEmoji: '🌸', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '바다 탐험 🐠', rows: 11, cols: 7,
    playerEmoji: '🐠', goalEmoji: '🐚',
    wallColor: Color(0xFF4FC3F7), wallBorderColor: Color(0xFF29B6F6),
    floorColor: Color(0xFFF4FCFE), visitedColor: Color(0xFFB2EBF2),
    backgroundGradient: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
    bgEmoji: '🫧', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '꽃밭 나들이 🐝', rows: 13, cols: 7,
    playerEmoji: '🐝', goalEmoji: '🌸',
    wallColor: Color(0xFFAED581), wallBorderColor: Color(0xFF9CCC65),
    floorColor: Color(0xFFFAFDF6), visitedColor: Color(0xFFDCEDC8),
    backgroundGradient: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
    bgEmoji: '🌼', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '우주 비행 🚀', rows: 13, cols: 9,
    playerEmoji: '🚀', goalEmoji: '🌎',
    wallColor: Color(0xFFB39DDB), wallBorderColor: Color(0xFF9575CD),
    floorColor: Color(0xFFFAF8FF), visitedColor: Color(0xFFD1C4E9),
    backgroundGradient: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    bgEmoji: '⭐', stepEmoji: '🐾',
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
    bgEmoji: '❄️', stepEmoji: '🐾',
  ),
  MazeTheme(
    title: '마법의 성 🦄', rows: 17, cols: 9,
    playerEmoji: '🦄', goalEmoji: '🏰',
    wallColor: Color(0xFFCE93D8), wallBorderColor: Color(0xFFBA68C8),
    floorColor: Color(0xFFFDF7FD), visitedColor: Color(0xFFE1BEE7),
    backgroundGradient: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    bgEmoji: '🌟', stepEmoji: '🐾',
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
  int _difficultyIdx = 0; // 0: 1단계 (기본 7x7), 1: 2단계 (보통 11x9), 2: 3단계 (어려움 15x11), 3: 4단계 (도전 19x13)
  int _stageLevel = 1;    // 현재 클리어 진행 단계 (1, 2, 3...)
  int _themeIdx = 0;
  bool _isLevelClear = false;
  Timer? _nextLevelTimer;
  Timer? _hintTimer;

  bool _showPathHint = false;
  Set<String> _hintPathCells = {};

  late List<List<int>> _maze;
  MazeTheme get _theme => _kThemes[_themeIdx % _kThemes.length];

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
    _nextLevelTimer?.cancel();
    _hintTimer?.cancel();
    _confetti.dispose();
    _bounceCtrl.dispose();
    _goalGlowCtrl.dispose();
    _floatingBgCtrl.dispose();
    super.dispose();
  }

  void _loadLevel() {
    _isLevelClear = false;
    _visitedCells.clear();
    _hintTimer?.cancel();
    _showPathHint = false;
    _hintPathCells.clear();

    int baseRows, baseCols;
    switch (_difficultyIdx) {
      case 0:
        baseRows = 7; baseCols = 7; // 1단계 (기본: 7x7)
        break;
      case 1:
        baseRows = 11; baseCols = 9; // 2단계 (보통: 11x9)
        break;
      case 2:
        baseRows = 15; baseCols = 11; // 3단계 (어려움: 15x11)
        break;
      case 3:
      default:
        baseRows = 19; baseCols = 13; // 4단계 (도전: 19x13)
        break;
    }

    // 단계가 올라갈 때마다 미로 크기와 복잡도가 점진적으로 늘어남
    final step = _stageLevel - 1;
    int targetRows = baseRows + step * 2;
    int targetCols = baseCols + (step * 1.5).floor() * 2;

    targetRows = targetRows.clamp(7, 25);
    targetCols = targetCols.clamp(7, 17);

    final rows = targetRows.isEven ? targetRows + 1 : targetRows;
    final cols = targetCols.isEven ? targetCols + 1 : targetCols;
    _maze = generateMaze(rows, cols, seed: Random().nextInt(10000));

    // (0,0) 좌표에서 시작
    _px = 0;
    _py = 0;
    _visitedCells.add("0,0");

    setState(() {});
  }

  // ── 🪄 길안내 힌트 (BFS 알고리즘 - 3초 후 자동 소멸) ──────────────────────
  void _triggerPathHint() {
    if (_isLevelClear) return;
    AudioManager.instance.playClick();
    _hintTimer?.cancel();

    setState(() {
      _showPathHint = true;
      _calculateHintPath();
    });

    // 3초 후 길안내 힌트 자동 소멸
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showPathHint = false;
        });
      }
    });
  }

  void _calculateHintPath() {
    final rows = _maze.length;
    final cols = _maze[0].length;
    final startR = ((_py + _cellSize / 2) / _cellSize).floor().clamp(0, rows - 1);
    final startC = ((_px + _cellSize / 2) / _cellSize).floor().clamp(0, cols - 1);
    final goalR = rows - 1;
    final goalC = cols - 1;

    final queue = <List<int>>[[startR, startC]];
    final parentMap = <String, List<int>>{};
    final visited = <String>{"$startR,$startC"};

    bool found = false;
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      final r = curr[0], c = curr[1];
      if (r == goalR && c == goalC) {
        found = true;
        break;
      }

      final dirs = [[0, 1], [1, 0], [0, -1], [-1, 0]];
      for (final d in dirs) {
        final nr = r + d[0], nc = c + d[1];
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && _maze[nr][nc] == 0) {
          final key = "$nr,$nc";
          if (!visited.contains(key)) {
            visited.add(key);
            parentMap[key] = [r, c];
            queue.add([nr, nc]);
          }
        }
      }
    }

    if (found) {
      final path = <String>{};
      String currKey = "$goalR,$goalC";
      while (parentMap.containsKey(currKey)) {
        path.add(currKey);
        final parent = parentMap[currKey]!;
        currKey = "${parent[0]},${parent[1]}";
      }
      path.add("$startR,$startC");
      _hintPathCells = path;
    }
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

      // 이동 소리 (선택된 테마 동물에 딱 맞춘 깜찍한 울음소리/효과음!)
      _stepSoundCounter++;
      if (_stepSoundCounter % 8 == 0) {
        AudioManager.instance.playMazeThemeMove(_themeIdx, emoji: _theme.playerEmoji);
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
      _confetti.play();
      AudioManager.instance.playMazeClear(emoji: _theme.playerEmoji, themeIdx: _themeIdx);
      HapticFeedback.heavyImpact();

      _nextLevelTimer?.cancel();
      _nextLevelTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isLevelClear) {
          _nextLevel();
        }
      });
    }
  }

  void _nextLevel() {
    _nextLevelTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _stageLevel++; // 클리어할 때마다 다음 레벨로 난이도 업!
      _themeIdx = (_themeIdx + 1) % _kThemes.length;
      _loadLevel();
    });
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
            // ── 둥둥 떠다니는 아기자기 감성 배경 아이콘 ──
            AnimatedBuilder(
              animation: _floatingBgCtrl,
              builder: (_, child) {
                final offsetY = sin(_floatingBgCtrl.value * pi) * 12;
                final val = _floatingBgCtrl.value;
                return Stack(
                  children: [
                    // 구름 및 별 반짝이 데코
                    Positioned(
                      top: 40 + offsetY,
                      left: 20 + val * 30,
                      child: const Opacity(opacity: 0.35, child: Text('☁️', style: TextStyle(fontSize: 48))),
                    ),
                    Positioned(
                      top: 120 - offsetY,
                      right: 25 + val * 20,
                      child: const Opacity(opacity: 0.35, child: Text('🎈', style: TextStyle(fontSize: 42))),
                    ),
                    Positioned(
                      bottom: 140 + offsetY,
                      left: 30 - val * 20,
                      child: const Opacity(opacity: 0.35, child: Text('✨', style: TextStyle(fontSize: 36))),
                    ),
                    Positioned(
                      bottom: 80 - offsetY,
                      right: 35 + val * 25,
                      child: Opacity(opacity: 0.35, child: Text(theme.bgEmoji, style: const TextStyle(fontSize: 44))),
                    ),

                    // 테마별 아기자기 아이템 둥둥
                    for (int i = 0; i < 16; i++)
                      Positioned(
                        left: (10 + i * 55.0 + (i.isEven ? val * 20 : -val * 20)) % (MediaQuery.of(context).size.width - 40),
                        top: (60 + i * 75.0 + (i.isEven ? offsetY : -offsetY)) % (MediaQuery.of(context).size.height - 60),
                        child: Opacity(
                          opacity: 0.30,
                          child: Text(
                            i % 4 == 0 ? theme.bgEmoji : (i % 4 == 1 ? theme.goalEmoji : (i % 4 == 2 ? '☁️' : '✨')),
                            style: TextStyle(fontSize: 24 + (i % 3) * 6.0),
                          ),
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
                  const SizedBox(height: 8),

                  // ── 미로 보드 (화면 전체를 가득 채우는 초대형 미로) ──
                  Expanded(
                    child: LayoutBuilder(builder: (ctx, cst) {
                      final avW = cst.maxWidth - 20;
                      final avH = cst.maxHeight - 10;
                      _cellSize = min(avW / cols, avH / rows);
                      _cellSize = _cellSize.clamp(20.0, 72.0);
                      final bw = _cellSize * cols;
                      final bh = _cellSize * rows;

                      return Center(
                        child: _buildBoard(bw, bh, rows, cols, theme, isDark),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  _buildBottomControlBar(theme, isDark),
                  const SizedBox(height: 10),
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
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (_, v, child) => Transform.scale(
                        scale: v,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 500),
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${theme.playerEmoji} 🎉 ${theme.goalEmoji}', style: const TextStyle(fontSize: 42)),
                                const SizedBox(height: 10),
                                Text('STAGE $_stageLevel 탈출 성공!', style: GoogleFonts.jua(fontSize: 28, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('다음 단계(STAGE ${_stageLevel + 1})는 더 넓고 재미나요! 🚀', style: GoogleFonts.jua(fontSize: 15, color: Colors.yellowAccent)),
                                const SizedBox(height: 18),

                                // 🚀 다음 단계로 넘어 가기! (왕 커다란 초록 버튼)
                                GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playClick();
                                    _nextLevel();
                                  },
                                  child: Container(
                                    height: 54,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF00C853).withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '다음 단계로 넘어 가기!',
                                              style: GoogleFonts.jua(fontSize: 19, color: Colors.white),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('➡️', style: TextStyle(fontSize: 22)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }

  // ── 상단 헤더 (단순하고 깔끔함) ─────────────────────────────────────────────
  Widget _buildHeader(Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(35) : Colors.white.withAlpha(225),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withAlpha(160), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () { AudioManager.instance.playClick(); Navigator.pop(context); },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(40) : KidsTheme.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _theme.title,
                        style: GoogleFonts.jua(fontSize: 17, color: textColor),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade400, width: 1.2),
                        ),
                        child: Text(
                          'STAGE $_stageLevel',
                          style: GoogleFonts.jua(fontSize: 13, color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                _showSettingsDialog();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('난이도', style: GoogleFonts.jua(fontSize: 13, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 깔끔한 모달 난이도 다이얼로그 ──────────────────────────────────────────
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐ 난이도 & 테마 선택 🎨', style: GoogleFonts.jua(fontSize: 21, color: KidsTheme.textDark)),
                  const SizedBox(height: 14),

                  Text('⭐ 난이도 선택', style: GoogleFonts.jua(fontSize: 16, color: Colors.orange.shade800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dialogDiffBtn(setModalState, 0, '1단계\n(초간단)'),
                      const SizedBox(width: 6),
                      _dialogDiffBtn(setModalState, 1, '2단계\n(쉬움)'),
                      const SizedBox(width: 6),
                      _dialogDiffBtn(setModalState, 2, '3단계\n(보통)'),
                      const SizedBox(width: 6),
                      _dialogDiffBtn(setModalState, 3, '4단계\n(도전)'),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Text('🎨 테마 선택', style: GoogleFonts.jua(fontSize: 16, color: Colors.purple.shade800)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kThemes.length,
                      itemBuilder: (context, i) {
                        final selected = i == _themeIdx;
                        final t = _kThemes[i];
                        return GestureDetector(
                          onTap: () {
                            AudioManager.instance.playMazeThemeMove(i, emoji: t.playerEmoji);
                            setModalState(() { _themeIdx = i; });
                            setState(() { _loadLevel(); });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? Colors.purple.shade400 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                t.title,
                                style: GoogleFonts.jua(
                                  fontSize: 13,
                                  color: selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                        gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('확인 👍', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
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

  Widget _dialogDiffBtn(StateSetter setModalState, int idx, String label) {
    final selected = _difficultyIdx == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          setModalState(() {
            _difficultyIdx = idx;
            _stageLevel = 1;
          });
          setState(() { _loadLevel(); });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.orange : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? Colors.deepOrange : Colors.orange.shade200, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.jua(
                fontSize: 12,
                color: selected ? Colors.white : Colors.brown.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 하단 컨트롤 바 ───────────────────────────────────────────────────────
  Widget _buildBottomControlBar(MazeTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🪄 길안내 힌트
          GestureDetector(
            onTap: _triggerPathHint,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🪄', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    _showPathHint ? '반짝 힌트 (3초)' : '길안내 힌트',
                    style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 🔄 새로운 미로
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _loadLevel();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha(40) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                children: [
                  const Text('🔄', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '새 미로',
                    style: GoogleFonts.jua(
                      fontSize: 14,
                      color: isDark ? Colors.white : theme.wallBorderColor,
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

              // ── 🪄 마법 길안내 힌트 반짝이 ──
              if (_showPathHint)
                for (int r = 0; r < rows; r++)
                  for (int c = 0; c < cols; c++)
                    if (_hintPathCells.contains("$r,$c") && _maze[r][c] == 0)
                      Positioned(
                        left: c * cs,
                        top: r * cs,
                        width: cs,
                        height: cs,
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(cs * 0.25),
                          ),
                          child: Center(
                            child: Text('✨', style: TextStyle(fontSize: cs * 0.45)),
                          ),
                        ),
                      ),

              // ── 지나온 타일 아기자기한 발자국 밝히기 ──
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
                          color: theme.visitedColor.withAlpha(180),
                          borderRadius: BorderRadius.circular(cs * 0.25),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: ((r + c) % 2 == 0) ? 0.22 : -0.22, // 아기자기한 왼발/오른발 회전
                            child: Opacity(
                              opacity: 0.7,
                              child: Text(theme.stepEmoji, style: TextStyle(fontSize: cs * 0.42)),
                            ),
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
