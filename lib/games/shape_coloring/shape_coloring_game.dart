import 'dart:math';
import 'dart:ui';
import 'package:confetti/confetti.dart' as confetti_pkg;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

enum ShapeType {
  bear,
  cat,
  bunny,
  dog,
  elephant,
  lion,
  giraffe,
  dolphin,
  fish,
  whale,
  unicorn,
  princess,
  rocket,
  flower,
  star,
  car,
  heart,
  icecream,
  cake,
  apple,
}

class Stroke {
  final List<Offset> points; // Relative points (0.0 to 1.0)
  final Color color;
  final double strokeWidth;
  final bool isRainbow;
  final String? stampEmoji;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isRainbow = false,
    this.stampEmoji,
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

Path _unionPaths(List<Path> paths) {
  if (paths.isEmpty) return Path();
  Path result = paths.first;
  for (int i = 1; i < paths.length; i++) {
    result = Path.combine(PathOperation.union, result, paths[i]);
  }
  return result;
}

// Global helper to get unified outer silhouette Path for each shape
Path getShapePath(ShapeType shape, Size size) {
  const double scale = 0.86;
  final double targetWidth = size.width * scale;
  final double targetHeight = size.height * scale;
  final double dx = (size.width - targetWidth) / 2;
  final double dy = (size.height - targetHeight) / 2;

  final path = Path();
  final w = targetWidth;
  final h = targetHeight;

  switch (shape) {
    case ShapeType.bear:
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.14, dy + h * 0.22, w * 0.72, h * 0.68)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.08, dy + h * 0.10, w * 0.28, h * 0.28)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.64, dy + h * 0.10, w * 0.28, h * 0.28)),
      ]);

    case ShapeType.cat:
      path.moveTo(dx + w * 0.22, dy + h * 0.35);
      path.lineTo(dx + w * 0.12, dy + h * 0.08);
      path.lineTo(dx + w * 0.38, dy + h * 0.25);
      path.lineTo(dx + w * 0.62, dy + h * 0.25);
      path.lineTo(dx + w * 0.88, dy + h * 0.08);
      path.lineTo(dx + w * 0.78, dy + h * 0.35);
      path.cubicTo(
        dx + w * 0.98,
        dy + h * 0.65,
        dx + w * 0.85,
        dy + h * 0.95,
        dx + w * 0.5,
        dy + h * 0.95,
      );
      path.cubicTo(
        dx + w * 0.15,
        dy + h * 0.95,
        dx + w * 0.02,
        dy + h * 0.65,
        dx + w * 0.22,
        dy + h * 0.35,
      );
      path.close();
      return path;

    case ShapeType.bunny:
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.18, dy + h * 0.38, w * 0.64, h * 0.56)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.22, dy + h * 0.03, w * 0.22, h * 0.46)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.56, dy + h * 0.03, w * 0.22, h * 0.46)),
      ]);

    case ShapeType.dog:
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.20, dy + h * 0.20, w * 0.60, h * 0.68)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.04, dy + h * 0.22, w * 0.26, h * 0.52)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.70, dy + h * 0.22, w * 0.26, h * 0.52)),
      ]);

    case ShapeType.elephant:
      final trunk = Path()
        ..moveTo(dx + w * 0.42, dy + h * 0.55)
        ..cubicTo(
          dx + w * 0.40,
          dy + h * 0.95,
          dx + w * 0.72,
          dy + h * 0.92,
          dx + w * 0.68,
          dy + h * 0.75,
        )
        ..cubicTo(
          dx + w * 0.60,
          dy + h * 0.80,
          dx + w * 0.52,
          dy + h * 0.75,
          dx + w * 0.54,
          dy + h * 0.55,
        )
        ..close();
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.24, dy + h * 0.20, w * 0.52, h * 0.55)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.02, dy + h * 0.16, w * 0.34, h * 0.50)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.64, dy + h * 0.16, w * 0.34, h * 0.50)),
        trunk,
      ]);

    case ShapeType.lion:
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int manePoints = 14;
      for (int i = 0; i <= manePoints; i++) {
        final angle = i * 2 * pi / manePoints;
        final r = (i % 2 == 0) ? rx : rx * 0.76;
        final currX = cx + r * cos(angle);
        final currY = cy + r * sin(angle);
        if (i == 0) {
          path.moveTo(currX, currY);
        } else {
          path.lineTo(currX, currY);
        }
      }
      path.close();
      return path;

    case ShapeType.giraffe:
      return _unionPaths([
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx + w * 0.35, dy + h * 0.38, w * 0.30, h * 0.56),
              Radius.circular(w * 0.12),
            ),
          ),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.24, dy + h * 0.16, w * 0.52, h * 0.34)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.30, dy + h * 0.03, w * 0.12, h * 0.20)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.58, dy + h * 0.03, w * 0.12, h * 0.20)),
      ]);

    case ShapeType.dolphin:
      final body = Path()
        ..moveTo(dx + w * 0.05, dy + h * 0.52)
        ..cubicTo(
          dx + w * 0.20,
          dy + h * 0.12,
          dx + w * 0.75,
          dy + h * 0.15,
          dx + w * 0.90,
          dy + h * 0.48,
        )
        ..lineTo(dx + w * 1.00, dy + h * 0.32)
        ..lineTo(dx + w * 0.93, dy + h * 0.52)
        ..lineTo(dx + w * 1.00, dy + h * 0.70)
        ..cubicTo(
          dx + w * 0.65,
          dy + h * 0.90,
          dx + w * 0.25,
          dy + h * 0.85,
          dx + w * 0.05,
          dy + h * 0.52,
        )
        ..close();
      final fin = Path()
        ..moveTo(dx + w * 0.44, dy + h * 0.26)
        ..quadraticBezierTo(dx + w * 0.55, dy + h * 0.03, dx + w * 0.68, dy + h * 0.28)
        ..close();
      return _unionPaths([body, fin]);

    case ShapeType.fish:
      path.moveTo(dx + w * 0.05, dy + h * 0.50);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.08, dx + w * 0.78, dy + h * 0.50);
      path.lineTo(dx + w * 0.98, dy + h * 0.22);
      path.lineTo(dx + w * 0.88, dy + h * 0.50);
      path.lineTo(dx + w * 0.98, dy + h * 0.78);
      path.lineTo(dx + w * 0.78, dy + h * 0.50);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.92, dx + w * 0.05, dy + h * 0.50);
      path.close();
      return path;

    case ShapeType.whale:
      path.moveTo(dx + w * 0.08, dy + h * 0.58);
      path.quadraticBezierTo(dx + w * 0.15, dy + h * 0.20, dx + w * 0.68, dy + h * 0.25);
      path.quadraticBezierTo(dx + w * 0.88, dy + h * 0.28, dx + w * 0.95, dy + h * 0.50);
      path.lineTo(dx + w * 1.04, dy + h * 0.35);
      path.lineTo(dx + w * 0.96, dy + h * 0.62);
      path.quadraticBezierTo(dx + w * 0.50, dy + h * 0.95, dx + w * 0.08, dy + h * 0.58);
      path.close();
      return path;

    case ShapeType.unicorn:
      final horn = Path()
        ..moveTo(dx + w * 0.50, dy + h * 0.03)
        ..lineTo(dx + w * 0.36, dy + h * 0.36)
        ..lineTo(dx + w * 0.64, dy + h * 0.36)
        ..close();
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.20, dy + h * 0.30, w * 0.60, h * 0.62)),
        horn,
      ]);

    case ShapeType.princess:
      path.moveTo(dx + w * 0.10, dy + h * 0.85);
      path.lineTo(dx + w * 0.04, dy + h * 0.25);
      path.lineTo(dx + w * 0.32, dy + h * 0.52);
      path.lineTo(dx + w * 0.50, dy + h * 0.10);
      path.lineTo(dx + w * 0.68, dy + h * 0.52);
      path.lineTo(dx + w * 0.96, dy + h * 0.25);
      path.lineTo(dx + w * 0.90, dy + h * 0.85);
      path.close();
      return path;

    case ShapeType.rocket:
      path.moveTo(dx + w * 0.50, dy + h * 0.04);
      path.quadraticBezierTo(dx + w * 0.82, dy + h * 0.30, dx + w * 0.72, dy + h * 0.76);
      path.lineTo(dx + w * 0.92, dy + h * 0.92);
      path.lineTo(dx + w * 0.68, dy + h * 0.86);
      path.lineTo(dx + w * 0.50, dy + h * 0.80);
      path.lineTo(dx + w * 0.32, dy + h * 0.86);
      path.lineTo(dx + w * 0.08, dy + h * 0.92);
      path.lineTo(dx + w * 0.28, dy + h * 0.76);
      path.quadraticBezierTo(dx + w * 0.18, dy + h * 0.30, dx + w * 0.50, dy + h * 0.04);
      path.close();
      return path;

    case ShapeType.flower:
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int petals = 6;
      for (int i = 0; i <= 360; i += 2) {
        final angle = i * pi / 180;
        final r = rx * (0.65 + 0.32 * cos(petals * angle).abs());
        final currX = cx + r * cos(angle);
        final currY = cy + r * sin(angle);
        if (i == 0) {
          path.moveTo(currX, currY);
        } else {
          path.lineTo(currX, currY);
        }
      }
      path.close();
      return path;

    case ShapeType.star:
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int points = 5;
      final angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = (i % 2 == 0) ? rx : rx * 0.45;
        final currX = cx + r * sin(i * angle);
        final currY = cy - r * cos(i * angle);
        if (i == 0) {
          path.moveTo(currX, currY);
        } else {
          path.lineTo(currX, currY);
        }
      }
      path.close();
      return path;

    case ShapeType.car:
      return _unionPaths([
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx + w * 0.06, dy + h * 0.42, w * 0.88, h * 0.36),
              Radius.circular(w * 0.12),
            ),
          ),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx + w * 0.22, dy + h * 0.16, w * 0.56, h * 0.34),
              Radius.circular(w * 0.12),
            ),
          ),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.16, dy + h * 0.66, w * 0.24, h * 0.24)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.60, dy + h * 0.66, w * 0.24, h * 0.24)),
      ]);

    case ShapeType.heart:
      path.moveTo(dx + w / 2, dy + h * 0.22);
      path.cubicTo(
        dx + w * 5 / 6,
        dy - h / 12,
        dx + w * 1.08,
        dy + h * 0.42,
        dx + w / 2,
        dy + h * 0.94,
      );
      path.cubicTo(
        dx - w * 0.08,
        dy + h * 0.42,
        dx + w / 6,
        dy - h / 12,
        dx + w / 2,
        dy + h * 0.22,
      );
      path.close();
      return path;

    case ShapeType.icecream:
      final cone = Path()
        ..moveTo(dx + w * 0.22, dy + h * 0.50)
        ..lineTo(dx + w * 0.50, dy + h * 0.96)
        ..lineTo(dx + w * 0.78, dy + h * 0.50)
        ..close();
      return _unionPaths([
        cone,
        Path()..addOval(Rect.fromLTWH(dx + w * 0.16, dy + h * 0.26, w * 0.68, h * 0.32)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.24, dy + h * 0.05, w * 0.52, h * 0.32)),
      ]);

    case ShapeType.cake:
      return _unionPaths([
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx + w * 0.10, dy + h * 0.52, w * 0.80, h * 0.42),
              const Radius.circular(14),
            ),
          ),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(dx + w * 0.22, dy + h * 0.26, w * 0.56, h * 0.30),
              const Radius.circular(12),
            ),
          ),
        Path()..addRect(Rect.fromLTWH(dx + w * 0.45, dy + h * 0.10, w * 0.10, h * 0.18)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.43, dy + h * 0.01, w * 0.14, h * 0.12)),
      ]);

    case ShapeType.apple:
      return _unionPaths([
        Path()..addOval(Rect.fromLTWH(dx + w * 0.12, dy + h * 0.20, w * 0.76, h * 0.74)),
        Path()..addRect(Rect.fromLTWH(dx + w * 0.47, dy + h * 0.06, w * 0.06, h * 0.18)),
        Path()..addOval(Rect.fromLTWH(dx + w * 0.50, dy + h * 0.04, w * 0.30, h * 0.16)),
      ]);
  }
}

