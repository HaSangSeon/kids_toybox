import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ── 브러시 모드 ──────────────────────────────────────────────────────────────
enum BrushMode { normal, rainbow, stamp, eraser }

// ── 도안 템플릿 종류 ────────────────────────────────────────────────────────
enum DecalTemplate {
  free('자유', '🎨', '나만의 멋진 작품!'),
  butterfly('나비', '🦋', '알록달록 예쁜 나비 완성!'),
  flower('꽃', '🌸', '향기로운 꽃 완성!'),
  crown('왕관', '👑', '반짝반짝 왕관 완성!'),
  rocket('우주선', '🚀', '멋진 우주선 완성!'),
  ladybug('무당벌레', '🐞', '귀여운 무당벌레 완성!');

  final String title;
  final String emoji;
  final String successMsg;

  const DecalTemplate(this.title, this.emoji, this.successMsg);
}

// ── 획 데이터 ────────────────────────────────────────────────────────────────
class Stroke {
  final List<Offset> points;
  final List<Color> colors; // 무지개 모드에서는 포인트마다 색상이 다름
  final double width;
  final bool isEraser;
  final String? stampEmoji;

  Stroke({
    required this.points,
    required this.colors,
    required this.width,
    this.isEraser = false,
    this.stampEmoji,
  });
}

// ── 축하 파티클 ──────────────────────────────────────────────────────────────
class _ConfettiParticle {
  double x, y, vx, vy;
  final Color color;
  final double size;
  double rotation;
  final double rotSpeed;
  double opacity;
  final String? emoji;

  _ConfettiParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color, required this.size,
    required this.rotSpeed,
    this.emoji,
  }) : rotation = 0, opacity = 1.0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 350 * dt; // gravity
    rotation += rotSpeed * dt;
    opacity -= 0.6 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ── 메인 게임 위젯 ───────────────────────────────────────────────────────────
class DecalcomaniaGame extends StatefulWidget {
  const DecalcomaniaGame({super.key});

  @override
  State<DecalcomaniaGame> createState() => _DecalcomaniaGameState();
}

