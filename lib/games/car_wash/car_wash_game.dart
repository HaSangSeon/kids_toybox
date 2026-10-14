import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════


part 'models/car_wash_models.dart';
part 'widgets/car_wash_widgets.dart';
part 'painters/car_wash_painters.dart';

part 'widgets/car_wash_stage_widgets.dart';
part 'widgets/car_wash_driving_widgets.dart';
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

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
