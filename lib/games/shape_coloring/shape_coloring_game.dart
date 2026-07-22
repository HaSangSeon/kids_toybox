import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

enum ShapeType {
  circle,
  square,
  triangle,
  star,
  heart,
  cloud,
  moon,
  flower,
  princess,
  bear,
  fish,
}

class Stroke {
  final List<Offset> points; // Relative points (0.0 to 1.0)
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class Confetti {
  double x, y;
  double vx, vy;
  Color color;
  double life = 1.0;
  final double size;

  Confetti({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

// Global helper to get Path for each shape (Centered and scaled down to 72% size)
Path getShapePath(ShapeType shape, Size size) {
  const double scale = 0.72; // Make shape smaller so kids can color it faster
  final double targetWidth = size.width * scale;
  final double targetHeight = size.height * scale;
  final double dx = (size.width - targetWidth) / 2;
  final double dy = (size.height - targetHeight) / 2;

  final path = Path();
  final subSize = Size(targetWidth, targetHeight);

  switch (shape) {
    case ShapeType.circle:
      path.addOval(Rect.fromLTWH(dx, dy, subSize.width, subSize.height));
      break;
    case ShapeType.square:
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(dx, dy, subSize.width, subSize.height),
        Radius.circular(subSize.width * 0.15),
      ));
      break;
    case ShapeType.triangle:
      path.moveTo(dx + subSize.width / 2, dy);
      path.lineTo(dx + subSize.width, dy + subSize.height);
      path.lineTo(dx, dy + subSize.height);
      path.close();
      break;
    case ShapeType.star:
      final double cx = dx + subSize.width / 2;
      final double cy = dy + subSize.height / 2;
      final double rx = subSize.width / 2;
      const int points = 5;
      final double angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final double r = (i % 2 == 0) ? rx : rx * 0.45;
        final double currX = cx + r * sin(i * angle);
        final double currY = cy - r * cos(i * angle);
        if (i == 0) path.moveTo(currX, currY);
        else path.lineTo(currX, currY);
      }
      path.close();
      break;
    case ShapeType.heart:
      final w = subSize.width;
      final h = subSize.height;
      path.moveTo(dx + w / 2, dy + h / 5);
      path.cubicTo(dx + w * 5 / 6, dy - h / 10, dx + w * 1.1, dy + h * 2 / 5, dx + w / 2, dy + h * 9 / 10);
      path.cubicTo(dx - w * 0.1, dy + h * 2 / 5, dx + w / 6, dy - h / 10, dx + w / 2, dy + h / 5);
      path.close();
      break;
    case ShapeType.cloud:
      final w = subSize.width;
      final h = subSize.height;
      path.moveTo(dx + w * 0.2, dy + h * 0.7);
      path.lineTo(dx + w * 0.8, dy + h * 0.7);
      path.cubicTo(dx + w * 0.95, dy + h * 0.7, dx + w * 0.95, dy + h * 0.45, dx + w * 0.8, dy + h * 0.45);
      path.cubicTo(dx + w * 0.85, dy + h * 0.2, dx + w * 0.6, dy + h * 0.2, dx + w * 0.55, dy + h * 0.3);
      path.cubicTo(dx + w * 0.45, dy + h * 0.15, dx + w * 0.25, dy + h * 0.2, dx + w * 0.25, dy + h * 0.4);
      path.cubicTo(dx + w * 0.05, dy + h * 0.4, dx + w * 0.05, dy + h * 0.7, dx + w * 0.2, dy + h * 0.7);
      path.close();
      break;
    case ShapeType.moon:
      final w = subSize.width;
      final h = subSize.height;
      path.moveTo(dx + w * 0.75, dy + h * 0.1);
      path.arcToPoint(
        Offset(dx + w * 0.75, dy + h * 0.9),
        radius: Radius.circular(w * 0.45),
        clockwise: true,
      );
      path.arcToPoint(
        Offset(dx + w * 0.75, dy + h * 0.1),
        radius: Radius.circular(w * 0.35),
        clockwise: false,
      );
      path.close();
      break;
    case ShapeType.flower:
      final double cx = dx + subSize.width / 2;
      final double cy = dy + subSize.height / 2;
      final double rx = subSize.width / 2;
      const int petals = 6;
      for (int i = 0; i <= 360; i += 2) {
        final angle = i * pi / 180;
        final double r = rx * (0.65 + 0.32 * cos(petals * angle).abs());
        final double currX = cx + r * cos(angle);
        final double currY = cy + r * sin(angle);
        if (i == 0) {
          path.moveTo(currX, currY);
        } else {
          path.lineTo(currX, currY);
        }
      }
      path.close();
      break;
    case ShapeType.princess:
      final w = subSize.width;
      final h = subSize.height;
      path.addOval(Rect.fromLTWH(dx + w * 0.2, dy + h * 0.35, w * 0.6, h * 0.6));
      path.moveTo(dx + w * 0.3, dy + h * 0.4);
      path.lineTo(dx + w * 0.18, dy + h * 0.15); 
      path.lineTo(dx + w * 0.38, dy + h * 0.28);
      path.lineTo(dx + w * 0.5, dy + h * 0.05); 
      path.lineTo(dx + w * 0.62, dy + h * 0.28);
      path.lineTo(dx + w * 0.82, dy + h * 0.15); 
      path.lineTo(dx + w * 0.7, dy + h * 0.4);
      path.close();
      break;
    case ShapeType.bear:
      final w = subSize.width;
      final h = subSize.height;
      path.addOval(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.25, w * 0.7, h * 0.7));
      path.addOval(Rect.fromLTWH(dx + w * 0.12, dy + h * 0.1, w * 0.26, h * 0.26));
      path.addOval(Rect.fromLTWH(dx + w * 0.62, dy + h * 0.1, w * 0.26, h * 0.26));
      break;
    case ShapeType.fish:
      final w = subSize.width;
      final h = subSize.height;
      path.moveTo(dx + w * 0.08, dy + h * 0.5);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.12, dx + w * 0.78, dy + h * 0.5);
      path.lineTo(dx + w * 0.94, dy + h * 0.28);
      path.lineTo(dx + w * 0.88, dy + h * 0.5);
      path.lineTo(dx + w * 0.94, dy + h * 0.72);
      path.lineTo(dx + w * 0.78, dy + h * 0.5);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.88, dx + w * 0.08, dy + h * 0.5);
      path.moveTo(dx + w * 0.4, dy + h * 0.32);
      path.quadraticBezierTo(dx + w * 0.5, dy + h * 0.2, dx + w * 0.6, dy + h * 0.35);
      path.close();
      break;
  }
  return path;
}