class DrawingEngine extends ChangeNotifier {
  final Map<ShapeType, List<Stroke>> shapeStrokes = {};
  final Map<ShapeType, Color?> shapeFillColors = {};
  final Map<ShapeType, Set<int>> shapeColoredGrid = {};

  final List<Confetti> canvasSparkles = [];
  final Random random = Random();

  double rainbowHue = 0.0;

  DrawingEngine() {
    for (var shape in ShapeType.values) {
      shapeStrokes[shape] = [];
      shapeFillColors[shape] = null;
      shapeColoredGrid[shape] = {};
    }
    _loadState();
  }

  void fillShape(ShapeType shape, Color color) {
    shapeFillColors[shape] = color;
    // Mark grid as 100% colored
    final grid = shapeColoredGrid[shape]!;
    for (int i = 0; i < 64; i++) {
      grid.add(i);
    }
    for (int i = 0; i < 18; i++) {
      canvasSparkles.add(Confetti(
        x: 0.2 + random.nextDouble() * 0.6,
        y: 0.2 + random.nextDouble() * 0.6,
        vx: (random.nextDouble() - 0.5) * 0.03,
        vy: (random.nextDouble() - 0.5) * 0.03,
        color: color,
        size: 5 + random.nextDouble() * 6,
      ));
    }
    _saveState();
    notifyListeners();
  }

