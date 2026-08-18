import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';

// --- DATA STRUCTURES ---

enum TracingCategory {
  shapes('도형과 선', '🔴', Colors.pinkAccent),
  numbers('숫자 놀이', '🔢', Colors.orangeAccent),
  hangul('한글 배우기', '🇰🇷', Colors.green),
  alphabet('ABC 알파벳', '🔤', Colors.purpleAccent),
  objects('그림 따라 그리기', '🎨', Colors.blueAccent);

  final String label;
  final String icon;
  final Color color;
  const TracingCategory(this.label, this.icon, this.color);
}

enum MagicBrushType {
  rainbow('무지개 🌈', Colors.pink, Icons.color_lens),
  sparkle('반짝이 별 ✨', Colors.amber, Icons.auto_awesome),
  bubble('마법 방울 🫧', Colors.lightBlue, Icons.bubble_chart),
  crayon('크레파스 🖍️', Colors.deepOrange, Icons.edit),
  comet('네온 은하수 🔥', Colors.cyanAccent, Icons.bolt);

  final String label;
  final Color color;
  final IconData icon;
  const MagicBrushType(this.label, this.color, this.icon);
}

class ShapeDef {
  final String name;
  final String emoji;
  final List<Offset> points;
  final TracingCategory category;
  final String hint;
  final bool isCurved;
  final bool isCircle;
  final Rect? circleRect;

  ShapeDef(
    this.name,
    this.emoji,
    this.points,
    this.category, {
    this.hint = '',
    this.isCurved = false,
    this.isCircle = false,
    this.circleRect,
  });
}

class DrawnStroke {
  final List<Offset> points;
  final MagicBrushType brushType;

  DrawnStroke({
    required this.points,
    required this.brushType,
  });
}

// --- PARTICLE MODEL ---

class TouchParticle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double alpha;
  double maxAlpha;
  String? char;

  TouchParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.alpha = 1.0,
    this.maxAlpha = 1.0,
    this.char,
  });

  void update() {
    position += velocity;
    alpha -= 0.03;
    if (alpha < 0) alpha = 0;
  }
}

class PopStar {
  final Key key = UniqueKey();
  Offset position;
  double scale;
  Color color;
  bool popped;

  PopStar({
    required this.position,
    this.scale = 1.0,
    required this.color,
    this.popped = false,
  });
}

// --- MAIN GAME WIDGET ---

