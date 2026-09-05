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
  final List<String> stickers;

  const _Vehicle({
    required this.id,
    required this.label,
    required this.emoji,
    required this.bodyColor,
    required this.roofColor,
    required this.wheelColor,
    required this.stickers,
  });
}

const List<_Vehicle> _kVehicles = [
  _Vehicle(
    id: 'car',
    label: '노랑 빵빵이',
    emoji: '🚗',
    bodyColor: Color(0xFFFFCC02),
    roofColor: Color(0xFFFF9F1C),
    wheelColor: Color(0xFF333333),
    stickers: ['🛞', '🚨', '⛽', '🔧', '🔩', '🛡️', '⚙️', '🏁'],
  ),
  _Vehicle(
    id: 'police',
    label: '멋진 경찰차',
    emoji: '🚓',
    bodyColor: Color(0xFF4FC3F7),
    roofColor: Color(0xFF0277BD),
    wheelColor: Color(0xFF333333),
    stickers: ['🚨', '🛡️', '⭐', '🔍', '📻', '🔦', '⚡', '🏆'],
  ),
  _Vehicle(
    id: 'fire',
    label: '용감 소방차',
    emoji: '🚒',
    bodyColor: Color(0xFFEF5350),
    roofColor: Color(0xFFB71C1C),
    wheelColor: Color(0xFF333333),
    stickers: ['🚨', '👨‍🚒', '🧯', '🪓', '💧', '🛡️', '🔥', '🏆'],
  ),
  _Vehicle(
    id: 'ambulance',
    label: '삐뽀 구급차',
    emoji: '🚑',
    bodyColor: Color(0xFFF5F5F5),
    roofColor: Color(0xFFB0BEC5),
    wheelColor: Color(0xFF333333),
    stickers: ['🚨', '🩺', '🩹', '💊', '🏥', '🛡️', '❤️', '⭐'],
  ),
  _Vehicle(
    id: 'bus',
    label: '타요 스쿨버스',
    emoji: '🚌',
    bodyColor: Color(0xFF42A5F5),
    roofColor: Color(0xFF1565C0),
    wheelColor: Color(0xFF333333),
    stickers: ['🛑', '🎒', '🔔', '🚸', '🛞', '⭐', '🚌', '🏁'],
  ),
  _Vehicle(
    id: 'racing',
    label: '스피드 레이싱카',
    emoji: '🏎️',
    bodyColor: Color(0xFFE53935),
    roofColor: Color(0xFFB71C1C),
    wheelColor: Color(0xFF111111),
    stickers: ['🏁', '🏆', '⚡', '🔥', '🛞', '🥇', '💨', '🛡️'],
  ),
  _Vehicle(
    id: 'monster',
    label: '몬스터 트럭',
    emoji: '🛻',
    bodyColor: Color(0xFF8B5CF6),
    roofColor: Color(0xFF6D28D9),
    wheelColor: Color(0xFF1F2937),
    stickers: ['🛞', '⚙️', '🥊', '👑', '💀', '💥', '🔥', '🛡️'],
  ),
  _Vehicle(
    id: 'taxi',
    label: '씽씽 모범택시',
    emoji: '🚕',
    bodyColor: Color(0xFFFFB703),
    roofColor: Color(0xFFFB8500),
    wheelColor: Color(0xFF333333),
    stickers: ['🏷️', '🗺️', '🧭', '💰', '🛞', '⭐', '🚕', '🏁'],
  ),
  _Vehicle(
    id: 'tractor',
    label: '힘센 트랙터',
    emoji: '🚜',
    bodyColor: Color(0xFF10B981),
    roofColor: Color(0xFF047857),
    wheelColor: Color(0xFF374151),
    stickers: ['🌾', '🌽', '🍎', '🌻', '🧑‍🌾', '🛞', '⚙️', '🔧'],
  ),
  _Vehicle(
    id: 'suv',
    label: '핑크 꼬마 SUV',
    emoji: '🚙',
    bodyColor: Color(0xFFEC4899),
    roofColor: Color(0xFFBE185D),
    wheelColor: Color(0xFF111111),
    stickers: ['🎀', '⛺', '🌸', '💖', '🕶️', '🎒', '⭐', '🛞'],
  ),
];

// 세차 순서: 차 선택 -> 매연 뿜으며 입장 -> 물로 먼지 씻기 -> 비누칠 -> 물로 헹구기 -> 수건 닦기 -> 스티커 -> 신나는 도로 달리기!
enum _WashStep { selectCar, driveIn, water, soap, rinse, dry, sticker, driving }

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

class _DrivingSpark {
  Offset pos;
  Offset vel;
  double life;
  Color color;
  double size;
  bool isStar;
  _DrivingSpark({
    required this.pos,
    required this.vel,
    required this.life,
    required this.color,
    this.size = 6.0,
    this.isStar = false,
  });
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

  DateTime _lastSoundTime = DateTime.now();

  void _playStepDragSound() {
    final now = DateTime.now();
    if (now.difference(_lastSoundTime).inMilliseconds < 120) return;
    _lastSoundTime = now;

    switch (_step) {
      case _WashStep.water:
        AudioManager.instance.playCarWashWaterSpray();
        break;
      case _WashStep.soap:
        AudioManager.instance.playCarWashSoapScrub();
        break;
      case _WashStep.rinse:
        AudioManager.instance.playCarWashRinse();
        break;
      case _WashStep.dry:
        AudioManager.instance.playCarWashDry();
        break;
      default:
        break;
    }
  }

