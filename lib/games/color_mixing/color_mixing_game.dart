import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

class _PaintColor {
  final String key;
  final String label;
  final String emoji;
  final Color rgb;
  const _PaintColor({
    required this.key,
    required this.label,
    required this.emoji,
    required this.rgb,
  });
}

class _MixResult {
  final Color color;
  final String name;
  final String funName;
  final String exclaim;
  final String badgeEmoji;
  const _MixResult(
    this.color,
    this.name,
    this.funName,
    this.exclaim,
    this.badgeEmoji,
  );
}

class _ColorMission {
  final List<String> recipeKeys;
  final String targetEmoji;
  final String targetName;
  final Color targetColor;
  final String cheerText;

  const _ColorMission({
    required this.recipeKeys,
    required this.targetEmoji,
    required this.targetName,
    required this.targetColor,
    required this.cheerText,
  });
}

class _DropState {
  final Color color;
  final int tubeIndex;
  final int totalTubes;
  double progress;
  _DropState({
    required this.color,
    required this.tubeIndex,
    required this.totalTubes,
  }) : progress = 0;
}

class _Sparkle {
  double x, y, size, opacity, angle, speed;
  Color color;
  _Sparkle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.angle,
    required this.speed,
    required this.color,
  });
}

class _SplashParticle {
  double x, y, vx, vy, size, opacity;
  Color color;
  _SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

class _StirBubble {
  double x, y, radius, opacity, vy;
  Color color;
  _StirBubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.vy,
    required this.color,
  });
}

class ColorMixingGame extends StatefulWidget {
  const ColorMixingGame({super.key});
  @override
  State<ColorMixingGame> createState() => _ColorMixingGameState();
}

