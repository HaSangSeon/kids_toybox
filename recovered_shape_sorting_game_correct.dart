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
  // 기본 도형
  circle, square, triangle, star, heart, diamond, hexagon, pentagon, cross, moon,
  // 동물
  bear, rabbit, cat, fish, bird,
  // 자연 & 식물
  flower, tree, cloud,
  // 탈것
  car, boat,
  // 건물
  house, castle,
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
  late AnimationController _bgAnimController;

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

  // 도형 마스터 목록 (다양한 테마: 기본, 동물, 식물, 탈것, 건물)
  static const List<_ShapeInfo> _allShapes = [
    // --- 기본 도형 ---
    _ShapeInfo(type: ShapeType.triangle, label: '세모', emoji: '🔺', color: Color(0xFFFF5252), shadowColor: Color(0xFFD32F2F)),
    _ShapeInfo(type: ShapeType.square, label: '네모', emoji: '🟧', color: Color(0xFFFF9800), shadowColor: Color(0xFFF57C00)),
    _ShapeInfo(type: ShapeType.circle, label: '동그라미', emoji: '🔵', color: Color(0xFF29B6F6), shadowColor: Color(0xFF0288D1)),
    _ShapeInfo(type: ShapeType.star, label: '별', emoji: '⭐', color: Color(0xFFFFCA28), shadowColor: Color(0xFFFFA000)),
    _ShapeInfo(type: ShapeType.heart, label: '하트', emoji: '❤️', color: Color(0xFFFF4081), shadowColor: Color(0xFFC2185B)),
    _ShapeInfo(type: ShapeType.diamond, label: '마름모', emoji: '💎', color: Color(0xFFAB47BC), shadowColor: Color(0xFF7B1FA2)),
    _ShapeInfo(type: ShapeType.hexagon, label: '육각형', emoji: '⬡', color: Color(0xFF26A69A), shadowColor: Color(0xFF00796B)),
    _ShapeInfo(type: ShapeType.pentagon, label: '오각형', emoji: '⬠', color: Color(0xFF5C6BC0), shadowColor: Color(0xFF3949AB)),
    _ShapeInfo(type: ShapeType.cross, label: '십자', emoji: '➕', color: Color(0xFF66BB6A), shadowColor: Color(0xFF388E3C)),
    _ShapeInfo(type: ShapeType.moon, label: '달', emoji: '🌙', color: Color(0xFF8E24AA), shadowColor: Color(0xFF6A1B9A)),
    
    // --- 동물 ---
    _ShapeInfo(type: ShapeType.bear, label: '곰', emoji: '🐻', color: Color(0xFF8D6E63), shadowColor: Color(0xFF5D4037)),
    _ShapeInfo(type: ShapeType.rabbit, label: '토끼', emoji: '🐰', color: Color(0xFFF48FB1), shadowColor: Color(0xFFC2185B)),
    _ShapeInfo(type: ShapeType.cat, label: '고양이', emoji: '🐱', color: Color(0xFFFFB74D), shadowColor: Color(0xFFF57C00)),
    _ShapeInfo(type: ShapeType.fish, label: '물고기', emoji: '🐟', color: Color(0xFF4DD0E1), shadowColor: Color(0xFF0097A7)),
    _ShapeInfo(type: ShapeType.bird, label: '새', emoji: '🐦', color: Color(0xFFBA68C8), shadowColor: Color(0xFF7B1FA2)),

    // --- 자연 & 식물 ---
    _ShapeInfo(type: ShapeType.flower, label: '꽃', emoji: '🌸', color: Color(0xFFFF8A80), shadowColor: Color(0xFFD50000)),
    _ShapeInfo(type: ShapeType.tree, label: '나무', emoji: '🌳', color: Color(0xFF81C784), shadowColor: Color(0xFF388E3C)),
    _ShapeInfo(type: ShapeType.cloud, label: '구름', emoji: '☁️', color: Color(0xFFE0E0E0), shadowColor: Color(0xFF9E9E9E)),

    // --- 탈것 ---
    _ShapeInfo(type: ShapeType.car, label: '자동차', emoji: '🚗', color: Color(0xFFE53935), shadowColor: Color(0xFFB71C1C)),
    _ShapeInfo(type: ShapeType.boat, label: '배', emoji: '⛵', color: Color(0xFF64B5F6), shadowColor: Color(0xFF1976D2)),

    // --- 건물 ---
    _ShapeInfo(type: ShapeType.house, label: '집', emoji: '🏠', color: Color(0xFFFFCC80), shadowColor: Color(0xFFEF6C00)),
    _ShapeInfo(type: ShapeType.castle, label: '성', emoji: '🏰', color: Color(0xFFBCAAA4), shadowColor: Color(0xFF795548)),
  ];

  /// 단계별 도형 개수
  int get _shapeCountForLevel {
    // 레벨에 따라 도형 개수가 점진적으로 증가하며, 화면 레이아웃을 위해 최대 6개로 제한
    int count = _level + 1;
    if (count > 6) {
      return 6;
    }
    return count;
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

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _startNewRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    _bgAnimController.dispose();
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
    // 레벨 제한 없이 무한히 상승하여 다양한 조합을 계속 즐길 수 있도록 함
    _level++;
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
              colors: [Color(0xFFE8F4F8), Color(0xFFFFF9EE), Color(0xFFFFEFF3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // 아기자기한 감성 플레이룸 배경 (가랜드, 구름, 반짝이 별, 파스텔 힐)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgAnimController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CharmingPlayroomBackgroundPainter(
                        animValue: _bgAnimController.value,
                      ),
                    );
                  },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 뒤로가기 버튼 (깔끔하고 고급스러운 글래스모피즘 원형 버튼)
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFFF5252),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 중앙 타이틀 (깔끔하고 아기자기한 프리미엄 캡슐 배지)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -1),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 미니 컬러 도형 아이콘 조합
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCA28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF29B6F6),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '모양 쏙쏙',
                    style: GoogleFonts.jua(
                      fontSize: 19,
                      color: const Color(0xFF37474F),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                    ),
                    child: Text(
                      '원목놀이',
                      style: GoogleFonts.jua(
                        fontSize: 11,
                        color: const Color(0xFFE65100),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 단계 선택 버튼 (고급스러운 골든 앰버 캡슐 배지)
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
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF9800),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '$_level단계',
                    style: GoogleFonts.jua(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 18,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x108D6E63),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧩', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '알맞은 모양을 쏙 넣어봐요!',
            style: GoogleFonts.jua(
              fontSize: 14,
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
              border: Border.all(color: const Color(0xFFFFD54F), width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x338D6E63),
                  blurRadius: 24,
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
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x442E7D32),
                          offset: Offset(0, 6),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '다음 단계 도전! 🚀',
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
              constraints: const BoxConstraints(maxWidth: 350),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2A8D6E63),
                    offset: Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더: 타이틀 + 닫기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                            ),
                            child: const Text('⭐', style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '모양 몇 개 맞출까?',
                                style: GoogleFonts.jua(fontSize: 19, color: const Color(0xFF37474F)),
                              ),
                              Text(
                                '도전할 단계를 골라보세요!',
                                style: GoogleFonts.jua(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Color(0xFF78909C), size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 현재 레벨이 20보다 큰 경우 안내 배지
                  if (_level > 20) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 현재 $_level단계 진행 중! (대단해요!)',
                        style: GoogleFonts.jua(fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // 5x4 단계 그리드 (1~20단계 깔끔한 배치)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      final lv = index + 1;
                      final count = (lv + 1) > 6 ? 6 : (lv + 1);
                      final isActive = _level == lv;

                      return GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() {
                            _level = lv;
                          });
                          Navigator.pop(ctx);
                          _startNewRound();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFFFDE7)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? Colors.white : const Color(0xFFFFE082),
                              width: isActive ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isActive
                                    ? const Color(0x66FF9800)
                                    : const Color(0x128D6E63),
                                offset: const Offset(0, 3),
                                blurRadius: isActive ? 6 : 3,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$lv',
                                style: GoogleFonts.jua(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.white : const Color(0xFF4E342E),
                                ),
                              ),
                              Text(
                                '$count개',
                                style: GoogleFonts.jua(
                                  fontSize: 10.5,
                                  color: isActive
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : const Color(0xFFFB8C00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 하단 안내 설명 카드 (조잡한 반복 텍스트 대신 명확한 1줄 가이드)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '1~5단계는 모양이 2~6개로 늘어나고, 6단계부터는 22가지 다양한 모양이 랜덤 등장해요!',
                            style: GoogleFonts.jua(
                              fontSize: 11,
                              color: const Color(0xFF6D4C41),
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

/// 아기자기한 감성 플레이룸 배경 페인터 (가랜드, 둥실둥실 구름, 반짝이 별, 파스텔 힐)
class _CharmingPlayroomBackgroundPainter extends CustomPainter {
  final double animValue;

  _CharmingPlayroomBackgroundPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 은은한 도트 패턴
    _drawPolkaDots(canvas, size);

    // 2. 하단 둥근 언덕 (부드러운 파스텔 힐)
    _drawBottomHills(canvas, size);

    // 3. 둥실둥실 떠다니는 귀여운 표정 구름들
    _drawCuteClouds(canvas, size);

    // 4. 공간을 채우는 아기자기한 미니 도형 & 반짝이 별 & 비눗방울
    _drawFloatingAccents(canvas, size);

    // 5. 상단 삼각 가랜드 (Bunting Flags)
    _drawTopGarland(canvas, size);
  }

  void _drawPolkaDots(Canvas canvas, Size size) {
    final dotColors = [
      const Color(0x18FF8A80),
      const Color(0x1880D8FF),
      const Color(0x18FFD180),
      const Color(0x18B9F6CA),
      const Color(0x18EA80FC),
    ];
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const step = 44.0;
    int idx = 0;
    for (double y = 50; y < size.height - 40; y += step) {
      final isOdd = (idx % 2 == 1);
      for (double x = isOdd ? step : step / 2; x < size.width; x += step) {
        dotPaint.color = dotColors[(idx + (x ~/ step)) % dotColors.length];
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
      idx++;
    }
  }

  void _drawBottomHills(Canvas canvas, Size size) {
    final hillPaint1 = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final hillPath1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 75)
      ..quadraticBezierTo(size.width * 0.35, size.height - 110, size.width * 0.75, size.height - 65)
      ..quadraticBezierTo(size.width * 0.9, size.height - 45, size.width, size.height - 55)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath1, hillPaint1);

    final hillPaint2 = Paint()
      ..color = const Color(0xFFFFF9C4).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final hillPath2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(size.width * 0.25, size.height - 60, size.width * 0.55, size.height - 35)
      ..quadraticBezierTo(size.width * 0.8, size.height - 15, size.width, size.height - 30)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath2, hillPaint2);
  }

  void _drawCuteClouds(Canvas canvas, Size size) {
    // 좌상단 구름
    final c1Y = 78 + sin(animValue * 2 * pi) * 5;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.16, c1Y),
      width: 88,
      height: 48,
      hasHappyFace: true,
    );

    // 우상단 구름
    final c2Y = 115 + cos(animValue * 2 * pi) * 6;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.86, c2Y),
      width: 76,
      height: 42,
      hasHappyFace: true,
    );

    // 좌하단 은은한 작은 구름
    final c3Y = size.height * 0.52 + sin(animValue * 2 * pi + 1.5) * 4;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.08, c3Y),
      width: 60,
      height: 34,
      hasHappyFace: false,
      alpha: 0.55,
    );

    // 우하단 은은한 작은 구름
    final c4Y = size.height * 0.62 + cos(animValue * 2 * pi + 2.0) * 4;
    _drawCloud(
      canvas: canvas,
      center: Offset(size.width * 0.92, c4Y),
      width: 66,
      height: 36,
      hasHappyFace: false,
      alpha: 0.55,
    );
  }

  void _drawCloud({
    required Canvas canvas,
    required Offset center,
    required double width,
    required double height,
    required bool hasHappyFace,
    double alpha = 0.92,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: alpha * 0.25)
      ..style = PaintingStyle.fill;

    // 구름 몽실몽실 원들
    final r = height / 2;
    void drawPuffs(Paint p) {
      canvas.drawCircle(Offset(-width * 0.22, 0), r * 0.85, p);
      canvas.drawCircle(Offset(0, -r * 0.28), r * 1.05, p);
      canvas.drawCircle(Offset(width * 0.24, 0), r * 0.8, p);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, r * 0.2), width: width * 0.85, height: r * 0.85),
          Radius.circular(r * 0.5),
        ),
        p,
      );
    }

    // 부드러운 하단 음영
    canvas.save();
    canvas.translate(0, 3.5);
    drawPuffs(shadowPaint);
    canvas.restore();

    // 메인 화이트 구름
    drawPuffs(cloudPaint);

    if (hasHappyFace) {
      final eyePaint = Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final blushPaint = Paint()
        ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      // 볼터치
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 4), width: 7, height: 4.5),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(14, 4), width: 7, height: 4.5),
        blushPaint,
      );

      // 눈 웃음 ^ ^
      final eyePath1 = Path()
        ..moveTo(-12, 1)
        ..quadraticBezierTo(-9, -3.5, -6, 1);
      final eyePath2 = Path()
        ..moveTo(6, 1)
        ..quadraticBezierTo(9, -3.5, 12, 1);
      canvas.drawPath(eyePath1, eyePaint);
      canvas.drawPath(eyePath2, eyePaint);

      // 미소
      final smilePaint = Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final smilePath = Path()
        ..moveTo(-3.5, 3.5)
        ..quadraticBezierTo(0, 7.0, 3.5, 3.5);
      canvas.drawPath(smilePath, smilePaint);
    }

    canvas.restore();
  }

  void _drawFloatingAccents(Canvas canvas, Size size) {
    // 반짝이 4포인트 별들
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.11, size.height * 0.28 + sin(animValue * 2 * pi + 0.5) * 6),
      size: 14 + sin(animValue * 2 * pi) * 2,
      color: const Color(0xFFFFCA28),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.89, size.height * 0.26 + cos(animValue * 2 * pi + 1.2) * 6),
      size: 13 + cos(animValue * 2 * pi) * 2,
      color: const Color(0xFFFF80AB),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.88, size.height * 0.72 + sin(animValue * 2 * pi + 2.0) * 5),
      size: 12,
      color: const Color(0xFF40C4FF),
    );
    _drawSparkleStar(
      canvas,
      Offset(size.width * 0.12, size.height * 0.76 + cos(animValue * 2 * pi + 3.0) * 5),
      size: 11,
      color: const Color(0xFFB388FF),
    );

    // 파스텔 미니 비눗방울 / 원목 구슬
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.07, size.height * 0.42 + cos(animValue * 2 * pi + 2.5) * 5),
      radius: 9,
      color: const Color(0xFFFF8A80),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.93, size.height * 0.46 + sin(animValue * 2 * pi + 1.8) * 5),
      radius: 11,
      color: const Color(0xFF80D8FF),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.20, size.height * 0.86 + sin(animValue * 2 * pi + 4.0) * 4),
      radius: 7,
      color: const Color(0xFFFFD180),
    );
    _drawPastelBubble(
      canvas,
      Offset(size.width * 0.82, size.height * 0.88 + cos(animValue * 2 * pi + 4.5) * 4),
      radius: 8,
      color: const Color(0xFFA7FFEB),
    );
  }

  void _drawSparkleStar(Canvas canvas, Offset center, {required double size, required Color color}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = size / 2;
    path.moveTo(0, -r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.quadraticBezierTo(0, 0, -r, 0);
    path.quadraticBezierTo(0, 0, 0, -r);
    canvas.drawPath(path, paint);

    // 중앙 작은 화이트 반짝임
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, r * 0.28, whitePaint);

    canvas.restore();
  }

  void _drawPastelBubble(Canvas canvas, Offset center, {required double radius, required Color color}) {
    final bubblePaint = Paint()
      ..color = color.withValues(alpha: 0.38)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bubblePaint);

    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);

    // 하이라이트 글린트
    final glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - radius * 0.32, center.dy - radius * 0.32), radius * 0.28, glintPaint);
  }

  void _drawTopGarland(Canvas canvas, Size size) {
    const flagColors = [
      Color(0xFFFF8DA1),
      Color(0xFFFFD54F),
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
      Color(0xFFFFB74D),
      Color(0xFF4DD0E1),
      Color(0xFFFF80AB),
      Color(0xFFAED581),
    ];

    final stringPaint = Paint()
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final stringPath = Path()
      ..moveTo(-10, 8)
      ..quadraticBezierTo(size.width * 0.5, 30, size.width + 10, 8);
    canvas.drawPath(stringPath, stringPaint);

    const int flagCount = 9;
    final flagWidth = size.width / (flagCount + 0.6);
    final flagHeight = flagWidth * 0.95;

    for (int i = 0; i < flagCount; i++) {
      final t = (i + 0.8) / (flagCount + 0.6);
      final x = t * size.width;
      final y = (1 - t) * (1 - t) * 8 + 2 * (1 - t) * t * 30 + t * t * 8;

      // 미세한 가랜드 살랑거림 애니메이션
      final sway = sin(animValue * 2 * pi + i * 0.8) * 2.5;

      final flagPaint = Paint()
        ..color = flagColors[i % flagColors.length].withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;

      final flagShadow = Paint()
        ..color = const Color(0x18000000)
        ..style = PaintingStyle.fill;

      final flagPath = Path()
        ..moveTo(x - flagWidth * 0.45, y)
        ..lineTo(x + flagWidth * 0.45, y)
        ..lineTo(x + sway, y + flagHeight)
        ..close();

      // 그림자
      canvas.save();
      canvas.translate(0, 2);
      canvas.drawPath(flagPath, flagShadow);
      canvas.restore();

      // 깃발
      canvas.drawPath(flagPath, flagPaint);

      // 깃발 꼭대기 작은 고정 방울 핀
      final pinPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 2.2, pinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CharmingPlayroomBackgroundPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
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
    case ShapeType.star: return _starPath(r);
    case ShapeType.heart: return _heartPath(r);
    case ShapeType.diamond:
      return Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.75, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.75, 0)
        ..close();
    case ShapeType.hexagon: return _polygonPath(6, r);
    case ShapeType.pentagon: return _polygonPath(5, r);
    case ShapeType.cross: return _crossPath(r);
    case ShapeType.moon: return _moonPath(r);
    
    // 추가된 다양한 형태들
    case ShapeType.bear: return _bearPath(r);
    case ShapeType.rabbit: return _rabbitPath(r);
    case ShapeType.cat: return _catPath(r);
    case ShapeType.fish: return _fishPath(r);
    case ShapeType.bird: return _birdPath(r);
    case ShapeType.flower: return _flowerPath(r);
    case ShapeType.tree: return _treePath(r);
    case ShapeType.cloud: return _cloudPath(r);
    case ShapeType.car: return _carPath(r);
    case ShapeType.boat: return _boatPath(r);
    case ShapeType.house: return _housePath(r);
    case ShapeType.castle: return _castlePath(r);
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

// ── 추가된 형태 (동물, 건물, 등등) ──────────────────────────────────────────────────────────

Path _bearPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.55, -r * 0.55), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.55, -r * 0.55), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.1), radius: r * 0.85));
  return path;
}