  // brushCells=2 on 15x15 grid → balanced area
  // delta=0.6 → needs 2 passes or slower drag to fully clean
  void _onDrag(Offset localPos, Size carSize) {
    if (_step == _WashStep.driveIn) return;

    _playStepDragSound();

    switch (_step) {
      case _WashStep.water:
        _paintGridLocal(localPos, carSize, 3, _dirtGrid, -1.0);
        _spawnDroplets(localPos);
        break;
      case _WashStep.soap:
        _paintGridLocal(localPos, carSize, 3, _soapGrid, 1.0);
        _spawnBubbles(localPos);
        break;
      case _WashStep.rinse:
        _paintGridLocal(localPos, carSize, 3, _rinseGrid, 1.0);
        _paintGridLocal(localPos, carSize, 3, _soapGrid, -1.0);
        _spawnDroplets(localPos);
        break;
      case _WashStep.dry:
        _paintGridLocal(localPos, carSize, 3, _dryGrid, 1.0);
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
    if (_stickers.length >= 30) return;
    final rel = _localToRel(localPos, carSize);
    if (_stickers.isNotEmpty) {
      final lastRel = _stickers.last.rel;
      final dist = (lastRel - rel).distance;
      if (dist < 0.08) return;
    }
    final stickersList = _car.stickers;
    if (_selectedStickerIdx < stickersList.length) {
      setState(() {
        _stickers.add(_Sticker(stickersList[_selectedStickerIdx], rel));
      });
      AudioManager.instance.playCarWashSticker();
    }
  }

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

  // Real-time Interactive Tool Overlay (Hose, Sponge, Shower, Towel)
  Offset? _toolPos;
  bool _isToolActive = false;
  double _idleToolPhase = 0.0;

  // Step banner text
  String _bannerText = '';
  Color  _bannerColor = KidsTheme.orange;

  // 🚗 Road Driving Scene State
  double _roadScrollX = 0.0;
  bool _isBoosting = false;
  Timer? _boostTimer;
  double _carJumpOffset = 0.0;
  String? _honkBubbleText;
  Timer? _honkTimer;
  final List<_DrivingSpark> _drivingSparks = [];
  bool _showFinishDialog = false;
  double _drivingBouncePhase = 0.0;

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
      _idleToolPhase += dt * 3.0;

      // ── Road Driving Animation Update ──
      if (_step == _WashStep.driving) {
        final currentSpeed = _isBoosting ? 2.6 : 1.0;
        _roadScrollX += dt * 280 * currentSpeed;
        _drivingBouncePhase += dt * 16 * currentSpeed;

        // Sparkle trailing behind shiny clean car
        if (_rng.nextDouble() < 0.45) {
          _spawnDrivingSparkle();
        }
        if (_isBoosting && _rng.nextDouble() < 0.75) {
          _spawnBoosterFire();
        }

        // Update driving sparks
        for (int i = _drivingSparks.length - 1; i >= 0; i--) {
          final s = _drivingSparks[i];
          s.pos += s.vel;
          s.vel = Offset(s.vel.dx * 0.96, s.vel.dy + 0.1);
          s.life -= dt * (s.isStar ? 1.4 : 2.2);
          if (s.life <= 0) _drivingSparks.removeAt(i);
        }
      }

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
    _boostTimer?.cancel();
    _honkTimer?.cancel();
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
    setState(() => _stepComplete = true);
    _showBanner(bannerText, bannerColor);
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _stepComplete) {
        _advanceStep();
      }
    });
  }

  static const double _advanceThreshold = 0.68;

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



  void _playCarArrivalSound(_Vehicle car) {
    AudioManager.instance.playVehicleSound(car.id);
  }

  void _spawnDrivingSparkle() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final roadTop = sh * 0.64;
    final roadH = sh - roadTop;
    final carX = sw * 0.28;
    final carY = roadTop + roadH * 0.38 - _carJumpOffset;
    final colors = [Colors.yellow, Colors.cyanAccent, Colors.white, Colors.pinkAccent, Colors.amber];
    _drivingSparks.add(_DrivingSpark(
      pos: Offset(carX + (_rng.nextDouble() - 0.5) * 80, carY + (_rng.nextDouble() - 0.5) * 40),
      vel: Offset(-(_rng.nextDouble() * 4 + 3), (_rng.nextDouble() - 0.5) * 2),
      life: 1.0,
      color: colors[_rng.nextInt(colors.length)],
      size: _rng.nextDouble() * 5 + 4,
      isStar: _rng.nextBool(),
    ));
  }

  void _spawnBoosterFire() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final roadTop = sh * 0.64;
    final roadH = sh - roadTop;
    final carW = (sw * 0.60).clamp(220.0, 360.0);
    final carH = carW * 0.62;
    final carX = sw * 0.28 - carW * 0.45;
    final carY = roadTop + roadH * 0.38 - _carJumpOffset + carH * 0.16;
    final fireColors = [Colors.red, Colors.orange, Colors.yellow, Colors.deepOrange];
    for (int i = 0; i < 3; i++) {
      _drivingSparks.add(_DrivingSpark(
        pos: Offset(carX, carY + (_rng.nextDouble() - 0.5) * 18),
        vel: Offset(-(_rng.nextDouble() * 8 + 6), (_rng.nextDouble() - 0.5) * 3),
        life: 1.0,
        color: fireColors[_rng.nextInt(fireColors.length)],
        size: _rng.nextDouble() * 8 + 6,
        isStar: false,
      ));
    }
  }

  void _spawnHonkStars() {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final roadTop = sh * 0.64;
    final roadH = sh - roadTop;
    final carX = sw * 0.28;
    final carY = roadTop + roadH * 0.38 - _carJumpOffset - 40;
    final starColors = [Colors.amber, Colors.yellow, Colors.pinkAccent, Colors.white, Colors.lightGreenAccent];
    for (int i = 0; i < 14; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = _rng.nextDouble() * 5 + 2.5;
      _drivingSparks.add(_DrivingSpark(
        pos: Offset(carX, carY),
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 1.5),
        life: 1.0,
        color: starColors[_rng.nextInt(starColors.length)],
        size: _rng.nextDouble() * 6 + 5,
        isStar: true,
      ));
    }
  }

  void _startRoadDriving() {
    _autoAdvanceTimer?.cancel();
    _boostTimer?.cancel();
    _honkTimer?.cancel();
    setState(() {
      _step = _WashStep.driving;
      _roadScrollX = 0.0;
      _isBoosting = false;
      _carJumpOffset = 0.0;
      _honkBubbleText = null;
      _showFinishDialog = false;
      _drivingSparks.clear();
      _carDriveCtrl.reset();
      _carDriveX = 0;
    });
    AudioManager.instance.playEngine();
    AudioManager.instance.playChime();
  }

  void _honkCar() {
    AudioManager.instance.playVehicleSound(_car.id);
    AudioManager.instance.playJump();
    setState(() {
      _carJumpOffset = 26.0;
      _honkBubbleText = switch (_car.id) {
        'police' => '삐뽀삐뽀! 🚓✨',
        'fire' => '애앵애앵! 🚒🔥',
        'ambulance' => '삐뽀삐뽀! 🚑❤️',
        'bus' => '빵빵~ 부릉! 🚌💨',
        'racing' => '부우우웅~! 🏎️💨',
        'monster' => '쿠구구궁! 🛻⚡',
        'taxi' => '빵빵~ 손님타요! 🚕✨',
        'tractor' => '탈탈탈~ 🚜🌾',
        'suv' => '씽씽 달려요! 🚙💖',
        _ => '빵빵~ 출발! 🚗✨',
      };
    });
    _spawnHonkStars();

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _carJumpOffset = 0.0);
    });
    _honkTimer?.cancel();
    _honkTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _honkBubbleText = null);
    });
  }

  void _triggerBooster() {
    if (_isBoosting) return;
    AudioManager.instance.playEngine();
    AudioManager.instance.playChime();
    setState(() => _isBoosting = true);
    _boostTimer?.cancel();
    _boostTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _isBoosting = false);
    });
  }

  void _startDriveOut() {
    _autoAdvanceTimer?.cancel();
    _playCarArrivalSound(_car);
    _spawnConfetti();
    _carDriveCtrl.forward().then((_) {
      if (!mounted) return;
      _startRoadDriving();
    });
  }

  void _startDriveIn(_Vehicle vehicle) {
    _autoAdvanceTimer?.cancel();
    _playCarArrivalSound(vehicle);
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
    _boostTimer?.cancel();
    _honkTimer?.cancel();
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
      _drivingSparks.clear();
      _carDriveX = 0;
      _carDriveInX = 1.0;
      _driveComplete = false;
      _bannerText = '';
      _isBoosting = false;
      _carJumpOffset = 0.0;
      _honkBubbleText = null;
      _showFinishDialog = false;
      _carDriveCtrl.reset();
      _driveInCtrl.reset();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_step == _WashStep.driving) {
      return _buildRoadDrivingScreen();
    }
    if (_driveComplete) return _buildCompleteScreen();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF0288D1), Color(0xFF80DEEA)],
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.25,
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
    // 🌟 Significantly enlarged car size for easier touch and more satisfying presence!
    final carW = (areaW * 0.92).clamp(280.0, 520.0);
    final carH = (carW * 0.62).clamp(170.0, 320.0);
    final carL = (areaW - carW) / 2.0;

    // Car sits on the wash bay floor
    final groundH = areaH * 0.28;
    final groundTop = areaH - groundH;
    final carT = (groundTop - carH * 0.76).clamp(10.0, areaH - carH);

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
        // 🌟 Rich, Fun Kid-Friendly Car Wash Bay Background (Canopy, Sign, Pipes, Rotating Soft Brushes, Tiles, Floor)
        Positioned.fill(
          child: _CarWashBayBackground(
            step: _step,
            idlePhase: _idleToolPhase,
            groundH: groundH,
          ),
        ),

        // Exhaust smoke particles (renders behind car)
        if (_step == _WashStep.driveIn && _smokes.isNotEmpty)
          Positioned(
            left: carL + totalOffsetX + carW * 0.85,
            top: carT + carH * 0.6,
            child: CustomPaint(
              painter: _SmokePainter(_smokes),
            ),
          ),

        // Car interactive container (Emoji + Mud + Soap + Sparks + Real-time Tool)
        Positioned(
          left: carL + totalOffsetX,
          top: carT,
          width: carW,
          height: carH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              setState(() {
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onPanUpdate: (d) {
              setState(() {
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onPanEnd: (_) {
              setState(() => _isToolActive = false);
            },
            onPanCancel: () {
              setState(() => _isToolActive = false);
            },
            onTapDown: (d) {
              setState(() {
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onTapUp: (_) {
              setState(() => _isToolActive = false);
            },
            onTapCancel: () {
              setState(() => _isToolActive = false);
            },
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
              toolPos: _toolPos,
              isToolActive: _isToolActive,
              idlePhase: _idleToolPhase,
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
                  itemCount: _car.stickers.length,
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
                          child: Text(_car.stickers[i], style: TextStyle(fontSize: selected ? 24 : 20)),
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

  // ── Road Driving Screen ──────────────────────────────────────────────────
  Widget _buildRoadDrivingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF29B6F6),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-screen Parallax Scenery (Sky, Sun, Clouds, Hills, Town, Trees, Cheering Animals, Road)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _honkCar,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RoadDrivingSceneryPainter(
                    scrollX: _roadScrollX,
                    bouncePhase: _drivingBouncePhase,
                    isBoosting: _isBoosting,
                    vehicle: _car,
                    stickers: _stickers,
                    jumpOffset: _carJumpOffset,
                    drivingSparks: _drivingSparks,
                    honkBubbleText: _honkBubbleText,
                  ),
                ),
              ),
            ),

            // 2. Top HUD Bar (Explicitly positioned at top of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildDrivingHud(),
            ),

            // 3. Interactive Kid Driving Control Buttons (Bottom)
            _buildDrivingControls(),

            // 4. Celebration Modal Dialog
            if (_showFinishDialog)
              Positioned.fill(
                child: _buildCelebrationModal(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingHud() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // Cute Back to Car Wash Button
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                _reset();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.25),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '세차장',
                      style: GoogleFonts.jua(
                        fontSize: 15,
                        color: const Color(0xFF0277BD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Cute Vehicle Badge Title: e.g. "🚌 버스 씽씽!", "🚓 경찰차 씽씽!"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.25),
                    blurRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_car.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '${_car.label} 씽씽!',
                    style: GoogleFonts.jua(
                      fontSize: 16,
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Cute Sound Toggle Button
            GestureDetector(
              onTap: () => setState(() => AudioManager.instance.toggleSound()),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.25),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFF0288D1),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingControls() {
    // Dynamic vehicle sound button label & icon across all vehicle types!
    final (hornIcon, hornLabel) = switch (_car.id) {
      'police' => ('🚨', '사이렌!'),
      'fire' => ('🚒', '출동!'),
      'ambulance' => ('🚑', '삐뽀!'),
      'bus' => ('🚌', '빵빵!'),
      'racing' => ('🏎️', '부릉!'),
      'monster' => ('🛻', '쿠쿵!'),
      'tractor' => ('🚜', '탈탈!'),
      'taxi' => ('🚕', '손님타요!'),
      'suv' => ('🚙', '씽씽!'),
      _ => ('📢', '빵빵!'),
    };

    return Positioned(
      left: 14,
      right: 14,
      bottom: 22,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 1. Vehicle Specific Horn / Siren Action Button
            Expanded(
              flex: 10,
              child: _buildDrivingToyButton(
                icon: hornIcon,
                label: hornLabel,
                bgColors: [const Color(0xFFFFF59D), const Color(0xFFFFD54F)],
                shadowColor: const Color(0xFFFFA000),
                textColor: const Color(0xFF5D4037),
                onTap: _honkCar,
              ),
            ),
            const SizedBox(width: 8),

            // 2. Celebration / Wash Finish Modal Button
            Expanded(
              flex: 13,
              child: _buildDrivingToyButton(
                icon: '🏆',
                label: '세차 완성!',
                bgColors: [const Color(0xFFB9F6CA), const Color(0xFF00E676)],
                shadowColor: const Color(0xFF00B248),
                textColor: const Color(0xFF1B5E20),
                isHighlight: true,
                onTap: () {
                  AudioManager.instance.playSuccessSound('audio/chime.wav', rate: 1.2);
                  _spawnConfetti();
                  setState(() => _showFinishDialog = true);
                },
              ),
            ),
            const SizedBox(width: 8),

            // 3. Speed Booster Button
            Expanded(
              flex: 10,
              child: _buildDrivingToyButton(
                icon: _isBoosting ? '🔥' : '⚡',
                label: _isBoosting ? '터보!' : '부스터!',
                bgColors: _isBoosting
                    ? [const Color(0xFFFF8A80), const Color(0xFFFF5252)]
                    : [const Color(0xFFFFCCBC), const Color(0xFFFF7043)],
                shadowColor: _isBoosting ? const Color(0xFFD50000) : const Color(0xFFD84315),
                textColor: _isBoosting ? Colors.white : const Color(0xFFBF360C),
                onTap: _triggerBooster,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingToyButton({
    required String icon,
    required String label,
    required List<Color> bgColors,
    required Color shadowColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playClick();
        onTap();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(0, 3.5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: isHighlight ? 21 : 18)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jua(
                  fontSize: isHighlight ? 15.5 : 14.0,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.amber, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆✨🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(
                '우와! 완벽한 세차 성공!',
                style: GoogleFonts.jua(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${_car.label}이(가) 반짝반짝 빛나요!\n신나게 도로를 달렸어요! 🌟',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() => _showFinishDialog = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('🛣️ 계속 달리기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        _reset();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('🚗 다른 차 씻기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
          gradient: LinearGradient(
            colors: [
              Colors.white,
              vehicle.bodyColor.withValues(alpha: 0.25),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: vehicle.bodyColor.withValues(alpha: 0.6), width: 3),
          boxShadow: [
            BoxShadow(
              color: vehicle.bodyColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(vehicle.emoji, style: const TextStyle(fontSize: 62)),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        vehicle.label,
                        style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.textDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Mud badge indicating dirty status
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text('먼지 퐁퐁! 💩', style: GoogleFonts.jua(fontSize: 9, color: Colors.white)),
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
  final Offset? toolPos;
  final bool isToolActive;
  final double idlePhase;

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
    required this.toolPos,
    required this.isToolActive,
    required this.idlePhase,
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
                widthFactor: 0.18,
                heightFactor: 0.32,
                child: FittedBox(
                  child: Text(s.emoji, style: const TextStyle(fontSize: 100)),
                ),
              ),
            ),
          ),

        // Real-time Dynamic Interactive Wash Tool (Hose Gun / Foam Brush / Shower / Microfiber Towel)
        if (step == _WashStep.water || step == _WashStep.soap || step == _WashStep.rinse || step == _WashStep.dry)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WashToolPainter(
                  step: step,
                  toolPos: toolPos,
                  isActive: isToolActive,
                  idlePhase: idlePhase,
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

    // Step A: Draw Car Emoji Graphic (Enlarged to 0.94 scale for bigger presence)
    final fontSize = min(size.width * 0.94, size.height * 0.94);
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

// ═══════════════════════════════════════════════════════════════════════════════
// 🔥 PREMIUM PHOTOREALISTIC WASH TOOL PAINTER (Full metallic, gradient, shadow)
// ═══════════════════════════════════════════════════════════════════════════════

class _WashToolPainter extends CustomPainter {
  final _WashStep step;
  final Offset? toolPos;
  final bool isActive;
  final double idlePhase;

  _WashToolPainter({
    required this.step,
    required this.toolPos,
    required this.isActive,
    required this.idlePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center;
    if (toolPos != null) {
      center = toolPos!;
    } else {
      final ox = size.width * 0.5 + sin(idlePhase) * (size.width * 0.25);
      final oy = size.height * 0.45 + cos(idlePhase * 1.3) * 16;
      center = Offset(ox, oy);
    }

    switch (step) {
      case _WashStep.water:
        _drawPremiumHoseGun(canvas, size, center);
        break;
      case _WashStep.soap:
        _drawPremiumScrubBrush(canvas, size, center);
        break;
      case _WashStep.rinse:
        _drawPremiumShowerHead(canvas, size, center);
        break;
      case _WashStep.dry:
        _drawPremiumMicrofiberMitt(canvas, size, center);
        break;
      default:
        break;
    }

    if (!isActive && toolPos == null) {
      _drawGuidePrompt(canvas, center);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🔧 HELPER: Draw metallic gradient rounded rect (3D raised panel look)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawMetalPanel(Canvas canvas, Rect rect, double radius, Color base) {
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    // Shadow
    canvas.drawRRect(
      rr.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    // Base gradient (top-light metallic)
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.55)!,
            base,
            Color.lerp(base, Colors.black, 0.32)!,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(rect),
    );
    // Specular shine streak
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rect.left + 4, rect.top + 3, rect.width * 0.45, rect.height * 0.35), Radius.circular(radius * 0.7)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🌊 1. HIGH-PRESSURE WATER GUN + BRAIDED RUBBER HOSE
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumHoseGun(Canvas canvas, Size size, Offset target) {
    final gunOrigin = target;
    final hoseAttach = target + const Offset(48, -28);
    final hoseEnd = Offset(size.width + 20, -20);

    // ── Braided rubber hose (3 layered strokes = thick + mid + highlight) ──
    final hosePath = Path()
      ..moveTo(hoseAttach.dx, hoseAttach.dy)
      ..cubicTo(
        hoseAttach.dx + 55, hoseAttach.dy - 38,
        hoseEnd.dx - 60, hoseEnd.dy + 65,
        hoseEnd.dx, hoseEnd.dy,
      );

    // Hose shadow
    canvas.drawPath(hosePath, Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // Hose body (dark rubber core)
    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose mid highlight
    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF42A5F5)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose glint streak (top shine)
    canvas.drawPath(hosePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Hose coil rings (braid texture dots)
    for (int i = 0; i <= 8; i++) {
      final t = i / 8.0;
      final cx2 = hoseAttach.dx + t * (hoseEnd.dx - hoseAttach.dx);
      final cy2 = hoseAttach.dy + t * (hoseEnd.dy - hoseAttach.dy) - sin(t * pi) * 38;
      canvas.drawCircle(Offset(cx2, cy2), 2.5, Paint()..color = const Color(0xFF0D47A1).withValues(alpha: 0.65));
    }

    // ── Water jet spray (active) ──
    if (isActive) {
      final sprayOrigin = target + const Offset(-2, 4);
      final sprayDir = const Offset(-0.65, 0.75);
      for (int j = 0; j < 5; j++) {
        final spread = (j - 2) * 0.12;
        final dir = Offset(sprayDir.dx + spread, sprayDir.dy - spread.abs() * 0.3).normalize();
        final tipEnd = sprayOrigin + dir * (40.0 + j * 8);

        canvas.drawLine(
          sprayOrigin,
          tipEnd,
          Paint()
            ..color = Color.lerp(const Color(0xEE00B0FF), const Color(0x3380D8FF), j / 4.0)!
            ..strokeWidth = (3.5 - j * 0.4).clamp(1.0, 4.0)
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, j * 0.6),
        );
      }

      // Mist splash at spray end
      for (int k = 0; k < 4; k++) {
        final ang = k * pi / 2 + idlePhase * 3;
        final sx = sprayOrigin.dx - 22 + cos(ang) * 14;
        final sy = sprayOrigin.dy + 38 + sin(ang) * 8;
        canvas.drawCircle(Offset(sx, sy), 5.0 - k * 0.5, Paint()
          ..color = const Color(0x8040C4FF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }
    }

    // ── Gun body (metallic dark grey) ──
    canvas.save();
    canvas.translate(gunOrigin.dx, gunOrigin.dy);
    canvas.rotate(0.62);

    // Main body
    _drawMetalPanel(canvas, const Rect.fromLTWH(24, -11, 38, 26), 5, const Color(0xFF37474F));

    // Nozzle tube
    _drawMetalPanel(canvas, const Rect.fromLTWH(-4, -7, 30, 14), 4, const Color(0xFF78909C));

    // Nozzle tip ring (brass)
    canvas.drawCircle(Offset.zero, 7, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFFF8F00), Color(0xFFBF360C)],
      ).createShader(const Rect.fromLTWH(-7, -7, 14, 14)));
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFF212121));

    // Trigger guard
    final triggerPath = Path()
      ..moveTo(36, 0)
      ..lineTo(36, 18)
      ..quadraticBezierTo(44, 22, 50, 15)
      ..lineTo(50, 10)
      ..close();
    canvas.drawPath(triggerPath, Paint()..color = const Color(0xFF263238));

    // Trigger lever (red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(34, 4, 6, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFFEF5350),
    );

    // Grip handle ergonomic wrap
    final gripPath = Path()
      ..moveTo(48, 15)
      ..lineTo(44, 40)
      ..quadraticBezierTo(38, 46, 34, 42)
      ..lineTo(38, 18);
    canvas.drawPath(gripPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF455A64), const Color(0xFF1C313A)],
      ).createShader(const Rect.fromLTWH(34, 15, 14, 31)));

    // Grip texture knurling lines
    final knurlPaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..strokeWidth = 1.0..style = PaintingStyle.stroke;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(Offset(36 + i * 2.0, 22.0), Offset(36 + i * 2.0, 38.0), knurlPaint);
    }

    // Water connector elbow (back of gun)
    canvas.drawCircle(const Offset(58, 5), 6, Paint()
      ..color = const Color(0xFF78909C)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🧽 2. PREMIUM CAR WASH BRUSH (Long-handle ergonomic + Dense bristles + Foam)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumScrubBrush(Canvas canvas, Size size, Offset target) {
    final jiggle = isActive ? sin(idlePhase * 14) * 0.10 : sin(idlePhase * 1.8) * 0.04;

    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(jiggle - 0.5);

    // ── Shadow of entire brush ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-28, -78, 56, 110), const Radius.circular(12)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── BRUSH BRISTLE HEAD (dense rows, yellow + white foam) ──
    // Bristle backing plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-28, 18, 56, 26), const Radius.circular(6)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFCA28), const Color(0xFFF57F17)],
        ).createShader(const Rect.fromLTWH(-28, 18, 56, 26)),
    );

    // Bristle rows (white/cream tight rows)
    final bristlePaint = Paint()..strokeWidth = 1.8..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (int col = -10; col <= 10; col += 2) {
      for (int row = 0; row < 3; row++) {
        final bx = col * 2.5;
        final byTop = 44.0 + row * 2.5;
        final byBot = byTop + 14.0;
        final wobble = sin(idlePhase * 12 + col * 0.4) * (isActive ? 2.5 : 0.5);
        bristlePaint.color = row == 0 ? Colors.white : const Color(0xFFFFF9C4);
        canvas.drawLine(Offset(bx, byTop), Offset(bx + wobble, byBot), bristlePaint);
      }
    }

    // Foam froth at bristle base (3D puffy look)
    final foamPaints = [
      Paint()..color = Colors.white.withValues(alpha: 0.98),
      Paint()..color = const Color(0xFFE3F2FD).withValues(alpha: 0.9),
    ];
    final foamBubbles = [
      [-22.0, 44.0, 8.0], [-8.0, 42.0, 10.0], [6.0, 43.0, 9.0], [20.0, 44.0, 7.5],
      [-15.0, 52.0, 7.0], [-2.0, 53.0, 9.0], [12.0, 51.0, 7.0],
    ];
    for (int f = 0; f < foamBubbles.length; f++) {
      final b = foamBubbles[f];
      final shimmer = isActive ? sin(idlePhase * 8 + f) * 1.5 : 0.0;
      canvas.drawCircle(Offset(b[0], b[1] + shimmer), b[2], foamPaints[f % 2]);
      // Glint on each bubble
      canvas.drawCircle(Offset(b[0] - b[2] * 0.35, b[1] - b[2] * 0.3 + shimmer), b[2] * 0.25, Paint()..color = Colors.white.withValues(alpha: 0.9));
    }

    // Flying bubbles when active
    if (isActive) {
      for (int i = 0; i < 7; i++) {
        final ang = i * (pi * 2 / 7) + idlePhase * 5;
        final d = 38.0 + sin(idlePhase * 4 + i * 1.1) * 10;
        final bx = cos(ang) * d;
        final by = sin(ang) * d + 10;
        final r = 5.0 + (i % 3) * 2.5;
        canvas.drawCircle(Offset(bx, by), r, Paint()
          ..color = const Color(0xCCB3E5FC)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
        canvas.drawCircle(Offset(bx - r * 0.3, by - r * 0.3), r * 0.3, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
    }

    // ── CONNECTOR COLLAR (chrome ring) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-22, 12, 44, 10), const Radius.circular(4)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFECEFF1), const Color(0xFF90A4AE), const Color(0xFF37474F)],
        ).createShader(const Rect.fromLTWH(-22, 12, 44, 10)),
    );

    // ── HANDLE (ergonomic rubberized with grip texture) ──
    // Handle shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -78, 22, 96), const Radius.circular(10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)
        ..style = PaintingStyle.fill,
    );

    // Handle body gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -76, 20, 92), const Radius.circular(9)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFF00838F), const Color(0xFF00BCD4), const Color(0xFF006064)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(const Rect.fromLTWH(-10, -76, 20, 92)),
    );

    // Handle specular
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -70, 6, 70), const Radius.circular(3)),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Grip knurling indents
    for (int g = 0; g < 8; g++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-9, -56 + g * 9.0, 18, 5), const Radius.circular(2)),
        Paint()..color = const Color(0xFF00BFA5).withValues(alpha: 0.55),
      );
    }

    // Handle top cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -80, 24, 10), const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFECEFF1), const Color(0xFF78909C)],
        ).createShader(const Rect.fromLTWH(-12, -80, 24, 10)),
    );

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🚿 3. PREMIUM CHROME SHOWER RINSE HEAD + STAINLESS HOSE
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumShowerHead(Canvas canvas, Size size, Offset target) {
    final hoseEnd = Offset(size.width + 20, -25);

    // ── STAINLESS STEEL HOSE (twisted metallic) ──
    final hp1 = target + const Offset(32, -22);
    final hosePath = Path()
      ..moveTo(hp1.dx, hp1.dy)
      ..cubicTo(
        hp1.dx + 60, hp1.dy - 42,
        hoseEnd.dx - 55, hoseEnd.dy + 72,
        hoseEnd.dx, hoseEnd.dy,
      );

    canvas.drawPath(hosePath, Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF546E7A)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(hosePath, Paint()
      ..color = const Color(0xFF90A4AE)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    canvas.drawPath(hosePath, Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Stainless coil rings
    for (int i = 0; i <= 10; i++) {
      final t = i / 10.0;
      final cx2 = hp1.dx + t * (hoseEnd.dx - hp1.dx);
      final cy2 = hp1.dy + t * (hoseEnd.dy - hp1.dy) - sin(t * pi) * 42;
      canvas.drawCircle(Offset(cx2, cy2), 2.0, Paint()
        ..color = const Color(0xFF37474F).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill);
    }

    // ── Water streams (active) ──
    if (isActive) {
      final nozzleBase = target + const Offset(0, 12);
      for (int i = -4; i <= 4; i++) {
        final sx = nozzleBase.dx + i * 7.5;
        final curveFactor = sin(idlePhase * 8 + i * 0.5) * 6;
        final streamPath = Path()
          ..moveTo(sx, nozzleBase.dy)
          ..quadraticBezierTo(sx + curveFactor - 10, nozzleBase.dy + 28, sx - 12 + i * 4.0, nozzleBase.dy + 58);

        canvas.drawPath(streamPath, Paint()
          ..color = Color.lerp(const Color(0xDD29B6F6), const Color(0x6681D4FA), i.abs() / 4.0)!
          ..strokeWidth = (2.5 - i.abs() * 0.18).clamp(1.0, 2.8)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
      }
      // Splash pool at ground
      canvas.drawOval(
        Rect.fromCenter(center: target + const Offset(-12, 65), width: 55, height: 14),
        Paint()
          ..color = const Color(0x5529B6F6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // ── CHROME SHOWER HEAD BODY ──
    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(0.45);

    // Head shadow
    canvas.drawOval(
      const Rect.fromLTWH(-28, -10, 56, 20),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Disc face (chrome gradient)
    canvas.drawOval(
      const Rect.fromLTWH(-26, -9, 52, 18),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFECEFF1),
            const Color(0xFFB0BEC5),
            const Color(0xFF546E7A),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(const Rect.fromLTWH(-26, -9, 52, 18)),
    );

    // Spray holes grid
    final holePaint = Paint()..color = const Color(0xFF263238);
    for (int hx = -3; hx <= 3; hx++) {
      canvas.drawCircle(Offset(hx * 6.5, 0), 1.8, holePaint);
    }
    for (int hx = -2; hx <= 2; hx++) {
      canvas.drawCircle(Offset(hx * 6.5, 6.0), 1.8, holePaint);
      canvas.drawCircle(Offset(hx * 6.5, -6.0), 1.8, holePaint);
    }

    // Chrome rim ring
    canvas.drawOval(
      const Rect.fromLTWH(-26, -9, 52, 18),
      Paint()
        ..color = const Color(0xFF90A4AE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Specular glint
    canvas.drawOval(
      const Rect.fromLTWH(-18, -6, 18, 6),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Handle neck (connector stem)
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -30, 18, 22), const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [const Color(0xFFB0BEC5), const Color(0xFF78909C), const Color(0xFF37474F)],
        ).createShader(const Rect.fromLTWH(-9, -30, 18, 22)),
    );
    // Neck ring accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -18, 20, 5), const Radius.circular(2)),
      Paint()
        ..shader = LinearGradient(
          colors: [const Color(0xFFECEFF1), const Color(0xFF78909C)],
        ).createShader(const Rect.fromLTWH(-10, -18, 20, 5)),
    );

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🧤 4. PREMIUM MICROFIBER WASH MITT (3D plush, stitching, gradient)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPremiumMicrofiberMitt(Canvas canvas, Size size, Offset target) {
    final tilt = isActive ? sin(idlePhase * 11) * 0.13 : sin(idlePhase * 1.7) * 0.05;

    canvas.save();
    canvas.translate(target.dx, target.dy);
    canvas.rotate(tilt - 0.15);

    // ── Shadow ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-38, -32, 72, 66), const Radius.circular(25)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── MITT THUMB (left side) ──
    final thumbPath = Path()
      ..moveTo(-38, -10)
      ..quadraticBezierTo(-55, -18, -52, -4)
      ..quadraticBezierTo(-50, 8, -38, 14);
    thumbPath.close();
    canvas.drawPath(thumbPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF40C4FF), const Color(0xFF0288D1)],
      ).createShader(const Rect.fromLTWH(-56, -20, 22, 38)));

    // ── MAIN MITT BODY ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-36, -30, 72, 62), const Radius.circular(22)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF81D4FA),
            const Color(0xFF29B6F6),
            const Color(0xFF0288D1),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(const Rect.fromLTWH(-36, -30, 72, 62)),
    );

    // ── MICROFIBER SURFACE TEXTURE (plush waffle grid) ──
    final meshPaint = Paint()
      ..color = const Color(0xFF0277BD).withValues(alpha: 0.35)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    // Horizontal mesh lines
    for (int row = -3; row <= 3; row++) {
      canvas.drawLine(Offset(-32, row * 8.0), Offset(32, row * 8.0), meshPaint);
    }
    // Vertical mesh lines
    for (int col = -3; col <= 3; col++) {
      canvas.drawLine(Offset(col * 10.0, -26), Offset(col * 10.0, 26), meshPaint);
    }
    // Diagonal stitch lines
    final stitchPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-30, -24), const Offset(28, 26), stitchPaint);
    canvas.drawLine(const Offset(-30, 0), const Offset(28, -26), stitchPaint);
    canvas.drawLine(const Offset(-14, -28), const Offset(28, 14), stitchPaint);

    // ── Specular highlight band ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -24, 28, 36), const Radius.circular(14)),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    // ── PLUSH LOOPS texture (tiny raised fiber dots) ──
    final loopPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    final loopPositions = [
      const Offset(-20, -14), const Offset(8, -18), const Offset(-4, 4),
      const Offset(18, 8), const Offset(-16, 16), const Offset(10, -4),
      const Offset(24, -10), const Offset(-26, 2), const Offset(4, 20),
    ];
    for (final lp in loopPositions) {
      canvas.drawCircle(lp, 2.5, loopPaint);
    }

    // ── WRIST CUFF (elastic terry cloth band) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-30, 26, 60, 16), const Radius.circular(8)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, const Color(0xFFE1F5FE), const Color(0xFF81D4FA)],
        ).createShader(const Rect.fromLTWH(-30, 26, 60, 16)),
    );

    // Elastic rib lines on cuff
    final ribPaint = Paint()
      ..color = const Color(0xFFB3E5FC).withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (int r = 0; r < 5; r++) {
      canvas.drawLine(Offset(-28, 28 + r * 2.8), Offset(28, 28 + r * 2.8), ribPaint);
    }

    // Cuff logo dot
    canvas.drawCircle(const Offset(18, 34), 4, Paint()..color = const Color(0xFF0288D1));
    canvas.drawCircle(const Offset(18, 34), 2.5, Paint()..color = Colors.white);

    // ── SPARKLE STARS when actively drying ──
    if (isActive) {
      final starPositions = [
        [const Offset(-48, -22), 10.0, const Color(0xFFFFD700)],
        [const Offset(44, -16), 12.0, const Color(0xFFE0F7FA)],
        [const Offset(-30, 40), 9.0, Colors.white],
        [const Offset(36, 36), 11.0, const Color(0xFFFF4081)],
        [const Offset(0, -40), 8.0, const Color(0xFFFFFF00)],
      ];
      for (final s in starPositions) {
        _drawSparkleStar(canvas, s[0] as Offset, (s[1] as double) * (0.8 + 0.2 * sin(idlePhase * 6)), s[2] as Color);
      }
    }

    canvas.restore();
  }

  // ── Helper: Premium 4-Point Sparkle Star ──
  void _drawSparkleStar(Canvas canvas, Offset center, double radius, Color color) {
    // Outer glow
    canvas.drawCircle(center, radius * 1.2, Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final path = Path();
    final shortR = radius * 0.38;
    for (int i = 0; i < 8; i++) {
      final ang = i * pi / 4;
      final r = (i % 2 == 0) ? radius : shortR;
      final p = center + Offset(cos(ang) * r, sin(ang) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(center, radius * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  // ── Helper: Guide Prompt ──
  void _drawGuidePrompt(Canvas canvas, Offset center) {
    final tp = TextPainter(
      text: TextSpan(
        text: '👆 쓱싹 문질러요!',
        style: GoogleFonts.jua(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center + Offset(-tp.width / 2, 42));
  }

  @override
  bool shouldRepaint(_WashToolPainter oldDelegate) => true;
}

// ── Offset normalize helper ──
extension _OffsetNormalize on Offset {
  Offset normalize() {
    final len = distance;
    return len > 0 ? this / len : const Offset(0, 1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🌟 1. CAR WASH BAY BACKGROUND (Canopy, Sign, Pipes, Brushes, Tiles, Floor)
// ═══════════════════════════════════════════════════════════════════════════════

class _CarWashBayBackground extends StatelessWidget {
  final _WashStep step;
  final double idlePhase;
  final double groundH;

  const _CarWashBayBackground({
    required this.step,
    required this.idlePhase,
    required this.groundH,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarWashBayPainter(
        step: step,
        idlePhase: idlePhase,
        groundH: groundH,
      ),
    );
  }
}

class _CarWashBayPainter extends CustomPainter {
  final _WashStep step;
  final double idlePhase;
  final double groundH;

  _CarWashBayPainter({
    required this.step,
    required this.idlePhase,
    required this.groundH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wallH = h - groundH;

    // 1. Tiled Back Wall
    _drawTiledWall(canvas, w, wallH);

    // 2. Overhead Water Pipes & Pressure Gauge
    _drawOverheadPipes(canvas, w);

    // 3. Rotating Soft-Wash Cylinder Brushes on Left & Right
    _drawSideBrushes(canvas, w, wallH);

    // 4. Soap Foam Tank
    _drawSoapTank(canvas);

    // 5. Floating Iridescent Bubbles
    _drawFloatingBubbles(canvas, w, wallH);

    // 6. Top Canopy Awning & Glowing Signboard
    _drawTopCanopyAndSign(canvas, w);

    // 7. Modern Wash Bay Floor with Hazard Stripes & Drainage Grates
    _drawBayFloor(canvas, w, h, groundH);
  }

  void _drawTiledWall(Canvas canvas, double w, double wallH) {
    final rect = Rect.fromLTWH(0, 0, w, wallH);
    final wallShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFF80DEEA)],
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = wallShader);

    // Ceramic tile grid
    final gridPaint = Paint()
      ..color = const Color(0xFF4DD0E1).withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const tileSize = 38.0;
    for (double y = 0; y < wallH; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }
    for (double x = 0; x < w; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, wallH), gridPaint);
    }

    // Sparkle glints on tiles
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (int i = 0; i < 6; i++) {
      final gx = (i * 65.0 + 24.0) % w;
      final gy = (i * 48.0 + 35.0) % wallH;
      canvas.drawCircle(Offset(gx, gy), 2.0, glintPaint);
    }
  }

  void _drawOverheadPipes(Canvas canvas, double w) {
    final pipeY = 48.0;
    // Pipe shadow
    canvas.drawLine(
      Offset(0, pipeY + 2), Offset(w, pipeY + 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..strokeWidth = 12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Silver pipe body
    canvas.drawLine(
      Offset(0, pipeY), Offset(w, pipeY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE), Color(0xFF546E7A)],
        ).createShader(Rect.fromLTWH(0, pipeY - 5, w, 10))
        ..strokeWidth = 9,
    );
    // Pipe highlight
    canvas.drawLine(
      Offset(0, pipeY - 2), Offset(w, pipeY - 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..strokeWidth = 2,
    );

    // Brass joints along pipe
    final brassPaint = Paint()..color = const Color(0xFFFFA000);
    for (double jx = w * 0.2; jx < w * 0.9; jx += w * 0.25) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(jx - 4, pipeY - 7, 8, 14), const Radius.circular(3)),
        brassPaint,
      );
      // Spray nozzles hanging down
      canvas.drawRect(
        Rect.fromLTWH(jx - 2, pipeY + 6, 4, 8),
        Paint()..color = const Color(0xFF78909C),
      );
      canvas.drawCircle(Offset(jx, pipeY + 15), 3, Paint()..color = const Color(0xFF37474F));
    }

    // Pressure gauge at top right
    final gaugeCenter = Offset(w * 0.82, pipeY);
    canvas.drawCircle(gaugeCenter, 14, Paint()..color = const Color(0xFFFFB300));
    canvas.drawCircle(gaugeCenter, 11, Paint()..color = Colors.white);
    // Needle twitching
    final needleAngle = -pi * 0.2 + sin(idlePhase * 4) * 0.25;
    canvas.drawLine(
      gaugeCenter,
      gaugeCenter + Offset(cos(needleAngle) * 8, sin(needleAngle) * 8),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(gaugeCenter, 2.5, Paint()..color = Colors.black);
  }

  void _drawSideBrushes(Canvas canvas, double w, double wallH) {
    const brushW = 32.0;
    final brushTop = 75.0;
    final brushBottom = wallH - 12.0;
    final brushH = brushBottom - brushTop;

    // Left rotating roller brush
    _drawCylinderBrush(canvas, 12, brushTop, brushW, brushH, idlePhase * 35);

    // Right rotating roller brush
    _drawCylinderBrush(canvas, w - 12 - brushW, brushTop, brushW, brushH, -idlePhase * 35);
  }

  void _drawCylinderBrush(Canvas canvas, double left, double top, double width, double height, double spinPhase) {
    final centerX = left + width / 2;
    // Central steel rod
    canvas.drawLine(
      Offset(centerX, top - 6),
      Offset(centerX, top + height + 6),
      Paint()
        ..color = const Color(0xFF455A64)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Clip to brush bounds
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, width, height), const Radius.circular(16)));

    // Brush background
    canvas.drawRect(
      Rect.fromLTWH(left, top, width, height),
      Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.2),
    );

    // Alternating spiral bristle stripes (Sky Blue & Candy Pink)
    const stripeSpacing = 28.0;
    final offset = spinPhase % stripeSpacing;

    final paintBlue = Paint()
      ..color = const Color(0xFF29B6F6)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final paintPink = Paint()
      ..color = const Color(0xFFF06292)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    for (double y = top - stripeSpacing; y < top + height + stripeSpacing * 2; y += stripeSpacing) {
      final sy = y + offset;
      final isBlue = ((y / stripeSpacing).floor() % 2 == 0);
      final p = isBlue ? paintBlue : paintPink;
      canvas.drawLine(Offset(left - 4, sy - 8), Offset(left + width + 4, sy + 8), p);
    }

    // Shadow on sides to give 3D cylinder depth
    canvas.drawRect(
      Rect.fromLTWH(left, top, 6, height),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTWH(left + width - 6, top, 6, height),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    // Center specular shine
    canvas.drawRect(
      Rect.fromLTWH(left + width * 0.35, top, width * 0.3, height),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );

    canvas.restore();
  }

  void _drawSoapTank(Canvas canvas) {
    // Soap dispenser on left wall
    const tankRect = Rect.fromLTWH(48, 85, 30, 48);
    final rrect = RRect.fromRectAndRadius(tankRect, const Radius.circular(8));
    // Tank shadow
    canvas.drawRRect(rrect.shift(const Offset(2, 2)), Paint()..color = Colors.black.withValues(alpha: 0.15));
    // Glass body
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF80DEEA)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Liquid inside (Bubbly turquoise)
    final liquidH = 32.0 + sin(idlePhase * 2) * 2;
    final liquidRect = Rect.fromLTWH(50, 85 + (48 - liquidH), 26, liquidH - 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(liquidRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFF26A69A).withValues(alpha: 0.75),
    );

    // Foam bubbles on top of liquid
    canvas.drawCircle(Offset(56, 85 + (48 - liquidH)), 3.5, Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawCircle(Offset(64, 85 + (48 - liquidH) - 1), 4.5, Paint()..color = Colors.white.withValues(alpha: 0.9));
    canvas.drawCircle(Offset(71, 85 + (48 - liquidH)), 3.0, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  void _drawFloatingBubbles(Canvas canvas, double w, double wallH) {
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int i = 0; i < 9; i++) {
      final t = (idlePhase * 0.08 + i * 0.11) % 1.0;
      final bx = (w * (0.12 + (i * 0.09))) + sin(idlePhase * 1.6 + i * 1.5) * 18;
      final by = wallH * (0.90 - t * 0.85);
      final r = 6.0 + (i % 3) * 3.5;

      bubblePaint.color = Colors.white.withValues(alpha: (1.0 - t * 0.6).clamp(0.2, 0.7));
      canvas.drawCircle(Offset(bx, by), r, bubblePaint);

      // Inner rainbow tint
      canvas.drawCircle(
        Offset(bx, by), r * 0.85,
        Paint()..color = const Color(0xFFE1BEE7).withValues(alpha: 0.15),
      );
      // Glint highlight
      canvas.drawCircle(
        Offset(bx - r * 0.35, by - r * 0.35), r * 0.25,
        Paint()..color = Colors.white.withValues(alpha: 0.8),
      );
    }
  }

  void _drawTopCanopyAndSign(Canvas canvas, double w) {
    const canopyH = 26.0;
    const scallopW = 28.0;
    final count = (w / scallopW).ceil() + 1;

    // Scalloped canopy awning
    for (int i = 0; i < count; i++) {
      final sx = i * scallopW;
      final isBlue = (i % 2 == 0);
      final color = isBlue ? const Color(0xFF0288D1) : const Color(0xFFFFCA28);

      final path = Path()
        ..moveTo(sx, 0)
        ..lineTo(sx + scallopW, 0)
        ..lineTo(sx + scallopW, canopyH)
        ..arcToPoint(
          Offset(sx, canopyH),
          radius: const Radius.circular(scallopW / 2),
          clockwise: true,
        )
        ..close();

      canvas.drawPath(path, Paint()..color = color);
    }

    // Dropshadow under canopy
    canvas.drawRect(
      Rect.fromLTWH(0, canopyH + scallopW / 2 - 4, w, 4),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );

    // Cheerful Signboard plaque
    final signW = 190.0;
    final signH = 30.0;
    final signX = (w - signW) / 2;
    final signY = 14.0;
    final signRect = Rect.fromLTWH(signX, signY, signW, signH);
    final signRRect = RRect.fromRectAndRadius(signRect, const Radius.circular(16));

    // Sign background
    canvas.drawRRect(signRRect.shift(const Offset(0, 2)), Paint()..color = Colors.black.withValues(alpha: 0.25));
    canvas.drawRRect(
      signRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFA000), Color(0xFFFF6F00)],
        ).createShader(signRect),
    );
    canvas.drawRRect(
      signRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Text on sign
    final tp = TextPainter(
      text: TextSpan(
        text: '🫧 뽀득뽀득 키즈 세차장 🧽',
        style: GoogleFonts.jua(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(signX + (signW - tp.width) / 2, signY + (signH - tp.height) / 2));

    // Blinking lights around sign
    final bulbColors = [const Color(0xFFFFEB3B), const Color(0xFFFF1744), const Color(0xFF00E676), const Color(0xFF00E5FF)];
    for (int i = 0; i < 4; i++) {
      final bx = signX + 16 + i * (signW - 32) / 3;
      final pulse = (sin(idlePhase * 4 + i) * 0.4 + 0.6).clamp(0.2, 1.0);
      final bColor = bulbColors[i % bulbColors.length].withValues(alpha: pulse);
      canvas.drawCircle(Offset(bx, signY + 3), 3, Paint()..color = bColor);
      canvas.drawCircle(Offset(bx, signY + signH - 3), 3, Paint()..color = bColor);
    }
  }

  void _drawBayFloor(Canvas canvas, double w, double h, double groundH) {
    final floorTop = h - groundH;
    final floorRect = Rect.fromLTWH(0, floorTop, w, groundH);

    // Sleek wet slate floor
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF455A64), Color(0xFF263238), Color(0xFF1E272C)],
        ).createShader(floorRect),
    );

    // Yellow & black safety hazard caution stripe curb along top of floor
    const curbH = 10.0;
    const stripeW = 16.0;
    final curbRect = Rect.fromLTWH(0, floorTop, w, curbH);
    canvas.drawRect(curbRect, Paint()..color = const Color(0xFFFFCA28));

    final hazardPaint = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = stripeW * 0.5
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.clipRect(curbRect);
    for (double sx = -curbH; sx < w + curbH * 2; sx += stripeW) {
      canvas.drawLine(Offset(sx, floorTop + curbH), Offset(sx + curbH, floorTop), hazardPaint);
    }
    canvas.restore();

    // Central drainage grate
    final grateRect = Rect.fromCenter(
      center: Offset(w / 2, floorTop + groundH * 0.52),
      width: w * 0.72,
      height: 18,
    );
    final grateRRect = RRect.fromRectAndRadius(grateRect, const Radius.circular(5));
    // Grate pit glow
    canvas.drawRRect(grateRRect, Paint()..color = const Color(0xFF102027));
    // Water puddle sheen
    canvas.drawRRect(
      grateRRect,
      Paint()
        ..color = const Color(0xFF4DD0E1).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Grate bars
    final barPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 2.0;
    for (double bx = grateRect.left + 8; bx < grateRect.right - 8; bx += 8) {
      canvas.drawLine(Offset(bx, grateRect.top + 2), Offset(bx, grateRect.bottom - 2), barPaint);
    }

    // Tire guide stripes
    final tirePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final leftTrackX = w * 0.22;
    final rightTrackX = w * 0.78;
    canvas.drawLine(Offset(leftTrackX, floorTop + 14), Offset(leftTrackX, h - 8), tirePaint);
    canvas.drawLine(Offset(rightTrackX, floorTop + 14), Offset(rightTrackX, h - 8), tirePaint);
  }

  @override
  bool shouldRepaint(covariant _CarWashBayPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🚗 2. ROAD DRIVING SCENERY PAINTER (Parallax, Animals, Town, Car, Booster)
// ═══════════════════════════════════════════════════════════════════════════════

class _RoadDrivingSceneryPainter extends CustomPainter {
  final double scrollX;
  final double bouncePhase;
  final bool isBoosting;
  final _Vehicle vehicle;
  final List<_Sticker> stickers;
  final double jumpOffset;
  final List<_DrivingSpark> drivingSparks;
  final String? honkBubbleText;

  _RoadDrivingSceneryPainter({
    required this.scrollX,
    required this.bouncePhase,
    required this.isBoosting,
    required this.vehicle,
    required this.stickers,
    required this.jumpOffset,
    required this.drivingSparks,
    required this.honkBubbleText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sunny Sky, Smiling Sun, Clouds & Hot Air Balloon
    _drawSkyAndSun(canvas, w, h);

    // 2. Rolling Green Hills & Wind Turbines
    _drawHillsAndTurbines(canvas, w, h);

    // 3. Cheerful Roadside Scenery (Houses, Apple Trees, Cheering Animals)
    _drawRoadsideScenery(canvas, w, h);

    // 4. Asphalt Highway Road & Moving Center Stripes
    _drawHighway(canvas, w, h);

    // 5. Clean & Decorated Player Car
    _drawPlayerCar(canvas, w, h);

    // 6. Driving Particles (Sparkles, Stars, Booster Flame)
    _drawParticles(canvas);
  }

  void _drawSkyAndSun(Canvas canvas, double w, double h) {
    final skyH = h * 0.62;
    final skyRect = Rect.fromLTWH(0, 0, w, skyH);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF29B6F6), Color(0xFF81D4FA), Color(0xFFE1F5FE)],
        ).createShader(skyRect),
    );

    // Smiling Sun at top right
    final sunCenter = Offset(w * 0.82, h * 0.12);
    final rayCount = 12;
    final rayPaint = Paint()
      ..color = const Color(0xFFFFCA28).withValues(alpha: 0.6)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final ang = i * (2 * pi / rayCount) + bouncePhase * 0.25;
      final p1 = sunCenter + Offset(cos(ang) * 25, sin(ang) * 25);
      final p2 = sunCenter + Offset(cos(ang) * 35, sin(ang) * 35);
      canvas.drawLine(p1, p2, rayPaint);
    }
    // Sun body
    canvas.drawCircle(sunCenter, 22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(sunCenter, 19, Paint()..color = const Color(0xFFFFEE58));

    // Sun cute smiling eyes & blush
    canvas.drawCircle(sunCenter + const Offset(-6, -2), 2.5, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(sunCenter + const Offset(6, -2), 2.5, Paint()..color = const Color(0xFF5D4037));
    canvas.drawCircle(sunCenter + const Offset(-9, 4), 2.8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7));
    canvas.drawCircle(sunCenter + const Offset(9, 4), 2.8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7));
    // Smile mouth
    canvas.drawArc(
      Rect.fromCenter(center: sunCenter + const Offset(0, 3), width: 10, height: 8),
      0, pi, false,
      Paint()..color = const Color(0xFF5D4037)..strokeWidth = 1.8..style = PaintingStyle.stroke,
    );

    // Floating Clouds
    final cloudConfigs = [
      [w * 0.15, h * 0.08, 22.0],
      [w * 0.55, h * 0.16, 26.0],
      [w * 0.90, h * 0.22, 20.0],
    ];
    for (int i = 0; i < cloudConfigs.length; i++) {
      final cfg = cloudConfigs[i];
      final cx = (cfg[0] - scrollX * (0.10 + i * 0.03)) % (w + 120) - 60;
      final cy = cfg[1];
      final cr = cfg[2];
      _drawFluffyCloud(canvas, Offset(cx, cy), cr);
    }

    // Distant hot air balloon
    final balloonX = (w * 0.38 - scrollX * 0.06) % (w + 100) - 50;
    _drawHotAirBalloon(canvas, Offset(balloonX, h * 0.18));
  }

  void _drawFluffyCloud(Canvas canvas, Offset pos, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.92);
    canvas.drawCircle(pos, r, p);
    canvas.drawCircle(pos + Offset(-r * 0.6, r * 0.2), r * 0.75, p);
    canvas.drawCircle(pos + Offset(r * 0.6, r * 0.2), r * 0.75, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx - r * 0.8, pos.dy, r * 1.6, r * 0.6), Radius.circular(r * 0.3)),
      p,
    );
  }

  void _drawHotAirBalloon(Canvas canvas, Offset pos) {
    // Balloon envelope
    final balloonRect = Rect.fromCenter(center: pos, width: 24, height: 30);
    canvas.drawOval(
      balloonRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFFD740), Color(0xFF40C4FF)],
        ).createShader(balloonRect),
    );
    // Basket
    canvas.drawRect(
      Rect.fromLTWH(pos.dx - 3, pos.dy + 18, 6, 5),
      Paint()..color = const Color(0xFF8D6E63),
    );
  }

  void _drawHillsAndTurbines(Canvas canvas, double w, double h) {
    // Distant soft mountain ridge
    final hillPath1 = Path()..moveTo(0, h * 0.44);
    for (double x = 0; x <= w; x += 25) {
      final y = h * 0.44 + sin((x + scrollX * 0.15) * 0.012) * 16;
      hillPath1.lineTo(x, y);
    }
    // Seamlessly finish at exact right edge to prevent broken cut-off edge
    final endY1 = h * 0.44 + sin((w + scrollX * 0.15) * 0.012) * 16;
    hillPath1.lineTo(w, endY1);
    hillPath1.lineTo(w, h * 0.65);
    hillPath1.lineTo(0, h * 0.65);
    hillPath1.close();
    canvas.drawPath(hillPath1, Paint()..color = const Color(0xFFA5D6A7));

    // Foreground rolling green hills
    final hillPath2 = Path()..moveTo(0, h * 0.50);
    for (double x = 0; x <= w; x += 20) {
      final y = h * 0.50 + sin((x + scrollX * 0.35) * 0.016) * 14;
      hillPath2.lineTo(x, y);
    }
    // Seamlessly finish at exact right edge
    final endY2 = h * 0.50 + sin((w + scrollX * 0.35) * 0.016) * 14;
    hillPath2.lineTo(w, endY2);
    hillPath2.lineTo(w, h * 0.65);
    hillPath2.lineTo(0, h * 0.65);
    hillPath2.close();
    canvas.drawPath(hillPath2, Paint()..color = const Color(0xFF66BB6A));

    // Wind turbines on hills
    final turbineX1 = (w * 0.25 - scrollX * 0.25) % (w + 80) - 40;
    final turbineX2 = (w * 0.72 - scrollX * 0.25) % (w + 80) - 40;
    _drawWindTurbine(canvas, Offset(turbineX1, h * 0.42));
    _drawWindTurbine(canvas, Offset(turbineX2, h * 0.44));
  }

  void _drawWindTurbine(Canvas canvas, Offset base) {
    final polePaint = Paint()..color = Colors.white..strokeWidth = 2.5;
    final hubY = base.dy - 32;
    canvas.drawLine(base, Offset(base.dx, hubY), polePaint);
    canvas.drawCircle(Offset(base.dx, hubY), 3.5, Paint()..color = const Color(0xFFCFD8DC));

    // 3 spinning blades
    final bladePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final ang = i * (2 * pi / 3) + bouncePhase * 2.8;
      canvas.drawLine(
        Offset(base.dx, hubY),
        Offset(base.dx + cos(ang) * 18, hubY + sin(ang) * 18),
        bladePaint,
      );
    }
  }

  void _drawRoadsideScenery(Canvas canvas, double w, double h) {
    // Roadside grass strip
    final grassRect = Rect.fromLTWH(0, h * 0.54, w, h * 0.11);
    canvas.drawRect(grassRect, Paint()..color = const Color(0xFF4CAF50));

    // Clean, spacious single-item storybook elements (spaced at 240dp)
    const itemSpacing = 240.0;
    final items = [
      ('🏡', 38.0, -12.0, false), // Cozy House
      ('🐰', 34.0, -8.0, true),   // Cute Bunny
      ('🌳', 38.0, -12.0, false), // Green Apple Tree
      ('🐶', 34.0, -8.0, true),   // Cheering Puppy
      ('🌸', 32.0, -6.0, false),  // Beautiful Flower
      ('🐻', 34.0, -8.0, true),   // Friendly Bear
      ('🌲', 38.0, -12.0, false), // Tall Pine Tree
      ('🐱', 34.0, -8.0, true),   // Smiling Cat
    ];

    final totalW = items.length * itemSpacing;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final ix = (i * itemSpacing - scrollX * 0.85) % totalW - 50;
      if (ix < -70 || ix > w + 70) continue; // Skip off-screen

      final isAnimal = item.$4;
      final hop = isAnimal ? sin(bouncePhase * 1.5 + i) * 4.0 : 0.0;
      final iy = h * 0.53 + item.$3 + hop;

      final tp = TextPainter(
        text: TextSpan(text: item.$1, style: TextStyle(fontSize: item.$2)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(ix, iy));
    }
  }

  void _drawHighway(Canvas canvas, double w, double h) {
    final roadTop = h * 0.64;
    final roadH = h - roadTop;
    final roadRect = Rect.fromLTWH(0, roadTop, w, roadH);

    // Asphalt highway surface extending completely to the bottom
    canvas.drawRect(
      roadRect,
      Paint()..color = const Color(0xFF263238),
    );

    // Top and bottom yellow kerb boundary lines
    final linePaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3.5;
    canvas.drawLine(Offset(0, roadTop + 2), Offset(w, roadTop + 2), linePaint);
    canvas.drawLine(Offset(0, h - 2), Offset(w, h - 2), linePaint);

    // Center white dashed stripes (Rapidly moving right to left)
    const dashSpacing = 80.0;
    const dashLen = 42.0;
    final dashY = roadTop + roadH * 0.40;
    final dashOffset = (scrollX * 1.6) % dashSpacing;

    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    for (double dx = -dashSpacing; dx < w + dashSpacing; dx += dashSpacing) {
      final sx = dx - dashOffset;
      canvas.drawLine(Offset(sx, dashY), Offset(sx + dashLen, dashY), dashPaint);
    }
  }

  void _drawPlayerCar(Canvas canvas, double w, double h) {
    final roadTop = h * 0.64;
    final roadH = h - roadTop;
    final carW = (w * 0.60).clamp(220.0, 360.0);
    final carH = carW * 0.62;
    final carX = w * 0.28;
    final carY = roadTop + roadH * 0.38 - jumpOffset + sin(bouncePhase) * 3.5;

    canvas.save();
    canvas.translate(carX, carY);

    // Tilt forward slightly when boosting
    if (isBoosting) {
      canvas.rotate(0.04);
    }

    // ── Exhaust Booster Fire & Rainbow Wind Streaks (When boosting) ──
    if (isBoosting) {
      // Booster fire
      final fireX = -carW * 0.46;
      final fireY = carH * 0.16;
      final flameLen = 42.0 + sin(bouncePhase * 8) * 12.0;

      final flamePath = Path()
        ..moveTo(fireX, fireY - 6)
        ..lineTo(fireX - flameLen, fireY)
        ..lineTo(fireX, fireY + 6)
        ..close();

      canvas.drawPath(flamePath, Paint()..color = const Color(0xFFFF1744));
      canvas.drawPath(
        Path()
          ..moveTo(fireX, fireY - 3)
          ..lineTo(fireX - flameLen * 0.65, fireY)
          ..lineTo(fireX, fireY + 3)
          ..close(),
        Paint()..color = const Color(0xFFFFEA00),
      );

      // Rainbow wind streaks
      final streakColors = [Colors.red, Colors.orange, Colors.yellow, Colors.cyanAccent];
      for (int s = 0; s < 4; s++) {
        final sy = -carH * 0.2 + s * 14.0;
        final sx1 = -carW * 0.5 - s * 15.0;
        final sx2 = sx1 - 40.0;
        canvas.drawLine(
          Offset(sx1, sy), Offset(sx2, sy),
          Paint()
            ..color = streakColors[s].withValues(alpha: 0.75)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Clean Car Body Emoji (Flipped horizontally so Unicode vehicles face forward to the RIGHT 👉) ──
    final tpCar = TextPainter(
      text: TextSpan(
        text: vehicle.emoji,
        style: TextStyle(fontSize: carW * 0.92),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final carTopLeft = Offset(-tpCar.width / 2, -tpCar.height / 2);

    canvas.save();
    canvas.scale(-1.0, 1.0);
    tpCar.paint(canvas, carTopLeft);
    canvas.restore();

    // ── Decorated Stickers ──
    // In wash bay, car faced left (rel.dx = 0 at front).
    // Now car faces right (front is at +width/2, rear at -width/2).
    for (final s in stickers) {
      final sx = (0.5 - s.rel.dx) * tpCar.width;
      final sy = (s.rel.dy - 0.5) * tpCar.height;
      final tpSticker = TextPainter(
        text: TextSpan(
          text: s.emoji,
          style: const TextStyle(fontSize: 26),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpSticker.paint(canvas, Offset(sx - tpSticker.width / 2, sy - tpSticker.height / 2));
    }

    // ── Continuous Sparkles around clean car ──
    final sparklePhase = bouncePhase * 3;
    final starGlints = [
      Offset(-carW * 0.35, -carH * 0.28),
      Offset(carW * 0.28, -carH * 0.25),
      Offset(carW * 0.05, -carH * 0.38),
    ];
    for (int g = 0; g < starGlints.length; g++) {
      final sp = starGlints[g];
      final scale = (sin(sparklePhase + g * 2) * 0.35 + 0.65).clamp(0.2, 1.0);
      _drawGlintStar(canvas, sp, 7.0 * scale, Colors.white);
    }

    // ── Speech Bubble (Honk 빵빵!) ──
    if (honkBubbleText != null) {
      final bubbleW = 120.0;
      final bubbleH = 34.0;
      final bubbleX = -bubbleW / 2;
      final bubbleY = -carH * 0.5 - 46.0;

      final bubbleRect = Rect.fromLTWH(bubbleX, bubbleY, bubbleW, bubbleH);
      final bubbleRRect = RRect.fromRectAndRadius(bubbleRect, const Radius.circular(16));

      // Pointer
      final pointerPath = Path()
        ..moveTo(0, bubbleY + bubbleH)
        ..lineTo(-8, bubbleY + bubbleH + 8)
        ..lineTo(8, bubbleY + bubbleH)
        ..close();

      canvas.drawRRect(bubbleRRect.shift(const Offset(0, 3)), Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawRRect(bubbleRRect, Paint()..color = Colors.white);
      canvas.drawPath(pointerPath, Paint()..color = Colors.white);
      canvas.drawRRect(
        bubbleRRect,
        Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 2.5,
      );

      final tpHonk = TextPainter(
        text: TextSpan(
          text: honkBubbleText!,
          style: GoogleFonts.jua(
            fontSize: 14,
            color: const Color(0xFFD84315),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpHonk.paint(canvas, Offset(bubbleX + (bubbleW - tpHonk.width) / 2, bubbleY + (bubbleH - tpHonk.height) / 2));
    }

    canvas.restore();
  }

  void _drawGlintStar(Canvas canvas, Offset center, double r, Color c) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final ang = i * pi / 4;
      final rad = (i % 2 == 0) ? r : r * 0.35;
      final pt = center + Offset(cos(ang) * rad, sin(ang) * rad);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c);
  }

  void _drawParticles(Canvas canvas) {
    for (final s in drivingSparks) {
      final alpha = s.life.clamp(0.0, 1.0);
      if (s.isStar) {
        _drawGlintStar(canvas, s.pos, s.size * alpha, s.color.withValues(alpha: alpha));
      } else {
        canvas.drawCircle(
          s.pos,
          s.size * alpha,
          Paint()..color = s.color.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoadDrivingSceneryPainter oldDelegate) => true;
}


