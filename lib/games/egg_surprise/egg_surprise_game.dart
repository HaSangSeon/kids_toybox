import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Egg Surprise Game — 톡톡 깜짝 알 깨기! (3~5세 톡톡 쉬운 놀이)
// 리얼한 알 껍질 노크/크랙 사운드 + 손가락으로 진짜 문질문질 쓰다듬는 촉각·사운드 인터랙션
// ─────────────────────────────────────────────────────────────────────────────

enum EggPatternType {
  spots,
  stripes,
  stars,
  hearts,
  zigzag,
}

class _HatchlingInfo {
  final String id;
  final String name;
  final String soundText;
  final String greeting;
  final String petReaction;
  final String emoji;
  final Color eggBaseColor;
  final Color eggAccentColor;
  final Color eggLightColor;
  final EggPatternType pattern;

  const _HatchlingInfo({
    required this.id,
    required this.name,
    required this.soundText,
    required this.greeting,
    required this.petReaction,
    required this.emoji,
    required this.eggBaseColor,
    required this.eggAccentColor,
    required this.eggLightColor,
    required this.pattern,
  });
}

class _EggShellPiece {
  double x, y, vx, vy, size, life, rotation, vRot;
  Color color;
  int kind; // 0: shell chip, 1: star, 2: heart, 3: music note

  _EggShellPiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
    required this.rotation,
    required this.vRot,
    this.kind = 0,
  });
}

class _RubTrailPoint {
  final Offset localPos;
  double life = 1.0;
  final Color color;

  _RubTrailPoint({
    required this.localPos,
    required this.color,
  });
}

class EggSurpriseGame extends StatefulWidget {
  const EggSurpriseGame({super.key});

  @override
  State<EggSurpriseGame> createState() => _EggSurpriseGameState();
}