class TracingGame extends StatefulWidget {
  const TracingGame({super.key});

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class _TracingGameState extends State<TracingGame> with TickerProviderStateMixin {
  TracingCategory _selectedCategory = TracingCategory.shapes;
  MagicBrushType _selectedBrush = MagicBrushType.rainbow;

  int _categoryIndex = 0;
  bool _isLevelClear = false;

  final List<DrawnStroke> _userStrokes = [];
  final Map<int, Set<int>> _strokeCoveredCheckpoints = {};

  late List<ShapeDef> _allShapes;
  late List<ShapeDef> _filteredShapes;

  // Particle Engine & Animation Timers
  final List<TouchParticle> _particles = [];
  final List<PopStar> _popStars = [];
  Timer? _tickerTimer;
  Timer? _autoNextTimer;
  double _hueTime = 0.0;

  // Mascot Cheer State
  late AnimationController _mascotBounceController;
  String _mascotMessage = '라인을 따라 자유롭게 쓱쓱 그려봐! ✨';
  final Random _random = Random();

  // Living Picture & Confetti
  late AnimationController _livingObjectController;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initShapes();
    _updateFilteredShapes();

    // Mascot animation
    _mascotBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Living picture controller
    _livingObjectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Main particle update tick
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted) return;
      setState(() {
        _hueTime += 0.05;
        for (var p in _particles) {
          p.update();
        }
        _particles.removeWhere((p) => p.alpha <= 0);
      });
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _autoNextTimer?.cancel();
    _confettiController.dispose();
    _mascotBounceController.dispose();
    _livingObjectController.dispose();
    super.dispose();
  }

  void _initShapes() {
    // 0~100 normalized grid
    _allShapes = [
      // 🔴 SHAPES
      ShapeDef('직선 긋기', '📏', const [Offset(10, 50), Offset(50, 50), Offset(90, 50)], TracingCategory.shapes, hint: '쭉 직선으로 그어봐!'),
      ShapeDef('지그재그', '⚡', const [Offset(10, 80), Offset(30, 20), Offset(50, 80), Offset(70, 20), Offset(90, 80)], TracingCategory.shapes, hint: '번개처럼 삐죽삐죽!'),
      ShapeDef('삼각형', '🔺', const [Offset(50, 10), Offset(90, 90), Offset(10, 90), Offset(50, 10)], TracingCategory.shapes, hint: '뾰족한 세모!'),
      ShapeDef('사각형', '🟦', const [Offset(20, 20), Offset(80, 20), Offset(80, 80), Offset(20, 80), Offset(20, 20)], TracingCategory.shapes, hint: '반듯반듯 네모!'),
      ShapeDef('동그라미 원', '🔴', const [Offset(50, 10), Offset(35, 14), Offset(20, 28), Offset(10, 50), Offset(20, 72), Offset(35, 86), Offset(50, 90), Offset(65, 86), Offset(80, 72), Offset(90, 50), Offset(80, 28), Offset(65, 14), Offset(50, 10)], TracingCategory.shapes, hint: '동글동글 동그라미!'),
      ShapeDef('반짝이 별', '⭐', const [Offset(50, 10), Offset(75, 90), Offset(10, 40), Offset(90, 40), Offset(25, 90), Offset(50, 10)], TracingCategory.shapes, hint: '밤하늘의 예쁜 별!'),
      ShapeDef('예쁜 하트', '💛', const [Offset(50, 30), Offset(40, 18), Offset(25, 12), Offset(12, 22), Offset(10, 42), Offset(25, 65), Offset(50, 90), Offset(75, 65), Offset(90, 42), Offset(88, 22), Offset(75, 12), Offset(60, 18), Offset(50, 30)], TracingCategory.shapes, hint: '사랑스러운 하트!'),

      // 🔢 NUMBERS (표준 획순 + 매끄러운 곡선)
      ShapeDef('숫자 1', '1️⃣', const [Offset(35, 25), Offset(50, 10), Offset(50, 90)], TracingCategory.numbers, hint: '위에서 아래로 1!'),
      ShapeDef('숫자 2', '2️⃣', const [Offset(22, 32), Offset(30, 20), Offset(45, 12), Offset(62, 12), Offset(76, 22), Offset(78, 36), Offset(72, 48), Offset(52, 65), Offset(22, 88), Offset(82, 88)], TracingCategory.numbers, hint: '오리 머리처럼 둥글게 2!'),
      ShapeDef('숫자 3', '3️⃣', const [Offset(25, 16), Offset(68, 16), Offset(80, 26), Offset(76, 40), Offset(50, 48), Offset(78, 56), Offset(82, 72), Offset(70, 86), Offset(48, 90), Offset(24, 82)], TracingCategory.numbers, hint: '볼록볼록 예쁜 3!'),
      ShapeDef('숫자 4', '4️⃣', const [Offset(65, 15), Offset(18, 60), Offset(82, 60), Offset.infinite, Offset(65, 15), Offset(65, 88)], TracingCategory.numbers, hint: '꺾어서 밑으로 4!'),
      ShapeDef('숫자 5', '5️⃣', const [Offset(76, 16), Offset(28, 16), Offset(24, 46), Offset(45, 42), Offset(68, 46), Offset(80, 60), Offset(76, 78), Offset(60, 88), Offset(36, 88), Offset(22, 78)], TracingCategory.numbers, hint: '지붕 덮고 볼록볼록 5!'),
      ShapeDef('숫자 6', '6️⃣', const [Offset(72, 16), Offset(50, 20), Offset(30, 36), Offset(20, 58), Offset(24, 78), Offset(44, 88), Offset(68, 86), Offset(78, 70), Offset(74, 54), Offset(58, 46), Offset(38, 48), Offset(20, 58)], TracingCategory.numbers, hint: '둥글게 내려와 6!'),
      ShapeDef('숫자 7', '7️⃣', const [Offset(20, 16), Offset(80, 16), Offset(38, 88)], TracingCategory.numbers, hint: '옆으로 아래로 7!'),
      ShapeDef('숫자 8', '8️⃣', const [Offset(50, 14), Offset(36, 18), Offset(28, 30), Offset(36, 42), Offset(50, 48), Offset(66, 56), Offset(74, 72), Offset(64, 86), Offset(50, 88), Offset(36, 86), Offset(26, 72), Offset(34, 56), Offset(50, 48), Offset(64, 42), Offset(72, 30), Offset(64, 18), Offset(50, 14)], TracingCategory.numbers, hint: '눈사람처럼 매끄럽게 8!'),
      ShapeDef('숫자 9', '9️⃣', const [Offset(74, 48), Offset(58, 46), Offset(38, 48), Offset(22, 36), Offset(24, 22), Offset(42, 14), Offset(66, 18), Offset(76, 32), Offset(74, 50), Offset(68, 72), Offset(52, 86), Offset(30, 88)], TracingCategory.numbers, hint: '동그라미 그리고 내려와 9!'),
      ShapeDef('숫자 0', '0️⃣', const [Offset(50, 12), Offset(34, 16), Offset(22, 32), Offset(18, 50), Offset(22, 68), Offset(34, 84), Offset(50, 88), Offset(66, 84), Offset(78, 68), Offset(82, 50), Offset(78, 32), Offset(66, 16), Offset(50, 12)], TracingCategory.numbers, hint: '동글동글 타원 0!'),

      // 🇰🇷 HANGUL (훈민정음 표준 획순 + 곡선 매끄러운 14자)
      ShapeDef('기역 (ㄱ)', 'ㄱ', const [Offset(20, 20), Offset(80, 20), Offset(80, 80)], TracingCategory.hangul, hint: '옆으로(ㅡ) 내리기(ㅣ) ㄱ!'),
      ShapeDef('니은 (ㄴ)', 'ㄴ', const [Offset(20, 20), Offset(20, 80), Offset(80, 80)], TracingCategory.hangul, hint: '아래로(ㅣ) 옆으로(ㅡ) ㄴ!'),
      ShapeDef('디귿 (ㄷ)', 'ㄷ', const [Offset(20, 25), Offset(80, 25), Offset.infinite, Offset(20, 25), Offset(20, 75), Offset(80, 75)], TracingCategory.hangul, hint: '위(ㅡ) 그리고 아래(ㄴ) ㄷ!'),
      ShapeDef('리을 (ㄹ)', 'ㄹ', const [Offset(20, 20), Offset(80, 20), Offset(80, 48), Offset.infinite, Offset(20, 48), Offset(80, 48), Offset.infinite, Offset(20, 48), Offset(20, 80), Offset(80, 80)], TracingCategory.hangul, hint: '순서대로 차근차근 ㄹ!'),
      ShapeDef('미음 (ㅁ)', 'ㅁ', const [Offset(25, 20), Offset(25, 80), Offset.infinite, Offset(25, 20), Offset(75, 20), Offset(75, 80), Offset.infinite, Offset(25, 80), Offset(75, 80)], TracingCategory.hangul, hint: '세로, ㄱ, 가로 획순 ㅁ!'),
      ShapeDef('비읍 (ㅂ)', 'ㅂ', const [Offset(25, 20), Offset(25, 80), Offset.infinite, Offset(75, 20), Offset(75, 80), Offset.infinite, Offset(25, 50), Offset(75, 50), Offset.infinite, Offset(25, 80), Offset(75, 80)], TracingCategory.hangul, hint: '두 세로획 그리고 두 가로획 ㅂ!'),
      ShapeDef('시옷 (ㅅ)', 'ㅅ', const [Offset(50, 20), Offset(20, 80), Offset.infinite, Offset(45, 42), Offset(80, 80)], TracingCategory.hangul, hint: '왼쪽 빗금, 오른쪽 빗금 ㅅ!'),
      ShapeDef('이응 (ㅇ)', 'ㅇ', const [Offset(50, 20), Offset(35, 24), Offset(24, 35), Offset(20, 50), Offset(24, 65), Offset(35, 76), Offset(50, 80), Offset(65, 76), Offset(76, 65), Offset(80, 50), Offset(76, 35), Offset(65, 24), Offset(50, 20)], TracingCategory.hangul, hint: '둥글둥글 완벽한 동그라미 ㅇ!'),
      ShapeDef('지읒 (ㅈ)', 'ㅈ', const [Offset(20, 20), Offset(80, 20), Offset.infinite, Offset(50, 20), Offset(20, 80), Offset.infinite, Offset(45, 45), Offset(80, 80)], TracingCategory.hangul, hint: '가로 긋고 두 빗금 ㅈ!'),
      ShapeDef('치읓 (ㅊ)', 'ㅊ', const [Offset(35, 12), Offset(65, 12), Offset.infinite, Offset(20, 30), Offset(80, 30), Offset.infinite, Offset(50, 30), Offset(20, 88), Offset.infinite, Offset(45, 55), Offset(80, 88)], TracingCategory.hangul, hint: '꼭지점부터 차근차근 ㅊ!'),
      ShapeDef('키읔 (ㅋ)', 'ㅋ', const [Offset(20, 20), Offset(80, 20), Offset(80, 80), Offset.infinite, Offset(20, 48), Offset(80, 48)], TracingCategory.hangul, hint: 'ㄱ 그리고 가로획 ㅋ!'),
      ShapeDef('티읕 (ㅌ)', 'ㅌ', const [Offset(20, 20), Offset(80, 20), Offset.infinite, Offset(20, 50), Offset(80, 50), Offset.infinite, Offset(20, 20), Offset(20, 80), Offset(80, 80)], TracingCategory.hangul, hint: '위 가로, 중간 가로, ㄴ ㅌ!'),
      ShapeDef('피읖 (ㅍ)', 'ㅍ', const [Offset(20, 20), Offset(80, 20), Offset.infinite, Offset(36, 20), Offset(36, 80), Offset.infinite, Offset(64, 20), Offset(64, 80), Offset.infinite, Offset(20, 80), Offset(80, 80)], TracingCategory.hangul, hint: '위 가로, 두 세로, 아래 가로 ㅍ!'),
      ShapeDef('히읗 (ㅎ)', 'ㅎ', const [Offset(35, 12), Offset(65, 12), Offset.infinite, Offset(20, 30), Offset(80, 30), Offset.infinite, Offset(50, 45), Offset(36, 49), Offset(28, 65), Offset(36, 81), Offset(50, 85), Offset(64, 81), Offset(72, 65), Offset(64, 49), Offset(50, 45)], TracingCategory.hangul, hint: '꼭지, 가로, 둥근 이응 ㅎ!'),

      // 🔤 ALPHABET (곡선 매끄러운 알파벳)
      ShapeDef('글자 A', '🅰️', const [Offset(50, 10), Offset(15, 90), Offset.infinite, Offset(50, 10), Offset(85, 90), Offset.infinite, Offset(30, 60), Offset(70, 60)], TracingCategory.alphabet, hint: '멋진 글자 A!'),
      ShapeDef('글자 B', '🅱️', const [Offset(20, 10), Offset(20, 90), Offset.infinite, Offset(20, 10), Offset(45, 10), Offset(68, 18), Offset(72, 30), Offset(64, 42), Offset(45, 48), Offset(20, 48), Offset.infinite, Offset(20, 48), Offset(48, 48), Offset(74, 56), Offset(78, 70), Offset(70, 84), Offset(45, 90), Offset(20, 90)], TracingCategory.alphabet, hint: '볼록볼록 B!'),
      ShapeDef('글자 C', '🔤', const [Offset(82, 25), Offset(65, 14), Offset(40, 10), Offset(20, 25), Offset(12, 50), Offset(20, 75), Offset(40, 90), Offset(65, 86), Offset(82, 75)], TracingCategory.alphabet, hint: '둥글둥글 C!'),
      ShapeDef('글자 D', '🔤', const [Offset(20, 10), Offset(20, 90), Offset.infinite, Offset(20, 10), Offset(48, 10), Offset(75, 25), Offset(82, 50), Offset(75, 75), Offset(48, 90), Offset(20, 90)], TracingCategory.alphabet, hint: '볼록 D!'),
      ShapeDef('글자 O', '⭕', const [Offset(50, 10), Offset(34, 14), Offset(22, 32), Offset(18, 50), Offset(22, 68), Offset(34, 84), Offset(50, 88), Offset(66, 84), Offset(78, 68), Offset(82, 50), Offset(78, 32), Offset(66, 14), Offset(50, 10)], TracingCategory.alphabet, hint: '동그란 O!'),
      ShapeDef('글자 S', '🐍', const [Offset(80, 25), Offset(60, 12), Offset(30, 12), Offset(16, 25), Offset(20, 42), Offset(45, 50), Offset(75, 58), Offset(82, 75), Offset(68, 88), Offset(35, 90), Offset(18, 80)], TracingCategory.alphabet, hint: '뱀처럼 구불구불 S!'),

      // 🎨 PICTURES (매끄러운 곡선 그림)
      ShapeDef('씽씽 자동차', '🚗', const [Offset(10, 65), Offset(10, 45), Offset(30, 45), Offset(40, 20), Offset(70, 20), Offset(85, 45), Offset(95, 45), Offset(95, 65), Offset(10, 65)], TracingCategory.objects, hint: '부릉부릉 자동차!'),
      ShapeDef('우주선 🚀', '🚀', const [Offset(50, 10), Offset(70, 40), Offset(70, 80), Offset(50, 90), Offset(30, 80), Offset(30, 40), Offset(50, 10)], TracingCategory.objects, hint: '우주로 슝 🚀'),
      ShapeDef('달콤한 사과', '🍎', const [Offset(50, 25), Offset(40, 15), Offset(25, 20), Offset(12, 40), Offset(10, 60), Offset(25, 82), Offset(42, 88), Offset(50, 84), Offset(58, 88), Offset(75, 82), Offset(90, 60), Offset(88, 40), Offset(75, 20), Offset(60, 15), Offset(50, 25)], TracingCategory.objects, hint: '탐스러운 사과 🍎'),
      ShapeDef('귀여운 고양이', '🐱', const [Offset(20, 25), Offset(32, 42), Offset(68, 42), Offset(80, 25), Offset(90, 55), Offset(80, 78), Offset(50, 88), Offset(20, 78), Offset(10, 55), Offset(20, 25)], TracingCategory.objects, hint: '동글동글 고양이 🐱'),
      ShapeDef('달콤 아이스크림', '🍦', const [Offset(50, 10), Offset(35, 18), Offset(22, 32), Offset(26, 48), Offset(40, 52), Offset(60, 52), Offset(74, 48), Offset(78, 32), Offset(65, 18), Offset(50, 10), Offset.infinite, Offset(24, 50), Offset(50, 94), Offset(76, 50)], TracingCategory.objects, hint: '시원한 아이스크림!'),
      ShapeDef('신나는 풍선', '🎈', const [Offset(50, 10), Offset(34, 16), Offset(20, 32), Offset(16, 50), Offset(24, 68), Offset(40, 76), Offset(50, 88), Offset(60, 76), Offset(76, 68), Offset(84, 50), Offset(80, 32), Offset(66, 16), Offset(50, 10)], TracingCategory.objects, hint: '동글동글 풍선!'),
    ];
  }

  void _updateFilteredShapes() {
    _filteredShapes = _allShapes.where((s) => s.category == _selectedCategory).toList();
    _categoryIndex = 0;
    _resetLevelState();
  }

  void _resetLevelState() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    _confettiController.stop();
    _userStrokes.clear();
    _strokeCoveredCheckpoints.clear();
    _isLevelClear = false;
    _popStars.clear();
    _mascotMessage = _currentShape.hint.isNotEmpty ? _currentShape.hint : '라인을 따라 꼼꼼하게 쓱쓱 그려봐! ✨';
  }

  ShapeDef get _currentShape {
    if (_filteredShapes.isEmpty) return _allShapes.first;
    return _filteredShapes[_categoryIndex % _filteredShapes.length];
  }

  List<Offset> _getScaledPoints(Size size) {
    final shape = _currentShape;
    final scaleX = size.width / 130;
    final scaleY = size.height / 130;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - 100 * scale) / 2;
    final offsetY = (size.height - 100 * scale) / 2 + 20;

    return shape.points.map((p) {
      if (p == Offset.infinite) return Offset.infinite;
      return Offset(p.dx * scale + offsetX, p.dy * scale + offsetY);
    }).toList();
  }

  void _spawnTouchParticles(Offset pos) {
    final colors = [
      Colors.amber,
      Colors.pinkAccent,
      Colors.lightBlueAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
    ];

    int count = _selectedBrush == MagicBrushType.sparkle ? 4 : 2;

    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * pi * 2;
      double speed = _random.nextDouble() * 3 + 1.5;
      Color c = colors[_random.nextInt(colors.length)];

      if (_selectedBrush == MagicBrushType.rainbow) {
        c = HSVColor.fromAHSV(1.0, (_hueTime * 50) % 360, 0.9, 0.95).toColor();
      } else if (_selectedBrush == MagicBrushType.comet) {
        c = i % 2 == 0 ? Colors.cyanAccent : Colors.pinkAccent;
      } else if (_selectedBrush == MagicBrushType.bubble) {
        c = Colors.lightBlue.withValues(alpha: 0.8);
      }

      _particles.add(TouchParticle(
        position: pos,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: c,
        size: _selectedBrush == MagicBrushType.bubble ? _random.nextDouble() * 12 + 8 : _random.nextDouble() * 8 + 4,
        char: _selectedBrush == MagicBrushType.sparkle ? '✨' : null,
      ));
    }
  }

  bool _hitTest(Offset p1, Offset p2, Offset target, double radius) {
    if ((p2 - target).distance < radius) return true;
    int steps = ((p1 - p2).distance / 15).ceil();
    for (int i = 1; i <= steps; i++) {
      Offset p = Offset.lerp(p1, p2, i / steps)!;
      if ((p - target).distance < radius) return true;
    }
    return false;
  }

  List<List<Offset>> _getDenseCheckpointsByStroke(List<Offset> points, Rect? circleRect) {
    if (circleRect != null) {
      final center = circleRect.center;
      final rx = circleRect.width / 2;
      final ry = circleRect.height / 2;
      const int steps = 48;
      List<Offset> circlePoints = [];
      for (int i = 0; i < steps; i++) {
        final angle = i * 2 * pi / steps;
        circlePoints.add(Offset(center.dx + rx * cos(angle), center.dy + ry * sin(angle)));
      }
      return [circlePoints];
    }

    List<List<Offset>> rawStrokes = [];
    List<Offset> current = [];
    for (var p in points) {
      if (p == Offset.infinite) {
        if (current.isNotEmpty) {
          rawStrokes.add(List.from(current));
          current.clear();
        }
      } else {
        current.add(p);
      }
    }
    if (current.isNotEmpty) rawStrokes.add(current);

    List<List<Offset>> strokeCheckpoints = [];
    for (var stroke in rawStrokes) {
      if (stroke.isEmpty) continue;
      List<Offset> cps = [];
      if (stroke.length == 1) {
        cps.add(stroke[0]);
      } else {
        for (int i = 0; i < stroke.length - 1; i++) {
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final dist = (p2 - p1).distance;
          int steps = max(1, (dist / 8.0).ceil());
          for (int s = 0; s < steps; s++) {
            cps.add(Offset.lerp(p1, p2, s / steps)!);
          }
        }
        cps.add(stroke.last);
      }
      if (cps.isNotEmpty) {
        strokeCheckpoints.add(cps);
      }
    }
    return strokeCheckpoints;
  }

  void _checkCoverage(Offset p1, Offset p2, List<List<Offset>> strokes, Size size) {
    const double hitRadius = 24.0; // 외곽선 두께(38px)에 맞춘 정확한 반경
    bool newlyAdded = false;

    for (int s = 0; s < strokes.length; s++) {
      final strokePoints = strokes[s];
      _strokeCoveredCheckpoints.putIfAbsent(s, () => <int>{});
      final coveredSet = _strokeCoveredCheckpoints[s]!;

      for (int i = 0; i < strokePoints.length; i++) {
        if (coveredSet.contains(i)) continue;
        if (_hitTest(p1, p2, strokePoints[i], hitRadius)) {
          coveredSet.add(i);
          newlyAdded = true;
        }
      }
    }



    int totalCheckpoints = 0;
    int totalCovered = 0;
    bool allStrokesSufficient = true;

    for (int s = 0; s < strokes.length; s++) {
      final strokeLen = strokes[s].length;
      final coveredLen = _strokeCoveredCheckpoints[s]?.length ?? 0;
      totalCheckpoints += strokeLen;
      totalCovered += coveredLen;

      // 모든 획이 각각 최소 90% 이상 끝까지 칠해져야 인정
      if (strokeLen > 0 && (coveredLen / strokeLen) < 0.90) {
        allStrokesSufficient = false;
      }
    }

    if (totalCheckpoints == 0) return;
    final double overallProgress = totalCovered / totalCheckpoints;

    // 모든 획 각각 90% 이상 & 전체 외곽선 95% 이상 끝까지 꽉 채웠을 때만 완성 연출 발동!
    if (allStrokesSufficient && overallProgress >= 0.95) {
      _onStageCompleted(size);
    } else if (newlyAdded) {
      final double pitch = (1.0 + overallProgress * 0.9).clamp(1.0, 2.0);
      _playBrushSound(pitch);
      HapticFeedback.selectionClick();

      if (totalCovered % 12 == 0) {
        final cheerMsgs = ['우와! 잘 그리고 있어! 🌈', '멋져 멋져! ✨', '끝까지 쓱쓱! 🎨', '우아 참 잘해요! 🐥'];
        _triggerMascotCheer(cheerMsgs[_random.nextInt(cheerMsgs.length)]);
      }
    }
  }

  DateTime _lastBrushSoundTime = DateTime.now().subtract(const Duration(seconds: 1));

  void _playBrushSound(double pitch) {
    // 완성 상태에서는 축하 팡파레가 웅장하게 들리도록 드로잉 소리를 잠시 차단
    if (_isLevelClear) return;
    final now = DateTime.now();
    if (now.difference(_lastBrushSoundTime).inMilliseconds < 100) return;
    _lastBrushSoundTime = now;
    AudioManager.instance.playTraceBrush(_selectedBrush.name, rate: pitch);
  }

  void _onStageCompleted(Size size) {
    if (_isLevelClear) return;
    setState(() {
      _isLevelClear = true;
      _mascotMessage = '🎉 ${_currentShape.name} 정말 멋지게 완성했어! 최고야! 🌟';
    });

    _confettiController.play();
    AudioManager.instance.playTraceSuccess();
    HapticFeedback.heavyImpact();
    PlayerDataManager.instance.addStarCoin(1);

    _livingObjectController.forward(from: 0.0);

    // 사방으로 퍼지는 화려한 축하 별가루 파티클
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 25; i++) {
      _spawnTouchParticles(center + Offset((_random.nextDouble() - 0.5) * 160, (_random.nextDouble() - 0.5) * 160));
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final points = _getScaledPoints(size);
    if (points.isEmpty) return;
    final circleRect = _getScaledCircleRect(size);

    final touchPos = details.localPosition;
    _userStrokes.add(DrawnStroke(
      points: [touchPos],
      brushType: _selectedBrush,
    ));
    _playBrushSound(1.0);
    _spawnTouchParticles(touchPos);

    if (!_isLevelClear) {
      final strokes = _getDenseCheckpointsByStroke(points, circleRect);
      _checkCoverage(touchPos, touchPos, strokes, size);
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_userStrokes.isEmpty) return;

    final points = _getScaledPoints(size);
    if (points.isEmpty) return;
    final circleRect = _getScaledCircleRect(size);

    final currentPos = details.localPosition;
    final currentStroke = _userStrokes.last;
    final prevPos = currentStroke.points.isNotEmpty ? currentStroke.points.last : currentPos;

    currentStroke.points.add(currentPos);
    _spawnTouchParticles(currentPos);

    if (!_isLevelClear) {
      final strokes = _getDenseCheckpointsByStroke(points, circleRect);
      _checkCoverage(prevPos, currentPos, strokes, size);
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    // Current stroke is complete
  }

  void _triggerMascotCheer(String text) {
    _mascotMessage = text;
    _mascotBounceController.forward(from: 0.0);
  }

  void _popRewardStar(PopStar star) {
    if (star.popped) return;
    setState(() {
      star.popped = true;
    });
    AudioManager.instance.playPop();
    HapticFeedback.lightImpact();
  }

  void _nextLevel() {
    setState(() {
      _categoryIndex++;
      _resetLevelState();
    });
  }

  void _prevLevel() {
    setState(() {
      if (_categoryIndex > 0) {
        _categoryIndex--;
      } else {
        _categoryIndex = _filteredShapes.length - 1;
      }
      _resetLevelState();
    });
  }

  Rect? _getScaledCircleRect(Size size) {
    final shape = _currentShape;
    if (shape.circleRect == null) return null;
    final scaleX = size.width / 130;
    final scaleY = size.height / 130;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - 100 * scale) / 2;
    final offsetY = (size.height - 100 * scale) / 2 + 20;

    final r = shape.circleRect!;
    return Rect.fromLTRB(
      r.left * scale + offsetX,
      r.top * scale + offsetY,
      r.right * scale + offsetX,
      r.bottom * scale + offsetY,
    );
  }

  // --- BUILD METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic themed gradient background
          _buildBackground(),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar (Header)
                _buildHeader(),

                // Category Selector Bar
                _buildCategoryBar(),

                // Main Drawing Stage Canvas
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      final points = _getScaledPoints(size);
                      final circleRect = _getScaledCircleRect(size);

                      return Stack(
                        children: [
                          // Background Grid
                          CustomPaint(
                            painter: GridBackgroundPainter(isSpace: _selectedCategory == TracingCategory.objects),
                            child: const SizedBox.expand(),
                          ),

                          // Guide Line (Grey outline + dashes)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TracingOutlinePainter(
                                points: points,
                                isCurved: _currentShape.isCurved,
                                isCircle: _currentShape.isCircle,
                                circleRect: circleRect,
                              ),
                            ),
                          ),

                          // User Trace Drawing Canvas
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: (d) => _onPanStart(d, size),
                              onPanUpdate: (d) => _onPanUpdate(d, size),
                              onPanEnd: _onPanEnd,
                              child: CustomPaint(
                                painter: TracingPathPainter(
                                  strokes: _userStrokes,
                                  hueTime: _hueTime,
                                  isCurved: _currentShape.isCurved,
                                  isCircle: _currentShape.isCircle,
                                ),
                              ),
                            ),
                          ),

                          // Touch & Drag Magic Particle Painter
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ParticlePainter(particles: _particles),
                              ),
                            ),
                          ),

                          // 하단 네비게이션 버튼 바 (평소 드로잉 중)
                          if (!_isLevelClear)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // ◀ 이전 단계 버튼
                                  _buildNavPillButton(
                                    label: '이전',
                                    icon: Icons.arrow_back_rounded,
                                    color: const Color(0xFFFF9F1C),
                                    onTap: _prevLevel,
                                  ),

                                  // 다음 단계 ➡️ 버튼
                                  _buildNavPillButton(
                                    label: '다음',
                                    icon: Icons.arrow_forward_rounded,
                                    color: const Color(0xFF10B981),
                                    isForward: true,
                                    onTap: _nextLevel,
                                  ),
                                ],
                              ),
                            ),

                          // 🎉 완성 시: 상단 칭찬 배지 (터치 통과되어 계속 그리기 가능!) & 하단 액션 바
                          if (_isLevelClear) ...[
                            // 화려한 축하 폭죽 컨페티
                            Align(
                              alignment: Alignment.topCenter,
                              child: IgnorePointer(
                                child: ConfettiWidget(
                                  confettiController: _confettiController,
                                  blastDirectionality: BlastDirectionality.explosive,
                                  shouldLoop: false,
                                  numberOfParticles: 40,
                                  gravity: 0.18,
                                  emissionFrequency: 0.05,
                                  colors: const [
                                    Colors.pinkAccent,
                                    Colors.amber,
                                    Colors.cyanAccent,
                                    Colors.purpleAccent,
                                    Colors.greenAccent,
                                    Colors.orangeAccent,
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 20,
                              right: 20,
                              child: IgnorePointer(
                                child: _buildCelebrationBadge(),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: _buildCelebrationBottomBar(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),

                // Magic Brush Tool Selector at Bottom
                _buildBrushSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    List<Color> gradientColors;

    switch (_selectedCategory) {
      case TracingCategory.shapes:
        gradientColors = [const Color(0xFFFFF9E6), const Color(0xFFFFECC8), const Color(0xFFFFD89E)];
        break;
      case TracingCategory.numbers:
        gradientColors = [const Color(0xFFE8FDF5), const Color(0xFFC4F5E5), const Color(0xFFA2ECD5)];
        break;
      case TracingCategory.hangul:
        gradientColors = [const Color(0xFFF0F7FF), const Color(0xFFD6EBFF), const Color(0xFFBCE0FD)];
        break;
      case TracingCategory.alphabet:
        gradientColors = [const Color(0xFFFDF0FF), const Color(0xFFF2D6FF), const Color(0xFFE3B8FE)];
        break;
      case TracingCategory.objects:
        gradientColors = [const Color(0xFF231742), const Color(0xFF1B1832), const Color(0xFF0F172A)];
        break;
    }

    return Stack(
      children: [
        // Gradient sky background
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Live Animated Drifting Clouds, Twinkling Stars & Floating Magic Bubbles!
        Positioned.fill(
          child: CustomPaint(
            painter: CuteBackgroundParticlePainter(
              hueTime: _hueTime,
              category: _selectedCategory,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: KidsTheme.softShadows,
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: KidsTheme.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KidsTheme.red.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, color: KidsTheme.red, size: 18),
                  const SizedBox(width: 4),
                  Text('나가기', style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.red)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Emoji
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_currentShape.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currentShape.name,
                        style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.textDark),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Reset/Clear Button
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() {
                _resetLevelState();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text('다시 쓰기', style: GoogleFonts.jua(fontSize: 14, color: Colors.orange.shade800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: TracingCategory.values.length,
        itemBuilder: (context, index) {
          final cat = TracingCategory.values[index];
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() {
                _selectedCategory = cat;
                _updateFilteredShapes();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(24),
                boxShadow: isSelected ? KidsTheme.softShadows : [],
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(cat.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: GoogleFonts.jua(
                      fontSize: 15,
                      color: isSelected ? Colors.white : KidsTheme.textDark,
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

  Widget _buildBrushSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MagicBrushType.values.map((brush) {
            final isSelected = brush == _selectedBrush;
            return GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                setState(() {
                  _selectedBrush = brush;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? brush.color.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? brush.color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(brush.icon, color: brush.color, size: isSelected ? 24 : 20),
                    const SizedBox(height: 2),
                    Text(
                      brush.label,
                      style: GoogleFonts.jua(
                        fontSize: 11,
                        color: isSelected ? KidsTheme.textDark : Colors.grey.shade600,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCelebrationBadge() {
    return AnimatedBuilder(
      animation: _livingObjectController,
      builder: (context, child) {
        final val = _livingObjectController.value;
        final emoji = _currentShape.emoji;

        double scale = 1.0 + (sin(val * pi * 3) * 0.16);
        double rotate = sin(val * pi * 4) * 0.10;

        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD166), Color(0xFFFF9F1C)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: rotate,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '🎉 참 잘했어요! ${_currentShape.name} 완성! 🎉',
                  style: GoogleFonts.jua(
                    fontSize: 18,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCelebrationBottomBar() {
    return Row(
      children: [
        // 다시 쓰기 버튼
        GestureDetector(
          onTap: () {
            AudioManager.instance.playClick();
            setState(() {
              _resetLevelState();
            });
          },
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade400, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, color: Colors.orange.shade800, size: 20),
                const SizedBox(width: 4),
                Text('다시 쓰기', style: GoogleFonts.jua(fontSize: 16, color: Colors.orange.shade800)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 커다란 다음 단계로 가기 버튼
        Expanded(
          child: GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _nextLevel();
            },
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '다음 단계로 가기! ➡️',
                      style: GoogleFonts.jua(
                        fontSize: 18,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
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
    );
  }

  Widget _buildPopStarWidget(PopStar star) {
    if (star.popped) return const SizedBox.shrink();

    return Positioned(
      left: star.position.dx - 25,
      top: star.position.dy - 25,
      child: GestureDetector(
        onTap: () => _popRewardStar(star),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.15),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: star.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: star.color.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⭐', style: TextStyle(fontSize: 28)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMascotWidget() {
    return AnimatedBuilder(
      animation: _mascotBounceController,
      builder: (context, child) {
        final bounce = sin(_mascotBounceController.value * pi) * 8;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Speech bubble
              Container(
                constraints: const BoxConstraints(maxWidth: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 24, right: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: KidsTheme.softShadows,
                ),
                child: Text(
                  _mascotMessage,
                  style: GoogleFonts.jua(fontSize: 13, color: KidsTheme.textDark),
                ),
              ),

              // Cute Bird Mascot Emoji
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: const Text('🐥', style: TextStyle(fontSize: 32)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavPillButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isForward = false,
  }) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.8), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isForward
              ? [
                  Text(label, style: GoogleFonts.jua(fontSize: 16, color: color)),
                  const SizedBox(width: 4),
                  Icon(icon, color: color, size: 20),
                ]
              : [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 4),
                  Text(label, style: GoogleFonts.jua(fontSize: 16, color: color)),
                ],
        ),
      ),
    );
  }


}

// --- CUSTOM PAINTERS ---

// --- DYNAMIC CUTE BACKGROUND PAINTER ---

class CuteBackgroundParticlePainter extends CustomPainter {
  final double hueTime;
  final TracingCategory category;

  CuteBackgroundParticlePainter({required this.hueTime, required this.category});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);

    // 1. Floating Clouds & Cute Shapes
    for (int i = 0; i < 7; i++) {
      final double baseX = (rand.nextDouble() * size.width);
      final double baseY = (rand.nextDouble() * size.height);
      final double speed = 12.0 + (i * 4.0);
      final double x = (baseX + hueTime * speed) % (size.width + 120) - 60;
      final double y = baseY + sin(hueTime * 1.5 + i) * 14.0;
      final double cloudScale = 0.7 + (i % 3) * 0.25;

      final cloudPaint = Paint()
        ..color = category == TracingCategory.objects
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;

      // Draw cute puffy cloud
      canvas.drawCircle(Offset(x, y), 22 * cloudScale, cloudPaint);
      canvas.drawCircle(Offset(x - 16 * cloudScale, y + 4 * cloudScale), 16 * cloudScale, cloudPaint);
      canvas.drawCircle(Offset(x + 16 * cloudScale, y + 4 * cloudScale), 16 * cloudScale, cloudPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y + 8 * cloudScale), width: 44 * cloudScale, height: 16 * cloudScale),
          Radius.circular(8 * cloudScale),
        ),
        cloudPaint,
      );
    }

    // 2. Twinkling & Floating Stars / Sparkles
    for (int i = 0; i < 14; i++) {
      final double x = (rand.nextDouble() * size.width + sin(hueTime + i) * 10) % size.width;
      final double y = (rand.nextDouble() * size.height + cos(hueTime + i * 2) * 10) % size.height;
      final double pulse = 0.5 + 0.5 * sin(hueTime * 3.0 + i * 1.5);
      final double starSize = (3.0 + (i % 4) * 2.0) * (0.6 + pulse * 0.5);

      final starPaint = Paint()
        ..color = category == TracingCategory.objects
            ? Colors.amberAccent.withValues(alpha: 0.25 + pulse * 0.45)
            : (i % 2 == 0 ? Colors.amber : Colors.white).withValues(alpha: 0.3 + pulse * 0.4)
        ..style = PaintingStyle.fill;

      // Draw 4-point sparkle star
      final path = Path();
      path.moveTo(x, y - starSize);
      path.quadraticBezierTo(x, y, x + starSize, y);
      path.quadraticBezierTo(x, y, x, y + starSize);
      path.quadraticBezierTo(x, y, x - starSize, y);
      path.quadraticBezierTo(x, y, x, y - starSize);
      canvas.drawPath(path, starPaint);
    }

    // 3. Floating Colorful Bubbles
    for (int i = 0; i < 10; i++) {
      final double baseX = (rand.nextDouble() * size.width);
      final double baseY = (rand.nextDouble() * size.height);
      final double y = (baseY - hueTime * (18.0 + (i % 3) * 6)) % (size.height + 40) - 20;
      final double x = baseX + sin(hueTime * 2.0 + i) * 16.0;
      final double bubbleRadius = 8.0 + (i % 5) * 4.0;

      final bubblePaint = Paint()
        ..color = [
          Colors.pinkAccent,
          Colors.lightBlueAccent,
          Colors.amberAccent,
          Colors.purpleAccent,
          Colors.tealAccent,
        ][i % 5].withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(x, y), bubbleRadius, bubblePaint);

      // Bubble highlight shine
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x - bubbleRadius * 0.35, y - bubbleRadius * 0.35), bubbleRadius * 0.25, shinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CuteBackgroundParticlePainter oldDelegate) => true;
}

class GridBackgroundPainter extends CustomPainter {
  final bool isSpace;
  GridBackgroundPainter({required this.isSpace});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft sketchbook page background with smooth glow
    final bgPaint = Paint()
      ..color = isSpace ? const Color(0xFF1E1530).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      const Radius.circular(28),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Dotted gentle grid for neat drawing guidance
    final dotPaint = Paint()
      ..color = isSpace ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF94A3B8).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    const double step = 28.0;
    for (double y = 28; y < size.height - 16; y += step) {
      for (double x = 28; x < size.width - 16; x += step) {
        canvas.drawCircle(Offset(x, y), 1.8, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TracingOutlinePainter extends CustomPainter {
  final List<Offset> points;
  final bool isCurved;
  final bool isCircle;
  final Rect? circleRect;

  TracingOutlinePainter({
    required this.points,
    this.isCurved = false,
    this.isCircle = false,
    this.circleRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty && circleRect == null) return;

    final outlinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isCircle && circleRect != null) {
      // 100% 수학적으로 완벽한 파펙트 진짜 원형 렌더링!
      path.addOval(circleRect!);
    } else {
      List<List<Offset>> strokes = [];
      List<Offset> currentStroke = [];
      for (var p in points) {
        if (p == Offset.infinite) {
          if (currentStroke.isNotEmpty) {
            strokes.add(List.from(currentStroke));
            currentStroke.clear();
          }
        } else {
          currentStroke.add(p);
        }
      }
      if (currentStroke.isNotEmpty) {
        strokes.add(currentStroke);
      }

      for (var stroke in strokes) {
        if (stroke.isEmpty) continue;
        path.moveTo(stroke[0].dx, stroke[0].dy);
        if (stroke.length == 1) continue;

        if (stroke.length == 2 || !isCurved) {
          for (int i = 1; i < stroke.length; i++) {
            path.lineTo(stroke[i].dx, stroke[i].dy);
          }
        } else {
          // 100% 매끄러운 3D 베지어 곡선(Cubic Bezier Spline) 인터폴레이션!
          for (int i = 0; i < stroke.length - 1; i++) {
            final p0 = i > 0 ? stroke[i - 1] : stroke[i];
            final p1 = stroke[i];
            final p2 = stroke[i + 1];
            final p3 = i < stroke.length - 2 ? stroke[i + 2] : p2;

            final cp1 = Offset(
              p1.dx + (p2.dx - p0.dx) / 6,
              p1.dy + (p2.dy - p0.dy) / 6,
            );
            final cp2 = Offset(
              p2.dx - (p3.dx - p1.dx) / 6,
              p2.dy - (p3.dy - p1.dy) / 6,
            );

            path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
          }
        }
      }
    }

    canvas.drawPath(path, outlinePaint);

    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TracingPathPainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final double hueTime;
  final bool isCurved;
  final bool isCircle;

  TracingPathPainter({
    required this.strokes,
    required this.hueTime,
    this.isCurved = false,
    this.isCircle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    for (var drawnStroke in strokes) {
      final stroke = drawnStroke.points;
      if (stroke.isEmpty) continue;

      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);

      if (stroke.length == 1) {
        path.addOval(Rect.fromCircle(center: stroke[0], radius: 18));
      } else if (stroke.length == 2 || !isCurved) {
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
      } else {
        for (int i = 0; i < stroke.length - 1; i++) {
          final p0 = i > 0 ? stroke[i - 1] : stroke[i];
          final p1 = stroke[i];
          final p2 = stroke[i + 1];
          final p3 = i < stroke.length - 2 ? stroke[i + 2] : p2;

          final cp1 = Offset(
            p1.dx + (p2.dx - p0.dx) / 6,
            p1.dy + (p2.dy - p0.dy) / 6,
          );
          final cp2 = Offset(
            p2.dx - (p3.dx - p1.dx) / 6,
            p2.dy - (p3.dy - p1.dy) / 6,
          );

          path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
        }
      }

      Paint paint = Paint()
        ..strokeWidth = 36
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = stroke.length == 1 ? PaintingStyle.fill : PaintingStyle.stroke;

      switch (drawnStroke.brushType) {
        case MagicBrushType.rainbow:
          final hsv = HSVColor.fromAHSV(1.0, (hueTime * 60) % 360, 0.85, 0.95);
          paint.color = hsv.toColor();
          final aura = Paint()
            ..color = paint.color.withValues(alpha: 0.4)
            ..strokeWidth = 46
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = stroke.length == 1 ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawPath(path, aura);
          break;

        case MagicBrushType.sparkle:
          paint.color = Colors.amber;
          final aura = Paint()
            ..color = Colors.amberAccent.withValues(alpha: 0.35)
            ..strokeWidth = 44
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = stroke.length == 1 ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawPath(path, aura);
          break;

        case MagicBrushType.bubble:
          paint.color = Colors.cyan.shade300;
          final aura = Paint()
            ..color = Colors.lightBlueAccent.withValues(alpha: 0.35)
            ..strokeWidth = 44
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = stroke.length == 1 ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawPath(path, aura);
          break;

        case MagicBrushType.crayon:
          paint.color = Colors.deepOrangeAccent;
          paint.strokeWidth = 32;
          break;

        case MagicBrushType.comet:
          paint.color = Colors.pinkAccent;
          final glow = Paint()
            ..color = Colors.cyanAccent.withValues(alpha: 0.5)
            ..strokeWidth = 48
            ..strokeCap = StrokeCap.round
            ..style = stroke.length == 1 ? PaintingStyle.fill : PaintingStyle.stroke;
          canvas.drawPath(path, glow);
          break;
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ParticlePainter extends CustomPainter {
  final List<TouchParticle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha)
        ..style = PaintingStyle.fill;

      if (p.char != null) {
        final textPainter = TextPainter(
          text: TextSpan(text: p.char, style: TextStyle(fontSize: p.size * 2, color: p.color.withValues(alpha: p.alpha))),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, p.position);
      } else {
        canvas.drawCircle(p.position, p.size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
