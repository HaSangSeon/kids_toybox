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

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isRainbow = false,
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
  const double scale = 0.72; // Scaled down for easy coloring
  final double targetWidth = size.width * scale;
  final double targetHeight = size.height * scale;
  final double dx = (size.width - targetWidth) / 2;
  final double dy = (size.height - targetHeight) / 2;

  final path = Path();
  final subSize = Size(targetWidth, targetHeight);
  final w = subSize.width;
  final h = subSize.height;

  switch (shape) {
    case ShapeType.bear:
      // 🐻 곰돌이
      path.addOval(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.25, w * 0.7, h * 0.7));
      path.addOval(Rect.fromLTWH(dx + w * 0.12, dy + h * 0.1, w * 0.26, h * 0.26));
      path.addOval(Rect.fromLTWH(dx + w * 0.62, dy + h * 0.1, w * 0.26, h * 0.26));
      break;

    case ShapeType.cat:
      // 🐱 야옹이 (귀 뾰족)
      path.moveTo(dx + w * 0.2, dy + h * 0.4);
      path.lineTo(dx + w * 0.15, dy + h * 0.12);
      path.lineTo(dx + w * 0.4, dy + h * 0.25);
      path.lineTo(dx + w * 0.6, dy + h * 0.25);
      path.lineTo(dx + w * 0.85, dy + h * 0.12);
      path.lineTo(dx + w * 0.8, dy + h * 0.4);
      path.quadraticBezierTo(dx + w * 0.95, dy + h * 0.7, dx + w * 0.5, dy + h * 0.95);
      path.quadraticBezierTo(dx + w * 0.05, dy + h * 0.7, dx + w * 0.2, dy + h * 0.4);
      path.close();
      break;

    case ShapeType.bunny:
      // 🐰 토끼
      path.addOval(Rect.fromLTWH(dx + w * 0.2, dy + h * 0.4, w * 0.6, h * 0.55));
      path.addOval(Rect.fromLTWH(dx + w * 0.22, dy + h * 0.05, w * 0.22, h * 0.42));
      path.addOval(Rect.fromLTWH(dx + w * 0.56, dy + h * 0.05, w * 0.22, h * 0.42));
      break;

    case ShapeType.dog:
      // 🐶 강아지 (늘어진 귀)
      path.addOval(Rect.fromLTWH(dx + w * 0.25, dy + h * 0.25, w * 0.5, h * 0.6));
      // 왼쪽 귀
      path.addOval(Rect.fromLTWH(dx + w * 0.05, dy + h * 0.2, w * 0.25, h * 0.55));
      // 오른쪽 귀
      path.addOval(Rect.fromLTWH(dx + w * 0.7, dy + h * 0.2, w * 0.25, h * 0.55));
      break;

    case ShapeType.elephant:
      // 🐘 코끼리 (큰 귀 & 코)
      path.addOval(Rect.fromLTWH(dx + w * 0.25, dy + h * 0.25, w * 0.5, h * 0.5));
      path.addOval(Rect.fromLTWH(dx + w * 0.05, dy + h * 0.2, w * 0.3, h * 0.45)); // 귀1
      path.addOval(Rect.fromLTWH(dx + w * 0.65, dy + h * 0.2, w * 0.3, h * 0.45)); // 귀2
      // 코
      path.moveTo(dx + w * 0.45, dy + h * 0.65);
      path.quadraticBezierTo(dx + w * 0.5, dy + h * 0.95, dx + w * 0.65, dy + h * 0.85);
      path.lineTo(dx + w * 0.55, dy + h * 0.65);
      break;

    case ShapeType.lion:
      // 🦁 사자 (갈기 & 얼굴)
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int manePoints = 12;
      for (int i = 0; i <= manePoints; i++) {
        final angle = i * 2 * pi / manePoints;
        final r = (i % 2 == 0) ? rx : rx * 0.7;
        final currX = cx + r * cos(angle);
        final currY = cy + r * sin(angle);
        if (i == 0) path.moveTo(currX, currY);
        else path.lineTo(currX, currY);
      }
      path.close();
      break;

    case ShapeType.giraffe:
      // 🦒 기린 (긴 목 & 뿔)
      path.addOval(Rect.fromLTWH(dx + w * 0.3, dy + h * 0.2, w * 0.4, h * 0.45));
      path.addRect(Rect.fromLTWH(dx + w * 0.38, dy + h * 0.55, w * 0.24, h * 0.4));
      path.addOval(Rect.fromLTWH(dx + w * 0.32, dy + h * 0.05, w * 0.12, h * 0.18)); // 뿔1
      path.addOval(Rect.fromLTWH(dx + w * 0.56, dy + h * 0.05, w * 0.12, h * 0.18)); // 뿔2
      break;

    case ShapeType.dolphin:
      // 🐬 돌고래
      path.moveTo(dx + w * 0.1, dy + h * 0.5);
      path.quadraticBezierTo(dx + w * 0.4, dy + h * 0.08, dx + w * 0.9, dy + h * 0.5);
      path.lineTo(dx + w * 1.0, dy + h * 0.38);
      path.lineTo(dx + w * 0.92, dy + h * 0.5);
      path.lineTo(dx + w * 1.0, dy + h * 0.62);
      path.quadraticBezierTo(dx + w * 0.5, dy + h * 0.92, dx + w * 0.1, dy + h * 0.5);
      path.close();
      break;

    case ShapeType.fish:
      // 🐠 물고기
      path.moveTo(dx + w * 0.08, dy + h * 0.5);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.12, dx + w * 0.78, dy + h * 0.5);
      path.lineTo(dx + w * 0.96, dy + h * 0.25);
      path.lineTo(dx + w * 0.88, dy + h * 0.5);
      path.lineTo(dx + w * 0.96, dy + h * 0.75);
      path.lineTo(dx + w * 0.78, dy + h * 0.5);
      path.quadraticBezierTo(dx + w * 0.45, dy + h * 0.88, dx + w * 0.08, dy + h * 0.5);
      path.close();
      break;

    case ShapeType.whale:
      // 🐳 아기 고래
      path.moveTo(dx + w * 0.1, dy + h * 0.6);
      path.quadraticBezierTo(dx + w * 0.15, dy + h * 0.25, dx + w * 0.65, dy + h * 0.3);
      path.quadraticBezierTo(dx + w * 0.85, dy + h * 0.3, dx + w * 0.95, dy + h * 0.55);
      path.lineTo(dx + w * 1.05, dy + h * 0.4);
      path.lineTo(dx + w * 0.95, dy + h * 0.65);
      path.quadraticBezierTo(dx + w * 0.5, dy + h * 0.95, dx + w * 0.1, dy + h * 0.6);
      path.close();
      break;

    case ShapeType.unicorn:
      // 🦄 유니콘 뿔 & 머리
      path.addOval(Rect.fromLTWH(dx + w * 0.25, dy + h * 0.35, w * 0.5, h * 0.55));
      path.moveTo(dx + w * 0.5, dy + h * 0.05);
      path.lineTo(dx + w * 0.38, dy + h * 0.38);
      path.lineTo(dx + w * 0.62, dy + h * 0.38);
      path.close();
      break;

    case ShapeType.princess:
      // 👑 공주 왕관
      path.addOval(Rect.fromLTWH(dx + w * 0.2, dy + h * 0.45, w * 0.6, h * 0.5));
      path.moveTo(dx + w * 0.25, dy + h * 0.5);
      path.lineTo(dx + w * 0.15, dy + h * 0.15); 
      path.lineTo(dx + w * 0.38, dy + h * 0.32);
      path.lineTo(dx + w * 0.5, dy + h * 0.08); 
      path.lineTo(dx + w * 0.62, dy + h * 0.32);
      path.lineTo(dx + w * 0.85, dy + h * 0.15); 
      path.lineTo(dx + w * 0.75, dy + h * 0.5);
      path.close();
      break;

    case ShapeType.rocket:
      // 🚀 로켓
      path.moveTo(dx + w * 0.5, dy + h * 0.08);
      path.quadraticBezierTo(dx + w * 0.8, dy + h * 0.3, dx + w * 0.7, dy + h * 0.75);
      path.lineTo(dx + w * 0.88, dy + h * 0.9);
      path.lineTo(dx + w * 0.65, dy + h * 0.85);
      path.lineTo(dx + w * 0.5, dy + h * 0.78);
      path.lineTo(dx + w * 0.35, dy + h * 0.85);
      path.lineTo(dx + w * 0.12, dy + h * 0.9);
      path.lineTo(dx + w * 0.3, dy + h * 0.75);
      path.quadraticBezierTo(dx + w * 0.2, dy + h * 0.3, dx + w * 0.5, dy + h * 0.08);
      path.close();
      break;

    case ShapeType.flower:
      // 🌸 꽃
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int petals = 5;
      for (int i = 0; i <= 360; i += 2) {
        final angle = i * pi / 180;
        final r = rx * (0.65 + 0.32 * cos(petals * angle).abs());
        final currX = cx + r * cos(angle);
        final currY = cy + r * sin(angle);
        if (i == 0) path.moveTo(currX, currY);
        else path.lineTo(currX, currY);
      }
      path.close();
      break;

    case ShapeType.star:
      // ⭐ 별
      final cx = dx + w / 2;
      final cy = dy + h / 2;
      final rx = w / 2;
      const int points = 5;
      final angle = pi / points;
      for (int i = 0; i < 2 * points; i++) {
        final r = (i % 2 == 0) ? rx : rx * 0.45;
        final currX = cx + r * sin(i * angle);
        final currY = cy - r * cos(i * angle);
        if (i == 0) path.moveTo(currX, currY);
        else path.lineTo(currX, currY);
      }
      path.close();
      break;

    case ShapeType.car:
      // 🚗 붕붕이
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + w * 0.1, dy + h * 0.45, w * 0.8, h * 0.35),
        Radius.circular(w * 0.12),
      ));
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + w * 0.25, dy + h * 0.2, w * 0.5, h * 0.32),
        Radius.circular(w * 0.1),
      ));
      path.addOval(Rect.fromLTWH(dx + w * 0.2, dy + h * 0.7, w * 0.22, h * 0.22));
      path.addOval(Rect.fromLTWH(dx + w * 0.58, dy + h * 0.7, w * 0.22, h * 0.22));
      break;

    case ShapeType.heart:
      // 💖 하트
      path.moveTo(dx + w / 2, dy + h / 5);
      path.cubicTo(dx + w * 5 / 6, dy - h / 10, dx + w * 1.1, dy + h * 2 / 5, dx + w / 2, dy + h * 9 / 10);
      path.cubicTo(dx - w * 0.1, dy + h * 2 / 5, dx + w / 6, dy - h / 10, dx + w / 2, dy + h / 5);
      path.close();
      break;

    case ShapeType.icecream:
      // 🍦 아이스크림 콘
      path.moveTo(dx + w * 0.2, dy + h * 0.45);
      path.lineTo(dx + w * 0.5, dy + h * 0.95);
      path.lineTo(dx + w * 0.8, dy + h * 0.45);
      path.close();
      // 스쿱
      path.addOval(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.1, w * 0.7, h * 0.45));
      break;

    case ShapeType.cake:
      // 🎂 케이크 & 초
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + w * 0.15, dy + h * 0.45, w * 0.7, h * 0.45),
        Radius.circular(12),
      ));
      path.addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(dx + w * 0.25, dy + h * 0.25, w * 0.5, h * 0.25),
        Radius.circular(10),
      ));
      // 초
      path.addRect(Rect.fromLTWH(dx + w * 0.45, dy + h * 0.08, w * 0.1, h * 0.18));
      break;

    case ShapeType.apple:
      // 🍎 사과
      path.addOval(Rect.fromLTWH(dx + w * 0.15, dy + h * 0.2, w * 0.7, h * 0.7));
      // 잎사귀
      path.addOval(Rect.fromLTWH(dx + w * 0.48, dy + h * 0.08, w * 0.25, h * 0.15));
      break;
  }
  return path;
}