  void addStamp(ShapeType shape, Offset relativePoint, String emoji, Color color) {
    shapeStrokes[shape]!.add(Stroke(
      points: [relativePoint],
      color: color,
      strokeWidth: 36,
      stampEmoji: emoji,
    ));
    _markGridCell(shape, relativePoint);
    for (int i = 0; i < 8; i++) {
      canvasSparkles.add(Confetti(
        x: relativePoint.dx,
        y: relativePoint.dy,
        vx: (random.nextDouble() - 0.5) * 0.025,
        vy: (random.nextDouble() - 0.5) * 0.025,
        color: Colors.amber,
        size: 4 + random.nextDouble() * 5,
      ));
    }
    _saveState();
    notifyListeners();
  }

  void startStroke(
    ShapeType shape,
    Offset relativePoint,
    Color color,
    double canvasSize,
    double strokeWidth, {
    bool isRainbow = false,
  }) {
    Color strokeColor = color;
    if (isRainbow) {
      rainbowHue = (rainbowHue + 18) % 360;
      strokeColor = HSVColor.fromAHSV(1.0, rainbowHue, 0.85, 1.0).toColor();
    }

    shapeStrokes[shape]!.add(Stroke(
      points: [relativePoint],
      color: strokeColor,
      strokeWidth: strokeWidth,
      isRainbow: isRainbow,
    ));
    if (color != Colors.white) {
      _markGridCell(shape, relativePoint);
    }
    _spawnSparkles(relativePoint, strokeColor);
    notifyListeners();
  }

  void addPointToLastStroke(ShapeType shape, Offset relativePoint, double canvasSize) {
    final strokes = shapeStrokes[shape]!;
    if (strokes.isNotEmpty) {
      final lastStroke = strokes.last;
      if (lastStroke.stampEmoji != null) return;
      Color pointColor = lastStroke.color;
      if (lastStroke.isRainbow) {
        rainbowHue = (rainbowHue + 10) % 360;
        pointColor = HSVColor.fromAHSV(1.0, rainbowHue, 0.85, 1.0).toColor();
      }

      lastStroke.points.add(relativePoint);
      if (lastStroke.color != Colors.white) {
        _markGridCell(shape, relativePoint);
      }
      _spawnSparkles(relativePoint, pointColor);
      notifyListeners();
    }
  }

  void _markGridCell(ShapeType shape, Offset rel) {
    if (rel.dx < 0.15 || rel.dx > 0.85 || rel.dy < 0.15 || rel.dy > 0.85) return;
    final gx = ((rel.dx - 0.15) / 0.70 * 8).floor().clamp(0, 7);
    final gy = ((rel.dy - 0.15) / 0.70 * 8).floor().clamp(0, 7);
    shapeColoredGrid[shape]!.add(gy * 8 + gx);
  }

