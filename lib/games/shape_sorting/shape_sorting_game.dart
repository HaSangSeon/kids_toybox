import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shape Sorting Game — 모양 쏙쏙! (4~5세 톡톡 쉬운 놀이)
// Rive 시바 친구와 함께하는 프리미엄 3D 원목 모양 맞추기 놀이
// ─────────────────────────────────────────────────────────────────────────────

part 'models/shape_sorting_models.dart';
part 'widgets/shape_sorting_widgets.dart';
part 'painters/shape_sorting_painters.dart';

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
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  // ── Game State ──
  int _level = 1; // 1 ~ 20 단계
  int _totalStars = 0;
  int _rewardChestTapCount = 0;
  bool _showingLevelComplete = false;
  ShapeThemeCategory _selectedTheme = ShapeThemeCategory.all;

  // 라운드 데이터
  late List<_ShapeInfo> _roundShapes;
  late List<ShapeType> _remainingPieces;
  final Set<ShapeType> _filledShapes = {};
  ShapeType? _justSnappedShape;

  // 시바 친구 인터랙션
  String _shibaSpeech = '알맞은 모양을 쏙쏙 넣어봐 멍! 🧩';
  bool _isShibaCelebrating = false;
  Timer? _shibaCelebrationTimer;

  final List<_SparkleParticle> _particles = [];
  final Random _rng = Random();

  // 도형 마스터 목록 (다양한 테마: 기본, 동물, 식물, 탈것, 건물)
  static const List<_ShapeInfo> _allShapes = [
    // --- 기본 도형 ---
    _ShapeInfo(type: ShapeType.triangle, label: '세모', emoji: '🔺', color: Color(0xFFFF5252), shadowColor: Color(0xFFD32F2F), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.square, label: '네모', emoji: '🟧', color: Color(0xFFFF9800), shadowColor: Color(0xFFF57C00), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.circle, label: '동그라미', emoji: '🔵', color: Color(0xFF29B6F6), shadowColor: Color(0xFF0288D1), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.star, label: '별', emoji: '⭐', color: Color(0xFFFFCA28), shadowColor: Color(0xFFFFA000), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.heart, label: '하트', emoji: '❤️', color: Color(0xFFFF4081), shadowColor: Color(0xFFC2185B), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.diamond, label: '마름모', emoji: '💎', color: Color(0xFFAB47BC), shadowColor: Color(0xFF7B1FA2), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.hexagon, label: '육각형', emoji: '⬡', color: Color(0xFF26A69A), shadowColor: Color(0xFF00796B), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.pentagon, label: '오각형', emoji: '⬠', color: Color(0xFF5C6BC0), shadowColor: Color(0xFF3949AB), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.cross, label: '십자', emoji: '➕', color: Color(0xFF66BB6A), shadowColor: Color(0xFF388E3C), category: ShapeThemeCategory.shapes),
    _ShapeInfo(type: ShapeType.moon, label: '달', emoji: '🌙', color: Color(0xFF8E24AA), shadowColor: Color(0xFF6A1B9A), category: ShapeThemeCategory.shapes),

    // --- 동물 ---
    _ShapeInfo(type: ShapeType.bear, label: '곰', emoji: '🐻', color: Color(0xFF8D6E63), shadowColor: Color(0xFF5D4037), category: ShapeThemeCategory.animals),
    _ShapeInfo(type: ShapeType.rabbit, label: '토끼', emoji: '🐰', color: Color(0xFFF48FB1), shadowColor: Color(0xFFC2185B), category: ShapeThemeCategory.animals),
    _ShapeInfo(type: ShapeType.cat, label: '고양이', emoji: '🐱', color: Color(0xFFFFB74D), shadowColor: Color(0xFFF57C00), category: ShapeThemeCategory.animals),
    _ShapeInfo(type: ShapeType.fish, label: '물고기', emoji: '🐟', color: Color(0xFF4DD0E1), shadowColor: Color(0xFF0097A7), category: ShapeThemeCategory.animals),
    _ShapeInfo(type: ShapeType.bird, label: '새', emoji: '🐦', color: Color(0xFFBA68C8), shadowColor: Color(0xFF7B1FA2), category: ShapeThemeCategory.animals),

    // --- 자연 & 식물 ---
    _ShapeInfo(type: ShapeType.flower, label: '꽃', emoji: '🌸', color: Color(0xFFFF8A80), shadowColor: Color(0xFFD50000), category: ShapeThemeCategory.nature),
    _ShapeInfo(type: ShapeType.tree, label: '나무', emoji: '🌳', color: Color(0xFF81C784), shadowColor: Color(0xFF388E3C), category: ShapeThemeCategory.nature),
    _ShapeInfo(type: ShapeType.cloud, label: '구름', emoji: '☁️', color: Color(0xFFE0E0E0), shadowColor: Color(0xFF9E9E9E), category: ShapeThemeCategory.nature),

    // --- 탈것 ---
    _ShapeInfo(type: ShapeType.car, label: '자동차', emoji: '🚗', color: Color(0xFFE53935), shadowColor: Color(0xFFB71C1C), category: ShapeThemeCategory.vehicles),
    _ShapeInfo(type: ShapeType.boat, label: '배', emoji: '⛵', color: Color(0xFF64B5F6), shadowColor: Color(0xFF1976D2), category: ShapeThemeCategory.vehicles),

    // --- 건물 ---
    _ShapeInfo(type: ShapeType.house, label: '집', emoji: '🏠', color: Color(0xFFFFCC80), shadowColor: Color(0xFFEF6C00), category: ShapeThemeCategory.vehicles),
    _ShapeInfo(type: ShapeType.castle, label: '성', emoji: '🏰', color: Color(0xFFBCAAA4), shadowColor: Color(0xFF795548), category: ShapeThemeCategory.vehicles),
  ];

  /// 단계별 도형 개수 (최대 6개)
  int get _shapeCountForLevel {
    int count = _level + 1;
    if (count > 6) return 6;
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

    // 상자 흔들기 셰이크 애니메이션
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _startNewRound();
  }

  @override
  void dispose() {
    _shibaCelebrationTimer?.cancel();
    _confettiController.dispose();
    _floatController.dispose();
    _bgAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Round Logic ──────────────────────────────────────────────────────────

  void _startNewRound() {
    final count = _shapeCountForLevel;

    // 선택된 테마에 맞는 도형 풀 필터링
    List<_ShapeInfo> candidateShapes = _selectedTheme == ShapeThemeCategory.all
        ? List<_ShapeInfo>.from(_allShapes)
        : _allShapes.where((s) => s.category == _selectedTheme).toList();

    if (candidateShapes.length < count) {
      // 테마별 후보가 적으면 전체에서 채움
      candidateShapes = List<_ShapeInfo>.from(_allShapes);
    }

    final shuffled = List<_ShapeInfo>.from(candidateShapes)..shuffle(_rng);
    _roundShapes = shuffled.take(count).toList();

    // 트레이에는 섞인 순서로 배치
    final pieceTypes = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
    _remainingPieces = pieceTypes;
    _filledShapes.clear();
    _justSnappedShape = null;
    _showingLevelComplete = false;
    _rewardChestTapCount = 0;
    _shibaSpeech = '알맞은 모양을 쏙쏙 넣어봐 멍! 🧩';

    setState(() {});
  }

  /// 우르르 쏟기 (Toy Box Shake & Dump)
  void _shakeAndPour() {
    if (_filledShapes.isEmpty) {
      AudioManager.instance.playCardFlip();
      _setShibaSpeech('아직 맞춘 모양이 없어 멍! 먼저 맞춰봐~ 🧩', celebrate: false);
      return;
    }

    AudioManager.instance.playCardFlip();
    AudioManager.instance.playThud();
    HapticFeedback.heavyImpact();

    _shakeController.forward(from: 0.0);

    setState(() {
      _remainingPieces = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
      _filledShapes.clear();
      _justSnappedShape = null;
    });

    _setShibaSpeech('우르르~ 쏟았다! 다시 쏙쏙 맞춰봐 멍! 🎲', celebrate: true);
  }

  /// 원터치 쏙 맞추기 (Tap to Snap)
  void _onPieceTapped(ShapeType tappedType) {
    if (!_remainingPieces.contains(tappedType)) return;

    // 해당 도형이 보드에 있고 아직 채워지지 않았으면 즉시 쏙!
    if (_roundShapes.any((s) => s.type == tappedType) && !_filledShapes.contains(tappedType)) {
      _onShapeDropped(tappedType, tappedType, Offset.zero);
    }
  }

  void _onShapeDropped(ShapeType droppedType, ShapeType targetType, Offset dropPos) {
    if (droppedType == targetType && !_filledShapes.contains(targetType)) {
      // 정답 스냅!
      AudioManager.instance.playCardMatch();
      HapticFeedback.mediumImpact();

      final shapeInfo = _getShapeInfo(targetType);

      // 동물이나 탈것일 경우 실감나는 효과음 추가 재생
      AudioManager.instance.playEmojiSound(shapeInfo.emoji);

      setState(() {
        _filledShapes.add(targetType);
        _remainingPieces.remove(droppedType);
        _justSnappedShape = targetType;
      });

      _setShibaSpeech('${shapeInfo.label} 쏙! 참 잘했어 멍! 💖', celebrate: true);
      _spawnSparkles(dropPos, shapeInfo.color);

      // 전체 완료 체크
      if (_filledShapes.length == _roundShapes.length) {
        Future.delayed(const Duration(milliseconds: 650), _onRoundComplete);
      }
    } else {
      // 오답 튕김
      AudioManager.instance.playCardMismatch();
      HapticFeedback.lightImpact();
      _setShibaSpeech('어라? 다른 구멍인가 봐 멍! 다시 해봐~ 🐾', celebrate: false);
    }
  }

  void _setShibaSpeech(String speech, {required bool celebrate}) {
    _shibaCelebrationTimer?.cancel();
    setState(() {
      _shibaSpeech = speech;
      if (celebrate) _isShibaCelebrating = true;
    });

    if (celebrate) {
      _shibaCelebrationTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isShibaCelebrating = false;
          });
        }
      });
    }
  }

  void _spawnSparkles(Offset center, Color color) {
    final cx = center == Offset.zero ? 200.0 : center.dx;
    final cy = center == Offset.zero ? 300.0 : center.dy;

    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.0 + _rng.nextDouble() * 4.0;
      _particles.add(_SparkleParticle(
        x: cx,
        y: cy,
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

    _totalStars += 3;

    setState(() {
      _showingLevelComplete = true;
    });

    _setShibaSpeech('우와! 전부 다 맞췄다 멍! 최고야! 🏆', celebrate: true);
  }

  void _nextRound() {
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
              // 아기자기한 감성 플레이룸 배경
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
                    const SizedBox(height: 4),

                    // 시바 친구 컴패니언 셸프 & 말풍선 & 우르르 쏟기 버튼
                    _buildMascotShelf(),
                    const SizedBox(height: 6),

                    // 테마 선택 칩 바
                    _buildThemeChipsBar(),
                    const SizedBox(height: 8),

                    // 메인 퍼즐 보드 (흔들기 애니메이션 적용)
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) {
                            final shakeOffset = sin(_shakeAnim.value * pi * 4) * 8.0;
                            final shakeAngle = sin(_shakeAnim.value * pi * 4) * 0.04;
                            return Transform.translate(
                              offset: Offset(shakeOffset, 0),
                              child: Transform.rotate(
                                angle: shakeAngle,
                                child: child,
                              ),
                            );
                          },
                          child: _buildPuzzleBoard(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 하단 원목 도형 트레이 (터치 또는 드래그 지원)
                    _buildPieceTray(),
                    const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
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
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFFF5252),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 중앙 타이틀
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧩', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '모양 쏙쏙',
                    style: GoogleFonts.jua(
                      fontSize: 17,
                      color: const Color(0xFF37474F),
                      fontWeight: FontWeight.bold,
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
          const SizedBox(width: 8),

          // 단계 선택 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _showDifficultyDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF9800),
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '$_level단계',
                    style: GoogleFonts.jua(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 시바 친구 마스코트 셸프 & 말풍선 & 우르르 쏟기 ───────────────────────

  Widget _buildMascotShelf() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Rive 시바 마스코트 아바타
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFB74D), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: RiveAnimation.asset(
                'assets/rive/dog.riv',
                artboard: 'Shiba',
                animations: [_isShibaCelebrating ? 'WinEndState' : 'Anim_shiba'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 시바의 실시간 말풍선
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x108D6E63),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                _shibaSpeech,
                style: GoogleFonts.jua(
                  fontSize: 13,
                  color: const Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 우르르 쏟기 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _shakeAndPour,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 3),
                    Text(
                      '쏟기',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 테마 선택 칩 바 ──────────────────────────────────────────────────

  Widget _buildThemeChipsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ShapeThemeCategory.values.map((theme) {
          final isSelected = _selectedTheme == theme;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (_selectedTheme == theme) return;
                AudioManager.instance.playClick();
                setState(() {
                  _selectedTheme = theme;
                });
                _startNewRound();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF9800) : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.white : const Color(0xFFFFE082),
                    width: isSelected ? 2 : 1.2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Text(
                  theme.label,
                  style: GoogleFonts.jua(
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF6D4C41),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Puzzle Board (아기자기한 원목 퍼즐 판) ──────────────────────────────

  Widget _buildPuzzleBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _roundShapes.length;

        final int crossAxisCount = count <= 3 ? count : (count == 4 ? 2 : 3);
        final double maxBoardW = min(constraints.maxWidth - 28, 420.0);

        final double spacing = 12.0;
        final double totalHSpacing = spacing * (crossAxisCount + 1);
        final double cardWidth = ((maxBoardW - 32) - totalHSpacing) / crossAxisCount;
        final double cardSize = cardWidth.clamp(78.0, 110.0);

        return Container(
          width: maxBoardW,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFFFE082),
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
              const Positioned(top: -4, left: -4, child: _WoodPeg()),
              const Positioned(top: -4, right: -4, child: _WoodPeg()),
              const Positioned(bottom: -4, left: -4, child: _WoodPeg()),
              const Positioned(bottom: -4, right: -4, child: _WoodPeg()),

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

  // ── Piece Tray (하단 도형 진열대: 탭 또는 드래그 가능) ─────────────────────

  Widget _buildPieceTray() {
    if (_remainingPieces.isEmpty) {
      return Container(
        height: 80,
        alignment: Alignment.center,
        child: Text(
          '우와! 모든 모양이 쏙 들어갔어요! 💖',
          style: GoogleFonts.jua(fontSize: 16, color: const Color(0xFF6D4C41)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '👇 터치하거나 끌어다 쏙 넣어보세요!',
                style: GoogleFonts.jua(fontSize: 12, color: Colors.brown.shade400),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
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
        ],
      ),
    );
  }

  /// 드래그 및 원터치 쏙 지원 3D 원목 블록
  Widget _buildDraggableBlock(_ShapeInfo info) {
    const double blockSize = 76.0;

    return GestureDetector(
      onTap: () => _onPieceTapped(info.type),
      child: Draggable<ShapeType>(
        data: info.type,
        onDragStarted: () {
          AudioManager.instance.playCardFlip();
          HapticFeedback.lightImpact();
          _setShibaSpeech('거기가 맞을까? 쏙 넣어봐 멍! 🌟', celebrate: false);
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
      ),
    );
  }

  // ── Completion Overlay (Rive Rating & Rewards 적용) ──────────────────────

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFDE7), Colors.white],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFFD54F), width: 4),
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
                // Rive 5-Star Rating 세레머니
                const SizedBox(
                  width: 140,
                  height: 55,
                  child: RiveAnimation.asset(
                    'assets/rive/rating.riv',
                    animations: ['5_stars'],
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  '참 잘했어요!',
                  style: GoogleFonts.jua(
                    fontSize: 28,
                    color: KidsTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '모든 모양을 쏙쏙 맞췄어요! ❤️',
                  style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.textLight),
                ),
                const SizedBox(height: 12),

                // 완성된 도형 아이콘들
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _roundShapes.map((s) {
                    return Text(s.emoji, style: const TextStyle(fontSize: 26));
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 보물상자 터치 보너스 인터랙션 (Rive rewards.riv)
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playRacingItemStar();
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _rewardChestTapCount++;
                      _totalStars += 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 44,
                          height: 44,
                          child: RiveAnimation.asset(
                            'assets/rive/rewards.riv',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '보물상자 톡톡! 🎁',
                              style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFD97706)),
                            ),
                            Text(
                              '+${3 + _rewardChestTapCount} ⭐ (총 $_totalStars개)',
                              style: GoogleFonts.jua(fontSize: 12, color: Colors.brown),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 다음 단계 버튼
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    _nextRound();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                          style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
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
