import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

  ShapeDef(this.name, this.emoji, this.points, this.category, {this.hint = ''});
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

  int _score = 0;
  int _categoryIndex = 0;
  bool _isLevelClear = false;

  final List<Offset> _userPath = [];
  int _targetPointIndex = 0;
  bool _isReversed = false;

  late List<ShapeDef> _allShapes;
  late List<ShapeDef> _filteredShapes;

  // Particle Engine & Animation Timers
  final List<TouchParticle> _particles = [];
  final List<PopStar> _popStars = [];
  Timer? _tickerTimer;
  double _hueTime = 0.0;

  // Mascot Cheer State
  late AnimationController _mascotBounceController;
  String _mascotMessage = '손가락으로 라인을 따라 그려봐! ✨';
  final Random _random = Random();

  // Living Picture Animation
  late AnimationController _livingObjectController;

  @override
  void initState() {
    super.initState();
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
      ShapeDef('반짝이 별', '⭐', const [Offset(50, 10), Offset(75, 90), Offset(10, 40), Offset(90, 40), Offset(25, 90), Offset(50, 10)], TracingCategory.shapes, hint: '밤하늘의 예쁜 별!'),
      ShapeDef('예쁜 하트', '💛', const [Offset(50, 30), Offset(35, 10), Offset(15, 25), Offset(15, 50), Offset(50, 85), Offset(85, 50), Offset(85, 25), Offset(65, 10), Offset(50, 30)], TracingCategory.shapes, hint: '사랑스러운 하트!'),

      // 🔢 NUMBERS
      ShapeDef('숫자 1', '1️⃣', const [Offset(40, 25), Offset(50, 10), Offset(50, 90)], TracingCategory.numbers, hint: '위에서 아래로 1!'),
      ShapeDef('숫자 2', '2️⃣', const [Offset(20, 30), Offset(50, 10), Offset(80, 30), Offset(20, 85), Offset(85, 85)], TracingCategory.numbers, hint: '오리처럼 둥글게 2!'),
      ShapeDef('숫자 3', '3️⃣', const [Offset(20, 20), Offset(80, 20), Offset(50, 50), Offset(80, 75), Offset(20, 90)], TracingCategory.numbers, hint: '볼록볼록 3!'),
      ShapeDef('숫자 4', '4️⃣', const [Offset(70, 85), Offset(70, 10), Offset(20, 60), Offset(85, 60)], TracingCategory.numbers, hint: '돛단배 같은 4!'),
      ShapeDef('숫자 5', '5️⃣', const [Offset(80, 15), Offset(30, 15), Offset(25, 50), Offset(75, 60), Offset(30, 90)], TracingCategory.numbers, hint: '지붕 덮고 볼록 5!'),

      // 🇰🇷 HANGUL
      ShapeDef('기역 (ㄱ)', 'ㄱ', const [Offset(15, 20), Offset(85, 20), Offset(85, 85)], TracingCategory.hangul, hint: '옆으로 내려서 ㄱ!'),
      ShapeDef('니은 (ㄴ)', 'ㄴ', const [Offset(20, 15), Offset(20, 80), Offset(85, 80)], TracingCategory.hangul, hint: '아래로 옆으로 ㄴ!'),
      ShapeDef('디귿 (ㄷ)', 'ㄷ', const [Offset(85, 20), Offset(20, 20), Offset(20, 80), Offset(85, 80)], TracingCategory.hangul, hint: '디귿 완성해봐!'),
      ShapeDef('리을 (ㄹ)', 'ㄹ', const [Offset(20, 20), Offset(80, 20), Offset(80, 50), Offset(20, 50), Offset(20, 80), Offset(80, 80)], TracingCategory.hangul, hint: '구불구불 리을!'),
      ShapeDef('미음 (ㅁ)', 'ㅁ', const [Offset(25, 25), Offset(75, 25), Offset(75, 75), Offset(25, 75), Offset(25, 25)], TracingCategory.hangul, hint: '네모 박스 미음!'),
      ShapeDef('시옷 (ㅅ)', 'ㅅ', const [Offset(50, 15), Offset(15, 85), Offset(50, 50), Offset(85, 85)], TracingCategory.hangul, hint: '산처럼 솟은 시옷!'),

      // 🔤 ALPHABET
      ShapeDef('글자 A', '🅰️', const [Offset(15, 90), Offset(50, 10), Offset(85, 90), Offset(30, 60), Offset(70, 60)], TracingCategory.alphabet, hint: '멋진 글자 A!'),
      ShapeDef('글자 B', '🅱️', const [Offset(20, 10), Offset(20, 90), Offset(70, 30), Offset(20, 50), Offset(75, 70), Offset(20, 90)], TracingCategory.alphabet, hint: '볼록이 두개 B!'),
      ShapeDef('글자 C', '🔤', const [Offset(80, 25), Offset(40, 10), Offset(15, 50), Offset(40, 90), Offset(85, 75)], TracingCategory.alphabet, hint: '동그랗게 C!'),
      ShapeDef('글자 O', '⭕', const [Offset(50, 10), Offset(85, 50), Offset(50, 90), Offset(15, 50), Offset(50, 10)], TracingCategory.alphabet, hint: '동그란 공 O!'),
      ShapeDef('글자 S', '🐍', const [Offset(80, 25), Offset(30, 10), Offset(20, 45), Offset(80, 60), Offset(70, 90), Offset(20, 80)], TracingCategory.alphabet, hint: '뱀처럼 구불 S!'),

      // 🎨 PICTURES
      ShapeDef('씽씽 자동차', '🚗', const [Offset(10, 65), Offset(10, 45), Offset(30, 45), Offset(40, 20), Offset(70, 20), Offset(85, 45), Offset(95, 45), Offset(95, 65), Offset(10, 65)], TracingCategory.objects, hint: '부릉부릉 자동차!'),
      ShapeDef('우주선 🚀', '🚀', const [Offset(50, 10), Offset(70, 40), Offset(70, 80), Offset(50, 90), Offset(30, 80), Offset(30, 40), Offset(50, 10)], TracingCategory.objects, hint: '우주로 슝 🚀'),
      ShapeDef('달콤한 사과', '🍎', const [Offset(50, 30), Offset(75, 20), Offset(90, 50), Offset(70, 90), Offset(50, 80), Offset(30, 90), Offset(10, 50), Offset(25, 20), Offset(50, 30)], TracingCategory.objects, hint: '맛있는 사과 🍎'),
      ShapeDef('귀여운 고양이', '🐱', const [Offset(20, 20), Offset(35, 40), Offset(65, 40), Offset(80, 20), Offset(90, 60), Offset(50, 90), Offset(10, 60), Offset(20, 20)], TracingCategory.objects, hint: '야옹이 고양이 🐱'),
      ShapeDef('달콤 아이스크림', '🍦', const [Offset(50, 10), Offset(80, 35), Offset(70, 55), Offset(50, 95), Offset(30, 55), Offset(20, 35), Offset(50, 10)], TracingCategory.objects, hint: '시원한 아이스크림!'),
    ];
  }

  void _updateFilteredShapes() {
    _filteredShapes = _allShapes.where((s) => s.category == _selectedCategory).toList();
    _categoryIndex = 0;
    _resetLevelState();
  }

  void _resetLevelState() {
    _userPath.clear();
    _targetPointIndex = 0;
    _isReversed = false;
    _isLevelClear = false;
    _popStars.clear();
    _mascotMessage = _currentShape.hint.isNotEmpty ? _currentShape.hint : '라인을 따라 손가락을 쓱쓱!';
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

    return shape.points.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();
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

  void _onPanStart(DragStartDetails details, Size size) {
    if (_isLevelClear) return;
    final points = _getScaledPoints(size);
    if (points.isEmpty) return;

    if (_targetPointIndex == 0) {
      double distFirst = (details.localPosition - points.first).distance;
      double distLast = (details.localPosition - points.last).distance;

      if (distFirst < 50) {
        _isReversed = false;
        _userPath.add(points.first);
        _targetPointIndex = 1;
        AudioManager.instance.playTraceStart();
        _spawnTouchParticles(points.first);
        _triggerMascotCheer('시작이 좋아! 계속 그려봐! 🐥');
        setState(() {});
      } else if (distLast < 50) {
        _isReversed = true;
        _userPath.add(points.last);
        _targetPointIndex = 1;
        AudioManager.instance.playTraceStart();
        _spawnTouchParticles(points.last);
        _triggerMascotCheer('반대쪽에서 시작! 멋져! 🌟');
        setState(() {});
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_isLevelClear || _userPath.isEmpty) return;

    final points = _getScaledPoints(size);
    if (points.isEmpty) return;

    final currentPos = details.localPosition;
    _userPath.add(currentPos);
    _spawnTouchParticles(currentPos);

    if (_targetPointIndex < points.length) {
      int actualTargetIndex = _isReversed ? (points.length - 1 - _targetPointIndex) : _targetPointIndex;
      Offset prevPos = _userPath.length > 1 ? _userPath[_userPath.length - 2] : currentPos;
      
      // Precision radius (45.0) so completion requires drawing all the way to the end point!
      double hitRadius = 45.0;
      bool hitActual = _hitTest(prevPos, currentPos, points[actualTargetIndex], hitRadius);

      bool isClosed = (points.first - points.last).distance < 15;
      bool hitAlt = false;

      if (!hitActual && isClosed && _targetPointIndex == 1) {
        int altIndex = _isReversed ? 1 : (points.length - 2);
        if (_hitTest(prevPos, currentPos, points[altIndex], hitRadius)) {
          hitAlt = true;
          _isReversed = !_isReversed;
        }
      }

      if (hitActual || hitAlt) {
        _targetPointIndex++;
        double pitch = 1.0 + (_targetPointIndex * 0.12);
        if (pitch > 2.0) pitch = 2.0;
        AudioManager.instance.playTraceDraw(rate: pitch);
        HapticFeedback.selectionClick();

        // Random mascot cheers
        final cheerMsgs = ['우와! 최고야! 🌈', '거의 다 그려가! 🔥', '멋져 멋져! ✨', '우아 참 잘해요! 🐥'];
        _triggerMascotCheer(cheerMsgs[_random.nextInt(cheerMsgs.length)]);

        if (_targetPointIndex >= points.length) {
          _onStageCompleted(size);
        }
      }
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isLevelClear) {
      _userPath.clear();
      _targetPointIndex = 0;
      _isReversed = false;
      _triggerMascotCheer('아쉬워요! 별 위치부터 다시 해볼까? 😊');
      setState(() {});
    }
  }

  void _onStageCompleted(Size size) {
    AudioManager.instance.playTraceSuccess();
    AudioManager.instance.playEmojiSound(_currentShape.emoji);
    HapticFeedback.heavyImpact();

    // Give 1 Global Star Coin for the Gacha Shop!
    PlayerDataManager.instance.addStarCoin(1);

    // Spawn 5 pop stars for interactive reward popping
    _popStars.clear();
    for (int i = 0; i < 5; i++) {
      _popStars.add(PopStar(
        position: Offset(
          _random.nextDouble() * (size.width - 100) + 50,
          _random.nextDouble() * (size.height * 0.4) + size.height * 0.3,
        ),
        color: KidsTheme.getRandomColor(),
      ));
    }

    _livingObjectController.forward(from: 0.0);

    setState(() {
      _isLevelClear = true;
      _score += 20;
      _mascotMessage = '우와! ${_currentShape.name} 완공 축하해! 🌟🎉';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _isLevelClear) {
        _nextLevel();
      }
    });
  }

  void _triggerMascotCheer(String text) {
    _mascotMessage = text;
    _mascotBounceController.forward(from: 0.0);
  }

  void _popRewardStar(PopStar star) {
    if (star.popped) return;
    setState(() {
      star.popped = true;
      _score += 5;
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
                              painter: TracingOutlinePainter(points: points),
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
                                  pathPoints: _userPath,
                                  brushType: _selectedBrush,
                                  hueTime: _hueTime,
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

                          // Guided Pulse Marker on Target Point (shows children where to touch!)
                          if (!_isLevelClear && points.isNotEmpty) _buildGuidedPulseMarker(points),

                          // Interactive Living Picture Animation on Stage Clear!
                          if (_isLevelClear) _buildLivingPictureAnimation(size),

                          // Floating Pop Stars Reward
                          if (_isLevelClear) ..._popStars.map((star) => _buildPopStarWidget(star)),

                          // Cheering Mascot at Bottom Right
                          Positioned(
                            bottom: 12,
                            right: 16,
                            child: _buildMascotWidget(),
                          ),

                          // Next / Prev Stage Buttons
                          Positioned(
                            left: 12,
                            bottom: 16,
                            child: Row(
                              children: [
                                _buildCircleBtn(
                                  icon: Icons.arrow_back_rounded,
                                  color: Colors.orange,
                                  onTap: _prevLevel,
                                ),
                                const SizedBox(width: 8),
                                _buildCircleBtn(
                                  icon: Icons.arrow_forward_rounded,
                                  color: Colors.green,
                                  onTap: _nextLevel,
                                ),
                              ],
                            ),
                          ),
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
    Color topColor;
    Color bottomColor;

    switch (_selectedCategory) {
      case TracingCategory.shapes:
        topColor = const Color(0xFFFFF3E0);
        bottomColor = const Color(0xFFFFE0B2);
        break;
      case TracingCategory.numbers:
        topColor = const Color(0xFFE8F5E9);
        bottomColor = const Color(0xFFA5D6A7);
        break;
      case TracingCategory.hangul:
        topColor = const Color(0xFFE0F7FA);
        bottomColor = const Color(0xFF80DEEA);
        break;
      case TracingCategory.alphabet:
        topColor = const Color(0xFFF3E5F5);
        bottomColor = const Color(0xFFCE93D8);
        break;
      case TracingCategory.objects:
        topColor = const Color(0xFF1A1C2E);
        bottomColor = const Color(0xFF373B5E);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topColor, bottomColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_currentShape.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  _currentShape.name,
                  style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                ),
              ],
            ),
          ),

          // Star score counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade300, width: 2),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '$_score',
                  style: GoogleFonts.jua(fontSize: 18, color: Colors.amber.shade900),
                ),
              ],
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

  Widget _buildGuidedPulseMarker(List<Offset> points) {
    Offset target;
    if (_targetPointIndex == 0) {
      target = points.first;
    } else if (_targetPointIndex < points.length) {
      int actualIdx = _isReversed ? (points.length - 1 - _targetPointIndex) : _targetPointIndex;
      target = points[actualIdx];
    } else {
      target = points.last;
    }

    return Positioned(
      left: target.dx - 30,
      top: target.dy - 30,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1.25),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.3),
                  border: Border.all(color: Colors.amber, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👉', style: TextStyle(fontSize: 28)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLivingPictureAnimation(Size size) {
    return AnimatedBuilder(
      animation: _livingObjectController,
      builder: (context, child) {
        final val = _livingObjectController.value;
        final emoji = _currentShape.emoji;

        // Custom animation based on emoji object
        double dx = size.width / 2 - 50;
        double dy = size.height / 2 - 50;
        double scale = 1.0 + (sin(val * pi * 3) * 0.3);
        double rotate = 0.0;

        if (emoji == '🚗') {
          dx = -100 + (val * (size.width + 200));
          dy = size.height * 0.5;
        } else if (emoji == '🚀') {
          dy = (size.height * 0.7) - (val * (size.height * 0.8));
          dx = size.width * 0.5 - 50;
        } else if (emoji == '🐱' || emoji == '🐻') {
          rotate = sin(val * pi * 4) * 0.25;
        }

        return Stack(
          children: [
            // Floating Living Emoji
            Positioned(
              left: dx,
              top: dy,
              child: Transform.rotate(
                angle: rotate,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 70)),
                  ),
                ),
              ),
            ),

            // Congratulations Toast
            Center(
              child: GestureDetector(
                onTap: () {
                  if (_isLevelClear) _nextLevel();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: KidsTheme.toyDecoration(
                    color: KidsTheme.green,
                    borderRadius: 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '참 잘했어요! 🌟',
                        style: GoogleFonts.jua(fontSize: 38, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              AudioManager.instance.playClick();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 4),
                                  Text('나가기 🏠', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (_isLevelClear) _nextLevel();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade400,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_forward_rounded, color: KidsTheme.textDark, size: 18),
                                  const SizedBox(width: 4),
                                  Text('다음 단계 ⚡', style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

  Widget _buildCircleBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: KidsTheme.softShadows,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

// --- CUSTOM PAINTERS ---

class GridBackgroundPainter extends CustomPainter {
  final bool isSpace;
  GridBackgroundPainter({required this.isSpace});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSpace ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double step = 32.0;
    for (double y = 40; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 32; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TracingOutlinePainter extends CustomPainter {
  final List<Offset> points;
  TracingOutlinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final outlinePaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
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
  final List<Offset> pathPoints;
  final MagicBrushType brushType;
  final double hueTime;

  TracingPathPainter({
    required this.pathPoints,
    required this.brushType,
    required this.hueTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.isEmpty) return;

    final path = Path();
    path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
    for (int i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
    }

    Paint paint = Paint()
      ..strokeWidth = 36
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (brushType) {
      case MagicBrushType.rainbow:
        final hsv = HSVColor.fromAHSV(1.0, (hueTime * 60) % 360, 0.85, 0.95);
        paint.color = hsv.toColor();
        // Glowing aura
        final aura = Paint()
          ..color = paint.color.withValues(alpha: 0.4)
          ..strokeWidth = 46
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, aura);
        break;

      case MagicBrushType.sparkle:
        paint.color = Colors.amber;
        break;

      case MagicBrushType.bubble:
        paint.color = Colors.cyan.shade300;
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
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, glow);
        break;
    }

    canvas.drawPath(path, paint);
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
