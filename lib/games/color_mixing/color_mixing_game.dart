import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

class _PaintColor {
  final String key;
  final String label;
  final String emoji;
  final Color rgb;
  const _PaintColor({required this.key, required this.label, required this.emoji, required this.rgb});
}

class _MixResult {
  final Color color;
  final String name;
  final String funName;
  final String exclaim;
  const _MixResult(this.color, this.name, this.funName, this.exclaim);
}

class _DropState {
  final Color color;
  final int tubeIndex;
  final int totalTubes;
  double progress;
  _DropState({required this.color, required this.tubeIndex, required this.totalTubes, this.progress = 0});
}

class _Sparkle {
  double x, y, size, opacity, angle, speed;
  Color color;
  _Sparkle({required this.x, required this.y, required this.size,
    required this.opacity, required this.angle, required this.speed, required this.color});
}

class _SplashParticle {
  double x, y, vx, vy, size, opacity;
  Color color;
  _SplashParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.size, required this.opacity,
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
    _PaintColor(key: 'red',    label: '빨강',  emoji: '🍓', rgb: Color(0xFFE53935)),
    _PaintColor(key: 'orange', label: '주황',  emoji: '🍊', rgb: Color(0xFFFF7043)),
    _PaintColor(key: 'yellow', label: '노랑',  emoji: '🌟', rgb: Color(0xFFFFD600)),
    _PaintColor(key: 'green',  label: '초록',  emoji: '🍀', rgb: Color(0xFF43A047)),
    _PaintColor(key: 'blue',   label: '파랑',  emoji: '🫐', rgb: Color(0xFF1E88E5)),
    _PaintColor(key: 'purple', label: '보라',  emoji: '🍇', rgb: Color(0xFF8E24AA)),
    _PaintColor(key: 'pink',   label: '분홍',  emoji: '🌸', rgb: Color(0xFFEC407A)),
    _PaintColor(key: 'white',  label: '흰색',  emoji: '☁️', rgb: Color(0xFFF5F5F5)),
    _PaintColor(key: 'black',  label: '검정',  emoji: '🖤', rgb: Color(0xFF424242)),
  ];

  static const Map<String, _MixResult> _kMixTable = {
    'red+yellow':        _MixResult(Color(0xFFFF6D00), '주황색!',     '🍊 오렌지 색이에요',       '와아~! 🤩'),
    'blue+yellow':       _MixResult(Color(0xFF2E7D32), '초록색!',     '🍀 풀밭 색이에요',         '신기해! ✨'),
    'blue+red':          _MixResult(Color(0xFF6A1B9A), '보라색!',     '🍇 포도 색이에요',         '예쁘다! 💜'),
    'orange+yellow':     _MixResult(Color(0xFFFFB300), '황금색!',     '✨ 황금 색이에요',         '반짝반짝! 🌟'),
    'green+yellow':      _MixResult(Color(0xFF9CCC65), '연두색!',     '🌿 새싹 색이에요',         '귀여워! 🌱'),
    'blue+green':        _MixResult(Color(0xFF00ACC1), '청록색!',     '🌊 바다 색이에요',         '시원해! 🌊'),
    'orange+red':        _MixResult(Color(0xFFE64A19), '다홍색!',     '🔥 불꽃 색이에요',         '뜨거워! 🔥'),
    'purple+blue':       _MixResult(Color(0xFF4527A0), '남보라색!',   '🪀 밤하늘 색이에요',       '신비해! 🌌'),
    'pink+purple':       _MixResult(Color(0xFFAD1457), '자주색!',     '💐 라일락 색이에요',       '향기나! 💜'),
    'orange+green':      _MixResult(Color(0xFF689F38), '황록색!',     '🦎 이구아나 색이에요',     '특이해! 🦎'),
    'pink+red':          _MixResult(Color(0xFFF06292), '연빨강!',     '🍓 딸기 색이에요',         '달콤해! 🍓'),
    'pink+orange':       _MixResult(Color(0xFFFF7043), '코랄색!',     '🐚 산호 색이에요',         '예쁘다! 🐚'),
    'red+white':         _MixResult(Color(0xFFF48FB1), '분홍색!',     '🌸 벚꽃 색이에요',         '귀여워! 🌸'),
    'blue+white':        _MixResult(Color(0xFF80D8FF), '하늘색!',     '🩵 맑은 하늘 색이에요',    '시원해! 🌤'),
    'white+yellow':      _MixResult(Color(0xFFFFF9C4), '크림색!',     '🍦 아이스크림 색이에요',   '맛있겠다! 🍦'),
    'green+white':       _MixResult(Color(0xFFC8E6C9), '연초록!',     '🌱 새잎 색이에요',         '싱그러워! 🌿'),
    'orange+white':      _MixResult(Color(0xFFFFCCBC), '살구색!',     '🍑 복숭아 색이에요',       '달콤해! 🍑'),
    'purple+white':      _MixResult(Color(0xFFCE93D8), '라벤더!',     '💐 라벤더 색이에요',       '향기나! 💜'),
    'pink+white':        _MixResult(Color(0xFFFCE4EC), '파스텔핑크!', '🩷 솜사탕 색이에요',       '폭신폭신! 🍬'),
    'black+red':         _MixResult(Color(0xFFB71C1C), '진빨강!',     '🌹 장미꽃 색이에요',       '멋져! 🌹'),
    'black+blue':        _MixResult(Color(0xFF0D47A1), '남색!',       '🌊 깊은 바다 색이에요',    '깊어보여! 🌊'),
    'black+yellow':      _MixResult(Color(0xFF827717), '올리브!',     '🫒 올리브 색이에요',       '신기해! 🫒'),
    'black+green':       _MixResult(Color(0xFF1B5E20), '진초록!',     '🌲 숲속 색이에요',         '울창해! 🌲'),
    'black+orange':      _MixResult(Color(0xFF6D4C41), '갈색!',       '🪵 나무 색이에요',         '나무 같아! 🪵'),
    'black+purple':      _MixResult(Color(0xFF4A148C), '진보라!',     '🔮 마법사 색이에요',       '신비해! 🔮'),
    'black+pink':        _MixResult(Color(0xFFC2185B), '딸기색!',     '🍓 딸기 색이에요',         '맛있어! 🍓'),
    'black+white':       _MixResult(Color(0xFF9E9E9E), '회색!',       '☁️ 구름 색이에요',         '포슬포슬해! ☁️'),
    'blue+red+yellow':   _MixResult(Color(0xFF795548), '갈색!',       '🪵 나무 색이에요',         '와, 갈색이다! 🌳'),
    'blue+white+yellow': _MixResult(Color(0xFF80CBC4), '민트색!',     '🌿 민트 색이에요',         '상쾌해! 🌿'),
    'blue+red+white':    _MixResult(Color(0xFFCE93D8), '라벤더!',     '💐 라벤더 색이에요',       '향기날 것 같아! 💜'),
    'red+white+yellow':  _MixResult(Color(0xFFFFCCBC), '살구색!',     '🍑 복숭아 색이에요',       '달콤해! 🍑'),
    'blue+green+white':  _MixResult(Color(0xFF80DEEA), '에메랄드!',   '💎 에메랄드 색이에요',     '반짝반짝! 💎'),
    'orange+red+white':  _MixResult(Color(0xFFFF8A65), '연산호색!',   '🐠 열대어 색이에요',       '예쁘다! 🐠'),
    'purple+pink+white': _MixResult(Color(0xFFF8BBD0), '로즈핑크!',   '🌹 장미 색이에요',         '아름다워! 🌹'),
    'black+orange+red':  _MixResult(Color(0xFFBF360C), '벽돌색!',     '🧱 벽돌 색이에요',         '튼튼해! 🧱'),
    'black+blue+green':  _MixResult(Color(0xFF004D40), '짙은청록!',   '🌊 심해 색이에요',         '깊어! 🌊'),
    'black+red+white':   _MixResult(Color(0xFFE91E63), '핫핑크!',     '💗 핫핑크 색이에요',       '화려해! 💗'),
    'black+blue+white':  _MixResult(Color(0xFF607D8B), '청회색!',     '🌫 안개 색이에요',         '신비해! 🌫'),
    'black+green+yellow':_MixResult(Color(0xFF558B2F), '풀빛!',       '🌿 이끼 색이에요',         '자연스러워! 🍃'),
  };

  final List<String> _bowl = [];
  Color _bowlColor    = Colors.white;
  Color _prevColor    = Colors.white;
  Color _newDropColor = Colors.white;
  String _resultText  = '';
  String _funText     = '';
  String _exclaim     = '';
  bool _hasMix        = false;
  bool _isSpecialMix  = false;
  bool _isMixing      = false;
  bool _showSpoon     = false;

  _DropState? _drop;
  final List<_Sparkle> _sparkles = [];
  final List<_SplashParticle> _splashParticles = [];
  final _rng = Random();

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

  @override
  void initState() {
    super.initState();
    _swirlCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _popCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _popScale = CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut);
    _dropCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
    _mixCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _mixCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() { _showSpoon = false; _isMixing = false; });
      }
    });
    _splashCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _splashCtrl.addListener(_updateSplash);
    _splashCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _splashParticles.clear());
    });
    _swirlStrengthCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _swirlCtrl.dispose(); _popCtrl.dispose(); _dropCtrl.dispose();
    _shakeCtrl.dispose(); _sparkleCtrl.dispose(); _wobbleCtrl.dispose();
    _bgAnimCtrl.dispose(); _mixCtrl.dispose(); _splashCtrl.dispose();
    _swirlStrengthCtrl.dispose();
    super.dispose();
  }

  void _onDropTick() {
    if (_drop != null) setState(() => _drop!.progress = _dropCtrl.value);
  }

  void _updateSparkles() {
    setState(() {
      for (final s in _sparkles) {
        s.x += cos(s.angle) * s.speed;
        s.y += sin(s.angle) * s.speed - 0.5;
        s.opacity -= 0.02;
      }
      _sparkles.removeWhere((s) => s.opacity <= 0);
    });
  }

  void _addSparkles(Color color) {
    final colors = [color, Colors.white, Colors.yellow, color.withValues(alpha: 0.5)];
    for (int i = 0; i < 20; i++) {
      _sparkles.add(_Sparkle(
        x: 0.5 + (_rng.nextDouble() - 0.5) * 0.3,
        y: 0.55 + (_rng.nextDouble() - 0.5) * 0.2,
        size: 4 + _rng.nextDouble() * 8,
        opacity: 0.8 + _rng.nextDouble() * 0.2,
        angle: _rng.nextDouble() * 2 * pi,
        speed: 0.002 + _rng.nextDouble() * 0.004,
        color: colors[_rng.nextInt(colors.length)],
      ));
    }
    _sparkleCtrl.forward(from: 0);
  }

  void _triggerSplash() {
    if (!_hasMix) return;
    final color = _newDropColor;
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 0.004 + _rng.nextDouble() * 0.008;
      _splashParticles.add(_SplashParticle(
        x: 0.5, y: 0.38,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 0.006,
        size: 5 + _rng.nextDouble() * 9,
        opacity: 1.0, color: color,
      ));
    }
    _splashCtrl.forward(from: 0);
  }

  void _updateSplash() {
    setState(() {
      for (final p in _splashParticles) {
        p.x += p.vx; p.y += p.vy;
        p.vy += 0.001;
        p.opacity -= 0.03;
      }
      _splashParticles.removeWhere((p) => p.opacity <= 0);
    });
  }

  void _triggerMixing() {
    if (_bowl.length < 2) return;
    setState(() { _showSpoon = true; _isMixing = true; });
    _mixCtrl.forward(from: 0);
    _swirlStrengthCtrl.forward(from: 0).then((_) => _swirlStrengthCtrl.reverse());
  }

  void _addPaint(int index) {
    final paint = _kPaints[index];
    if (_bowl.contains(paint.key)) {
      HapticFeedback.lightImpact();
      setState(() { _bowl.remove(paint.key); _prevColor = _bowlColor; _computeMix(); });
      AudioManager.instance.playPaintDrop();
      return;
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
      _drop = _DropState(color: paint.rgb, tubeIndex: index, totalTubes: _kPaints.length);
    });
    _dropCtrl.forward(from: 0);
    _wobbleCtrl.forward(from: 0).then((_) => _wobbleCtrl.reverse());
    AudioManager.instance.playPaintDrop();
  }

  void _computeMix() {
    if (_bowl.isEmpty) {
      _bowlColor = Colors.white; _resultText = ''; _funText = ''; _exclaim = '';
      _hasMix = false; _isSpecialMix = false; return;
    }
    if (_bowl.length == 1) {
      final p = _kPaints.firstWhere((p) => p.key == _bowl.first);
      _bowlColor = p.rgb; _resultText = '${p.label}이에요!';
      _funText = '${p.emoji} 순수한 ${p.label}이에요'; _exclaim = '';
      _hasMix = true; _isSpecialMix = false; return;
    }
    final sortedKey = (List<String>.from(_bowl.toSet().toList())..sort()).join('+');
    final result = _kMixTable[sortedKey];
    if (result != null) {
      final wasNew = _resultText != result.name;
      _bowlColor = result.color; _resultText = result.name;
      _funText = result.funName; _exclaim = result.exclaim;
      _hasMix = true; _isSpecialMix = true;
      if (wasNew && _bowl.length >= 2) { _popCtrl.forward(from: 0); _addSparkles(result.color); }
    } else {
      _bowlColor = _blendColors(); _resultText = '신비한 색이에요!';
      _funText = '🔮 새로운 색이 탄생했어요'; _exclaim = '마법 같아! ✨';
      _hasMix = true; _isSpecialMix = true;
      _popCtrl.forward(from: 0); _addSparkles(_bowlColor);
    }
  }

  Color _blendColors() {
    double r = 0, g = 0, b = 0;
    for (final key in _bowl) {
      final c = _kPaints.firstWhere((p) => p.key == key).rgb;
      r += c.r; g += c.g; b += c.b;
    }
    final n = _bowl.length;
    final darken = 0.85 + (0.15 / n);
    return Color.fromARGB(255,
      ((r / n) * darken * 255).round().clamp(0, 255),
      ((g / n) * darken * 255).round().clamp(0, 255),
      ((b / n) * darken * 255).round().clamp(0, 255));
  }

  void _clearBowl() {
    setState(() {
      _bowl.clear(); _bowlColor = Colors.white; _prevColor = Colors.white;
      _resultText = ''; _funText = ''; _exclaim = '';
      _hasMix = false; _isSpecialMix = false; _isMixing = false; _showSpoon = false;
      _sparkles.clear(); _splashParticles.clear();
    });
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                Color.lerp(const Color(0xFFFFF8E1), _bowlColor.withValues(alpha: 0.3), _bowl.isEmpty ? 0 : 0.5)!,
                Color.lerp(const Color(0xFFE3F2FD), _bowlColor.withValues(alpha: 0.2), _bowl.isEmpty ? 0 : 0.4)!,
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) => CustomPaint(
              painter: _FloatingBlobsPainter(_bgAnimCtrl.value, _bowlColor, _bowl.isEmpty),
              child: child,
            ),
            child: SafeArea(child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 6),
              _buildResultLabel(),
              const SizedBox(height: 8),
              Expanded(child: Stack(alignment: Alignment.center, children: [
                if (_sparkles.isNotEmpty) Positioned.fill(child: _buildSparkles(size)),
                _buildBowl(),
                if (_splashParticles.isNotEmpty) Positioned.fill(child: _buildSplash(size)),
                if (_drop != null) _buildDrop(size),
                if (_showSpoon) _buildSpoon(),
              ])),
              const SizedBox(height: 12),
              _buildPalette(),
              const SizedBox(height: 12),
              _buildClearButton(),
              const SizedBox(height: 16),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () { AudioManager.instance.playClick(); Navigator.pop(context); },
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF6A1B9A)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('🎨 마법 물감 놀이', style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFF4A148C))),
          Text('물감을 섞어봐요!', style: GoogleFonts.jua(fontSize: 13, color: Colors.purple.shade300)),
        ])),
        if (_bowl.isNotEmpty)
          Row(mainAxisSize: MainAxisSize.min, children: _bowl.map((key) {
            final p = _kPaints.firstWhere((p) => p.key == key);
            return Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(color: p.rgb, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: p.rgb.withValues(alpha: 0.4), blurRadius: 6)]),
            );
          }).toList()),
      ]),
    );
  }

  Widget _buildResultLabel() {
    return AnimatedBuilder(
      animation: _popScale,
      builder: (_, __) => Transform.scale(
        scale: _hasMix ? (0.85 + _popScale.value * 0.15) : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: _hasMix ? _bowlColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _hasMix ? _bowlColor : Colors.grey.shade200, width: 2.5),
            boxShadow: _hasMix ? [BoxShadow(color: _bowlColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))] : [],
          ),
          child: _hasMix
              ? Column(children: [
                  Text(_resultText, style: GoogleFonts.jua(fontSize: 26, color: const Color(0xFF4A148C),
                    shadows: const [Shadow(color: Colors.white, blurRadius: 4)])),
                  if (_funText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_funText, style: GoogleFonts.jua(fontSize: 15, color: Colors.purple.shade400)),
                  ],
                  if (_exclaim.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(color: _bowlColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(_exclaim, style: GoogleFonts.jua(fontSize: 20, color: const Color(0xFF4A148C))),
                    ),
                  ],
                ])
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('👇 ', style: TextStyle(fontSize: 22)),
                  Text('아래 물감을 눌러봐요!', style: GoogleFonts.jua(fontSize: 18, color: Colors.grey.shade400)),
                ]),
        ),
      ),
    );
  }

  Widget _buildBowl() {
    return AnimatedBuilder(
      animation: Listenable.merge([_swirlCtrl, _wobbleCtrl, _shakeCtrl, _mixCtrl, _swirlStrengthCtrl]),
      builder: (_, __) => SlideTransition(
        position: _shakeAnim,
        child: SizedBox(width: 240, height: 240,
          child: CustomPaint(painter: _BowlPainter(
            liquidColor: _bowlColor, prevColor: _prevColor,
            swirlPhase: _swirlCtrl.value * 2 * pi,
            hasMix: _hasMix, isSpecialMix: _isSpecialMix, wobble: _wobbleCtrl.value, rng: _rng,
            mixProgress: _mixCtrl.value, isMixing: _isMixing, swirlStrength: _swirlStrengthCtrl.value,
          ))),
      ),
    );
  }

  Widget _buildSpoon() {
    return AnimatedBuilder(
      animation: _mixCtrl,
      builder: (_, __) {
        final angle = _mixCtrl.value * 4 * pi;
        const orbitR = 62.0;
        final sx = cos(angle) * orbitR;
        final sy = sin(angle) * orbitR;
        double opacity = 1.0;
        if (_mixCtrl.value < 0.1) opacity = _mixCtrl.value / 0.1;
        if (_mixCtrl.value > 0.85) opacity = (1.0 - _mixCtrl.value) / 0.15;
        final spoonAngle = angle + pi / 2;
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(sx, sy),
            child: Transform.rotate(angle: spoonAngle,
              child: _SpoonWidget(color: _bowlColor))),
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
    const bowlY = 0.52;
    final t = _dropCtrl.value;
    final cx = tubeX + (bowlX - tubeX) * t;
    final cy = 0.85 + (bowlY + 0.02 - 0.85) * t - sin(t * pi) * 0.12;
    final dropW = 34.0 - t * 12;
    final dropH = dropW * (1.2 + t * 0.4);
    final opacity = 1.0 - (t > 0.8 ? (t - 0.8) / 0.2 : 0);
    return Positioned(
      left: cx * size.width - dropW / 2,
      top: cy * size.height - dropH / 2,
      child: Opacity(opacity: opacity,
        child: CustomPaint(size: Size(dropW, dropH), painter: _TeardropPainter(color: drop.color))),
    );
  }

  Widget _buildSparkles(Size size) => CustomPaint(painter: _SparklePainter(sparkles: _sparkles, screenSize: size));
  Widget _buildSplash(Size size) => CustomPaint(painter: _SplashPainter(particles: _splashParticles, screenSize: size));

  Widget _buildPalette() {
    Widget buildTube(int globalIndex) {
      final paint = _kPaints[globalIndex];
      final inBowl = _bowl.contains(paint.key);
      return GestureDetector(
        onTap: () => _addPaint(globalIndex),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: inBowl ? 58 : 52, height: inBowl ? 68 : 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [paint.rgb, Color.lerp(paint.rgb, Colors.black, 0.2)!]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: inBowl ? Colors.white : Colors.white.withValues(alpha: 0.6), width: inBowl ? 3.5 : 2),
              boxShadow: [BoxShadow(color: paint.rgb.withValues(alpha: inBowl ? 0.7 : 0.35), blurRadius: inBowl ? 18 : 6, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(paint.emoji, style: TextStyle(fontSize: inBowl ? 26 : 22)),
              if (inBowl) Container(
                width: 20, height: 20, margin: const EdgeInsets.only(top: 2),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: const Center(child: Text('✕', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Text(inBowl ? '빼기!' : paint.label,
            style: GoogleFonts.jua(fontSize: 11, color: inBowl ? Colors.redAccent : Colors.grey.shade600,
              fontWeight: inBowl ? FontWeight.bold : FontWeight.normal)),
        ])),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (i) => buildTube(i))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const SizedBox(width: 30),
          ...List.generate(4, (i) => buildTube(i + 5)),
          const SizedBox(width: 30),
        ]),
      ])),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: _clearBowl,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40), height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)]),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🧹', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text('깨끗이 씻어요!', style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _SpoonWidget extends StatelessWidget {
  final Color color;
  const _SpoonWidget({required this.color});
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(28, 52), painter: _SpoonPainter(liquidColor: color));
}