class _DecalcomaniaGameState extends State<DecalcomaniaGame>
    with TickerProviderStateMixin {

  // 그리기 상태
  final List<Stroke> _leftStrokes = [];
  List<Stroke> _rightStrokes = [];
  Stroke? _currentStroke;

  // 도안 템플릿
  DecalTemplate _selectedTemplate = DecalTemplate.butterfly;

  // 브러시 설정
  Color _selectedColor = const Color(0xFFFF5964);
  double _strokeWidth = 16.0;
  BrushMode _brushMode = BrushMode.normal;
  int _rainbowIndex = 0;

  // 무지개 색상 순환
  final List<Color> _rainbowColors = [
    const Color(0xFFFF5964), const Color(0xFFFF9F1C), const Color(0xFFFFD166),
    const Color(0xFF06D6A0), const Color(0xFF118AB2), const Color(0xFF8338EC),
    const Color(0xFFFF6EB4),
  ];

  // 팔레트
  final List<Color> _palette = [
    const Color(0xFFFF5964), // 빨강
    const Color(0xFFFF9F1C), // 주황
    const Color(0xFFFFD166), // 노랑
    const Color(0xFF06D6A0), // 초록
    const Color(0xFF118AB2), // 파랑
    const Color(0xFF8338EC), // 보라
    const Color(0xFFFF6EB4), // 핑크
    const Color(0xFF26C6DA), // 시안
    const Color(0xFF795548), // 갈색
    Colors.white,
    Colors.black,
  ];

  // 스탬프 옵션
  final List<String> _stampEmojis = ['⭐', '❤️', '🦋', '🌸', '👑', '🎈', '🐱', '🍩', '🌟', '🌈'];
  String _selectedStamp = '⭐';

  // 굵기 옵션
  final List<double> _widthOptions = [8.0, 16.0, 28.0, 44.0];
  int _widthIndex = 1;

  // 접기 애니메이션
  late AnimationController _foldController;
  late Animation<double> _foldAnimation;
  bool _isFolding = false;
  bool _hasFolded = false;

  // 버튼 펄스 애니메이션 (접기 버튼)
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 축하 파티클
  List<_ConfettiParticle> _confetti = [];
  late AnimationController _confettiController;

  // 힌트 및 토스트 표시
  bool _hasDrawn = false;
  bool _showToast = false;

  @override
  void initState() {
    super.initState();

    // 접기 애니메이션
    _foldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _foldAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -pi)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 38,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(-pi), weight: 24),
      TweenSequenceItem(
        tween: Tween<double>(begin: -pi, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 38,
      ),
    ]).animate(_foldController);

    _foldController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isFolding = false;
          _hasFolded = true;
          _showToast = true;
        });
        _launchConfetti();
        AudioManager.instance.playMagicUnfoldSuccess();
        HapticFeedback.heavyImpact();

        // 2.2초 후 칭찬 토스트 자동 숨김
        Future.delayed(const Duration(milliseconds: 2200), () {
          if (mounted) {
            setState(() {
              _showToast = false;
            });
          }
        });
      }
    });

    _foldController.addListener(() {
      if (_foldController.value > 0.44 && _foldController.value < 0.56 && _isFolding) {
        if (_rightStrokes.isEmpty && _leftStrokes.isNotEmpty) {
          _mirrorStrokes();
        }
      }
    });

    // 접기 버튼 펄스
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 파티클 컨트롤러
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _confettiController.addListener(() {
      if (_confetti.isNotEmpty) {
        setState(() {
          const dt = 0.016;
          for (final p in _confetti) {
            p.update(dt);
          }
          _confetti.removeWhere((p) => p.opacity <= 0);
        });
      }
    });
  }

  @override
  void dispose() {
    _foldController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }



  // ── 대칭 복사 ──────────────────────────────────────────────────────────────
  void _mirrorStrokes() {
    setState(() {
      _rightStrokes = List.from(_leftStrokes);
    });
    AudioManager.instance.playChime();
    HapticFeedback.mediumImpact();
  }

  // ── 파티클 생성 ─────────────────────────────────────────────────────────────
  void _launchConfetti() {
    final rand = Random();
    final w = MediaQuery.of(context).size.width;
    final magicEmojis = ['✨', '⭐', '🦋', '🌸', '💖', '🌟', '🎉'];
    setState(() {
      _confetti = List.generate(80, (i) {
        final color = _rainbowColors[i % _rainbowColors.length];
        final useEmoji = i % 3 == 0;
        return _ConfettiParticle(
          x: rand.nextDouble() * w,
          y: -20,
          vx: (rand.nextDouble() - 0.5) * 350,
          vy: rand.nextDouble() * 250 + 120,
          color: color,
          size: useEmoji ? 16 + rand.nextDouble() * 16 : 8 + rand.nextDouble() * 12,
          rotSpeed: (rand.nextDouble() - 0.5) * 8,
          emoji: useEmoji ? magicEmojis[i % magicEmojis.length] : null,
        );
      });
    });
    _confettiController.repeat();
    Future.delayed(const Duration(milliseconds: 2800), () {
      _confettiController.stop();
    });
  }

  // ── 그리기 핸들러 ──────────────────────────────────────────────────────────
  void _onPanStart(DragStartDetails details, double halfWidth) {
    if (_isFolding) return;
    if (details.localPosition.dx > halfWidth) return;

    Color startColor;
    if (_brushMode == BrushMode.rainbow) {
      startColor = _rainbowColors[_rainbowIndex % _rainbowColors.length];
    } else if (_brushMode == BrushMode.eraser) {
      startColor = Colors.white;
    } else {
      startColor = _selectedColor;
    }

    final stroke = Stroke(
      points: [details.localPosition],
      colors: [startColor],
      width: _brushMode == BrushMode.eraser ? _strokeWidth * 2.5 : _strokeWidth,
      isEraser: _brushMode == BrushMode.eraser,
    );
    setState(() {
      _currentStroke = stroke;
      _leftStrokes.add(stroke);
      _rightStrokes.clear();
      _hasFolded = false;
      _hasDrawn = true;
    });
    if (_brushMode != BrushMode.eraser) {
      AudioManager.instance.playScribble();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double halfWidth) {
    if (_isFolding || _currentStroke == null) return;
    double dx = details.localPosition.dx.clamp(0.0, halfWidth);

    Color pointColor;
    if (_brushMode == BrushMode.rainbow) {
      _rainbowIndex++;
      pointColor = _rainbowColors[_rainbowIndex % _rainbowColors.length];
    } else if (_brushMode == BrushMode.eraser) {
      pointColor = Colors.white;
    } else {
      pointColor = _selectedColor;
    }

    setState(() {
      _currentStroke!.points.add(Offset(dx, details.localPosition.dy));
      _currentStroke!.colors.add(pointColor);
    });
  }

  void _onTapDown(TapDownDetails details, double halfWidth) {
    if (_isFolding) return;
    if (_brushMode != BrushMode.stamp) return;
    if (details.localPosition.dx > halfWidth) return;

    final color = _selectedColor;
    final stampStroke = Stroke(
      points: [details.localPosition],
      colors: [color],
      width: _strokeWidth * 1.5,
      stampEmoji: _selectedStamp,
    );
    setState(() {
      _leftStrokes.add(stampStroke);
      _rightStrokes.clear();
      _hasFolded = false;
      _hasDrawn = true;
    });
    AudioManager.instance.playPop();
    HapticFeedback.lightImpact();
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isFolding) return;
    setState(() => _currentStroke = null);
  }

  // ── 접기 ───────────────────────────────────────────────────────────────────
  void _foldPaper() {
    if (_isFolding || _leftStrokes.isEmpty) return;
    setState(() {
      _isFolding = true;
      _hasFolded = false;
      _rightStrokes.clear();
    });
    AudioManager.instance.playMagicFold();
    _foldController.reset();
    _foldController.forward();
  }

  // ── 실행취소 ────────────────────────────────────────────────────────────────
  void _undo() {
    if (_leftStrokes.isEmpty) return;
    setState(() {
      _leftStrokes.removeLast();
      _rightStrokes.clear();
      _hasFolded = false;
    });
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
  }

  // ── 전체 지우기 ─────────────────────────────────────────────────────────────
  void _clearCanvas() {
    setState(() {
      _leftStrokes.clear();
      _rightStrokes.clear();
      _hasFolded = false;
      _hasDrawn = false;
    });
    AudioManager.instance.playClick();
  }

  // ── 빌드 ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF0E6FF), Color(0xFFFFE8F4), Color(0xFFE8F4FF)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 6),
                _buildTemplateSelector(),
                const SizedBox(height: 6),
                Expanded(child: _buildCanvas()),
                const SizedBox(height: 8),
                _buildBottomPanel(),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // 축하 파티클
          if (_confetti.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(_confetti),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 헤더 ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8338EC).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 뒤로가기
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6EB4), Color(0xFF8338EC)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8338EC).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            const Text('🦋', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(
              '데칼코마니',
              style: GoogleFonts.jua(
                fontSize: 20,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFFFF6EB4), Color(0xFF8338EC)],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
              ),
            ),
            const Spacer(),
            // 실행취소
            _HeaderBtn(
              icon: Icons.undo_rounded,
              color: const Color(0xFF118AB2),
              enabled: _leftStrokes.isNotEmpty,
              onTap: _undo,
              tooltip: '되돌리기',
            ),
            const SizedBox(width: 6),
            // 전체 지우기
            _HeaderBtn(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFFF5964),
              enabled: _leftStrokes.isNotEmpty,
              onTap: () => _showClearDialog(context),
              tooltip: '전체지우기',
            ),
          ],
        ),
      ),
    );
  }

  // ── 도안 템플릿 선택 바 ────────────────────────────────────────────────────
  Widget _buildTemplateSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: DecalTemplate.values.length,
        itemBuilder: (context, i) {
          final template = DecalTemplate.values[i];
          final isSelected = _selectedTemplate == template;
          return GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              setState(() {
                _selectedTemplate = template;
                _leftStrokes.clear();
                _rightStrokes.clear();
                _hasFolded = false;
                _hasDrawn = false;
              });
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF8338EC)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? const Color(0xFF8338EC) : Colors.white,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF8338EC).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Text(template.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    template.title,
                    style: GoogleFonts.jua(
                      fontSize: 14,
                      color: isSelected ? Colors.white : const Color(0xFF2B2D42),
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

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('전체 지우기', style: GoogleFonts.jua(color: const Color(0xFF2B2D42))),
        content: Text('그림을 모두 지울까요?', style: GoogleFonts.jua(fontSize: 16, color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: GoogleFonts.jua(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCanvas();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5964),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('지우기', style: GoogleFonts.jua(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 캔버스 영역 ─────────────────────────────────────────────────────────────
  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8338EC).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final halfWidth = width / 2;

              return Stack(
                children: [
                  // 배경 도트 패턴
                  Positioned.fill(
                    child: CustomPaint(painter: _DotGridPainter()),
                  ),

                  // 왼쪽 연한 보라색 배경 (그리기 영역 표시)
                  Positioned(
                    left: 0, top: 0, bottom: 0, width: halfWidth,
                    child: Container(
                      color: const Color(0xFFFFF0FB).withValues(alpha: 0.6),
                    ),
                  ),

                  // 도안 점선 가이드 렌더링
                  if (_selectedTemplate != DecalTemplate.free)
                    Positioned(
                      left: 0, top: 0, bottom: 0, width: halfWidth,
                      child: CustomPaint(
                        size: Size(halfWidth, height),
                        painter: _GuidePainter(_selectedTemplate),
                      ),
                    ),

                  // 중앙 접힘선 (빛나는 효과)
                  Positioned(
                    left: halfWidth - 1.5,
                    top: 0, bottom: 0, width: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF8338EC).withValues(alpha: 0.0),
                            const Color(0xFF8338EC).withValues(alpha: 0.3),
                            const Color(0xFFFF6EB4).withValues(alpha: 0.5),
                            const Color(0xFF8338EC).withValues(alpha: 0.3),
                            const Color(0xFF8338EC).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 힌트 텍스트 (그리기 전)
                  if (!_hasDrawn && _selectedTemplate == DecalTemplate.free)
                    Positioned(
                      left: 0, top: 0, bottom: 0, width: halfWidth,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✏️', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(
                              '여기에\n그려봐요!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jua(
                                fontSize: 18,
                                color: const Color(0xFF8338EC).withValues(alpha: 0.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 오른쪽 힌트 텍스트
                  if (!_hasFolded)
                    Positioned(
                      left: halfWidth, top: 0, bottom: 0, width: halfWidth,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text(
                              '접으면\n나타나요!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jua(
                                fontSize: 18,
                                color: const Color(0xFF8338EC).withValues(alpha: 0.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 왼쪽 그리기 패널 (GestureDetector)
                  Positioned(
                    left: 0, top: 0, bottom: 0, width: halfWidth,
                    child: GestureDetector(
                      onPanStart: (d) => _onPanStart(d, halfWidth),
                      onPanUpdate: (d) => _onPanUpdate(d, halfWidth),
                      onPanEnd: _onPanEnd,
                      onTapDown: _brushMode == BrushMode.stamp
                          ? (d) => _onTapDown(d, halfWidth)
                          : null,
                      child: CustomPaint(
                        size: Size(halfWidth, height),
                        painter: _StrokePainter(
                          strokes: _leftStrokes,
                          isMirrored: false,
                        ),
                      ),
                    ),
                  ),

                  // 오른쪽 결과 패널
                  Positioned(
                    left: halfWidth, top: 0, bottom: 0, width: halfWidth,
                    child: CustomPaint(
                      size: Size(halfWidth, height),
                      painter: _StrokePainter(
                        strokes: _rightStrokes,
                        isMirrored: true,
                      ),
                    ),
                  ),

                  // 접히는 종이 3D 애니메이션 (마법 접기 동작 중에만 오버레이 표시)
                  if (_isFolding)
                    AnimatedBuilder(
                      animation: _foldAnimation,
                      builder: (context, child) {
                        final isBackVisible = _foldAnimation.value < -pi / 2;
                        return Positioned(
                          left: halfWidth, top: 0, bottom: 0, width: halfWidth,
                          child: Transform(
                            alignment: Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(_foldAnimation.value),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isBackVisible
                                    ? const Color(0xFFFFF0FB)
                                    : Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(-8, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  // 좌/우 라벨
                  Positioned(
                    left: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8338EC).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '✏️ 그리기',
                        style: GoogleFonts.jua(
                          fontSize: 12,
                          color: const Color(0xFF8338EC).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6EB4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🪄 마법 결과',
                        style: GoogleFonts.jua(
                          fontSize: 12,
                          color: const Color(0xFFFF6EB4).withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),

                  // 접기 완성 칭찬 플로팅 토스트 (모달 배너 대신 2초간 살짝 표시)
                  Positioned(
                    top: 14, left: 0, right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _showToast ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedScale(
                          scale: _showToast ? 1.0 : 0.8,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.elasticOut,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6EB4), Color(0xFF8338EC)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8338EC).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_selectedTemplate.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedTemplate.successMsg,
                                  style: GoogleFonts.jua(
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── 하단 툴바 ──────────────────────────────────────────────────────────────
  Widget _buildBottomPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1행: 브러시 모드 선택 ──
          SizedBox(
            height: 52,
            child: Row(
              children: [
                _ModeBtn(
                  emoji: '✏️',
                  label: '일반',
                  isSelected: _brushMode == BrushMode.normal,
                  onTap: () => setState(() => _brushMode = BrushMode.normal),
                ),
                const SizedBox(width: 8),
                _ModeBtn(
                  emoji: '🌈',
                  label: '무지개',
                  isSelected: _brushMode == BrushMode.rainbow,
                  onTap: () => setState(() => _brushMode = BrushMode.rainbow),
                ),
                const SizedBox(width: 8),
                _ModeBtn(
                  emoji: '🔵',
                  label: '스탬프',
                  isSelected: _brushMode == BrushMode.stamp,
                  onTap: () => setState(() => _brushMode = BrushMode.stamp),
                ),
                const SizedBox(width: 8),
                _ModeBtn(
                  emoji: '🧹',
                  label: '지우개',
                  isSelected: _brushMode == BrushMode.eraser,
                  onTap: () => setState(() => _brushMode = BrushMode.eraser),
                ),
                const Spacer(),
                // 굵기 선택
                ..._widthOptions.asMap().entries.map((e) {
                  final i = e.key;
                  final isSelected = _widthIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _widthIndex = i);
                      _strokeWidth = _widthOptions[i];
                      AudioManager.instance.playClick();
                    },
                    child: Container(
                      width: 38, height: 38,
                      margin: const EdgeInsets.only(left: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8338EC).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF8338EC)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: (4 + i * 4.5).clamp(4, 22),
                          height: (4 + i * 4.5).clamp(4, 22),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF8338EC)
                                : Colors.grey.shade400,
                            shape: BoxShape.circle,
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
          // ── 2행: 색상 팔레트 + 접기 버튼 ──
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 색상 팔레트 또는 스탬프 선택 (스크롤 가능)
                Expanded(
                  child: _brushMode == BrushMode.stamp
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _stampEmojis.length,
                          itemBuilder: (context, i) {
                            final emoji = _stampEmojis[i];
                            final isSelected = _selectedStamp == emoji;
                            return GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                setState(() {
                                  _selectedStamp = emoji;
                                });
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: isSelected ? 46 : 40,
                                height: isSelected ? 46 : 40,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8338EC).withValues(alpha: 0.15)
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF8338EC) : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF8338EC).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    emoji,
                                    style: TextStyle(fontSize: isSelected ? 24 : 20),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _palette.length,
                          itemBuilder: (context, i) {
                            final color = _palette[i];
                            final isSelected = _brushMode != BrushMode.eraser &&
                                _brushMode != BrushMode.rainbow &&
                                _selectedColor == color;
                            return GestureDetector(
                              onTap: () {
                                AudioManager.instance.playColorSelect();
                                setState(() {
                                  _selectedColor = color;
                                  if (_brushMode == BrushMode.eraser ||
                                      _brushMode == BrushMode.rainbow) {
                                    _brushMode = BrushMode.normal;
                                  }
                                });
                                HapticFeedback.selectionClick();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: isSelected ? 46 : 40,
                                height: isSelected ? 46 : 40,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF8338EC) : Colors.white,
                                    width: isSelected ? 3 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: isSelected ? 10 : 4,
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? Icon(Icons.check_rounded, color: color == Colors.white ? Colors.grey : Colors.white, size: 18)
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 10),
                // 마법 접기 버튼
                ScaleTransition(
                  scale: (_leftStrokes.isEmpty || _isFolding)
                      ? const AlwaysStoppedAnimation(1.0)
                      : _pulseAnimation,
                  child: GestureDetector(
                    onTap: _foldPaper,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: (_leftStrokes.isEmpty || _isFolding)
                              ? [Colors.grey.shade300, Colors.grey.shade400]
                              : [const Color(0xFFFF6EB4), const Color(0xFF8338EC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: (_leftStrokes.isEmpty || _isFolding)
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF8338EC).withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isFolding ? '🪄' : '✨',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFolding ? '마법중...' : '마법 접기!',
                            style: GoogleFonts.jua(
                              fontSize: 17,
                              color: _leftStrokes.isEmpty || _isFolding
                                  ? Colors.grey.shade600
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 아이콘 버튼 ─────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final String tooltip;

  const _HeaderBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: enabled ? color : Colors.grey.shade400, size: 18),
        ),
      ),
    );
  }
}

// ── 브러시 모드 버튼 ─────────────────────────────────────────────────────────
class _ModeBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8338EC).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF8338EC) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF8338EC).withValues(alpha: 0.2), blurRadius: 8)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.jua(
                fontSize: 12,
                color: isSelected ? const Color(0xFF8338EC) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 도안 가이드 점선 Painter ──────────────────────────────────────────────────
class _GuidePainter extends CustomPainter {
  final DecalTemplate template;

  _GuidePainter(this.template);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8338EC).withValues(alpha: 0.35)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    switch (template) {
      case DecalTemplate.butterfly:
        // 나비 큰 날개 + 작은 날개 (오른쪽 중앙 접힘선 기준)
        path.moveTo(w, h * 0.5);
        path.cubicTo(w - w * 0.7, h * 0.2, w - w * 0.85, h * 0.45, w, h * 0.52);
        path.cubicTo(w - w * 0.65, h * 0.6, w - w * 0.7, h * 0.8, w, h * 0.75);
        // 안테나
        path.moveTo(w, h * 0.48);
        path.quadraticBezierTo(w - w * 0.3, h * 0.3, w - w * 0.4, h * 0.22);
        break;

      case DecalTemplate.flower:
        // 꽃잎 3개 + 줄기 + 잎사귀
        path.moveTo(w, h * 0.4);
        path.cubicTo(w - w * 0.5, h * 0.25, w - w * 0.7, h * 0.38, w, h * 0.48);
        path.cubicTo(w - w * 0.65, h * 0.5, w - w * 0.5, h * 0.65, w, h * 0.6);
        // 줄기
        path.moveTo(w, h * 0.6);
        path.quadraticBezierTo(w - 15, h * 0.75, w, h * 0.88);
        // 잎사귀
        path.moveTo(w, h * 0.72);
        path.quadraticBezierTo(w - w * 0.4, h * 0.68, w, h * 0.78);
        break;

      case DecalTemplate.crown:
        // 왕관 반쪽
        path.moveTo(w, h * 0.7);
        path.lineTo(w - w * 0.75, h * 0.7);
        path.lineTo(w - w * 0.8, h * 0.45);
        path.lineTo(w - w * 0.5, h * 0.55);
        path.lineTo(w - w * 0.2, h * 0.38);
        path.lineTo(w, h * 0.48);
        break;

      case DecalTemplate.rocket:
        // 우주선 반쪽
        path.moveTo(w, h * 0.25);
        path.cubicTo(w - w * 0.5, h * 0.3, w - w * 0.5, h * 0.65, w - w * 0.4, h * 0.75);
        path.lineTo(w, h * 0.75);
        // 날개
        path.moveTo(w - w * 0.4, h * 0.65);
        path.lineTo(w - w * 0.8, h * 0.78);
        path.lineTo(w - w * 0.4, h * 0.75);
        break;

      case DecalTemplate.ladybug:
        // 무당벌레 반쪽 몸통 + 다리
        path.moveTo(w, h * 0.3);
        path.cubicTo(w - w * 0.8, h * 0.3, w - w * 0.8, h * 0.75, w, h * 0.75);
        // 점 2개
        canvas.drawCircle(Offset(w - w * 0.35, h * 0.45), 10, paint);
        canvas.drawCircle(Offset(w - w * 0.45, h * 0.62), 12, paint);
        break;

      case DecalTemplate.free:
        return;
    }

    // 점선(Dash) 패턴으로 그리기
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length) ? dashWidth : metric.length - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePainter oldDelegate) =>
      oldDelegate.template != template;
}

// ── 획 그리기 Painter ─────────────────────────────────────────────────────────
class _StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final bool isMirrored;

  _StrokePainter({required this.strokes, required this.isMirrored});

  double _getX(double originalX, double maxWidth) =>
      isMirrored ? maxWidth - originalX : originalX;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // 스탬프인 경우 (이모지 그리기)
      if (stroke.stampEmoji != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: stroke.stampEmoji,
            style: TextStyle(fontSize: stroke.width * 1.6),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        for (final pt in stroke.points) {
          final x = _getX(pt.dx, size.width);
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, pt.dy - textPainter.height / 2),
          );
        }
        continue;
      }

      // 점만 있는 단일 획
      if (stroke.points.length == 1) {
        final paint = Paint()
          ..color = stroke.colors.first
          ..style = PaintingStyle.fill
          ..isAntiAlias = true
          ..maskFilter = stroke.isEraser ? const MaskFilter.blur(BlurStyle.normal, 2) : null;
        canvas.drawCircle(
          Offset(_getX(stroke.points.first.dx, size.width), stroke.points.first.dy),
          stroke.width / 2,
          paint,
        );
        continue;
      }

      // 무지개 등 색상이 포인트별로 다른 경우: 선분 단위로 색상 적용
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        final c1 = i < stroke.colors.length ? stroke.colors[i] : stroke.colors.last;

        final paint = Paint()
          ..color = stroke.isEraser ? Colors.white : c1
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(_getX(p1.dx, size.width), p1.dy),
          Offset(_getX(p2.dx, size.width), p2.dy),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

// ── 도트 그리드 배경 ─────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8338EC).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 축하 파티클 Painter ───────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.opacity <= 0) continue;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.emoji != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.emoji,
            style: TextStyle(
              fontSize: p.size * 1.5,
              color: Colors.white.withValues(alpha: p.opacity.clamp(0.0, 1.0)),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      } else {
        final paint = Paint()
          ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
