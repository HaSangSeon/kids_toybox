import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _Vehicle {
  final String id;
  final String label;
  final String emoji;
  final Color bodyColor;
  final Color roofColor;
  final Color wheelColor;

  const _Vehicle({
    required this.id,
    required this.label,
    required this.emoji,
    required this.bodyColor,
    required this.roofColor,
    required this.wheelColor,
  });
}

const List<_Vehicle> _kVehicles = [
  _Vehicle(id: 'car',        label: '노랑 빵빵이', emoji: '🚗', bodyColor: Color(0xFFFFCC02), roofColor: Color(0xFFFF9F1C), wheelColor: Color(0xFF333333)),
  _Vehicle(id: 'police',     label: '멋진 경찰차', emoji: '🚓', bodyColor: Color(0xFF4FC3F7), roofColor: Color(0xFF0277BD), wheelColor: Color(0xFF333333)),
  _Vehicle(id: 'fire',       label: '용감 소방차', emoji: '🚒', bodyColor: Color(0xFFEF5350), roofColor: Color(0xFFB71C1C), wheelColor: Color(0xFF333333)),
  _Vehicle(id: 'ambulance',  label: '삐뽀 구급차', emoji: '🚑', bodyColor: Color(0xFFF5F5F5), roofColor: Color(0xFFB0BEC5), wheelColor: Color(0xFF333333)),
  _Vehicle(id: 'bus',        label: '파란 버스',   emoji: '🚌', bodyColor: Color(0xFF42A5F5), roofColor: Color(0xFF1565C0), wheelColor: Color(0xFF333333)),
  _Vehicle(id: 'racing',     label: '레이싱카',    emoji: '🏎️', bodyColor: Color(0xFFE53935), roofColor: Color(0xFFB71C1C), wheelColor: Color(0xFF111111)),
];

// 세차 순서: 차 선택 -> 매연 뿜으며 입장 -> 물로 먼지 씻기 -> 비누칠 -> 물로 헹구기 -> 수건 닦기 -> 스티커 -> 출발
enum _WashStep { selectCar, driveIn, water, soap, rinse, dry, sticker }

class _Droplet {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;
  _Droplet({required this.pos, required this.vel, required this.radius, required this.life, required this.color});
}

class _Bubble {
  Offset pos;
  double radius;
  double life;
  _Bubble({required this.pos, required this.radius, required this.life});
}

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  Color color;
  _Spark({required this.pos, required this.vel, required this.life, required this.color});
}

class _Smoke {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  _Smoke({required this.pos, required this.vel, required this.radius, required this.life});
}

class _Sticker {
  final String emoji;
  final Offset rel;
  _Sticker(this.emoji, this.rel);
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN GAME
// ═══════════════════════════════════════════════════════════════════════════════

class CarWashGame extends StatefulWidget {
  const CarWashGame({super.key});

  @override
  State<CarWashGame> createState() => _CarWashGameState();
}

class _CarWashGameState extends State<CarWashGame> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _WashStep _step = _WashStep.selectCar;
  _Vehicle _car = _kVehicles[0];

  // Dirt / soap / shine coverage grids (15×15 = 225 cells, balanced size)
  static const int _gridN = 15;
  static const int _gridSize = _gridN * _gridN;
  final List<double> _dirtGrid   = List.filled(_gridSize, 0.0); // 1=dirty 0=clean
  final List<double> _soapGrid   = List.filled(_gridSize, 0.0); // 0=bare  1=soapy
  final List<double> _rinseGrid  = List.filled(_gridSize, 0.0); // 0=soapy 1=rinsed
  final List<double> _dryGrid    = List.filled(_gridSize, 0.0); // 0=wet   1=dry

  // Car body strictly matches a generic car emoji profile (roof + body)
  // This ensures no "invisible" dirt is tracked in transparent corners
  bool _isCarCell(int x, int y) {
    final rx = (x + 0.5) / _gridN;
    final ry = (y + 0.5) / _gridN;
    
    final isRoof = rx >= 0.35 && rx <= 0.65 && ry >= 0.20 && ry < 0.50;
    final isBody = rx >= 0.20 && rx <= 0.80 && ry >= 0.50 && ry <= 0.85;
    
    return isRoof || isBody;
  }

  late int _cachedCarCellCount;

