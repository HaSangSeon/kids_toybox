import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';

// ─── Map Constants & Cell Types ─────────────────────────────────────────────
const int cellEmpty = 0;
const int cellWall = 1;
const int cellDot = 2;
const int cellPower = 3;
const int cellGhostHouse = 4;
const int cellFruit = 5;

/// Stage Theme Definitions
class StageTheme {
  final String name;
  final Color wallFill;
  final Color wallOuter;
  final Color wallInner;
  final Color bg;
  final String fruitEmoji;
  final int fruitPoints;

  const StageTheme({
    required this.name,
    required this.wallFill,
    required this.wallOuter,
    required this.wallInner,
    required this.bg,
    required this.fruitEmoji,
    required this.fruitPoints,
  });
}

const List<StageTheme> kStageThemes = [
  // Stage 1: Classic Royal Blue & Cherry
  StageTheme(
    name: '네온 블루',
    wallFill: Color(0xFF0A1026),
    wallOuter: Color(0xFF1D4ED8),
    wallInner: Color(0xFF60A5FA),
    bg: Color(0xFF030712),
    fruitEmoji: '🍒',
    fruitPoints: 100,
  ),
  // Stage 2: Emerald Green & Strawberry
  StageTheme(
    name: '에메랄드 그린',
    wallFill: Color(0xFF064E3B),
    wallOuter: Color(0xFF059669),
    wallInner: Color(0xFF34D399),
    bg: Color(0xFF022C22),
    fruitEmoji: '🍓',
    fruitPoints: 300,
  ),
  // Stage 3: Electric Purple & Orange
  StageTheme(
    name: '일렉트릭 퍼플',
    wallFill: Color(0xFF3B0764),
    wallOuter: Color(0xFF7C3AED),
    wallInner: Color(0xFFC084FC),
    bg: Color(0xFF1E1B4B),
    fruitEmoji: '🍊',
    fruitPoints: 500,
  ),
  // Stage 4: Crimson Pink & Apple
  StageTheme(
    name: '크림슨 핑크',
    wallFill: Color(0xFF4C0519),
    wallOuter: Color(0xFFE11D48),
    wallInner: Color(0xFFFB7185),
    bg: Color(0xFF2A0A12),
    fruitEmoji: '🍎',
    fruitPoints: 700,
  ),
  // Stage 5: Cyber Gold & Melon
  StageTheme(
    name: '사이버 골드',
    wallFill: Color(0xFF451A03),
    wallOuter: Color(0xFFD97706),
    wallInner: Color(0xFFFBBF24),
    bg: Color(0xFF1C0D02),
    fruitEmoji: '🍈',
    fruitPoints: 1000,
  ),
];

