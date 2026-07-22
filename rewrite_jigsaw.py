code = """import 'dart:math';
import 'package:flutter/material';
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
];

class _JigsawPuzzleGameState extends State<JigsawPuzzleGame> {
  int _score = 0;
  int _level = 1;
  bool _isLevelClear = false;

  late List<PuzzlePiece> _targetPieces;
  late List<PuzzlePiece> _availablePieces;
  late Map<int, PuzzlePiece?> _placedPieces;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
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
      setState(() {
        _isLevelClear = true;
        _score += 20;
      });

      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) {
          setState(() {
            _level++;
            _generatePuzzle();
          });
        }
      });
    }
  }

  Widget _buildThemeBackground(JigsawTheme theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.bgColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: GridBackgroundPainter(),
            child: const SizedBox.expand(),
          ),
          if (theme.bgDecorations.length >= 4) ...[
            Positioned(top: 100, left: 30, child: Text(theme.bgDecorations[0], style: const TextStyle(fontSize: 40))),
            Positioned(top: 180, right: 40, child: Text(theme.bgDecorations[1], style: const TextStyle(fontSize: 35))),
            Positioned(bottom: 160, left: 50, child: Text(theme.bgDecorations[2], style: const TextStyle(fontSize: 35))),
            Positioned(bottom: 240, right: 30, child: Text(theme.bgDecorations[3], style: const TextStyle(fontSize: 40))),
          ],
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
                        // 닫기 버튼
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
                            child: const Icon(Icons.close_rounded, color: KidsTheme.textDark, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 타이틀
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🧩', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  theme.title,
                                  style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 점수 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade200, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '$_score',
                                style: GoogleFonts.jua(fontSize: 16, color: Colors.amber.shade900),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                if (_isLevelClear)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: KidsTheme.toyDecoration(
                      color: KidsTheme.green,
                      borderRadius: 32,
                    ),
                    child: Text(
                      '완성했어요! 🌟',
                      style: GoogleFonts.jua(fontSize: 32, color: Colors.white),
                    ),
                  ),

                const Spacer(),

                // 퍼즐 보드 (2x2)
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
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
                        feedback: _buildPieceWidget(piece, size: 85.0, isDragging: true),
                        childWhenDragging: Opacity(
                          opacity: 0.25,
                          child: _buildPieceWidget(piece, size: 70.0),
                        ),
                        child: _buildPieceWidget(piece, size: 70.0),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
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
            HapticFeedback.lightImpact();
          } else {
            AudioManager.instance.playJigsawSnapIncorrect();
          }

          setState(() {
            _placedPieces[index] = piece;
            _availablePieces.remove(piece);
          });
          
          _checkWinCondition();
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
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.03)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double step = 30.0;
    for (double y = 60; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 30; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
"""

with open("lib/games/jigsaw_puzzle/jigsaw_puzzle_game.dart", "w", encoding="utf-8") as f:
    f.write(code)
print("Updated jigsaw_puzzle_game.dart successfully")
