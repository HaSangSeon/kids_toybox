import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum BrushStep {
  selectAnimal, // 동물 친구 고르기
  eating,       // 간식 먹고 이 더러워지기
  selectPaste,  // 맛있는 치약 고르기
  brushing,     // 쓱싹쓱싹 양치질
  rinsing,      // 가글가글 물로 헹구기
  complete,     // 반짝반짝 축하 & 보상
}

class _AnimalFriend {
  final String id;
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Color faceColor;
  final Color mouthColor;
  final String favoriteSnack;
  final String cheerMessage;
  final String soundPath;

  const _AnimalFriend({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.faceColor,
    required this.mouthColor,
    required this.favoriteSnack,
    required this.cheerMessage,
    required this.soundPath,
  });
}

const List<_AnimalFriend> _kAnimals = [
  _AnimalFriend(
    id: 'croco',
    name: '아기 악어 크롱이',
    emoji: '🐊',
    primaryColor: Color(0xFF66BB6A),
    secondaryColor: Color(0xFF388E3C),
    faceColor: Color(0xFFA5D6A7),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍫 달콤 초콜릿',
    cheerMessage: '우와! 내 이빨이 반짝반짝해! 크아앙~ 고마워! 🐊✨',
    soundPath: 'audio/animal_hippo.wav',
  ),
  _AnimalFriend(
    id: 'hippo',
    name: '하마 포포',
    emoji: '🦛',
    primaryColor: Color(0xFFAB47BC),
    secondaryColor: Color(0xFF7B1FA2),
    faceColor: Color(0xFFCE93D8),
    mouthColor: Color(0xFFFF80AB),
    favoriteSnack: '🍩 딸기 도넛',
    cheerMessage: '와아! 입안이 정말 상쾌해! 하마마~ 고마워! 🦛💖',
    soundPath: 'audio/animal_hippo.wav',
  ),
  _AnimalFriend(
    id: 'tiger',
    name: '아기 호랑이 어흥이',
    emoji: '🐯',
    primaryColor: Color(0xFFFFA726),
    secondaryColor: Color(0xFFF57C00),
    faceColor: Color(0xFFFFCC80),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍭 알록달록 사탕',
    cheerMessage: '어흥! 세균 몬스터를 다 무찔렀어! 최고야! 🐯🔥',
    soundPath: 'audio/animal_lion.wav',
  ),
  _AnimalFriend(
    id: 'bear',
    name: '곰돌이 몽이',
    emoji: '🐻',
    primaryColor: Color(0xFF8D6E63),
    secondaryColor: Color(0xFF5D4037),
    faceColor: Color(0xFFBCAAA4),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍪 달콤 쿠키',
    cheerMessage: '꿀맛 쿠키 먹고 양치까지 완벽해! 몽몽 고마워! 🐻🍯',
    soundPath: 'audio/animal_bear.wav',
  ),
  _AnimalFriend(
    id: 'lion',
    name: '아기 사자 레오',
    emoji: '🦁',
    primaryColor: Color(0xFFFFCA28),
    secondaryColor: Color(0xFFFFA000),
    faceColor: Color(0xFFFFE082),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍦 달콤 아이스크림',
    cheerMessage: '으르렁! 사자 왕의 이빨처럼 눈부셔! 🦁👑',
    soundPath: 'audio/animal_lion.wav',
  ),
  _AnimalFriend(
    id: 'rabbit',
    name: '토끼 토리',
    emoji: '🐰',
    primaryColor: Color(0xFFF06292),
    secondaryColor: Color(0xFFC2185B),
    faceColor: Color(0xFFF8BBD0),
    mouthColor: Color(0xFFFF80AB),
    favoriteSnack: '🧁 달콤 컵케이크',
    cheerMessage: '깡총깡총! 새하얀 앞니가 너무 마음에 들어! 🐰🌸',
    soundPath: 'audio/animal_rabbit.wav',
  ),
];

class _Toothpaste {
  final String name;
  final String flavor;
  final String emoji;
  final Color color;
  final Color foamColor;

  const _Toothpaste({
    required this.name,
    required this.flavor,
    required this.emoji,
    required this.color,
    required this.foamColor,
  });
}

const List<_Toothpaste> _kPastes = [
  _Toothpaste(
    name: '딸기 치약',
    flavor: '달콤한 딸기향 🍓',
    emoji: '🍓',
    color: Color(0xFFFF4081),
    foamColor: Color(0xFFFFCDD2),
  ),
  _Toothpaste(
    name: '바나나 치약',
    flavor: '부드러운 바나나향 🍌',
    emoji: '🍌',
    color: Color(0xFFFFD600),
    foamColor: Color(0xFFFFF9C4),
  ),
  _Toothpaste(
    name: '포도 치약',
    flavor: '향긋한 포도향 🍇',
    emoji: '🍇',
    color: Color(0xFFAB47BC),
    foamColor: Color(0xFFE1BEE7),
  ),
  _Toothpaste(
    name: '민트 치약',
    flavor: '시원 상쾌한 민트향 🌿',
    emoji: '🌿',
    color: Color(0xFF26A69A),
    foamColor: Color(0xFFB2DFDB),
  ),
];

class _Snack {
  final String name;
  final String emoji;
  final Color stainColor;

  const _Snack({required this.name, required this.emoji, required this.stainColor});
}

const List<_Snack> _kSnacks = [
  _Snack(name: '초콜릿', emoji: '🍫', stainColor: Color(0xFF5D4037)),
  _Snack(name: '막대사탕', emoji: '🍭', stainColor: Color(0xFFE91E63)),
  _Snack(name: '도넛', emoji: '🍩', stainColor: Color(0xFF8D6E63)),
  _Snack(name: '아이스크림', emoji: '🍦', stainColor: Color(0xFFFFB300)),
  _Snack(name: '쿠키', emoji: '🍪', stainColor: Color(0xFF795548)),
  _Snack(name: '콜라', emoji: '🥤', stainColor: Color(0xFF3E2723)),
];