  void _cacheCarCellCount() {
    int count = 0;
    for (int y = 0; y < _gridN; y++) {
      for (int x = 0; x < _gridN; x++) {
        if (_isCarCell(x, y)) count++;
      }
    }
    _cachedCarCellCount = count > 0 ? count : 1;
  }

  void _initGrids() {
    for (int y = 0; y < _gridN; y++) {
      for (int x = 0; x < _gridN; x++) {
        final idx = y * _gridN + x;
        final inside = _isCarCell(x, y);
        _dirtGrid[idx] = inside ? 1.0 : 0.0;
        _soapGrid[idx] = 0.0;
        _rinseGrid[idx] = 0.0;
        _dryGrid[idx] = 0.0;
      }
    }
  }

  double _gridProgress(List<double> grid, bool invert) {
    double sum = 0;
    for (int y = 0; y < _gridN; y++) {
      for (int x = 0; x < _gridN; x++) {
        if (!_isCarCell(x, y)) continue;
        sum += grid[y * _gridN + x];
      }
    }
    final ratio = sum / _cachedCarCellCount;
    return (invert ? (1.0 - ratio) : ratio).clamp(0.0, 1.0);
  }

  double get _waterProgress => _gridProgress(_dirtGrid, true);
  double get _soapProgress  => _gridProgress(_soapGrid, false);
  double get _rinseProgress => _gridProgress(_rinseGrid, false);
  double get _dryProgress   => _gridProgress(_dryGrid, false);

  // Particles
  final List<_Droplet> _drops   = [];
  final List<_Bubble>  _bubbles = [];
  final List<_Spark>   _sparks  = [];
  final List<_Smoke>   _smokes  = [];
  final List<_Spark>   _confetti = [];

  // Stickers
  final List<_Sticker> _stickers = [];
  int _selectedStickerIdx = 0;
  static const List<String> _stickerEmojis = [
    '⭐', '💙', '🌸', '⚡', '🐾', '🎀', '🌈', '🔥', '🍭', '🎉',
  ];

  // Animations
  late AnimationController _ticker;
  late AnimationController _carDriveCtrl;   // Drive-out
  late AnimationController _driveInCtrl;    // Drive-in entrance
  late AnimationController _stepBannerCtrl;
  late Animation<double>   _stepBannerAnim;

  final Random _rng = Random();

  double _carDriveX = 0;      // Drive-out progress (0..1)
  double _carDriveInX = 1.0;  // Drive-in progress (1..0)
  bool _driveComplete = false;
  bool _stepComplete = false;

  // Step banner text
  String _bannerText = '';
  Color  _bannerColor = KidsTheme.orange;

  @override
  void initState() {
    super.initState();
    _cacheCarCellCount();
    _initGrids();

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_tick)..repeat();

