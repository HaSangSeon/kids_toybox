code = """import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

class MazeTheme {
  final String title;
  final int rows;
  final int cols;
  final List<List<int>> maze;
  final String playerEmoji;
  final String goalEmoji;
  final String wallEmoji;
  final List<Color> backgroundGradient;

  MazeTheme({
    required this.title,
    required this.rows,
    required this.cols,
    required this.maze,
    required this.playerEmoji,
    required this.goalEmoji,
    required this.wallEmoji,
    required this.backgroundGradient,
  });
}

class MazeEscapeGame extends StatefulWidget {
  const MazeEscapeGame({super.key});

  @override
  State<MazeEscapeGame> createState() => _MazeEscapeGameState();
}

class _MazeEscapeGameState extends State<MazeEscapeGame> {
  int _score = 0;
  bool _isLevelClear = false;
  int _level = 1;

  late MazeTheme _currentTheme;

  // 1: Wall, 0: Path
  final List<MazeTheme> _themes = [
    // Level 1: 5x5 Farm
    MazeTheme(
      title: '동물 농장 미로 🐭',
      rows: 5, cols: 5,
      playerEmoji: '🐭', goalEmoji: '🧀', wallEmoji: '🧱',
      backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      maze: [
        [0, 0, 1, 0, 0],
        [1, 0, 1, 0, 1],
        [0, 0, 0, 0, 0],
        [0, 1, 1, 1, 0],
        [0, 0, 0, 1, 0],
      ],
    ),
    // Level 2: 6x6 Ocean
    MazeTheme(
      title: '바다 탐험 🐠',
      rows: 6, cols: 6,
      playerEmoji: '🐠', goalEmoji: '🐚', wallEmoji: '🪸',
      backgroundGradient: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
      maze: [
        [0, 0, 0, 1, 0, 0],
        [0, 1, 0, 1, 0, 1],
        [0, 1, 0, 0, 0, 0],
        [0, 1, 1, 1, 1, 0],
        [0, 0, 0, 0, 1, 0],
        [1, 1, 1, 0, 0, 0],
      ],
    ),
    // Level 3: 7x7 Garden
    MazeTheme(
      title: '꽃밭 나들이 🐝',
      rows: 7, cols: 7,
      playerEmoji: '🐝', goalEmoji: '🌻', wallEmoji: '🌿',
      backgroundGradient: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      maze: [
        [0, 1, 0, 0, 0, 0, 0],
        [0, 1, 0, 1, 1, 1, 0],
        [0, 0, 0, 1, 0, 0, 0],
        [1, 1, 1, 1, 0, 1, 1],
        [0, 0, 0, 0, 0, 1, 0],
        [0, 1, 1, 1, 1, 1, 0],
        [0, 0, 0, 0, 0, 0, 0],
      ],
    ),
    // Level 4: 8x8 Space
    MazeTheme(
      title: '우주 비행 🚀',
      rows: 8, cols: 8,
      playerEmoji: '🚀', goalEmoji: '🌎', wallEmoji: '☄️',
      backgroundGradient: [Color(0xFF1A237E), Color(0xFF311B92)],
      maze: [
        [0, 0, 1, 0, 0, 0, 1, 0],
        [1, 0, 1, 0, 1, 0, 1, 0],
        [0, 0, 0, 0, 1, 0, 0, 0],
        [0, 1, 1, 1, 1, 1, 1, 0],
        [0, 0, 0, 0, 0, 0, 1, 0],
        [1, 1, 1, 1, 1, 0, 1, 0],
        [0, 0, 0, 0, 1, 0, 0, 0],
        [0, 1, 1, 0, 0, 0, 1, 0],
      ],
    ),
  ];

  double _playerX = 0.0;
  double _playerY = 0.0;
  double _goalX = 0.0;
  double _goalY = 0.0;
  double _cellSize = 0.0;

  @override
  void initState() {
    super.initState();
    _loadLevel();
  }

  void _loadLevel() {
    _isLevelClear = false;
    _currentTheme = _themes[(_level - 1) % _themes.length];
    
    // reset position
    _playerX = 0.0;
    _playerY = 0.0;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, double boardWidth, double boardHeight) {
    if (_isLevelClear) return;

    setState(() {
      double newX = _playerX + details.delta.dx;
      double newY = _playerY + details.delta.dy;

      // Bound checking
      if (newX < 0) newX = 0;
      if (newY < 0) newY = 0;
      if (newX > boardWidth - _cellSize) newX = boardWidth - _cellSize;
      if (newY > boardHeight - _cellSize) newY = boardHeight - _cellSize;

      // Hitbox is slightly smaller than the cell for smooth sliding
      double hitMargin = _cellSize * 0.2;
      double playerLeft = newX + hitMargin;
      double playerRight = newX + _cellSize - hitMargin;
      double playerTop = newY + hitMargin;
      double playerBottom = newY + _cellSize - hitMargin;

      int colStart = (playerLeft / _cellSize).floor();
      int colEnd = (playerRight / _cellSize).floor();
      int rowStart = (playerTop / _cellSize).floor();
      int rowEnd = (playerBottom / _cellSize).floor();

      bool collision = false;
      for (int r = rowStart; r <= rowEnd; r++) {
        for (int c = colStart; c <= colEnd; c++) {
          if (r >= 0 && r < _currentTheme.rows && c >= 0 && c < _currentTheme.cols) {
            if (_currentTheme.maze[r][c] == 1) {
              collision = true;
              break;
            }
          }
        }
        if (collision) break;
      }

      if (!collision) {
        // Move valid
        int oldCol = (_playerX / _cellSize).round();
        int oldRow = (_playerY / _cellSize).round();
        _playerX = newX;
        _playerY = newY;
        
        int newCol = (_playerX / _cellSize).round();
        int newRow = (_playerY / _cellSize).round();
        if (oldCol != newCol || oldRow != newRow) {
           AudioManager.instance.playMazeMove();
        }
      } else {
        AudioManager.instance.playMazeBump();
        HapticFeedback.selectionClick();
      }

      // Check goal
      if ((_playerX - _goalX).abs() < _cellSize * 0.4 && (_playerY - _goalY).abs() < _cellSize * 0.4) {
        _isLevelClear = true;
        _score += 50;
        AudioManager.instance.playMazeClear();
        HapticFeedback.heavyImpact();

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _level++;
              _loadLevel();
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _currentTheme.backgroundGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: const Icon(Icons.close, color: KidsTheme.textDark, size: 28),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _currentTheme.title,
                            style: GoogleFonts.jua(
                              fontSize: 28,
                              color: _level == 4 ? Colors.indigo : KidsTheme.orange,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: KidsTheme.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          '⭐ $_score',
                          style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Padding around the board
                    double availableWidth = constraints.maxWidth - 32;
                    double availableHeight = constraints.maxHeight - 64;

                    _cellSize = min(
                      availableWidth / _currentTheme.cols,
                      availableHeight / _currentTheme.rows,
                    );

                    double boardWidth = _cellSize * _currentTheme.cols;
                    double boardHeight = _cellSize * _currentTheme.rows;
                    
                    _goalX = (_currentTheme.cols - 1) * _cellSize;
                    _goalY = (_currentTheme.rows - 1) * _cellSize;

                    return Center(
                      child: Container(
                        width: boardWidth + 12, // add border width
                        height: boardHeight + 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Render Grid Lines Optional
                            for (int r = 0; r <= _currentTheme.rows; r++)
                              Positioned(
                                top: r * _cellSize, left: 0,
                                child: Container(width: boardWidth, height: 1, color: Colors.black.withValues(alpha: 0.05)),
                              ),
                            for (int c = 0; c <= _currentTheme.cols; c++)
                              Positioned(
                                top: 0, left: c * _cellSize,
                                child: Container(width: 1, height: boardHeight, color: Colors.black.withValues(alpha: 0.05)),
                              ),

                            // Draw Walls
                            for (int r = 0; r < _currentTheme.rows; r++)
                              for (int c = 0; c < _currentTheme.cols; c++)
                                if (_currentTheme.maze[r][c] == 1)
                                  Positioned(
                                    left: c * _cellSize,
                                    top: r * _cellSize,
                                    width: _cellSize,
                                    height: _cellSize,
                                    child: Center(
                                      child: Text(
                                        _currentTheme.wallEmoji,
                                        style: TextStyle(fontSize: _cellSize * 0.6),
                                      ),
                                    ),
                                  ),

                            // Goal
                            Positioned(
                              left: _goalX,
                              top: _goalY,
                              width: _cellSize,
                              height: _cellSize,
                              child: Center(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.1),
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.easeInOut,
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: child,
                                    );
                                  },
                                  onEnd: () {
                                    // continuous bounce would require a state or looping animation controller,
                                    // simplified with just one bounce here
                                  },
                                  child: Text(_currentTheme.goalEmoji, style: TextStyle(fontSize: _cellSize * 0.7)),
                                ),
                              ),
                            ),

                            // Player
                            Positioned(
                              left: _playerX,
                              top: _playerY,
                              width: _cellSize,
                              height: _cellSize,
                              child: GestureDetector(
                                onPanUpdate: (details) => _onPanUpdate(details, boardWidth, boardHeight),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent, // expanded hitbox
                                  ),
                                  child: Center(
                                    child: AnimatedScale(
                                      scale: _isLevelClear ? 1.5 : 1.0,
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.elasticOut,
                                      child: Text(_currentTheme.playerEmoji, style: TextStyle(fontSize: _cellSize * 0.7)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isLevelClear)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: KidsTheme.toyDecoration(
                      color: KidsTheme.green,
                      borderRadius: 32,
                    ),
                    child: Text(
                      '도착했어요! 🌟',
                      style: GoogleFonts.jua(fontSize: 40, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
"""
with open("lib/games/maze_escape/maze_escape_game.dart", "w") as f:
    f.write(code)
