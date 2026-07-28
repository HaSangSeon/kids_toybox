import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

class JigsawPuzzleGame extends StatefulWidget {
  const JigsawPuzzleGame({super.key});

  @override
  State<JigsawPuzzleGame> createState() => _JigsawPuzzleGameState();
}

class PuzzlePiece {
  final int id;
  final String emoji;
  final Color color;

  PuzzlePiece({required this.id, required this.emoji, required this.color});
}

class JigsawTheme {
  final String title;
  final List<PuzzlePiece> pieces;
  final List<Color> bgColors;
  final List<String> bgDecorations;

  const JigsawTheme({
    required this.title,
    required this.pieces,
    required this.bgColors,
    required this.bgDecorations,
  });
}

final List<JigsawTheme> _puzzleThemes = [
  JigsawTheme(
    title: '동물 농장 퍼즐',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🐶', color: const Color(0xFFFFD54F)), // Amber
      PuzzlePiece(id: 1, emoji: '🐱', color: const Color(0xFFF06292)), // Pink
      PuzzlePiece(id: 2, emoji: '🐰', color: const Color(0xFF81C784)), // Green
      PuzzlePiece(id: 3, emoji: '🐻', color: const Color(0xFFA1887F)), // Brown
    ],
    bgColors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
    bgDecorations: ['🌳', '🐰', '🌻', '🏡'],
  ),
  JigsawTheme(
    title: '바다 속 친구들',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🐳', color: const Color(0xFF64B5F6)), // Blue
      PuzzlePiece(id: 1, emoji: '🐙', color: const Color(0xFFE57373)), // Red
      PuzzlePiece(id: 2, emoji: '🦀', color: const Color(0xFFFF8A65)), // Orange
      PuzzlePiece(id: 3, emoji: '🐢', color: const Color(0xFF4DB6AC)), // Teal
    ],
    bgColors: [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)],
    bgDecorations: ['🪼', '🐚', '🐠', '🌊'],
  ),
  JigsawTheme(
    title: '달콤 과일 파티',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🍎', color: const Color(0xFFEF5350)), // Red
      PuzzlePiece(id: 1, emoji: '🍌', color: const Color(0xFFFFEE58)), // Yellow
      PuzzlePiece(id: 2, emoji: '🍇', color: const Color(0xFFAB47BC)), // Purple
      PuzzlePiece(id: 3, emoji: '🍓', color: const Color(0xFFEC407A)), // Pink
    ],
    bgColors: [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)],
    bgDecorations: ['🍒', '🍍', '🍉', '🍈'],
  ),
  JigsawTheme(
    title: '빵빵 교통 수단',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🚗', color: const Color(0xFF42A5F5)), // Blue
      PuzzlePiece(id: 1, emoji: '✈️', color: const Color(0xFF29B6F6)), // Sky Blue
      PuzzlePiece(id: 2, emoji: '🚢', color: const Color(0xFF26A69A)), // Teal
      PuzzlePiece(id: 3, emoji: '🚂', color: const Color(0xFFFF7043)), // Orange
    ],
    bgColors: [const Color(0xFFECEFF1), const Color(0xFFCFD8DC)],
    bgDecorations: ['🚦', '☁️', '⚓', '🛤️'],
  ),
  JigsawTheme(
    title: '숲속 곤충 탐험',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🦋', color: const Color(0xFFAB47BC)), // Purple
      PuzzlePiece(id: 1, emoji: '🐝', color: const Color(0xFFFFCA28)), // Amber
      PuzzlePiece(id: 2, emoji: '🐞', color: const Color(0xFFEF5350)), // Red
      PuzzlePiece(id: 3, emoji: '🦗', color: const Color(0xFF9CCC65)), // Light Green
    ],
    bgColors: [const Color(0xFFF1F8E9), const Color(0xFFDCEDC8)],
    bgDecorations: ['🌿', '🌸', '🍃', '🍄'],
  ),
  JigsawTheme(
    title: '공룡 시대 퍼즐',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🦖', color: const Color(0xFF66BB6A)), // Green
      PuzzlePiece(id: 1, emoji: '🦕', color: const Color(0xFF26C6DA)), // Cyan
      PuzzlePiece(id: 2, emoji: '🐊', color: const Color(0xFF26A69A)), // Teal
      PuzzlePiece(id: 3, emoji: '🌋', color: const Color(0xFFFF7043)), // Orange
    ],
    bgColors: [const Color(0xFFEFEBE9), const Color(0xFFD7CCC8)],
    bgDecorations: ['🌴', '🦴', '🥚', '🐾'],
  ),
  JigsawTheme(
    title: '알록달록 야채 친구들',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🥕', color: const Color(0xFFFFA726)), // Orange
      PuzzlePiece(id: 1, emoji: '🥦', color: const Color(0xFF4CAF50)), // Green
      PuzzlePiece(id: 2, emoji: '🌽', color: const Color(0xFFFFD54F)), // Amber
      PuzzlePiece(id: 3, emoji: '🍅', color: const Color(0xFFE57373)), // Red
    ],
    bgColors: [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
    bgDecorations: ['🌱', '🧺', '✨', '🥗'],
  ),
  JigsawTheme(
    title: '새콤달콤 디저트',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🍰', color: const Color(0xFFEC407A)), // Pink
      PuzzlePiece(id: 1, emoji: '🍦', color: const Color(0xFFFFE082)), // Amber
      PuzzlePiece(id: 2, emoji: '🍩', color: const Color(0xFF8D6E63)), // Brown
      PuzzlePiece(id: 3, emoji: '🍭', color: const Color(0xFFBA68C8)), // Purple
    ],
    bgColors: [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
    bgDecorations: ['✨', '🧁', '🍨', '🍬'],
  ),
  JigsawTheme(
    title: '신나는 우주 여행',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🚀', color: const Color(0xFF5C6BC0)), // Indigo
      PuzzlePiece(id: 1, emoji: '🪐', color: const Color(0xFFFFA726)), // Orange
      PuzzlePiece(id: 2, emoji: '⭐', color: const Color(0xFFFFD54F)), // Yellow
      PuzzlePiece(id: 3, emoji: '👾', color: const Color(0xFFAB47BC)), // Purple
    ],
    bgColors: [const Color(0xFFEDE7F6), const Color(0xFFD1C4E9)],
    bgDecorations: ['🌌', '☄️', '🛸', '🌙'],
  ),
  JigsawTheme(
    title: '와일드 사파리',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🦁', color: const Color(0xFFFFB74D)), // Amber
      PuzzlePiece(id: 1, emoji: '🐘', color: const Color(0xFF90A4AE)), // Blue Grey
      PuzzlePiece(id: 2, emoji: '🦒', color: const Color(0xFFFFD54F)), // Yellow
      PuzzlePiece(id: 3, emoji: '🦓', color: const Color(0xFF78909C)), // Grey
    ],
    bgColors: [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)],
    bgDecorations: ['🌾', '☀️', '🌴', '🏕️'],
  ),
  JigsawTheme(
    title: '신나는 스포츠',
    pieces: [
      PuzzlePiece(id: 0, emoji: '⚽', color: const Color(0xFF42A5F5)), // Blue
      PuzzlePiece(id: 1, emoji: '🏀', color: const Color(0xFFFF7043)), // Orange
      PuzzlePiece(id: 2, emoji: '⚾', color: const Color(0xFFEF5350)), // Red
      PuzzlePiece(id: 3, emoji: '🏈', color: const Color(0xFF8D6E63)), // Brown
    ],
    bgColors: [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
    bgDecorations: ['🏆', '🥇', '👟', '🏟️'],
  ),
  JigsawTheme(
    title: '예쁜 꽃밭 이야기',
    pieces: [
      PuzzlePiece(id: 0, emoji: '🌷', color: const Color(0xFFEC407A)), // Pink
      PuzzlePiece(id: 1, emoji: '🌻', color: const Color(0xFFFFCA28)), // Amber
      PuzzlePiece(id: 2, emoji: '🌹', color: const Color(0xFFE53935)), // Red
      PuzzlePiece(id: 3, emoji: '🌸', color: const Color(0xFFF48FB1)), // Light Pink
    ],
    bgColors: [const Color(0xFFF1F8E9), const Color(0xFFF0F4C3)],
    bgDecorations: ['🦋', '🐝', '💧', '☀️'],
  ),
];