class _SpoonPainter extends CustomPainter {
  final Color liquidColor;
  _SpoonPainter({required this.liquidColor});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawLine(Offset(w / 2, h * 0.3), Offset(w / 2, h),
      Paint()..color = const Color(0xFFBDBDBD)..strokeWidth = 5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    final headRect = Rect.fromCenter(center: Offset(w / 2, h * 0.15), width: w * 0.9, height: h * 0.28);
    canvas.drawOval(headRect, Paint()..color = const Color(0xFFE0E0E0));
    canvas.drawOval(headRect, Paint()..color = const Color(0xFF9E9E9E)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, h * 0.16), width: w * 0.6, height: h * 0.18),
      Paint()..color = liquidColor.withValues(alpha: 0.6));
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2 - w * 0.1, h * 0.1), width: w * 0.25, height: h * 0.08),
      Paint()..color = Colors.white.withValues(alpha: 0.7));
  }
  @override
  bool shouldRepaint(_SpoonPainter old) => old.liquidColor != liquidColor;
}

class _TeardropPainter extends CustomPainter {
  final Color color;
  _TeardropPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height; final cx = w / 2;
    final path = Path();
    path.moveTo(cx, h);
    path.cubicTo(cx - w * 0.6, h * 0.7, cx - w * 0.6, h * 0.2, cx, 0);
    path.cubicTo(cx + w * 0.6, h * 0.2, cx + w * 0.6, h * 0.7, cx, h);
    canvas.drawPath(path, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.7), color]).createShader(Rect.fromLTWH(0, 0, w, h)));
    canvas.drawCircle(Offset(cx - w * 0.15, h * 0.25), w * 0.12, Paint()..color = Colors.white.withValues(alpha: 0.5));
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

  _BowlPainter({
    required this.liquidColor, required this.prevColor, required this.swirlPhase,
    required this.hasMix, required this.isSpecialMix, required this.wobble, required this.rng,
    required this.mixProgress, required this.isMixing, required this.swirlStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; final cy = size.height / 2; final r = size.width * 0.44;
    canvas.drawCircle(Offset(cx, cy + 10), r * 1.02,
      Paint()..color = Colors.black.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawCircle(Offset(cx, cy), r + 8, Paint()
      ..shader = RadialGradient(colors: [const Color(0xFFECEFF1), const Color(0xFFB0BEC5)])
        .createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFFFAFAFA));
    if (hasMix) {
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.98)));
      final extraWave = isMixing ? swirlStrength * 18 : 0.0;
      final waveAmp = 6.0 + wobble * 8 + extraWave;
      final liquidY = cy + r * 0.05;
      if (isMixing && mixProgress < 0.8) {
        final blendOpacity = (1.0 - mixProgress / 0.8).clamp(0.0, 1.0);
        _drawSwirlLayer(canvas, cx, cy, r, prevColor, swirlPhase, blendOpacity, waveAmp, liquidY);
      }
      final liqPath = Path();
      liqPath.moveTo(cx - r, cy + r); liqPath.lineTo(cx + r, cy + r); liqPath.lineTo(cx + r, liquidY);
      for (double x = cx + r; x >= cx - r; x -= 2) {
        liqPath.lineTo(x, liquidY + sin((x / (r * 2) * 2 * pi) + swirlPhase) * waveAmp
                                  + sin((x / (r * 2) * pi) + swirlPhase * 1.5) * waveAmp * 0.5);
      }
      liqPath.close();
      final mainOpacity = isMixing ? (0.5 + mixProgress * 0.5).clamp(0.0, 1.0) : 1.0;
      canvas.drawPath(liqPath, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          liquidColor.withValues(alpha: 0.8 * mainOpacity),
          liquidColor.withValues(alpha: mainOpacity),
        ]).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
      if (isSpecialMix || isMixing) {
        final swirlAlpha = isMixing ? (0.15 + swirlStrength * 0.35) : 0.18;
        final swirl = Paint()..color = Colors.white.withValues(alpha: swirlAlpha)
          ..style = PaintingStyle.stroke..strokeWidth = isMixing ? 4.5 : 3;
        final swirlCount = isMixing ? 5 : 3;
        for (int i = 0; i < swirlCount; i++) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(cx, cy + r * 0.05), radius: r * (0.15 + i * 0.14)),
            swirlPhase * (isMixing ? 3 : 1) + i * (2 * pi / swirlCount), pi * 1.3, false, swirl);
        }
        if (isMixing && mixProgress < 0.6) {
          final streakPaint = Paint()
            ..color = prevColor.withValues(alpha: (0.5 - mixProgress * 0.8).clamp(0.0, 0.5))
            ..style = PaintingStyle.stroke..strokeWidth = 6;
          for (int i = 0; i < 3; i++) {
            canvas.drawArc(
              Rect.fromCircle(center: Offset(cx, cy + r * 0.05), radius: r * (0.2 + i * 0.2)),
              swirlPhase * 2 + i * (2 * pi / 3), pi * 0.8, false, streakPaint);
          }
        }
      }
      final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
      final seedRng = Random(swirlPhase.toInt() * 7);
      final bubbleCount = isMixing ? 14 : 8;
      for (int i = 0; i < bubbleCount; i++) {
        final bx = cx + (seedRng.nextDouble() - 0.5) * r * 1.4;
        final by = cy + seedRng.nextDouble() * r * 0.5;
        final br = 2.0 + seedRng.nextDouble() * 5;
        if ((bx - cx) * (bx - cx) + (by - cy) * (by - cy) < r * r * 0.85) canvas.drawCircle(Offset(bx, by), br, bPaint);
      }
      canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3), r * 0.15, Paint()..color = Colors.white.withValues(alpha: 0.35));
      canvas.restore();
    } else {
      final tp = TextPainter(
        text: TextSpan(text: '🎨\n물감을\n넣어봐요!', style: GoogleFonts.jua(fontSize: 20, color: Colors.grey.shade400, height: 1.4)),
        textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout(maxWidth: r * 1.6);
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.stroke..strokeWidth = 3);
    if (isSpecialMix) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()
        ..color = liquidColor.withValues(alpha: isMixing ? 0.6 : 0.4)
        ..style = PaintingStyle.stroke..strokeWidth = isMixing ? 12 : 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
    }
  }

  void _drawSwirlLayer(Canvas canvas, double cx, double cy, double r, Color color,
      double phase, double opacity, double waveAmp, double liquidY) {
    final path = Path();
    path.moveTo(cx - r, cy + r); path.lineTo(cx + r, cy + r); path.lineTo(cx + r, liquidY);
    for (double x = cx + r; x >= cx - r; x -= 2) {
      path.lineTo(x, liquidY + sin((x / (r * 2) * 2 * pi) + phase * 2.5) * waveAmp * 1.2
                              + sin((x / (r * 2) * pi) + phase * 1.8) * waveAmp * 0.6);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity * 0.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(covariant _BowlPainter old) =>
      old.swirlPhase != swirlPhase || old.liquidColor != liquidColor || old.hasMix != hasMix ||
      old.isSpecialMix != isSpecialMix || old.wobble != wobble || old.mixProgress != mixProgress ||
      old.isMixing != isMixing || old.swirlStrength != swirlStrength || old.prevColor != prevColor;
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final Size screenSize;
  _SparklePainter({required this.sparkles, required this.screenSize});
  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final paint = Paint()..color = s.color.withValues(alpha: s.opacity.clamp(0, 1));
      final px = s.x * screenSize.width; final py = s.y * screenSize.height;
      final path = Path();
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final r = i % 2 == 0 ? s.size : s.size * 0.4;
        final x = px + r * cos(angle); final y = py + r * sin(angle);
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
        Rect.fromCenter(center: Offset(p.x * screenSize.width, p.y * screenSize.height), width: p.size, height: p.size * 1.3),
        Paint()..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0)));
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
    final smallPaint = Paint()..color = Colors.white.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    _drawBlob(canvas, smallPaint, size, 0.2, 0.5, 20, animValue, 1.8);
    _drawBlob(canvas, smallPaint, size, 0.6, 0.1, 25, animValue, 1.6);
    _drawBlob(canvas, smallPaint, size, 0.9, 0.7, 30, animValue, 1.3);
  }

  void _drawBlob(Canvas canvas, Paint paint, Size size, double nx, double ny, double radius, double anim, double speed) {
    final progress = (ny + anim * speed) % 1.0;
    final y = (size.height + radius * 2) - progress * (size.height + radius * 4);
    final x = size.width * nx + sin(progress * pi * 4) * (radius * 0.8);
    final squeeze = sin(progress * pi * 8) * (radius * 0.1);
    canvas.drawPath(Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: radius * 2 + squeeze, height: radius * 2 - squeeze)), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x - radius * 0.3, y - radius * 0.3), width: radius * 0.5, height: radius * 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  @override
  bool shouldRepaint(_FloatingBlobsPainter old) =>
      old.animValue != animValue || old.baseColor != baseColor || old.isEmpty != isEmpty;
}
