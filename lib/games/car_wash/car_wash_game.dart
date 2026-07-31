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

// 세차 순서: 물로 먼지씻기 → 비누칠하기 → 물로 비누헹구기 → 타월닦기 → 스티커
enum _WashStep { selectCar, water, soap, rinse, dry, sticker }

class _Droplet {
  Offset pos;
  Offset vel;
  double radius;
  double life; // 1.0 → 0.0
  Color color;
  _Droplet({required this.pos, required this.vel, required this.radius, required this.life, required this.color});
}

class _Bubble {
  Offset pos;
  double radius;
  double life; // 1.0 → 0.0
  _Bubble({required this.pos, required this.radius, required this.life});
}

class _Spark {
  Offset pos;
  Offset vel;
  double life;
  Color color;
  _Spark({required this.pos, required this.vel, required this.life, required this.color});
}

class _Sticker {
  final String emoji;
  final Offset rel; // 0..1
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

  // Dirt / soap / shine coverage grids (20×20 = 400 cells)
  static const int _gridN = 20;
  static const int _gridSize = _gridN * _gridN;
  final List<double> _dirtGrid   = List.filled(_gridSize, 1.0); // 1=dirty 0=clean (step1: water)
  final List<double> _soapGrid   = List.filled(_gridSize, 0.0); // 0=bare  1=soapy (step2: soap)
  final List<double> _rinseGrid  = List.filled(_gridSize, 0.0); // 0=soapy 1=rinsed (step3: rinse off soap)
  final List<double> _dryGrid    = List.filled(_gridSize, 0.0); // 0=wet   1=dry (step4: towel)

  double get _waterProgress => 1.0 - (_dirtGrid.fold(0.0, (s, v) => s + v) / _gridSize);
  double get _soapProgress  => _soapGrid.fold(0.0, (s, v) => s + v) / _gridSize;
  double get _rinseProgress => _rinseGrid.fold(0.0, (s, v) => s + v) / _gridSize;
  double get _dryProgress   => _dryGrid.fold(0.0, (s, v) => s + v) / _gridSize;

  // Particles
  final List<_Droplet> _drops   = [];
  final List<_Bubble>  _bubbles = [];
  final List<_Spark>   _sparks  = [];

  // Stickers
  final List<_Sticker> _stickers = [];
  int _selectedStickerIdx = 0;
  static const List<String> _stickerEmojis = [
    '⭐', '💙', '🌸', '⚡', '🐾', '🎀', '🌈', '🔥', '🍭', '🎉',
  ];

  // Confetti for complete screen
  final List<_Spark> _confetti = [];



  // Animations
  late AnimationController _ticker;   // master 60fps ticker
  late AnimationController _carDriveCtrl;
  late AnimationController _stepBannerCtrl;
  late Animation<double>   _stepBannerAnim;
  final Random _rng = Random();

  double _carDriveX = 0; // 0=center, used for drive-out
  bool _driveComplete = false;

  // Step banner text
  String _bannerText = '';
  Color  _bannerColor = KidsTheme.orange;

