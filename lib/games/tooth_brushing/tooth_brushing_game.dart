import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════


import 'dart:ui' as ui;

part 'models/tooth_brushing_models.dart';
part 'painters/tooth_brushing_painters.dart';
part 'widgets/tooth_brushing_stage.dart';
part 'widgets/tooth_brushing_trays.dart';
part 'widgets/tooth_brushing_character.dart';

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
  late AnimationController _blinkCtrl;
  late AnimationController _swishCtrl;

  _Snack? _flyingSnack;
  bool _isEating = false;
  String? _customDialogue;
  bool _isBrushingFinished = false;
  bool _isRinsingFinished = false;
  int _lastBrushSoundMs = 0;
  int _lastRinseSoundMs = 0;

  @override
  void initState() {
    super.initState();
    _chewCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _sparkleLoopCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _mascotJumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _brushWiggleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _snackFlyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _ambientBubbleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _swishCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..repeat(reverse: true);

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
    _blinkCtrl.dispose();
    _swishCtrl.dispose();
    super.dispose();
  }

  bool _hasDecayed = false;
  bool _isMouthOpen = false;
  int? _pokedToothIndex;

  void _initTeeth() {
    _teeth.clear();
    _hasDecayed = false;
    _isMouthOpen = false;
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
      _isMouthOpen = false;
      _isBrushingFinished = false;
      _isRinsingFinished = false;
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
      _isMouthOpen = true;
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

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (touchedAny && (nowMs - _lastBrushSoundMs > 180)) {
      _lastBrushSoundMs = nowMs;
      _brushWiggleCtrl.forward(from: 0.0);
      final scrubRate = 1.05 + (_rng.nextDouble() * 0.4);
      AudioManager.instance.playEffect('audio/car_soap_foam.wav', rate: scrubRate);
      HapticFeedback.selectionClick();
    }

    // Check completion for brushing
    if (_totalCleanliness >= 0.96 && !_isBrushingFinished) {
      _isBrushingFinished = true;
      AudioManager.instance.playEffect('audio/chime.wav', rate: 1.2);
      setState(() {
        _customDialogue = '우와! 깨끗해졌어!\\n이제 손을 떼봐요!';
      });
    }
  }

  void _onBrushPanEnd() {
    setState(() {
      _brushTouchPos = null;
    });
    if (_isBrushingFinished) {
      _finishBrushing();
    }
  }

  void _triggerMonsterPop(_ToothState tooth, Size mouthSize) {
    final popRate = 1.15 + (_rng.nextDouble() * 0.4);
    AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: popRate);
    HapticFeedback.mediumImpact();
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
    HapticFeedback.heavyImpact();
    setState(() {
      _customDialogue = '이제 물로 헹구자!';
    });
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _step = BrushStep.rinsing;
          _customDialogue = null;
        });
      }
    });
  }

  void _onRinseSpray(Offset localPos, Size mouthSize) {
    if (_step != BrushStep.rinsing) return;

    setState(() {
      _rinseProgress = (_rinseProgress + 0.2).clamp(0.0, 1.0);

      // Add water particles
      for (int i = 0; i < 8; i++) {
        _waterDrops.add(_WaterParticle(
          pos: localPos + Offset((_rng.nextDouble() - 0.5) * 50, (_rng.nextDouble() - 0.5) * 50),
          vel: Offset((_rng.nextDouble() - 0.5) * 4, 3 + _rng.nextDouble() * 6),
          radius: 6 + _rng.nextDouble() * 12,
          life: 1.0,
          color: const Color(0xFF81D4FA).withValues(alpha: 0.85),
        ));
      }

      // Wash away foams
      if (_foams.isNotEmpty) {
        _foams.removeRange(0, min(16, _foams.length));
      }
    });

    final nowRinseMs = DateTime.now().millisecondsSinceEpoch;
    if (nowRinseMs - _lastRinseSoundMs > 180) {
      _lastRinseSoundMs = nowRinseMs;
      AudioManager.instance.playEffect('audio/car_water_spray.wav', rate: 1.15);
      HapticFeedback.lightImpact();
    }

    if ((_rinseProgress >= 0.95 || _foams.isEmpty) && !_isRinsingFinished) {
      _isRinsingFinished = true;
      _completeGame();
    }
  }

  void _onRinsePanEnd() {
    if (_isRinsingFinished) {
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
}