class _EggSurpriseGameState extends State<EggSurpriseGame>
    with TickerProviderStateMixin {
  static const int _maxCrackSteps = 5;

  static const List<_HatchlingInfo> _hatchlings = [
    _HatchlingInfo(
      id: 'trex',
      name: '아기 티라노',
      soundText: '크아앙~!',
      greeting: '안녕! 나는 용감한 아기 티라노야! 🦖',
      petReaction: '크아앙~ 머리를 쓰다듬어 주니까 기분이 최고야! 💕',
      emoji: '🦖',
      eggBaseColor: Color(0xFFFF7043),
      eggAccentColor: Color(0xFFFFCA28),
      eggLightColor: Color(0xFFFFCCBC),
      pattern: EggPatternType.zigzag,
    ),
    _HatchlingInfo(
      id: 'chick',
      name: '아기 병아리',
      soundText: '삐약삐약~!',
      greeting: '삐약삐약! 따뜻한 둥지가 정말 좋아! 🐥',
      petReaction: '삐약삐약~ 포근포근 손길이 정말 따뜻해! 💛',
      emoji: '🐥',
      eggBaseColor: Color(0xFFFFD54F),
      eggAccentColor: Color(0xFFFF8F00),
      eggLightColor: Color(0xFFFFF9C4),
      pattern: EggPatternType.stripes,
    ),
    _HatchlingInfo(
      id: 'unicorn',
      name: '아기 유니콘',
      soundText: '샤라랑~✨',
      greeting: '반짝반짝 무지개 마법 유니콘이야! 🦄',
      petReaction: '샤라랑~ 갈기를 쓰다듬어 주니까 마법 별이 피어나! ✨',
      emoji: '🦄',
      eggBaseColor: Color(0xFFF48FB1),
      eggAccentColor: Color(0xFF80DEEA),
      eggLightColor: Color(0xFFFCE4EC),
      pattern: EggPatternType.hearts,
    ),
    _HatchlingInfo(
      id: 'brachio',
      name: '아기 브라키오',
      soundText: '우우웅~🌿',
      greeting: '목이 길~쭉한 초식공룡 브라키오야! 🦕',
      petReaction: '우우웅~ 살살 문질러 주니까 간지러워~ 헤헤! 🌿',
      emoji: '🦕',
      eggBaseColor: Color(0xFF66BB6A),
      eggAccentColor: Color(0xFFFFF176),
      eggLightColor: Color(0xFFC8E6C9),
      pattern: EggPatternType.spots,
    ),
    _HatchlingInfo(
      id: 'penguin',
      name: '아기 펭귄',
      soundText: '뒤뚱뒤뚱~❄️',
      greeting: '얼음 나라에서 온 시원한 아기 펭귄이야! 🐧',
      petReaction: '뒤뚱뒤뚱~ 보들보들 쓰다듬어 줘서 고마워! ❄️',
      emoji: '🐧',
      eggBaseColor: Color(0xFF4FC3F7),
      eggAccentColor: Color(0xFFE1F5FE),
      eggLightColor: Color(0xFFB3E5FC),
      pattern: EggPatternType.stars,
    ),
    _HatchlingInfo(
      id: 'dragon',
      name: '꼬마 드래곤',
      soundText: '슈우웅~🔥',
      greeting: '하늘을 멋지게 나는 꼬마 드래곤이야! 🐉',
      petReaction: '푸르릉~ 볼을 문질러 주니까 따뜻해서 잠이 솔솔 와! 💜',
      emoji: '🐉',
      eggBaseColor: Color(0xFFAB47BC),
      eggAccentColor: Color(0xFFFFD54F),
      eggLightColor: Color(0xFFE1BEE7),
      pattern: EggPatternType.stars,
    ),
    _HatchlingInfo(
      id: 'rabbit',
      name: '아기 토끼',
      soundText: '깡충깡충~🥕',
      greeting: '귀가 쫑긋! 당근을 좋아하는 토끼야! 🐰',
      petReaction: '쫑긋쫑긋~ 귀를 살살 쓰다듬어 주니까 너무 행복해! 🩷',
      emoji: '🐰',
      eggBaseColor: Color(0xFFFF80AB),
      eggAccentColor: Color(0xFFFFFFFF),
      eggLightColor: Color(0xFFF8BBD0),
      pattern: EggPatternType.hearts,
    ),
    _HatchlingInfo(
      id: 'turtle',
      name: '꼬마 거북이',
      soundText: '엉금엉금~🌊',
      greeting: '푸른 바다를 헤엄치는 꼬마 거북이야! 🐢',
      petReaction: '엉금엉금~ 등껍질을 문질러 주니까 시원해! 🌊',
      emoji: '🐢',
      eggBaseColor: Color(0xFF26A69A),
      eggAccentColor: Color(0xFFA7FFEB),
      eggLightColor: Color(0xFFB2DFDB),
      pattern: EggPatternType.spots,
    ),
    _HatchlingInfo(
      id: 'bear',
      name: '아기 곰돌이',
      soundText: '우르르~🍯',
      greeting: '달콤한 꿀을 좋아하는 포근한 곰돌이야! 🐻',
      petReaction: '우르르~ 몽실몽실 털을 쓰다듬어 주니 꿀맛 같아! 🍯',
      emoji: '🐻',
      eggBaseColor: Color(0xFFA1887F),
      eggAccentColor: Color(0xFFFFE082),
      eggLightColor: Color(0xFFD7CCC8),
      pattern: EggPatternType.spots,
    ),
    _HatchlingInfo(
      id: 'dog',
      name: '아기 강아지',
      soundText: '멍멍! 🐾',
      greeting: '꼬리를 살랑살랑 흔드는 아기 강아지야! 🐶',
      petReaction: '멍멍! 헤헤~ 쓰다듬어 주니까 꼬리가 멈추질 않아! 🐾',
      emoji: '🐶',
      eggBaseColor: Color(0xFFFFB74D),
      eggAccentColor: Color(0xFFFFF3E0),
      eggLightColor: Color(0xFFFFE0B2),
      pattern: EggPatternType.stripes,
    ),
    _HatchlingInfo(
      id: 'cat',
      name: '아기 고양이',
      soundText: '야옹~🎀',
      greeting: '새근새근 귀여운 아기 고양이야! 🐱',
      petReaction: '골골골~ 야옹! 턱이랑 머리를 쓰다듬어 주니 최고야! 🎀',
      emoji: '🐱',
      eggBaseColor: Color(0xFFFF8A65),
      eggAccentColor: Color(0xFFFFF59D),
      eggLightColor: Color(0xFFFFCCBC),
      pattern: EggPatternType.hearts,
    ),
    _HatchlingInfo(
      id: 'octopus',
      name: '아기 문어',
      soundText: '보글보글~🫧',
      greeting: '다리가 여덟 개인 춤추는 아기 문어야! 🐙',
      petReaction: '보글보글~ 말랑말랑 머리를 문질러 주니 춤이 절로 나와! 🫧',
      emoji: '🐙',
      eggBaseColor: Color(0xFF5C6BC0),
      eggAccentColor: Color(0xFF80DEEA),
      eggLightColor: Color(0xFFC5CAE9),
      pattern: EggPatternType.zigzag,
    ),
  ];

  late ConfettiController _confettiCtrl;
  late AnimationController _wobbleCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _hatchPopCtrl;
  late AnimationController _autoPetCtrl;
  late Ticker _particleTicker;

  final Random _rng = Random();
  final List<_EggShellPiece> _particles = [];
  final List<_RubTrailPoint> _rubTrail = [];
  final Set<String> _discoveredIds = {};
  final Set<String> _maxLovedIds = {}; // 사랑 게이지 100% 슈퍼 변신 달성 도감

  int _currentIndex = 0;
  int _crackStep = 0;
  bool _isHatched = false;
  bool _isMaxLove = false; // 100% 달성 시 왕관+날개+무지개 오라 슈퍼 변신!
  int _selectedAccessoryIndex = 0; // 0: 👑 왕관, 1: 🕶️ 선글라스, 2: 🎀 리본, 3: 🎩 마술모자
  static const List<({String emoji, String label})> _accessories = [
    (emoji: '👑', label: '황금왕관'),
    (emoji: '🕶️', label: '선글라스'),
    (emoji: '🎀', label: '핑크리본'),
    (emoji: '🎩', label: '마술모자'),
  ];
  int _totalStars = 0;
  int _petCount = 0;

  // ── 리얼 쓰다듬기(Stroking) 상태 ──
  bool _isBeingRubbed = false;
  Offset? _activeHandLocalPos; // 스테이지(250x250) 내부 손 위치
  double _rubTiltAngle = 0.0; // 쓰다듬는 방향으로 캐릭터가 갸우뚱 기울어짐
  double _rubSquish = 0.0; // 말랑말랑 젤리 눌림 정도 (0.0 ~ 0.14)
  double _affectionProgress = 0.0; // 0.0 ~ 1.0 (사랑 게이지)
  double _accumulatedRubDist = 0.0;
  DateTime _lastStrokeSoundTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastVoiceTime = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _rubEndTimer;

  String _shibaSpeech = '신비한 알을 톡톡 두드리거나 따뜻하게 문질러 봐 멍! 🥚';
  bool _isShibaCelebrating = false;
  Timer? _shibaTimer;

  _HatchlingInfo get _currentHatchling => _hatchlings[_currentIndex];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));

    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _hatchPopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // 쓰다듬기 버튼 클릭 시 손바닥이 머리 위를 실제로 왕복하며 쓰다듬는 애니메이션
    _autoPetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(_onAutoPetTick);

    _particleTicker = createTicker((_) {
      bool dirty = false;
      if (_particles.isNotEmpty) {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += (p.kind == 0) ? 0.16 : -0.04; // 하트·음표는 위로 둥실 떠오름!
          p.rotation += p.vRot;
          p.life -= 0.024;
        }
        _particles.removeWhere((p) => p.life <= 0);
        dirty = true;
      }
      if (_rubTrail.isNotEmpty) {
        for (final t in _rubTrail) {
          t.life -= 0.05;
        }
        _rubTrail.removeWhere((t) => t.life <= 0);
        dirty = true;
      }
      // 쓰다듬기가 끝났을 때 기울기와 젤리 탄성 복원
      if (!_isBeingRubbed &&
          (_rubTiltAngle.abs() > 0.002 || _rubSquish > 0.002)) {
        _rubTiltAngle *= 0.82;
        _rubSquish *= 0.82;
        dirty = true;
      }
      if (dirty && mounted) {
        setState(() {});
      }
    })..start();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        AudioManager.instance.playVoice('audio/voice_egg_intro.wav');
      }
    });
  }

  @override
  void dispose() {
    _rubEndTimer?.cancel();
    _shibaTimer?.cancel();
    _particleTicker.dispose();
    _autoPetCtrl.dispose();
    _confettiCtrl.dispose();
    _wobbleCtrl.dispose();
    _floatCtrl.dispose();
    _bgCtrl.dispose();
    _hatchPopCtrl.dispose();
    super.dispose();
  }

  // ── 자동 쓰다듬기 모션 (버튼을 눌렀을 때도 실제 손이 머리를 슥삭슥삭 문질러 줌!) ──
  void _startAutoPetMotion(Offset globalCenter) {
    _rubEndTimer?.cancel();
    setState(() {
      _isBeingRubbed = true;
    });
    _triggerRealRubFeedback(
      globalPos: globalCenter,
      localPos: const Offset(125, 86),
      deltaX: 8.0,
      forceVoice: true,
    );
    _autoPetCtrl.forward(from: 0.0).whenComplete(() {
      if (mounted) {
        setState(() {
          _isBeingRubbed = false;
          _activeHandLocalPos = null;
        });
      }
    });
  }

  void _onAutoPetTick() {
    final t = _autoPetCtrl.value;
    // 2.5회 왕복 사인파 스트로크
    final wave = sin(t * pi * 5);
    final cosWave = cos(t * pi * 5);
    final handX = 125.0 + wave * 46.0;
    final handY = 78.0 + (1 - wave.abs()) * 10.0;
    final localPos = Offset(handX, handY);

    _rubTiltAngle = (wave * 0.14).clamp(-0.18, 0.18);
    _rubSquish = 0.06 + (1 - wave.abs()) * 0.06;
    _activeHandLocalPos = localPos;

    _rubTrail.add(_RubTrailPoint(
      localPos: localPos,
      color: _currentHatchling.eggBaseColor,
    ));

    // 왕복 방향이 바뀔 때마다 리얼 쓰다듬기 마찰 사운드 + 햅틱 + 하트 방울
    final now = DateTime.now();
    if (now.difference(_lastStrokeSoundTime).inMilliseconds > 260 &&
        cosWave.abs() > 0.5) {
      _lastStrokeSoundTime = now;
      HapticFeedback.selectionClick();
      AudioManager.instance.playEggRealPetStroke(
        creatureId: _currentHatchling.id,
        isHatched: _isHatched,
        speakVoice: false,
      );
      final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
      _spawnFloatingLoveParticles(
        Offset(size.width / 2 + wave * 42, size.height * 0.42),
        count: 3,
      );
    }
    setState(() {});
  }

  // ── 손가락으로 직접 문질문질 드래그 쓰다듬기 (Pan Gesture) ──
  void _onRubStart(DragStartDetails details) {
    _rubEndTimer?.cancel();
    _autoPetCtrl.stop();
    setState(() {
      _isBeingRubbed = true;
      _activeHandLocalPos = details.localPosition;
    });
    _triggerRealRubFeedback(
      globalPos: details.globalPosition,
      localPos: details.localPosition,
      deltaX: 4.0,
      forceVoice: false,
    );
  }

  void _onRubUpdate(DragUpdateDetails details) {
    final delta = details.delta;
    _accumulatedRubDist += delta.distance;

    setState(() {
      _isBeingRubbed = true;
      _activeHandLocalPos = details.localPosition;
      // 손가락이 움직이는 방향으로 캐릭터가 말랑하게 기울어지며 눌림
      _rubTiltAngle =
          (_rubTiltAngle * 0.7 + (delta.dx * 0.012)).clamp(-0.20, 0.20);
      _rubSquish = (_rubSquish * 0.75 + (delta.distance * 0.005)).clamp(0.03, 0.14);

      _rubTrail.add(_RubTrailPoint(
        localPos: details.localPosition,
        color: _currentHatchling.eggBaseColor,
      ));
    });

    if (_accumulatedRubDist >= 26.0) {
      _accumulatedRubDist = 0.0;
      _triggerRealRubFeedback(
        globalPos: details.globalPosition,
        localPos: details.localPosition,
        deltaX: delta.dx,
        forceVoice: false,
      );
    }
  }

  void _onRubEnd() {
    _rubEndTimer?.cancel();
    _rubEndTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted && !_autoPetCtrl.isAnimating) {
        setState(() {
          _isBeingRubbed = false;
          _activeHandLocalPos = null;
        });
      }
    });
  }

  void _triggerRealRubFeedback({
    required Offset globalPos,
    required Offset localPos,
    required double deltaX,
    required bool forceVoice,
  }) {
    final info = _currentHatchling;
    final now = DateTime.now();
    final canPlayStroke =
        now.difference(_lastStrokeSoundTime).inMilliseconds >= 210;
    final canSpeakVoice = forceVoice ||
        now.difference(_lastVoiceTime).inMilliseconds >= 3400;

    if (canPlayStroke) {
      _lastStrokeSoundTime = now;
      HapticFeedback.selectionClick();
      if (canSpeakVoice) {
        _lastVoiceTime = now;
      }
      AudioManager.instance.playEggRealPetStroke(
        creatureId: info.id,
        isHatched: _isHatched,
        speakVoice: canSpeakVoice,
      );
    }

    if (_isHatched) {
      _spawnFloatingLoveParticles(globalPos, count: 4);
      setState(() {
        _petCount++;
        final prevAffection = _affectionProgress;
        _affectionProgress = (_affectionProgress + 0.12).clamp(0.0, 1.0);
        if (_petCount % 3 == 0) {
          _totalStars += 1;
        }
        // 사랑 게이지 100% 달성 시: 알 껍질을 벗고 왕관+날개 슈퍼 해피 모습으로 변신!
        if (prevAffection < 1.0 && _affectionProgress >= 1.0) {
          _isMaxLove = true;
          _maxLovedIds.add(info.id);
          _totalStars += 3;
          _confettiCtrl.play();
          _hatchPopCtrl.forward(from: 0.0);
          HapticFeedback.heavyImpact();
          AudioManager.instance.playMagicUnfoldSuccess();
          Future.delayed(const Duration(milliseconds: 220), () {
            AudioManager.instance.playVoice('audio/voice_egg_pet3.wav');
          });
          _spawnShellChips(
            globalPos,
            const Color(0xFFFFD54F),
            const Color(0xFFFF4081),
            count: 30,
            includeStars: true,
          );
          _setShibaSpeech(
            '👑 우와! 사랑 100%! ${info.name}(이)가 쑥쑥 자라 슈퍼 왕관 친구로 변신했어 멍! ⭐+3',
            celebrate: true,
          );
        } else {
          _setShibaSpeech(
            '${info.emoji} ${info.petReaction}',
            celebrate: true,
          );
        }
      });
    } else {
      // 부화 전 알을 따뜻하게 문질러 줄 때
      _spawnFloatingLoveParticles(globalPos, count: 3);
      setState(() {
        _affectionProgress = (_affectionProgress + 0.18).clamp(0.0, 1.0);
        if (_affectionProgress >= 1.0) {
          _affectionProgress = 0.0;
          _onEggTapped(globalPos);
        } else {
          _setShibaSpeech(
            '🌡️ 스르륵~ 알을 따뜻하게 문질러 주니까 안에서 아기가 좋아해 멍! 💓',
            celebrate: false,
          );
        }
      });
    }
  }

  void _onEggTapped(Offset globalPos) {
    if (_isHatched) {
      _startAutoPetMotion(globalPos);
      return;
    }

    HapticFeedback.mediumImpact();
    _wobbleCtrl.forward(from: 0.0);

    setState(() {
      _crackStep++;
    });

    final info = _currentHatchling;
    _spawnShellChips(globalPos, info.eggBaseColor, info.eggAccentColor,
        count: 11);

    if (_crackStep < _maxCrackSteps) {
      AudioManager.instance.playEggTap(tapStep: _crackStep);
      AudioManager.instance.playEggCrackVoice(_crackStep);

      final remaining = _maxCrackSteps - _crackStep;
      final speeches = [
        '톡! 톡! 어라? 알이 흔들흔들 움직여 멍! 🥚',
        '빠직! 금이 갔어! $remaining번만 더 톡톡 해봐 멍! ✨',
        '우와! 안에서 "${info.soundText}" 소리가 들려 멍! 💓',
      ];
      _setShibaSpeech(speeches[_crackStep % speeches.length], celebrate: false);
    } else {
      _hatchEgg(globalPos);
    }
  }

  void _hatchEgg(Offset globalPos) {
    final info = _currentHatchling;
    HapticFeedback.heavyImpact();
    _confettiCtrl.play();
    _hatchPopCtrl.forward(from: 0.0);

    AudioManager.instance.playEggHatchComplete(info.id);

    setState(() {
      _isHatched = true;
      _isMaxLove = false;
      _discoveredIds.add(info.id);
      _totalStars += 3;
      _petCount = 0;
      _affectionProgress = 0.20;
    });

    _spawnShellChips(globalPos, info.eggBaseColor, info.eggAccentColor,
        count: 26, includeStars: true);
    _setShibaSpeech(
      '🎉 짜잔! ${info.emoji} ${info.name} 탄생! 손가락으로 문질문질 쓰다듬어 봐 멍!',
      celebrate: true,
    );
  }

  void _selectNextEgg({int? targetIndex}) {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    _autoPetCtrl.stop();
    setState(() {
      if (targetIndex != null) {
        _currentIndex = targetIndex;
      } else {
        final unhatchedIdx = _hatchlings.indexWhere(
          (h) => !_discoveredIds.contains(h.id),
        );
        if (unhatchedIdx != -1 && unhatchedIdx != _currentIndex) {
          _currentIndex = unhatchedIdx;
        } else {
          _currentIndex = (_currentIndex + 1) % _hatchlings.length;
        }
      }
      _crackStep = 0;
      _isHatched = false;
      _isMaxLove = false;
      _petCount = 0;
      _affectionProgress = 0.0;
      _isBeingRubbed = false;
      _activeHandLocalPos = null;
      _rubTrail.clear();
    });

    _setShibaSpeech(
      '새로운 신비한 알이 나타났어! 톡톡 두드리거나 문질러 깨워봐 멍! 🥚',
      celebrate: false,
    );
  }

  void _setShibaSpeech(String text, {required bool celebrate}) {
    _shibaTimer?.cancel();
    setState(() {
      _shibaSpeech = text;
      if (celebrate) _isShibaCelebrating = true;
    });
    if (celebrate) {
      _shibaTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isShibaCelebrating = false);
      });
    }
  }

  void _spawnFloatingLoveParticles(Offset center, {int count = 5}) {
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    final cx = center == Offset.zero ? size.width / 2 : center.dx;
    final cy = center == Offset.zero ? size.height * 0.42 : center.dy;

    final colors = [
      const Color(0xFFFF4081),
      const Color(0xFFFF80AB),
      const Color(0xFFFFCA28),
      const Color(0xFF40C4FF),
    ];

    for (int i = 0; i < count; i++) {
      _particles.add(_EggShellPiece(
        x: cx + (_rng.nextDouble() - 0.5) * 44,
        y: cy - 10 + (_rng.nextDouble() - 0.5) * 24,
        vx: (_rng.nextDouble() - 0.5) * 2.2,
        vy: -1.4 - _rng.nextDouble() * 2.0,
        size: 11 + _rng.nextDouble() * 7,
        life: 1.0,
        color: colors[i % colors.length],
        rotation: (_rng.nextDouble() - 0.5) * 0.4,
        vRot: (_rng.nextDouble() - 0.5) * 0.06,
        kind: (i % 3 == 0) ? 3 : 2, // 2: 하트, 3: 음표/반짝이
      ));
    }
  }

  void _spawnShellChips(
    Offset center,
    Color c1,
    Color c2, {
    int count = 12,
    bool includeStars = false,
  }) {
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    final cx = center == Offset.zero ? size.width / 2 : center.dx;
    final cy = center == Offset.zero ? size.height * 0.45 : center.dy;

    final colors = [
      c1,
      c2,
      Colors.white,
      const Color(0xFFFFD54F),
      const Color(0xFFFF80AB),
    ];

    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.5 + _rng.nextDouble() * 6.0;
      _particles.add(_EggShellPiece(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2.2,
        size: 7 + _rng.nextDouble() * 8,
        life: 1.0,
        color: colors[i % colors.length],
        rotation: _rng.nextDouble() * pi,
        vRot: (_rng.nextDouble() - 0.5) * 0.25,
        kind: (includeStars && (i % 2 == 0)) ? 1 : 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _currentHatchling;

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE0F7FA),
                Color(0xFFFFF9C4),
                Color(0xFFFCE4EC),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 1. 아기자기한 숲속 둥지 배경
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bgCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _EggForestBackgroundPainter(
                        animValue: _bgCtrl.value,
                      ),
                    );
                  },
                ),
              ),

              // 2. 메인 콘텐츠
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    _buildMascotBar(),
                    const SizedBox(height: 8),

                    // 중앙 알 & 둥지 & 리얼 쓰다듬기 스테이지
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildEggNestStage(info),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 하단 12종 알/아기동물 도감 선택 바
                    _buildCollectionCarousel(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // 3. 알 껍질 & 하트 & 음표 파티클 오버레이
              if (_particles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _EggParticlePainter(particles: _particles),
                    ),
                  ),
                ),

              // 4. 부화 & 사랑 게이지 축하 컨페티
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 35,
                  colors: const [
                    Color(0xFFFF6B6B),
                    Color(0xFF4ECDC4),
                    Color(0xFFFFE66D),
                    Color(0xFFFF80AB),
                    Color(0xFFBA68C8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
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

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
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
                children: [
                  const Text('🥚', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '톡톡 깜짝 알 깨기',
                      style: GoogleFonts.jua(
                        fontSize: 17,
                        color: const Color(0xFF4E342E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                    ),
                    child: Text(
                      '도감 ${_discoveredIds.length}/${_hatchlings.length}',
                      style: GoogleFonts.jua(
                        fontSize: 11.5,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFFF8F00)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '$_totalStars',
                  style: GoogleFonts.jua(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isHatched) {
                AudioManager.instance
                    .playEggHatchComplete(_currentHatchling.id);
              } else {
                AudioManager.instance.playVoice('audio/voice_egg_intro.wav');
              }
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
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
                  animations: [
                    _isShibaCelebrating ? 'WinEndState' : 'Anim_shiba'
                  ],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD54F), width: 1.8),
              ),
              child: Text(
                _shibaSpeech,
                style: GoogleFonts.jua(
                  fontSize: 13,
                  color: const Color(0xFF4E342E),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _selectNextEgg(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🥚', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '다음 알',
                    style: GoogleFonts.jua(fontSize: 12.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEggNestStage(_HatchlingInfo info) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 405),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFDF8),
            Color(0xFFFFF6E5),
          ],
        ),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFFFCA28), width: 4.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD49A35),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x245D4037),
            offset: Offset(0, 14),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 게이지: 부화 전에는 알 깨기 단계 / 부화 후에는 💕 쓰다듬기 사랑 게이지!
          if (!_isHatched)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_maxCrackSteps, (idx) {
                    final filled = idx < _crackStep;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedScale(
                        scale: filled ? 1.18 : 0.92,
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.elasticOut,
                        child: Text(
                          filled ? '🥚' : '⚪',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    '톡톡 $_crackStep / $_maxCrackSteps',
                    style: GoogleFonts.jua(
                      fontSize: 13,
                      color: const Color(0xFF6D4C41),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: _isMaxLove
                    ? const LinearGradient(
                        colors: [Color(0xFFFFF59D), Color(0xFFFFCA28)],
                      )
                    : null,
                color: _isMaxLove ? null : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isMaxLove
                      ? const Color(0xFFFF8F00)
                      : const Color(0xFFFF80AB),
                  width: 1.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isMaxLove
                        ? '👑 슈퍼 해피 변신 완료! ✨'
                        : (_isBeingRubbed ? '👋 쓰다듬는 중~' : '💕 사랑 게이지'),
                    style: GoogleFonts.jua(
                      fontSize: 12.5,
                      color: _isMaxLove
                          ? const Color(0xFFBF360C)
                          : const Color(0xFFC2185B),
                    ),
                  ),
                  if (!_isMaxLove) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 110,
                      height: 12,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _affectionProgress,
                          backgroundColor: Colors.white,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF4081),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(_affectionProgress * 100).round()}%',
                      style: GoogleFonts.jua(
                        fontSize: 12.5,
                        color: const Color(0xFFC2185B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 10),

          // 중앙 알 또는 부화한 아기 동물 (터치 + 좌우로 문질문질 드래그 쓰다듬기 모두 지원!)
          GestureDetector(
            onTapDown: (details) => _onEggTapped(details.globalPosition),
            onPanStart: _onRubStart,
            onPanUpdate: _onRubUpdate,
            onPanEnd: (_) => _onRubEnd(),
            onPanCancel: _onRubEnd,
            child: AnimatedBuilder(
              animation: Listenable.merge([_wobbleCtrl, _floatCtrl]),
              builder: (context, child) {
                final wobbleAngle =
                    sin(_wobbleCtrl.value * pi * 4) * (0.07 + _crackStep * 0.015) +
                        _rubTiltAngle;
                final wobbleScale = 1.0 + sin(_wobbleCtrl.value * pi) * 0.06;
                final floatY = (_floatCtrl.value - 0.5) * 6.0;
                final scaleX = wobbleScale * (1.0 + _rubSquish);
                final scaleY = wobbleScale * (1.0 - _rubSquish * 0.68);

                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: Transform.rotate(
                    angle: wobbleAngle,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                      child: child,
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: 250,
                height: 250,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. 포근한 짚단 둥지 (하단)
                    Positioned(
                      bottom: 2,
                      child: CustomPaint(
                        size: const Size(224, 74),
                        painter: _CozyStrawNestPainter(),
                      ),
                    ),

                    // 2. 부화 전: 3D 무늬 알 / 부화 후: 깨진 알 아랫부분 요람 + 귀여운 아기 동물
                    if (!_isHatched)
                      Positioned(
                        bottom: 22,
                        child: CustomPaint(
                          size: const Size(165, 195),
                          painter: _Luxury3DEggPainter(
                            baseColor: info.eggBaseColor,
                            accentColor: info.eggAccentColor,
                            lightColor: info.eggLightColor,
                            pattern: info.pattern,
                            crackStep: _crackStep,
                            isWarmGlow: _isBeingRubbed,
                          ),
                        ),
                      )
                    else
                      Positioned.fill(
                        child: _buildHatchedCreatureView(info),
                      ),

                    // 3. 손가락으로 문질문질할 때 따라다니는 따뜻한 빛 궤적 & 진짜 쓰다듬는 손(👋)
                    if (_rubTrail.isNotEmpty || _activeHandLocalPos != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _RubHandAndTrailPainter(
                              trail: _rubTrail,
                              handPos: _activeHandLocalPos,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 하단 액션 버튼 영역
          if (!_isHatched)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Builder(
                  builder: (btnCtx) {
                    return GestureDetector(
                      onTap: () {
                        final rb = btnCtx.findRenderObject() as RenderBox?;
                        final pos = rb != null
                            ? rb.localToGlobal(Offset(
                                rb.size.width / 2, rb.size.height / 2))
                            : Offset.zero;
                        _onEggTapped(pos);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7043), Color(0xFFF4511E)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44E64A19),
                              offset: Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔨', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 5),
                            Text(
                              '톡! 톡! 두드리기',
                              style: GoogleFonts.jua(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (warmCtx) {
                    return GestureDetector(
                      onTap: () {
                        final rb = warmCtx.findRenderObject() as RenderBox?;
                        final pos = rb != null
                            ? rb.localToGlobal(Offset(
                                rb.size.width / 2, rb.size.height / 2))
                            : Offset.zero;
                        _startAutoPetMotion(pos);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 2.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👋', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 5),
                            Text(
                              '알 쓰다듬기',
                              style: GoogleFonts.jua(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          else
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: _isMaxLove
                        ? const LinearGradient(
                            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                          )
                        : null,
                    color: _isMaxLove
                        ? null
                        : info.eggLightColor.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _isMaxLove
                          ? const Color(0xFFFF8F00)
                          : info.eggBaseColor,
                      width: 1.8,
                    ),
                  ),
                  child: Text(
                    _isMaxLove
                        ? '👑 사랑을 듬뿍 받아 알 껍질을 벗고 슈퍼 친구로 쑥쑥 자랐어요! ✨'
                        : (_isBeingRubbed ? info.petReaction : info.greeting),
                    style: GoogleFonts.jua(
                      fontSize: 13.5,
                      color: const Color(0xFF4E342E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 사랑 게이지 100% 달성 시 오픈되는 [슈퍼 변신 꾸미기 & 간식 주기] 바!
                if (_isMaxLove) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(_accessories.length, (idx) {
                          final acc = _accessories[idx];
                          final selected = _selectedAccessoryIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                AudioManager.instance.playRacingItemStar();
                                setState(() {
                                  _selectedAccessoryIndex = idx;
                                });
                                _setShibaSpeech(
                                  '${acc.emoji} 우와! ${info.name}에게 ${acc.label}(을)를 씌워줬어 멍! 멋지다!',
                                  celebrate: true,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFFFCA28)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFFFF6F00)
                                        : const Color(0xFFFFE082),
                                    width: selected ? 2.2 : 1.4,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(acc.emoji,
                                        style: const TextStyle(fontSize: 15)),
                                    const SizedBox(width: 3),
                                    Text(
                                      acc.label,
                                      style: GoogleFonts.jua(
                                        fontSize: 11.5,
                                        color: const Color(0xFF4E342E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              AudioManager.instance.playSnakeEatStar();
                              _wobbleCtrl.forward(from: 0.0);
                              final size = MediaQuery.maybeOf(context)?.size ??
                                  const Size(380, 760);
                              _spawnFloatingLoveParticles(
                                Offset(size.width / 2, size.height * 0.42),
                                count: 8,
                              );
                              setState(() {
                                _totalStars += 1;
                              });
                              _setShibaSpeech(
                                '🍓 냠냠쩝쩝! ${info.name}(이)가 달콤한 딸기 간식을 맛있게 먹었어 멍! ⭐+1',
                                celebrate: true,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF80AB),
                                    Color(0xFFFF4081)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🍓',
                                      style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '간식주기',
                                    style: GoogleFonts.jua(
                                      fontSize: 11.5,
                                      color: Colors.white,
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
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (petBtnCtx) {
                        return GestureDetector(
                          onTap: () {
                            final rb =
                                petBtnCtx.findRenderObject() as RenderBox?;
                            final pos = rb != null
                                ? rb.localToGlobal(Offset(
                                    rb.size.width / 2, rb.size.height / 2))
                                : Offset.zero;
                            _startAutoPetMotion(pos);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x40F50057),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('👋',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 5),
                                Text(
                                  '문질문질 쓰다듬기',
                                  style: GoogleFonts.jua(
                                      fontSize: 15, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => _selectNextEgg(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🥚', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 5),
                            Text(
                              '다음 알 깨기!',
                              style: GoogleFonts.jua(
                                  fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHatchedCreatureView(_HatchlingInfo info) {
    final accEmoji = _accessories[_selectedAccessoryIndex].emoji;

    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _hatchPopCtrl,
        curve: Curves.elasticOut,
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 0. 100% 슈퍼 변신 달성 시: 회전하는 황금 무지개 후광 & 파닥이는 천사 날개(🪽)
          if (_isMaxLove) ...[
            Positioned(
              top: 18,
              child: AnimatedBuilder(
                animation: _bgCtrl,
                builder: (context, _) {
                  return Transform.rotate(
                    angle: _bgCtrl.value * 2 * pi,
                    child: Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFF59D).withValues(alpha: 0.85),
                            const Color(0xFFFFCA28).withValues(alpha: 0.45),
                            const Color(0xFFFF80AB).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 왼쪽/오른쪽 천사 날개
            Positioned(
              left: 14,
              top: 76,
              child: Transform.rotate(
                angle: -0.25 + sin(_floatCtrl.value * pi) * 0.18,
                child: const Text('🪽', style: TextStyle(fontSize: 40)),
              ),
            ),
            Positioned(
              right: 14,
              top: 76,
              child: Transform.flip(
                flipX: true,
                child: Transform.rotate(
                  angle: -0.25 + sin(_floatCtrl.value * pi) * 0.18,
                  child: const Text('🪽', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ],

          // 1. 상단 사운드 & 애교 상태 말풍선
          Positioned(
            top: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isMaxLove
                    ? const Color(0xFFFFF8E1)
                    : (_isBeingRubbed
                        ? const Color(0xFFFFF0F5)
                        : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isMaxLove
                      ? const Color(0xFFFF8F00)
                      : (_isBeingRubbed
                          ? const Color(0xFFFF4081)
                          : info.eggBaseColor),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: info.eggBaseColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _isMaxLove
                    ? '👑 슈퍼 ${info.name}! 사랑해 친구야! 💖'
                    : (_isBeingRubbed
                        ? '💖 기분 좋아~ 골골골~ 🎵'
                        : '${info.soundText} (손으로 문질러 봐! 👋)'),
                style: GoogleFonts.jua(
                  fontSize: 13,
                  color: _isMaxLove
                      ? const Color(0xFFE65100)
                      : (_isBeingRubbed
                          ? const Color(0xFFD81B60)
                          : info.eggBaseColor),
                ),
              ),
            ),
          ),

          // 2. 아기 동물 캐릭터 본체 (100% 변신 시 1.16배 쑥쑥 커지고 황금 테두리 & 왕관/액세서리 착용!)
          Positioned(
            top: _isMaxLove ? 30 : 38,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              width: _isMaxLove ? 158 : 142,
              height: _isMaxLove ? 158 : 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: _isMaxLove
                      ? [
                          Colors.white,
                          const Color(0xFFFFF59D),
                          const Color(0xFFFFCA28).withValues(alpha: 0.65),
                        ]
                      : [
                          Colors.white,
                          _isBeingRubbed
                              ? const Color(0xFFFFCDD2)
                              : info.eggLightColor,
                          info.eggBaseColor.withValues(alpha: 0.38),
                        ],
                ),
                border: Border.all(
                  color: _isMaxLove
                      ? const Color(0xFFFFB300)
                      : (_isBeingRubbed
                          ? const Color(0xFFFF80AB)
                          : Colors.white),
                  width: _isMaxLove ? 4.5 : 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isMaxLove
                            ? const Color(0xFFFFB300)
                            : (_isBeingRubbed
                                ? const Color(0xFFFF4081)
                                : info.eggBaseColor))
                        .withValues(alpha: 0.45),
                    blurRadius: (_isMaxLove || _isBeingRubbed) ? 24 : 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(fontSize: _isMaxLove ? 90 : 78),
                    child: Text(info.emoji),
                  ),

                  // 100% 변신 시 머리 위 왕관/선글라스/리본/모자 & 가슴의 하트 메달(💝)!
                  if (_isMaxLove) ...[
                    Positioned(
                      top: _selectedAccessoryIndex == 1 ? 38 : -14,
                      child: Text(
                        accEmoji,
                        style: TextStyle(
                          fontSize: _selectedAccessoryIndex == 1 ? 42 : 38,
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 8,
                      child: Text('💝', style: TextStyle(fontSize: 24)),
                    ),
                  ],

                  // 쓰다듬거나 100% 변신 상태일 때 양 볼 발그레 & 하트 반짝이
                  if (_isBeingRubbed || _isMaxLove) ...[
                    Positioned(
                      left: 18,
                      bottom: 44,
                      child: Container(
                        width: 24,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 18,
                      bottom: 44,
                      child: Container(
                        width: 24,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 8,
                      right: 10,
                      child: Text('💕', style: TextStyle(fontSize: 20)),
                    ),
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Text('✨', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. 100% 변신 전에는 깨진 알 껍질 요람 안에 앉아 있고, 100% 달성 시 알 껍질을 완전히 벗고 독립!
          if (!_isMaxLove)
            Positioned(
              bottom: 24,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(156, 72),
                  painter: _BrokenBottomShellPainter(
                    baseColor: info.eggBaseColor,
                    accentColor: info.eggAccentColor,
                    lightColor: info.eggLightColor,
                  ),
                ),
              ),
            ),

          // 4. 아기 동물 이름표 (100% 달성 시 '👑 슈퍼 아기 티라노' 골드 배지로 업그레이드!)
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isMaxLove
                      ? const [Color(0xFFFFB300), Color(0xFFF57C00)]
                      : [info.eggBaseColor, KidsTheme.orange],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2.0),
              ),
              child: Text(
                _isMaxLove ? '👑 슈퍼 ${info.name}' : info.name,
                style: GoogleFonts.jua(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCarousel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F795548),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🐣 알록달록 알 도감 (알을 골라 깨우고 쓰다듬어 보세요!)',
            style: GoogleFonts.jua(
              fontSize: 12,
              color: const Color(0xFF6D4C41),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(_hatchlings.length, (idx) {
                final h = _hatchlings[idx];
                final isSelected = idx == _currentIndex;
                final isDiscovered = _discoveredIds.contains(h.id);
                final isMaxLoved = _maxLovedIds.contains(h.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GestureDetector(
                    onTap: () => _selectNextEgg(targetIndex: idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? h.eggBaseColor
                            : (isMaxLoved
                                ? const Color(0xFFFFF8E1)
                                : (isDiscovered
                                    ? h.eggLightColor.withValues(alpha: 0.6)
                                    : const Color(0xFFF5F5F5))),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : (isMaxLoved
                                  ? const Color(0xFFFFB300)
                                  : (isDiscovered
                                      ? h.eggBaseColor
                                      : Colors.grey.shade300)),
                          width: (isSelected || isMaxLoved) ? 2.5 : 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMaxLoved)
                            const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child:
                                  Text('👑', style: TextStyle(fontSize: 13)),
                            ),
                          Text(
                            isDiscovered ? h.emoji : '🥚',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDiscovered ? h.name : '깜짝 알 ${idx + 1}',
                            style: GoogleFonts.jua(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4E342E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painters for 3D Egg, Broken Eggshell Cradle, Petting Hand Trail & Nest
// ─────────────────────────────────────────────────────────────────────────────

/// 쓰다듬을 때 손가락을 따라다니는 포근한 하트 빛 궤적 & 쓰다듬는 손(👋) 페인터
class _RubHandAndTrailPainter extends CustomPainter {
  final List<_RubTrailPoint> trail;
  final Offset? handPos;

  _RubHandAndTrailPainter({
    required this.trail,
    required this.handPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 부드러운 핑크/골드 쓰다듬기 온기 궤적
    for (final pt in trail) {
      final alpha = (pt.life * 0.55).clamp(0.0, 1.0);
      final radius = 16.0 * pt.life;
      final paint = Paint()
        ..color = const Color(0xFFFF80AB).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pt.localPos, radius, paint);
    }

    // 2. 실제로 머리를 쓰다듬는 손바닥(👋) 커서 렌더링
    if (handPos != null) {
      final pos = handPos!;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);

      // 따뜻한 후광 원
      canvas.drawCircle(
        Offset.zero,
        24,
        Paint()
          ..color = const Color(0xFFFFF59D).withValues(alpha: 0.65)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      final tp = TextPainter(
        text: const TextSpan(
          text: '👋',
          style: TextStyle(fontSize: 36),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RubHandAndTrailPainter oldDelegate) => true;
}

/// 부화한 뒤 아기 동물이 쏙 들어가 앉아 있는 깨진 알 껍질 하단 요람 페인터
class _BrokenBottomShellPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;
  final Color lightColor;

  _BrokenBottomShellPainter({
    required this.baseColor,
    required this.accentColor,
    required this.lightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 지그재그로 깨진 윗부분 림 + 둥근 알 아랫부분
    final shellPath = Path()
      ..moveTo(w * 0.06, h * 0.22)
      ..lineTo(w * 0.20, h * 0.40)
      ..lineTo(w * 0.34, h * 0.16)
      ..lineTo(w * 0.50, h * 0.38)
      ..lineTo(w * 0.66, h * 0.15)
      ..lineTo(w * 0.80, h * 0.38)
      ..lineTo(w * 0.94, h * 0.20)
      ..cubicTo(w * 0.96, h * 0.72, w * 0.76, h * 0.96, w * 0.50, h * 0.96)
      ..cubicTo(w * 0.24, h * 0.96, w * 0.04, h * 0.72, w * 0.06, h * 0.22)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          lightColor,
          baseColor,
          Color.lerp(baseColor, const Color(0xFF3E2723), 0.28)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shellPath, fillPaint);

    // 껍질 두께(흰색 속껍질 테두리)
    canvas.drawPath(
      shellPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      shellPath,
      Paint()
        ..color = Color.lerp(baseColor, const Color(0xFF3E2723), 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BrokenBottomShellPainter old) =>
      old.baseColor != baseColor;
}

class _Luxury3DEggPainter extends CustomPainter {
  final Color baseColor;
  final Color accentColor;
  final Color lightColor;
  final EggPatternType pattern;
  final int crackStep;
  final bool isWarmGlow;

  _Luxury3DEggPainter({
    required this.baseColor,
    required this.accentColor,
    required this.lightColor,
    required this.pattern,
    required this.crackStep,
    this.isWarmGlow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final eggPath = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..cubicTo(w * 0.88, h * 0.04, w * 0.98, h * 0.52, w * 0.92, h * 0.74)
      ..cubicTo(w * 0.86, h * 0.94, w * 0.68, h * 0.98, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.32, h * 0.98, w * 0.14, h * 0.94, w * 0.08, h * 0.74)
      ..cubicTo(w * 0.02, h * 0.52, w * 0.12, h * 0.04, w * 0.5, h * 0.04)
      ..close();

    if (isWarmGlow) {
      canvas.drawPath(
        eggPath,
        Paint()
          ..color = const Color(0xFFFF80AB).withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }

    // 1. 입체 3D 그라데이션 본체
    final fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.95,
        colors: [
          lightColor,
          baseColor,
          Color.lerp(baseColor, const Color(0xFF3E2723), 0.32)!,
        ],
        stops: const [0.0, 0.62, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(eggPath, fillPaint);

    // 2. 알 무늬 클리핑 드로잉
    canvas.save();
    canvas.clipPath(eggPath);
    _drawEggPattern(canvas, size);
    canvas.restore();

    // 3. 알 테두리 & 좌상단 광택 글린트
    final borderPaint = Paint()
      ..color = Color.lerp(baseColor, const Color(0xFF3E2723), 0.4)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawPath(eggPath, borderPaint);

    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.52)
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(w * 0.32, h * 0.24);
    canvas.rotate(-0.38);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: h * 0.26),
      glossPaint,
    );
    canvas.restore();

    // 4. 터치 단계별 금(Crack) 라인
    if (crackStep > 0) {
      _drawCracks(canvas, size, crackStep);
    }
  }

  void _drawEggPattern(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.82)
      ..style = PaintingStyle.fill;

    switch (pattern) {
      case EggPatternType.spots:
        final spots = [
          Offset(w * 0.32, h * 0.32),
          Offset(w * 0.68, h * 0.28),
          Offset(w * 0.50, h * 0.52),
          Offset(w * 0.26, h * 0.66),
          Offset(w * 0.72, h * 0.64),
          Offset(w * 0.48, h * 0.80),
        ];
        for (int i = 0; i < spots.length; i++) {
          canvas.drawCircle(spots[i], (i % 2 == 0) ? 14 : 11, pPaint);
        }
        break;
      case EggPatternType.stripes:
        final stripePaint = Paint()
          ..color = accentColor.withValues(alpha: 0.78)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round;
        for (final yFactor in [0.30, 0.52, 0.74]) {
          final path = Path()
            ..moveTo(0, h * yFactor)
            ..quadraticBezierTo(w * 0.5, h * (yFactor + 0.08), w, h * yFactor);
          canvas.drawPath(path, stripePaint);
        }
        break;
      case EggPatternType.zigzag:
        final zigPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeJoin = StrokeJoin.round;
        for (final yBase in [h * 0.35, h * 0.64]) {
          final path = Path()..moveTo(0, yBase);
          for (int i = 1; i <= 6; i++) {
            path.lineTo(w * (i / 6), yBase + ((i % 2 == 0) ? -12 : 12));
          }
          canvas.drawPath(path, zigPaint);
        }
        break;
      case EggPatternType.stars:
      case EggPatternType.hearts:
        final centers = [
          Offset(w * 0.32, h * 0.34),
          Offset(w * 0.68, h * 0.36),
          Offset(w * 0.50, h * 0.56),
          Offset(w * 0.30, h * 0.70),
          Offset(w * 0.70, h * 0.70),
        ];
        for (final c in centers) {
          canvas.drawCircle(c, 12, pPaint);
          canvas.drawCircle(
            c,
            6,
            Paint()..color = Colors.white.withValues(alpha: 0.75),
          );
        }
        break;
    }
  }

  void _drawCracks(Canvas canvas, Size size, int step) {
    final w = size.width;
    final h = size.height;

    final crackShadow = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final crackPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.50, h * 0.25)
      ..lineTo(w * 0.42, h * 0.36)
      ..lineTo(w * 0.54, h * 0.45);

    if (step >= 2) {
      path
        ..lineTo(w * 0.38, h * 0.56)
        ..moveTo(w * 0.42, h * 0.36)
        ..lineTo(w * 0.26, h * 0.42);
    }
    if (step >= 3) {
      path
        ..moveTo(w * 0.54, h * 0.45)
        ..lineTo(w * 0.72, h * 0.40)
        ..lineTo(w * 0.66, h * 0.54);
    }
    if (step >= 4) {
      path
        ..moveTo(w * 0.38, h * 0.56)
        ..lineTo(w * 0.52, h * 0.68)
        ..lineTo(w * 0.44, h * 0.78);
    }

    canvas.drawPath(path, crackShadow);
    canvas.drawPath(path, crackPaint);
  }

  @override
  bool shouldRepaint(covariant _Luxury3DEggPainter old) =>
      old.baseColor != baseColor ||
      old.crackStep != crackStep ||
      old.pattern != pattern ||
      old.isWarmGlow != isWarmGlow;
}

class _CozyStrawNestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromLTWH(w * 0.06, h * 0.35, w * 0.88, h * 0.62),
      Paint()..color = const Color(0x335D4037),
    );

    final nestRect = Rect.fromLTWH(w * 0.04, h * 0.18, w * 0.92, h * 0.74);
    final nestPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD7A86E),
          Color(0xFFA67B44),
          Color(0xFF795548),
        ],
      ).createShader(nestRect);
    canvas.drawOval(nestRect, nestPaint);

    canvas.drawOval(
      Rect.fromLTWH(w * 0.14, h * 0.24, w * 0.72, h * 0.42),
      Paint()..color = const Color(0xFF5D4037).withValues(alpha: 0.75),
    );

    final strawPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 9; i++) {
      final x = w * (0.14 + i * 0.09);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(x, h * 0.62), width: 34, height: 18),
        0.1,
        pi - 0.2,
        false,
        strawPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EggParticlePainter extends CustomPainter {
  final List<_EggShellPiece> particles;

  _EggParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final alpha = p.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      if (p.kind == 2) {
        // 핑크 하트 파티클 (쓰다듬을 때 퐁퐁 피어오름)
        final r = p.size * 0.85;
        final heartPath = Path()
          ..moveTo(0, r * 0.7)
          ..cubicTo(-r * 1.1, r * 0.1, -r * 0.9, -r * 0.8, 0, -r * 0.3)
          ..cubicTo(r * 0.9, -r * 0.8, r * 1.1, r * 0.1, 0, r * 0.7)
          ..close();
        canvas.drawPath(heartPath, paint);
      } else if (p.kind == 3 || p.kind == 1) {
        // 반짝이 별/음표 구슬
        canvas.drawCircle(Offset.zero, p.size * 0.55, paint);
        canvas.drawCircle(
          Offset(-p.size * 0.15, -p.size * 0.15),
          p.size * 0.2,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      } else {
        // 삼각형 알 껍질 조각
        final path = Path()
          ..moveTo(0, -p.size * 0.7)
          ..lineTo(p.size * 0.65, p.size * 0.5)
          ..lineTo(-p.size * 0.65, p.size * 0.4)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _EggParticlePainter oldDelegate) => true;
}

class _EggForestBackgroundPainter extends CustomPainter {
  final double animValue;

  _EggForestBackgroundPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.12 + (i * 0.11));
      final y = size.height * (0.20 + (i % 3) * 0.22) +
          sin(animValue * 2 * pi + i) * 8;
      canvas.drawCircle(Offset(x, y), 6 + (i % 3) * 3.0, glowPaint);
    }

    final hillPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.48)
      ..style = PaintingStyle.fill;
    final hillPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 80)
      ..quadraticBezierTo(
          size.width * 0.5, size.height - 130, size.width, size.height - 75)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(hillPath, hillPaint);
  }

  @override
  bool shouldRepaint(covariant _EggForestBackgroundPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}