/// 5 Unique Level Map Templates (15 Rows x 13 Columns)
const List<List<List<int>>> kPacmanMaps = [
  // Map 1: Very Simple Big Blocks (Level 1)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 3, 2, 2, 2, 2, 1, 2, 2, 2, 2, 3, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 4, 4, 4, 1, 1, 1, 2, 1],
    [0, 2, 1, 1, 1, 4, 4, 4, 1, 1, 1, 2, 0],
    [1, 2, 1, 1, 1, 1, 0, 1, 1, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 3, 2, 2, 1, 2, 0, 2, 1, 2, 2, 3, 1],
    [1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Map 2: Dual Circuit Loops (Level 2)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 3, 2, 2, 1, 2, 2, 2, 1, 2, 2, 3, 1],
    [1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 1],
    [1, 2, 1, 4, 4, 4, 4, 4, 4, 4, 1, 2, 1],
    [0, 2, 1, 4, 4, 4, 4, 4, 4, 4, 1, 2, 0],
    [1, 2, 1, 1, 1, 1, 0, 1, 1, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 1, 1, 2, 1, 1, 1, 1, 1, 2, 1, 1, 1],
    [1, 3, 2, 2, 2, 2, 0, 2, 2, 2, 2, 3, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Map 3: Diamond Center Maze (Level 3)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1],
    [1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1, 2, 1],
    [1, 2, 1, 2, 2, 2, 1, 2, 2, 2, 1, 2, 1],
    [1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 1],
    [1, 1, 1, 2, 1, 4, 4, 4, 1, 2, 1, 1, 1],
    [0, 2, 2, 2, 1, 4, 4, 4, 1, 2, 2, 2, 0],
    [1, 1, 1, 2, 1, 1, 0, 1, 1, 2, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 3, 2, 1, 2, 2, 0, 2, 2, 1, 2, 3, 1],
    [1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Map 4: Twin Castle Towers (Level 4)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 3, 2, 1, 2, 2, 2, 2, 2, 1, 2, 3, 1],
    [1, 1, 2, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1],
    [1, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 1],
    [1, 1, 1, 2, 1, 4, 4, 4, 1, 2, 1, 1, 1],
    [0, 0, 1, 2, 1, 4, 4, 4, 1, 2, 1, 0, 0],
    [1, 1, 1, 2, 1, 1, 0, 1, 1, 2, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1, 2, 1],
    [1, 3, 1, 2, 2, 2, 0, 2, 2, 2, 1, 3, 1],
    [1, 1, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
  // Map 5: Spiral Core Layout (Level 5+)
  [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 1],
    [1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1],
    [1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1],
    [1, 2, 1, 2, 1, 1, 2, 1, 1, 2, 1, 2, 1],
    [1, 1, 1, 2, 1, 4, 4, 4, 1, 2, 1, 1, 1],
    [0, 2, 2, 2, 1, 4, 4, 4, 1, 2, 2, 2, 0],
    [1, 1, 1, 2, 1, 1, 0, 1, 1, 2, 1, 1, 1],
    [1, 2, 1, 2, 1, 1, 1, 1, 1, 2, 1, 2, 1],
    [1, 2, 1, 2, 2, 2, 2, 2, 2, 2, 1, 2, 1],
    [1, 3, 1, 1, 1, 1, 0, 1, 1, 1, 1, 3, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 2, 1],
    [1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ],
];

// ─── Data Classes ───────────────────────────────────────────────────────────
enum Direction { none, up, down, left, right }

enum GhostState { normal, frightened, eaten }

class Ghost {
  final String name;
  final Color color;
  final String emoji;
  double x;
  double y;
  Direction dir;
  GhostState state;
  int houseTimer;
  int lastTileX;
  int lastTileY;

  Ghost({
    required this.name,
    required this.color,
    required this.emoji,
    required this.x,
    required this.y,
    this.dir = Direction.up,
    this.state = GhostState.normal,
    this.houseTimer = 0,
    this.lastTileX = -1,
    this.lastTileY = -1,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.size = 8.0,
    this.opacity = 1.0,
  });
}

// ─── Pacman Game Widget ─────────────────────────────────────────────────────
class PacmanGame extends StatefulWidget {
  final String playerSkin;

  const PacmanGame({
    super.key,
    this.playerSkin = '🟡',
  });

  @override
  State<PacmanGame> createState() => _PacmanGameState();
}

class _PacmanGameState extends State<PacmanGame>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late ConfettiController _confettiController;

  int _level = 1;
  int _score = 0;
  int _highScore = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isGameClear = false;
  bool _isPaused = false;

  // Current Stage Theme
  StageTheme get _currentTheme => kStageThemes[(_level - 1) % kStageThemes.length];

  // Grid Map State
  late List<List<int>> _grid;
  int _totalDots = 0;
  int _dotsEaten = 0;
  bool _fruitSpawned = false;

  // Player State
  double _playerX = 6.0;
  double _playerY = 12.0;
  Direction _currentDir = Direction.none;
  Direction _nextDir = Direction.none;
  double _mouthAngle = 0.2;
  bool _mouthOpening = true;

  // Power Pellet State
  bool _isPowerActive = false;
  int _powerTimeRemainingMs = 0;

  // Ghosts State
  late List<Ghost> _ghosts;

  // Visual effects
  final List<Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initLevel(_level);

    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _initLevel(int level) {
    final mapIdx = (level - 1) % kPacmanMaps.length;
    final template = kPacmanMaps[mapIdx];

    // Deep copy grid map based on progressive level templates
    _grid = List.generate(
      template.length,
      (r) => List.generate(template[r].length, (c) => template[r][c]),
    );

    _totalDots = 0;
    _dotsEaten = 0;
    _fruitSpawned = false;
    for (var r = 0; r < _grid.length; r++) {
      for (var c = 0; c < _grid[r].length; c++) {
        if (_grid[r][c] == cellDot || _grid[r][c] == cellPower) {
          _totalDots++;
        }
      }
    }

    // Reset Player position (6.0, 10.0)
    _playerX = 6.0;
    _playerY = 10.0;
    _currentDir = Direction.none;
    _nextDir = Direction.none;

    // Staggered Ghost House exit times scaled by Level (much slower on Level 1)
    final int pinkyDelay = (3500 - (_level * 500)).clamp(500, 3000);
    final int inkyDelay = (8000 - (_level * 1000)).clamp(1000, 7000);
    final int clydeDelay = (13000 - (_level * 2000)).clamp(1500, 11000);

    _ghosts = [
      Ghost(name: '블링키', color: const Color(0xFFEF4444), emoji: '🔴', x: 6.0, y: 5.0, houseTimer: 0),
      Ghost(name: '핑키', color: const Color(0xFFEC4899), emoji: '🩷', x: 5.0, y: 6.0, houseTimer: pinkyDelay),
      Ghost(name: '인키', color: const Color(0xFF06B6D4), emoji: '🩵', x: 6.0, y: 6.0, houseTimer: inkyDelay),
      Ghost(name: '클라이드', color: const Color(0xFFF97316), emoji: '🧡', x: 7.0, y: 6.0, houseTimer: clydeDelay),
    ];

    _isPowerActive = false;
    _powerTimeRemainingMs = 0;
    _isGameClear = false;
    _isGameOver = false;
  }

  // ── Game Logic Updates ────────────────────────────────────────────────────
  double _lastTickTime = 0;

  void _onTick(Duration elapsed) {
    if (_isGameOver || _isGameClear || _isPaused) return;

    final double currentTime = elapsed.inMilliseconds / 1000.0;
    if (_lastTickTime == 0) {
      _lastTickTime = currentTime;
      return;
    }
    final double dt = (currentTime - _lastTickTime).clamp(0.001, 0.05);
    _lastTickTime = currentTime;

    setState(() {
      _updateMouthAnimation();
      _updatePowerTimer(dt);
      _updatePlayerMovement(dt);
      _updateGhostsMovement(dt);
      _checkCollisions();
      _updateParticles(dt);
    });
  }

  void _updateMouthAnimation() {
    if (_mouthOpening) {
      _mouthAngle += 0.04;
      if (_mouthAngle >= 0.7) _mouthOpening = false;
    } else {
      _mouthAngle -= 0.04;
      if (_mouthAngle <= 0.1) _mouthOpening = true;
    }
  }

  void _updatePowerTimer(double dt) {
    if (_isPowerActive) {
      _powerTimeRemainingMs -= (dt * 1000).toInt();
      if (_powerTimeRemainingMs <= 0) {
        _isPowerActive = false;
        _powerTimeRemainingMs = 0;
        for (var g in _ghosts) {
          if (g.state == GhostState.frightened) {
            g.state = GhostState.normal;
          }
        }
      }
    }
  }

  bool _canMove(double currX, double currY, Direction dir, {bool isGhost = false}) {
    if (dir == Direction.none) return true;

    final double speedFactor = isGhost ? 0.05 : 0.25;
    double targetX = currX;
    double targetY = currY;

    switch (dir) {
      case Direction.up:    targetY -= speedFactor; break;
      case Direction.down:  targetY += speedFactor; break;
      case Direction.left:  targetX -= speedFactor; break;
      case Direction.right: targetX += speedFactor; break;
      case Direction.none:  return true;
    }

    // Tunnel wrap around sides
    if (targetX < 0 || targetX >= 13) return true;

    final int r1 = targetY.floor().clamp(0, 14);
    final int r2 = targetY.ceil().clamp(0, 14);
    final int c1 = targetX.floor().clamp(0, 12);
    final int c2 = targetX.ceil().clamp(0, 12);

    return _grid[r1][c1] != cellWall &&
           _grid[r1][c2] != cellWall &&
           _grid[r2][c1] != cellWall &&
           _grid[r2][c2] != cellWall;
  }

  void _updatePlayerMovement(double dt) {
    final double speed = 3.8 + (_level * 0.15).clamp(0.0, 1.5);

    if (_nextDir != Direction.none) {
      if (_currentDir == Direction.none) {
        if (_canMove(_playerX, _playerY, _nextDir)) {
          _currentDir = _nextDir;
        }
      } else if (_nextDir != _currentDir) {
        final double snapTolerance = 0.45;
        final double alignX = (_playerX - _playerX.round()).abs();
        final double alignY = (_playerY - _playerY.round()).abs();

        if ((_nextDir == Direction.up || _nextDir == Direction.down) && alignX < snapTolerance) {
          if (_canMove(_playerX.roundToDouble(), _playerY, _nextDir)) {
            _playerX = _playerX.roundToDouble();
            _currentDir = _nextDir;
          }
        } else if ((_nextDir == Direction.left || _nextDir == Direction.right) && alignY < snapTolerance) {
          if (_canMove(_playerX, _playerY.roundToDouble(), _nextDir)) {
            _playerY = _playerY.roundToDouble();
            _currentDir = _nextDir;
          }
        } else if (_nextDir == _oppositeDir(_currentDir)) {
          _currentDir = _nextDir;
        }
      }
    }

    if (_canMove(_playerX, _playerY, _currentDir)) {
      switch (_currentDir) {
        case Direction.up:    _playerY -= speed * dt; break;
        case Direction.down:  _playerY += speed * dt; break;
        case Direction.left:  _playerX -= speed * dt; break;
        case Direction.right: _playerX += speed * dt; break;
        case Direction.none:  break;
      }
    }

    // Tunnel warp around map edges
    if (_playerX < -0.5) _playerX = 12.5;
    if (_playerX > 12.5) _playerX = -0.5;

    // Check cell pickup
    final int gridR = _playerY.round().clamp(0, 14);
    final int gridC = _playerX.round().clamp(0, 12);

    final cell = _grid[gridR][gridC];
    if (cell == cellDot) {
      _grid[gridR][gridC] = cellEmpty;
      _score += 10;
      if (_score > _highScore) _highScore = _score;
      _dotsEaten++;
      AudioManager.instance.playPop();
      _spawnParticles(gridC + 0.5, gridR + 0.5, _currentTheme.wallInner, 4);

      // Spawn stage fruit when 30% of dots eaten
      if (!_fruitSpawned && _dotsEaten > (_totalDots * 0.3)) {
        _fruitSpawned = true;
        _grid[8][6] = cellFruit;
      }

      _checkVictory();
    } else if (cell == cellPower) {
      _grid[gridR][gridC] = cellEmpty;
      _score += 50;
      if (_score > _highScore) _highScore = _score;
      _dotsEaten++;
      _isPowerActive = true;
      _powerTimeRemainingMs = (8500 - (_level * 600)).clamp(3500, 8500);
      AudioManager.instance.playSuccess();
      _spawnParticles(gridC + 0.5, gridR + 0.5, Colors.lightBlueAccent, 12);

      for (var g in _ghosts) {
        if (g.state == GhostState.normal) {
          g.state = GhostState.frightened;
        }
      }
      _checkVictory();
    } else if (cell == cellFruit) {
      _grid[gridR][gridC] = cellEmpty;
      _score += _currentTheme.fruitPoints;
      if (_score > _highScore) _highScore = _score;
      AudioManager.instance.playSuccess();
      _spawnParticles(gridC + 0.5, gridR + 0.5, Colors.amberAccent, 16);
    }
  }

  void _updateGhostsMovement(double dt) {
    final double speed = _isPowerActive ? 0.9 : (0.8 + (_level * 0.25).clamp(0.0, 2.5));

    for (var g in _ghosts) {
      if (g.houseTimer > 0) {
        g.houseTimer -= (dt * 1000).toInt();
        continue;
      }

      // Dedicated Ghost House Exit Guidance
      final int gr = g.y.round().clamp(0, 14);
      final int gc = g.x.round().clamp(0, 12);
      final bool isInsideHouse = _grid[gr][gc] == cellGhostHouse;

      if (isInsideHouse && g.state != GhostState.eaten) {
        if ((g.x - 6.0).abs() > 0.1) {
          g.x += (6.0 - g.x).sign * 2.5 * dt;
        } else {
          g.x = 6.0;
          g.y -= 2.8 * dt; // Exit UP into Row 4
          g.dir = Direction.up;
        }
        continue;
      }

      if (g.state == GhostState.eaten) {
        // Return to house center
        g.x += (6.0 - g.x).sign * 4.0 * dt;
        g.y += (6.0 - g.y).sign * 4.0 * dt;
        if ((g.x - 6.0).abs() < 0.3 && (g.y - 6.0).abs() < 0.3) {
          g.state = GhostState.normal;
          g.houseTimer = 3000; // Respawn delay 3 seconds
          g.lastTileX = -1;
          g.lastTileY = -1;
        }
        continue;
      }

      // Standard Ghost AI Movement with Grid Snapping at intersections
      final int tileX = g.x.round().clamp(0, 12);
      final int tileY = g.y.round().clamp(0, 14);

      final bool isNewTile = (tileX != g.lastTileX || tileY != g.lastTileY);
      final double distFromCenter = max((g.x - tileX).abs(), (g.y - tileY).abs());
      final bool nearCenter = distFromCenter < 0.12;

      if (isNewTile && nearCenter) {
        g.lastTileX = tileX;
        g.lastTileY = tileY;

        final opposite = _oppositeDir(g.dir);
        final validDirs = <Direction>[];
        for (var d in [Direction.up, Direction.down, Direction.left, Direction.right]) {
          if (d != opposite && _canMove(tileX.toDouble(), tileY.toDouble(), d, isGhost: true)) {
            validDirs.add(d);
          }
        }

        final bool currentDirBlocked = !_canMove(tileX.toDouble(), tileY.toDouble(), g.dir, isGhost: true);
        Direction nextDir = g.dir;

        if (currentDirBlocked) {
          if (validDirs.isNotEmpty) {
            nextDir = validDirs[_rng.nextInt(validDirs.length)];
          } else {
            nextDir = opposite; // Dead end, U-turn
          }
        } else if (validDirs.length > 1 && _rng.nextDouble() < 0.35) {
          final alternatives = validDirs.where((d) => d != g.dir).toList();
          if (alternatives.isNotEmpty) {
            nextDir = alternatives[_rng.nextInt(alternatives.length)];
          }
        }

        if (nextDir != g.dir) {
          // Snap position only when turning to align cleanly with perpendicular corridor
          g.x = tileX.toDouble();
          g.y = tileY.toDouble();
          g.dir = nextDir;
        }
      }

      // Apply movement
      if (_canMove(g.x, g.y, g.dir, isGhost: true)) {
        switch (g.dir) {
          case Direction.up:    g.y -= speed * dt; break;
          case Direction.down:  g.y += speed * dt; break;
          case Direction.left:  g.x -= speed * dt; break;
          case Direction.right: g.x += speed * dt; break;
          case Direction.none:  break;
        }
      } else {
        // Fallback: U-turn if blocked unexpectedly (e.g. initialization or lag)
        g.dir = _oppositeDir(g.dir);
      }
    }
  }

  Direction _oppositeDir(Direction d) {
    switch (d) {
      case Direction.up:    return Direction.down;
      case Direction.down:  return Direction.up;
      case Direction.left:  return Direction.right;
      case Direction.right: return Direction.left;
      case Direction.none:  return Direction.none;
    }
  }

  void _checkCollisions() {
    for (var g in _ghosts) {
      if (g.state == GhostState.eaten || g.houseTimer > 0) continue;

      final dist = (g.x - _playerX).abs() + (g.y - _playerY).abs();
      if (dist < 0.75) {
        if (g.state == GhostState.frightened) {
          // Eat Ghost!
          g.state = GhostState.eaten;
          _score += 200;
          if (_score > _highScore) _highScore = _score;
          AudioManager.instance.playPop();
          _spawnParticles(g.x + 0.5, g.y + 0.5, const Color(0xFFC084FC), 16);
        } else if (g.state == GhostState.normal) {
          // Pacman hit!
          _lives--;
          AudioManager.instance.playDamage();
          _spawnParticles(_playerX + 0.5, _playerY + 0.5, const Color(0xFFEF4444), 20);

          if (_lives <= 0) {
            _isGameOver = true;
          } else {
            // Respawn positions
            _playerX = 6.0;
            _playerY = 10.0;
            _currentDir = Direction.none;
            _nextDir = Direction.none;
          }
          break;
        }
      }
    }
  }

  void _checkVictory() {
    bool hasDots = false;
    for (var r = 0; r < _grid.length; r++) {
      for (var c = 0; c < _grid[r].length; c++) {
        if (_grid[r][c] == cellDot || _grid[r][c] == cellPower) {
          hasDots = true;
          break;
        }
      }
      if (hasDots) break;
    }

    if (!hasDots) {
      _isGameClear = true;
      _confettiController.play();
      AudioManager.instance.playSuccess();
      PlayerDataManager.instance.addStarCoin(2);
    }
  }

  void _spawnParticles(double x, double y, Color color, int count) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 4 + 1;
      _particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        size: _rng.nextDouble() * 6 + 4,
      ));
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.opacity -= dt * 1.5;
      if (p.opacity <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  // ── User Input Handlers ───────────────────────────────────────────────────
  void _changeDir(Direction dir) {
    AudioManager.instance.playClick();
    _nextDir = dir;
  }

  // ── UI Build Methods ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
            _changeDir(Direction.up);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
            _changeDir(Direction.down);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
            _changeDir(Direction.left);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
            _changeDir(Direction.right);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: theme.bg,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(theme),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.wallOuter, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: theme.wallOuter.withValues(alpha: 0.45),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Builder(
                          builder: (boardContext) {
                            return GestureDetector(
                              onTapDown: (details) {
                                final RenderBox? box = boardContext.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                final localPos = box.globalToLocal(details.globalPosition);
                                final cellW = box.size.width / 13;
                                final cellH = box.size.height / 15;

                                final tapGridX = localPos.dx / cellW;
                                final tapGridY = localPos.dy / cellH;

                                final dx = tapGridX - (_playerX + 0.5);
                                final dy = tapGridY - (_playerY + 0.5);

                                if (dx.abs() > dy.abs()) {
                                  if (dx > 0) {
                                    _changeDir(Direction.right);
                                  } else {
                                    _changeDir(Direction.left);
                                  }
                                } else {
                                  if (dy > 0) {
                                    _changeDir(Direction.down);
                                  } else {
                                    _changeDir(Direction.up);
                                  }
                                }
                              },
                              onPanUpdate: (details) {
                                if (details.delta.dx.abs() > details.delta.dy.abs()) {
                                  if (details.delta.dx > 3) {
                                    _changeDir(Direction.right);
                                  } else if (details.delta.dx < -3) {
                                    _changeDir(Direction.left);
                                  }
                                } else {
                                  if (details.delta.dy > 3) {
                                    _changeDir(Direction.down);
                                  } else if (details.delta.dy < -3) {
                                    _changeDir(Direction.up);
                                  }
                                }
                              },
                              child: CustomPaint(
                                size: Size.infinite,
                                painter: _PacmanBoardPainter(
                                  grid: _grid,
                                  playerX: _playerX,
                                  playerY: _playerY,
                                  playerDir: _currentDir,
                                  mouthAngle: _mouthAngle,
                                  playerSkin: widget.playerSkin,
                                  ghosts: _ghosts,
                                  particles: _particles,
                                  isPowerActive: _isPowerActive,
                                  theme: theme,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Confetti Overlay
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.yellow, Colors.orange, Colors.pink, Colors.cyan],
                ),
              ),

              // Pause Overlay
              if (_isPaused) _buildPauseModal(),

              // Game Clear Modal
              if (_isGameClear) _buildVictoryModal(),

              // Game Over Modal
              if (_isGameOver) _buildGameOverModal(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header Bar ───────────────────────────────────────────────────────────
  Widget _buildHeader(StageTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () {
                  AudioManager.instance.playClick();
                  Navigator.pop(context);
                },
              ),

              // Title
              Text(
                '👾 팩맨 미로 탐험 👾',
                style: GoogleFonts.jua(
                  fontSize: 22,
                  color: const Color(0xFFFDE047),
                ),
              ),

              // Pause
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() => _isPaused = !_isPaused);
                },
              ),
            ],
          ),

          // Scores & Lives Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.wallOuter.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score
                Text(
                  '점수: $_score',
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                ),
                // Stage Badge with Theme Name
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.wallOuter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(theme.fruitEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        'STAGE $_level - ${theme.name}',
                        style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Lives
                Row(
                  children: List.generate(
                    3,
                    (i) => Text(
                      i < _lives ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Power Pellet Active Bar
          if (_isPowerActive)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _powerTimeRemainingMs / 7000.0,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                  minHeight: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Modals ───────────────────────────────────────────────────────────────
  Widget _buildPauseModal() {
    return Container(
      color: const Color(0xB3000000),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏸️ 일시 정지', style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KidsTheme.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () => setState(() => _isPaused = false),
                child: Text('계속하기 ▶️', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFBBF24), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Badge
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(_currentTheme.fruitEmoji, style: const TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 12),
              Text(
                'STAGE $_level 클리어!',
                style: GoogleFonts.jua(fontSize: 28, color: const Color(0xFFFBBF24)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${_currentTheme.name} 미로 완파!',
                style: GoogleFonts.jua(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Reward Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '보상 별코인 +5개!',
                      style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Column(
                children: [
                  // Next Level Button (Primary)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _level++;
                          _initLevel(_level);
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('다음 단계', style: GoogleFonts.jua(fontSize: 20)),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Replay & Home Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              AudioManager.instance.playClick();
                              setState(() {
                                _initLevel(_level);
                              });
                            },
                            child: Text('다시하기 🔄', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              AudioManager.instance.playClick();
                              Navigator.pop(context);
                            },
                            child: Text('로비로 🏠', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B4B),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFEC4899), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.pink.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('👻', style: TextStyle(fontSize: 44)),
              ),
              const SizedBox(height: 12),
              Text(
                '아쉬워요!',
                style: GoogleFonts.jua(fontSize: 28, color: const Color(0xFFF472B6)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '최종 점수: $_score점',
                style: GoogleFonts.jua(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          AudioManager.instance.playClick();
                          Navigator.pop(context);
                        },
                        child: Text('로비로 🏠', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _initLevel(_level);
                          });
                        },
                        child: Text('다시 도전 🚀', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
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

// ── Authentic Stage-Themed Neon Board Painter ────────────────────────────────
class _PacmanBoardPainter extends CustomPainter {
  final List<List<int>> grid;
  final double playerX;
  final double playerY;
  final Direction playerDir;
  final double mouthAngle;
  final String playerSkin;
  final List<Ghost> ghosts;
  final List<Particle> particles;
  final bool isPowerActive;
  final StageTheme theme;

  _PacmanBoardPainter({
    required this.grid,
    required this.playerX,
    required this.playerY,
    required this.playerDir,
    required this.mouthAngle,
    required this.playerSkin,
    required this.ghosts,
    required this.particles,
    required this.isPowerActive,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    final cols = grid[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // 1. Black Canvas Background
    final bgPaint = Paint()..color = theme.bg;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Dynamic Stage-Themed Wall Painter
    final gatePaint = Paint()
      ..color = const Color(0xFFF472B6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final dotPaint = Paint()..color = const Color(0xFFFDE047);
    final powerDotPaint = Paint()..color = const Color(0xFFFFD700);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);

        if (grid[r][c] == cellWall) {
          final rRect = RRect.fromRectAndRadius(rect.deflate(2.0), const Radius.circular(10));
          
          // Clean, modern base fill
          canvas.drawRRect(rRect, Paint()..color = theme.wallFill);

          // Glowing simple rounded border
          canvas.drawRRect(
            rRect,
            Paint()
              ..color = theme.wallOuter
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5,
          );
        } else if (grid[r][c] == cellGhostHouse) {
          canvas.drawRect(rect, Paint()..color = const Color(0xFF1E1B4B).withValues(alpha: 0.5));
          if (r == 5 && c == 6) {
            canvas.drawLine(
              Offset(c * cellW, r * cellH),
              Offset((c + 1) * cellW, r * cellH),
              gatePaint,
            );
          }
        } else if (grid[r][c] == cellDot) {
          canvas.drawCircle(rect.center, min(cellW, cellH) * 0.14, dotPaint);
        } else if (grid[r][c] == cellPower) {
          final double pelletRadius = min(cellW, cellH) * 0.32;
          canvas.drawCircle(
            rect.center,
            pelletRadius + 2,
            Paint()
              ..color = const Color(0xFFFDE047).withValues(alpha: 0.35)
              ..style = PaintingStyle.fill,
          );
          canvas.drawCircle(rect.center, pelletRadius, powerDotPaint);
        } else if (grid[r][c] == cellFruit) {
          // Draw Stage Bonus Fruit
          final textPainter = TextPainter(
            text: TextSpan(text: theme.fruitEmoji, style: TextStyle(fontSize: min(cellW, cellH) * 0.9)),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2));
        }
      }
    }

    // 3. Draw Explosion / Eating Particles
    for (var p in particles) {
      final pPaint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * cellW, p.y * cellH), p.size, pPaint);
    }

    // 4. Draw Authentic Classic Pac-Man Character
    final px = (playerX + 0.5) * cellW;
    final py = (playerY + 0.5) * cellH;
    final radius = min(cellW, cellH) * 0.44;

    if (playerSkin == '🟡') {
      double startAngle = mouthAngle;
      switch (playerDir) {
        case Direction.right: startAngle += 0; break;
        case Direction.down:  startAngle += pi / 2; break;
        case Direction.left:  startAngle += pi; break;
        case Direction.up:    startAngle += 3 * pi / 2; break;
        case Direction.none:  break;
      }
      final sweepAngle = 2 * pi - (mouthAngle * 2);

      canvas.drawCircle(
        Offset(px, py),
        radius + 2,
        Paint()..color = const Color(0xFFFACC15).withValues(alpha: 0.3),
      );

      final pacPaint = Paint()..color = const Color(0xFFFACC15);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(px, py), radius: radius),
        startAngle,
        sweepAngle,
        true,
        pacPaint,
      );
    } else {
      final textPainter = TextPainter(
        text: TextSpan(text: playerSkin, style: TextStyle(fontSize: min(cellW, cellH) * 0.9)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(px - textPainter.width / 2, py - textPainter.height / 2));
    }

    // 5. Draw Authentic Vector Arcade Ghosts
    for (var g in ghosts) {
      if (g.houseTimer > 0) continue;
      final gx = (g.x + 0.5) * cellW;
      final gy = (g.y + 0.5) * cellH;

      if (g.state == GhostState.frightened) {
        _drawVectorGhost(canvas, gx, gy, cellW, cellH, const Color(0xFF1D4ED8), g.dir, isFrightened: true);
      } else if (g.state == GhostState.eaten) {
        _drawGhostEyes(canvas, gx, gy, cellW, cellH, g.dir);
      } else {
        _drawVectorGhost(canvas, gx, gy, cellW, cellH, g.color, g.dir);
      }
    }
  }

  // ── Authentic Vector Arcade Ghost Drawing ────────────────────────────────
  void _drawVectorGhost(
    Canvas canvas,
    double cx,
    double cy,
    double cellW,
    double cellH,
    Color ghostColor,
    Direction dir, {
    bool isFrightened = false,
  }) {
    final double w = cellW * 0.82;
    final double h = cellH * 0.85;
    final double left = cx - w / 2;
    final double top = cy - h / 2;

    final path = Path();
    path.moveTo(left, top + h * 0.5);
    path.arcTo(
      Rect.fromLTWH(left, top, w, h * 0.9),
      pi,
      pi,
      false,
    );
    path.lineTo(left + w, top + h);

    final double waveW = w / 3;
    path.quadraticBezierTo(left + w - waveW * 0.5, top + h - 5, left + w - waveW, top + h);
    path.quadraticBezierTo(left + waveW * 1.5, top + h - 5, left + waveW, top + h);
    path.quadraticBezierTo(left + waveW * 0.5, top + h - 5, left, top + h);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = ghostColor.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 3,
    );
    canvas.drawPath(path, Paint()..color = ghostColor);

    if (isFrightened) {
      final eyePaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(cx - w * 0.2, cy - h * 0.1), 3, eyePaint);
      canvas.drawCircle(Offset(cx + w * 0.2, cy - h * 0.1), 3, eyePaint);

      final mouthPath = Path();
      mouthPath.moveTo(cx - w * 0.3, cy + h * 0.15);
      mouthPath.lineTo(cx - w * 0.15, cy + h * 0.05);
      mouthPath.lineTo(cx, cy + h * 0.15);
      mouthPath.lineTo(cx + w * 0.15, cy + h * 0.05);
      mouthPath.lineTo(cx + w * 0.3, cy + h * 0.15);
      canvas.drawPath(mouthPath, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      _drawGhostEyes(canvas, cx, cy, cellW, cellH, dir);
    }
  }

  void _drawGhostEyes(Canvas canvas, double cx, double cy, double cellW, double cellH, Direction dir) {
    final double w = cellW * 0.82;
    final double h = cellH * 0.85;

    final double eyeR = w * 0.16;
    final double pupilR = eyeR * 0.55;

    final eyeLeft = Offset(cx - w * 0.22, cy - h * 0.12);
    final eyeRight = Offset(cx + w * 0.22, cy - h * 0.12);

    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = const Color(0xFF1E3A8A);

    canvas.drawCircle(eyeLeft, eyeR, whitePaint);
    canvas.drawCircle(eyeRight, eyeR, whitePaint);

    double dx = 0, dy = 0;
    switch (dir) {
      case Direction.left:  dx = -eyeR * 0.45; break;
      case Direction.right: dx = eyeR * 0.45; break;
      case Direction.up:    dy = -eyeR * 0.45; break;
      case Direction.down:  dy = eyeR * 0.45; break;
      case Direction.none:  break;
    }

    canvas.drawCircle(eyeLeft + Offset(dx, dy), pupilR, pupilPaint);
    canvas.drawCircle(eyeRight + Offset(dx, dy), pupilR, pupilPaint);
  }

  @override
  bool shouldRepaint(_PacmanBoardPainter old) => true;
}