class DrawingEngine extends ChangeNotifier {
  final Map<ShapeType, List<Stroke>> shapeStrokes = {};
  final Map<ShapeType, Set<int>> shapeColoredGrid = {};
  
  final List<Confetti> canvasSparkles = [];
  final Random random = Random();

  double rainbowHue = 0.0;

  DrawingEngine() {
    for (var shape in ShapeType.values) {
      shapeStrokes[shape] = [];
      shapeColoredGrid[shape] = {};
    }
    _loadState();
  }

  void startStroke(ShapeType shape, Offset relativePoint, Color color, double canvasSize, double strokeWidth, {bool isRainbow = false}) {
    Color strokeColor = color;
    if (isRainbow) {
      rainbowHue = (rainbowHue + 15) % 360;
      strokeColor = HSVColor.fromAHSV(1.0, rainbowHue, 0.9, 1.0).toColor();
    }

    shapeStrokes[shape]!.add(Stroke(
      points: [relativePoint],
      color: strokeColor,
      strokeWidth: strokeWidth,
      isRainbow: isRainbow,
    ));
    _spawnSparkles(relativePoint, strokeColor);
    notifyListeners();
  }

  void addPointToLastStroke(ShapeType shape, Offset relativePoint, double canvasSize) {
    final strokes = shapeStrokes[shape]!;
    if (strokes.isNotEmpty) {
      final lastStroke = strokes.last;
      Color pointColor = lastStroke.color;
      if (lastStroke.isRainbow) {
        rainbowHue = (rainbowHue + 8) % 360;
        pointColor = HSVColor.fromAHSV(1.0, rainbowHue, 0.9, 1.0).toColor();
      }

      lastStroke.points.add(relativePoint);
      _spawnSparkles(relativePoint, pointColor);
      notifyListeners();
    }
  }

