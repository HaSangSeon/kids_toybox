import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS & SCENE DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════════════

enum TabType { none, out, inTab }

class PieceEdge {
  final TabType top;
  final TabType right;
  final TabType bottom;
  final TabType left;

  const PieceEdge({
    this.top = TabType.none,
    this.right = TabType.none,
    this.bottom = TabType.none,
    this.left = TabType.none,
  });
}

class PuzzleTheme {
  final int id;
  final String title;
  final String categoryEmoji;
  final List<Color> bgGradient;
  final String mainEmoji;
  final List<String> subEmojis;
  final String description;
  final int defaultGridSize;

  const PuzzleTheme({
    required this.id,
    required this.title,
    required this.categoryEmoji,
    required this.bgGradient,
    required this.mainEmoji,
    required this.subEmojis,
    required this.description,
    this.defaultGridSize = 2,
  });
}

const List<PuzzleTheme> kPuzzleThemes = [
  PuzzleTheme(
    id: 1,
    title: '동물 농장 소풍',
    categoryEmoji: '🐶',
    bgGradient: [Color(0xFFFFF9C4), Color(0xFFA5D6A7)],
    mainEmoji: '🐶',
    subEmojis: ['🐱', '🐰', '🐥', '🌻', '🏡', '🌳', '☀️'],
    description: '귀여운 강아지와 시골 농장 친구들!',
  ),
  PuzzleTheme(
    id: 2,
    title: '신비한 바다 속',
    categoryEmoji: '🐳',
    bgGradient: [Color(0xFFE0F7FA), Color(0xFF4FC3F7)],
    mainEmoji: '🐳',
    subEmojis: ['🐙', '🦀', '🐢', '🐠', '🪼', '🐚', '🌊'],
    description: '헤엄치는 아기 고래와 바다 친구들!',
  ),
  PuzzleTheme(
    id: 3,
    title: '공룡 탐험 세계',
    categoryEmoji: '🦖',
    bgGradient: [Color(0xFFE8F5E9), Color(0xFF81C784)],
    mainEmoji: '🦖',
    subEmojis: ['🦕', '🐊', '🌋', '🌴', '🦴', '🥚', '☁️'],
    description: '쿵쾅쿵쾅 신나는 공룡 세상!',
  ),
  PuzzleTheme(
    id: 4,
    title: '달콤 디저트 천국',
    categoryEmoji: '🍰',
    bgGradient: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
    mainEmoji: '🍰',
    subEmojis: ['🍦', '🍩', '🍭', '🧁', '🍒', '🍨', '✨'],
    description: '달콤한 케이크와 아이스크림 파티!',
  ),
  PuzzleTheme(
    id: 5,
    title: '빵빵 자동차 도시',
    categoryEmoji: '🚗',
    bgGradient: [Color(0xFFFFF3E0), Color(0xFFFFB74D)],
    mainEmoji: '🚗',
    subEmojis: ['🚓', '🚒', '🚑', '🚌', '🚦', '☁️', '🏢'],
    description: '씽씽 달리는 멋진 자동차 도로!',
  ),
  PuzzleTheme(
    id: 6,
    title: '신나는 우주 여행',
    categoryEmoji: '🚀',
    bgGradient: [Color(0xFFEDE7F6), Color(0xFFB39DDB)],
    mainEmoji: '🚀',
    subEmojis: ['🪐', '⭐', '👾', '🛸', '☄️', '🌙', '🌌'],
    description: '반짝이는 별들과 우주선 탐험!',
  ),
  PuzzleTheme(
    id: 7,
    title: '알록달록 과일 동산',
    categoryEmoji: '🍎',
    bgGradient: [Color(0xFFFFEBEE), Color(0xFFEF9A9A)],
    mainEmoji: '🍎',
    subEmojis: ['🍌', '🍇', '🍓', '🍉', '🍍', '🍈', '☀️'],
    description: '새콤달콤 싱싱한 과일들!',
  ),
  PuzzleTheme(
    id: 8,
    title: '와일드 사파리',
    categoryEmoji: '🦁',
    bgGradient: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
    mainEmoji: '🦁',
    subEmojis: ['🐘', '🦒', '🦓', '🏕️', '🌾', '🌴', '☀️'],
    description: '용감한 사자와 넓은 초원 동물들!',
  ),
  PuzzleTheme(
    id: 9,
    title: '신비한 핼러윈 파티',
    categoryEmoji: '🎃',
    bgGradient: [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
    mainEmoji: '🎃',
    subEmojis: ['👻', '🦇', '🕷️', '🕸️', '🍭', '🌙', '🍬'],
    description: '유령 친구들과 함께하는 핼러윈!',
    defaultGridSize: 3,
  ),
  PuzzleTheme(
    id: 10,
    title: '포근한 크리스마스',
    categoryEmoji: '🎄',
    bgGradient: [Color(0xFFFFEBEE), Color(0xFFEF9A9A)],
    mainEmoji: '🎅',
    subEmojis: ['🎄', '🦌', '🎁', '⛄', '🧦', '❄️', '⭐'],
    description: '산타 할아버지의 특별한 선물!',
    defaultGridSize: 3,
  ),
  PuzzleTheme(
    id: 11,
    title: '즐거운 숲속 캠핑',
    categoryEmoji: '🏕️',
    bgGradient: [Color(0xFFEFEBE9), Color(0xFFBCAAA4)],
    mainEmoji: '⛺',
    subEmojis: ['🔥', '🌲', '🦉', '🪵', '🍄', '✨', '🌙'],
    description: '모닥불 곁에서 별을 구경해요!',
    defaultGridSize: 3,
  ),
  PuzzleTheme(
    id: 12,
    title: '꽁꽁 북극 탐험',
    categoryEmoji: '🐧',
    bgGradient: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
    mainEmoji: '🐧',
    subEmojis: ['🐻‍❄️', '❄️', '🧊', '🦭', '🎿', '🌬️', '🌨️'],
    description: '추운 얼음나라 동물 친구들!',
    defaultGridSize: 4,
  ),
  PuzzleTheme(
    id: 13,
    title: '반짝반짝 유니콘',
    categoryEmoji: '🦄',
    bgGradient: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
    mainEmoji: '🦄',
    subEmojis: ['🌈', '✨', '💎', '🧚‍♀️', '🎀', '🍭', '💖'],
    description: '무지개빛 신비한 유니콘 나라!',
    defaultGridSize: 4,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class JigsawPuzzleGame extends StatefulWidget {
  const JigsawPuzzleGame({super.key});

  @override
  State<JigsawPuzzleGame> createState() => _JigsawPuzzleGameState();
}

class _PieceData {
  final int index;
  final int row;
  final int col;
  final PieceEdge edge;
  Offset currentPos;
  bool isPlaced;

  _PieceData({
    required this.index,
    required this.row,
    required this.col,
    required this.edge,
    required this.currentPos,
    this.isPlaced = false,
  });
}

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  Color color;
  _Spark({required this.pos, required this.vel, required this.life, required this.color});
}

class _JigsawPuzzleGameState extends State<JigsawPuzzleGame>
    with TickerProviderStateMixin {
  int _themeIndex = 0;
  int _gridSize = 2; // 2x2 = 4 pieces default (kid friendly)
  bool _showThemeSelect = true;

  late List<_PieceData> _pieces;
  List<PieceEdge> _edges = [];
  final List<_Spark> _sparks = [];

  bool _isComplete = false;

  late AnimationController _ticker;
  late AnimationController _bgAnimController;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_updateParticles)
      ..repeat();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
    _initPuzzle();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  void _updateParticles() {
    if (_sparks.isEmpty) return;
    setState(() {
      for (final s in _sparks) {
        s.pos += s.vel;
        s.life -= 0.04;
      }
      _sparks.removeWhere((s) => s.life <= 0);
    });
  }

  void _initPuzzle() {
    _isComplete = false;
    _sparks.clear();

    final total = _gridSize * _gridSize;
    _edges = _generateEdges(_gridSize);

    _pieces = List.generate(total, (i) {
      final r = i ~/ _gridSize;
      final c = i % _gridSize;
      return _PieceData(
        index: i,
        row: r,
        col: c,
        edge: _edges[i],
        currentPos: Offset.zero,
      );
    });
  }

  List<PieceEdge> _generateEdges(int n) {
    // Generate matching interlocking tabs/blanks for a nxn grid
    final hTabs = List.generate(n * (n - 1), (_) => _rng.nextBool() ? TabType.out : TabType.inTab);
    final vTabs = List.generate((n - 1) * n, (_) => _rng.nextBool() ? TabType.out : TabType.inTab);

    List<PieceEdge> edges = [];

    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        TabType top = TabType.none;
        TabType bottom = TabType.none;
        TabType left = TabType.none;
        TabType right = TabType.none;

        if (r > 0) {
          final idx = (r - 1) * n + c;
          top = vTabs[idx] == TabType.out ? TabType.inTab : TabType.out;
        }
        if (r < n - 1) {
          final idx = r * n + c;
          bottom = vTabs[idx];
        }
        if (c > 0) {
          final idx = r * (n - 1) + (c - 1);
          left = hTabs[idx] == TabType.out ? TabType.inTab : TabType.out;
        }
        if (c < n - 1) {
          final idx = r * (n - 1) + c;
          right = hTabs[idx];
        }

        edges.add(PieceEdge(top: top, right: right, bottom: bottom, left: left));
      }
    }
    return edges;
  }

  void _spawnSparks(Offset center) {
    final colors = [Colors.amber, Colors.yellow, Colors.cyan, Colors.pinkAccent];
    for (int i = 0; i < 24; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 5 + 2;
      _sparks.add(_Spark(
        pos: center,
        vel: Offset(cos(angle) * speed, sin(angle) * speed),
        life: 1.0,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
  }

  void _onPuzzleCompleted() {
    setState(() {
      _isComplete = true;
    });

    AudioManager.instance.playJigsawSuccess();

    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    for (int i = 0; i < 60; i++) {
      _spawnSparks(Offset(_rng.nextDouble() * sw, _rng.nextDouble() * sh * 0.5));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_showThemeSelect) {
      return _buildThemeSelectScreen();
    }

    final theme = kPuzzleThemes[_themeIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child) {
            return CustomPaint(
              painter: _FloatingShapesPainter(_bgAnimController.value, Colors.white),
              child: child,
            );
          },
          child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(theme),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = min(constraints.maxWidth - 32, constraints.maxHeight - 160);
                    final boardRect = Rect.fromLTWH(
                      (constraints.maxWidth - boardSize) / 2,
                      16,
                      boardSize,
                      boardSize,
                    );

                    return Stack(
                      children: [
                        // 1. Puzzle Board Frame & Interactive Drag Target Slots
                        Positioned(
                          left: boardRect.left,
                          top: boardRect.top,
                          width: boardRect.width,
                          height: boardRect.height,
                          child: _buildBoardFrame(theme, boardRect.size),
                        ),

                        // 2. Unplaced Pieces Tray at Bottom
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12,
                          height: 120,
                          child: _buildPieceTray(theme, boardRect),
                        ),

                        // 4. Particle Layer
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ParticlePainter(sparks: _sparks),
                            ),
                          ),
                        ),

                        // 5. Completion Overlay Dialog
                        if (_isComplete)
                          Positioned.fill(
                            child: _buildCompleteOverlay(theme),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ── 0. Top Header ─────────────────────────────────────────────────────────
  Widget _buildTopHeader(PuzzleTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() => _showThemeSelect = true);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: KidsTheme.textDark, size: 24),
            ),
          ),
          const SizedBox(width: 10),

          // Theme Title Pill
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Text(theme.categoryEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      theme.title,
                      style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Grid Toggle Button (2x2 / 3x3)
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() {
                if (_gridSize == 2) {
                  _gridSize = 3;
                } else if (_gridSize == 3) {
                  _gridSize = 4;
                } else {
                  _gridSize = 2;
                }
                _initPuzzle();
              });
            },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: KidsTheme.orange, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  '${_gridSize}x$_gridSize (${_gridSize * _gridSize}조각)',
                  style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.orange, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Puzzle Board Frame & Faded Blueprint ──────────────────────────────
  Widget _buildBoardFrame(PuzzleTheme theme, Size size) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Faded Full Picture Scene Blueprint
            Opacity(
              opacity: 0.35,
              child: _buildFullSceneIllustration(theme, size),
            ),

            // Grid Outlines with Puzzle Interlocking Tabs
            CustomPaint(
              size: size,
              painter: _JigsawGridOutlinePainter(gridSize: _gridSize, edges: _edges),
            ),

            // Drag Targets & Placed Pieces for each cell (r, c)
            for (int r = 0; r < _gridSize; r++)
              for (int c = 0; c < _gridSize; c++)
                _buildBoardSlot(theme, r, c, size),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardSlot(PuzzleTheme theme, int r, int c, Size boardSize) {
    final cellW = boardSize.width / _gridSize;
    final cellH = boardSize.height / _gridSize;
    final targetIndex = r * _gridSize + c;
    final piece = _pieces[targetIndex];

    final targetW = cellW * 0.35;
    final targetH = cellH * 0.35;

    return Positioned(
      left: c * cellW,
      top: r * cellH,
      width: cellW,
      height: cellH,
      child: piece.isPlaced
          ? _buildPuzzlePieceWidget(theme, piece, boardSize)
          : Center(
              child: SizedBox(
                width: targetW,
                height: targetH,
                child: DragTarget<_PieceData>(
                  onWillAcceptWithDetails: (details) => details.data.index == piece.index,
                  onAcceptWithDetails: (details) {
                    setState(() {
                      details.data.isPlaced = true;
                    });
                    AudioManager.instance.playJigsawSnapCorrect();
                    HapticFeedback.lightImpact();
                    _spawnSparks(Offset(
                      (c + 0.5) * cellW,
                      (r + 0.5) * cellH,
                    ));
                    if (_pieces.every((p) => p.isPlaced)) {
                      _onPuzzleCompleted();
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        color: isHovering
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.transparent,
                        border: Border.all(
                          color: isHovering ? KidsTheme.yellow : Colors.transparent,
                          width: isHovering ? 3 : 0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isHovering
                          ? const Center(
                              child: Text('✨', style: TextStyle(fontSize: 24)),
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
    );
  }

  // ── 2. Piece Tray at Bottom ──────────────────────────────────────────────
  Widget _buildPieceTray(PuzzleTheme theme, Rect boardRect) {
    final unplaced = _pieces.where((p) => !p.isPlaced).toList();
    final pieceW = boardRect.width / _gridSize;
    final pieceH = boardRect.height / _gridSize;

    // Tray item size: fit all pieces comfortably at once
    final trayItemSize = _gridSize == 2 ? 74.0 : 58.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: unplaced.isEmpty
          ? Center(
              child: Text(
                '🎉 모든 조각을 맞췄어요!',
                style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.green),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: unplaced.map((piece) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Draggable<_PieceData>(
                      data: piece,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: Transform.translate(
                        offset: Offset(-pieceW / 2, -pieceH / 2),
                        child: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: pieceW,
                            height: pieceH,
                            child: _buildPuzzlePieceWidget(theme, piece, boardRect.size, isDragging: true),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.2,
                        child: SizedBox(
                          width: trayItemSize,
                          height: trayItemSize,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: pieceW,
                              height: pieceH,
                              child: _buildPuzzlePieceWidget(theme, piece, boardRect.size),
                            ),
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: trayItemSize,
                        height: trayItemSize,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: pieceW,
                            height: pieceH,
                            child: _buildPuzzlePieceWidget(theme, piece, boardRect.size),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  // ── 3. Single Puzzle Piece Widget (Jigsaw Clipped) ────────────────────────
  Widget _buildPuzzlePieceWidget(PuzzleTheme theme, _PieceData piece, Size boardSize, {bool isDragging = false}) {
    final cellW = boardSize.width / _gridSize;
    final cellH = boardSize.height / _gridSize;

    return ClipPath(
      clipper: _JigsawPieceClipper(edge: piece.edge),
      child: Container(
        width: cellW,
        height: cellH,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: isDragging ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ] : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sub-crop of the Full Scene Illustration matching (row, col)
            Positioned(
              left: -piece.col * cellW,
              top: -piece.row * cellH,
              width: boardSize.width,
              height: boardSize.height,
              child: _buildFullSceneIllustration(theme, boardSize),
            ),
            // Shiny Piece Border Highlight
            Positioned.fill(
              child: CustomPaint(
                painter: _JigsawPieceBorderPainter(edge: piece.edge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Full Scene Illustration (Rich Canvas + Emojis) ────────────────────
  Widget _buildFullSceneIllustration(PuzzleTheme theme, Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: size.height * 0.1, left: size.width * 0.1, child: Text(theme.subEmojis[0], style: TextStyle(fontSize: size.width * 0.15))),
          Positioned(top: size.height * 0.12, right: size.width * 0.12, child: Text(theme.subEmojis[1], style: TextStyle(fontSize: size.width * 0.14))),
          Positioned(bottom: size.height * 0.15, left: size.width * 0.15, child: Text(theme.subEmojis[2], style: TextStyle(fontSize: size.width * 0.14))),
          Positioned(bottom: size.height * 0.12, right: size.width * 0.15, child: Text(theme.subEmojis[3], style: TextStyle(fontSize: size.width * 0.15))),
          if (theme.subEmojis.length > 4)
            Positioned(top: size.height * 0.45, right: size.width * 0.08, child: Text(theme.subEmojis[4], style: TextStyle(fontSize: size.width * 0.12))),
          if (theme.subEmojis.length > 5)
            Positioned(bottom: size.height * 0.4, left: size.width * 0.08, child: Text(theme.subEmojis[5], style: TextStyle(fontSize: size.width * 0.12))),

          // Hero Center Emoji
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: Text(
                theme.mainEmoji,
                style: TextStyle(fontSize: size.width * 0.38),
              ),
            ),
          ),

          // Title Tag at Bottom Center
          Positioned(
            bottom: size.height * 0.06,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  theme.title,
                  style: GoogleFonts.jua(fontSize: size.width * 0.06, color: KidsTheme.textDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Completion Overlay Dialog ──────────────────────────────────────────
  Widget _buildCompleteOverlay(PuzzleTheme theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 10),
              Text(
                '퍼즐 완성! 최고예요! 🌟',
                style: GoogleFonts.jua(fontSize: 24, color: KidsTheme.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${theme.title} 퍼즐을 성공적으로 모두 맞췄어요!',
                style: GoogleFonts.jua(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() => _initPuzzle());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('다시하기 🔄', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _themeIndex = (_themeIndex + 1) % kPuzzleThemes.length;
                          _initPuzzle();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('다음 퍼즐 ➡️', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
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

  // ── 6. Theme Selection Grid Screen ────────────────────────────────────────
  Widget _buildThemeSelectScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child) {
            return CustomPaint(
              painter: _FloatingShapesPainter(_bgAnimController.value, Colors.white),
              child: child,
            );
          },
          child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: KidsTheme.textDark, size: 24),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '🧩 그림 퍼즐 맞추기',
                      style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              Text(
                '하고 싶은 퍼즐 주제를 골라보세요! ✨',
                style: GoogleFonts.jua(fontSize: 15, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: kPuzzleThemes.length,
                    itemBuilder: (ctx, i) {
                      final t = kPuzzleThemes[i];
                      return GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _themeIndex = i;
                            _showThemeSelect = false;
                            _gridSize = t.defaultGridSize;
                            _initPuzzle();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: t.bgGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(t.mainEmoji, style: const TextStyle(fontSize: 44)),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t.title,
                                    style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.textDark),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// JIGSAW PUZZLE PIECE CLIPPER & PAINTERS (凹凸 Shape Logic)
// ═══════════════════════════════════════════════════════════════════════════════

class _JigsawPieceClipper extends CustomClipper<Path> {
  final PieceEdge edge;
  _JigsawPieceClipper({required this.edge});

  @override
  Path getClip(Size size) {
    return _createJigsawPath(size, edge);
  }

  @override
  bool shouldReclip(_JigsawPieceClipper oldClipper) => oldClipper.edge != edge;
}

class _JigsawPieceBorderPainter extends CustomPainter {
  final PieceEdge edge;
  _JigsawPieceBorderPainter({required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createJigsawPath(size, edge);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_JigsawPieceBorderPainter oldPainter) => oldPainter.edge != edge;
}

class _JigsawGridOutlinePainter extends CustomPainter {
  final int gridSize;
  final List<PieceEdge> edges;

  _JigsawGridOutlinePainter({required this.gridSize, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final idx = r * gridSize + c;
        if (idx < edges.length) {
          canvas.save();
          canvas.translate(c * cellW, r * cellH);
          final path = _createJigsawPath(Size(cellW, cellH), edges[idx]);
          canvas.drawPath(path, paint);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_JigsawGridOutlinePainter oldPainter) => true;
}

Path _createJigsawPath(Size size, PieceEdge edge) {
  final path = Path();
  final w = size.width;
  final h = size.height;

  path.moveTo(0, 0);

  _drawEdgeTab(path, Offset(0, 0), Offset(w, 0), edge.top);
  _drawEdgeTab(path, Offset(w, 0), Offset(w, h), edge.right);
  _drawEdgeTab(path, Offset(w, h), Offset(0, h), edge.bottom);
  _drawEdgeTab(path, Offset(0, h), Offset(0, 0), edge.left);

  path.close();
  return path;
}

void _drawEdgeTab(Path path, Offset start, Offset end, TabType tab) {
  if (tab == TabType.none) {
    path.lineTo(end.dx, end.dy);
    return;
  }

  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final len = sqrt(dx * dx + dy * dy);

  final ux = dx / len;
  final uy = dy / len;

  final dir = (tab == TabType.out) ? 1.0 : -1.0;
  final px = -uy * dir;
  final py = ux * dir;

  final tabDepth = len * 0.15;
  final tabWidth = len * 0.26;

  final p1 = start + Offset(ux * (len - tabWidth) * 0.5, uy * (len - tabWidth) * 0.5);
  final p2 = p1 + Offset(px * tabDepth, py * tabDepth);
  final p3 = p2 + Offset(ux * tabWidth, uy * tabWidth);
  final p4 = start + Offset(ux * (len + tabWidth) * 0.5, uy * (len + tabWidth) * 0.5);

  path.lineTo(p1.dx, p1.dy);
  path.cubicTo(
    p1.dx + px * tabDepth * 0.5, p1.dy + py * tabDepth * 0.5,
    p2.dx - ux * tabWidth * 0.2, p2.dy - uy * tabWidth * 0.2,
    p2.dx, p2.dy,
  );
  path.lineTo(p3.dx, p3.dy);
  path.cubicTo(
    p3.dx + ux * tabWidth * 0.2, p3.dy + uy * tabWidth * 0.2,
    p4.dx + px * tabDepth * 0.5, p4.dy + py * tabDepth * 0.5,
    p4.dx, p4.dy,
  );
  path.lineTo(end.dx, end.dy);
}

class _ParticlePainter extends CustomPainter {
  final List<_Spark> sparks;
  _ParticlePainter({required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, 5 * s.life, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldPainter) => true;
}

class _FloatingShapesPainter extends CustomPainter {
  final double animValue;
  final Color color;

  _FloatingShapesPainter(this.animValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    
    _drawShape(canvas, paint, size, 0.15, 0.8, 40, animValue, 1.0);
    _drawShape(canvas, paint, size, 0.35, 0.5, 20, animValue, 1.5);
    _drawShape(canvas, paint, size, 0.75, 0.9, 50, animValue, 0.8);
    _drawShape(canvas, paint, size, 0.85, 0.3, 30, animValue, 1.2);
    _drawShape(canvas, paint, size, 0.50, 0.1, 25, animValue, 1.1);
    
    _drawShape(canvas, paint, size, 0.20, 0.2, 35, animValue, 0.9);
    _drawShape(canvas, paint, size, 0.65, 0.6, 45, animValue, 1.3);
  }

  void _drawShape(Canvas canvas, Paint paint, Size size, double nx, double ny, double radius, double anim, double speed) {
    double totalTravel = size.height + radius * 4;
    double progress = (ny + anim * speed) % 1.0;
    
    double y = (size.height + radius * 2) - progress * totalTravel;
    
    double x = size.width * nx + sin(progress * pi * 4) * (radius * 1.5);
    
    canvas.drawCircle(Offset(x, y), radius, paint);
    
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x - radius * 0.3, y - radius * 0.3), radius * 0.3, highlight);
  }

  @override
  bool shouldRepaint(_FloatingShapesPainter old) => old.animValue != animValue;
}