class _ToothState {
  final int index;
  final bool isTop;
  final double xRatio; // 0.0 ~ 1.0 (relative to 280x280 canvas)
  final double yRatio; // 0.0 ~ 1.0
  final double width;
  final double height;
  double cleanliness; // 0.0 (dirty) ~ 1.0 (clean)
  Color stainColor;
  bool hasMonster;
  String monsterEmoji;

  _ToothState({
    required this.index,
    required this.isTop,
    required this.xRatio,
    required this.yRatio,
    required this.width,
    required this.height,
    this.cleanliness = 0.0,
    this.stainColor = const Color(0xFF5D4037),
    this.hasMonster = true,
    this.monsterEmoji = '👾',
  });
}

class _FoamParticle {
  Offset pos;
  double radius;
  Color color;
  double life; // 1.0 -> 0.0
  _FoamParticle({required this.pos, required this.radius, required this.color, required this.life});
}

class _WaterParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;
  _WaterParticle({required this.pos, required this.vel, required this.radius, required this.life, required this.color});
}

class _Sparkle {
  Offset pos;
  double size;
  double opacity;
  double rotation;
  Color color;
  _Sparkle({required this.pos, required this.size, required this.opacity, required this.rotation, required this.color});
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOOTH BRUSHING GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class ToothBrushingGame extends StatefulWidget {
  const ToothBrushingGame({super.key});

  @override
  State<ToothBrushingGame> createState() => _ToothBrushingGameState();
}

class _ToothBrushingGameState extends State<ToothBrushingGame> with TickerProviderStateMixin {
  BrushStep _step = BrushStep.selectAnimal;
  _AnimalFriend _animal = _kAnimals[0];
  _Toothpaste _paste = _kPastes[0];
  _Snack _selectedSnack = _kSnacks[0];

  final List<_ToothState> _teeth = [];
  final List<_FoamParticle> _foams = [];
  final List<_WaterParticle> _waterDrops = [];
  final List<_Sparkle> _sparkles = [];
  final Random _rng = Random();

  Offset? _brushTouchPos;
  double _rinseProgress = 0.0;

  late AnimationController _chewCtrl;
  late AnimationController _sparkleLoopCtrl;
  late AnimationController _mascotJumpCtrl;
  late AnimationController _brushWiggleCtrl;
  late AnimationController _snackFlyCtrl;
  late AnimationController _ambientBubbleCtrl;

  _Snack? _flyingSnack;
  bool _isEating = false;
  String? _customDialogue;

  @override
  void initState() {
    super.initState();
    _chewCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _sparkleLoopCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _mascotJumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _brushWiggleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _snackFlyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _ambientBubbleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

    _initTeeth();
  }

  @override
  void dispose() {
    _chewCtrl.dispose();
    _sparkleLoopCtrl.dispose();
    _mascotJumpCtrl.dispose();
    _brushWiggleCtrl.dispose();
    _snackFlyCtrl.dispose();
    _ambientBubbleCtrl.dispose();
    super.dispose();
  }

  bool _hasDecayed = false;
  int? _pokedToothIndex;

  void _initTeeth() {
    _teeth.clear();
    _hasDecayed = false;
    _pokedToothIndex = null;
    const monsters = ['👾', '😈', '🦠', '🪱'];

    // ── 4 Top Big Cute Baby Teeth (큼직하고 몽글몽글한 윗니 4개) ──
    final topX = [0.32, 0.44, 0.56, 0.68];
    final topY = [0.536, 0.540, 0.540, 0.536];
    final topW = [30.0, 32.0, 32.0, 30.0];
    final topH = [27.0, 29.0, 29.0, 27.0];

    for (int i = 0; i < 4; i++) {
      _teeth.add(_ToothState(
        index: i,
        isTop: true,
        xRatio: topX[i],
        yRatio: topY[i],
        width: topW[i],
        height: topH[i],
        cleanliness: 1.0,
        stainColor: _selectedSnack.stainColor,
        hasMonster: false,
        monsterEmoji: monsters[i % monsters.length],
      ));
    }

    // ── 4 Bottom Big Cute Baby Teeth (큼직하고 몽글몽글한 아랫니 4개) ──
    final botX = [0.325, 0.442, 0.558, 0.675];
    final botY = [0.718, 0.712, 0.712, 0.718];
    final botW = [29.0, 31.0, 31.0, 29.0];
    final botH = [25.0, 26.5, 26.5, 25.0];

    for (int i = 0; i < 4; i++) {
      _teeth.add(_ToothState(
        index: i + 4,
        isTop: false,
        xRatio: botX[i],
        yRatio: botY[i],
        width: botW[i],
        height: botH[i],
        cleanliness: 1.0,
        stainColor: _selectedSnack.stainColor,
        hasMonster: false,
        monsterEmoji: monsters[(i + 2) % monsters.length],
      ));
    }
  }

  double get _totalCleanliness {
    if (_teeth.isEmpty) return 0.0;
    final sum = _teeth.fold<double>(0.0, (prev, t) => prev + t.cleanliness);
    return (sum / _teeth.length).clamp(0.0, 1.0);
  }

  // ── Step Transitions ────────────────────────────────────────────────────────