  void _spawnSparkles(Offset rel, Color color) {
    if (color == Colors.white) return;
    if (random.nextDouble() > 0.45) return;
    canvasSparkles.add(Confetti(
      x: rel.dx,
      y: rel.dy,
      vx: (random.nextDouble() - 0.5) * 0.02,
      vy: (random.nextDouble() - 0.5) * 0.02,
      color: Colors.white,
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
    canvasSparkles.clear();
    _saveState();
    notifyListeners();
  }

  bool isShapeColored(ShapeType shape) {
    return shapeStrokes[shape]!.any((stroke) => stroke.color != Colors.white);
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
          'isRainbow': s.isRainbow,
        }).toList();
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
          final shape = ShapeType.values.firstWhere((e) => e.name == key, orElse: () => ShapeType.bear);
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
              isRainbow: (m['isRainbow'] as bool?) ?? false,
            );
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

class _ShapeColoringGameState extends State<ShapeColoringGame> with TickerProviderStateMixin {
  ShapeType _selectedShape = ShapeType.bear;
  Color _selectedColor = const Color(0xFFFF6B8B); // Cute Strawberry Pink
  bool _isRainbowMode = false;
  double _selectedWidth = 20.0; 
  late DrawingEngine _engine;
  late Ticker _ticker;
  late AnimationController _bgAnimCtrl;

