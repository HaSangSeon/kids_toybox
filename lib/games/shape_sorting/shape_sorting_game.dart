import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shape Sorting Game — 모양 쏙쏙! (4~5세 눈높이 한국어 음성 & 프리미엄 원목 교구 놀이)
// Rive 시바 친구와 함께하는 아기자기하고 고급스러운 3D 원목 모양 맞추기
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
  late AnimationController _hintPulseController;
  late Ticker _particleTicker;

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
  ShapeType? _hintedShape;
  Timer? _hintTimer;

  // 시바 친구 인터랙션
  String _shibaSpeech = '같은 모양 구멍을 찾아 쏙쏙 넣어볼까요? 🧩';
  bool _isShibaCelebrating = false;
  Timer? _shibaCelebrationTimer;

  final List<_SparkleParticle> _particles = [];
  final Random _rng = Random();

  // 도형 마스터 목록 (다양한 테마: 기본, 동물, 식물, 탈것, 건물)
  static const List<_ShapeInfo> _allShapes = [
    // --- 기본 도형 ---
    _ShapeInfo(
      type: ShapeType.triangle,
      label: '세모',
      funTitle: '뾰족뾰족 세모',
      emoji: '🔺',
      color: Color(0xFFFF5252),
      shadowColor: Color(0xFFC62828),
      lightColor: Color(0xFFFF8A80),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.square,
      label: '네모',
      funTitle: '반듯반듯 네모',
      emoji: '🟧',
      color: Color(0xFFFF9800),
      shadowColor: Color(0xFFE65100),
      lightColor: Color(0xFFFFCC80),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.circle,
      label: '동그라미',
      funTitle: '데구르르 동그라미',
      emoji: '🔵',
      color: Color(0xFF29B6F6),
      shadowColor: Color(0xFF0277BD),
      lightColor: Color(0xFF81D4FA),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.star,
      label: '별',
      funTitle: '반짝반짝 별',
      emoji: '⭐',
      color: Color(0xFFFFCA28),
      shadowColor: Color(0xFFF57F17),
      lightColor: Color(0xFFFFF59D),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.heart,
      label: '하트',
      funTitle: '사랑해 하트',
      emoji: '❤️',
      color: Color(0xFFFF4081),
      shadowColor: Color(0xFFAD1457),
      lightColor: Color(0xFFFF80AB),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.diamond,
      label: '마름모',
      funTitle: '반짝이는 마름모',
      emoji: '💎',
      color: Color(0xFFAB47BC),
      shadowColor: Color(0xFF6A1B9A),
      lightColor: Color(0xFFE1BEE7),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.hexagon,
      label: '육각형',
      funTitle: '벌집 모양 육각형',
      emoji: '⬡',
      color: Color(0xFF26A69A),
      shadowColor: Color(0xFF00695C),
      lightColor: Color(0xFF80CBC4),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.pentagon,
      label: '오각형',
      funTitle: '멋진 오각형',
      emoji: '⬠',
      color: Color(0xFF5C6BC0),
      shadowColor: Color(0xFF283593),
      lightColor: Color(0xFF9FA8DA),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.cross,
      label: '십자',
      funTitle: '더하기 모양 십자',
      emoji: '➕',
      color: Color(0xFF66BB6A),
      shadowColor: Color(0xFF2E7D32),
      lightColor: Color(0xFFA5D6A7),
      category: ShapeThemeCategory.shapes,
    ),
    _ShapeInfo(
      type: ShapeType.moon,
      label: '초승달',
      funTitle: '밤하늘 초승달',
      emoji: '🌙',
      color: Color(0xFF8E24AA),
      shadowColor: Color(0xFF4A148C),
      lightColor: Color(0xFFCE93D8),
      category: ShapeThemeCategory.shapes,
    ),

    // --- 동물 ---
    _ShapeInfo(
      type: ShapeType.bear,
      label: '곰돌이',
      funTitle: '귀여운 곰돌이',
      emoji: '🐻',
      color: Color(0xFFA1887F),
      shadowColor: Color(0xFF5D4037),
      lightColor: Color(0xFFD7CCC8),
      category: ShapeThemeCategory.animals,
    ),
    _ShapeInfo(
      type: ShapeType.rabbit,
      label: '토끼',
      funTitle: '깡충깡충 토끼',
      emoji: '🐰',
      color: Color(0xFFF48FB1),
      shadowColor: Color(0xFFC2185B),
      lightColor: Color(0xFFF8BBD0),
      category: ShapeThemeCategory.animals,
    ),
    _ShapeInfo(
      type: ShapeType.cat,
      label: '고양이',
      funTitle: '야옹야옹 고양이',
      emoji: '🐱',
      color: Color(0xFFFFB74D),
      shadowColor: Color(0xFFEF6C00),
      lightColor: Color(0xFFFFE0B2),
      category: ShapeThemeCategory.animals,
    ),
    _ShapeInfo(
      type: ShapeType.fish,
      label: '물고기',
      funTitle: '뻐끔뻐끔 물고기',
      emoji: '🐟',
      color: Color(0xFF26C6DA),
      shadowColor: Color(0xFF00838F),
      lightColor: Color(0xFF80DEEA),
      category: ShapeThemeCategory.animals,
    ),
    _ShapeInfo(
      type: ShapeType.bird,
      label: '아기 새',
      funTitle: '짹짹 아기 새',
      emoji: '🐦',
      color: Color(0xFFBA68C8),
      shadowColor: Color(0xFF7B1FA2),
      lightColor: Color(0xFFE1BEE7),
      category: ShapeThemeCategory.animals,
    ),

    // --- 자연 & 식물 ---
    _ShapeInfo(
      type: ShapeType.flower,
      label: '꽃',
      funTitle: '향기로운 꽃',
      emoji: '🌸',
      color: Color(0xFFFF8A80),
      shadowColor: Color(0xFFD32F2F),
      lightColor: Color(0xFFFFCDD2),
      category: ShapeThemeCategory.nature,
    ),
    _ShapeInfo(
      type: ShapeType.tree,
      label: '나무',
      funTitle: '푸른 나무',
      emoji: '🌳',
      color: Color(0xFF66BB6A),
      shadowColor: Color(0xFF2E7D32),
      lightColor: Color(0xFFC8E6C9),
      category: ShapeThemeCategory.nature,
    ),
    _ShapeInfo(
      type: ShapeType.cloud,
      label: '구름',
      funTitle: '몽실몽실 구름',
      emoji: '☁️',
      color: Color(0xFF90CAF9),
      shadowColor: Color(0xFF1976D2),
      lightColor: Color(0xFFE3F2FD),
      category: ShapeThemeCategory.nature,
    ),

    // --- 탈것 ---
    _ShapeInfo(
      type: ShapeType.car,
      label: '자동차',
      funTitle: '부릉부릉 자동차',
      emoji: '🚗',
      color: Color(0xFFEF5350),
      shadowColor: Color(0xFFB71C1C),
      lightColor: Color(0xFFFFCDD2),
      category: ShapeThemeCategory.vehicles,
    ),
    _ShapeInfo(
      type: ShapeType.boat,
      label: '돛단배',
      funTitle: '둥실둥실 돛단배',
      emoji: '⛵',
      color: Color(0xFF42A5F5),
      shadowColor: Color(0xFF1565C0),
      lightColor: Color(0xFFBBDEFB),
      category: ShapeThemeCategory.vehicles,
    ),

    // --- 건물 ---
    _ShapeInfo(
      type: ShapeType.house,
      label: '우리 집',
      funTitle: '포근한 우리 집',
      emoji: '🏠',
      color: Color(0xFFFFB74D),
      shadowColor: Color(0xFFE65100),
      lightColor: Color(0xFFFFE0B2),
      category: ShapeThemeCategory.vehicles,
    ),
    _ShapeInfo(
      type: ShapeType.castle,
      label: '성',
      funTitle: '멋진 왕자님 공주님 성',
      emoji: '🏰',
      color: Color(0xFF9575CD),
      shadowColor: Color(0xFF512DA8),
      lightColor: Color(0xFFD1C4E9),
      category: ShapeThemeCategory.vehicles,
    ),
  ];

  /// 단계별 도형 개수 (최대 6개)
  int get _shapeCountForLevel {
    final count = _level + 1;
    return count > 6 ? 6 : count;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -3.5, end: 3.5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    _hintPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _particleTicker = createTicker((_) {
      if (_particles.isNotEmpty) {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.10; // 부드러운 중력
          p.rotation += p.vRot;
          p.life -= 0.025;
        }
        _particles.removeWhere((p) => p.life <= 0);
        setState(() {});
      }
    })..start();

    _startNewRound(playIntroVoice: true);
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _shibaCelebrationTimer?.cancel();
    _particleTicker.dispose();
    _hintPulseController.dispose();
    _confettiController.dispose();
    _floatController.dispose();
    _bgAnimController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Round Logic ──────────────────────────────────────────────────────────

  void _startNewRound({bool playIntroVoice = false}) {
    final count = _shapeCountForLevel;

    List<_ShapeInfo> candidateShapes = _selectedTheme == ShapeThemeCategory.all
        ? List<_ShapeInfo>.from(_allShapes)
        : _allShapes.where((s) => s.category == _selectedTheme).toList();

    if (candidateShapes.length < count) {
      candidateShapes = List<_ShapeInfo>.from(_allShapes);
    }

    final shuffled = List<_ShapeInfo>.from(candidateShapes)..shuffle(_rng);
    _roundShapes = shuffled.take(count).toList();

    final pieceTypes = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
    _remainingPieces = pieceTypes;
    _filledShapes.clear();
    _justSnappedShape = null;
    _hintedShape = null;
    _showingLevelComplete = false;
    _rewardChestTapCount = 0;
    _shibaSpeech = '빈 구멍을 톡! 누르면 모양 이름을 알려줘 멍! 🔊';

    setState(() {});

    if (playIntroVoice) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          AudioManager.instance.playShapeGuideVoice('intro');
        }
      });
    }
  }

  /// 힌트 버튼 또는 빈 구멍 터치 시 음성 안내 + 마법 하이라이트
  void _triggerShapeHint(ShapeType targetType) {
    final info = _getShapeInfo(targetType);
    _hintTimer?.cancel();
    HapticFeedback.selectionClick();
    AudioManager.instance.playChime();
    AudioManager.instance.playShapeNameVoice(targetType.name);

    setState(() {
      _hintedShape = targetType;
      _shibaSpeech = '${info.emoji} "${info.funTitle}" 조각을 찾아 넣어봐 멍! ✨';
    });

    _hintTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          if (_hintedShape == targetType) _hintedShape = null;
        });
      }
    });
  }

  /// 이미 맞춘 블록을 다시 터치했을 때: 통통 튀며 음성 + 효과음 재생
  void _onFilledSlotTapped(_ShapeInfo info, Offset globalCenter) {
    HapticFeedback.lightImpact();
    AudioManager.instance.playShapeNameVoice(info.type.name);
    setState(() {
      _justSnappedShape = info.type;
    });
    _setShibaSpeech('${info.emoji} ${info.funTitle}! 정말 예쁘다 멍! 💖', celebrate: true);
    _spawnSparkles(globalCenter, info.color);
  }

  /// 남은 조각 중 하나를 시바가 음성으로 힌트 주기
  void _speakNextHintFromMascot() {
    if (_remainingPieces.isEmpty) {
      AudioManager.instance.playShapeGuideVoice('clear');
      return;
    }
    final nextType = _remainingPieces.first;
    _triggerShapeHint(nextType);
  }

  /// 우르르 쏟기 (Toy Box Shake & Dump)
  void _shakeAndPour() {
    if (_filledShapes.isEmpty) {
      AudioManager.instance.playCardFlip();
      _speakNextHintFromMascot();
      return;
    }

    AudioManager.instance.playCardFlip();
    AudioManager.instance.playThud();
    AudioManager.instance.playShapeGuideVoice('pour');
    HapticFeedback.heavyImpact();

    _shakeController.forward(from: 0.0);

    setState(() {
      _remainingPieces = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
      _filledShapes.clear();
      _justSnappedShape = null;
      _hintedShape = null;
    });

    _setShibaSpeech('우르르~ 쏟았다! 다시 쏙쏙 맞춰볼까요 멍! 🎲', celebrate: true);
  }

  /// 원터치 쏙 맞추기 (Tap to Snap)
  void _onPieceTapped(ShapeType tappedType, Offset globalPos) {
    if (!_remainingPieces.contains(tappedType)) return;

    if (_roundShapes.any((s) => s.type == tappedType) &&
        !_filledShapes.contains(tappedType)) {
      _onShapeDropped(tappedType, tappedType, globalPos);
    }
  }

  void _onShapeDropped(
      ShapeType droppedType, ShapeType targetType, Offset dropPos) {
    if (droppedType == targetType && !_filledShapes.contains(targetType)) {
      // 정답 스냅!
      HapticFeedback.mediumImpact();
      final shapeInfo = _getShapeInfo(targetType);
      final stepIdx = _filledShapes.length;

      // 실로폰 음계 + 원목 스냅음 + 테마 효과음 + 한국어 음성 ("세모, 쏙!")
      AudioManager.instance.playShapeMatchRich(
        shapeName: targetType.name,
        stepIndex: stepIdx,
      );

      setState(() {
        _filledShapes.add(targetType);
        _remainingPieces.remove(droppedType);
        _justSnappedShape = targetType;
        if (_hintedShape == targetType) _hintedShape = null;
      });

      _setShibaSpeech(
        '${shapeInfo.emoji} ${shapeInfo.funTitle} 쏙! 참 잘했어 멍! 💖',
        celebrate: true,
      );
      _spawnSparkles(dropPos, shapeInfo.color);

      // 전체 완료 체크
      if (_filledShapes.length == _roundShapes.length) {
        Future.delayed(const Duration(milliseconds: 950), _onRoundComplete);
      }
    } else {
      // 오답 튕김
      AudioManager.instance.playCardMismatch();
      AudioManager.instance.playShapeGuideVoice('wrong');
      HapticFeedback.lightImpact();
      final targetInfo = _getShapeInfo(targetType);
      _setShibaSpeech(
        '앗! 여기는 "${targetInfo.label}" 집이야 멍! 다시 찾아볼까? 🐾',
        celebrate: false,
      );
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
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    final cx = center == Offset.zero ? size.width / 2 : center.dx;
    final cy = center == Offset.zero ? size.height * 0.45 : center.dy;

    final palette = [
      color,
      const Color(0xFFFFD54F),
      const Color(0xFFFF80AB),
      const Color(0xFF40C4FF),
      const Color(0xFF69F0AE),
    ];

    for (int i = 0; i < 22; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.2 + _rng.nextDouble() * 5.2;
      _particles.add(_SparkleParticle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 1.5,
        size: 7 + _rng.nextDouble() * 7,
        life: 1.0,
        color: palette[i % palette.length],
        rotation: _rng.nextDouble() * pi,
        vRot: (_rng.nextDouble() - 0.5) * 0.18,
        kind: i % 3,
      ));
    }
  }

  void _onRoundComplete() {
    if (!mounted) return;
    _confettiController.play();
    AudioManager.instance.playFeedAnimalsSuccess();
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        AudioManager.instance.playShapeGuideVoice('clear');
      }
    });
    HapticFeedback.heavyImpact();

    setState(() {
      _totalStars += 3;
      _showingLevelComplete = true;
    });

    _setShibaSpeech('우와! 모든 모양을 다 맞췄어요! 최고야 멍! 🏆', celebrate: true);
  }

  void _nextRound() {
    _level++;
    _startNewRound(playIntroVoice: false);
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
              colors: [
                Color(0xFFE3F4FA),
                Color(0xFFFFF9EE),
                Color(0xFFFFEFF4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // 1. 아기자기한 감성 플레이룸 배경
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

              // 2. 메인 게임 레이아웃
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),

                    // 시바 친구 컴패니언 셸프 & 음성 힌트 버튼 & 쏟기 버튼
                    _buildMascotShelf(),
                    const SizedBox(height: 6),

                    // 테마 선택 칩 바
                    _buildThemeChipsBar(),
                    const SizedBox(height: 8),

                    // 메인 원목 퍼즐 보드 (흔들기 애니메이션 적용)
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _shakeAnim,
                          builder: (context, child) {
                            final shakeOffset =
                                sin(_shakeAnim.value * pi * 4) * 8.0;
                            final shakeAngle =
                                sin(_shakeAnim.value * pi * 4) * 0.04;
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

                    const SizedBox(height: 8),

                    // 하단 원목 도형 트레이 (터치 또는 드래그 지원)
                    _buildPieceTray(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // 3. 마법 별·하트 스파클 파티클 레이어
              if (_particles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SparkleOverlayPainter(particles: _particles),
                    ),
                  ),
                ),

              // 4. 컨페티 팡파레
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 38,
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

              // 5. 클리어 팝업
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                color: Colors.white.withValues(alpha: 0.96),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFE082), width: 2),
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

          // 중앙 타이틀 + 누적 스타 배지
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFFDF5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFE082), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x148D6E63),
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
                  Flexible(
                    child: Text(
                      '모양 쏙쏙',
                      style: GoogleFonts.jua(
                        fontSize: 17,
                        color: const Color(0xFF4E342E),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text(
                          '$_totalStars',
                          style: GoogleFonts.jua(
                            fontSize: 12,
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
                  colors: [Color(0xFFFFB74D), Color(0xFFFF8F00)],
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

  // ── 시바 친구 마스코트 셸프 & 음성 힌트 & 쏟기 ──────────────────────────

  Widget _buildMascotShelf() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Rive 시바 마스코트 아바타 (터치 시 음성 힌트!)
          GestureDetector(
            onTap: _speakNextHintFromMascot,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFFDE7), Color(0xFFFFE082)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: RiveAnimation.asset(
                      'assets/rive/dog.riv',
                      artboard: 'Shiba',
                      animations: [
                        _isShibaCelebrating ? 'WinEndState' : 'Anim_shiba'
                      ],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4081),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 시바의 실시간 말풍선 (터치해도 음성 힌트 재생!)
          Expanded(
            child: GestureDetector(
              onTap: _speakNextHintFromMascot,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: const Color(0xFFFFD54F), width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x148D6E63),
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _shibaSpeech,
                    key: ValueKey<String>(_shibaSpeech),
                    style: GoogleFonts.jua(
                      fontSize: 13,
                      color: const Color(0xFF4E342E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 🔊 음성 힌트 듣기 버튼
          _VoiceWaveBadge(
            isActive: _hintedShape != null,
            onTap: _speakNextHintFromMascot,
          ),
          const SizedBox(width: 6),

          // 우르르 쏟기 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _shakeAndPour,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎲', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 3),
                    Text(
                      '쏟기',
                      style:
                          GoogleFonts.jua(fontSize: 12.5, color: Colors.white),
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
                _startNewRound(playIntroVoice: false);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.accentColor,
                            Color.lerp(
                                theme.accentColor, const Color(0xFFBF360C), 0.25)!,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        isSelected ? Colors.white : const Color(0xFFFFE082),
                    width: isSelected ? 2 : 1.4,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Text(
                  theme.label,
                  style: GoogleFonts.jua(
                    fontSize: 12.5,
                    color: isSelected ? Colors.white : const Color(0xFF5D4037),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Puzzle Board (고급 몬테소리 원목 퍼즐 교구 보드) ──────────────────────

  Widget _buildPuzzleBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _roundShapes.length;
        final filledCount = _filledShapes.length;

        final int crossAxisCount = count <= 3 ? count : (count == 4 ? 2 : 3);
        final double maxBoardW = min(constraints.maxWidth - 24, 430.0);

        const double spacing = 12.0;
        final double totalHSpacing = spacing * (crossAxisCount + 1);
        final double cardWidth =
            ((maxBoardW - 36) - totalHSpacing) / crossAxisCount;
        final double cardSize = cardWidth.clamp(82.0, 118.0);

        return Container(
          width: maxBoardW,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFDF7),
                Color(0xFFFFF8E7),
                Color(0xFFFDF1D6),
              ],
            ),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
              color: const Color(0xFFE6B86A),
              width: 5.5,
            ),
            boxShadow: const [
              // 원목 보드 하단 두툼한 3D 나무 두께감
              BoxShadow(
                color: Color(0xFFC49245),
                offset: Offset(0, 7),
                blurRadius: 0,
              ),
              BoxShadow(
                color: Color(0x285D4037),
                offset: Offset(0, 14),
                blurRadius: 22,
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

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 보드 상단 미니 별 진행도 플레이트
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7E7C8).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE0B675),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(count, (idx) {
                          final isDone = idx < filledCount;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: AnimatedScale(
                              scale: isDone ? 1.15 : 0.95,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.elasticOut,
                              child: Text(
                                isDone ? '🌟' : '🤍',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '$filledCount / $count 쏙쏙!',
                          style: GoogleFonts.jua(
                            fontSize: 12.5,
                            color: const Color(0xFF6D4C41),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 도형 슬롯 그리드
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: spacing,
                          runSpacing: spacing,
                          children: _roundShapes.map((shapeInfo) {
                            return _buildSlotTargetCard(shapeInfo, cardSize);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 개별 슬롯 타겟 카드 (빈 구멍 터치 시 한국어 음성 힌트 & 맞춘 도형 터치 시 재재생!)
  Widget _buildSlotTargetCard(_ShapeInfo shapeInfo, double size) {
    final isFilled = _filledShapes.contains(shapeInfo.type);
    final isJustSnapped = _justSnappedShape == shapeInfo.type;
    final isHinted = _hintedShape == shapeInfo.type && !isFilled;

    return Builder(
      builder: (cardContext) {
        Offset getCardCenter() {
          final renderBox = cardContext.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            return renderBox.localToGlobal(
              Offset(renderBox.size.width / 2, renderBox.size.height / 2),
            );
          }
          return Offset.zero;
        }

        return DragTarget<ShapeType>(
          onWillAcceptWithDetails: (details) => !isFilled,
          onAcceptWithDetails: (details) {
            _onShapeDropped(details.data, shapeInfo.type, getCardCenter());
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return GestureDetector(
              onTap: () {
                if (isFilled) {
                  _onFilledSlotTapped(shapeInfo, getCardCenter());
                } else {
                  _triggerShapeHint(shapeInfo.type);
                }
              },
              child: AnimatedBuilder(
                animation: _hintPulseController,
                builder: (context, child) {
                  final pulseScale = isHinted
                      ? 1.0 + (_hintPulseController.value * 0.05)
                      : 1.0;
                  return Transform.scale(
                    scale: pulseScale,
                    child: child,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: size,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isFilled
                          ? [
                              Colors.white,
                              shapeInfo.lightColor.withValues(alpha: 0.35),
                            ]
                          : (isHovering || isHinted)
                              ? [
                                  Colors.white,
                                  shapeInfo.lightColor.withValues(alpha: 0.45),
                                ]
                              : const [
                                  Color(0xFFFAF3E3),
                                  Color(0xFFF3E6CE),
                                ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: (isHovering || isHinted)
                          ? shapeInfo.color
                          : (isFilled
                              ? shapeInfo.color.withValues(alpha: 0.55)
                              : const Color(0xFFDFC9A6)),
                      width: (isHovering || isHinted) ? 3.2 : 2.2,
                    ),
                    boxShadow: (isHovering || isHinted)
                        ? [
                            BoxShadow(
                              color: shapeInfo.color.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: isFilled
                                  ? shapeInfo.color.withValues(alpha: 0.18)
                                  : const Color(0x14795548),
                              offset: const Offset(0, 3),
                              blurRadius: 6,
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
                                key: ValueKey<String>(
                                    '${shapeInfo.type.name}_$isJustSnapped'),
                                tween: Tween(
                                  begin: isJustSnapped ? 0.35 : 1.0,
                                  end: 1.0,
                                ),
                                duration: const Duration(milliseconds: 520),
                                curve: Curves.elasticOut,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                      scale: scale, child: child);
                                },
                                child: CustomPaint(
                                  painter: _ChunkyBlockPainter(
                                    type: shapeInfo.type,
                                    color: shapeInfo.color,
                                    shadowColor: shapeInfo.shadowColor,
                                    lightColor: shapeInfo.lightColor,
                                    isHappy: true,
                                  ),
                                ),
                              )
                            : CustomPaint(
                                painter: _SlotHolePainter(
                                  type: shapeInfo.type,
                                  accentColor: shapeInfo.color,
                                  isHovering: isHovering,
                                  isHinted: isHinted,
                                ),
                              ),
                      ),
                      const SizedBox(height: 6),

                      // 도형 이름 라벨 배지 + 미니 스피커 아이콘
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: isFilled
                              ? LinearGradient(
                                  colors: [
                                    shapeInfo.color,
                                    shapeInfo.shadowColor,
                                  ],
                                )
                              : null,
                          color: isFilled ? null : Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: isFilled
                                ? Colors.white.withValues(alpha: 0.8)
                                : (isHinted
                                    ? shapeInfo.color
                                    : const Color(0xFFD7CCC8)),
                            width: 1.4,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                shapeInfo.label,
                                style: GoogleFonts.jua(
                                  fontSize: 12.5,
                                  color: isFilled
                                      ? Colors.white
                                      : const Color(0xFF5D4037),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.volume_up_rounded,
                              size: 11,
                              color: isFilled
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : shapeInfo.color,
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
      },
    );
  }

  // ── Piece Tray (하단 고급 원목 도형 진열대: 탭 또는 드래그 가능) ─────────

  Widget _buildPieceTray() {
    if (_remainingPieces.isEmpty) {
      return Container(
        height: 86,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF8E1)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFD54F), width: 3),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '우와! 모든 모양이 쏙 들어갔어요! 💖',
                style: GoogleFonts.jua(
                  fontSize: 16,
                  color: const Color(0xFF5D4037),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFFAF0)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFCA28), width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE0A82E),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x22795548),
            offset: Offset(0, 10),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '모양을 톡! 터치하거나 구멍으로 끌어다 놓아보세요',
                style: GoogleFonts.jua(
                  fontSize: 12,
                  color: const Color(0xFF795548),
                ),
              ),
              const SizedBox(width: 4),
              const Text('✨', style: TextStyle(fontSize: 12)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildDraggableBlock(info),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 드래그 및 원터치 쏙 지원 3D 원목 블록 (한국어 음성 피드백 연동)
  Widget _buildDraggableBlock(_ShapeInfo info) {
    const double blockSize = 72.0;
    final isHinted = _hintedShape == info.type;

    return Builder(
      builder: (blockContext) {
        return GestureDetector(
          onTap: () {
            final rb = blockContext.findRenderObject() as RenderBox?;
            final pos = rb != null
                ? rb.localToGlobal(
                    Offset(rb.size.width / 2, rb.size.height / 2))
                : Offset.zero;
            _onPieceTapped(info.type, pos);
          },
          child: Draggable<ShapeType>(
            data: info.type,
            onDragStarted: () {
              AudioManager.instance.playCardFlip();
              AudioManager.instance.playShapeNameVoice(info.type.name);
              HapticFeedback.lightImpact();
              _setShibaSpeech(
                '${info.emoji} "${info.funTitle}"! 어디로 들어갈까 멍? 🌟',
                celebrate: false,
              );
            },
            feedback: Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 1.22,
                child: SizedBox(
                  width: blockSize,
                  height: blockSize,
                  child: CustomPaint(
                    painter: _ChunkyBlockPainter(
                      type: info.type,
                      color: info.color,
                      shadowColor: info.shadowColor,
                      lightColor: info.lightColor,
                      isDragging: true,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.25,
              child: _buildTrayBlockCard(info, blockSize, isHinted: false),
            ),
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatAnim, _hintPulseController]),
              builder: (context, child) {
                final dy = isHinted
                    ? -6.0 * _hintPulseController.value
                    : _floatAnim.value;
                final scale = isHinted
                    ? 1.0 + 0.08 * _hintPulseController.value
                    : 1.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: _buildTrayBlockCard(info, blockSize, isHinted: isHinted),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrayBlockCard(_ShapeInfo info, double blockSize,
      {required bool isHinted}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: isHinted
            ? info.lightColor.withValues(alpha: 0.45)
            : const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHinted
              ? info.color
              : info.color.withValues(alpha: 0.35),
          width: isHinted ? 2.6 : 1.5,
        ),
        boxShadow: [
          if (isHinted)
            BoxShadow(
              color: info.color.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: blockSize,
            height: blockSize,
            child: CustomPaint(
              painter: _ChunkyBlockPainter(
                type: info.type,
                color: info.color,
                shadowColor: info.shadowColor,
                lightColor: info.lightColor,
                isHinted: isHinted,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            info.label,
            style: GoogleFonts.jua(
              fontSize: 12,
              color: const Color(0xFF5D4037),
            ),
          ),
        ],
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
            constraints: const BoxConstraints(maxWidth: 355),
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
                  style: GoogleFonts.jua(
                      fontSize: 15, color: KidsTheme.textLight),
                ),
                const SizedBox(height: 12),

                // 완성된 도형 칩 (터치하면 그 모양의 한국어 음성을 다시 들려줌!)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: _roundShapes.map((s) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioManager.instance.playShapeNameVoice(s.type.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: s.lightColor.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: s.color, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Text(
                              s.label,
                              style: GoogleFonts.jua(
                                fontSize: 13,
                                color: const Color(0xFF4E342E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // 보물상자 터치 보너스 인터랙션 (Rive rewards.riv)
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playRacingItemStar();
                    if (_rewardChestTapCount % 2 == 0) {
                      AudioManager.instance.playShapeGuideVoice('cheer2');
                    }
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _rewardChestTapCount++;
                      _totalStars += 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
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
                              style: GoogleFonts.jua(
                                  fontSize: 13,
                                  color: const Color(0xFFD97706)),
                            ),
                            Text(
                              '+${3 + _rewardChestTapCount} ⭐ (총 $_totalStars개)',
                              style: GoogleFonts.jua(
                                  fontSize: 12, color: Colors.brown),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
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
                          style: GoogleFonts.jua(
                              fontSize: 18, color: Colors.white),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border:
                    Border.all(color: const Color(0xFFFFD54F), width: 2.5),
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
                              border: Border.all(
                                  color: const Color(0xFFFFB74D), width: 1.5),
                            ),
                            child: const Text('⭐',
                                style: TextStyle(fontSize: 18)),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '모양 몇 개 맞출까?',
                                style: GoogleFonts.jua(
                                    fontSize: 19,
                                    color: const Color(0xFF37474F)),
                              ),
                              Text(
                                '도전할 단계를 골라보세요!',
                                style: GoogleFonts.jua(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
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
                          child: const Icon(Icons.close_rounded,
                              color: Color(0xFF78909C), size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_level > 20) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '🔥 현재 $_level단계 진행 중! (대단해요!)',
                        style: GoogleFonts.jua(
                            fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                          _startNewRound(playIntroVoice: false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFFB74D),
                                      Color(0xFFFF9800)
                                    ],
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
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFFFFE082),
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
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF4E342E),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFFFE082), width: 1.2),
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