Path _rabbitPath(double r) {
  final path = Path();
  path.addOval(Rect.fromCenter(center: Offset(-r * 0.35, -r * 0.4), width: r * 0.35, height: r * 1.4));
  path.addOval(Rect.fromCenter(center: Offset(r * 0.35, -r * 0.4), width: r * 0.35, height: r * 1.4));
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.4), radius: r * 0.75));
  return path;
}

Path _catPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.7, -r * 0.1);
  path.lineTo(-r * 0.85, -r * 0.9);
  path.lineTo(-r * 0.1, -r * 0.5);
  path.moveTo(r * 0.7, -r * 0.1);
  path.lineTo(r * 0.85, -r * 0.9);
  path.lineTo(r * 0.1, -r * 0.5);
  path.addOval(Rect.fromCircle(center: Offset(0, r * 0.2), radius: r * 0.8));
  return path;
}

Path _fishPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.4, 0);
  path.lineTo(-r * 1.1, -r * 0.6);
  path.lineTo(-r * 1.1, r * 0.6);
  path.addOval(Rect.fromCenter(center: Offset(r * 0.1, 0), width: r * 1.6, height: r * 1.1));
  return path;
}

Path _birdPath(double r) {
  final path = Path();
  path.moveTo(r * 0.6, -r * 0.4);
  path.lineTo(r * 1.1, -r * 0.2);
  path.lineTo(r * 0.6, 0);
  path.moveTo(-r * 0.6, r * 0.2);
  path.lineTo(-r * 1.2, r * 0.6);
  path.lineTo(-r * 1.0, -r * 0.1);
  path.addOval(Rect.fromCircle(center: Offset(r * 0.4, -r * 0.3), radius: r * 0.4));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.1, r * 0.2), radius: r * 0.65));
  return path;
}

