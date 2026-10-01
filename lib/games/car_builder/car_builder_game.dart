import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:ui' as ui;

part 'models/car_builder_models.dart';
part 'painters/car_builder_painters.dart';

class CarBuilderGame extends StatefulWidget {
  const CarBuilderGame({super.key});

  @override
  State<CarBuilderGame> createState() => _CarBuilderGameState();
}

class _CarBuilderGameState extends State<CarBuilderGame>
    with TickerProviderStateMixin {
  _BuildPhase _phase = _BuildPhase.assemble;
  _ChassisPreset _selectedChassis = _kChassisList[0];
  Color _bodyColor = _kChassisList[0].defaultColor;
  _PartCategory _selectedCategory = _PartCategory.wheels;

  // 조립된 부품 리스트
  final List<_PlacedPart> _placedParts = [];
  // 각 차종별 독립 부품 보관함 (차종 변경 시 부품이 따라다니지 않도록 분리)
  final Map<String, List<_PlacedPart>> _chassisPlacedParts = {};
  String? _selectedPlacedPartId; // 선택된 부품

  // 시운전 애니메이션 컨트롤러
  late AnimationController _driveAnimCtrl;
  late AnimationController _sparkleCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _cloudCtrl;
  late AnimationController _sceneAnimCtrl; // 배경 동적 애니메이션 (파도, 별, 갈매기 등)
  late AnimationController _carBounceCtrl; // 차체 서스펜션 젤리 바운스 물리 효과

  // 파티클
  final List<_SparkleParticle> _sparkles = [];
  final List<_ConfettiDot> _confetti = [];
  final Random _rng = Random();

  double _driveProgress = 0.0;
  bool _showCelebration = false;
  bool _isCarCanvasHovered = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cloudCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _sceneAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _carBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _driveAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    _driveAnimCtrl.addListener(_onDriveUpdate);
    _sparkleCtrl.addListener(_updateSparkles);
    _confettiCtrl.addListener(_updateConfetti);

    _addDefaultStartingParts();
  }

  void _triggerCarBounce() {
    _carBounceCtrl.reset();
    _carBounceCtrl.forward();
  }

  List<_PlacedPart> _createDefaultPartsForChassis(String chassisId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final basicWheel = _kAllParts.firstWhere((p) => p.id == 'w_basic');
    final basicWin = _kAllParts.firstWhere((p) => p.id == 'win_pilot');

    switch (chassisId) {
      case 'truck':
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.72, 0.32), scale: 1.0),
        ];
      case 'sports':
        final sportWheel = _kAllParts.firstWhere((p) => p.id == 'w_sport', orElse: () => basicWheel);
        return [
          _PlacedPart(id: 'w1_$now', template: sportWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: sportWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.52, 0.32), scale: 1.0),
        ];
      case 'police':
        final siren = _kAllParts.firstWhere((p) => p.id == 'l_siren_b', orElse: () => basicWin);
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.56, 0.32), scale: 1.0),
          _PlacedPart(id: 'sir_${now + 3}', template: siren, relativePos: const Offset(0.54, 0.16), scale: 1.0),
        ];
      case 'ambulance':
        final siren = _kAllParts.firstWhere((p) => p.id == 'l_siren_r', orElse: () => basicWin);
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.68, 0.32), scale: 1.0),
          _PlacedPart(id: 'sir_${now + 3}', template: siren, relativePos: const Offset(0.64, 0.16), scale: 1.0),
        ];
      case 'monster':
        final monsterWheel = _kAllParts.firstWhere((p) => p.id == 'w_monster', orElse: () => basicWheel);
        return [
          _PlacedPart(id: 'w1_$now', template: monsterWheel, relativePos: const Offset(0.24, 0.74), scale: 1.25),
          _PlacedPart(id: 'w2_${now + 1}', template: monsterWheel, relativePos: const Offset(0.76, 0.74), scale: 1.25),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.56, 0.32), scale: 1.0),
        ];
      case 'bus':
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.74), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.74), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.72, 0.34), scale: 1.0),
        ];
      case 'rocket':
        final booster = _kAllParts.firstWhere((p) => p.id == 'b_rocket', orElse: () => basicWin);
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.52, 0.32), scale: 1.0),
          _PlacedPart(id: 'bst_${now + 3}', template: booster, relativePos: const Offset(0.12, 0.58), scale: 1.0),
        ];
      case 'sedan':
      default:
        return [
          _PlacedPart(id: 'w1_$now', template: basicWheel, relativePos: const Offset(0.24, 0.72), scale: 1.15),
          _PlacedPart(id: 'w2_${now + 1}', template: basicWheel, relativePos: const Offset(0.76, 0.72), scale: 1.15),
          _PlacedPart(id: 'win_${now + 2}', template: basicWin, relativePos: const Offset(0.56, 0.32), scale: 1.0),
        ];
    }
  }

  void _addDefaultStartingParts() {
    _placedParts.clear();
    final defaultParts = _createDefaultPartsForChassis(_selectedChassis.id);
    _placedParts.addAll(defaultParts);
    _chassisPlacedParts[_selectedChassis.id] = List<_PlacedPart>.from(defaultParts);
  }

  void _onChassisSelected(_ChassisPreset newChassis) {
    if (newChassis.id == _selectedChassis.id) return;

    AudioManager.instance.playCarBuilderSnap();
    HapticFeedback.lightImpact();
    _triggerCarBounce();

    setState(() {
      // 1. 현재 자동차의 부품 목록을 백업 저장
      _chassisPlacedParts[_selectedChassis.id] = List<_PlacedPart>.from(_placedParts);

      // 2. 새로운 차종으로 변경
      _selectedChassis = newChassis;
      _bodyColor = newChassis.defaultColor;
      _selectedPlacedPartId = null;

      // 3. 바뀐 자동차의 부품을 가져오거나, 처음 선택된 자동차라면
      //    이전 차의 부품이 따라오지 않고 해당 차종에 맞는 기본 부품으로 '처음부터 새로 시작'!
      _placedParts.clear();
      if (_chassisPlacedParts.containsKey(newChassis.id)) {
        _placedParts.addAll(_chassisPlacedParts[newChassis.id]!);
      } else {
        final newParts = _createDefaultPartsForChassis(newChassis.id);
        _placedParts.addAll(newParts);
        _chassisPlacedParts[newChassis.id] = List<_PlacedPart>.from(newParts);
      }
    });
  }

  @override
  void dispose() {
    _cloudCtrl.dispose();
    _sceneAnimCtrl.dispose();
    _carBounceCtrl.dispose();
    _driveAnimCtrl.dispose();
    _sparkleCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ─── PARTICLE UPDATES ───────────────────────────────────────────────────────

  void _spawnSparklesAt(Offset globalPos) {
    for (int i = 0; i < 10; i++) {
      _sparkles.add(_SparkleParticle(
        pos: globalPos + Offset((_rng.nextDouble() - 0.5) * 40, (_rng.nextDouble() - 0.5) * 40),
        vel: Offset((_rng.nextDouble() - 0.5) * 6, -_rng.nextDouble() * 5 - 2),
        life: 1.0,
        color: [Colors.amber, Colors.cyanAccent, Colors.pinkAccent, Colors.white, Colors.greenAccent][_rng.nextInt(5)],
      ));
    }
  }

  void _updateSparkles() {
    if (_sparkles.isEmpty) return;
    for (int i = _sparkles.length - 1; i >= 0; i--) {
      final s = _sparkles[i];
      s.pos += s.vel;
      s.life -= 0.05;
      if (s.life <= 0) _sparkles.removeAt(i);
    }
    if (mounted) setState(() {});
  }

  void _updateConfetti() {
    if (_phase != _BuildPhase.testDrive || !_showCelebration) return;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    if (_confetti.length < 70 && _rng.nextDouble() < 0.4) {
      _confetti.add(_ConfettiDot(
        pos: Offset(_rng.nextDouble() * w, -10),
        vel: Offset((_rng.nextDouble() - 0.5) * 3, _rng.nextDouble() * 4 + 2),
        color: [Colors.redAccent, Colors.amber, Colors.cyanAccent, Colors.pinkAccent, Colors.greenAccent, Colors.purpleAccent][_rng.nextInt(6)],
        size: 5 + _rng.nextDouble() * 6,
      ));
    }
    for (int i = _confetti.length - 1; i >= 0; i--) {
      final c = _confetti[i];
      c.pos += c.vel;
      if (c.pos.dy > h + 10) _confetti.removeAt(i);
    }
    if (mounted) setState(() {});
  }

  // ─── DRAG & DROP LOGIC ──────────────────────────────────────────────────────

  void _handlePartDropped(_PartTemplate template, Offset dropGlobalPos) {
    final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox == null) return;

    final localPos = canvasBox.globalToLocal(dropGlobalPos);
    final canvasSize = canvasBox.size;

    final relX = (localPos.dx / canvasSize.width).clamp(0.05, 0.95);
    final relY = (localPos.dy / canvasSize.height).clamp(0.05, 0.95);

    AudioManager.instance.playCarBuilderSnap();
    HapticFeedback.heavyImpact();
    _spawnSparklesAt(dropGlobalPos);
    _triggerCarBounce();

    setState(() {
      final newPart = _PlacedPart(
        id: 'part_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999)}',
        template: template,
        relativePos: Offset(relX, relY),
        scale: 1.0,
      );
      _placedParts.add(newPart);
      _selectedPlacedPartId = newPart.id;
      _isCarCanvasHovered = false;
    });
  }

  void _removePlacedPart(String id) {
    AudioManager.instance.playPop();
    HapticFeedback.mediumImpact();
    _triggerCarBounce();
    setState(() {
      _placedParts.removeWhere((p) => p.id == id);
      if (_selectedPlacedPartId == id) _selectedPlacedPartId = null;
    });
  }

  void _clearAllParts() {
    AudioManager.instance.playPop();
    _triggerCarBounce();
    setState(() {
      _placedParts.clear();
      _selectedPlacedPartId = null;
      _chassisPlacedParts[_selectedChassis.id] = [];
    });
  }

  // ─── TEST DRIVE ────────────────────────────────────────────────────────────

  void _startTestDrive() {
    // 1단계: 시동 키 돌리는 소리 (치키키킥- 부릉!)
    AudioManager.instance.playEffect('audio/car_ignition_start.wav');
    HapticFeedback.heavyImpact();

    setState(() {
      _phase = _BuildPhase.testDrive;
      _selectedPlacedPartId = null;
      _driveProgress = 0.0;
      _showCelebration = false;
      _confetti.clear();
    });

    _driveAnimCtrl.reset();
    _driveAnimCtrl.forward();

    // 2단계 (400ms 후): 힘찬 가속 질주 사운드 + 햅틱 피드백
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || _phase != _BuildPhase.testDrive) return;
      final vehicleSound = switch (_selectedChassis.id) {
        'police' => 'police',
        'monster' => 'monster',
        'sports' => 'racing',
        'bus' => 'bus',
        'ambulance' => 'ambulance',
        _ => 'car',
      };
      AudioManager.instance.playCarWashHighwayDrive();
      HapticFeedback.mediumImpact();
    });
  }

  void _onDriveUpdate() {
    if (!mounted) return;
    setState(() {
      _driveProgress = _driveAnimCtrl.value;
    });
    if (_driveAnimCtrl.isCompleted && !_showCelebration) {
      setState(() => _showCelebration = true);
      AudioManager.instance.playTraceSuccess();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) AudioManager.instance.playChime();
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _honkInDrive() {
    HapticFeedback.mediumImpact();
    final hasSiren = _placedParts.any((p) => p.template.isSiren);

    if (hasSiren) {
      AudioManager.instance.playVehicleSound('police');
    } else {
      final vehicleSound = switch (_selectedChassis.id) {
        'police' => 'police',
        'ambulance' => 'ambulance',
        'bus' => 'bus',
        'monster' => 'monster',
        'truck' => 'suv',
        'sports' => 'racing',
        'rocket' => 'racing',
        _ => 'car',
      };
      AudioManager.instance.playVehicleSound(vehicleSound);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildSkyBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: _phase == _BuildPhase.assemble
                      ? _buildWorkshopAssembleView()
                      : _buildTestDriveView(),
                ),
              ],
            ),
          ),

          if (_sparkles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _SparklePainter(sparkles: _sparkles)),
              ),
            ),

          if (_confetti.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ConfettiPainter(confetti: _confetti)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkyBackground() {
    final isTestDrive = _phase == _BuildPhase.testDrive;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isTestDrive
              ? const [Color(0xFF60A5FA), Color(0xFFA5E6FF), Color(0xFF90EE90)]
              : const [Color(0xFF87CEEB), Color(0xFFC8E6FF), Color(0xFFFFF9E6)],
        ),
      ),
      child: AnimatedBuilder(
        animation: _cloudCtrl,
        builder: (context, child) {
          final w = MediaQuery.of(context).size.width;
          final p = _cloudCtrl.value;
          return Stack(
            children: [
              Positioned(
                top: 15, right: 25,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD166),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFD166).withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 4)],
                  ),
                ),
              ),
              Positioned(top: 25, left: (p * (w + 100)) - 50, child: const Text('☁️', style: TextStyle(fontSize: 36))),
              Positioned(top: 60, left: (((p + 0.5) % 1.0) * (w + 80)) - 40, child: const Text('☁️', style: TextStyle(fontSize: 28))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AudioManager.instance.playClick();
                if (_phase == _BuildPhase.testDrive) {
                  setState(() => _phase = _BuildPhase.assemble);
                } else {
                  Navigator.of(context).pop();
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, color: Color(0xFFFF9F1C), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _phase == _BuildPhase.testDrive ? '조립소로' : '로비',
                      style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF2B2D42)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Title badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF06D6A0), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF06D6A0).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Text(
              _phase == _BuildPhase.assemble ? '🔧 드래그해서 차 만들기!' : '🏁 부릉부릉 시운전!',
              style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2B2D42)),
            ),
          ),

          const Spacer(),

          // Sound toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => AudioManager.instance.toggleSound()),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                ),
                child: Icon(
                  AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFFFF9F1C), size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORKSHOP ASSEMBLE VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWorkshopAssembleView() {
    return Column(
      children: [
        // 1. Top Controls (Chassis Preset Picker)
        _buildChassisBar(),

        // 2. Workbench Interactive Car Canvas (DragTarget)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: _buildWorkbenchCanvas(),
          ),
        ),

        // 3. Bottom Drag & Drop Parts Drawer
        _buildBottomPartsDrawer(),
      ],
    );
  }

  Widget _buildChassisBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // 차종 선택 버튼 목록 (혼란 방지를 위해 색상 선택 제거)
          ..._kChassisList.map((chassis) {
            final isSelected = chassis.id == _selectedChassis.id;
            return GestureDetector(
              onTap: () => _onChassisSelected(chassis),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF9F1C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF9F1C) : const Color(0xFFE2E8F0),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: const Color(0xFFFF9F1C).withValues(alpha: 0.35), blurRadius: 6)]
                      : null,
                ),
                child: Row(
                  children: [
                    Text(chassis.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(chassis.name, style: GoogleFonts.jua(
                      fontSize: 12,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    )),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkbenchCanvas() {
    final selectedPart = _selectedPlacedPartId != null
        ? _placedParts.where((p) => p.id == _selectedPlacedPartId).firstOrNull
        : null;

    return DragTarget<_PartTemplate>(
      onWillAcceptWithDetails: (_) {
        setState(() => _isCarCanvasHovered = true);
        return true;
      },
      onLeave: (_) {
        setState(() => _isCarCanvasHovered = false);
      },
      onAcceptWithDetails: (details) {
        _handlePartDropped(details.data, details.offset);
      },
      builder: (context, candidateData, rejectedData) {
        final sceneTheme = _kChassisScene[_selectedChassis.id] ?? _SceneTheme.coastal;
        return Container(
          key: _canvasKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isCarCanvasHovered ? const Color(0xFF06D6A0) : Colors.transparent,
              width: _isCarCanvasHovered ? 3.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: _isCarCanvasHovered
                    ? const Color(0xFF06D6A0).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 0. Tap canvas background to complete part editing
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_selectedPlacedPartId != null) {
                        AudioManager.instance.playClick();
                        setState(() => _selectedPlacedPartId = null);
                      }
                    },
                  ),
                ),

                // 1. Live Animated Scene background (Wave, Seagulls, Stars, etc.)
                AnimatedBuilder(
                  animation: _sceneAnimCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _SceneBackgroundPainter(
                        theme: sceneTheme,
                        animValue: _sceneAnimCtrl.value,
                        isHovered: _isCarCanvasHovered,
                      ),
                    );
                  },
                ),

                // 2. Base Chassis Illustration with Suspension Spring Bounce
                Center(
                  child: AnimatedBuilder(
                    animation: _carBounceCtrl,
                    builder: (context, child) {
                      // 젤리 탄성 바운스 커브 (0.94 -> 1.06 -> 1.0)
                      final val = _carBounceCtrl.value;
                      final scale = 1.0 + sin(val * pi * 2) * (1.0 - val) * 0.08;
                      final bounceY = -sin(val * pi * 2) * (1.0 - val) * 10;
                      return Transform.translate(
                        offset: Offset(0, bounceY),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        // 차체 터치 시 빵빵 사운드 + 통통 바운스
                        _triggerCarBounce();
                        HapticFeedback.mediumImpact();
                        AudioManager.instance.playCarBuilderSnap();
                      },
                      child: SizedBox(
                        width: 290,
                        height: 190,
                        child: CustomPaint(
                          painter: _ChassisPainter(
                            chassisId: _selectedChassis.id,
                            color: _bodyColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. User-Placed Interactive Drag-and-Drop Parts with Spring Bounce
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasW = constraints.maxWidth;
                      final canvasH = constraints.maxHeight;

                      return AnimatedBuilder(
                        animation: _carBounceCtrl,
                        builder: (context, child) {
                          final val = _carBounceCtrl.value;
                          final scale = 1.0 + sin(val * pi * 2) * (1.0 - val) * 0.08;
                          final bounceY = -sin(val * pi * 2) * (1.0 - val) * 10;
                          return Transform.translate(
                            offset: Offset(0, bounceY),
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          );
                        },
                        child: Stack(
                          children: _placedParts.map((placed) {
                            final isSelected = placed.id == _selectedPlacedPartId;
                            final partW = placed.template.defaultWidth * placed.scale;
                            final partH = placed.template.defaultHeight * placed.scale;
                            final partPxX = placed.relativePos.dx * canvasW;
                            final partPxY = placed.relativePos.dy * canvasH;

                            return Positioned(
                              left: partPxX - partW / 2,
                              top: partPxY - partH / 2,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  AudioManager.instance.playCarBuilderSnap();
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedPlacedPartId = isSelected ? null : placed.id;
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    _selectedPlacedPartId = placed.id;
                                    final newX = ((partPxX + details.delta.dx) / canvasW).clamp(0.05, 0.95);
                                    final newY = ((partPxY + details.delta.dy) / canvasH).clamp(0.05, 0.95);
                                    placed.relativePos = Offset(newX, newY);
                                  });
                                },
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: partW,
                                      height: partH,
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: const Color(0xFF06D6A0), width: 2.5),
                                              color: const Color(0xFF06D6A0).withValues(alpha: 0.18),
                                            )
                                          : null,
                                      child: Transform.rotate(
                                        angle: placed.rotation,
                                        child: Transform.scale(
                                          scale: placed.scale,
                                          child: Transform.flip(
                                            flipX: placed.isFlipped,
                                            child: Center(
                                              child: Text(
                                                placed.template.emoji,
                                                style: TextStyle(fontSize: placed.template.defaultWidth * 0.72),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 선택된 부품 우측 상단 바로 완료(체크) 버튼
                                    if (isSelected)
                                      Positioned(
                                        top: -10,
                                        right: -10,
                                        child: GestureDetector(
                                          onTap: () {
                                            AudioManager.instance.playClick();
                                            HapticFeedback.lightImpact();
                                            setState(() => _selectedPlacedPartId = null);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF06D6A0),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 2)),
                                              ],
                                            ),
                                            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // 4. Dedicated High-Accessibility Floating Action Bar for Selected Part (한눈에 완료까지 100% 다 보임)
                if (selectedPart != null)
                  Positioned(
                    top: 8,
                    left: 6,
                    right: 6,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. 선택 부품 이모지 뱃지
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(selectedPart.template.emoji, style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 5),

                            // 2. 🔄 회전 버튼
                            _buildToolButton(
                              label: '회전',
                              icon: Icons.rotate_right_rounded,
                              color: const Color(0xFF38BDF8),
                              onTap: () {
                                AudioManager.instance.playClick();
                                HapticFeedback.lightImpact();
                                setState(() => selectedPart.rotation += pi / 4);
                              },
                            ),
                            const SizedBox(width: 4),

                            // 3. 🔍 크기 버튼
                            _buildToolButton(
                              label: '크기',
                              icon: Icons.aspect_ratio_rounded,
                              color: const Color(0xFFFFCA28),
                              onTap: () {
                                AudioManager.instance.playClick();
                                HapticFeedback.lightImpact();
                                setState(() {
                                  if (selectedPart.scale >= 1.5) {
                                    selectedPart.scale = 0.8;
                                  } else {
                                    selectedPart.scale += 0.3;
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 4),

                            // 4. ↔️ 반전 버튼
                            _buildToolButton(
                              label: '반전',
                              icon: Icons.flip_rounded,
                              color: const Color(0xFFA855F7),
                              onTap: () {
                                AudioManager.instance.playClick();
                                HapticFeedback.lightImpact();
                                setState(() => selectedPart.isFlipped = !selectedPart.isFlipped);
                              },
                            ),
                            const SizedBox(width: 4),

                            // 5. 🗑️ 삭제 버튼
                            _buildToolButton(
                              label: '삭제',
                              icon: Icons.delete_outline_rounded,
                              color: const Color(0xFFFF5964),
                              onTap: () => _removePlacedPart(selectedPart.id),
                            ),
                            const SizedBox(width: 6),

                            // 6. ✅ 완료 버튼 (언제나 맨 우측에 눈에 띄는 초록색으로 확실히 표시!)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedPlacedPartId = null);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06D6A0),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF06D6A0).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 17),
                                      const SizedBox(width: 3),
                                      Text(
                                        '완료',
                                        style: GoogleFonts.jua(
                                          fontSize: 13,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                    ),
                  ),

                // 5. Bottom Quick Action Buttons (Clear All & Test Drive)
                if (selectedPart == null)
                  Positioned(
                    top: 10, right: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_placedParts.isNotEmpty)
                          GestureDetector(
                            onTap: _clearAllParts,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFF5964), width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5964), size: 16),
                                  const SizedBox(width: 2),
                                  Text('비우기', style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFFFF5964))),
                                ],
                              ),
                            ),
                          ),

                        // Test Drive Launch Button
                        GestureDetector(
                          onTap: _startTestDrive,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: KidsTheme.toyDecoration(color: const Color(0xFF06D6A0), borderRadius: 20),
                            child: Row(
                              children: [
                                const Text('🏁', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text('시운전 출발! ➡️', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Guide hint badge
                if (_placedParts.length <= 3 && selectedPart == null)
                  Positioned(
                    bottom: 10, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '👇 아래 부품을 손으로 끌어다 붙여보세요!',
                        style: GoogleFonts.jua(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 2),
              Text(
                label,
                style: GoogleFonts.jua(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPartsDrawer() {
    final filteredParts = _kAllParts.where((p) => p.category == _selectedCategory).toList();

    return Container(
      height: 165,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category selector tabs with vibrant kid-friendly pills
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: _PartCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                final catInfo = _getCategoryInfo(cat);
                final themeColor = _getCategoryColor(cat);

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? themeColor : const Color(0xFFE2E8F0),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: themeColor.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(catInfo.$1, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            catInfo.$2,
                            style: GoogleFonts.jua(
                              fontSize: isSelected ? 13 : 12,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

          const SizedBox(height: 6),

          // Animated Item Tray (Shows items belonging to the selected category!)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                );
              },
              child: ListView.separated(
                key: ValueKey<String>('tray_${_selectedCategory.name}'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: filteredParts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final part = filteredParts[index];
                  return _buildDraggablePartTile(part);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePartTile(_PartTemplate part) {
    return Draggable<_PartTemplate>(
      data: part,
      affinity: Axis.vertical,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.35,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06D6A0).withValues(alpha: 0.65),
                  blurRadius: 20,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Text(part.emoji, style: const TextStyle(fontSize: 48)),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildPartTrayCard(part),
      ),
      child: GestureDetector(
        // 원터치 탭으로도 차체에 바로 장착 가능!
        onTap: () => _autoAttachPart(part),
        child: _buildPartTrayCard(part),
      ),
    );
  }

  void _autoAttachPart(_PartTemplate part) {
    // 카테고리별 스마트 기본 위치 선정
    final autoPos = switch (part.category) {
      _PartCategory.wheels => const Offset(0.50, 0.72),
      _PartCategory.booster => const Offset(0.12, 0.54),
      _PartCategory.lights => const Offset(0.86, 0.52),
      _PartCategory.bumper => const Offset(0.90, 0.60),
      _PartCategory.roof => const Offset(0.46, 0.16),
      _PartCategory.window => const Offset(0.52, 0.30),
      _PartCategory.stickers => const Offset(0.48, 0.54),
    };

    AudioManager.instance.playCarBuilderSnap();
    HapticFeedback.mediumImpact();
    _triggerCarBounce();

    final RenderBox? canvasBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (canvasBox != null) {
      final center = canvasBox.localToGlobal(Offset(canvasBox.size.width * autoPos.dx, canvasBox.size.height * autoPos.dy));
      _spawnSparklesAt(center);
    }

    setState(() {
      final newPart = _PlacedPart(
        id: 'part_${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(999)}',
        template: part,
        relativePos: autoPos,
        scale: 1.0,
      );
      _placedParts.add(newPart);
      _selectedPlacedPartId = newPart.id;
    });
  }

  Widget _buildPartTrayCard(_PartTemplate part) {
    final themeColor = _getCategoryColor(part.category);

    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(part.emoji, style: const TextStyle(fontSize: 34)),
          ),
          const SizedBox(height: 3),
          Text(
            part.name,
            style: GoogleFonts.jua(fontSize: 10.5, color: const Color(0xFF334155)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(_PartCategory cat) {
    return switch (cat) {
      _PartCategory.wheels => const Color(0xFF3B82F6),   // 파랑
      _PartCategory.booster => const Color(0xFFF97316),  // 오렌지
      _PartCategory.lights => const Color(0xFFEAB308),   // 노랑
      _PartCategory.bumper => const Color(0xFF10B981),   // 그린
      _PartCategory.roof => const Color(0xFF8B5CF6),     // 보라
      _PartCategory.window => const Color(0xFFEC4899),   // 핑크
      _PartCategory.stickers => const Color(0xFFEF4444), // 레드
    };
  }

  (String, String) _getCategoryInfo(_PartCategory cat) {
    return switch (cat) {
      _PartCategory.wheels => ('🛞', '바퀴'),
      _PartCategory.booster => ('🚀', '부스터/날개'),
      _PartCategory.lights => ('💡', '라이트/사이렌'),
      _PartCategory.bumper => ('🛡️', '범퍼/도구'),
      _PartCategory.roof => ('👑', '루프/장식'),
      _PartCategory.window => ('🪟', '창문/조종사'),
      _PartCategory.stickers => ('🎨', '스티커'),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEST DRIVE VIEW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTestDriveView() {
    final hasBooster = _placedParts.any((p) => p.template.isBooster);
    final hasSiren = _placedParts.any((p) => p.template.isSiren);
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    // 자연스럽고 힘찬 전진 주행 모션 (출발 시 부드럽게 가속하여 중앙 전방으로 진입)
    final carX = _driveProgress < 0.15
        ? (-120.0 + (_driveProgress / 0.15) * (screenW * 0.22 + 120.0))
        : (screenW * 0.22 + sin(_driveProgress * pi * 4) * 12);
    final carY = screenH * 0.16 + sin(_driveProgress * 32) * 2.5;

    return GestureDetector(
      onTap: _showCelebration ? null : _honkInDrive,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Scrolling Realistic Parallax Road Scenery (City & Nature)
          CustomPaint(
            painter: _TestDrivePainter(
              progress: _driveProgress,
              cloudProgress: _cloudCtrl.value,
            ),
          ),

          // 2. Custom Car with all user-placed parts driving on road
          if (!_showCelebration)
            Positioned(
              bottom: carY,
              left: carX,
              child: SizedBox(
                width: 230,
                height: 145,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Dynamic Headlight Beam Casting Forward onto Road
                    Positioned(
                      left: 170,
                      top: 40,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(180, 80),
                          painter: _HeadlightBeamPainter(),
                        ),
                      ),
                    ),

                    // Rear Exhaust & Speed Dust Puffs (차 뒤쪽으로 연기/불꽃이 뿜어지도록 flipX 적용)
                    Positioned(
                      left: -28,
                      bottom: 22,
                      child: IgnorePointer(
                        child: Transform.flip(
                          flipX: true, // 이모지 좌우 반전하여 연기 꼬리가 차 뒤(왼쪽 바깥)로 뿜어지게 함!
                          child: Text(
                            hasBooster ? '💨🔥' : '💨',
                            style: TextStyle(
                              fontSize: 18 + sin(_driveProgress * 28).abs() * 8,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Base Chassis
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ChassisPainter(
                          chassisId: _selectedChassis.id,
                          color: _bodyColor,
                        ),
                      ),
                    ),

                    // User Placed Parts with Forward Drive Animations
                    ..._placedParts.map((placed) {
                      final partW = placed.template.defaultWidth * placed.scale * 0.75;
                      final partH = placed.template.defaultHeight * placed.scale * 0.75;
                      final x = placed.relativePos.dx * 230 - partW / 2;
                      final y = placed.relativePos.dy * 145 - partH / 2;

                      // 바퀴는 자연스러운 전진 회전 (시계방향 순회전)
                      final rotationAngle = placed.template.isWheel
                          ? (_driveProgress * pi * 14)
                          : placed.rotation;

                      // 사이렌 경광등 플래시
                      final isSirenOn = placed.template.isSiren && ((_driveProgress * 16).toInt() % 2 == 0);

                      return Positioned(
                        left: x,
                        top: y,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // 부스터 파이어 이펙트 (차 뒤쪽으로 뿜어지도록 flipX)
                            if (placed.template.isBooster)
                              Positioned(
                                left: -24,
                                child: Transform.flip(
                                  flipX: true,
                                  child: Text('🔥', style: TextStyle(fontSize: 18 + sin(_driveProgress * 30).abs() * 8)),
                                ),
                              ),

                            // 사이렌 글로우
                            if (isSirenOn)
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent.withValues(alpha: 0.5),
                                  boxShadow: [
                                    BoxShadow(color: Colors.redAccent.withValues(alpha: 0.7), blurRadius: 14, spreadRadius: 4),
                                  ],
                                ),
                              ),

                            Transform.rotate(
                              angle: rotationAngle,
                              child: Transform.scale(
                                scale: placed.scale * 0.75,
                                child: Transform.flip(
                                  flipX: placed.isFlipped,
                                  child: Text(placed.template.emoji, style: const TextStyle(fontSize: 32)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          // Honk & Action Hint
          if (!_showCelebration)
            Positioned(
              bottom: 25, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6)],
                  ),
                  child: Text(
                    hasSiren
                        ? '🚨 화면을 탭해서 삐뽀삐뽀 사이렌을 울려요!'
                        : hasBooster
                            ? '🚀 화면을 탭해서 슈퍼 부스터를 발사해요!'
                            : '📢 화면을 탭해서 빵빵 경적을 울려요!',
                    style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF2B2D42)),
                  ),
                ),
              ),
            ),

          // 3. Completion Celebration Modal
          if (_showCelebration)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(24),
                  decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 28),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 54)),
                        const SizedBox(height: 6),
                        Text('세상에 하나뿐인 자동차!', style: GoogleFonts.jua(fontSize: 24, color: const Color(0xFFFF9F1C))),
                        const SizedBox(height: 4),
                        Text('내가 만든 멋진 자동차가 완주했어요! 🎉', style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF64748B))),
                        const SizedBox(height: 12),

                        // Mini Preview
                        Container(
                          width: 200,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _ChassisPainter(
                                    chassisId: _selectedChassis.id,
                                    color: _bodyColor,
                                  ),
                                ),
                              ),
                              ..._placedParts.map((placed) {
                                final partW = placed.template.defaultWidth * placed.scale * 0.6;
                                final partH = placed.template.defaultHeight * placed.scale * 0.6;
                                final x = placed.relativePos.dx * 200 - partW / 2;
                                final y = placed.relativePos.dy * 110 - partH / 2;
                                return Positioned(
                                  left: x, top: y,
                                  child: Transform.rotate(
                                    angle: placed.rotation,
                                    child: Transform.flip(
                                      flipX: placed.isFlipped,
                                      child: Text(placed.template.emoji, style: const TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                setState(() {
                                  _phase = _BuildPhase.assemble;
                                  _showCelebration = false;
                                  _confetti.clear();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: KidsTheme.toyDecoration(color: const Color(0xFFFF9F1C), borderRadius: 18),
                                child: Text('🔧 더 조립하기', style: GoogleFonts.jua(fontSize: 14, color: Colors.white)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: KidsTheme.toyDecoration(color: const Color(0xFF06D6A0), borderRadius: 18),
                                child: Text('🏠 로비로', style: GoogleFonts.jua(fontSize: 14, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CUSTOM PAINTERS — DISTINCT RICH CHASSIS DRAWINGS
// ═══════════════════════════════════════════════════════════════════════════════

/// 작업대 배경 격자 & 바닥 그림자
// ── Scene Background Painter (Living Dynamic Environment) ────────────────────
