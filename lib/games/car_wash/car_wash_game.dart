import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:ui' as ui;

part 'models/car_wash_models.dart';
part 'widgets/car_wash_widgets.dart';
part 'painters/car_wash_painters.dart';

class CarWashGame extends StatefulWidget {
  const CarWashGame({super.key});

  @override
  State<CarWashGame> createState() => _CarWashGameState();
}

class _CarWashGameState extends State<CarWashGame> with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _WashStep _step = _WashStep.selectCar;
  _Vehicle _car = _kVehicles[0];

  // Dirt / soap / wet / shine coverage grids (15×15 = 225 cells)
  static const int _gridN = 15;
  static const int _gridSize = _gridN * _gridN;
  final List<double> _dirtGrid  = List.filled(_gridSize, 0.0); // 1=dirty 0=clean
  final List<double> _soapGrid  = List.filled(_gridSize, 0.0); // 0=bare  1=soapy
  final List<double> _wetGrid   = List.filled(_gridSize, 0.0); // 0=dry   1=wet
  final List<double> _shineGrid = List.filled(_gridSize, 0.0); // 0=matte 1=glossy

  // Generous envelope covering the car emoji shape (roof/cabin + body/wheels)
  // Everything outside emoji non-transparent pixels is cleanly clipped by BlendMode.srcATop
  bool _isCarCell(int x, int y) {
    final rx = (x + 0.5) / _gridN;
    final ry = (y + 0.5) / _gridN;
    
    final isRoof = rx >= 0.24 && rx <= 0.76 && ry >= 0.18 && ry < 0.50;
    final isBody = rx >= 0.10 && rx <= 0.90 && ry >= 0.48 && ry <= 0.86;
    
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
        _dirtGrid[idx]  = inside ? 1.0 : 0.0;
        _soapGrid[idx]  = 0.0;
        _wetGrid[idx]   = 0.0;
        _shineGrid[idx] = 0.0;
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
  double get _rinseProgress => _gridProgress(_soapGrid, true);
  double get _dryProgress   => _gridProgress(_wetGrid, true);

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
    if (_stepComplete || _requireNewTouch) return;

    _playStepDragSound();

    switch (_step) {
      case _WashStep.water:
        _paintGridLocal(localPos, carSize, 4, _dirtGrid, -1.0);
        _spawnDroplets(localPos);
        break;
      case _WashStep.soap:
        _paintGridLocal(localPos, carSize, 4, _soapGrid, 1.0);
        _spawnBubbles(localPos);
        break;
      case _WashStep.rinse:
        _paintGridLocal(localPos, carSize, 4, _soapGrid, -1.0);
        _paintGridLocal(localPos, carSize, 4, _wetGrid, 1.0);
        _spawnDroplets(localPos);
        break;
      case _WashStep.dry:
        _paintGridLocal(localPos, carSize, 4, _wetGrid, -1.0);
        _paintGridLocal(localPos, carSize, 4, _shineGrid, 1.0);
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
  bool _requireNewTouch = false;

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
    AudioManager.instance.playCarWashStageComplete();
    setState(() {
      _stepComplete = true;
      _requireNewTouch = true;
    });
    _showBanner(bannerText, bannerColor);
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _stepComplete) {
        _advanceStep();
      }
    });
  }

  // 🌟 Relaxed threshold (85%) makes it easier to complete despite different car shapes
  static const double _advanceThreshold = 0.85;

  void _checkAdvance() {
    if (_stepComplete) return;
    switch (_step) {
      case _WashStep.water:
        if (_waterProgress >= _advanceThreshold) {
          // Perfectly clear any remaining specks of mud
          _dirtGrid.fillRange(0, _gridSize, 0.0);
          _triggerStepComplete('✨ 먼지 씻기 성공! 비누칠 단계로 넘어가요!', const Color(0xFF7E57C2));
        }
        break;
      case _WashStep.soap:
        if (_soapProgress >= _advanceThreshold) {
          // Fully envelop all car cells in fluffy foam
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _soapGrid[i] = 1.0;
          }
          _triggerStepComplete('🫧 거품 칠하기 성공! 헹구러 가요!', const Color(0xFF0288D1));
        }
        break;
      case _WashStep.rinse:
        if (_rinseProgress >= _advanceThreshold) {
          // Completely rinse all soap and leave car fully glistening wet
          _soapGrid.fillRange(0, _gridSize, 0.0);
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _wetGrid[i] = 1.0;
          }
          _triggerStepComplete('🌊 헹구기 성공! 닦기 단계로 넘어가요!', const Color(0xFFFF7043));
        }
        break;
      case _WashStep.dry:
        if (_dryProgress >= _advanceThreshold) {
          // Wipe all wetness away and leave brilliant diamond shine
          _wetGrid.fillRange(0, _gridSize, 0.0);
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _shineGrid[i] = 1.0;
          }
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
        case _WashStep.water:
          _dirtGrid.fillRange(0, _gridSize, 0.0);
          _step = _WashStep.soap;
          break;
        case _WashStep.soap:
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _soapGrid[i] = 1.0;
          }
          _step = _WashStep.rinse;
          break;
        case _WashStep.rinse:
          _soapGrid.fillRange(0, _gridSize, 0.0);
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _wetGrid[i] = 1.0;
          }
          _step = _WashStep.dry;
          break;
        case _WashStep.dry:
          _wetGrid.fillRange(0, _gridSize, 0.0);
          for (int i = 0; i < _gridSize; i++) {
            if (_isCarCell(i % _gridN, i ~/ _gridN)) _shineGrid[i] = 1.0;
          }
          _step = _WashStep.sticker;
          break;
        default:
          break;
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
    AudioManager.instance.playCarWashHighwayDrive();
  }

  void _honkCar() {
    AudioManager.instance.playVehicleSound(_car.id);
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
    AudioManager.instance.playCarWashHighwayDrive();
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

    final double displayProgress = _stepComplete
        ? 1.0
        : (progress / _advanceThreshold).clamp(0.0, 1.0);
    final int percentInt = (displayProgress * 100).round();

    final stepInfoMap = <_WashStep, (String, Color, Color)>{
      _WashStep.water: ('🚿 물로 먼지와 진흙 씻기', const Color(0xFF0288D1), const Color(0xFF4FC3F7)),
      _WashStep.soap:  ('🫧 골고루 비누 거품 칠하기', const Color(0xFF7E57C2), const Color(0xFFBA68C8)),
      _WashStep.rinse: ('🌊 깨끗하게 거품 헹구기', const Color(0xFF00ACC1), const Color(0xFF4DD0E1)),
      _WashStep.dry:   ('🧻 수건으로 물기 뽀송뽀송 닦기', const Color(0xFFFF7043), const Color(0xFFFFB74D)),
      _WashStep.sticker: ('🎀 예쁜 스티커로 꾸미기', const Color(0xFF26A69A), const Color(0xFF80CBC4)),
    };
    final currentInfo = stepInfoMap[_step] ?? ('🚗 신나는 드라이브', const Color(0xFF43E97B), const Color(0xFF06D6A0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
          child: SizedBox(
            height: 68,
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
                            height: isNextReady ? 46 : (isCurrent ? 42 : 34),
                            width:  isNextReady ? 46 : (isCurrent ? 42 : 34),
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
                                  blurRadius: 16, spreadRadius: 2,
                                ),
                              ] : isCurrent ? [
                                BoxShadow(color: s.$4.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                              ] : [],
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : Text(s.$1, style: TextStyle(fontSize: isNextReady ? 22 : (isCurrent ? 20 : 16))),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isNextReady ? '👆 탭!' : s.$2,
                            style: GoogleFonts.jua(
                              fontSize: isNextReady ? 11 : (isCurrent ? 11 : 10),
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

        // 🌟 Synchronized, Responsive, Crystal-clear Progress Bar with Percentage
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentInfo.$1,
                      style: GoogleFonts.jua(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _stepComplete ? const Color(0xFF43E97B) : currentInfo.$2,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (_stepComplete ? const Color(0xFF43E97B) : currentInfo.$2).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        _stepComplete ? '✨ 100% 완료!' : '$percentInt%',
                        style: GoogleFonts.jua(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final barW = boxConstraints.maxWidth * displayProgress;
                        return Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: barW,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _stepComplete
                                      ? [const Color(0xFF06D6A0), const Color(0xFF43E97B)]
                                      : [currentInfo.$2, currentInfo.$3],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 1,
                              left: 2,
                              right: 2,
                              height: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
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
                _requireNewTouch = false;
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
                _requireNewTouch = false;
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
              wetGrid: _wetGrid,
              shineGrid: _shineGrid,
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
      _WashStep.water: '💧 손가락으로 쓱쓱 문질러 먼지와 진흙을 깨끗이 씻어내요!',
      _WashStep.soap:  '🫧 자동차 구석구석 문질러 뽀글뽀글 거품을 내봐요!',
      _WashStep.rinse: '🌊 샤워기로 물을 뿌려 비누 거품을 깨끗이 헹궈내요!',
      _WashStep.dry:   '🧻 보들보들 수건으로 쓱싹 문질러 물기를 닦아내요!',
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

    return Positioned.fill(
      child: SafeArea(
        child: Stack(
          children: [
            // 1. Celebration / Wash Finish Modal Button (Top Right)
            Positioned(
              top: 90,
              right: 16,
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

            // 2. Vehicle Specific Horn / Siren Action Button (Bottom Left)
            Positioned(
              bottom: 32,
              left: 24,
              child: _buildDrivingToyButton(
                icon: hornIcon,
                label: hornLabel,
                bgColors: [const Color(0xFFFFF59D), const Color(0xFFFFD54F)],
                shadowColor: const Color(0xFFFFA000),
                textColor: const Color(0xFF5D4037),
                onTap: _honkCar,
              ),
            ),

            // 3. Speed Booster Button (Bottom Right)
            Positioned(
              bottom: 32,
              right: 24,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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

