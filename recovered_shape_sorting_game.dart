import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shape Sorting Game — 모양 쏙쏙! (4~5세 톡톡 쉬운 놀이)
// 원목 교구 느낌의 프리미엄 3D 모양 맞추기 게임
// ─────────────────────────────────────────────────────────────────────────────

/// 도형 종류
enum ShapeType {
  circle,
  square,
  triangle,
  star,
  heart,
  diamond,
  hexagon,
  pentagon,
  cross,
  moon,
}

/// 도형 메타데이터
class _ShapeInfo {
  final ShapeType type;
  final String label;
  final String emoji;
  final Color color;
  final Color shadowColor;

  const _ShapeInfo({
    required this.type,
    required this.label,
    required this.emoji,
    required this.color,
    required this.shadowColor,
  });
}

/// 성공 시 팡 터지는 파티클
class _SparkleParticle {
  double x, y, vx, vy, size, life;
  Color color;

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}

class ShapeSortingGame extends StatefulWidget {
  const ShapeSortingGame({super.key});

  @override
  State<ShapeSortingGame> createState() => _ShapeSortingGameState();
}

class _ShapeSortingGameState extends State<ShapeSortingGame>
    with TickerProviderStateMixin {
  // ── Controllers ──
  late ConfettiController _confettiController;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  // ── Game State ──
  int _level = 1; // 1 ~ 5 단계
  bool _showingLevelComplete = false;

  // 라운드 데이터
  late List<_ShapeInfo> _roundShapes;
  late List<ShapeType> _remainingPieces;
  final Set<ShapeType> _filledShapes = {};
  ShapeType? _justSnappedShape;

  final List<_SparkleParticle> _particles = [];
  final Random _rng = Random();

  // 도형 마스터 목록 (10가지 다양한 형태와 산뜻한 파스텔 원목 컬러)
  static const List<_ShapeInfo> _allShapes = [
    _ShapeInfo(
      type: ShapeType.triangle,
      label: '세모',
      emoji: '🔺',
      color: Color(0xFFFF5252),
      shadowColor: Color(0xFFD32F2F),
    ),
    _ShapeInfo(
      type: ShapeType.square,
      label: '네모',
      emoji: '🟧',
      color: Color(0xFFFF9800),
      shadowColor: Color(0xFFF57C00),
    ),
    _ShapeInfo(
      type: ShapeType.circle,
      label: '동그라미',
      emoji: '🔵',
      color: Color(0xFF29B6F6),
      shadowColor: Color(0xFF0288D1),
    ),
    _ShapeInfo(
      type: ShapeType.star,
      label: '별',
      emoji: '⭐',
      color: Color(0xFFFFCA28),
      shadowColor: Color(0xFFFFA000),
    ),
    _ShapeInfo(
      type: ShapeType.heart,
      label: '하트',
      emoji: '❤️',
      color: Color(0xFFFF4081),
      shadowColor: Color(0xFFC2185B),
    ),
    _ShapeInfo(
      type: ShapeType.diamond,
      label: '마름모',
      emoji: '💎',
      color: Color(0xFFAB47BC),
      shadowColor: Color(0xFF7B1FA2),
    ),
    _ShapeInfo(
      type: ShapeType.hexagon,
      label: '육각형',
      emoji: '⬡',
      color: Color(0xFF26A69A),
      shadowColor: Color(0xFF00796B),
    ),
    _ShapeInfo(
      type: ShapeType.pentagon,
      label: '오각형',
      emoji: '⬠',
      color: Color(0xFF5C6BC0),
      shadowColor: Color(0xFF3949AB),
    ),
    _ShapeInfo(
      type: ShapeType.cross,
      label: '십자',
      emoji: '➕',
      color: Color(0xFF66BB6A),
      shadowColor: Color(0xFF388E3C),
    ),
    _ShapeInfo(
      type: ShapeType.moon,
      label: '달',
      emoji: '🌙',
      color: Color(0xFF8E24AA),
      shadowColor: Color(0xFF6A1B9A),
    ),
  ];

  /// 단계별 도형 개수 (1단계: 2개 ~ 5단계: 6개)
  int get _shapeCountForLevel {
    switch (_level) {
      case 1:
        return 2;
      case 2:
        return 3;
      case 3:
        return 4;
      case 4:
        return 5;
      default:
        return 6;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _startNewRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  // ── Round Logic ──────────────────────────────────────────────────────────

  void _startNewRound() {
    final count = _shapeCountForLevel;

    // 도형 풀에서 랜덤으로 N개 선택
    final shuffled = List<_ShapeInfo>.from(_allShapes)..shuffle(_rng);
    _roundShapes = shuffled.take(count).toList();

    // 트레이에는 섞인 순서로 배치
    final pieceTypes = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
    _remainingPieces = pieceTypes;
    _filledShapes.clear();
    _justSnappedShape = null;
    _showingLevelComplete = false;

    setState(() {});
  }

  void _onShapeDropped(ShapeType droppedType, ShapeType targetType, Offset dropPos) {
    if (droppedType == targetType && !_filledShapes.contains(targetType)) {
      // 정답 스냅!
      AudioManager.instance.playCardMatch();
      HapticFeedback.mediumImpact();

      setState(() {
        _filledShapes.add(targetType);
        _remainingPieces.remove(droppedType);
        _justSnappedShape = targetType;
      });

      _spawnSparkles(dropPos, _getShapeInfo(targetType).color);

      // 전체 완료 체크
      if (_filledShapes.length == _roundShapes.length) {
        Future.delayed(const Duration(milliseconds: 600), _onRoundComplete);
      }
    } else {
      // 오답 튕김
      AudioManager.instance.playCardMismatch();
      HapticFeedback.lightImpact();
    }
  }

  void _spawnSparkles(Offset center, Color color) {
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.0 + _rng.nextDouble() * 4.0;
      _particles.add(_SparkleParticle(
        x: center.dx,
        y: center.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 5 + _rng.nextDouble() * 5,
        life: 1.0,
        color: color,
      ));
    }
  }

  void _onRoundComplete() {
    _confettiController.play();
    AudioManager.instance.playFeedAnimalsSuccess();
    HapticFeedback.heavyImpact();

    setState(() {
      _showingLevelComplete = true;
    });
  }

  void _nextRound() {
    // 매 판 완료 시 레벨 1단계씩 상승 (최대 5)
    if (_level < 5) {
      _level++;
    }
    _startNewRound();
  }

  _ShapeInfo _getShapeInfo(ShapeType type) {
    return _allShapes.firstWhere((s) => s.type == type);
  }

  // ── Build UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFBEA), Color(0xFFF0F9FF), Color(0xFFFFF0F5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // 배경 데코 (은은한 구름 및 부드러운 도트)
              Positioned.fill(
                child: CustomPaint(
                  painter: _CozyBackgroundPainter(),
                ),
              ),

              // 메인 게임 레이아웃
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 6),
                    _buildInstructionBanner(),
                    const SizedBox(height: 10),

                    // 메인 퍼즐 보드 (화면 중앙에 안정적으로 배치)
                    Expanded(
                      child: Center(
                        child: _buildPuzzleBoard(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 하단 원목 도형 트레이 (크기와 비율이 딱 맞는 터치 친화적 디자인)
                    _buildPieceTray(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // 컨페티 팡파레
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 35,
                  colors: const [
                    Color(0xFFFF6B6B),
                    Color(0xFF4ECDC4),
                    Color(0xFFFFE66D),
                    Color(0xFF95E1D3),
                    Color(0xFFFFA07A),
                    Color(0xFFBA68C8),
                  ],
                ),
              ),

              // 클리어 팝업
              if (_showingLevelComplete) _buildCompletionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7B7B), Color(0xFFFF4848)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFC62828),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // 중앙 타이틀
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), offset: Offset(0, 4), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧲', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    '모양 쏙쏙',
                    style: GoogleFonts.jua(
                      fontSize: 19,
                      color: KidsTheme.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 단계 선택 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _showDifficultyDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFE65100), offset: Offset(0, 4), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '$_level단계',
                    style: GoogleFonts.jua(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Instruction Banner ─────────────────────────────────────────────────

  Widget _buildInstructionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👆', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '알맞은 모양을 쏙 넣어봐요!',
            style: GoogleFonts.jua(
              fontSize: 15,
              color: const Color(0xFF5D4037),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Puzzle Board (아기자기한 원목 퍼즐 판) ──────────────────────────────

  Widget _buildPuzzleBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _roundShapes.length;

        // 아이템 개수에 따른 그리드 레이아웃 최적화
        final int crossAxisCount = count <= 3 ? count : (count == 4 ? 2 : 3);
        final double maxBoardW = min(constraints.maxWidth - 32, 420.0);

        // 카드 크기 계산 (아이템 개수에 따라 쾌적하게 비례 조절)
        final double spacing = 12.0;
        final double totalHSpacing = spacing * (crossAxisCount + 1);
        final double cardWidth = ((maxBoardW - 32) - totalHSpacing) / crossAxisCount;
        final double cardSize = cardWidth.clamp(78.0, 110.0);

        return Container(
          width: maxBoardW,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7), // 부드럽고 따뜻한 원목 크림 톤
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFFFE082), // 따뜻한 버터 옐로우 원목 테두리
              width: 5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x228D6E63),
                offset: Offset(0, 8),
                blurRadius: 18,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(0, -3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 4 귀퉁이 원목 고정 핀 데코
              const Positioned(top: -4, left: -4, child: _WoodPeg()),
              const Positioned(top: -4, right: -4, child: _WoodPeg()),
              const Positioned(bottom: -4, left: -4, child: _WoodPeg()),
              const Positioned(bottom: -4, right: -4, child: _WoodPeg()),

              // 슬롯 카드들 Wrap
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _roundShapes.map((shapeInfo) {
                    return _buildSlotTargetCard(shapeInfo, cardSize);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 개별 슬롯 타겟 카드
  Widget _buildSlotTargetCard(_ShapeInfo shapeInfo, double size) {
    final isFilled = _filledShapes.contains(shapeInfo.type);
    final isJustSnapped = _justSnappedShape == shapeInfo.type;

    return DragTarget<ShapeType>(
      onWillAcceptWithDetails: (details) => !isFilled,
      onAcceptWithDetails: (details) {
        final renderBox = context.findRenderObject() as RenderBox?;
        final center = renderBox != null
            ? renderBox.localToGlobal(Offset(renderBox.size.width / 2, renderBox.size.height / 2))
            : Offset.zero;
        _onShapeDropped(details.data, shapeInfo.type, center);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isFilled
                ? shapeInfo.color.withValues(alpha: 0.08)
                : (isHovering ? shapeInfo.color.withValues(alpha: 0.15) : const Color(0xFFF9F6EE)),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isHovering
                  ? shapeInfo.color
                  : (isFilled ? shapeInfo.color.withValues(alpha: 0.4) : const Color(0xFFE2D9C8)),
              width: isHovering ? 3.5 : 2.5,
            ),
            boxShadow: isHovering
                ? [
                    BoxShadow(
                      color: shapeInfo.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 도형 구멍 또는 채워진 도형
              SizedBox(
                width: size * 0.72,
                height: size * 0.72,
                child: isFilled
                    ? TweenAnimationBuilder<double>(
                        tween: Tween(begin: isJustSnapped ? 0.4 : 1.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: CustomPaint(
                          painter: _ChunkyBlockPainter(
                            type: shapeInfo.type,
                            color: shapeInfo.color,
                            shadowColor: shapeInfo.shadowColor,
                            isHappy: true,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _SlotHolePainter(
                          type: shapeInfo.type,
                          accentColor: shapeInfo.color,
                          isHovering: isHovering,
                        ),
                      ),
              ),

              const SizedBox(height: 6),

              // 이름 라벨 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFilled ? shapeInfo.color : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFilled ? shapeInfo.shadowColor : const Color(0xFFD7CCC8),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  shapeInfo.label,
                  style: GoogleFonts.jua(
                    fontSize: 13,
                    color: isFilled ? Colors.white : const Color(0xFF6D4C41),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Piece Tray (하단 도형 진열대) ─────────────────────────────────────────

  Widget _buildPieceTray() {
    if (_remainingPieces.isEmpty) {
      return const SizedBox(height: 85);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F795548),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _remainingPieces.map((type) {
            final info = _getShapeInfo(type);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildDraggableBlock(info),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 드래그 가능한 3D 원목 블록
  Widget _buildDraggableBlock(_ShapeInfo info) {
    const double blockSize = 76.0;

    return Draggable<ShapeType>(
      data: info.type,
      onDragStarted: () {
        AudioManager.instance.playCardFlip();
        HapticFeedback.lightImpact();
      },
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.18,
          child: SizedBox(
            width: blockSize,
            height: blockSize,
            child: CustomPaint(
              painter: _ChunkyBlockPainter(
                type: info.type,
                color: info.color,
                shadowColor: info.shadowColor,
                isDragging: true,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: SizedBox(
          width: blockSize,
          height: blockSize,
          child: CustomPaint(
            painter: _ChunkyBlockPainter(
              type: info.type,
              color: info.color,
              shadowColor: info.shadowColor,
            ),
          ),
        ),
      ),
      child: AnimatedBuilder(
        animation: _floatAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: child,
          );
        },
        child: SizedBox(
          width: blockSize,
          height: blockSize,
          child: CustomPaint(
            painter: _ChunkyBlockPainter(
              type: info.type,
              color: info.color,
              shadowColor: info.shadowColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── Completion Overlay ───────────────────────────────────────────────────

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(28),
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: KidsTheme.borderDark, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 🥳 🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text(
                  '참 잘했어요!',
                  style: GoogleFonts.jua(
                    fontSize: 30,
                    color: KidsTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '모든 모양을 쏙쏙 맞췄어요! ❤️',
                  style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textLight),
                ),
                const SizedBox(height: 14),

                // 완성된 도형 아이콘들
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _roundShapes.map((s) {
                    return Text(s.emoji, style: const TextStyle(fontSize: 28));
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 다음 단계 버튼
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    _nextRound();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: KidsTheme.borderDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF2E7D32),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _level < 5 ? '다음 단계 도전! 🚀' : '한 번 더 하기! 🔄',
                          style: GoogleFonts.jua(fontSize: 19, color: Colors.white),
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
    );
  }

  // ── Difficulty Selection Dialog ──────────────────────────────────────────

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: KidsTheme.borderDark, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⭐ 모양 몇 개 맞출까?',
                    style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final lv = i + 1;
                    final count = [2, 3, 4, 5, 6][i];
                    final labels = ['초간단', '쉬워요', '보통', '도전!', '마스터'];
                    final isActive = _level == lv;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _level = lv;
                          });
                          Navigator.pop(ctx);
                          _startNewRound();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFFFF8E1) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isActive ? const Color(0xFFFFB74D) : Colors.grey.shade300,
                              width: isActive ? 3 : 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text('⭐' * lv, style: const TextStyle(fontSize: 15)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${labels[i]} ($count개)',
                                  style: GoogleFonts.jua(
                                    fontSize: 16,
                                    color: isActive ? const Color(0xFFE65100) : KidsTheme.textDark,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isActive)
                                const Icon(Icons.check_circle, color: Color(0xFFFF9800), size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

/// 3D 원목/플라스틱 블록 페인터 (도형 본체 + 입체 두께 + 귀여운 표정 + 광택)
class _ChunkyBlockPainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final Color shadowColor;
  final bool isDragging;
  final bool isHappy;

  _ChunkyBlockPainter({
    required this.type,
    required this.color,
    required this.shadowColor,
    this.isDragging = false,
    this.isHappy = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.84;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 1. 하단 3D 두께 음영 (아래로 4px 이동)
    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(0, 4.0);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. 블록 전면 메인 색상
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. 테두리 외곽선
    final borderPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // 4. 귀여운 표정 (동글동글 큰 눈 + 볼터치 + 입)
    final eyePaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;

    final whiteGlint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blushPaint = Paint()
      ..color = const Color(0xFFFF5252).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final eyeSpacing = r * 0.28;
    final eyeY = -r * 0.04;
    final eyeRadius = r * 0.09;

    // 왼쪽/오른쪽 눈
    canvas.drawCircle(Offset(-eyeSpacing, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(eyeSpacing, eyeY), eyeRadius, eyePaint);

    // 눈 반짝임 하이라이트
    canvas.drawCircle(Offset(-eyeSpacing - 1.5, eyeY - 1.5), eyeRadius * 0.4, whiteGlint);
    canvas.drawCircle(Offset(eyeSpacing - 1.5, eyeY - 1.5), eyeRadius * 0.4, whiteGlint);

    // 핑크빛 볼터치
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-eyeSpacing * 1.4, eyeY + 6), width: 10, height: 6),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeSpacing * 1.4, eyeY + 6), width: 10, height: 6),
      blushPaint,
    );

    // 입 모양 (드래그 중이거나 완료 시 활짝 웃음)
    if (isDragging) {
      // 신나서 입을 벌린 모양 ':O'
      final openMouth = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(0, r * 0.22), width: 9, height: 11),
        openMouth,
      );
    } else {
      // 방긋 웃는 입
      final smilePaint = Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(-r * 0.16, r * 0.16)
        ..quadraticBezierTo(0, r * (isHappy ? 0.38 : 0.30), r * 0.16, r * 0.16);
      canvas.drawPath(smilePath, smilePaint);
    }

    // 5. 좌상단 글래스 하이라이트 (산뜻한 광택감)
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-r * 0.35, -r * 0.35), r * 0.16, glossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChunkyBlockPainter old) =>
      old.type != type || old.color != color || old.isDragging != isDragging || old.isHappy != isHappy;
}

/// 슬롯 구멍 페인터 (부드러운 음각 홈 + 은은한 점선 테두리)
class _SlotHolePainter extends CustomPainter {
  final ShapeType type;
  final Color accentColor;
  final bool isHovering;

  _SlotHolePainter({
    required this.type,
    required this.accentColor,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2 * 0.84;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final path = _getShapePath(type, r);

    // 1. 홈 내부 은은한 색상
    final bgPaint = Paint()
      ..color = isHovering
          ? accentColor.withValues(alpha: 0.2)
          : accentColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // 2. 점선 아웃라인
    final dashPaint = Paint()
      ..color = isHovering ? accentColor : accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHovering ? 2.8 : 2.0;

    _drawDashedPath(canvas, path, dashPaint);

    // 3. 중앙에 반투명 미니 실루엣
    final silhouettePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(_getShapePath(type, r * 0.6), silhouettePaint);

    canvas.restore();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final dashLen = min(5.5, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + dashLen);
        canvas.drawPath(extractPath, paint);
        distance += 9.5;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlotHolePainter old) =>
      old.type != type || old.accentColor != accentColor || old.isHovering != isHovering;
}

/// 원목 고정 핀 (원목 장난감 판 모서리 핀)
class _WoodPeg extends StatelessWidget {
  const _WoodPeg();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFA000), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5), blurRadius: 1),
        ],
      ),
    );
  }
}

/// 아늑한 배경 페인터 (은은한 파스텔 데코)
class _CozyBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0x0C795548)
      ..style = PaintingStyle.fill;

    // 미세한 도트 패턴
    const step = 36.0;
    for (double x = step / 2; x < size.width; x += step) {
      for (double y = step / 2; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Shape Path Helpers
// ─────────────────────────────────────────────────────────────────────────────

Path _getShapePath(ShapeType type, double r) {
  switch (type) {
    case ShapeType.circle:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    case ShapeType.square:
      return Path()..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 1.7, height: r * 1.7),
        Radius.circular(r * 0.22),
      ));
    case ShapeType.triangle:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(-r * 0.95, r * 0.75)
        ..lineTo(r * 0.95, r * 0.75)
        ..close();
    case ShapeType.star:
      return _starPath(r);
    case ShapeType.heart:
      return _heartPath(r);
    case ShapeType.diamond:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.75, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.75, 0)
        ..close();
    case ShapeType.hexagon:
      return _polygonPath(6, r);
    case ShapeType.pentagon:
      return _polygonPath(5, r);
    case ShapeType.cross:
      return _crossPath(r);
    case ShapeType.moon:
      return _moonPath(r);
  }
}

Path _starPath(double r) {
  final path = Path();
  for (int i = 0; i < 5; i++) {
    final outerAngle = -pi / 2 + (2 * pi * i / 5);
    final innerAngle = outerAngle + pi / 5;
    final outer = Offset(cos(outerAngle) * r, sin(outerAngle) * r);
    final inner = Offset(cos(innerAngle) * r * 0.48, sin(innerAngle) * r * 0.48);
    if (i == 0) {
      path.moveTo(outer.dx, outer.dy);
    } else {
      path.lineTo(outer.dx, outer.dy);
    }
    path.lineTo(inner.dx, inner.dy);
  }
  path.close();
  return path;
}

Path _heartPath(double r) {
  final path = Path();
  path.moveTo(0, r * 0.3);
  path.cubicTo(-r * 0.1, -r * 0.1, -r, -r * 0.3, -r * 0.5, -r * 0.7);
  path.cubicTo(-r * 0.2, -r, 0, -r * 0.7, 0, -r * 0.4);
  path.cubicTo(0, -r * 0.7, r * 0.2, -r, r * 0.5, -r * 0.7);
  path.cubicTo(r, -r * 0.3, r * 0.1, -r * 0.1, 0, r * 0.3);
  path.close();
  return path;
}

Path _polygonPath(int sides, double r) {
  final path = Path();
  for (int i = 0; i < sides; i++) {
    final angle = -pi / 2 + (2 * pi * i / sides);
    final p = Offset(cos(angle) * r, sin(angle) * r);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  return path;
}

Path _crossPath(double r) {
  final w = r * 0.38;
  final path = Path();
  path.moveTo(-w, -r);
  path.lineTo(w, -r);
  path.lineTo(w, -w);
  path.lineTo(r, -w);
  path.lineTo(r, w);
  path.lineTo(w, w);
  path.lineTo(w, r);
  path.lineTo(-w, r);
  path.lineTo(-w, w);
  path.lineTo(-r, w);
  path.lineTo(-r, -w);
  path.lineTo(-w, -w);
  path.close();
  return path;
}

Path _moonPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
  final cutPath = Path()
    ..addOval(Rect.fromCircle(center: Offset(r * 0.5, -r * 0.15), radius: r * 0.75));
  return Path.combine(PathOperation.difference, path, cutPath);
}