Path _flowerPath(double r) {
  final path = Path();
  final int petals = 6;
  for (int i = 0; i < petals; i++) {
    final angle = 2 * pi * i / petals;
    final cx = cos(angle) * r * 0.55;
    final cy = sin(angle) * r * 0.55;
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.45));
  }
  path.addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.4));
  return path;
}

Path _treePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.5), width: r * 0.35, height: r));
  path.addOval(Rect.fromCircle(center: Offset(0, -r * 0.4), radius: r * 0.65));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.45, -r * 0.1), radius: r * 0.45));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.45, -r * 0.1), radius: r * 0.45));
  return path;
}

Path _cloudPath(double r) {
  final path = Path();
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 1.8, height: r * 0.8),
    Radius.circular(r * 0.4),
  ));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.4, -r * 0.1), radius: r * 0.5));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.3, -r * 0.2), radius: r * 0.6));
  return path;
}

Path _carPath(double r) {
  final path = Path();
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(0, r * 0.2), width: r * 2.0, height: r * 0.7),
    Radius.circular(r * 0.2),
  ));
  path.addRRect(RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset(-r * 0.1, -r * 0.3), width: r * 1.2, height: r * 0.6),
    Radius.circular(r * 0.3),
  ));
  path.addOval(Rect.fromCircle(center: Offset(-r * 0.6, r * 0.6), radius: r * 0.35));
  path.addOval(Rect.fromCircle(center: Offset(r * 0.6, r * 0.6), radius: r * 0.35));
  return path;
}