    _carDriveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
      setState(() {
        _carDriveX = _carDriveCtrl.value;
      });
    });

    _driveInCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
      setState(() {
        final t = Curves.easeOutCubic.transform(_driveInCtrl.value);
        _carDriveInX = 1.0 - t;
      });
    });

    _stepBannerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _stepBannerAnim = CurvedAnimation(parent: _stepBannerCtrl, curve: Curves.elasticOut);
  }

  void _tick() {
    if (!mounted) return;
    final dt = 1 / 60;
    setState(() {
      // Spawn exhaust smoke during drive-in
      if (_step == _WashStep.driveIn && _driveInCtrl.isAnimating) {
        _smokes.add(_Smoke(
          pos: Offset(_rng.nextDouble() * 12 - 6, _rng.nextDouble() * 12 - 6),
          vel: Offset((_rng.nextDouble() * 3 + 2), -(_rng.nextDouble() * 1.5 + 0.5)),
          radius: _rng.nextDouble() * 8 + 6,
          life: 1.0,
        ));
      }

      // Update smoke
      for (int i = _smokes.length - 1; i >= 0; i--) {
        final s = _smokes[i];
        s.pos += s.vel;
        s.radius += 0.3;
        s.life -= dt * 1.4;
        if (s.life <= 0) _smokes.removeAt(i);
      }

      // Update drops
      for (int i = _drops.length - 1; i >= 0; i--) {
        final d = _drops[i];
        d.pos += d.vel;
        d.vel = Offset(d.vel.dx * 0.95, d.vel.dy + 0.3);
        d.life -= dt * 1.6;
        if (d.life <= 0) _drops.removeAt(i);
      }

      // Update bubbles
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final b = _bubbles[i];
        b.life -= dt * 0.8;
        b.pos += Offset((_rng.nextDouble() - 0.5) * 0.5, -0.3);
        if (b.life <= 0) _bubbles.removeAt(i);
      }

      // Update sparks
      for (int i = _sparks.length - 1; i >= 0; i--) {
        final s = _sparks[i];
        s.pos += s.vel;
        s.vel *= 0.96;
        s.life -= dt * 1.8;
        if (s.life <= 0) _sparks.removeAt(i);
      }

      // Update confetti
      for (int i = _confetti.length - 1; i >= 0; i--) {
        final c = _confetti[i];
        c.pos += c.vel;
        c.vel = Offset(c.vel.dx * 0.98, c.vel.dy + 0.15);
        c.life -= dt * 0.5;
        if (c.life <= 0) _confetti.removeAt(i);
      }
    });
  }

  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _ticker.dispose();
    _carDriveCtrl.dispose();
    _driveInCtrl.dispose();
    _stepBannerCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Offset _localToRel(Offset localPos, Size carSize) {
    return Offset(
      (localPos.dx / carSize.width).clamp(0.0, 1.0),
      (localPos.dy / carSize.height).clamp(0.0, 1.0),
    );
  }

  void _paintGridLocal(Offset localPos, Size carSize, int brushCells, List<double> grid, double delta) {
    final rel = _localToRel(localPos, carSize);
    final gx = (rel.dx * _gridN).floor().clamp(0, _gridN - 1);
    final gy = (rel.dy * _gridN).floor().clamp(0, _gridN - 1);
    // brushCells is the fixed radius in grid cells
    for (int dy = -brushCells; dy <= brushCells; dy++) {
      for (int dx = -brushCells; dx <= brushCells; dx++) {
        final nx = gx + dx;
        final ny = gy + dy;
        if (nx < 0 || nx >= _gridN || ny < 0 || ny >= _gridN) continue;
        if (!_isCarCell(nx, ny)) continue;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > brushCells) continue;
        final idx = ny * _gridN + nx;
        grid[idx] = (grid[idx] + delta).clamp(0.0, 1.0);
      }
    }
  }

  void _spawnDroplets(Offset localPos) {
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 3 + 1;
      _drops.add(_Droplet(
        pos: localPos + Offset((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 10),
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 2),
        radius: _rng.nextDouble() * 4 + 2,
        life: 1.0,
        color: const Color(0xFF81D4FA),
      ));
    }
  }

  void _spawnBubbles(Offset localPos) {
    for (int i = 0; i < 3; i++) {
      _bubbles.add(_Bubble(
        pos: localPos + Offset((_rng.nextDouble() - 0.5) * 20, (_rng.nextDouble() - 0.5) * 20),
        radius: _rng.nextDouble() * 8 + 4,
        life: 1.0,
      ));
    }
  }

  void _spawnSparks(Offset localPos) {
    final sparkColors = [Colors.yellow, Colors.amber, Colors.white, const Color(0xFFFFF176)];
    for (int i = 0; i < 5; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 4 + 2;
      _sparks.add(_Spark(
        pos: localPos,
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 1),
        life: 1.0,
        color: sparkColors[_rng.nextInt(sparkColors.length)],
      ));
    }
  }

  void _showBanner(String text, Color color) {
    setState(() {
      _bannerText = text;
      _bannerColor = color;
    });
    _stepBannerCtrl.forward(from: 0);
  }

  void _triggerStepComplete(String bannerText, Color bannerColor) {
    AudioManager.instance.playEffect('audio/pop.mp3');
    setState(() => _stepComplete = true);
    _showBanner(bannerText, bannerColor);
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _stepComplete) {
        _advanceStep();
      }
    });
  }

  static const double _advanceThreshold = 0.85;

  void _checkAdvance() {
    if (_stepComplete) return;
    switch (_step) {
      case _WashStep.water:
        if (_waterProgress >= _advanceThreshold) {
          _triggerStepComplete('✨ 먼지 씻기 성공! 비누칠 단계로 넘어가요!', const Color(0xFF7E57C2));
        }
        break;
      case _WashStep.soap:
        if (_soapProgress >= _advanceThreshold) {
          _triggerStepComplete('🌊 거품 칠하기 성공! 헹구러 가요!', const Color(0xFF0288D1));
        }
        break;
      case _WashStep.rinse:
        if (_rinseProgress >= _advanceThreshold) {
          _triggerStepComplete('🧹 헹구기 성공! 닦기 단계로 넘어가요!', const Color(0xFFFF7043));
        }
        break;
      case _WashStep.dry:
        if (_dryProgress >= _advanceThreshold) {
          _spawnConfetti();
          _triggerStepComplete('🎨 반짝반짝! 이제 스티커로 꾸며봐요!', const Color(0xFF26A69A));
        }
        break;
      default:
        break;
    }
  }

  void _advanceStep() {
    _autoAdvanceTimer?.cancel();
    AudioManager.instance.playClick();
    setState(() {
      _stepComplete = false;
      _bannerText = '';
      switch (_step) {
        case _WashStep.water:  _step = _WashStep.soap;    break;
        case _WashStep.soap:   _step = _WashStep.rinse;   break;
        case _WashStep.rinse:  _step = _WashStep.dry;     break;
        case _WashStep.dry:    _step = _WashStep.sticker; break;
        default: break;
      }
    });
  }

  void _spawnConfetti() {
    final confettiColors = [
      Colors.red, Colors.orange, Colors.yellow, Colors.green,
      Colors.blue, Colors.purple, Colors.pink,
    ];
    final sw = MediaQuery.of(context).size.width;
    for (int i = 0; i < 60; i++) {
      _confetti.add(_Spark(
        pos: Offset(_rng.nextDouble() * sw, -20),
        vel: Offset((_rng.nextDouble() - 0.5) * 6, _rng.nextDouble() * 3 + 1),
        life: 1.0,
        color: confettiColors[_rng.nextInt(confettiColors.length)],
      ));
    }
  }

  // brushCells=2 on 15x15 grid → balanced area
  // delta=0.6 → needs 2 passes or slower drag to fully clean
  void _onDrag(Offset localPos, Size carSize) {
    if (_step == _WashStep.driveIn) return;

    switch (_step) {
      case _WashStep.water:
        _paintGridLocal(localPos, carSize, 2, _dirtGrid, -0.6);
        _spawnDroplets(localPos);
        AudioManager.instance.playEffect('audio/pop.mp3');
        break;
      case _WashStep.soap:
        _paintGridLocal(localPos, carSize, 2, _soapGrid, 0.6);
        _spawnBubbles(localPos);
        break;
      case _WashStep.rinse:
        _paintGridLocal(localPos, carSize, 2, _rinseGrid, 0.6);
        _paintGridLocal(localPos, carSize, 2, _soapGrid, -0.6);
        _spawnDroplets(localPos);
        AudioManager.instance.playEffect('audio/pop.mp3');
        break;
      case _WashStep.dry:
        _paintGridLocal(localPos, carSize, 2, _dryGrid, 0.6);
        _spawnSparks(localPos);
        break;
      case _WashStep.sticker:
        _placeSticker(localPos, carSize);
        break;
      default:
        break;
    }
    _checkAdvance();
  }

  void _placeSticker(Offset localPos, Size carSize) {
    final rel = _localToRel(localPos, carSize);
    setState(() {
      _stickers.add(_Sticker(_stickerEmojis[_selectedStickerIdx], rel));
    });
    AudioManager.instance.playClick();
  }

  void _startDriveOut() {
    _autoAdvanceTimer?.cancel();
    AudioManager.instance.playClick();
    _spawnConfetti();
    _carDriveCtrl.forward().then((_) {
      setState(() => _driveComplete = true);
    });
  }

  void _startDriveIn(_Vehicle vehicle) {
    _autoAdvanceTimer?.cancel();
    AudioManager.instance.playClick();
    setState(() {
      _car = vehicle;
      _step = _WashStep.driveIn;
      _carDriveInX = 1.0;
      _stepComplete = false;
      _initGrids();
      _drops.clear();
      _bubbles.clear();
      _sparks.clear();
      _smokes.clear();
      _stickers.clear();
    });

    _driveInCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _step = _WashStep.water;
      });
      _showBanner('💧 손가락으로 쓱쓱~ 먼지를 씻어요!', const Color(0xFF0288D1));
    });
  }

  void _reset() {
    _autoAdvanceTimer?.cancel();
    setState(() {
      _step = _WashStep.selectCar;
      _stepComplete = false;
      _initGrids();
      _drops.clear();
      _bubbles.clear();
      _sparks.clear();
      _smokes.clear();
      _confetti.clear();
      _stickers.clear();
      _carDriveX = 0;
      _carDriveInX = 1.0;
      _driveComplete = false;
      _bannerText = '';
      _carDriveCtrl.reset();
      _driveInCtrl.reset();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_driveComplete) return _buildCompleteScreen();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0288D1), Color(0xFF80DEEA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _step == _WashStep.selectCar
              ? _buildSelectScreen()
              : _buildWashScreen(),
        ),
      ),
    );
  }

  // ── 0. Car Select Screen ──────────────────────────────────────────────────
  Widget _buildSelectScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { AudioManager.instance.playClick(); Navigator.of(context).pop(); },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                ),
              ),
              const Spacer(),
              Text('🚗 세차장에 어서오세요!',
                style: GoogleFonts.jua(fontSize: 22, color: Colors.white, shadows: [
                  const Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                ]),
              ),
              const Spacer(),
              const SizedBox(width: 44),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text('씻겨줄 먼지 묻은 차를 골라주세요! 🧼',
          style: GoogleFonts.jua(fontSize: 17, color: Colors.white.withValues(alpha: 0.85)),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _kVehicles.length,
              itemBuilder: (ctx, i) {
                final v = _kVehicles[i];
                return _CarSelectTile(
                  vehicle: v,
                  onTap: () => _startDriveIn(v),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── 1. Wash Screen ────────────────────────────────────────────────────────
  Widget _buildWashScreen() {
    return Column(
      children: [
        _buildTopBar(),
        _buildStepIndicator(),

        Expanded(
          child: LayoutBuilder(builder: (ctx, constraints) {
            return _buildCarArea(constraints);
          }),
        ),

        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); _reset(); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧼 ', style: TextStyle(fontSize: 18)),
                Text(
                  '${_car.label} 세차장',
                  style: GoogleFonts.jua(fontSize: 18, color: Colors.white, shadows: [
                    const Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 3),
                  ]),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => AudioManager.instance.toggleSound()),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Icon(
                AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: Colors.white, size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('🚿', '물씻기',  _WashStep.water,   const Color(0xFF0288D1)),
      ('🫧', '비누칠',  _WashStep.soap,    const Color(0xFF7E57C2)),
      ('🌊', '헹구기',  _WashStep.rinse,   const Color(0xFF00ACC1)),
      ('🧻', '닦기',    _WashStep.dry,     const Color(0xFFFF7043)),
      ('🎀', '꾸미기',  _WashStep.sticker, const Color(0xFF26A69A)),
    ];

    double progress = 0;
    switch (_step) {
      case _WashStep.water:  progress = _waterProgress; break;
      case _WashStep.soap:   progress = _soapProgress;  break;
      case _WashStep.rinse:  progress = _rinseProgress; break;
      case _WashStep.dry:    progress = _dryProgress;   break;
      default: progress = 1.0;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SizedBox(
            height: 72, // Fixed height to prevent layout shift when items grow
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: steps.map((s) {
                final isCurrent = _step == s.$3;
                final isDone = _step.index > s.$3.index;
                final isNextReady = _stepComplete && (_step.index + 1 == s.$3.index);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: isNextReady ? _advanceStep : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isNextReady ? 48 : (isCurrent ? 44 : 36),
                            width:  isNextReady ? 48 : (isCurrent ? 44 : 36),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF43E97B)
                                  : isNextReady || isCurrent
                                      ? s.$4
                                      : Colors.white.withValues(alpha: 0.25),
                              border: Border.all(
                                color: isCurrent || isNextReady ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isNextReady ? [
                                BoxShadow(
                                  color: s.$4.withValues(alpha: 0.8),
                                  blurRadius: 18, spreadRadius: 3,
                                ),
                              ] : isCurrent ? [
                                BoxShadow(color: s.$4.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                              ] : [],
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                                  : Text(s.$1, style: TextStyle(fontSize: isNextReady ? 24 : (isCurrent ? 22 : 18))),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isNextReady ? '👆 탭!' : s.$2,
                            style: GoogleFonts.jua(
                              fontSize: isNextReady ? 12 : (isCurrent ? 12 : 11),
                              color: isNextReady || isCurrent ? Colors.white : Colors.white60,
                              fontWeight: (isNextReady || isCurrent) ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress / _advanceThreshold).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                _stepComplete ? const Color(0xFF43E97B) : const Color(0xFF81D4FA),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }


  Widget _buildCarArea(BoxConstraints constraints) {
    final areaW = constraints.maxWidth;
    final areaH = constraints.maxHeight;
    final carW = (areaW * 0.80).clamp(200.0, 360.0);
    final carH = (carW * 0.58).clamp(120.0, 220.0);
    final carL = (areaW - carW) / 2.0;

    // Car sits on the road
    final groundH = areaH * 0.28;
    final groundTop = areaH - groundH;
    final carT = (groundTop - carH * 0.78).clamp(0.0, areaH - carH);

    // X offsets for Drive-In and Drive-Out
    final driveInOffsetX = _step == _WashStep.driveIn
        ? _carDriveInX * (areaW + carW + 60)
        : 0.0;
    final driveOutOffsetX = _carDriveCtrl.isAnimating || _driveComplete
        ? -_carDriveX * (areaW + carW + 60)
        : 0.0;

    final totalOffsetX = driveInOffsetX + driveOutOffsetX;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Road / Ground
        Positioned(
          left: 0, right: 0, bottom: 0,
          height: areaH * 0.28,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF546E7A),
              border: Border(top: BorderSide(color: Colors.blueGrey.shade700, width: 3)),
            ),
          ),
        ),

        // Road markings
        ...List.generate(5, (i) => Positioned(
          left: areaW * 0.1 + i * areaW * 0.18,
          bottom: areaH * 0.10,
          child: Container(
            width: areaW * 0.1,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        )),

        // Exhaust smoke particles (renders behind car)
        if (_step == _WashStep.driveIn && _smokes.isNotEmpty)
          Positioned(
            left: carL + totalOffsetX + carW * 0.85,
            top: carT + carH * 0.6,
            child: CustomPaint(
              painter: _SmokePainter(_smokes),
            ),
          ),

        // Car interactive container (Emoji + Mud + Soap + Sparks)
        Positioned(
          left: carL + totalOffsetX,
          top: carT,
          width: carW,
          height: carH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart:  (d) => _onDrag(d.localPosition, Size(carW, carH)),
            onPanUpdate: (d) => _onDrag(d.localPosition, Size(carW, carH)),
            onTapDown:   (d) => _onDrag(d.localPosition, Size(carW, carH)),
            child: _CarCanvas(
              vehicle: _car,
              step: _step,
              dirtGrid: _dirtGrid,
              soapGrid: _soapGrid,
              dryGrid: _dryGrid,
              drops: _drops,
              bubbles: _bubbles,
              sparks: _sparks,
              stickers: _stickers,
              gridN: _gridN,
            ),
          ),
        ),

        // Step complete banner
        if (_bannerText.isNotEmpty)
          Positioned(
            top: areaH * 0.05,
            left: 0, right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _stepBannerAnim,
                child: _StepBanner(text: _bannerText, color: _bannerColor),
              ),
            ),
          ),

        // Confetti overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(_confetti),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    const double barHeight = 130.0;

    if (_step == _WashStep.driveIn) {
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          alignment: Alignment.center,
          child: Text(
            '🏎️ 붕붕~ 부우웅! 차가 입장하고 있어요!',
            style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    if (_step == _WashStep.sticker) {
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stickerEmojis.length,
                  itemBuilder: (ctx, i) {
                    final selected = i == _selectedStickerIdx;
                    return GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        setState(() => _selectedStickerIdx = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 48 : 40,
                        height: selected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? KidsTheme.yellow : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: selected ? [
                            BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 8),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(_stickerEmojis[i], style: TextStyle(fontSize: selected ? 24 : 20)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startDriveOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43E97B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 6,
                    shadowColor: const Color(0xFF43E97B),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🚗', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('출발! 빵빵~!', style: GoogleFonts.jua(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Text('💨', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hints = <_WashStep, String>{
      _WashStep.water: '💧 손가락으로 쓱쓱~ 먼지를 씻어내요!',
      _WashStep.soap:  '🫧 비누로 구석구석 문질러요!',
      _WashStep.rinse: '🌊 물로 거품을 깨끗이 씻어내요!',
      _WashStep.dry:   '🧻 수건으로 반짝반짝 닦아요!',
    };

    final nextInfo = <_WashStep, (String, String, Color)>{
      _WashStep.water: ('🫧', '비누 칠하기 시작!', const Color(0xFF7E57C2)),
      _WashStep.soap:  ('🌊', '헹구기 시작!',    const Color(0xFF0288D1)),
      _WashStep.rinse: ('🧻', '수건으로 닦기!',  const Color(0xFFFF7043)),
      _WashStep.dry:   ('🎀', '꾸미기 시작!',    const Color(0xFF26A69A)),
    };

    if (_stepComplete && nextInfo.containsKey(_step)) {
      final info = nextInfo[_step]!;
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _advanceStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: info.$3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 10,
                shadowColor: info.$3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(info.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    info.$2,
                    style: GoogleFonts.jua(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: barHeight,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        alignment: Alignment.center,
        child: Text(
          hints[_step] ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  // ── Complete Screen ────────────────────────────────────────────────────────
  Widget _buildCompleteScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF7C4DFF), Color(0xFF00BCD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _ConfettiPainter(_confetti)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉✨🚿', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                Text('우와! 완벽한 세차 끝!',
                  style: GoogleFonts.jua(fontSize: 34, color: Colors.white, shadows: [
                    const Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 8),
                  ]),
                ),
                const SizedBox(height: 10),
                Text('차이가 깨끗해져서 기분이 참 좋아!',
                  style: GoogleFonts.jua(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 36),
                _BigButton(
                  label: '🚗 다른 차 또 씻기!',
                  color: const Color(0xFFFF7043),
                  onTap: _reset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTERS & COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════════

class _CarSelectTile extends StatelessWidget {
  final _Vehicle vehicle;
  final VoidCallback onTap;

  const _CarSelectTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(vehicle.emoji, style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  Text(vehicle.label, style: GoogleFonts.jua(fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
            // Mud badge indicating dirty status
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('먼지 가득! 💩', style: GoogleFonts.jua(fontSize: 10, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarCanvas extends StatelessWidget {
  final _Vehicle vehicle;
  final _WashStep step;
  final List<double> dirtGrid;
  final List<double> soapGrid;
  final List<double> dryGrid;
  final List<_Droplet> drops;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  final List<_Sticker> stickers;
  final int gridN;

  const _CarCanvas({
    required this.vehicle,
    required this.step,
    required this.dirtGrid,
    required this.soapGrid,
    required this.dryGrid,
    required this.drops,
    required this.bubbles,
    required this.sparks,
    required this.stickers,
    required this.gridN,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Car Emoji + Masked Dirt + Masked Soap + Masked Shine (Strictly clipped to car silhouette)
        Positioned.fill(
          child: CustomPaint(
            painter: _CarMaskedPainter(
              vehicle: vehicle,
              step: step,
              dirtGrid: dirtGrid,
              soapGrid: soapGrid,
              dryGrid: dryGrid,
              gridN: gridN,
            ),
          ),
        ),

        // Droplets + bubbles + sparks (water drops & sparks floating)
        Positioned.fill(
          child: CustomPaint(
            painter: _ParticlePainter(drops: drops, bubbles: bubbles, sparks: sparks),
          ),
        ),

        // Stickers
        for (final s in stickers)
          Positioned.fill(
            child: IgnorePointer(
              child: FractionallySizedBox(
                alignment: Alignment(s.rel.dx * 2 - 1, s.rel.dy * 2 - 1),
                widthFactor: 0.15,
                heightFactor: 0.3,
                child: FittedBox(
                  child: Text(s.emoji, style: const TextStyle(fontSize: 100)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Car Masked Painter (Alpha Silhouette Clipping) ───────────────────────────
class _CarMaskedPainter extends CustomPainter {
  final _Vehicle vehicle;
  final _WashStep step;
  final List<double> dirtGrid;
  final List<double> soapGrid;
  final List<double> dryGrid;
  final int gridN;

  _CarMaskedPainter({
    required this.vehicle,
    required this.step,
    required this.dirtGrid,
    required this.soapGrid,
    required this.dryGrid,
    required this.gridN,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Master Layer for Car Masking
    canvas.saveLayer(bounds, Paint());

    // Step A: Draw Car Emoji Graphic
    final fontSize = min(size.width * 0.78, size.height * 0.85);
    final textPainter = TextPainter(
      text: TextSpan(
        text: vehicle.emoji,
        style: TextStyle(fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final textPos = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    textPainter.paint(canvas, textPos);

    // Step B: Draw Dirt, Soap, Gloss ONLY inside Car Emoji Silhouette (srcATop)
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.srcATop);

    // B-1: Natural Mud Splatters (Rendered directly from dirtGrid)
    _drawMudLayer(canvas, size);

    // B-2: Soap foam
    _drawSoapLayer(canvas, size);

    // B-3: Dry Shine (Only shown during wiping step)
    if (step == _WashStep.dry) {
      _drawShineLayer(canvas, size);
    }

    canvas.restore(); // End Effects Layer
    canvas.restore(); // End Master Layer
  }

  void _drawMudLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final mudColor = const Color(0xFF5D4037);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final dirtVal = dirtGrid[y * gridN + x]; // 1.0 = dirty, 0.0 = clean
        if (dirtVal <= 0.02) continue;

        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        final baseR = cw * 0.90 * dirtVal;
        paint.color = mudColor.withValues(alpha: (dirtVal * 0.95).clamp(0.0, 0.95));

        canvas.drawCircle(center, baseR, paint);

        // Add subtle natural organic splatter texture per cell
        final rng = Random((y * 31 + x * 17) & 0x7FFFFFFF);
        for (int k = 0; k < 2; k++) {
          final ox = (rng.nextDouble() - 0.5) * cw * 0.7;
          final oy = (rng.nextDouble() - 0.5) * ch * 0.7;
          final subR = baseR * (0.35 + rng.nextDouble() * 0.35);
          canvas.drawCircle(center + Offset(ox, oy), subR, paint);
        }
      }
    }
  }

  void _drawSoapLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final foamPaint = Paint()..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = soapGrid[y * gridN + x];
        if (v <= 0.01) continue;
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        final r = cw * 0.7 * v;
        foamPaint.color = Colors.white.withValues(alpha: (v * 0.92).clamp(0.0, 0.92));
        canvas.drawCircle(center, r, foamPaint);

        final shimmer = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFE1BEE7).withValues(alpha: v * 0.35);
        canvas.drawCircle(center, r * 0.6, shimmer);
      }
    }
  }

  void _drawShineLayer(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final glossPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = dryGrid[y * gridN + x];
        if (v <= 0.05) continue;
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        glossPaint.color = Colors.white.withValues(alpha: (v * 0.25).clamp(0.0, 0.25));
        canvas.drawCircle(center, cw * 0.55 * v, glossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CarMaskedPainter oldDelegate) => true;
}

// ── Particles Painter ──────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Droplet> drops;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  _ParticlePainter({required this.drops, required this.bubbles, required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final d in drops) {
      p.color = d.color.withValues(alpha: d.life.clamp(0.0, 1.0));
      canvas.drawCircle(d.pos, d.radius, p);
    }

    for (final b in bubbles) {
      p.color = Colors.white.withValues(alpha: (b.life * 0.8).clamp(0.0, 0.8));
      p.style = PaintingStyle.stroke;
      p.strokeWidth = 1.5;
      canvas.drawCircle(b.pos, b.radius, p);
    }

    for (final s in sparks) {
      p.color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0));
      p.style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, 3 * s.life, p);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Exhaust Smoke Painter ──────────────────────────────────────────────────────
class _SmokePainter extends CustomPainter {
  final List<_Smoke> smokes;
  _SmokePainter(this.smokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (final s in smokes) {
      paint.color = Colors.grey.shade400.withValues(alpha: (s.life * 0.6).clamp(0.0, 0.6));
      canvas.drawCircle(s.pos, s.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => true;
}

// ── Confetti Painter ───────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_Spark> confetti;
  _ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final c in confetti) {
      p.color = c.color.withValues(alpha: c.life.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromLTWH(c.pos.dx, c.pos.dy, 8, 8), p);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}

// ── Step Banner ────────────────────────────────────────────────────────────────
class _StepBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _StepBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.jua(fontSize: 20, color: Colors.white,
          shadows: [const Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
        ),
      ),
    );
  }
}

// ── Big Button ─────────────────────────────────────────────────────────────────
class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(label, style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
      ),
    );
  }
}