  double getProgress(ShapeType shape) {
    if (shapeFillColors[shape] != null) return 1.0;
    final count = shapeColoredGrid[shape]?.length ?? 0;
    // 22 cells out of 64 inner cells is plenty for a 3-4 year old to reach 100%!
    return (count / 22.0).clamp(0.0, 1.0);
  }

  void _spawnSparkles(Offset rel, Color color) {
    if (color == Colors.white) return;
    if (random.nextDouble() > 0.45) return;
    canvasSparkles.add(Confetti(
      x: rel.dx,
      y: rel.dy,
      vx: (random.nextDouble() - 0.5) * 0.02,
      vy: (random.nextDouble() - 0.5) * 0.02,
      color: color,
      size: 3 + random.nextDouble() * 5,
    ));
  }

  void update(double dt) {
    if (canvasSparkles.isNotEmpty) {
      for (var p in canvasSparkles) {
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.05;
      }
      canvasSparkles.removeWhere((p) => p.life <= 0);
      notifyListeners();
    }
  }

  void clear(ShapeType shape) {
    shapeStrokes[shape]!.clear();
    shapeFillColors[shape] = null;
    shapeColoredGrid[shape]!.clear();
    canvasSparkles.clear();
    _saveState();
    notifyListeners();
  }

  bool isShapeColored(ShapeType shape) {
    return shapeFillColors[shape] != null ||
        shapeStrokes[shape]!.any((stroke) => stroke.color != Colors.white);
  }

  void saveState() {
    _saveState();
  }

  void _saveState() {
    try {
      final box = Hive.box('high_scores_box');
      final Map<String, dynamic> strokesMap = {};
      shapeStrokes.forEach((key, strokesList) {
        strokesMap[key.name] = strokesList
            .map((s) => {
                  'points': s.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
                  'color': s.color.toARGB32(),
                  'strokeWidth': s.strokeWidth,
                  'isRainbow': s.isRainbow,
                  'stampEmoji': s.stampEmoji,
                })
            .toList();
      });

      box.put('shape_strokes', strokesMap);
    } catch (e) {
      debugPrint('Error saving drawing state: $e');
    }
  }