class _JigsawPuzzleGameState extends State<JigsawPuzzleGame>
    with SingleTickerProviderStateMixin {
  int _score = 0;
  int _level = 1;
  bool _isLevelClear = false;
  bool _showStageSelect = true; // 게임 시작 시 주제 선택 화면 표시!

  late List<PuzzlePiece> _targetPieces;
  late List<PuzzlePiece> _availablePieces;
  late Map<int, PuzzlePiece?> _placedPieces;

  late AnimationController _clearController;
  late Animation<double> _clearScaleAnimation;

  @override
  void initState() {
    super.initState();
    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _clearScaleAnimation = CurvedAnimation(
      parent: _clearController,
      curve: Curves.elasticOut,
    );
    _generatePuzzle();
  }

  @override
  void dispose() {
    _clearController.dispose();
    super.dispose();
  }

  void _generatePuzzle() {
    final theme = _puzzleThemes[(_level - 1) % _puzzleThemes.length];
    _targetPieces = theme.pieces;

    _placedPieces = {0: null, 1: null, 2: null, 3: null};
    
    _availablePieces = List.from(_targetPieces);
    _availablePieces.shuffle();
    _isLevelClear = false;
    setState(() {});
  }

  void _checkWinCondition() {
    bool won = true;
    for (int i = 0; i < 4; i++) {
      if (_placedPieces[i] == null || _placedPieces[i]!.id != i) {
        won = false;
        break;
      }
    }

    if (won) {
      AudioManager.instance.playJigsawSuccess();
      HapticFeedback.mediumImpact();
      setState(() {
        _isLevelClear = true;
        _score += 20;
      });
      _clearController.forward(from: 0.0);

      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) {
          _clearController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _level++;
                _generatePuzzle();
              });
            }
          });
        }
      });
    }
  }

  // ─── Full-screen Stage Select Overlay ─────────────────────────────────────
  Widget _buildStageSelectOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.70),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 600),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _showStageSelect = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: KidsTheme.textDark),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧩', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 6),
                          Text(
                            '퍼즐 주제 선택',
                            style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '하고 싶은 퍼즐 주제를 마음대로 골라보세요!',
                  style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _puzzleThemes.length,
                    itemBuilder: (context, index) {
                      final t = _puzzleThemes[index];
                      final isSelected = (_level - 1) % _puzzleThemes.length == index;
                      final mainColor = t.bgColors.first;
                      final subColor = t.bgColors.last;

                      return GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _level = index + 1;
                            _showStageSelect = false;
                            _generatePuzzle();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [mainColor.withValues(alpha: 0.9), subColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: isSelected ? Border.all(color: Colors.yellow, width: 3.5) : null,
                            boxShadow: [
                              BoxShadow(
                                color: mainColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.pieces.map((p) => p.emoji).take(2).join(' '),
                                style: const TextStyle(fontSize: 38),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${index + 1}단계',
                                style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildThemeBackground(JigsawTheme theme) {
    final accentColor = theme.bgColors.last;
    final pieceEmojis = theme.pieces.map((p) => p.emoji).toList();
    final allEmojis = [...pieceEmojis, ...theme.bgDecorations];
    final rnd = Random(theme.title.length);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle dot-grid
          CustomPaint(
            painter: GridBackgroundPainter(dotColor: accentColor),
            child: const SizedBox.expand(),
          ),

          // Radial shimmer overlay (top-left)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.7),
                  radius: 1.0,
                  colors: [
                    Colors.white.withValues(alpha: 0.30),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Radial shimmer overlay (bottom-right)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 0.8),
                  radius: 0.8,
                  colors: [
                    accentColor.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Large scattered emoji decorations
          ...List.generate(allEmojis.length * 2, (i) {
            final emoji = allEmojis[i % allEmojis.length];
            final x = rnd.nextDouble();
            final y = rnd.nextDouble();
            final size = 28.0 + rnd.nextDouble() * 36;
            final opacity = 0.10 + rnd.nextDouble() * 0.18;
            final angle = (rnd.nextDouble() - 0.5) * 0.8;
            return Positioned(
              left: x * 380,
              top: y * 750,
              child: Transform.rotate(
                angle: angle,
                child: Opacity(
                  opacity: opacity,
                  child: Text(emoji, style: TextStyle(fontSize: size)),
                ),
              ),
            );
          }),

          // Animated floating bubbles
          const _JigsawAnimatedBubbles(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _puzzleThemes[(_level - 1) % _puzzleThemes.length];

    return Scaffold(
      body: Stack(
        children: [
          _buildThemeBackground(theme),
          SafeArea(
            child: Column(
              children: [
                // 상단 헤더 UI (고급스러운 단일 알약형 디자인)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 닫기/뒤로가기 버튼
                        GestureDetector(
                          onTap: () {
                            AudioManager.instance.playClick();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 20),
                          ),
                        ),
                        
                        // 중앙 타이틀
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🧩', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  theme.title,
                                  style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 상단 우측 주제 선택 버튼
                        GestureDetector(
                          onTap: () {
                            AudioManager.instance.playClick();
                            setState(() {
                              _showStageSelect = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [KidsTheme.purple, Color(0xFFAB47BC)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🗺️', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Text('주제', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // 퍼즐 보드 (2x2) - 완성 시 은은한 골드 글라우 및 부드러운 애니메이션
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isLevelClear ? const Color(0xFFFFD700) : Colors.white,
                      width: _isLevelClear ? 7 : 6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isLevelClear
                            ? const Color(0xFFFF9F1C).withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: _isLevelClear ? 25 : 15,
                        spreadRadius: _isLevelClear ? 4 : 0,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildDragTarget(0),
                              Container(width: 3, color: Colors.grey.shade200),
                              _buildDragTarget(1),
                            ],
                          ),
                        ),
                        Container(height: 3, color: Colors.grey.shade200),
                        Expanded(
                          child: Row(
                            children: [
                              _buildDragTarget(2),
                              Container(width: 3, color: Colors.grey.shade200),
                              _buildDragTarget(3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // 하단 드래그 가능 퍼즐 조각들 영역 (크기 줄여서 가로 스크롤 방지 및 프리미엄 스타일)
                Container(
                  height: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _availablePieces.map((piece) {
                      return Draggable<PuzzlePiece>(
                        data: piece,
                        onDragStarted: () {
                          AudioManager.instance.playJigsawPickup();
                        },
                        feedback: Transform.scale(
                          scale: 1.15,
                          child: Material(
                            color: Colors.transparent,
                            child: _buildPieceWidget(piece, size: 75.0),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: _buildPieceWidget(piece, size: 70.0),
                        ),
                        child: _buildPieceWidget(piece, size: 70.0),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // 🗺️ 하단 다른 퍼즐 선택 버튼 (아이들이 바로 알아보고 누르는 큼직한 오렌지 버튼)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      setState(() {
                        _showStageSelect = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🗺️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '다른 퍼즐 선택하기',
                            style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🌟 완성 축하 팝업 오버레이 (레이아웃 흔들림/움직임 제로!)
          if (_isLevelClear)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ScaleTransition(
                  scale: _clearScaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF9F1C)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 8),
                        Text(
                          '완성했어요! ✨',
                          style: GoogleFonts.jua(
                            fontSize: 24,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+20점!',
                            style: GoogleFonts.jua(fontSize: 14, color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 🗺️ 주제 선택 오버레이
          if (_showStageSelect) _buildStageSelectOverlay(),
        ],
      ),
    );
  }

  Widget _buildDragTarget(int index) {
    return Expanded(
      child: DragTarget<PuzzlePiece>(
        onWillAcceptWithDetails: (details) {
          return _placedPieces[index] == null;
        },
        onAcceptWithDetails: (details) {
          final piece = details.data;
          
          if (piece.id == index) {
            AudioManager.instance.playJigsawSnapCorrect();
            Future.delayed(const Duration(milliseconds: 150), () {
              AudioManager.instance.playEmojiSound(piece.emoji);
            });
            HapticFeedback.lightImpact();

            setState(() {
              _placedPieces[index] = piece;
              _availablePieces.remove(piece);
            });
            
            _checkWinCondition();
          } else {
            AudioManager.instance.playJigsawSnapIncorrect();
            // 오답일 경우 드래그 중이던 조각은 자동으로 원래 자리(하단 트레이)로 돌아갑니다.
          }
        },
        builder: (context, candidateData, rejectedData) {
          final placedPiece = _placedPieces[index];
          if (placedPiece != null) {
            return GestureDetector(
              onTap: () {
                if (_isLevelClear) return;
                AudioManager.instance.playClick();
                setState(() {
                  _availablePieces.add(placedPiece);
                  _placedPieces[index] = null;
                });
              },
              child: Center(
                child: _buildPieceWidget(placedPiece, size: 100.0),
              ),
            );
          } else {
            // 빈 슬롯
            return Container(
              color: candidateData.isNotEmpty ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
              child: Center(
                child: Text(
                  _targetPieces[index].emoji,
                  style: const TextStyle(fontSize: 45, color: Colors.black12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildPieceWidget(PuzzlePiece piece, {double size = 70.0, bool isDragging = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: piece.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDragging ? 0.25 : 0.1),
            blurRadius: isDragging ? 12 : 6,
            offset: Offset(0, isDragging ? 8 : 3),
          )
        ],
      ),
      child: Center(
        child: Text(
          piece.emoji,
          style: TextStyle(
            fontSize: size * 0.55,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class GridBackgroundPainter extends CustomPainter {
  final Color dotColor;
  const GridBackgroundPainter({this.dotColor = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const double step = 32.0;
    const double radius = 2.0;
    for (double y = step; y < size.height; y += step) {
      for (double x = step; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) => false;
}

// ─── Animated Floating Bubble Widget ────────────────────────────────────────

class _BubbleData {
  double x;
  double y;
  double radius;
  double speed;
  double drift;
  double driftPhase;
  double opacity;

  _BubbleData({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
    required this.driftPhase,
    required this.opacity,
  });
}

class _JigsawAnimatedBubbles extends StatefulWidget {
  const _JigsawAnimatedBubbles();

  @override
  State<_JigsawAnimatedBubbles> createState() => _JigsawAnimatedBubblesState();
}

class _JigsawAnimatedBubblesState extends State<_JigsawAnimatedBubbles>
    with SingleTickerProviderStateMixin {
  late List<_BubbleData> _bubbles;
  late Ticker _ticker;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(18, (_) => _makeBubble(Random()));
    _ticker = createTicker(_onTick)..start();
  }

  _BubbleData _makeBubble(Random r, {double? startY}) {
    return _BubbleData(
      x: r.nextDouble(),
      y: startY ?? (0.6 + r.nextDouble() * 0.5), // start below screen
      radius: 6 + r.nextDouble() * 22,
      speed: 0.0003 + r.nextDouble() * 0.0004,
      drift: 0.015 + r.nextDouble() * 0.03,
      driftPhase: r.nextDouble() * 2 * pi,
      opacity: 0.08 + r.nextDouble() * 0.12,
    );
  }

  double _time = 0;
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    _time = elapsed.inMilliseconds / 1000.0;
    setState(() {
      for (final b in _bubbles) {
        b.y -= b.speed;
        if (b.y < -0.15) {
          // Recycle bubble from bottom
          final nb = _makeBubble(_rnd, startY: 1.05 + _rnd.nextDouble() * 0.1);
          b.x = nb.x; b.y = nb.y; b.radius = nb.radius;
          b.speed = nb.speed; b.drift = nb.drift;
          b.driftPhase = nb.driftPhase; b.opacity = nb.opacity;
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      return Stack(
        children: _bubbles.map((b) {
          final offsetX = sin(_time * 0.7 + b.driftPhase) * b.drift * w;
          final cx = b.x * w + offsetX;
          final cy = b.y * h;
          return Positioned(
            left: cx - b.radius,
            top: cy - b.radius,
            child: Container(
              width: b.radius * 2,
              height: b.radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: b.opacity),
                border: Border.all(
                  color: Colors.white.withValues(alpha: b.opacity * 1.6),
                  width: 1.2,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