class DrawingEngine extends ChangeNotifier {
  final Map<ShapeType, List<Stroke>> shapeStrokes = {};
  final Map<ShapeType, Set<int>> shapeColoredGrid = {};
  final Map<ShapeType, Set<int>> _shapeTargetMask = {};
  final Map<ShapeType, bool> shapeCompleted = {};
  
  final List<Confetti> confettiParticles = [];
  final List<Confetti> canvasSparkles = []; // NEW: Sparkles drawn inside canvas
  
  final Random random = Random();

  double characterTime = 0.0;
  VoidCallback? onShapeCompleted;
  static const int gridSize = 45;
  int selectedBackgroundIndex = 0;

  DrawingEngine() {
    for (var shape in ShapeType.values) {
      shapeStrokes[shape] = [];
      shapeColoredGrid[shape] = {};
      shapeCompleted[shape] = false;
      _shapeTargetMask[shape] = _calculateTargetMask(shape);
    }
    _loadState();
  }

  Set<int> _calculateTargetMask(ShapeType shape) {
    final mask = <int>{};
    final path = getShapePath(shape, const Size(100, 100));
    final cellSize = 100 / gridSize;

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        final cx = x * cellSize + cellSize / 2;
        final cy = y * cellSize + cellSize / 2;
        if (path.contains(Offset(cx, cy))) {
          mask.add(y * gridSize + x);
        }
      }
    }
    return mask;
  }

  void startStroke(ShapeType shape, Offset relativePoint, Color color, double canvasSize, double strokeWidth) {
    if (shapeCompleted[shape]!) return;

    shapeStrokes[shape]!.add(Stroke(
      points: [relativePoint],
      color: color,
      strokeWidth: strokeWidth,
    ));
    _updateGrid(shape, relativePoint, color, canvasSize, strokeWidth);
    _spawnSparkles(relativePoint, color);
    notifyListeners();
  }

  void addPointToLastStroke(ShapeType shape, Offset relativePoint, double canvasSize) {
    if (shapeCompleted[shape]!) return;

    final strokes = shapeStrokes[shape]!;
    if (strokes.isNotEmpty) {
      strokes.last.points.add(relativePoint);
      _updateGrid(shape, relativePoint, strokes.last.color, canvasSize, strokes.last.strokeWidth);
      _spawnSparkles(relativePoint, strokes.last.color);
      notifyListeners();
    }
  }

  void _spawnSparkles(Offset rel, Color color) {
    if (color == Colors.white) return;
    if (random.nextDouble() > 0.4) return; // Randomly spawn
    canvasSparkles.add(Confetti(
      x: rel.dx,
      y: rel.dy,
      vx: (random.nextDouble() - 0.5) * 0.02,
      vy: (random.nextDouble() - 0.5) * 0.02,
      color: Colors.white, // Sparkles are white/glowy
      size: 3 + random.nextDouble() * 5,
    ));
  }

  void _updateGrid(ShapeType shape, Offset relPoint, Color color, double canvasSize, double strokeWidth) {
    final isEraser = color == Colors.white;
    final double gcx = relPoint.dx * gridSize;
    final double gcy = relPoint.dy * gridSize;
    final double relativeStrokeWidth = strokeWidth / canvasSize;
    final double gridRadius = (relativeStrokeWidth / 2) * gridSize;

    final int minX = (gcx - gridRadius).floor().clamp(0, gridSize - 1);
    final int maxX = (gcx + gridRadius).ceil().clamp(0, gridSize - 1);
    final int minY = (gcy - gridRadius).floor().clamp(0, gridSize - 1);
    final int maxY = (gcy + gridRadius).ceil().clamp(0, gridSize - 1);

    bool changed = false;
    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final double dx = (x + 0.5) - gcx;
        final double dy = (y + 0.5) - gcy;
        if (dx * dx + dy * dy <= gridRadius * gridRadius) {
          final index = y * gridSize + x;
          if (isEraser) {
            if (shapeColoredGrid[shape]!.remove(index)) changed = true;
          } else {
            if (_shapeTargetMask[shape]!.contains(index)) {
              if (shapeColoredGrid[shape]!.add(index)) changed = true;
            }
          }
        }
      }
    }

    if (changed && !isEraser && !shapeCompleted[shape]!) {
      _checkCompletion(shape);
    }
  }

  void _checkCompletion(ShapeType shape) {
    final targetMask = _shapeTargetMask[shape]!;
    final colored = shapeColoredGrid[shape]!;
    
    if (colored.length >= targetMask.length * 0.97) {
      shapeCompleted[shape] = true;
      _triggerConfetti();
      _saveState();
      onShapeCompleted?.call();
    }
  }

  void _triggerConfetti() {
    for (int i = 0; i < 60; i++) {
      confettiParticles.add(Confetti(
        x: 0.5, y: 0.5,
        vx: (random.nextDouble() - 0.5) * 0.04,
        vy: (random.nextDouble() - 0.5) * 0.04 - 0.02,
        color: KidsTheme.getRandomColor(),
        size: random.nextDouble() * 8 + 6,
      ));
    }
  }

  void update(double dt) {
    bool hasActiveAnimation = confettiParticles.isNotEmpty || canvasSparkles.isNotEmpty || shapeCompleted.values.any((c) => c);

    if (hasActiveAnimation) {
      characterTime += dt;

      for (var p in confettiParticles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.0015;
        p.life -= 0.015;
      }
      confettiParticles.removeWhere((p) => p.life <= 0);

      for (var p in canvasSparkles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.05; // Fade out quickly
      }
      canvasSparkles.removeWhere((p) => p.life <= 0);

      notifyListeners();
    }
  }

  void clearAll() {
    for (var shape in ShapeType.values) {
      shapeStrokes[shape]?.clear();
      shapeColoredGrid[shape]?.clear();
      shapeCompleted[shape] = false;
    }
    saveState();
    notifyListeners();
  }

  void clear(ShapeType shape) {
    shapeStrokes[shape]!.clear();
    shapeColoredGrid[shape]!.clear();
    shapeCompleted[shape] = false;
    confettiParticles.clear();
    canvasSparkles.clear();
    _saveState();
    notifyListeners();
  }

  bool isShapeColored(ShapeType shape) {
    return shapeStrokes[shape]!.any((stroke) => stroke.color != Colors.white);
  }

  void selectBackground(int index) {
    selectedBackgroundIndex = index;
    _saveState();
    notifyListeners();
  }

  void saveState() {
    _saveState();
  }

  void _saveState() {
    try {
      final box = Hive.box('high_scores_box');
      final Map<String, dynamic> strokesMap = {};
      shapeStrokes.forEach((key, strokesList) {
        strokesMap[key.name] = strokesList.map((s) => {
          'points': s.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
          'color': s.color.value,
          'strokeWidth': s.strokeWidth,
        }).toList();
      });

      final Map<String, dynamic> gridMap = {};
      shapeColoredGrid.forEach((key, gridSet) {
        gridMap[key.name] = gridSet.toList();
      });

      final Map<String, dynamic> completedMap = {};
      shapeCompleted.forEach((key, isDone) {
        completedMap[key.name] = isDone;
      });

      box.put('shape_strokes', strokesMap);
      box.put('shape_grid', gridMap);
      box.put('shape_completed', completedMap);
      box.put('selected_background', selectedBackgroundIndex);
    } catch (e) {
      debugPrint('Error saving drawing state: $e');
    }
  }

  void _loadState() {
    try {
      final box = Hive.box('high_scores_box');

      final rawCompleted = box.get('shape_completed');
      if (rawCompleted is Map) {
        rawCompleted.forEach((key, value) {
          final shape = ShapeType.values.firstWhere((e) => e.name == key, orElse: () => ShapeType.circle);
          shapeCompleted[shape] = value as bool;
        });
      }

      final rawStrokes = box.get('shape_strokes');
      if (rawStrokes is Map) {
        rawStrokes.forEach((key, value) {
          final shape = ShapeType.values.firstWhere((e) => e.name == key, orElse: () => ShapeType.circle);
          final List<dynamic> list = value as List<dynamic>;
          shapeStrokes[shape] = list.map((item) {
            final m = item as Map;
            final List<dynamic> rawPoints = m['points'] as List<dynamic>;
            final points = rawPoints.map((p) {
              final pm = p as Map;
              return Offset((pm['x'] as num).toDouble(), (pm['y'] as num).toDouble());
            }).toList();
            return Stroke(
              points: points,
              color: Color(m['color'] as int),
              strokeWidth: (m['strokeWidth'] as num).toDouble(),
            );
          }).toList();
        });
      }

      final rawGrid = box.get('shape_grid');
      if (rawGrid is Map) {
        rawGrid.forEach((key, value) {
          final shape = ShapeType.values.firstWhere((e) => e.name == key, orElse: () => ShapeType.circle);
          final List<dynamic> list = value as List<dynamic>;
          shapeColoredGrid[shape] = list.map((i) => i as int).toSet();
        });
      }

      final rawBg = box.get('selected_background');
      if (rawBg is int) {
        selectedBackgroundIndex = rawBg;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading drawing state: $e');
    }
  }
}