class _ColorMixingGameState extends State<ColorMixingGame>
    with TickerProviderStateMixin {
  static const List<_PaintColor> _kPaints = [
    _PaintColor(key: 'red', label: '빨강', emoji: '🍓', rgb: Color(0xFFE53935)),
    _PaintColor(key: 'orange', label: '주황', emoji: '🍊', rgb: Color(0xFFFF7043)),
    _PaintColor(key: 'yellow', label: '노랑', emoji: '🌟', rgb: Color(0xFFFFD600)),
    _PaintColor(key: 'green', label: '초록', emoji: '🍀', rgb: Color(0xFF43A047)),
    _PaintColor(key: 'blue', label: '파랑', emoji: '🫐', rgb: Color(0xFF1E88E5)),
    _PaintColor(key: 'purple', label: '보라', emoji: '🍇', rgb: Color(0xFF8E24AA)),
    _PaintColor(key: 'pink', label: '분홍', emoji: '🌸', rgb: Color(0xFFEC407A)),
    _PaintColor(key: 'white', label: '하양', emoji: '☁️', rgb: Color(0xFFF5F5F5)),
    _PaintColor(key: 'black', label: '검정', emoji: '🖤', rgb: Color(0xFF424242)),
  ];

  // 3~4세 유아 눈높이에 맞춘 직관적 2색·3색 마법 변신 미션
  static const List<_ColorMission> _kMissions = [
    _ColorMission(
      recipeKeys: ['red', 'yellow'],
      targetEmoji: '🍊',
      targetName: '주황색 오렌지',
      targetColor: Color(0xFFFF6D00),
      cheerText: '우와! 새콤달콤 주황색 오렌지가 되었어요! 🍊',
    ),
    _ColorMission(
      recipeKeys: ['blue', 'yellow'],
      targetEmoji: '🦖',
      targetName: '초록 아기공룡',
      targetColor: Color(0xFF2E7D32),
      cheerText: '크앙! 씩씩한 초록 아기공룡이 나타났어요! 🦖',
    ),
    _ColorMission(
      recipeKeys: ['blue', 'red'],
      targetEmoji: '🍇',
      targetName: '보라색 포도',
      targetColor: Color(0xFF6A1B9A),
      cheerText: '탱글탱글 맛있는 보라색 포도 완성! 🍇',
    ),
    _ColorMission(
      recipeKeys: ['red', 'white'],
      targetEmoji: '🌸',
      targetName: '분홍 벚꽃',
      targetColor: Color(0xFFF48FB1),
      cheerText: '샤랄라~ 예쁜 분홍색 꽃이 피었어요! 🌸',
    ),
    _ColorMission(
      recipeKeys: ['blue', 'white'],
      targetEmoji: '🐳',
      targetName: '하늘색 아기고래',
      targetColor: Color(0xFF29B6F6),
      cheerText: '푸른 바다를 헤엄치는 하늘색 고래예요! 🐳',
    ),
    _ColorMission(
      recipeKeys: ['white', 'yellow'],
      targetEmoji: '🍦',
      targetName: '크림 아이스크림',
      targetColor: Color(0xFFFFF176),
      cheerText: '냠냠! 달콤하고 시원한 아이스크림 완성! 🍦',
    ),
    _ColorMission(
      recipeKeys: ['green', 'yellow'],
      targetEmoji: '🐸',
      targetName: '연두 개구리',
      targetColor: Color(0xFF9CCC65),
      cheerText: '개굴개굴! 귀여운 연두색 개구리예요! 🐸',
    ),
    _ColorMission(
      recipeKeys: ['orange', 'white'],
      targetEmoji: '🍑',
      targetName: '살구빛 복숭아',
      targetColor: Color(0xFFFFAB91),
      cheerText: '말랑말랑 향긋한 복숭아가 되었어요! 🍑',
    ),
    _ColorMission(
      recipeKeys: ['purple', 'white'],
      targetEmoji: '🦄',
      targetName: '라벤더 유니콘',
      targetColor: Color(0xFFCE93D8),
      cheerText: '반짝반짝 신비로운 라벤더 유니콘 탄생! 🦄',
    ),
    _ColorMission(
      recipeKeys: ['blue', 'green'],
      targetEmoji: '🐬',
      targetName: '바다빛 돌고래',
      targetColor: Color(0xFF00ACC1),
      cheerText: '첨벙첨벙! 시원한 바다색 돌고래예요! 🐬',
    ),
    _ColorMission(
      recipeKeys: ['black', 'orange'],
      targetEmoji: '🐻',
      targetName: '갈색 곰돌이',
      targetColor: Color(0xFF6D4C41),
      cheerText: '포근포근 귀여운 갈색 곰돌이가 되었어요! 🐻',
    ),
    _ColorMission(
      recipeKeys: ['blue', 'red', 'yellow'],
      targetEmoji: '🍩',
      targetName: '초코 도넛',
      targetColor: Color(0xFF795548),
      cheerText: '세 가지 색이 모여 달콤한 초코 도넛 완성! 🍩',
    ),
  ];

  static const Map<String, _MixResult> _kMixTable = {
    'red+yellow': _MixResult(Color(0xFFFF6D00), '주황색!', '🍊 새콤달콤 오렌지 색', '와아~! 🤩', '🍊'),
    'blue+yellow': _MixResult(Color(0xFF2E7D32), '초록색!', '🦖 씩씩한 아기공룡 색', '신기해! ✨', '🦖'),
    'blue+red': _MixResult(Color(0xFF6A1B9A), '보라색!', '🍇 탱글탱글 포도 색', '예쁘다! 💜', '🍇'),
    'orange+yellow': _MixResult(Color(0xFFFFB300), '황금색!', '👑 반짝이는 왕관 색', '반짝반짝! 🌟', '👑'),
    'green+yellow': _MixResult(Color(0xFF9CCC65), '연두색!', '🐸 폴짝폴짝 개구리 색', '귀여워! 🌱', '🐸'),
    'blue+green': _MixResult(Color(0xFF00ACC1), '청록색!', '🐬 시원한 바다 돌고래 색', '시원해! 🌊', '🐬'),
    'orange+red': _MixResult(Color(0xFFE64A19), '다홍색!', '🚒 출동 소방차 색', '멋지다! 🔥', '🚒'),
    'purple+blue': _MixResult(Color(0xFF4527A0), '남보라색!', '🌌 반짝이는 밤하늘 색', '신비해! 🌌', '🌌'),
    'pink+purple': _MixResult(Color(0xFFAD1457), '자주색!', '🌺 향기로운 꽃다발 색', '향기나! 💜', '🌺'),
    'orange+green': _MixResult(Color(0xFF689F38), '황록색!', '🦎 카멜레온 친구 색', '특이해! 🦎', '🦎'),
    'pink+red': _MixResult(Color(0xFFF06292), '연빨강!', '🍓 달콤한 딸기 우유 색', '달콤해! 🍓', '🍓'),
    'pink+orange': _MixResult(Color(0xFFFF7043), '코랄색!', '🐠 바닷속 열대어 색', '예쁘다! 🐚', '🐠'),
    'red+white': _MixResult(Color(0xFFF48FB1), '분홍색!', '🌸 화사한 봄날 벚꽃 색', '귀여워! 🌸', '🌸'),
    'blue+white': _MixResult(Color(0xFF80D8FF), '하늘색!', '🐳 맑은 하늘 아기고래 색', '시원해! 🌤', '🐳'),
    'white+yellow': _MixResult(Color(0xFFFFF59D), '크림색!', '🍦 부드러운 아이스크림 색', '맛있겠다! 🍦', '🍦'),
    'green+white': _MixResult(Color(0xFFC8E6C9), '연초록!', '🌱 파릇파릇 새싹 색', '싱그러워! 🌿', '🌱'),
    'orange+white': _MixResult(Color(0xFFFFCCBC), '살구색!', '🍑 말랑말랑 복숭아 색', '달콤해! 🍑', '🍑'),
    'purple+white': _MixResult(Color(0xFFCE93D8), '라벤더!', '🦄 꿈꾸는 유니콘 색', '향기나! 💜', '🦄'),
    'pink+white': _MixResult(Color(0xFFFCE4EC), '솜사탕핑크!', '🍬 폭신폭신 솜사탕 색', '폭신폭신! 🍬', '🍬'),
    'black+red': _MixResult(Color(0xFFB71C1C), '진빨강!', '🌹 우아한 장미꽃 색', '멋져! 🌹', '🌹'),
    'black+blue': _MixResult(Color(0xFF0D47A1), '남색!', '🐳 깊은 바닷속 고래 색', '깊어보여! 🌊', '🐳'),
    'black+yellow': _MixResult(Color(0xFF827717), '올리브!', '🐢 엉금엉금 거북이 색', '신기해! 🐢', '🐢'),
    'black+green': _MixResult(Color(0xFF1B5E20), '진초록!', '🌲 커다란 소나무 숲 색', '울창해! 🌲', '🌲'),
    'black+orange': _MixResult(Color(0xFF6D4C41), '갈색!', '🐻 포근한 아기 곰돌이 색', '곰돌이 같아! 🐻', '🐻'),
    'black+purple': _MixResult(Color(0xFF4A148C), '진보라!', '🔮 마법사 구슬 색', '신비해! 🔮', '🔮'),
    'black+pink': _MixResult(Color(0xFFC2185B), '체리색!', '🍒 새콤달콤 체리 색', '맛있어! 🍒', '🍒'),
    'black+white': _MixResult(Color(0xFF9E9E9E), '회색!', '🐨 귀여운 코알라 색', '포슬포슬해! 🐨', '🐨'),
    'blue+red+yellow': _MixResult(Color(0xFF795548), '초코갈색!', '🍩 달콤한 초코 도넛 색', '와, 초코색이다! 🍩', '🍩'),
    'blue+white+yellow': _MixResult(Color(0xFF80CBC4), '민트색!', '🧁 상쾌한 민트 컵케이크 색', '상쾌해! 🧁', '🧁'),
    'blue+red+white': _MixResult(Color(0xFFCE93D8), '라벤더!', '🦄 신비한 유니콘 색', '예쁘다! 💜', '🦄'),
    'red+white+yellow': _MixResult(Color(0xFFFFCCBC), '살구색!', '🍑 달콤한 복숭아 색', '달콤해! 🍑', '🍑'),
    'blue+green+white': _MixResult(Color(0xFF80DEEA), '에메랄드!', '💎 반짝이는 보석 색', '반짝반짝! 💎', '💎'),
    'orange+red+white': _MixResult(Color(0xFFFF8A65), '연산호색!', '🦀 바닷가 꽃게 색', '귀여워! 🦀', '🦀'),
    'purple+pink+white': _MixResult(Color(0xFFF8BBD0), '로즈핑크!', '🎀 공주님 리본 색', '아름다워! 🎀', '🎀'),
    'black+orange+red': _MixResult(Color(0xFFBF360C), '벽돌색!', '🏠 튼튼한 벽돌집 색', '튼튼해! 🏠', '🏠'),
    'black+blue+green': _MixResult(Color(0xFF004D40), '짙은청록!', '🐊 정글 악어 색', '멋지다! 🐊', '🐊'),
    'black+red+white': _MixResult(Color(0xFFE91E63), '핫핑크!', '🦩 멋쟁이 홍학 색', '화려해! 🦩', '🦩'),
    'black+blue+white': _MixResult(Color(0xFF607D8B), '청회색!', '🐘 아기 코끼리 색', '반가워! 🐘', '🐘'),
    'black+green+yellow': _MixResult(Color(0xFF558B2F), '풀빛!', '🐛 꼬물꼬물 애벌레 색', '귀여워! 🐛', '🐛'),
  };

  // 모드 & 미션 상태 (기본: 3~4세가 좋아하는 🎯 마법 색칠 미션 모드)
  bool _isMissionMode = true;
  int _missionIndex = 0;
  int _starsCollected = 0;
  bool _missionCompleted = false;

  final List<String> _bowl = [];
  Color _bowlColor = Colors.white;
  Color _prevColor = Colors.white;
  Color _newDropColor = Colors.white;
  String _resultText = '';
  String _funText = '';
  String _exclaim = '';
  String _badgeEmoji = '🎨';
  bool _hasMix = false;
  bool _isSpecialMix = false;
  bool _isMixing = false;
  bool _showSpoon = false;

  _DropState? _drop;
  final List<_Sparkle> _sparkles = [];
  final List<_SplashParticle> _splashParticles = [];
  final List<_StirBubble> _stirBubbles = [];
  final _rng = Random();
  DateTime _lastStirSound = DateTime.now();

  late ConfettiController _confettiCtrl;
  late AnimationController _swirlCtrl;
  late AnimationController _popCtrl;
  late Animation<double> _popScale;
  late AnimationController _dropCtrl;
  late AnimationController _shakeCtrl;
  late Animation<Offset> _shakeAnim;
  late AnimationController _sparkleCtrl;
  late AnimationController _wobbleCtrl;
  late AnimationController _bgAnimCtrl;
  late AnimationController _mixCtrl;
  late AnimationController _splashCtrl;
  late AnimationController _swirlStrengthCtrl;
  late AnimationController _hintPulseCtrl;

  _ColorMission get _currentMission => _kMissions[_missionIndex % _kMissions.length];

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));
    _swirlCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _popScale = CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut);
    _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _dropCtrl.addListener(_onDropTick);
    _dropCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _drop = null);
        _triggerSplash();
        _triggerMixing();
      }
    });
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<Offset>([
      TweenSequenceItem(tween: Tween(begin: Offset.zero, end: const Offset(0.04, 0)), weight: 25),
      TweenSequenceItem(tween: Tween(begin: const Offset(0.04, 0), end: const Offset(-0.04, 0)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: const Offset(-0.04, 0), end: Offset.zero), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _sparkleCtrl.addListener(_updateSparkles);
    _wobbleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _mixCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    _mixCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() {
          _showSpoon = false;
          _isMixing = false;
        });
      }
    });
    _splashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _splashCtrl.addListener(_updateSplash);
    _splashCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _splashParticles.clear());
      }
    });
    _swirlStrengthCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _hintPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _swirlCtrl.dispose();
    _popCtrl.dispose();
    _dropCtrl.dispose();
    _shakeCtrl.dispose();
    _sparkleCtrl.dispose();
    _wobbleCtrl.dispose();
    _bgAnimCtrl.dispose();
    _mixCtrl.dispose();
    _splashCtrl.dispose();
    _swirlStrengthCtrl.dispose();
    _hintPulseCtrl.dispose();
    super.dispose();
  }

  void _onDropTick() {
    if (_drop != null) setState(() => _drop!.progress = _dropCtrl.value);
  }

  void _updateSparkles() {
    setState(() {
      for (final s in _sparkles) {
        s.x += cos(s.angle) * s.speed;
        s.y += sin(s.angle) * s.speed - 0.004;
        s.opacity -= 0.02;
      }
      _sparkles.removeWhere((s) => s.opacity <= 0);

      for (final b in _stirBubbles) {
        b.y += b.vy;
        b.opacity -= 0.025;
      }
      _stirBubbles.removeWhere((b) => b.opacity <= 0);
    });
  }

  void _addSparkles(Color color) {
    final colors = [color, Colors.white, Colors.yellow, color.withValues(alpha: 0.6)];
    for (int i = 0; i < 22; i++) {
      _sparkles.add(_Sparkle(
        x: 0.5 + (_rng.nextDouble() - 0.5) * 0.35,
        y: 0.52 + (_rng.nextDouble() - 0.5) * 0.25,
        size: 5 + _rng.nextDouble() * 9,
        opacity: 0.85 + _rng.nextDouble() * 0.15,
        angle: _rng.nextDouble() * 2 * pi,
        speed: 0.002 + _rng.nextDouble() * 0.005,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
    _sparkleCtrl.forward(from: 0);
  }

  void _triggerSplash() {
    if (!_hasMix) return;
    final color = _newDropColor;
    for (int i = 0; i < 16; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 0.004 + _rng.nextDouble() * 0.008;
      _splashParticles.add(_SplashParticle(
        x: 0.5,
        y: 0.45,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 0.006,
        size: 6 + _rng.nextDouble() * 10,
        opacity: 1.0,
        color: color,
      ));
    }
    _splashCtrl.forward(from: 0);
  }

  void _updateSplash() {
    setState(() {
      for (final p in _splashParticles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.001;
        p.opacity -= 0.03;
      }
      _splashParticles.removeWhere((p) => p.opacity <= 0);
    });
  }

  void _triggerMixing() {
    if (_bowl.length < 2) return;
    setState(() {
      _showSpoon = true;
      _isMixing = true;
    });
    AudioManager.instance.playCookStir();
    _mixCtrl.forward(from: 0);
    _swirlStrengthCtrl.forward(from: 0).then((_) => _swirlStrengthCtrl.reverse());
  }

  /// 아이가 손가락으로 물감 항아리를 직접 문질러 저을 때 반응
  void _onBowlFingerStir(Offset localPos, Size bowlSize) {
    if (_bowl.isEmpty) {
      // 빈 그릇을 터치하면 아래 물감을 눌러보라고 흔들어줌
      if (!_shakeCtrl.isAnimating) {
        _shakeCtrl.forward(from: 0);
        AudioManager.instance.playBoing();
      }
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastStirSound).inMilliseconds > 180) {
      _lastStirSound = now;
      HapticFeedback.selectionClick();
      AudioManager.instance.playPaintDrop();
      _wobbleCtrl.forward(from: 0).then((_) => _wobbleCtrl.reverse());
    }

    setState(() {
      _isMixing = true;
      _stirBubbles.add(_StirBubble(
        x: (localPos.dx / bowlSize.width).clamp(0.18, 0.82),
        y: (localPos.dy / bowlSize.height).clamp(0.18, 0.82),
        radius: 6 + _rng.nextDouble() * 10,
        opacity: 0.9,
        vy: -0.008 - _rng.nextDouble() * 0.01,
        color: Color.lerp(_bowlColor, Colors.white, 0.45)!,
      ));
    });
    if (!_sparkleCtrl.isAnimating) {
      _sparkleCtrl.forward(from: 0);
    }
  }

  void _addPaint(int index) {
    final paint = _kPaints[index];

    // 미션 클리어 직후에 다른 물감을 누르면 자동으로 다음 미션이거나 리셋
    if (_isMissionMode && _missionCompleted) {
      _nextMission();
      return;
    }

    if (_bowl.contains(paint.key)) {
      HapticFeedback.lightImpact();
      setState(() {
        _bowl.remove(paint.key);
        _prevColor = _bowlColor;
        _computeMix();
      });
      AudioManager.instance.playPaintDrop();
      return;
    }

    // 미션 모드에서는 레시피에 없는 물감을 눌렀을 때 귀여운 안내와 함께 필요한 물감이 반짝임
    if (_isMissionMode) {
      final needed = _currentMission.recipeKeys;
      if (!needed.contains(paint.key)) {
        HapticFeedback.lightImpact();
        _shakeCtrl.forward(from: 0);
        AudioManager.instance.playBoing();
        return;
      }
    }

    if (_bowl.length >= 5) {
      _shakeCtrl.forward(from: 0);
      AudioManager.instance.playBoing();
      return;
    }

    HapticFeedback.lightImpact();
    _prevColor = _bowlColor;
    _newDropColor = paint.rgb;
    setState(() {
      _bowl.add(paint.key);
      _computeMix();
      _drop = _DropState(
        color: paint.rgb,
        tubeIndex: index,
        totalTubes: _kPaints.length,
      );
    });
    _dropCtrl.forward(from: 0);
    _wobbleCtrl.forward(from: 0).then((_) => _wobbleCtrl.reverse());
    AudioManager.instance.playPaintDrop();
  }

  void _computeMix() {
    if (_bowl.isEmpty) {
      _bowlColor = Colors.white;
      _resultText = '';
      _funText = '';
      _exclaim = '';
      _badgeEmoji = '🎨';
      _hasMix = false;
      _isSpecialMix = false;
      _missionCompleted = false;
      return;
    }
    if (_bowl.length == 1) {
      final p = _kPaints.firstWhere((p) => p.key == _bowl.first);
      _bowlColor = p.rgb;
      _resultText = '${p.label} 물감!';
      _funText = '${p.emoji} 다른 색도 하나 더 넣어볼까요?';
      _exclaim = '';
      _badgeEmoji = p.emoji;
      _hasMix = true;
      _isSpecialMix = false;
      return;
    }

    final sortedKey = (List<String>.from(_bowl.toSet().toList())..sort()).join('+');
    final result = _kMixTable[sortedKey];
    if (result != null) {
      final wasNew = _resultText != result.name;
      _bowlColor = result.color;
      _resultText = result.name;
      _funText = result.funName;
      _exclaim = result.exclaim;
      _badgeEmoji = result.badgeEmoji;
      _hasMix = true;
      _isSpecialMix = true;
      if (wasNew && _bowl.length >= 2) {
        _popCtrl.forward(from: 0);
        _addSparkles(result.color);
      }
    } else {
      _bowlColor = _blendColors();
      _resultText = '무지개 마법색!';
      _funText = '🔮 세상에 하나뿐인 신비한 색이에요';
      _exclaim = '마법 같아! ✨';
      _badgeEmoji = '🔮';
      _hasMix = true;
      _isSpecialMix = true;
      _popCtrl.forward(from: 0);
      _addSparkles(_bowlColor);
    }

    // 미션 모드 정답 체크
    if (_isMissionMode && !_missionCompleted) {
      final targetSorted = (List<String>.from(_currentMission.recipeKeys)..sort()).join('+');
      if (sortedKey == targetSorted) {
        _missionCompleted = true;
        _starsCollected++;
        _confettiCtrl.play();
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            AudioManager.instance.playCookComplete();
          }
        });
      }
    }
  }

  Color _blendColors() {
    double r = 0, g = 0, b = 0;
    for (final key in _bowl) {
      final c = _kPaints.firstWhere((p) => p.key == key).rgb;
      r += c.r;
      g += c.g;
      b += c.b;
    }
    final n = _bowl.length;
    final darken = 0.85 + (0.15 / n);
    return Color.fromARGB(
      255,
      ((r / n) * darken * 255).round().clamp(0, 255),
      ((g / n) * darken * 255).round().clamp(0, 255),
      ((b / n) * darken * 255).round().clamp(0, 255),
    );
  }

  void _clearBowl() {
    setState(() {
      _bowl.clear();
      _bowlColor = Colors.white;
      _prevColor = Colors.white;
      _resultText = '';
      _funText = '';
      _exclaim = '';
      _badgeEmoji = '🎨';
      _hasMix = false;
      _isSpecialMix = false;
      _isMixing = false;
      _showSpoon = false;
      _missionCompleted = false;
      _sparkles.clear();
      _splashParticles.clear();
      _stirBubbles.clear();
    });
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
  }

  void _nextMission() {
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
    setState(() {
      _missionIndex = (_missionIndex + 1) % _kMissions.length;
      _bowl.clear();
      _bowlColor = Colors.white;
      _prevColor = Colors.white;
      _resultText = '';
      _funText = '';
      _exclaim = '';
      _badgeEmoji = '🎨';
      _hasMix = false;
      _isSpecialMix = false;
      _isMixing = false;
      _showSpoon = false;
      _missionCompleted = false;
      _sparkles.clear();
      _splashParticles.clear();
      _stirBubbles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(
                      const Color(0xFFFFF8E1),
                      _bowlColor.withValues(alpha: 0.32),
                      _bowl.isEmpty ? 0 : 0.55,
                    )!,
                    Color.lerp(
                      const Color(0xFFE3F2FD),
                      _bowlColor.withValues(alpha: 0.24),
                      _bowl.isEmpty ? 0 : 0.45,
                    )!,
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _bgAnimCtrl,
                builder: (context, child) => CustomPaint(
                  painter: _FloatingBlobsPainter(
                    _bgAnimCtrl.value,
                    _bowlColor,
                    _bowl.isEmpty,
                  ),
                  child: child,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 6),
                      _buildModeToggle(),
                      const SizedBox(height: 6),
                      _isMissionMode ? _buildMissionCard() : _buildFreeResultCard(),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bowlDim = min(
                              210.0,
                              min(constraints.maxWidth * 0.56, constraints.maxHeight * 0.88),
                            ).clamp(130.0, 220.0);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_sparkles.isNotEmpty)
                                  Positioned.fill(child: _buildSparkles(size)),
                                _buildInteractiveBowl(bowlDim),
                                if (_splashParticles.isNotEmpty)
                                  Positioned.fill(child: _buildSplash(size)),
                                if (_drop != null) _buildDrop(size),
                                if (_showSpoon) _buildSpoon(bowlDim),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPalette(),
                      const SizedBox(height: 8),
                      _buildBottomActionButton(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
            // 축하 폭죽
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiCtrl,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 28,
                colors: const [
                  Color(0xFFFF5252),
                  Color(0xFFFFD600),
                  Color(0xFF69F0AE),
                  Color(0xFF40C4FF),
                  Color(0xFFE040FB),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎨 마법 물감 실험실',
                  style: GoogleFonts.jua(
                    fontSize: 21,
                    color: const Color(0xFF4A148C),
                  ),
                ),
                Text(
                  _isMissionMode
                      ? '물감을 섞어 친구들을 색칠해요!'
                      : '원하는 물감을 마음껏 섞어봐요!',
                  style: GoogleFonts.jua(
                    fontSize: 12.5,
                    color: Colors.purple.shade400,
                  ),
                ),
              ],
            ),
          ),
          // 획득한 별 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD54F), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 4),
                Text(
                  '$_starsCollected',
                  style: GoogleFonts.jua(
                    fontSize: 17,
                    color: const Color(0xFFF57F17),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.purple.shade100, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isMissionMode) {
                    setState(() => _isMissionMode = true);
                    _clearBowl();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: _isMissionMode
                        ? const Color(0xFF8E24AA)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '🎯 마법 색칠 미션',
                      style: GoogleFonts.jua(
                        fontSize: 14,
                        color: _isMissionMode
                            ? Colors.white
                            : Colors.purple.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isMissionMode) {
                    setState(() => _isMissionMode = false);
                    _clearBowl();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: !_isMissionMode
                        ? const Color(0xFF00ACC1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '🧪 자유 물감 놀이',
                      style: GoogleFonts.jua(
                        fontSize: 14,
                        color: !_isMissionMode
                            ? Colors.white
                            : Colors.teal.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3~4세 아이들이 글씨를 몰라도 그림 레시피([빨강] + [노랑] = [🍊])를 보고 맞추는 미션 카드
  Widget _buildMissionCard() {
    final mission = _currentMission;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _missionCompleted
            ? mission.targetColor.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _missionCompleted
              ? mission.targetColor
              : const Color(0xFFCE93D8),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_missionCompleted ? mission.targetColor : Colors.purple)
                .withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 왼쪽: 색칠 전(흑백 실루엣) → 색칠 후(화사하게 변신한 캐릭터)
              AnimatedScale(
                scale: _missionCompleted ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _missionCompleted
                        ? mission.targetColor.withValues(alpha: 0.22)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _missionCompleted
                          ? mission.targetColor
                          : Colors.grey.shade300,
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: _missionCompleted
                        ? Text(
                            mission.targetEmoji,
                            style: const TextStyle(fontSize: 38),
                          )
                        : ColorFiltered(
                            colorFilter: const ColorFilter.matrix(<double>[
                              0.2126, 0.7152, 0.0722, 0, 80,
                              0.2126, 0.7152, 0.0722, 0, 80,
                              0.2126, 0.7152, 0.0722, 0, 80,
                              0,      0,      0,      0.55, 0,
                            ]),
                            child: Text(
                              mission.targetEmoji,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 오른쪽: 시각적 물감 공식 ([🍓빨강] + [🌟노랑] = [🍊])
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _missionCompleted
                          ? mission.cheerText
                          : '🦎 "${mission.targetName} 색을 만들어줘!"',
                      style: GoogleFonts.jua(
                        fontSize: 14.5,
                        color: const Color(0xFF4A148C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          for (int i = 0; i < mission.recipeKeys.length; i++) ...[
                            if (i > 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '+',
                                  style: GoogleFonts.jua(
                                    fontSize: 18,
                                    color: Colors.purple.shade400,
                                  ),
                                ),
                              ),
                            _buildRecipePill(mission.recipeKeys[i]),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '=',
                              style: GoogleFonts.jua(
                                fontSize: 18,
                                color: Colors.purple.shade400,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mission.targetColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: mission.targetColor.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  mission.targetEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _missionCompleted ? '성공! 🎉' : '?',
                                  style: GoogleFonts.jua(
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipePill(String paintKey) {
    final paint = _kPaints.firstWhere((p) => p.key == paintKey);
    final isAdded = _bowl.contains(paintKey);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isAdded
            ? paint.rgb
            : paint.rgb.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: paint.rgb,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(paint.emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 3),
          Text(
            isAdded ? '${paint.label} ✓' : paint.label,
            style: GoogleFonts.jua(
              fontSize: 12.5,
              color: isAdded
                  ? (paintKey == 'white' || paintKey == 'yellow'
                      ? Colors.black87
                      : Colors.white)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeResultCard() {
    return AnimatedBuilder(
      animation: _popScale,
      builder: (_, _) => Transform.scale(
        scale: _hasMix ? (0.9 + _popScale.value * 0.1) : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _hasMix
                ? _bowlColor.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hasMix ? _bowlColor : Colors.grey.shade300,
              width: 2.5,
            ),
          ),
          child: _hasMix
              ? Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bowlColor, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          _badgeEmoji,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _resultText,
                                style: GoogleFonts.jua(
                                  fontSize: 21,
                                  color: const Color(0xFF4A148C),
                                ),
                              ),
                              if (_exclaim.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _bowlColor.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _exclaim,
                                    style: GoogleFonts.jua(
                                      fontSize: 13,
                                      color: const Color(0xFF4A148C),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_funText.isNotEmpty)
                            Text(
                              _funText,
                              style: GoogleFonts.jua(
                                fontSize: 13.5,
                                color: Colors.purple.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('👇 ', style: TextStyle(fontSize: 20)),
                    Text(
                      '아래 물감을 톡톡 눌러 섞어봐요!',
                      style: GoogleFonts.jua(
                        fontSize: 16.5,
                        color: Colors.purple.shade300,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInteractiveBowl(double bowlDim) {
    final bowlSize = Size(bowlDim, bowlDim);
    return GestureDetector(
      onPanUpdate: (d) => _onBowlFingerStir(d.localPosition, bowlSize),
      onTapDown: (d) => _onBowlFingerStir(d.localPosition, bowlSize),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _swirlCtrl,
          _wobbleCtrl,
          _shakeCtrl,
          _mixCtrl,
          _swirlStrengthCtrl,
          _popScale,
        ]),
        builder: (_, _) => SlideTransition(
          position: _shakeAnim,
          child: SizedBox(
            width: bowlDim,
            height: bowlDim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: bowlSize,
                  painter: _BowlPainter(
                    liquidColor: _bowlColor,
                    prevColor: _prevColor,
                    swirlPhase: _swirlCtrl.value * 2 * pi,
                    hasMix: _hasMix,
                    isSpecialMix: _isSpecialMix,
                    wobble: _wobbleCtrl.value,
                    rng: _rng,
                    mixProgress: _mixCtrl.value,
                    isMixing: _isMixing,
                    swirlStrength: _swirlStrengthCtrl.value,
                    stirBubbles: _stirBubbles,
                  ),
                ),
                // 물감이 섞였을 때 그릇 한가운데서 통통 튀어오르는 직관적인 결과 이모지
                if (_hasMix && _bowl.length >= 2)
                  Transform.scale(
                    scale: 0.85 + _popScale.value * 0.25,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _bowlColor.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        _isMissionMode && _missionCompleted
                            ? _currentMission.targetEmoji
                            : _badgeEmoji,
                        style: TextStyle(fontSize: bowlDim * 0.24),
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

  Widget _buildSpoon(double bowlDim) {
    return AnimatedBuilder(
      animation: _mixCtrl,
      builder: (_, _) {
        final angle = _mixCtrl.value * 4 * pi;
        final orbitR = bowlDim * 0.25;
        final sx = cos(angle) * orbitR;
        final sy = sin(angle) * orbitR;
        double opacity = 1.0;
        if (_mixCtrl.value < 0.1) opacity = _mixCtrl.value / 0.1;
        if (_mixCtrl.value > 0.85) opacity = (1.0 - _mixCtrl.value) / 0.15;
        final spoonAngle = angle + pi / 2;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(sx, sy),
            child: Transform.rotate(
              angle: spoonAngle,
              child: _SpoonWidget(color: _bowlColor),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrop(Size size) {
    if (_drop == null) return const SizedBox.shrink();
    final drop = _drop!;
    final tubeCount = _kPaints.length;
    final tubeSpacing = 1.0 / (tubeCount + 1);
    final tubeX = tubeSpacing * (drop.tubeIndex + 1);
    const bowlX = 0.5;
    const bowlY = 0.50;
    final t = _dropCtrl.value;
    final cx = tubeX + (bowlX - tubeX) * t;
    final cy = 0.82 + (bowlY - 0.82) * t - sin(t * pi) * 0.12;
    final dropW = 32.0 - t * 10;
    final dropH = dropW * (1.2 + t * 0.4);
    final opacity = 1.0 - (t > 0.8 ? (t - 0.8) / 0.2 : 0);
    return Positioned(
      left: cx * size.width - dropW / 2,
      top: cy * size.height - dropH / 2,
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(dropW, dropH),
          painter: _TeardropPainter(color: drop.color),
        ),
      ),
    );
  }

  Widget _buildSparkles(Size size) =>
      CustomPaint(painter: _SparklePainter(sparkles: _sparkles, screenSize: size));

  Widget _buildSplash(Size size) =>
      CustomPaint(painter: _SplashPainter(particles: _splashParticles, screenSize: size));

  Widget _buildPalette() {
    Widget buildTube(int globalIndex) {
      final paint = _kPaints[globalIndex];
      final inBowl = _bowl.contains(paint.key);
      final isHinted = _isMissionMode &&
          !_missionCompleted &&
          _currentMission.recipeKeys.contains(paint.key) &&
          !inBowl;

      return AnimatedBuilder(
        animation: _hintPulseCtrl,
        builder: (context, child) {
          final pulseScale = isHinted ? (1.0 + _hintPulseCtrl.value * 0.10) : 1.0;
          return Transform.scale(
            scale: pulseScale,
            child: GestureDetector(
              onTap: () => _addPaint(globalIndex),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: inBowl ? 56 : 50,
                        height: inBowl ? 62 : 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              paint.rgb,
                              Color.lerp(paint.rgb, Colors.black, 0.18)!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isHinted
                                ? const Color(0xFFFFD600)
                                : (inBowl
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7)),
                            width: (inBowl || isHinted) ? 3.5 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isHinted
                                  ? const Color(0xFFFFD600).withValues(alpha: 0.65)
                                  : paint.rgb.withValues(alpha: inBowl ? 0.65 : 0.35),
                              blurRadius: (inBowl || isHinted) ? 14 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              paint.emoji,
                              style: TextStyle(fontSize: inBowl ? 24 : 21),
                            ),
                            if (inBowl)
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '✕',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isHinted)
                        Positioned(
                          top: -8,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('👆', style: TextStyle(fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    inBowl ? '빼기!' : paint.label,
                    style: GoogleFonts.jua(
                      fontSize: 11,
                      color: inBowl
                          ? Colors.redAccent
                          : (isHinted
                              ? const Color(0xFF6A1B9A)
                              : Colors.grey.shade700),
                      fontWeight:
                          (inBowl || isHinted) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => buildTube(i)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 24),
              ...List.generate(4, (i) => buildTube(i + 5)),
              const SizedBox(width: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton() {
    if (_isMissionMode && _missionCompleted) {
      return GestureDetector(
        onTap: _nextMission,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('✨', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '다음 친구 색칠하기! 👉',
                style: GoogleFonts.jua(fontSize: 19, color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _clearBowl,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🧹', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '깨끗이 씻기',
                      style: GoogleFonts.jua(fontSize: 17, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isMissionMode) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _nextMission,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '다른 그림 🔄',
                      style: GoogleFonts.jua(
                        fontSize: 15,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpoonWidget extends StatelessWidget {
  final Color color;
  const _SpoonWidget({required this.color});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(28, 52), painter: _SpoonPainter(liquidColor: color));
}

class _SpoonPainter extends CustomPainter {
  final Color liquidColor;
  _SpoonPainter({required this.liquidColor});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w / 2, h * 0.3),
      Offset(w / 2, h),
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final headRect =
        Rect.fromCenter(center: Offset(w / 2, h * 0.15), width: w * 0.9, height: h * 0.28);
    canvas.drawOval(headRect, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawOval(
      headRect,
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.16), width: w * 0.6, height: h * 0.18),
      Paint()..color = liquidColor.withValues(alpha: 0.6),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2 - w * 0.1, h * 0.1),
        width: w * 0.25,
        height: h * 0.08,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_SpoonPainter old) => old.liquidColor != liquidColor;
}

class _TeardropPainter extends CustomPainter {
  final Color color;
  _TeardropPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final path = Path();
    path.moveTo(cx, h);
    path.cubicTo(cx - w * 0.6, h * 0.7, cx - w * 0.6, h * 0.2, cx, 0);
    path.cubicTo(cx + w * 0.6, h * 0.2, cx + w * 0.6, h * 0.7, cx, h);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.7), color],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawCircle(
      Offset(cx - w * 0.15, h * 0.25),
      w * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_TeardropPainter old) => old.color != color;
}

class _BowlPainter extends CustomPainter {
  final Color liquidColor;
  final Color prevColor;
  final double swirlPhase;
  final bool hasMix;
  final bool isSpecialMix;
  final double wobble;
  final Random rng;
  final double mixProgress;
  final bool isMixing;
  final double swirlStrength;
  final List<_StirBubble> stirBubbles;

  _BowlPainter({
    required this.liquidColor,
    required this.prevColor,
    required this.swirlPhase,
    required this.hasMix,
    required this.isSpecialMix,
    required this.wobble,
    required this.rng,
    required this.mixProgress,
    required this.isMixing,
    required this.swirlStrength,
    required this.stirBubbles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;
    canvas.drawCircle(
      Offset(cx, cy + 10),
      r * 1.02,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      r + 8,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFECEFF1), Color(0xFFB0BEC5)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFFFAFAFA));
    if (hasMix) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.98)),
      );
      final extraWave = isMixing ? swirlStrength * 18 : 0.0;
      final waveAmp = 6.0 + wobble * 8 + extraWave;
      final liquidY = cy + r * 0.05;
      if (isMixing && mixProgress < 0.8) {
        final blendOpacity = (1.0 - mixProgress / 0.8).clamp(0.0, 1.0);
        _drawSwirlLayer(
          canvas,
          cx,
          cy,
          r,
          prevColor,
          swirlPhase,
          blendOpacity,
          waveAmp,
          liquidY,
        );
      }
      final liqPath = Path();
      liqPath.moveTo(cx - r, cy + r);
      liqPath.lineTo(cx + r, cy + r);
      liqPath.lineTo(cx + r, liquidY);
      for (double x = cx + r; x >= cx - r; x -= 2) {
        liqPath.lineTo(
          x,
          liquidY +
              sin((x / (r * 2) * 2 * pi) + swirlPhase) * waveAmp +
              sin((x / (r * 2) * pi) + swirlPhase * 1.5) * waveAmp * 0.5,
        );
      }
      liqPath.close();
      final mainOpacity = isMixing ? (0.5 + mixProgress * 0.5).clamp(0.0, 1.0) : 1.0;
      canvas.drawPath(
        liqPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              liquidColor.withValues(alpha: 0.8 * mainOpacity),
              liquidColor.withValues(alpha: mainOpacity),
            ],
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
      if (isSpecialMix || isMixing) {
        final swirlAlpha = isMixing ? (0.15 + swirlStrength * 0.35) : 0.18;
        final swirl = Paint()
          ..color = Colors.white.withValues(alpha: swirlAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isMixing ? 4.5 : 3;
        final swirlCount = isMixing ? 5 : 3;
        for (int i = 0; i < swirlCount; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(cx, cy + r * 0.05),
              radius: r * (0.15 + i * 0.14),
            ),
            swirlPhase * (isMixing ? 3 : 1) + i * (2 * pi / swirlCount),
            pi * 1.3,
            false,
            swirl,
          );
        }
      }
      final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
      final seedRng = Random(swirlPhase.toInt() * 7);
      final bubbleCount = isMixing ? 14 : 8;
      for (int i = 0; i < bubbleCount; i++) {
        final bx = cx + (seedRng.nextDouble() - 0.5) * r * 1.4;
        final by = cy + seedRng.nextDouble() * r * 0.5;
        final br = 2.0 + seedRng.nextDouble() * 5;
        if ((bx - cx) * (bx - cx) + (by - cy) * (by - cy) < r * r * 0.85) {
          canvas.drawCircle(Offset(bx, by), br, bPaint);
        }
      }
      // 아이가 손가락으로 저을 때 생기는 인터랙티브 버블
      for (final sb in stirBubbles) {
        canvas.drawCircle(
          Offset(sb.x * size.width, sb.y * size.height),
          sb.radius,
          Paint()..color = sb.color.withValues(alpha: sb.opacity.clamp(0.0, 1.0)),
        );
      }
      canvas.drawCircle(
        Offset(cx - r * 0.3, cy - r * 0.3),
        r * 0.15,
        Paint()..color = Colors.white.withValues(alpha: 0.35),
      );
      canvas.restore();
    } else {
      final tp = TextPainter(
        text: TextSpan(
          text: '🎨\n빤짝이는 물감을\n톡! 눌러봐요',
          style: GoogleFonts.jua(
            fontSize: size.width * 0.095,
            color: Colors.grey.shade400,
            height: 1.35,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(maxWidth: r * 1.6);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    if (isSpecialMix) {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = liquidColor.withValues(alpha: isMixing ? 0.6 : 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isMixing ? 12 : 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  void _drawSwirlLayer(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    Color color,
    double phase,
    double opacity,
    double waveAmp,
    double liquidY,
  ) {
    final path = Path();
    path.moveTo(cx - r, cy + r);
    path.lineTo(cx + r, cy + r);
    path.lineTo(cx + r, liquidY);
    for (double x = cx + r; x >= cx - r; x -= 2) {
      path.lineTo(
        x,
        liquidY +
            sin((x / (r * 2) * 2 * pi) + phase * 2.5) * waveAmp * 1.2 +
            sin((x / (r * 2) * pi) + phase * 1.8) * waveAmp * 0.6,
      );
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: opacity * 0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(covariant _BowlPainter old) => true;
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final Size screenSize;
  _SparklePainter({required this.sparkles, required this.screenSize});
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final paint = Paint()..color = s.color.withValues(alpha: s.opacity.clamp(0, 1));
      final px = s.x * screenSize.width;
      final py = s.y * screenSize.height;
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final r = i % 2 == 0 ? s.size : s.size * 0.4;
        final x = px + r * cos(angle);
        final y = py + r * sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => true;
}

class _SplashPainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final Size screenSize;
  _SplashPainter({required this.particles, required this.screenSize});
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(p.x * screenSize.width, p.y * screenSize.height),
          width: p.size,
          height: p.size * 1.3,
        ),
        Paint()..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) => true;
}

class _FloatingBlobsPainter extends CustomPainter {
  final double animValue;
  final Color baseColor;
  final bool isEmpty;
  _FloatingBlobsPainter(this.animValue, this.baseColor, this.isEmpty);

  @override
  void paint(Canvas canvas, Size size) {
    final blobColor = isEmpty ? const Color(0xFFB3E5FC) : baseColor;
    final paint = Paint()
      ..color = blobColor.withValues(alpha: isEmpty ? 0.4 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    _drawBlob(canvas, paint, size, 0.1, 0.8, 60, animValue, 1.0);
    _drawBlob(canvas, paint, size, 0.3, 0.4, 40, animValue, 1.4);
    _drawBlob(canvas, paint, size, 0.8, 0.9, 80, animValue, 0.8);
    _drawBlob(canvas, paint, size, 0.7, 0.2, 50, animValue, 1.2);
    _drawBlob(canvas, paint, size, 0.5, 0.6, 70, animValue, 1.1);
    final smallPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    _drawBlob(canvas, smallPaint, size, 0.2, 0.5, 20, animValue, 1.8);
    _drawBlob(canvas, smallPaint, size, 0.6, 0.1, 25, animValue, 1.6);
    _drawBlob(canvas, smallPaint, size, 0.9, 0.7, 30, animValue, 1.3);
  }

  void _drawBlob(
    Canvas canvas,
    Paint paint,
    Size size,
    double nx,
    double ny,
    double radius,
    double anim,
    double speed,
  ) {
    final progress = (ny + anim * speed) % 1.0;
    final y = (size.height + radius * 2) - progress * (size.height + radius * 4);
    final x = size.width * nx + sin(progress * pi * 4) * (radius * 0.8);
    final squeeze = sin(progress * pi * 8) * (radius * 0.1);
    canvas.drawPath(
      Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: radius * 2 + squeeze,
            height: radius * 2 - squeeze,
          ),
        ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x - radius * 0.3, y - radius * 0.3),
        width: radius * 0.5,
        height: radius * 0.5,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_FloatingBlobsPainter old) =>
      old.animValue != animValue || old.baseColor != baseColor || old.isEmpty != isEmpty;
}