  void _onSelectAnimal(_AnimalFriend animal) {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _animal = animal;
      _step = BrushStep.eating;
      _customDialogue = null;
      _isEating = false;
      _flyingSnack = null;
      _initTeeth();
    });
  }

  Future<void> _feedSnackWithEffect(_Snack snack, GlobalKey cardKey) async {
    if (_isEating) return;

    // 1. Play sound & haptic
    AudioManager.instance.playEffect('audio/item_heart.wav', rate: 1.15);
    HapticFeedback.lightImpact();

    // 2. Start flying snack animation into mouth
    setState(() {
      _isEating = true;
      _flyingSnack = snack;
      _selectedSnack = snack;
      _customDialogue = '냠냠냠! ${snack.name} 정말 달콤하다! 😋';
    });

    await _snackFlyCtrl.forward(from: 0.0);

    // 3. Chomping & munching sound effects
    for (int i = 0; i < 3; i++) {
      AudioManager.instance.playEffect('audio/munch.wav', rate: 1.25);
      HapticFeedback.mediumImpact();
      await _chewCtrl.forward();
      await _chewCtrl.reverse();
    }

    if (!mounted) return;
    setState(() {
      _flyingSnack = null;
      _customDialogue = '어라...? 이빨이 점점 까맣게 변해요! 😱';
    });

    // 4. Sequential popping tooth decay & monster appearance! (톡! 톡! 톡!)
    for (int i = 0; i < _teeth.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: 1.0 + (i * 0.08));
      HapticFeedback.lightImpact();

      setState(() {
        _teeth[i].stainColor = snack.stainColor;
        _teeth[i].cleanliness = 0.0;
        // Assign monsters to 4 cute baby teeth
        if (i == 0 || i == 2 || i == 5 || i == 7) {
          _teeth[i].hasMonster = true;
        } else {
          _teeth[i].hasMonster = false;
        }
      });
    }

    if (!mounted) return;
    setState(() {
      _isEating = false;
      _hasDecayed = true;
      _customDialogue = '으악! 이에 세균 몬스터가 생겼어요! 😱\n양치하러 가볼까요? 🪥';
    });
  }

  void _onPokeTooth(int index) {
    AudioManager.instance.playBoing();
    HapticFeedback.selectionClick();
    setState(() {
      _pokedToothIndex = index;
      _customDialogue = '아야야! 세균이 간지러워요! 😱';
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _pokedToothIndex = null;
        });
      }
    });
  }

  void _goToSelectPaste() {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _step = BrushStep.selectPaste;
      _customDialogue = null;
    });
  }

  void _onSelectPaste(_Toothpaste paste) {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _paste = paste;
      _step = BrushStep.brushing;
    });
  }

  void _onBrushPan(Offset localPos, Size mouthSize) {
    if (_step != BrushStep.brushing) return;

    setState(() {
      _brushTouchPos = localPos;
    });

    final touchRx = (localPos.dx / mouthSize.width).clamp(0.0, 1.0);
    final touchRy = (localPos.dy / mouthSize.height).clamp(0.0, 1.0);

    bool touchedAny = false;

    for (final tooth in _teeth) {
      final dx = touchRx - tooth.xRatio;
      final dy = touchRy - tooth.yRatio;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < 0.13) {
        touchedAny = true;
        tooth.cleanliness = (tooth.cleanliness + 0.08).clamp(0.0, 1.0);
        if (tooth.cleanliness >= 0.7 && tooth.hasMonster) {
          tooth.hasMonster = false;
          _triggerMonsterPop(tooth, mouthSize);
        }

        // Add foam bubbles
        for (int i = 0; i < 2; i++) {
          _foams.add(_FoamParticle(
            pos: localPos + Offset((_rng.nextDouble() - 0.5) * 36, (_rng.nextDouble() - 0.5) * 36),
            radius: 8 + _rng.nextDouble() * 16,
            color: _paste.foamColor.withValues(alpha: 0.85),
            life: 1.0,
          ));
        }
      }
    }

    if (touchedAny) {
      _brushWiggleCtrl.forward(from: 0.0);
      AudioManager.instance.playEffect('audio/car_soap_foam.wav', rate: 1.25);
      HapticFeedback.lightImpact();
    }

    // Check completion for brushing
    if (_totalCleanliness >= 0.96) {
      _finishBrushing();
    }
  }

  void _triggerMonsterPop(_ToothState tooth, Size mouthSize) {
    AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: 1.35);
    HapticFeedback.lightImpact();
    final px = tooth.xRatio * mouthSize.width;
    final py = tooth.yRatio * mouthSize.height;

    for (int i = 0; i < 8; i++) {
      _sparkles.add(_Sparkle(
        pos: Offset(px, py),
        size: 10 + _rng.nextDouble() * 12,
        opacity: 1.0,
        rotation: _rng.nextDouble() * 2 * pi,
        color: _paste.color,
      ));
    }
  }

  void _finishBrushing() {
    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.2);
    HapticFeedback.heavyImpact();
    setState(() {
      _step = BrushStep.rinsing;
      _brushTouchPos = null;
    });
  }

  void _onRinseSpray(Offset localPos, Size mouthSize) {
    if (_step != BrushStep.rinsing) return;

    setState(() {
      _rinseProgress = (_rinseProgress + 0.04).clamp(0.0, 1.0);

      // Add water particles
      for (int i = 0; i < 6; i++) {
        _waterDrops.add(_WaterParticle(
          pos: localPos + Offset((_rng.nextDouble() - 0.5) * 40, (_rng.nextDouble() - 0.5) * 40),
          vel: Offset((_rng.nextDouble() - 0.5) * 4, 3 + _rng.nextDouble() * 5),
          radius: 6 + _rng.nextDouble() * 10,
          life: 1.0,
          color: const Color(0xFF81D4FA).withValues(alpha: 0.8),
        ));
      }

      // Wash away foams
      if (_foams.isNotEmpty) {
        _foams.removeRange(0, min(8, _foams.length));
      }
    });

    AudioManager.instance.playEffect('audio/car_water_spray.wav', rate: 1.15);
    HapticFeedback.lightImpact();

    if (_rinseProgress >= 0.95 && _foams.isEmpty) {
      _completeGame();
    }
  }

  void _completeGame() {
    _foams.clear();
    _waterDrops.clear();

    // 1. Chime fairy sparkle sound
    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.0);

    // 2. Squeaky clean tooth sound
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      AudioManager.instance.playEffect('audio/car_towel_squeak.wav', rate: 1.2);
    });

    // 3. Cute celebration fanfare (무서운 동물 울음소리 대신 밝고 신나는 축하 팡파레)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      AudioManager.instance.playSuccess();
    });

    HapticFeedback.mediumImpact();
    _mascotJumpCtrl.repeat(reverse: true);

    setState(() {
      _step = BrushStep.complete;
    });
  }

  void _resetGame() {
    AudioManager.instance.playClick();
    setState(() {
      _step = BrushStep.selectAnimal;
      _brushTouchPos = null;
      _rinseProgress = 0.0;
      _foams.clear();
      _waterDrops.clear();
      _sparkles.clear();
      _mascotJumpCtrl.stop();
      _initTeeth();
    });
  }

  void _onStepBack() {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();

    if (_isEating) return;

    setState(() {
      switch (_step) {
        case BrushStep.selectAnimal:
          Navigator.of(context).pop();
          break;
        case BrushStep.eating:
          _step = BrushStep.selectAnimal;
          _customDialogue = null;
          _flyingSnack = null;
          _isEating = false;
          break;
        case BrushStep.selectPaste:
          _step = BrushStep.eating;
          _customDialogue = null;
          _flyingSnack = null;
          _isEating = false;
          _initTeeth();
          break;
        case BrushStep.brushing:
          _step = BrushStep.selectPaste;
          _brushTouchPos = null;
          break;
        case BrushStep.rinsing:
          _step = BrushStep.brushing;
          break;
        case BrushStep.complete:
          _step = BrushStep.selectAnimal;
          break;
      }
    });
  }

  // ── Build UI ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == BrushStep.selectAnimal,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onStepBack();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Dynamic Animated Pastel Background with Soap Bubbles & Sparkles
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE0F7FA), // Soft Cyan Mint
                      Color(0xFFEDE7F6), // Lavender Mist
                      Color(0xFFFFF3E0), // Warm Cream
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _ambientBubbleCtrl,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _AmbientBubblePainter(progress: _ambientBubbleCtrl.value),
                    );
                  },
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      _buildHeader(),
                      _buildStepProgressBar(),
                      Expanded(
                        child: _buildBodyContent(constraints),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 1. Home Button (Always goes back to Main Lobby)
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.home_rounded, color: Color(0xFFE65100), size: 24),
            ),
          ),

          // 2. Step-by-Step Back Button (Only visible after selecting animal)
          if (_step != BrushStep.selectAnimal) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onStepBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00897B), size: 20),
              ),
            ),
          ],
          const SizedBox(width: 12),

          // Title & Step Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🪥 치카치카 양치 놀이',
                  style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFF263238)),
                ),
                Text(
                  _getStepTitle(),
                  style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF00897B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_step) {
      case BrushStep.selectAnimal:
        return '동물 친구를 골라보세요! 🐾';
      case BrushStep.eating:
        return '맛있는 간식을 먹여주세요! 🍩';
      case BrushStep.selectPaste:
        return '좋아하는 치약을 골라봐요! 🍓';
      case BrushStep.brushing:
        return '칫솔로 이를 쓱싹쓱싹 문질러요! 🪥';
      case BrushStep.rinsing:
        return '물로 거품을 시원하게 헹궈요! 💧';
      case BrushStep.complete:
        return '이가 반짝반짝 눈부셔요! 🌟';
    }
  }

  Widget _buildStepProgressBar() {
    final steps = ['동물 선택', '간식 먹기', '치약 선택', '치카치카', '물 헹구기', '반짝반짝'];
    final currentIdx = _step.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = index < currentIdx;
          final isCurrent = index == currentIdx;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF00ACC1)
                    : (isDone ? const Color(0xFF80CBC4) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBodyContent(BoxConstraints constraints) {
    if (_step == BrushStep.selectAnimal) {
      return _buildAnimalSelectView();
    }
    // All other steps share the EXACT same fixed geometry scaffold (Zero Layout Shift)
    return _buildUnifiedGameStage(constraints);
  }

  // ── 1. Select Animal View ─────────────────────────────────────────────────

  Widget _buildAnimalSelectView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.teal.withValues(alpha: 0.15), blurRadius: 10),
              ],
            ),
            child: Text(
              '양치질이 필요한 동물 친구를 골라주세요! 🦷',
              style: GoogleFonts.jua(fontSize: 17, color: const Color(0xFF00695C)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _kAnimals.map((animal) {
                  return GestureDetector(
                    onTap: () => _onSelectAnimal(animal),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: animal.primaryColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: animal.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: animal.faceColor.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(animal.emoji, style: const TextStyle(fontSize: 44)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            animal.name,
                            style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF37474F)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── UNIFIED FIXED STAGE (Mascot & Bottom Tray NEVER Shift Position) ────────

  Widget _buildUnifiedGameStage(BoxConstraints constraints) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 6),

            // 1. FIXED HEIGHT SPEECH BUBBLE (Exact 52px, never causes jumping)
            Container(
              height: 52,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _animal.primaryColor, width: 2.5),
                boxShadow: [
                  BoxShadow(color: _animal.primaryColor.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _getFixedDialogueText(),
                  key: ValueKey(_getFixedDialogueText()),
                  style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF263238)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 2. FIXED CENTER MASCOT (280x280 Canvas ALWAYS at the exact same screen location)
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Base Animal Head
                      _buildAnimalHeadWidget(
                        showDirty: _step == BrushStep.selectPaste || _step == BrushStep.brushing || (_step == BrushStep.eating && _customDialogue != null),
                        openWide: true,
                        isShining: _step == BrushStep.complete || _isEating,
                      ),

                      // Interactive Layer for Brushing
                      if (_step == BrushStep.brushing) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            onPanUpdate: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            onTapDown: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            behavior: HitTestBehavior.opaque,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _FoamAndParticlePainter(
                                foams: _foams,
                                sparkles: _sparkles,
                              ),
                            ),
                          ),
                        ),
                        if (_brushTouchPos != null)
                          Positioned(
                            left: _brushTouchPos!.dx - 22,
                            top: _brushTouchPos!.dy - 44,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _brushWiggleCtrl,
                                builder: (context, child) {
                                  final angle = sin(_brushWiggleCtrl.value * pi * 2) * 0.25;
                                  return Transform.rotate(
                                    angle: angle,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
                                        ],
                                      ),
                                      child: const Text('🪥', style: TextStyle(fontSize: 34)),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],

                      // Interactive Layer for Rinsing
                      if (_step == BrushStep.rinsing)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (details) => _onRinseSpray(details.localPosition, const Size(280, 280)),
                            onTapDown: (details) => _onRinseSpray(details.localPosition, const Size(280, 280)),
                            behavior: HitTestBehavior.opaque,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _RinsePainter(
                                foams: _foams,
                                waterDrops: _waterDrops,
                              ),
                            ),
                          ),
                        ),

                      // Celebration Sparkles for Complete
                      if (_step == BrushStep.complete)
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _sparkleLoopCtrl,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CelebrationSparklePainter(progress: _sparkleLoopCtrl.value),
                              );
                            },
                          ),
                        ),

                      // Floating Hearts while eating
                      if (_isEating)
                        Positioned(
                          top: -10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('💖', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 40),
                              Text('✨', style: TextStyle(fontSize: 32)),
                              SizedBox(width: 40),
                              Text('😋', style: TextStyle(fontSize: 28)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. FIXED HEIGHT BOTTOM CONTROL TRAY (Exact 190px, never causes jumping)
            Container(
              height: 190,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _getBottomTrayBorderColor(), width: 2.5),
                boxShadow: [
                  BoxShadow(color: _getBottomTrayBorderColor().withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBottomTrayContent(),
              ),
            ),
          ],
        ),

        // Flying Snack Animation
        if (_flyingSnack != null)
          AnimatedBuilder(
            animation: _snackFlyCtrl,
            builder: (context, child) {
              final t = _snackFlyCtrl.value;
              final startY = constraints.maxHeight - 120;
              final targetY = constraints.maxHeight * 0.38;
              final currentY = startY + (targetY - startY) * t;
              final scale = 1.0 + sin(t * pi) * 0.5;
              final rotation = t * pi * 2;

              return Positioned(
                left: (constraints.maxWidth / 2) - 30,
                top: currentY,
                child: Opacity(
                  opacity: (1.0 - (t > 0.85 ? (t - 0.85) / 0.15 : 0.0)).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        _flyingSnack!.emoji,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getFixedDialogueText() {
    if (_customDialogue != null) return _customDialogue!;
    switch (_step) {
      case BrushStep.eating:
        return '${_animal.name}: "달콤한 간식을 골라주세요!" 😋';
      case BrushStep.selectPaste:
        return '치아에 세균이 생겼어요! 치약을 골라볼까요? 🪥';
      case BrushStep.brushing:
        return '손가락으로 이를 쓱싹쓱싹 문질러요! 🫧';
      case BrushStep.rinsing:
        return '물방울을 쏴아~ 뿌려서 헹궈내요! 💧';
      case BrushStep.complete:
        return '🎉 치카치카 대성공! 이가 반짝반짝 눈부셔요! ✨';
      default:
        return '';
    }
  }

  Color _getBottomTrayBorderColor() {
    switch (_step) {
      case BrushStep.eating:
        return Colors.orange.shade300;
      case BrushStep.selectPaste:
        return const Color(0xFF80DEEA);
      case BrushStep.brushing:
        return _paste.color;
      case BrushStep.rinsing:
        return const Color(0xFF0288D1);
      case BrushStep.complete:
        return Colors.amber;
      default:
        return Colors.grey.shade300;
    }
  }

  Widget _buildBottomTrayContent() {
    switch (_step) {
      case BrushStep.eating:
        return _buildSnackTrayContent();
      case BrushStep.selectPaste:
        return _buildPasteTrayContent();
      case BrushStep.brushing:
        return _buildBrushingTrayContent();
      case BrushStep.rinsing:
        return _buildRinsingTrayContent();
      case BrushStep.complete:
        return _buildCompleteTrayContent();
      default:
        return const SizedBox.shrink();
    }
  }

  // Tray 1: Snack Grid & Ready-to-Brush Button
  Widget _buildSnackTrayContent() {
    if (_hasDecayed) {
      return Column(
        key: const ValueKey('tray_eating_decayed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('간식을 더 먹이거나, 양치질을 시작해요!', style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          // Compact Snack Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _kSnacks.map((snack) {
                return GestureDetector(
                  onTap: () => _feedSnackWithEffect(snack, GlobalKey()),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade300, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snack.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(snack.name, style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFF4E342E))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Big Shiny "Go to Brush" Button
          GestureDetector(
            onTap: _goToSelectPaste,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('치카치카 양치하러 가기!', style: GoogleFonts.jua(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('tray_eating_initial'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👇', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('먹이고 싶은 간식을 콕! 터치해요', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSnackCardItem(_kSnacks[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildSnackCardItem(_kSnacks[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSnackCardItem(_kSnacks[2])),
            const SizedBox(width: 8),
            Expanded(child: _buildSnackCardItem(_kSnacks[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildSnackCardItem(_Snack snack) {
    final key = GlobalKey();
    return Builder(
      builder: (context) {
        return GestureDetector(
          key: key,
          onTap: () => _feedSnackWithEffect(snack, key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.orange.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade300, width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(snack.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 6),
                Text(
                  snack.name,
                  style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF4E342E), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tray 2: 3 Toothpastes
  Widget _buildPasteTrayContent() {
    return Column(
      key: const ValueKey('tray_paste'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('어떤 향기의 치약으로 닦을까요?', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF00695C), fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _kPastes.map((paste) {
            return Expanded(
              child: GestureDetector(
                onTap: () => _onSelectPaste(paste),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: paste.color, width: 2.2),
                    boxShadow: [
                      BoxShadow(color: paste.color.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: paste.foamColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(paste.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 6),
                      Text(paste.name, style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF263238))),
                      Text(paste.flavor, style: GoogleFonts.jua(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Tray 3: Brushing Progress & Guidance
  Widget _buildBrushingTrayContent() {
    final progress = _totalCleanliness;
    return Column(
      key: const ValueKey('tray_brushing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🪥 치카치카 진행률', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF37474F))),
            Text('${(progress * 100).toInt()}%',
                style: GoogleFonts.jua(fontSize: 16, color: _paste.color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_paste.color),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _paste.foamColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('동물 친구의 치아를 문질러 거품을 내요! 🫧', style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF004D40))),
            ],
          ),
        ),
      ],
    );
  }

  // Tray 4: Water Rinse Action
  Widget _buildRinsingTrayContent() {
    return Column(
      key: const ValueKey('tray_rinsing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('물로 거품을 깨끗하게 헹궈주세요! 💧', style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF01579B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTapDown: (details) {
            _onRinseSpray(const Offset(140, 140), const Size(280, 280));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF0288D1)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0288D1).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💧', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('물 뿌리기 (가글가글 퉤!)', style: GoogleFonts.jua(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tray 5: Complete Reward & Replay
  Widget _buildCompleteTrayContent() {
    return Column(
      key: const ValueKey('tray_complete'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF66BB6A), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.15), blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text('치아가 반짝반짝 정말 깨끗해요! 👏',
                  style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _resetGame,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔄', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('다른 친구 닦아주기', style: GoogleFonts.jua(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── ADORABLE CHIBI ANIMAL CHARACTER RENDERING (280x280 Canvas) ────────────

  Widget _buildAnimalHeadWidget({required bool showDirty, required bool openWide, bool isShining = false}) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Back Features: Ears / Mane / Dino Spikes
          _buildBackFeatures(isShining),

          // 2. Main Cute Head & Face Body
          _buildHeadAndFaceBody(isShining),

          // 3. Cute Happy Open Mouth Cavity (Soft Coral-Pink smile)
          _buildCuteOpenMouth(),

          // 4. Cute Big Puffy Baby Teeth (8 adorable round marshmallow teeth)
          ..._teeth.map((tooth) => _buildSingleTooth(tooth, showDirty, isShining)),

          // 5. Cute Muzzle / Nose / Whiskers
          _buildCuteMuzzle(),

          // 6. Sparkling Cute Eyes, Brows & Cheeks
          _buildCuteEyesAndCheeks(isShining),
        ],
      ),
    );
  }

  // ── 1. Back Features (Mane, Ears, Spikes) ──────────────────────────────────

  Widget _buildBackFeatures(bool isShining) {
    switch (_animal.id) {
      case 'lion':
        // Soft rounded golden-orange mane puffs
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            ...List.generate(12, (i) {
              final angle = i * (2 * pi / 12);
              return Positioned(
                left: 140 + cos(angle) * 105 - 28,
                top: 140 + sin(angle) * 105 - 28,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            // Lion Cute Round Ears
            Positioned(top: 32, left: 55, child: _buildCuteRoundEar(const Color(0xFFFFB74D), const Color(0xFFFFF3E0))),
            Positioned(top: 32, right: 55, child: _buildCuteRoundEar(const Color(0xFFFFB74D), const Color(0xFFFFF3E0))),
          ],
        );

      case 'rabbit':
        // Cute bunny ears - kept safely inside top bounds
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 8,
              left: 60,
              child: Transform.rotate(
                angle: -0.1,
                child: Container(
                  width: 44,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF06292), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 60,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  width: 44,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF48FB1),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFF06292), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 20,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'croco':
        // Baby dino / croc spines on top
        return Positioned(
          top: 32,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 16,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
              );
            }),
          ),
        );

      case 'tiger':
        // Cute Tiger rounded-pointy ears
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 26, left: 45, child: _buildCuteRoundEar(const Color(0xFFFB8C00), const Color(0xFFFFF8E1), isTiger: true)),
            Positioned(top: 26, right: 45, child: _buildCuteRoundEar(const Color(0xFFFB8C00), const Color(0xFFFFF8E1), isTiger: true)),
          ],
        );

      case 'bear':
        // Fluffy teddy bear ears
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 28, left: 42, child: _buildCuteRoundEar(const Color(0xFF8D6E63), const Color(0xFFD7CCC8))),
            Positioned(top: 28, right: 42, child: _buildCuteRoundEar(const Color(0xFF8D6E63), const Color(0xFFD7CCC8))),
          ],
        );

      case 'hippo':
        // Cute tiny hippo ears
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: 35, left: 52, child: _buildCuteRoundEar(const Color(0xFFAB47BC), const Color(0xFFF8BBD0), size: 36)),
            Positioned(top: 35, right: 52, child: _buildCuteRoundEar(const Color(0xFFAB47BC), const Color(0xFFF8BBD0), size: 36)),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCuteRoundEar(Color outerColor, Color innerColor, {double size = 48, bool isTiger = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outerColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.15), width: 3),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.52,
        height: size * 0.52,
        decoration: BoxDecoration(color: innerColor, shape: BoxShape.circle),
      ),
    );
  }

  // ── 2. Head & Face Body ───────────────────────────────────────────────────

  Widget _buildHeadAndFaceBody(bool isShining) {
    final faceColor = _animal.faceColor;
    final primaryColor = _animal.primaryColor;

    return Container(
      width: 220,
      height: 220,
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: faceColor,
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor, width: 5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  // ── 3. Cute Happy Open Mouth (Soft Warm Pink smile) ──────────────────────

  Widget _buildCuteOpenMouth() {
    return Positioned(
      top: 136,
      child: Container(
        width: 164,
        height: 86,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF8DA1), Color(0xFFFF5277)],
          ),
          borderRadius: BorderRadius.circular(43),
          border: Border.all(color: const Color(0xFFE91E63), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC2185B).withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Soft Cute Jelly Tongue at bottom
            Positioned(
              bottom: -2,
              child: Container(
                width: 84,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF80AB), Color(0xFFFF4081)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: const Color(0xFFE91E63), width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Teeth Items (Chunky, Puffy, Cute Baby Teeth) ───────────────────────

  Widget _buildSingleTooth(_ToothState tooth, bool showDirty, bool isShining) {
    const canvasW = 280.0;
    const canvasH = 280.0;

    final leftPos = tooth.xRatio * canvasW;
    final topPos = tooth.yRatio * canvasH;

    final cleanRatio = showDirty ? tooth.cleanliness : 1.0;
    final dirtyRatio = 1.0 - cleanRatio;

    // Special cute buck teeth for rabbit on upper middle teeth
    final isRabbitBuck = _animal.id == 'rabbit' && tooth.isTop && (tooth.index == 1 || tooth.index == 2);
    final toothW = isRabbitBuck ? (tooth.width + 2.0) : tooth.width;
    final toothH = isRabbitBuck ? (tooth.height + 4.0) : tooth.height;

    final isPoked = _pokedToothIndex == tooth.index;

    return Positioned(
      left: leftPos - (toothW / 2),
      top: topPos - (toothH / 2),
      child: GestureDetector(
        onTap: () => _onPokeTooth(tooth.index),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Chunky Marshmallow Tooth Body (둥글둥글 귀여운 왕치아)
            AnimatedScale(
              scale: isPoked ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: toothW,
                height: toothH,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isShining
                        ? [const Color(0xFFFFFDE7), const Color(0xFFFFE082)]
                        : (dirtyRatio > 0.05
                            ? [Colors.white, const Color(0xFFD7CCC8)]
                            : [Colors.white, const Color(0xFFECEFF1)]),
                  ),
                  borderRadius: BorderRadius.circular(isRabbitBuck ? 8 : 11),
                  border: Border.all(
                    color: isShining
                        ? Colors.amber
                        : (dirtyRatio > 0.05 ? const Color(0xFF8D6E63) : const Color(0xFFCFD8DC)),
                    width: isShining ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isShining ? Colors.amber.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.12),
                      blurRadius: isShining ? 8 : 2.5,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Cute Glossy Highlight Dot (상단 좌측 반짝이 하이라이트)
                    Positioned(
                      left: 3.5,
                      top: 3.0,
                      child: Container(
                        width: 7.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: dirtyRatio > 0.4 ? 0.2 : 0.85),
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                      ),
                    ),

                    // Food Stain / Plaque overlay
                    if (dirtyRatio > 0.05)
                      Center(
                        child: Container(
                          width: toothW * 0.72 * dirtyRatio,
                          height: toothH * 0.72 * dirtyRatio,
                          decoration: BoxDecoration(
                            color: tooth.stainColor.withValues(alpha: 0.85 * dirtyRatio),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),

                    // Shining sparkle star
                    if (isShining)
                      const Center(child: Text('✨', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),

            // 2. Germ Monster with jump reaction when poked
            if (showDirty && tooth.hasMonster && dirtyRatio > 0.3)
              Positioned(
                top: tooth.isTop ? (isPoked ? -18 : -10) : null,
                bottom: tooth.isTop ? null : (isPoked ? -18 : -10),
                child: AnimatedScale(
                  scale: isPoked ? 1.4 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      tooth.monsterEmoji,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 5. Cute Muzzle / Nose / Whiskers ──────────────────────────────────────

  Widget _buildCuteMuzzle() {
    switch (_animal.id) {
      case 'lion':
      case 'tiger':
        return Positioned(
          top: 116,
          child: Column(
            children: [
              // Cute pink nose
              Container(
                width: 26,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 2),
              // Whiskers
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('— —', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  const SizedBox(width: 16),
                  Text('— —', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
        );

      case 'rabbit':
        return Positioned(
          top: 120,
          child: Column(
            children: [
              Container(
                width: 18,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                  const SizedBox(width: 12),
                  Text('—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        );

      case 'croco':
        return Positioned(
          top: 124,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
                const SizedBox(width: 20),
                Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle)),
              ],
            ),
          ),
        );

      case 'bear':
        return Positioned(
          top: 115,
          child: Container(
            width: 58,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD7CCC8),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: 22,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        );

      case 'hippo':
        return Positioned(
          top: 114,
          child: Container(
            width: 78,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFCE93D8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF6A1B9A), shape: BoxShape.circle)),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ── 6. Sparkling Cute Eyes & Blush ────────────────────────────────────────

  Widget _buildCuteEyesAndCheeks(bool isShining) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Forehead tiger stripes
        if (_animal.id == 'tiger')
          Positioned(
            top: 55,
            child: Column(
              children: [
                Container(width: 32, height: 5, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 3),
                Container(width: 20, height: 4, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3))),
              ],
            ),
          ),

        // Big Cute Sparkling Anime Eyes
        Positioned(
          top: 76,
          left: 68,
          child: _buildCuteEye(isShining),
        ),
        Positioned(
          top: 76,
          right: 68,
          child: _buildCuteEye(isShining),
        ),

        // Soft Pink Rosy Cheeks
        Positioned(
          top: 132,
          left: 36,
          child: Container(
            width: 26,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Positioned(
          top: 132,
          right: 36,
          child: Container(
            width: 26,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCuteEye(bool isShining) {
    if (isShining) {
      return const Text('😍', style: TextStyle(fontSize: 32));
    }
    return Container(
      width: 26,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFF212121),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          // Main big sparkle highlight
          Positioned(
            top: 4,
            left: 5,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          // Small sub sparkle
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class _FoamAndParticlePainter extends CustomPainter {
  final List<_FoamParticle> foams;
  final List<_Sparkle> sparkles;

  _FoamAndParticlePainter({required this.foams, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw Foams
    for (final foam in foams) {
      final paint = Paint()
        ..color = foam.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(foam.pos, foam.radius, paint);

      // Bubble shine
      final shinePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
      canvas.drawCircle(foam.pos - Offset(foam.radius * 0.3, foam.radius * 0.3), foam.radius * 0.25, shinePaint);
    }

    // Draw Sparkles
    for (final sp in sparkles) {
      final paint = Paint()..color = sp.color.withValues(alpha: sp.opacity);
      canvas.save();
      canvas.translate(sp.pos.dx, sp.pos.dy);
      canvas.rotate(sp.rotation);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sp.size, height: sp.size * 0.3), paint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: sp.size * 0.3, height: sp.size), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RinsePainter extends CustomPainter {
  final List<_FoamParticle> foams;
  final List<_WaterParticle> waterDrops;

  _RinsePainter({required this.foams, required this.waterDrops});

  @override
  void paint(Canvas canvas, Size size) {
    // Foams
    for (final foam in foams) {
      final paint = Paint()..color = foam.color.withValues(alpha: 0.5);
      canvas.drawCircle(foam.pos, foam.radius, paint);
    }

    // Water Drops
    for (final drop in waterDrops) {
      final paint = Paint()..color = drop.color;
      canvas.drawOval(
        Rect.fromCenter(center: drop.pos, width: drop.radius * 1.5, height: drop.radius * 2.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CelebrationSparklePainter extends CustomPainter {
  final double progress;
  _CelebrationSparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const count = 12;

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * pi / count) + (progress * 2 * pi);
      final r = 120 + sin(progress * pi * 4 + i) * 20;
      final px = cx + cos(angle) * r;
      final py = cy + sin(angle) * r;

      final paint = Paint()..color = Colors.amber.withValues(alpha: (0.5 + sin(progress * pi * 2 + i) * 0.5).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), 6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Dynamic Animated Pastel Background with Floating Soap Bubbles & Sparkles
class _AmbientBubblePainter extends CustomPainter {
  final double progress;
  _AmbientBubblePainter({required this.progress});

  // Deterministic bubble seeds (xRatio, size, speedFactor, phaseOffset, hue)
  static final List<List<double>> _bubbleSeeds = [
    [0.10, 32.0, 1.0, 0.1, 180.0],
    [0.22, 18.0, 1.3, 0.4, 210.0],
    [0.35, 42.0, 0.8, 0.7, 320.0],
    [0.48, 24.0, 1.1, 0.2, 160.0],
    [0.62, 38.0, 0.9, 0.8, 280.0],
    [0.75, 20.0, 1.4, 0.3, 190.0],
    [0.88, 48.0, 0.7, 0.5, 330.0],
    [0.05, 26.0, 1.2, 0.9, 200.0],
    [0.55, 16.0, 1.5, 0.6, 290.0],
    [0.92, 28.0, 1.0, 0.0, 170.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft Bottom Cloud Waves
    final wavePaint = Paint()
      ..color = const Color(0xFFF3E5F5).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final wavePath = Path();
    wavePath.moveTo(0, size.height);
    wavePath.lineTo(0, size.height - 80);
    wavePath.quadraticBezierTo(size.width * 0.25, size.height - 110, size.width * 0.5, size.height - 80);
    wavePath.quadraticBezierTo(size.width * 0.75, size.height - 50, size.width, size.height - 75);
    wavePath.lineTo(size.width, size.height);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    // 2. Floating Soap Bubbles with Reflections
    for (int i = 0; i < _bubbleSeeds.length; i++) {
      final seed = _bubbleSeeds[i];
      final xBase = seed[0] * size.width;
      final radius = seed[1];
      final speed = seed[2];
      final phase = seed[3];
      final hue = seed[4];

      // Vertical floating progress (Bottom to Top loop)
      final t = (progress * speed + phase) % 1.0;
      final y = size.height - (t * (size.height + radius * 3)) + radius;

      // Gentle horizontal sway
      final x = xBase + sin(progress * pi * 2 * speed + phase * 10) * 22;

      // Alpha fade in from bottom, fade out at very top
      final alpha = (sin(t * pi)).clamp(0.0, 1.0) * 0.55;

      // Bubble Body (Soft Pastel Tint)
      final bubbleColor = HSVColor.fromAHSV(alpha, hue, 0.35, 0.98).toColor();
      final bodyPaint = Paint()
        ..color = bubbleColor.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, bodyPaint);

      // Bubble Ring Stroke
      final strokePaint = Paint()
        ..color = bubbleColor.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(x, y), radius, strokePaint);

      // Cute Bubble Crescent Highlight (Top-Left 3D Shine)
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x - radius * 0.35, y - radius * 0.38),
          width: radius * 0.45,
          height: radius * 0.28,
        ),
        shinePaint,
      );

      // Small secondary shine dot (Bottom-Right)
      canvas.drawCircle(
        Offset(x + radius * 0.4, y + radius * 0.4),
        radius * 0.12,
        shinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