class ShapeColoringGame extends StatefulWidget {
  const ShapeColoringGame({super.key});

  @override
  State<ShapeColoringGame> createState() => _ShapeColoringGameState();
}

class _ShapeColoringGameState extends State<ShapeColoringGame> with TickerProviderStateMixin {
  ShapeType _selectedShape = ShapeType.star;
  Color _selectedColor = KidsTheme.yellow;
  double _selectedWidth = 18.0; 
  late DrawingEngine _engine;
  late Ticker _ticker;

  final List<Color> _paletteColors = [
    KidsTheme.red,
    KidsTheme.orange,
    KidsTheme.yellow,
    KidsTheme.green,
    KidsTheme.blue,
    KidsTheme.purple,
    KidsTheme.pink,
    Colors.white, // Eraser
  ];

  final List<double> _brushSizes = [8.0, 18.0, 32.0];

  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  bool _showSuccessText = false;

  @override
  void initState() {
    super.initState();
    _engine = DrawingEngine();
    _engine.onShapeCompleted = _onShapeCompleted;

    _ticker = createTicker((elapsed) {
      _engine.update(0.016);
    })..start();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 70),
    ]).animate(_bounceController);
    
    _bounceController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showSuccessText = false);
      }
    });
  }

  void _onShapeCompleted() {
    AudioManager.instance.playPop();
    HapticFeedback.heavyImpact();
    setState(() => _showSuccessText = true);
    _bounceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bounceController.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _resetAllColoring() {
    AudioManager.instance.playPop();
    _engine.clearAll();
  }

  void _resetColoring() {
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
    _engine.clear(_selectedShape);
  }

  String _getShapeNameKo(ShapeType type) {
    switch (type) {
      case ShapeType.circle: return '동그라미';
      case ShapeType.square: return '네모';
      case ShapeType.triangle: return '세모';
      case ShapeType.star: return '별';
      case ShapeType.heart: return '하트';
      case ShapeType.moon: return '달';
      case ShapeType.cloud: return '구름';
      case ShapeType.bear: return '곰돌이';
      case ShapeType.flower: return '꽃';
      case ShapeType.princess: return '공주님';
      case ShapeType.fish: return '물고기';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // 프리미엄 패턴을 연상시키는 파스텔톤 부드러운 그라데이션
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFFFFF3E0), Color(0xFFFCE4EC), Color(0xFFE8EAF6)],
          ),
        ),
        child: Stack(
          children: [
            // 배경 은은한 격자 무늬 추가
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: GridPaper(
                  color: Colors.black,
                  divisions: 2,
                  subdivisions: 2,
                  interval: 60,
                ),
              ),
            ),
            
            // 메인 UI 영역
            Column(
              children: [
                // 투명한 플로팅 헤더 (Glassmorphism)
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 28),
                                ),
                              ),
                              
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '모양 색칠하기 🎨',
                                    style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 48), // Balance left back button for perfect centering
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Shape Selector (Floating Style)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListenableBuilder(
                      listenable: _engine,
                      builder: (context, child) {
                        return Row(
                          children: ShapeType.values.map((shape) {
                            final isSelected = _selectedShape == shape;
                            final isColored = _engine.isShapeColored(shape);
                            final isCompleted = _engine.shapeCompleted[shape] ?? false;

                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedShape = shape);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? KidsTheme.orange : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: isSelected ? KidsTheme.orange : Colors.white, width: 3),
                                    boxShadow: isSelected ? [const BoxShadow(color: KidsTheme.orange, blurRadius: 10, offset: Offset(0, 4))] : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      CustomPaint(
                                        size: const Size(24, 24),
                                        painter: _ShapeItemPainter(
                                          shape: shape,
                                          isColored: isColored,
                                          coloredColor: isColored ? KidsTheme.pink : Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isCompleted ? '${_getShapeNameKo(shape)} ✨' : _getShapeNameKo(shape),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: isSelected ? Colors.white : KidsTheme.textDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }
                    ),
                  ),
                ),

                // Canvas 영역
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white, width: 8),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 10))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final canvasWidth = constraints.maxWidth;
                                    final canvasHeight = constraints.maxHeight;

                                    return GestureDetector(
                                      onPanStart: (details) {
                                        AudioManager.instance.playTraceDraw(rate: 1.2);
                                        HapticFeedback.lightImpact();
                                        final relX = details.localPosition.dx / canvasWidth;
                                        final relY = details.localPosition.dy / canvasHeight;
                                        _engine.startStroke(_selectedShape, Offset(relX, relY), _selectedColor, canvasWidth, _selectedWidth);
                                      },
                                      onPanUpdate: (details) {
                                        final relX = details.localPosition.dx / canvasWidth;
                                        final relY = details.localPosition.dy / canvasHeight;
                                        _engine.addPointToLastStroke(_selectedShape, Offset(relX, relY), canvasWidth);
                                      },
                                      onPanEnd: (details) => _engine.saveState(),
                                      onPanCancel: () => _engine.saveState(),
                                      child: ScaleTransition(
                                        scale: _bounceAnimation,
                                        child: CustomPaint(
                                          size: Size(canvasWidth, canvasHeight),
                                          painter: _MainShapePainter(
                                            shape: _selectedShape,
                                            engine: _engine,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // 캔버스 내부 파티클 (Sparkles)
                                ListenableBuilder(
                                  listenable: _engine,
                                  builder: (context, child) {
                                    return IgnorePointer(
                                      child: CustomPaint(
                                        painter: _CanvasSparklePainter(_engine.canvasSparkles),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 둥둥 떠있는 형태의 Bottom Palette
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            // Width Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '두께:',
                                  style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark),
                                ),
                                const SizedBox(width: 8),
                                ..._brushSizes.map((size) {
                                  final isSelected = _selectedWidth == size;
                                  double dotSize = size == 8.0 ? 6.0 : (size == 18.0 ? 12.0 : 18.0);
                                  String sizeLabel = size == 8.0 ? '얇게' : (size == 18.0 ? '보통' : '두껍게');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedWidth = size);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? KidsTheme.orange : Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isSelected ? [const BoxShadow(color: KidsTheme.orange, blurRadius: 6)] : [],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20, height: 20,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade200,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Container(
                                                width: dotSize, height: dotSize,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? Colors.white : KidsTheme.textDark,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              sizeLabel,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: isSelected ? Colors.white : KidsTheme.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Colors (Cute rounded squares)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: _paletteColors.map((color) {
                                final isSelected = _selectedColor == color;
                                final isEraser = color == Colors.white;

                                return GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playColorSelect();
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedColor = color);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    width: isSelected ? 52 : 44,
                                    height: isSelected ? 52 : 44,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: KidsTheme.borderDark, width: 3),
                                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))] : [],
                                    ),
                                    child: Center(
                                      child: isEraser ? const Icon(Icons.cleaning_services, size: 20, color: KidsTheme.textDark) : null,
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
                ),
              ],
            ),
            
            // "참 잘했어요!" 성공 팝업 애니메이션
            if (_showSuccessText)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.4,
                left: 0,
                right: 0,
                child: Center(
                  child: IgnorePointer(
                    child: ScaleTransition(
                      scale: _bounceAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: KidsTheme.red,
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Text(
                          '참 잘했어요! 💖',
                          style: GoogleFonts.jua(fontSize: 40, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 폭죽 이펙트 (스크린 전체)
            Positioned.fill(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _engine,
                  builder: (context, child) {
                    if (_engine.confettiParticles.isEmpty) return const SizedBox.shrink();
                    return CustomPaint(
                      painter: _ConfettiPainter(_engine.confettiParticles),
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasSparklePainter extends CustomPainter {
  final List<Confetti> sparkles;
  _CanvasSparklePainter(this.sparkles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in sparkles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Glow effect
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class _ConfettiPainter extends CustomPainter {
  final List<Confetti> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class _ShapeItemPainter extends CustomPainter {
  final ShapeType shape;
  final bool isColored;
  final Color coloredColor;

  _ShapeItemPainter({required this.shape, required this.isColored, required this.coloredColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [coloredColor.withValues(alpha: 0.5), coloredColor],
        center: const Alignment(-0.3, -0.3),
        radius: 0.8,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = KidsTheme.borderDark..style = PaintingStyle.stroke..strokeWidth = 2;
    
    final path = getShapePath(shape, size);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _ShapeItemPainter oldDelegate) => true;
}

class _MainShapePainter extends CustomPainter {
  final ShapeType shape;
  final DrawingEngine engine;

  _MainShapePainter({required this.shape, required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shapePath = getShapePath(shape, size);
    final isCompleted = engine.shapeCompleted[shape] ?? false;

    const double scale = 0.72;
    final double w = size.width * scale;
    final double h = size.height * scale;
    final double dx = (size.width - w) / 2;
    final double dy = (size.height - h) / 2;

    Offset faceCenter = Offset(dx + w / 2, dy + h / 2);
    if (shape == ShapeType.triangle) {
      faceCenter = Offset(dx + w / 2, dy + h * 0.58);
    } else if (shape == ShapeType.star) {
      faceCenter = Offset(dx + w / 2, dy + h * 0.52);
    } else if (shape == ShapeType.moon) {
      faceCenter = Offset(dx + w * 0.42, dy + h * 0.5);
    }

    if (isCompleted) {
      final limbPaint = Paint()
        ..color = KidsTheme.borderDark
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final double time = engine.characterTime;
      final double swing = sin(time * 7.0);
      final double ly = faceCenter.dy;

      final leftArmPath = Path()
        ..moveTo(dx + w * 0.22, ly)
        ..quadraticBezierTo(
          dx + w * 0.1, ly - 5 + swing * 10, 
          dx + w * 0.05, ly - 12 + swing * 22
        );
      canvas.drawPath(leftArmPath, limbPaint);
      
      final rightArmPath = Path()
        ..moveTo(dx + w * 0.78, ly)
        ..quadraticBezierTo(
          dx + w * 0.9, ly - 5 - swing * 10, 
          dx + w * 0.95, ly - 12 - swing * 22
        );
      canvas.drawPath(rightArmPath, limbPaint);

      final leftLegPath = Path()
        ..moveTo(dx + w * 0.38, dy + h * 0.82)
        ..quadraticBezierTo(
          dx + w * 0.35, dy + h * 0.90,
          dx + w * (0.32 + swing * 0.04), dy + h * 0.97
        );
      canvas.drawPath(leftLegPath, limbPaint);

      final rightLegPath = Path()
        ..moveTo(dx + w * 0.62, dy + h * 0.82)
        ..quadraticBezierTo(
          dx + w * 0.65, dy + h * 0.90,
          dx + w * (0.68 - swing * 0.04), dy + h * 0.97
        );
      canvas.drawPath(rightLegPath, limbPaint);
    }

    canvas.save();
    canvas.clipPath(shapePath);
    
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
        stops: const [0.0, 0.8, 1.0],
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);
    
    final dotPaint = Paint()..color = Colors.grey.withValues(alpha: 0.15)..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 20) {
      for (double x = 0; x < size.width; x += 20) {
        final offsetX = (y / 20) % 2 == 0 ? x : x + 10;
        canvas.drawCircle(Offset(offsetX, y), 3, dotPaint);
      }
    }
    canvas.restore();

    canvas.saveLayer(rect, Paint());
    canvas.clipPath(shapePath);
    final strokes = engine.shapeStrokes[shape] ?? [];
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final isEraser = stroke.color == Colors.white;
      final strokePaint = Paint()
        ..color = isEraser ? Colors.transparent : stroke.color
        ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(stroke.points.first.dx * size.width, stroke.points.first.dy * size.height);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx * size.width, stroke.points[i].dy * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }
    canvas.restore();

    if (isCompleted) {
      final double time = engine.characterTime;
      final Offset leftEye = Offset(faceCenter.dx - 18, faceCenter.dy - 10);
      final Offset rightEye = Offset(faceCenter.dx + 18, faceCenter.dy - 10);
      final Offset leftBlush = Offset(faceCenter.dx - 26, faceCenter.dy + 2);
      final Offset rightBlush = Offset(faceCenter.dx + 26, faceCenter.dy + 2);

      final blushPaint = Paint()..color = KidsTheme.pink.withValues(alpha: 0.5)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: leftBlush, width: 14, height: 8), blushPaint);
      canvas.drawOval(Rect.fromCenter(center: rightBlush, width: 14, height: 8), blushPaint);

      final bool isBlinking = (time % 3.5) < 0.16;
      if (isBlinking) {
        final blinkPaint = Paint()
          ..color = KidsTheme.borderDark
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(Path()..moveTo(leftEye.dx - 6, leftEye.dy)..quadraticBezierTo(leftEye.dx, leftEye.dy + 3, leftEye.dx + 6, leftEye.dy), blinkPaint);
        canvas.drawPath(Path()..moveTo(rightEye.dx - 6, rightEye.dy)..quadraticBezierTo(rightEye.dx, rightEye.dy + 3, rightEye.dx + 6, rightEye.dy), blinkPaint);
      } else {
        final eyePaint = Paint()..color = KidsTheme.borderDark..style = PaintingStyle.fill;
        final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
        canvas.drawCircle(leftEye, 5.5, eyePaint);
        canvas.drawCircle(rightEye, 5.5, eyePaint);
        canvas.drawCircle(Offset(leftEye.dx - 1.8, leftEye.dy - 1.8), 1.8, whitePaint);
        canvas.drawCircle(Offset(rightEye.dx - 1.8, rightEye.dy - 1.8), 1.8, whitePaint);
      }

      final mouthOutlinePaint = Paint()
        ..color = KidsTheme.borderDark
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final mouthPath = Path()
        ..moveTo(faceCenter.dx - 8, faceCenter.dy + 3)
        ..quadraticBezierTo(faceCenter.dx, faceCenter.dy + 12, faceCenter.dx + 8, faceCenter.dy + 3)
        ..close();

      canvas.drawPath(mouthPath, Paint()..color = KidsTheme.red..style = PaintingStyle.fill);
      canvas.drawPath(mouthPath, mouthOutlinePaint);
    }

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.fill;
    if (shape == ShapeType.circle) {
      canvas.drawOval(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.15, w * 0.25, h * 0.15), highlightPaint);
    } else if (shape == ShapeType.square) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.15, w * 0.3, h * 0.15), const Radius.circular(12)), highlightPaint);
    } else if (shape == ShapeType.triangle) {
      canvas.drawPath(Path()..moveTo(dx + w / 2, dy + h * 0.15)..lineTo(dx + w * 0.68, dy + h * 0.32)..lineTo(dx + w * 0.32, dy + h * 0.32)..close(), highlightPaint);
    } else if (shape == ShapeType.star) {
      canvas.drawPath(Path()..moveTo(dx + w / 2, dy + h * 0.18)..lineTo(dx + w * 0.58, dy + h * 0.35)..lineTo(dx + w * 0.42, dy + h * 0.35)..close(), highlightPaint);
    } else if (shape == ShapeType.heart) {
      canvas.drawPath(Path()..moveTo(dx + w * 0.35, dy + h * 0.22)..cubicTo(dx + w * 0.4, dy + h * 0.15, dx + w * 0.48, dy + h * 0.2, dx + w * 0.35, dy + h * 0.35)..close(), highlightPaint);
    } else if (shape == ShapeType.cloud) {
      canvas.drawOval(Rect.fromLTWH(dx + w * 0.25, dy + h * 0.25, w * 0.25, h * 0.12), highlightPaint);
    } else if (shape == ShapeType.moon) {
      canvas.drawOval(Rect.fromLTWH(dx + w * 0.35, dy + h * 0.25, w * 0.15, h * 0.12), highlightPaint);
    } else if (shape == ShapeType.flower) {
      canvas.drawCircle(Offset(faceCenter.dx - 8, faceCenter.dy - 8), w * 0.08, highlightPaint);
    }

    final strokePaint = Paint()
      ..color = isCompleted ? KidsTheme.orange : KidsTheme.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompleted ? 8 : 6;
    canvas.drawPath(shapePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MainShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.engine != engine;
  }
}