Path _boatPath(double r) {
  final path = Path();
  path.moveTo(-r * 0.8, r * 0.2);
  path.lineTo(r * 0.8, r * 0.2);
  path.lineTo(r * 0.5, r * 0.7);
  path.lineTo(-r * 0.5, r * 0.7);
  path.close();
  path.addRect(Rect.fromCenter(center: Offset(r * 0.1, -r * 0.4), width: r * 0.1, height: r * 1.2));
  path.moveTo(r * 0.15, -r * 0.9);
  path.lineTo(r * 0.8, -r * 0.1);
  path.lineTo(r * 0.15, -r * 0.1);
  path.close();
  return path;
}

Path _housePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.4), width: r * 1.2, height: r * 1.0));
  path.moveTo(-r * 0.8, -r * 0.1);
  path.lineTo(r * 0.8, -r * 0.1);
  path.lineTo(0, -r * 0.9);
  path.close();
  path.addRect(Rect.fromCenter(center: Offset(r * 0.5, -r * 0.5), width: r * 0.25, height: r * 0.7));
  return path;
}

Path _castlePath(double r) {
  final path = Path();
  path.addRect(Rect.fromCenter(center: Offset(0, r * 0.4), width: r * 1.4, height: r * 1.0));
  path.addRect(Rect.fromCenter(center: Offset(0, -r * 0.3), width: r * 0.4, height: r * 0.8));
  path.addRect(Rect.fromCenter(center: Offset(-r * 0.7, 0), width: r * 0.4, height: r * 1.8));
  path.addRect(Rect.fromCenter(center: Offset(r * 0.7, 0), width: r * 0.4, height: r * 1.8));
  
  path.moveTo(-r * 0.9, -r * 0.9);
  path.lineTo(-r * 0.5, -r * 0.9);
  path.lineTo(-r * 0.7, -r * 1.3);
  path.close();

  path.moveTo(r * 0.9, -r * 0.9);
  path.lineTo(r * 0.5, -r * 0.9);
  path.lineTo(r * 0.7, -r * 1.3);
  path.close();

  path.moveTo(-r * 0.2, -r * 0.7);
  path.lineTo(r * 0.2, -r * 0.7);
  path.lineTo(0, -r * 1.1);
  path.close();
  return path;
}