  final List<Color> _paletteColors = [
    const Color(0xFFFF6B8B), // 🍓 Strawberry Pink
    const Color(0xFFFF9F43), // 🍊 Juicy Orange
    const Color(0xFFFECA57), // 🌟 Sun Yellow
    const Color(0xFF1DD1A1), // 🌿 Mint Green
    const Color(0xFF48DBFB), // 🐳 Sky Blue
    const Color(0xFF9C88FF), // 🍇 Purple Grape
    const Color(0xFF8395A7), // 🍫 Chocolate
    Colors.white,            // 🧹 Eraser
  ];

  final List<double> _brushSizes = [10.0, 20.0, 36.0];

  @override
  void initState() {
    super.initState();
    _engine = DrawingEngine();

    _bgAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _ticker = createTicker((elapsed) {
      _engine.update(0.016);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _bgAnimCtrl.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _resetColoring() {
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
    _engine.clear(_selectedShape);
  }

  String _getShapeNameKo(ShapeType type) {
    switch (type) {
      case ShapeType.bear: return '🐻 곰돌이';
      case ShapeType.cat: return '🐱 야옹이';
      case ShapeType.bunny: return '🐰 토끼';
      case ShapeType.dog: return '🐶 강아지';
      case ShapeType.elephant: return '🐘 코끼리';
      case ShapeType.lion: return '🦁 사자';
      case ShapeType.giraffe: return '🦒 기린';
      case ShapeType.dolphin: return '🐬 돌고래';
      case ShapeType.fish: return '🐠 물고기';
      case ShapeType.whale: return '🐳 고래';
      case ShapeType.unicorn: return '🦄 유니콘';
      case ShapeType.princess: return '👑 왕관';
      case ShapeType.rocket: return '🚀 로켓';
      case ShapeType.flower: return '🌸 꽃';
      case ShapeType.star: return '⭐ 별';
      case ShapeType.car: return '🚗 붕붕이';
      case ShapeType.heart: return '💖 하트';
      case ShapeType.icecream: return '🍦 아이스크림';
      case ShapeType.cake: return '🎂 케이크';
      case ShapeType.apple: return '🍎 사과';
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
                      const Color(0xFFE0F7FA), // Mint cyan sky
                      Color.lerp(const Color(0xFFFFF9C4), const Color(0xFFFFE0B2), _bgAnimCtrl.value)!, // Cream yellow
                      const Color(0xFFFCE4EC), // Soft pink
                    ],
                  ),
                ),
              );
            },
          ),