  void _loadState() {
    try {
      final box = Hive.box('high_scores_box');

      final rawStrokes = box.get('shape_strokes');
      if (rawStrokes is Map) {
        rawStrokes.forEach((key, value) {
          final shape = ShapeType.values.firstWhere(
            (e) => e.name == key,
            orElse: () => ShapeType.bear,
          );
          final List<dynamic> list = value as List<dynamic>;
          shapeStrokes[shape] = list.map((item) {
            final m = item as Map;
            final List<dynamic> rawPoints = m['points'] as List<dynamic>;
            final points = rawPoints.map((p) {
              final pm = p as Map;
              return Offset(
                (pm['x'] as num).toDouble(),
                (pm['y'] as num).toDouble(),
              );
            }).toList();
            final stroke = Stroke(
              points: points,
              color: Color(m['color'] as int),
              strokeWidth: (m['strokeWidth'] as num).toDouble(),
              isRainbow: (m['isRainbow'] as bool?) ?? false,
              stampEmoji: m['stampEmoji'] as String?,
            );
            for (final pt in points) {
              _markGridCell(shape, pt);
            }
            return stroke;
          }).toList();
        });
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

class _ShapeColoringGameState extends State<ShapeColoringGame>
    with TickerProviderStateMixin {
  ShapeType _selectedShape = ShapeType.bear;
  Color _selectedColor = const Color(0xFFFF6B8B); // Cute Strawberry Pink
  bool _isRainbowMode = false;
  String? _selectedStamp; // null = brush mode, non-null = stamp emoji mode
  double _selectedWidth = 24.0;
  bool _isCelebrating = false;

  late DrawingEngine _engine;
  late Ticker _ticker;
  late AnimationController _bgAnimCtrl;
  late AnimationController _bounceCtrl;
  late confetti_pkg.ConfettiController _confettiCtrl;

  final List<Color> _paletteColors = [
    const Color(0xFFFF6B8B), // 🍓 Strawberry Pink
    const Color(0xFFFF9F43), // 🍊 Juicy Orange
    const Color(0xFFFECA57), // 🌟 Sun Yellow
    const Color(0xFF1DD1A1), // 🌿 Mint Green
    const Color(0xFF48DBFB), // 🐳 Sky Blue
    const Color(0xFF9C88FF), // 🍇 Purple Grape
    const Color(0xFFA1887F), // 🐻 Warm Brown
    Colors.white, // 🧹 Eraser
  ];

  final List<double> _brushSizes = [14.0, 24.0, 40.0];
  static const List<String> _stamps = ['⭐', '💖', '🌸', '🦋', '🍓'];

  @override
  void initState() {
    super.initState();
    _engine = DrawingEngine();
    _confettiCtrl = confetti_pkg.ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _ticker = createTicker((elapsed) {
      _engine.update(0.016);
    })..start();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _bounceCtrl.dispose();
    _ticker.dispose();
    _bgAnimCtrl.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _resetColoring() {
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
    setState(() => _isCelebrating = false);
    _engine.clear(_selectedShape);
  }

  void _magicFillShape() {
    final fillColor = _isRainbowMode
        ? HSVColor.fromAHSV(1.0, (_engine.rainbowHue + 45) % 360, 0.75, 1.0).toColor()
        : (_selectedColor == Colors.white ? const Color(0xFFFF6B8B) : _selectedColor);
    AudioManager.instance.playPaintDrop();
    HapticFeedback.mediumImpact();
    _engine.fillShape(_selectedShape, fillColor);
  }

  void _celebrateArtwork() {
    AudioManager.instance.playCookComplete();
    HapticFeedback.heavyImpact();
    _confettiCtrl.play();
    setState(() => _isCelebrating = true);
    _bounceCtrl.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _bounceCtrl.stop();
        _bounceCtrl.reset();
        setState(() => _isCelebrating = false);
      }
    });
  }

  String _getShapeNameKo(ShapeType type) {
    switch (type) {
      case ShapeType.bear:
        return '🐻 곰돌이';
      case ShapeType.cat:
        return '🐱 야옹이';
      case ShapeType.bunny:
        return '🐰 토끼';
      case ShapeType.dog:
        return '🐶 강아지';
      case ShapeType.elephant:
        return '🐘 코끼리';
      case ShapeType.lion:
        return '🦁 사자';
      case ShapeType.giraffe:
        return '🦒 기린';
      case ShapeType.dolphin:
        return '🐬 돌고래';
      case ShapeType.fish:
        return '🐠 물고기';
      case ShapeType.whale:
        return '🐳 고래';
      case ShapeType.unicorn:
        return '🦄 유니콘';
      case ShapeType.princess:
        return '👑 왕관';
      case ShapeType.rocket:
        return '🚀 로켓';
      case ShapeType.flower:
        return '🌸 꽃';
      case ShapeType.star:
        return '⭐ 별';
      case ShapeType.car:
        return '🚗 붕붕이';
      case ShapeType.heart:
        return '💖 하트';
      case ShapeType.icecream:
        return '🍦 아이스크림';
      case ShapeType.cake:
        return '🎂 케이크';
      case ShapeType.apple:
        return '🍎 사과';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 동화속 무지개 파스텔 배경
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE0F7FA),
                      Color.lerp(
                        const Color(0xFFFFF9C4),
                        const Color(0xFFFFE0B2),
                        _bgAnimCtrl.value,
                      )!,
                      const Color(0xFFFCE4EC),
                    ],
                  ),
                ),
              );
            },
          ),

          // 메인 UI 영역
          Column(
            children: [
              // 3D Glassmorphic 프리미엄 헤더
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 58,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 🏠 뒤로가기 버튼
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFB74D),
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: KidsTheme.textDark,
                                  size: 24,
                                ),
                              ),
                            ),

                            // 🎨 메인 타이틀
                            Expanded(
                              child: Center(
                                child: Text(
                                  '아기자기 색칠공부 🎨',
                                  style: GoogleFonts.jua(
                                    fontSize: 20,
                                    color: KidsTheme.purple,
                                  ),
                                ),
                              ),
                            ),

                            // 🎉 완성! 뽐내기 버튼
                            GestureDetector(
                              onTap: _celebrateArtwork,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🎉', style: TextStyle(fontSize: 15)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '완성!',
                                      style: GoogleFonts.jua(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // 🧹 현재 그림 지우기 버튼
                            GestureDetector(
                              onTap: _resetColoring,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.cleaning_services_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '지우기',
                                      style: GoogleFonts.jua(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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

              // 20종 동물/모양 선택 카루셀 (색칠한 친구는 초록 체크 표시!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListenableBuilder(
                    listenable: _engine,
                    builder: (context, child) {
                      return Row(
                        children: ShapeType.values.map((shape) {
                          final isSelected = _selectedShape == shape;
                          final isColored = _engine.isShapeColored(shape);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedShape = shape;
                                  _isCelebrating = false;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF9F43)
                                      : Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : (isColored
                                            ? const Color(0xFF66BB6A)
                                            : const Color(0xFFFFCC80)),
                                    width: 2.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          const BoxShadow(
                                            color: Color(0xFFFF9F43),
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          ),
                                        ]
                                      : [
                                          const BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _getShapeNameKo(shape),
                                      style: GoogleFonts.jua(
                                        fontSize: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : KidsTheme.textDark,
                                      ),
                                    ),
                                    if (isColored) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 12,
                                          color: isSelected
                                              ? const Color(0xFFFF9F43)
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),

              // 🎨 메인 캔버스 카드 (Expanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (context, child) {
                      final scale = _isCelebrating ? (1.0 + _bounceCtrl.value * 0.05) : 1.0;
                      final angle = _isCelebrating
                          ? sin(_bounceCtrl.value * pi * 2) * 0.03
                          : 0.0;
                      return Transform.scale(
                        scale: scale,
                        child: Transform.rotate(angle: angle, child: child),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: _isCelebrating
                              ? const Color(0xFFFFD54F)
                              : Colors.white,
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: KidsTheme.orange.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final canvasWidth = constraints.maxWidth;
                                final canvasHeight = constraints.maxHeight;

                                return GestureDetector(
                                  onTapDown: (details) {
                                    final relX = details.localPosition.dx / canvasWidth;
                                    final relY = details.localPosition.dy / canvasHeight;
                                    if (_selectedStamp != null) {
                                      AudioManager.instance.playDecalStamp();
                                      HapticFeedback.mediumImpact();
                                      _engine.addStamp(
                                        _selectedShape,
                                        Offset(relX, relY),
                                        _selectedStamp!,
                                        _selectedColor,
                                      );
                                    } else {
                                      // 톡 찍어도 큼직한 점이 찍히도록 지원 (3세 유아 탭 색칠)
                                      AudioManager.instance.playPaintDrop();
                                      HapticFeedback.lightImpact();
                                      _engine.startStroke(
                                        _selectedShape,
                                        Offset(relX, relY),
                                        _selectedColor,
                                        canvasWidth,
                                        _selectedWidth,
                                        isRainbow: _isRainbowMode,
                                      );
                                      _engine.addPointToLastStroke(
                                        _selectedShape,
                                        Offset(relX + 0.001, relY + 0.001),
                                        canvasWidth,
                                      );
                                      _engine.saveState();
                                    }
                                  },
                                  onPanStart: (details) {
                                    final relX = details.localPosition.dx / canvasWidth;
                                    final relY = details.localPosition.dy / canvasHeight;
                                    if (_selectedStamp != null) {
                                      AudioManager.instance.playDecalStamp();
                                      HapticFeedback.lightImpact();
                                      _engine.addStamp(
                                        _selectedShape,
                                        Offset(relX, relY),
                                        _selectedStamp!,
                                        _selectedColor,
                                      );
                                      return;
                                    }
                                    AudioManager.instance.playTraceDraw(rate: 1.2);
                                    HapticFeedback.lightImpact();
                                    _engine.startStroke(
                                      _selectedShape,
                                      Offset(relX, relY),
                                      _selectedColor,
                                      canvasWidth,
                                      _selectedWidth,
                                      isRainbow: _isRainbowMode,
                                    );
                                  },
                                  onPanUpdate: (details) {
                                    if (_selectedStamp != null) return;
                                    final relX = details.localPosition.dx / canvasWidth;
                                    final relY = details.localPosition.dy / canvasHeight;
                                    _engine.addPointToLastStroke(
                                      _selectedShape,
                                      Offset(relX, relY),
                                      canvasWidth,
                                    );
                                  },
                                  onPanEnd: (details) => _engine.saveState(),
                                  onPanCancel: () => _engine.saveState(),
                                  child: CustomPaint(
                                    size: Size(canvasWidth, canvasHeight),
                                    painter: _MainShapePainter(
                                      shape: _selectedShape,
                                      engine: _engine,
                                      isCelebrating: _isCelebrating,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // 캔버스 반짝이 파티클
                            ListenableBuilder(
                              listenable: _engine,
                              builder: (context, child) {
                                return IgnorePointer(
                                  child: CustomPaint(
                                    painter: _CanvasSparklePainter(
                                      _engine.canvasSparkles,
                                    ),
                                  ),
                                );
                              },
                            ),
                            // 좌상단: 🪣 한 번에 색칠(물감 붓기) 버튼
                            Positioned(
                              top: 12,
                              left: 12,
                              child: GestureDetector(
                                onTap: _magicFillShape,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🪣', style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '물감 붓기!',
                                        style: GoogleFonts.jua(
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 우상단: 색칠 완성도 게이지 & 칭찬 배지
                            Positioned(
                              top: 12,
                              right: 12,
                              child: ListenableBuilder(
                                listenable: _engine,
                                builder: (context, _) {
                                  final pct = (_engine.getProgress(_selectedShape) * 100).round();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pct >= 100
                                          ? const Color(0xFFFFF8E1)
                                          : Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: pct >= 100
                                            ? const Color(0xFFFFB300)
                                            : Colors.orange.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          pct >= 100 ? '🌟' : '🎨',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          pct >= 100 ? '멋진 작품!' : '$pct%',
                                          style: GoogleFonts.jua(
                                            fontSize: 13.5,
                                            color: pct >= 100
                                                ? const Color(0xFFE65100)
                                                : KidsTheme.textDark,
                                          ),
                                        ),
                                      ],
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
                ),
              ),

              // 🖌️ 3D 하단 팔레트 및 도구/스탬프 선택바
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 14, top: 4, bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.80),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 붓 두께 + 귀여운 스탬프 선택바
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ..._brushSizes.map((size) {
                                  final isSelected =
                                      _selectedStamp == null && _selectedWidth == size;
                                  final dotSize = size == 14.0
                                      ? 6.0
                                      : (size == 24.0 ? 11.0 : 16.0);
                                  final sizeLabel = size == 14.0
                                      ? '✏️ 얇게'
                                      : (size == 24.0 ? '🖌️ 보통' : '🎨 두껍게');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedStamp = null;
                                          _selectedWidth = size;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFFF9F43)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withValues(alpha: 0.3)
                                                    : Colors.grey.shade200,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Container(
                                                width: dotSize,
                                                height: dotSize,
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : KidsTheme.textDark,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              sizeLabel,
                                              style: GoogleFonts.jua(
                                                fontSize: 12.5,
                                                color: isSelected
                                                    ? Colors.white
                                                    : KidsTheme.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 6),
                                // ✨ 스탬프 5종 (⭐, 💖, 🌸, 🦋, 🍓)
                                ..._stamps.map((emoji) {
                                  final isSelected = _selectedStamp == emoji;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playDecalStamp();
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedStamp = emoji);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFAB47BC)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.amber
                                                : Colors.purple.shade100,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            emoji,
                                            style: const TextStyle(fontSize: 17),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 색상 팔레트 + 무지개 요술펜
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🌈 무지개 요술펜
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      AudioManager.instance.playColorSelect();
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedStamp = null;
                                        _isRainbowMode = true;
                                        _selectedColor = Colors.purple;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: (_selectedStamp == null && _isRainbowMode)
                                          ? 44
                                          : 36,
                                      height: (_selectedStamp == null && _isRainbowMode)
                                          ? 44
                                          : 36,
                                      decoration: BoxDecoration(
                                        gradient: const SweepGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.orange,
                                            Colors.yellow,
                                            Colors.green,
                                            Colors.blue,
                                            Colors.purple,
                                            Colors.red,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: (_selectedStamp == null && _isRainbowMode)
                                              ? 3.0
                                              : 2.0,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text('🌈', style: TextStyle(fontSize: 16)),
                                      ),
                                    ),
                                  ),
                                ),

                                // 단색 팔레트들
                                ..._paletteColors.map((color) {
                                  final isSelected = _selectedStamp == null &&
                                      !_isRainbowMode &&
                                      _selectedColor == color;
                                  final isEraser = color == Colors.white;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playColorSelect();
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _selectedStamp = null;
                                          _isRainbowMode = false;
                                          _selectedColor = color;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: isSelected ? 44 : 36,
                                        height: isSelected ? 44 : 36,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? KidsTheme.purple
                                                : Colors.white,
                                            width: isSelected ? 3.0 : 2.0,
                                          ),
                                          boxShadow: isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: color.withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Center(
                                          child: isEraser
                                              ? const Icon(
                                                  Icons.cleaning_services_rounded,
                                                  size: 18,
                                                  color: KidsTheme.textDark,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 축하 폭죽
          Align(
            alignment: Alignment.topCenter,
            child: confetti_pkg.ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: confetti_pkg.BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 30,
              colors: const [
                Color(0xFFFF6B8B),
                Color(0xFFFFD600),
                Color(0xFF1DD1A1),
                Color(0xFF48DBFB),
                Color(0xFF9C88FF),
              ],
            ),
          ),
        ],
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
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MainShapePainter extends CustomPainter {
  final ShapeType shape;
  final DrawingEngine engine;
  final bool isCelebrating;

  _MainShapePainter({
    required this.shape,
    required this.engine,
    required this.isCelebrating,
  }) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shapePath = getShapePath(shape, size);

    canvas.save();
    canvas.clipPath(shapePath);

    final fillColor = engine.shapeFillColors[shape];
    if (fillColor != null) {
      canvas.drawRect(rect, Paint()..color = fillColor);
    } else {
      final bgPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFAFAFA), Color(0xFFEFEFEF)],
          stops: [0.0, 0.8, 1.0],
          center: Alignment(-0.3, -0.3),
          radius: 1.0,
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bgPaint);

      final dotPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      for (double y = 0; y < size.height; y += 22) {
        for (double x = 0; x < size.width; x += 22) {
          final offsetX = (y / 22) % 2 == 0 ? x : x + 11;
          canvas.drawCircle(Offset(offsetX, y), 2.5, dotPaint);
        }
      }
    }
    canvas.restore();

    // 아이가 칠한 붓터치 & 스탬프 레이어
    canvas.saveLayer(rect, Paint());
    canvas.clipPath(shapePath);
    final strokes = engine.shapeStrokes[shape] ?? [];
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // 스탬프 렌더링
      if (stroke.stampEmoji != null) {
        final pt = stroke.points.first;
        final tp = TextPainter(
          text: TextSpan(
            text: stroke.stampEmoji,
            style: const TextStyle(fontSize: 32),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            pt.dx * size.width - tp.width / 2,
            pt.dy * size.height - tp.height / 2,
          ),
        );
        continue;
      }

      final isEraser = stroke.color == Colors.white && !stroke.isRainbow;
      if (stroke.isRainbow && stroke.points.length > 1) {
        // 진짜 무지개 그라디언트 스트로크 렌더링
        for (int i = 1; i < stroke.points.length; i++) {
          final p0 = Offset(
            stroke.points[i - 1].dx * size.width,
            stroke.points[i - 1].dy * size.height,
          );
          final p1 = Offset(
            stroke.points[i].dx * size.width,
            stroke.points[i].dy * size.height,
          );
          final segColor =
              HSVColor.fromAHSV(1.0, (i * 12.0) % 360, 0.85, 1.0).toColor();
          canvas.drawLine(
            p0,
            p1,
            Paint()
              ..color = segColor
              ..strokeWidth = stroke.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      } else {
        final strokePaint = Paint()
          ..color = isEraser ? Colors.transparent : stroke.color
          ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver
          ..strokeWidth = stroke.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (stroke.points.length == 1) {
          final p = Offset(
            stroke.points.first.dx * size.width,
            stroke.points.first.dy * size.height,
          );
          canvas.drawCircle(
            p,
            stroke.strokeWidth / 2,
            Paint()
              ..color = isEraser ? Colors.transparent : stroke.color
              ..blendMode = isEraser ? BlendMode.clear : BlendMode.srcOver,
          );
        } else {
          final path = Path()
            ..moveTo(
              stroke.points.first.dx * size.width,
              stroke.points.first.dy * size.height,
            );
          for (int i = 1; i < stroke.points.length; i++) {
            path.lineTo(
              stroke.points[i].dx * size.width,
              stroke.points[i].dy * size.height,
            );
          }
          canvas.drawPath(path, strokePaint);
        }
      }
    }
    canvas.restore();

    // 외곽선
    final strokePaint = Paint()
      ..color = KidsTheme.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawPath(shapePath, strokePaint);

    // 3~4세 아이들이 캐릭터로 바로 인지할 수 있는 귀여운 눈·코·입·볼터치 디테일 오버레이
    _drawCuteCharacterDetails(canvas, size);
  }

  void _drawCuteCharacterDetails(Canvas canvas, Size size) {
    const double scale = 0.86;
    final double w = size.width * scale;
    final double h = size.height * scale;
    final double dx = (size.width - w) / 2;
    final double dy = (size.height - h) / 2;

    final darkPaint = Paint()
      ..color = KidsTheme.borderDark
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = KidsTheme.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    void drawEye(double rx, double ry, {double r = 7}) {
      final cx = dx + w * rx;
      final cy = dy + h * ry;
      if (isCelebrating) {
        // 웃는 눈 (^ ^)
        final arc = Path()
          ..moveTo(cx - r, cy + 2)
          ..quadraticBezierTo(cx, cy - r * 1.1, cx + r, cy + 2);
        canvas.drawPath(arc, linePaint);
      } else {
        canvas.drawCircle(Offset(cx, cy), r, darkPaint);
        canvas.drawCircle(
          Offset(cx - r * 0.3, cy - r * 0.3),
          r * 0.35,
          Paint()..color = Colors.white,
        );
      }
    }

    void drawCheeks(double lx, double rx, double ry, {double r = 10}) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx + w * lx, dy + h * ry),
          width: r * 2.2,
          height: r * 1.4,
        ),
        cheekPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx + w * rx, dy + h * ry),
          width: r * 2.2,
          height: r * 1.4,
        ),
        cheekPaint,
      );
    }

    void drawSmile(double cxRatio, double cyRatio, {double width = 24}) {
      final cx = dx + w * cxRatio;
      final cy = dy + h * cyRatio;
      final p = Path()
        ..moveTo(cx - width / 2, cy)
        ..quadraticBezierTo(cx, cy + width * 0.45, cx + width / 2, cy);
      canvas.drawPath(p, linePaint);
    }

    switch (shape) {
      case ShapeType.bear:
      case ShapeType.dog:
      case ShapeType.lion:
        drawEye(0.38, 0.46, r: 7.5);
        drawEye(0.62, 0.46, r: 7.5);
        drawCheeks(0.30, 0.70, 0.54);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(dx + w * 0.50, dy + h * 0.54),
            width: 16,
            height: 11,
          ),
          darkPaint,
        );
        drawSmile(0.50, 0.59, width: 22);
        break;

      case ShapeType.cat:
      case ShapeType.bunny:
        drawEye(0.37, 0.56, r: 7.5);
        drawEye(0.63, 0.56, r: 7.5);
        drawCheeks(0.28, 0.72, 0.64);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(dx + w * 0.50, dy + h * 0.62),
            width: 12,
            height: 9,
          ),
          Paint()..color = const Color(0xFFFF6B8B),
        );
        drawSmile(0.50, 0.66, width: 20);
        break;

      case ShapeType.elephant:
        drawEye(0.38, 0.42, r: 7);
        drawEye(0.62, 0.42, r: 7);
        drawCheeks(0.31, 0.69, 0.49);
        break;

      case ShapeType.giraffe:
      case ShapeType.unicorn:
        drawEye(0.40, 0.34, r: 6.5);
        drawEye(0.60, 0.34, r: 6.5);
        drawCheeks(0.33, 0.67, 0.41, r: 8);
        drawSmile(0.50, 0.41, width: 18);
        break;

      case ShapeType.dolphin:
      case ShapeType.fish:
      case ShapeType.whale:
        drawEye(0.26, 0.48, r: 7);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(dx + w * 0.22, dy + h * 0.56),
            width: 16,
            height: 10,
          ),
          cheekPaint,
        );
        drawSmile(0.30, 0.56, width: 16);
        break;

      case ShapeType.star:
      case ShapeType.heart:
      case ShapeType.flower:
      case ShapeType.apple:
      case ShapeType.icecream:
        drawEye(0.42, 0.50, r: 6.5);
        drawEye(0.58, 0.50, r: 6.5);
        drawCheeks(0.34, 0.66, 0.57, r: 8);
        drawSmile(0.50, 0.57, width: 18);
        break;

      case ShapeType.car:
        // 자동차 창문 & 헤드라이트 눈
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dx + w * 0.28, dy + h * 0.22, w * 0.44, h * 0.20),
            const Radius.circular(10),
          ),
          linePaint,
        );
        drawEye(0.30, 0.56, r: 6);
        drawEye(0.70, 0.56, r: 6);
        drawSmile(0.50, 0.58, width: 20);
        break;

      case ShapeType.rocket:
        canvas.drawCircle(
          Offset(dx + w * 0.50, dy + h * 0.44),
          w * 0.12,
          linePaint,
        );
        drawEye(0.45, 0.44, r: 5);
        drawEye(0.55, 0.44, r: 5);
        drawSmile(0.50, 0.48, width: 14);
        break;

      case ShapeType.princess:
      case ShapeType.cake:
        drawEye(0.42, 0.62, r: 6);
        drawEye(0.58, 0.62, r: 6);
        drawCheeks(0.34, 0.66, 0.68, r: 8);
        drawSmile(0.50, 0.68, width: 18);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MainShapePainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.engine != engine ||
        oldDelegate.isCelebrating != isCelebrating;
  }
}