  @override
  void initState() {
    super.initState();

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
      // Update drops
      for (int i = _drops.length - 1; i >= 0; i--) {
        final d = _drops[i];
        d.pos += d.vel;
        d.vel = Offset(d.vel.dx * 0.95, d.vel.dy + 0.3); // gravity
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

  @override
  void dispose() {
    _ticker.dispose();
    _carDriveCtrl.dispose();
    _stepBannerCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  // Convert local position (relative to car widget) to 0..1 relative
  Offset _localToRel(Offset localPos, Size carSize) {
    return Offset(
      (localPos.dx / carSize.width).clamp(0.0, 1.0),
      (localPos.dy / carSize.height).clamp(0.0, 1.0),
    );
  }

  void _paintGridLocal(Offset localPos, Size carSize, double brushR, List<double> grid, double delta) {
    final rel = _localToRel(localPos, carSize);
    final gx = (rel.dx * _gridN).floor();
    final gy = (rel.dy * _gridN).floor();
    final br = (brushR / carSize.width * _gridN).ceil().clamp(1, _gridN);
    for (int dy = -br; dy <= br; dy++) {
      for (int dx = -br; dx <= br; dx++) {
        final nx = gx + dx;
        final ny = gy + dy;
        if (nx < 0 || nx >= _gridN || ny < 0 || ny >= _gridN) continue;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > br) continue;
        final idx = ny * _gridN + nx;
        final strength = (1.0 - dist / br).clamp(0.0, 1.0);
        grid[idx] = (grid[idx] + delta * strength).clamp(0.0, 1.0);
      }
    }
  }

  void _spawnDroplets(Offset localPos) {
    final local = localPos;
    for (int i = 0; i < 6; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 3 + 1;
      _drops.add(_Droplet(
        pos: local + Offset((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 10),
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 2),
        radius: _rng.nextDouble() * 4 + 2,
        life: 1.0,
        color: const Color(0xFF81D4FA),
      ));
    }
  }

  void _spawnBubbles(Offset localPos) {
    final local = localPos;
    for (int i = 0; i < 3; i++) {
      _bubbles.add(_Bubble(
        pos: local + Offset((_rng.nextDouble() - 0.5) * 20, (_rng.nextDouble() - 0.5) * 20),
        radius: _rng.nextDouble() * 8 + 4,
        life: 1.0,
      ));
    }
  }

  void _spawnSparks(Offset localPos) {
    final local = localPos;
    final sparkColors = [Colors.yellow, Colors.amber, Colors.white, const Color(0xFFFFF176)];
    for (int i = 0; i < 5; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 4 + 2;
      _sparks.add(_Spark(
        pos: local,
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

  void _checkAdvance() {
    switch (_step) {
      case _WashStep.water:
        if (_waterProgress >= 0.88) {
          setState(() => _step = _WashStep.soap);
          AudioManager.instance.playEffect('audio/pop.mp3');
          _showBanner('🫧 이제 비누로 문질러요!', const Color(0xFF7E57C2));
        }
        break;
      case _WashStep.soap:
        if (_soapProgress >= 0.88) {
          setState(() => _step = _WashStep.rinse);
          AudioManager.instance.playEffect('audio/pop.mp3');
          _showBanner('🚿 물로 비누를 씻어내요!', const Color(0xFF0288D1));
        }
        break;
      case _WashStep.rinse:
        if (_rinseProgress >= 0.88) {
          setState(() => _step = _WashStep.dry);
          AudioManager.instance.playEffect('audio/pop.mp3');
          _showBanner('🧻 수건으로 보송보송 닦아요!', const Color(0xFFFF7043));
        }
        break;
      case _WashStep.dry:
        if (_dryProgress >= 0.88) {
          setState(() => _step = _WashStep.sticker);
          AudioManager.instance.playEffect('audio/pop.mp3');
          _showBanner('🎨 예쁘게 꾸며봐요!', const Color(0xFF26A69A));
          _spawnConfetti();
        }
        break;
      default:
        break;
    }
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

  // localPos = position relative to the car widget, carSize = car widget size
  void _onDrag(Offset localPos, Size carSize) {
    switch (_step) {
      case _WashStep.water:
        // 물로 먼지 씻기: dirtGrid 값을 낮춤
        _paintGridLocal(localPos, carSize, 28, _dirtGrid, -0.35);
        _spawnDroplets(localPos);
        AudioManager.instance.playEffect('audio/pop.mp3');
        break;
      case _WashStep.soap:
        // 비누 칠하기: soapGrid 값을 높임
        _paintGridLocal(localPos, carSize, 28, _soapGrid, 0.35);
        _spawnBubbles(localPos);
        break;
      case _WashStep.rinse:
        // 비누 헹구기: rinseGrid 값을 높임 + soapGrid 낮춤(시각적으로 거품 제거)
        _paintGridLocal(localPos, carSize, 28, _rinseGrid, 0.35);
        _paintGridLocal(localPos, carSize, 28, _soapGrid, -0.4);
        _spawnDroplets(localPos);
        AudioManager.instance.playEffect('audio/pop.mp3');
        break;
      case _WashStep.dry:
        // 타월 닦기: dryGrid 값을 높임
        _paintGridLocal(localPos, carSize, 32, _dryGrid, 0.35);
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
    AudioManager.instance.playClick();
    _spawnConfetti();
    _carDriveCtrl.forward().then((_) {
      setState(() => _driveComplete = true);
    });
  }

  void _reset() {
    setState(() {
      _step = _WashStep.selectCar;
      _dirtGrid.fillRange(0, _gridSize, 1.0);
      _soapGrid.fillRange(0, _gridSize, 0.0);
      _rinseGrid.fillRange(0, _gridSize, 0.0);
      _dryGrid.fillRange(0, _gridSize, 0.0);
      _drops.clear();
      _bubbles.clear();
      _sparks.clear();
      _confetti.clear();
      _stickers.clear();
      _carDriveX = 0;
      _driveComplete = false;
      _bannerText = '';
      _carDriveCtrl.reset();
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
        // Header
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
        Text('씻겨줄 차를 골라주세요! 🧼',
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
                  onTap: () {
                    AudioManager.instance.playClick();
                    setState(() {
                      _car = v;
                      _step = _WashStep.water;
                    });
                    _showBanner('🚿 물로 먼지를 씻어요!', const Color(0xFF0288D1));
                  },
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

        // Main wash area (expands to fill)
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); _reset(); },
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text('삐까번쩍 세차장 🧼',
                style: GoogleFonts.jua(fontSize: 20, color: Colors.white, shadows: [
                  const Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 4),
                ]),
              ),
              Text(_car.label, style: GoogleFonts.jua(fontSize: 14, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => AudioManager.instance.toggleSound()),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: Colors.white, size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('🚿', '물 씻기',  _WashStep.water),
      ('🫧', '비누',    _WashStep.soap),
      ('🌊', '헹구기',  _WashStep.rinse),
      ('🧻', '닦기',    _WashStep.dry),
      ('🎀', '꾸미기',  _WashStep.sticker),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final isCurrent = _step == s.$3;
          final isDone = _step.index > s.$3.index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == steps.length - 1 ? 0 : 4),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isCurrent ? 44 : 34,
                    width: isCurrent ? 44 : 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? const Color(0xFF43E97B)
                          : isCurrent
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.25),
                      boxShadow: isCurrent ? [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2),
                      ] : [],
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                          : Text(s.$1, style: TextStyle(fontSize: isCurrent ? 22 : 16)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(s.$2, style: GoogleFonts.jua(
                    fontSize: isCurrent ? 13 : 11,
                    color: isCurrent ? Colors.white : Colors.white60,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCarArea(BoxConstraints constraints) {
    final areaW = constraints.maxWidth;
    final areaH = constraints.maxHeight;
    final carW = (areaW * 0.80).clamp(200.0, 360.0);
    final carH = (carW * 0.58).clamp(120.0, 220.0);
    final carL = (areaW - carW) / 2.0;
    final carT = (areaH - carH) / 2.0;

    // Drive-out offset
    final driveOffsetX = _carDriveCtrl.isAnimating || _driveComplete
        ? _carDriveX * (areaW + carW + 60)
        : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ground
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

        // Wash arch (left pipe)
        Positioned(
          left: carL - 18,
          top: carT - 20,
          child: _WashArchPainter(
            step: _step,
            height: carH + 40,
          ),
        ),

        // Car interactive container — use localPosition so coords are car-relative
        Positioned(
          left: carL + driveOffsetX,
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
    if (_step == _WashStep.sticker) {
      return Container(
        color: Colors.black.withValues(alpha: 0.35),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
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
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: selected ? 60 : 50,
                      height: selected ? 60 : 50,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? KidsTheme.yellow : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected ? [
                          BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 10),
                        ] : [],
                      ),
                      child: Center(
                        child: Text(_stickerEmojis[i], style: TextStyle(fontSize: selected ? 30 : 24)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startDriveOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43E97B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                  shadowColor: const Color(0xFF43E97B),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚗', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text('출발! 빵빵~!', style: GoogleFonts.jua(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Text('💨', style: TextStyle(fontSize: 24)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Hint bar
    final hints = <_WashStep, String>{
      _WashStep.water: '💧 손가락으로 쓱쓱~ 먼지를 씻어내요!',
      _WashStep.soap:  '🫧 비누로 구석구석 문질러요!',
      _WashStep.rinse: '🌊 물로 거품을 깨끗이 씻어내요!',
      _WashStep.dry:   '🧻 수건으로 반짝반짝 닦아요!',
    };
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hints[_step] ?? '',
            textAlign: TextAlign.center,
            style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
          ),
        ],
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
          // Confetti overlay
          Positioned.fill(
            child: CustomPaint(painter: _ConfettiPainter(_confetti)),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 12),
                  Text('삐까번쩍!', style: GoogleFonts.jua(
                    fontSize: 48, color: Colors.white,
                    shadows: [const Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 8)],
                  )),
                  Text('세차 완료!', style: GoogleFonts.jua(
                    fontSize: 36, color: Colors.yellow,
                    shadows: [const Shadow(color: Colors.black38, offset: Offset(0, 2), blurRadius: 6)],
                  )),
                  const SizedBox(height: 12),
                  Text(_car.label, style: GoogleFonts.jua(fontSize: 24, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('너무너무 깨끗해졌어요! ✨', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BigButton(
                        label: '다시 하기 🔄',
                        color: const Color(0xFF43E97B),
                        onTap: () => setState(() {
                          _reset();
                          _driveComplete = false;
                        }),
                      ),
                      const SizedBox(width: 16),
                      _BigButton(
                        label: '로비로 🏠',
                        color: const Color(0xFF5C6BC0),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUB-WIDGETS & PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Car Select Tile ────────────────────────────────────────────────────────────
class _CarSelectTile extends StatelessWidget {
  final _Vehicle vehicle;
  final VoidCallback onTap;
  const _CarSelectTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white30,
        highlightColor: Colors.white12,
        child: Container(
          decoration: BoxDecoration(
            color: v.bodyColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
            boxShadow: [
              BoxShadow(color: v.bodyColor.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(v.emoji, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(v.label, style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Car Canvas (main interactive widget) ──────────────────────────────────────
class _CarCanvas extends StatelessWidget {
  final _Vehicle vehicle;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          // Car background with metallic gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  vehicle.roofColor.withValues(alpha: 0.9),
                  vehicle.bodyColor,
                  vehicle.bodyColor.withValues(alpha: 0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Car body graphic (big emoji centered)
          Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(vehicle.emoji, style: const TextStyle(fontSize: 120)),
              ),
            ),
          ),

          // Dirt overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _DirtPainter(dirtGrid: dirtGrid, gridN: gridN),
            ),
          ),

          // Soap foam overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _SoapPainter(soapGrid: soapGrid, gridN: gridN),
            ),
          ),

          // Dry gloss overlay (shows after towel step)
          Positioned.fill(
            child: CustomPaint(
              painter: _ShinePainter(shineGrid: dryGrid, gridN: gridN),
            ),
          ),

          // Droplets + bubbles + sparks
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

          // Gloss highlight at top
          Positioned(
            top: 0, left: 0, right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wash Arch (left side pipe decor) ──────────────────────────────────────────
class _WashArchPainter extends StatelessWidget {
  final _WashStep step;
  final double height;
  const _WashArchPainter({required this.step, required this.height});

  Color get _pipeColor {
    switch (step) {
      case _WashStep.water: return const Color(0xFF4FC3F7);
      case _WashStep.soap:  return const Color(0xFFCE93D8);
      case _WashStep.rinse: return const Color(0xFF4FC3F7);
      case _WashStep.dry:   return const Color(0xFFFFD54F);
      default:              return const Color(0xFF78909C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: height,
      child: CustomPaint(painter: _ArchPaint(_pipeColor)),
    );
  }
}

class _ArchPaint extends CustomPainter {
  final Color color;
  _ArchPaint(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 12..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }
  @override
  bool shouldRepaint(_ArchPaint old) => old.color != color;
}

// ── Dirt Grid Painter ──────────────────────────────────────────────────────────
class _DirtPainter extends CustomPainter {
  final List<double> dirtGrid;
  final int gridN;
  _DirtPainter({required this.dirtGrid, required this.gridN});

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    const mudBase = Color(0xFF795548);
    final paint = Paint()..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = dirtGrid[y * gridN + x];
        if (v <= 0.01) continue;
        paint.color = mudBase.withValues(alpha: (v * 0.82).clamp(0.0, 1.0));
        final rect = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        canvas.drawOval(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DirtPainter old) => true;
}

// ── Soap Grid Painter ──────────────────────────────────────────────────────────
class _SoapPainter extends CustomPainter {
  final List<double> soapGrid;
  final int gridN;
  _SoapPainter({required this.soapGrid, required this.gridN});

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final foamPaint = Paint()..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = soapGrid[y * gridN + x];
        if (v <= 0.01) continue;
        final center = Offset((x + 0.5) * cw, (y + 0.5) * ch);
        final r = cw * 0.65 * v;
        foamPaint.color = Colors.white.withValues(alpha: (v * 0.9).clamp(0.0, 0.9));
        canvas.drawCircle(center, r, foamPaint);

        // Iridescent inner
        final shimmer = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFE1BEE7).withValues(alpha: v * 0.3);
        canvas.drawCircle(center, r * 0.6, shimmer);
      }
    }
  }

  @override
  bool shouldRepaint(_SoapPainter old) => true;
}

// ── Shine Grid Painter ──────────────────────────────────────────────────────────
class _ShinePainter extends CustomPainter {
  final List<double> shineGrid;
  final int gridN;
  _ShinePainter({required this.shineGrid, required this.gridN});

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / gridN;
    final ch = size.height / gridN;
    final glossPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < gridN; y++) {
      for (int x = 0; x < gridN; x++) {
        final v = shineGrid[y * gridN + x];
        if (v <= 0.01) continue;
        final rect = Rect.fromLTWH(x * cw, y * ch, cw, ch);
        glossPaint.color = Colors.white.withValues(alpha: v * 0.28);
        canvas.drawRect(rect, glossPaint);
        // Star sparkle at high shine
        if (v > 0.7) {
          final cx = (x + 0.5) * cw;
          final cy = (y + 0.5) * ch;
          final starPaint = Paint()
            ..color = const Color(0xFFFFEB3B).withValues(alpha: (v - 0.7) * 2)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          final r = cw * 0.35;
          canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), starPaint);
          canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), starPaint);
          canvas.drawLine(Offset(cx - r * 0.7, cy - r * 0.7), Offset(cx + r * 0.7, cy + r * 0.7), starPaint);
          canvas.drawLine(Offset(cx + r * 0.7, cy - r * 0.7), Offset(cx - r * 0.7, cy + r * 0.7), starPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ShinePainter old) => true;
}

// ── Particle Painter ───────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Droplet> drops;
  final List<_Bubble>  bubbles;
  final List<_Spark>   sparks;

  _ParticlePainter({required this.drops, required this.bubbles, required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    // Droplets
    for (final d in drops) {
      final paint = Paint()
        ..color = d.color.withValues(alpha: d.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(d.pos, d.radius, paint);
    }

    // Bubbles
    for (final b in bubbles) {
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: b.life * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final fillPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: b.life * 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(b.pos, b.radius, fillPaint);
      canvas.drawCircle(b.pos, b.radius, borderPaint);
      // Highlight
      final hlPaint = Paint()..color = Colors.white.withValues(alpha: b.life * 0.6)..style = PaintingStyle.fill;
      canvas.drawCircle(b.pos + Offset(-b.radius * 0.3, -b.radius * 0.3), b.radius * 0.25, hlPaint);
    }

    // Sparks
    for (final s in sparks) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(s.pos, s.pos + s.vel * 2, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ── Confetti Painter ───────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final List<_Spark> confetti;
  _ConfettiPainter(this.confetti);

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      final paint = Paint()
        ..color = c.color.withValues(alpha: c.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.pos, width: 8, height: 12),
          const Radius.circular(2),
        ),
        paint,
      );
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 4)),
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