          // ☁️ 둥둥 떠다니는 귀여운 구름 & 별무리 배경 요소
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              final val = _bgAnimCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    left: 20 + val * 30,
                    top: 70,
                    child: const Opacity(opacity: 0.6, child: Text('☁️', style: TextStyle(fontSize: 48))),
                  ),
                  Positioned(
                    right: 30 + val * 40,
                    top: 140,
                    child: const Opacity(opacity: 0.5, child: Text('☁️', style: TextStyle(fontSize: 40))),
                  ),
                  Positioned(
                    left: 240 - val * 20,
                    top: 110,
                    child: const Opacity(opacity: 0.7, child: Text('🎈', style: TextStyle(fontSize: 32))),
                  ),
                  Positioned(
                    right: 180 + val * 20,
                    top: 80,
                    child: const Opacity(opacity: 0.65, child: Text('✨', style: TextStyle(fontSize: 28))),
                  ),
                ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 26),
                              ),
                            ),
                            
                            // 🎨 메인 타이틀
                            Expanded(
                              child: Center(
                                child: Text(
                                  '아기자기 색칠공부 🎨',
                                  style: GoogleFonts.jua(
                                    fontSize: 22,
                                    foreground: Paint()
                                      ..style = PaintingStyle.fill
                                      ..color = KidsTheme.purple,
                                    shadows: const [
                                      Shadow(color: Colors.white, offset: Offset(1.5, 1.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 🧹 현재 그림 지우기 버튼
                            GestureDetector(
                              onTap: _resetColoring,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      '지우기',
                                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
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

              // 20종 동물/모양 선택 카루셀 (깔끔한 텍스트 뱃지)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
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

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                HapticFeedback.selectionClick();
                                setState(() => _selectedShape = shape);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF9F43) : Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : const Color(0xFFFFCC80),
                                    width: 2.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [const BoxShadow(color: Color(0xFFFF9F43), blurRadius: 8, offset: Offset(0, 3))]
                                      : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                child: Text(
                                  _getShapeNameKo(shape),
                                  style: GoogleFonts.jua(
                                    fontSize: 16,
                                    color: isSelected ? Colors.white : KidsTheme.textDark,
                                  ),
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

              // 🎨 메인 캔버스 카드
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          border: Border.all(color: Colors.white, width: 6),
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
                                    onPanStart: (details) {
                                      AudioManager.instance.playTraceDraw(rate: 1.2);
                                      HapticFeedback.lightImpact();
                                      final relX = details.localPosition.dx / canvasWidth;
                                      final relY = details.localPosition.dy / canvasHeight;
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
                                      final relX = details.localPosition.dx / canvasWidth;
                                      final relY = details.localPosition.dy / canvasHeight;
                                      _engine.addPointToLastStroke(_selectedShape, Offset(relX, relY), canvasWidth);
                                    },
                                    onPanEnd: (details) => _engine.saveState(),
                                    onPanCancel: () => _engine.saveState(),
                                    child: CustomPaint(
                                      size: Size(canvasWidth, canvasHeight),
                                      painter: _MainShapePainter(
                                        shape: _selectedShape,
                                        engine: _engine,
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

              // 🖌️ 3D 하단 팔레트 및 도구 선택바
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          // 붓 두께 선택바
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '붓 두께:',
                                  style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.textDark),
                                ),
                                const SizedBox(width: 6),
                                ..._brushSizes.map((size) {
                                  final isSelected = _selectedWidth == size;
                                  double dotSize = size == 10.0 ? 6.0 : (size == 20.0 ? 12.0 : 18.0);
                                  String sizeLabel = size == 10.0 ? '✏️ 얇게' : (size == 20.0 ? '🖌️ 보통' : '🎨 두껍게');

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedWidth = size);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFFF9F43) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: isSelected ? Colors.white : Colors.grey.shade300, width: 2),
                                          boxShadow: isSelected ? [const BoxShadow(color: Color(0xFFFF9F43), blurRadius: 6)] : [],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16, height: 16,
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
                                              style: GoogleFonts.jua(
                                                fontSize: 13,
                                                color: isSelected ? Colors.white : KidsTheme.textDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 색상 팔레트 + 무지개 요술펜 (가로 스크롤 가능하여 절대 잘리지 않음)
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
                                        _isRainbowMode = true;
                                        _selectedColor = Colors.purple;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: _isRainbowMode ? 44 : 36,
                                      height: _isRainbowMode ? 44 : 36,
                                      decoration: BoxDecoration(
                                        gradient: const SweepGradient(
                                          colors: [
                                            Colors.red, Colors.orange, Colors.yellow,
                                            Colors.green, Colors.blue, Colors.purple, Colors.red,
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isRainbowMode ? Colors.white : Colors.white.withValues(alpha: 0.8),
                                          width: _isRainbowMode ? 3.0 : 2.0,
                                        ),
                                        boxShadow: _isRainbowMode
                                            ? [const BoxShadow(color: Colors.purple, blurRadius: 8, offset: Offset(0, 3))]
                                            : [],
                                      ),
                                      child: const Center(
                                        child: Text('🌈', style: TextStyle(fontSize: 16)),
                                      ),
                                    ),
                                  ),
                                ),

                                // 단색 팔레트들
                                ..._paletteColors.map((color) {
                                  final isSelected = !_isRainbowMode && _selectedColor == color;
                                  final isEraser = color == Colors.white;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playColorSelect();
                                        HapticFeedback.selectionClick();
                                        setState(() {
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
                                            color: isSelected ? KidsTheme.purple : Colors.white,
                                            width: isSelected ? 3.0 : 2.0,
                                          ),
                                          boxShadow: isSelected
                                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))]
                                              : [],
                                        ),
                                        child: Center(
                                          child: isEraser
                                              ? const Icon(Icons.cleaning_services_rounded, size: 18, color: KidsTheme.textDark)
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
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MainShapePainter extends CustomPainter {
  final ShapeType shape;
  final DrawingEngine engine;

  _MainShapePainter({required this.shape, required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final shapePath = getShapePath(shape, size);

    canvas.save();
    canvas.clipPath(shapePath);
    
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Colors.white, Color(0xFFFAFAFA), Color(0xFFE8E8E8)],
        stops: const [0.0, 0.8, 1.0],
        center: const Alignment(-0.3, -0.3),
        radius: 1.0,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);
    
    final dotPaint = Paint()..color = Colors.grey.withValues(alpha: 0.12)..style = PaintingStyle.fill;
    for (double y = 0; y < size.height; y += 20) {
      for (double x = 0; x < size.width; x += 20) {
        final offsetX = (y / 20) % 2 == 0 ? x : x + 10;
        canvas.drawCircle(Offset(offsetX, y), 2.5, dotPaint);
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

    final strokePaint = Paint()
      ..color = KidsTheme.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawPath(shapePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _MainShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.engine != engine;
  }
}
