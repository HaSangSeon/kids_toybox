import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum _BuildPhase { assemble, testDrive }

enum _PartCategory { wheels, booster, lights, bumper, roof, window, stickers }

/// 부품 템플릿 정보
class _PartTemplate {
  final String id;
  final String name;
  final String emoji;
  final _PartCategory category;
  final double defaultWidth;
  final double defaultHeight;
  final bool isWheel; // 바퀴 여부 (시운전 시 회전)
  final bool isBooster; // 부스터 여부 (시운전 시 불꽃)
  final bool isSiren; // 사이렌 여부 (시운전 시 깜빡임)

  const _PartTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.defaultWidth = 52,
    this.defaultHeight = 52,
    this.isWheel = false,
    this.isBooster = false,
    this.isSiren = false,
  });
}

/// 차체에 실제로 붙여진 부품 인스턴스
class _PlacedPart {
  final String id;
  final _PartTemplate template;
  Offset relativePos; // (0.0 ~ 1.0, 0.0 ~ 1.0) 차체 영역 내 비율 좌표
  double scale;
  double rotation; // 라디안
  bool isFlipped;

  _PlacedPart({
    required this.id,
    required this.template,
    required this.relativePos,
    this.scale = 1.0,
  })  : rotation = 0.0,
        isFlipped = false;
}

/// 차체 기본형
class _ChassisPreset {
  final String id;
  final String name;
  final String emoji;
  final Color defaultColor;

  const _ChassisPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.defaultColor,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATIC DATA
// ═══════════════════════════════════════════════════════════════════════════════

const List<_ChassisPreset> _kChassisList = [
  _ChassisPreset(id: 'sedan', name: '승용차', emoji: '🚗', defaultColor: Color(0xFFFF5964)),
  _ChassisPreset(id: 'truck', name: '트럭', emoji: '🛻', defaultColor: Color(0xFF38BDF8)),
  _ChassisPreset(id: 'sports', name: '스포츠카', emoji: '🏎️', defaultColor: Color(0xFFFF3366)),
  _ChassisPreset(id: 'police', name: '경찰차', emoji: '🚔', defaultColor: Color(0xFF1E293B)),
  _ChassisPreset(id: 'ambulance', name: '구급차', emoji: '🚑', defaultColor: Color(0xFFFFFFFF)),
  _ChassisPreset(id: 'monster', name: '몬스터', emoji: '🚙', defaultColor: Color(0xFF06D6A0)),
  _ChassisPreset(id: 'bus', name: '버스', emoji: '🚌', defaultColor: Color(0xFFFFCA28)),
  _ChassisPreset(id: 'rocket', name: '로켓차', emoji: '🚀', defaultColor: Color(0xFF8338EC)),
];

const List<Color> _kBodyColorPalette = [
  Color(0xFFFF5964), // 빨강
  Color(0xFFFF9F1C), // 주황
  Color(0xFFFFD166), // 노랑
  Color(0xFF06D6A0), // 초록
  Color(0xFF38BDF8), // 하늘
  Color(0xFF8338EC), // 보라
  Color(0xFFFF6EB4), // 핑크
  Color(0xFF1E293B), // 다크
  Color(0xFFFFFFFF), // 화이트
];

const List<_PartTemplate> _kAllParts = [
  // 🛞 바퀴류 (시운전 시 씽씽 굴러감!)
  _PartTemplate(id: 'w_basic', name: '기본 바퀴', emoji: '🛞', category: _PartCategory.wheels, defaultWidth: 48, defaultHeight: 48, isWheel: true),
  _PartTemplate(id: 'w_sport', name: '스포츠 휠', emoji: '🔘', category: _PartCategory.wheels, defaultWidth: 50, defaultHeight: 50, isWheel: true),
  _PartTemplate(id: 'w_monster', name: '빅 몬스터 휠', emoji: '🟤', category: _PartCategory.wheels, defaultWidth: 58, defaultHeight: 58, isWheel: true),
  _PartTemplate(id: 'w_star', name: '별 휠', emoji: '⭐', category: _PartCategory.wheels, defaultWidth: 48, defaultHeight: 48, isWheel: true),
  _PartTemplate(id: 'w_rainbow', name: '무지개 휠', emoji: '🌈', category: _PartCategory.wheels, defaultWidth: 50, defaultHeight: 50, isWheel: true),
  _PartTemplate(id: 'w_fire', name: '불꽃 바퀴', emoji: '🔥', category: _PartCategory.wheels, defaultWidth: 48, defaultHeight: 48, isWheel: true),
  _PartTemplate(id: 'w_donut', name: '도넛 바퀴', emoji: '🍩', category: _PartCategory.wheels, defaultWidth: 46, defaultHeight: 46, isWheel: true),
  _PartTemplate(id: 'w_track', name: '탱크 궤도', emoji: '⛓️', category: _PartCategory.wheels, defaultWidth: 60, defaultHeight: 40, isWheel: true),

  // 🚀 부스터 / 엔진 / 날개
  _PartTemplate(id: 'b_rocket', name: '로켓 부스터', emoji: '🚀', category: _PartCategory.booster, defaultWidth: 52, defaultHeight: 52, isBooster: true),
  _PartTemplate(id: 'b_exhaust', name: '터보 배기통', emoji: '💨', category: _PartCategory.booster, defaultWidth: 46, defaultHeight: 46, isBooster: true),
  _PartTemplate(id: 'b_wing', name: '제트 날개', emoji: '🪽', category: _PartCategory.booster, defaultWidth: 58, defaultHeight: 46),
  _PartTemplate(id: 'b_propeller', name: '프로펠러', emoji: '🚁', category: _PartCategory.booster, defaultWidth: 50, defaultHeight: 50),
  _PartTemplate(id: 'b_spoiler', name: '레이싱 날개', emoji: '🚩', category: _PartCategory.booster, defaultWidth: 48, defaultHeight: 42),
  _PartTemplate(id: 'b_engine', name: '슈퍼 엔진', emoji: '⚙️', category: _PartCategory.booster, defaultWidth: 46, defaultHeight: 46),

  // 💡 라이트 & 사이렌
  _PartTemplate(id: 'l_siren_r', name: '빨간 사이렌', emoji: '🚨', category: _PartCategory.lights, defaultWidth: 44, defaultHeight: 44, isSiren: true),
  _PartTemplate(id: 'l_siren_b', name: '파란 경광등', emoji: '🚔', category: _PartCategory.lights, defaultWidth: 46, defaultHeight: 46, isSiren: true),
  _PartTemplate(id: 'l_search', name: '서치라이트', emoji: '🔦', category: _PartCategory.lights, defaultWidth: 44, defaultHeight: 44),
  _PartTemplate(id: 'l_head_eye', name: '로봇 눈 라이트', emoji: '👀', category: _PartCategory.lights, defaultWidth: 46, defaultHeight: 40),
  _PartTemplate(id: 'l_star', name: '반짝 별빛', emoji: '🌟', category: _PartCategory.lights, defaultWidth: 44, defaultHeight: 44),
  _PartTemplate(id: 'l_heart', name: '하트 램프', emoji: '💖', category: _PartCategory.lights, defaultWidth: 42, defaultHeight: 42),

  // 🛡️ 범퍼 & 공구/그릴
  _PartTemplate(id: 'bp_chrome', name: '크롬 범퍼', emoji: '🛡️', category: _PartCategory.bumper, defaultWidth: 48, defaultHeight: 44),
  _PartTemplate(id: 'bp_drill', name: '드릴 범퍼', emoji: '🔩', category: _PartCategory.bumper, defaultWidth: 46, defaultHeight: 46),
  _PartTemplate(id: 'bp_dino', name: '공룡 이빨', emoji: '🦖', category: _PartCategory.bumper, defaultWidth: 48, defaultHeight: 46),
  _PartTemplate(id: 'bp_shovel', name: '굴삭기 삽', emoji: '🚜', category: _PartCategory.bumper, defaultWidth: 52, defaultHeight: 46),
  _PartTemplate(id: 'bp_robot_arm', name: '로봇 손', emoji: '🦾', category: _PartCategory.bumper, defaultWidth: 48, defaultHeight: 48),

  // 👑 루프 & 지붕 장식
  _PartTemplate(id: 'r_crown', name: '황금 왕관', emoji: '👑', category: _PartCategory.roof, defaultWidth: 48, defaultHeight: 44),
  _PartTemplate(id: 'r_taxi', name: '택시등', emoji: '🚕', category: _PartCategory.roof, defaultWidth: 44, defaultHeight: 40),
  _PartTemplate(id: 'r_surf', name: '서핑보드', emoji: '🏄', category: _PartCategory.roof, defaultWidth: 58, defaultHeight: 38),
  _PartTemplate(id: 'r_antenna', name: '위성 안테나', emoji: '📡', category: _PartCategory.roof, defaultWidth: 46, defaultHeight: 46),
  _PartTemplate(id: 'r_horn', name: '메가폰 확성기', emoji: '📢', category: _PartCategory.roof, defaultWidth: 44, defaultHeight: 44),
  _PartTemplate(id: 'r_balloon', name: '풍선 다발', emoji: '🎈', category: _PartCategory.roof, defaultWidth: 50, defaultHeight: 50),
  _PartTemplate(id: 'r_flag', name: '체커 깃발', emoji: '🏁', category: _PartCategory.roof, defaultWidth: 46, defaultHeight: 46),

  // 🪟 창문 & 콕핏 & 조종석
  _PartTemplate(id: 'win_basic', name: '기본 창문', emoji: '🪟', category: _PartCategory.window, defaultWidth: 50, defaultHeight: 46),
  _PartTemplate(id: 'win_tint', name: '선글라스 창', emoji: '🕶️', category: _PartCategory.window, defaultWidth: 48, defaultHeight: 42),
  _PartTemplate(id: 'win_space', name: '우주 돔', emoji: '🪐', category: _PartCategory.window, defaultWidth: 50, defaultHeight: 50),
  _PartTemplate(id: 'win_pilot', name: '조종사 곰돌이', emoji: '🧸', category: _PartCategory.window, defaultWidth: 46, defaultHeight: 46),
  _PartTemplate(id: 'win_cat', name: '드라이버 야옹이', emoji: '🐱', category: _PartCategory.window, defaultWidth: 46, defaultHeight: 46),
  _PartTemplate(id: 'win_dog', name: '드라이버 멍멍이', emoji: '🐶', category: _PartCategory.window, defaultWidth: 46, defaultHeight: 46),

  // 🎨 스티커 & 엠블럼
  _PartTemplate(id: 'st_flame', name: '불꽃 스티커', emoji: '🔥', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
  _PartTemplate(id: 'st_bolt', name: '번개 스티커', emoji: '⚡', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
  _PartTemplate(id: 'st_star', name: '황금 별', emoji: '⭐', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
  _PartTemplate(id: 'st_heart', name: '핑크 하트', emoji: '💖', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
  _PartTemplate(id: 'st_trophy', name: '1등 트로피', emoji: '🏆', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
  _PartTemplate(id: 'st_num1', name: '넘버 1', emoji: '1️⃣', category: _PartCategory.stickers, defaultWidth: 38, defaultHeight: 38),
  _PartTemplate(id: 'st_num7', name: '행운의 7', emoji: '7️⃣', category: _PartCategory.stickers, defaultWidth: 38, defaultHeight: 38),
  _PartTemplate(id: 'st_diamond', name: '다이아몬드', emoji: '💎', category: _PartCategory.stickers, defaultWidth: 38, defaultHeight: 38),
  _PartTemplate(id: 'st_music', name: '음표', emoji: '🎵', category: _PartCategory.stickers, defaultWidth: 38, defaultHeight: 38),
  _PartTemplate(id: 'st_skull', name: '해적 엠블럼', emoji: '🏴‍☠️', category: _PartCategory.stickers, defaultWidth: 40, defaultHeight: 40),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

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
  String? _selectedPlacedPartId; // 선택된 부품

  // 시운전 애니메이션 컨트롤러
  late AnimationController _driveAnimCtrl;
  late AnimationController _sparkleCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _cloudCtrl;

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
    _driveAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _sparkleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

    _driveAnimCtrl.addListener(_onDriveUpdate);
    _sparkleCtrl.addListener(_updateSparkles);
    _confettiCtrl.addListener(_updateConfetti);

    _addDefaultStartingParts();
  }

  void _addDefaultStartingParts() {
    _placedParts.clear();
    final basicWheel = _kAllParts.firstWhere((p) => p.id == 'w_basic');
    _placedParts.add(_PlacedPart(
      id: 'w1_${DateTime.now().millisecondsSinceEpoch}',
      template: basicWheel,
      relativePos: const Offset(0.24, 0.72),
      scale: 1.15,
    ));
    _placedParts.add(_PlacedPart(
      id: 'w2_${DateTime.now().millisecondsSinceEpoch + 1}',
      template: basicWheel,
      relativePos: const Offset(0.76, 0.72),
      scale: 1.15,
    ));
    final basicWin = _kAllParts.firstWhere((p) => p.id == 'win_pilot');
    _placedParts.add(_PlacedPart(
      id: 'win_${DateTime.now().millisecondsSinceEpoch + 2}',
      template: basicWin,
      relativePos: const Offset(0.48, 0.32),
      scale: 1.0,
    ));
  }

  @override
  void dispose() {
    _cloudCtrl.dispose();
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

    AudioManager.instance.playSnap();
    HapticFeedback.heavyImpact();
    _spawnSparklesAt(dropGlobalPos);

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
    setState(() {
      _placedParts.removeWhere((p) => p.id == id);
      if (_selectedPlacedPartId == id) _selectedPlacedPartId = null;
    });
  }

  void _clearAllParts() {
    AudioManager.instance.playPop();
    setState(() {
      _placedParts.clear();
      _selectedPlacedPartId = null;
    });
  }

  // ─── TEST DRIVE ────────────────────────────────────────────────────────────

  void _startTestDrive() {
    AudioManager.instance.playChime();
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
    AudioManager.instance.playEngine();
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
    final hasBooster = _placedParts.any((p) => p.template.isBooster);

    if (hasSiren) {
      AudioManager.instance.playVehicleSound('police');
    } else if (hasBooster) {
      AudioManager.instance.playVehicleSound('monster');
    } else {
      AudioManager.instance.playVehicleSound('car');
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
        // 1. Top Controls (Chassis Preset & Paint Color Picker)
        _buildChassisAndColorBar(),

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

  Widget _buildChassisAndColorBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Chassis selector
          ..._kChassisList.map((chassis) {
            final isSelected = chassis.id == _selectedChassis.id;
            return GestureDetector(
              onTap: () {
                AudioManager.instance.playSnap();
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedChassis = chassis;
                  _bodyColor = chassis.defaultColor;
                });
              },
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

          const VerticalDivider(width: 14, thickness: 1.5, color: Color(0xFFCBD5E1)),

          // Color palette
          ..._kBodyColorPalette.map((color) {
            final isSelected = color == _bodyColor;
            return GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                HapticFeedback.lightImpact();
                setState(() => _bodyColor = color);
              },
              child: Container(
                width: 32, height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF9F1C) : Colors.white,
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 3),
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
        return Container(
          key: _canvasKey,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isCarCanvasHovered ? const Color(0xFF06D6A0) : const Color(0xFFCBD5E1),
              width: _isCarCanvasHovered ? 3.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isCarCanvasHovered
                    ? const Color(0xFF06D6A0).withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Grid background & Floor shadow
                CustomPaint(
                  painter: _WorkbenchBackgroundPainter(isHovered: _isCarCanvasHovered),
                ),

                // 2. Base Chassis Illustration (Custom per model!)
                Center(
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

                // 3. User-Placed Interactive Drag-and-Drop Parts
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasW = constraints.maxWidth;
                      final canvasH = constraints.maxHeight;

                      return Stack(
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
                                AudioManager.instance.playSnap();
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
                              child: Container(
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
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

                // 4. Dedicated High-Accessibility Floating Action Bar for Selected Part
                if (selectedPart != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Selected part preview
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Text(selectedPart.template.emoji, style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 4),
                                    Text(
                                      selectedPart.template.name,
                                      style: GoogleFonts.jua(fontSize: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 🔄 Rotate Button
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
                              const SizedBox(width: 6),

                              // 🔍 Scale Button
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
                              const SizedBox(width: 6),

                              // ↔️ Flip Button
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
                              const SizedBox(width: 6),

                              // 🗑️ Delete Button
                              _buildToolButton(
                                label: '삭제',
                                icon: Icons.delete_forever_rounded,
                                color: const Color(0xFFFF5964),
                                onTap: () => _removePlacedPart(selectedPart.id),
                              ),
                              const SizedBox(width: 6),

                              // ✅ Done Button
                              _buildToolButton(
                                label: '완료',
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF06D6A0),
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  setState(() => _selectedPlacedPartId = null);
                                },
                              ),
                            ],
                          ),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.jua(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
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
      height: 145,
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Column(
        children: [
          // Category tabs
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _PartCategory.values.map((cat) {
                final isSelected = cat == _selectedCategory;
                final catInfo = _getCategoryInfo(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      setState(() => _selectedCategory = cat);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF9F1C) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF9F1C) : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(catInfo.$1, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(catInfo.$2, style: GoogleFonts.jua(
                            fontSize: 12,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Draggable Parts Tray
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredParts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final part = filteredParts[index];
                return _buildDraggablePartTile(part);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggablePartTile(_PartTemplate part) {
    return Draggable<_PartTemplate>(
      data: part,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.3,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06D6A0).withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Text(part.emoji, style: const TextStyle(fontSize: 44)),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _buildPartTrayCard(part),
      ),
      child: _buildPartTrayCard(part),
    );
  }

  Widget _buildPartTrayCard(_PartTemplate part) {
    return Container(
      width: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(part.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 2),
          Text(
            part.name,
            style: GoogleFonts.jua(fontSize: 10, color: const Color(0xFF334155)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  (String, String) _getCategoryInfo(_PartCategory cat) {
    switch (cat) {
      case _PartCategory.wheels: return ('🛞', '바퀴');
      case _PartCategory.booster: return ('🚀', '부스터/날개');
      case _PartCategory.lights: return ('💡', '라이트/사이렌');
      case _PartCategory.bumper: return ('🛡️', '범퍼/도구');
      case _PartCategory.roof: return ('👑', '루프/장식');
      case _PartCategory.window: return ('🪟', '창문/조종사');
      case _PartCategory.stickers: return ('🎨', '스티커');
    }
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

                    // Rear Exhaust & Speed Dust Puffs
                    Positioned(
                      left: -20,
                      bottom: 24,
                      child: IgnorePointer(
                        child: Text(
                          hasBooster ? '💨🔥' : '💨',
                          style: TextStyle(
                            fontSize: 16 + sin(_driveProgress * 28).abs() * 8,
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
                            // 부스터 파이어 이펙트
                            if (placed.template.isBooster)
                              Positioned(
                                left: -22,
                                child: Text('🔥', style: TextStyle(fontSize: 18 + sin(_driveProgress * 30).abs() * 8)),
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
class _WorkbenchBackgroundPainter extends CustomPainter {
  final bool isHovered;
  _WorkbenchBackgroundPainter({required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = (isHovered ? const Color(0xFF06D6A0) : const Color(0xFFCBD5E1)).withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final shadowRect = Rect.fromLTWH(w * 0.12, h * 0.78, w * 0.76, 18);
    canvas.drawOval(shadowRect, Paint()..color = Colors.black.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  @override
  bool shouldRepaint(covariant _WorkbenchBackgroundPainter old) => old.isHovered != isHovered;
}

/// 차종별 고유하고 디테일한 차체 렌더링
class _ChassisPainter extends CustomPainter {
  final String chassisId;
  final Color color;

  _ChassisPainter({required this.chassisId, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (chassisId) {
      case 'truck':
        _drawTruck(canvas, w, h);
      case 'police':
        _drawPoliceCar(canvas, w, h);
      case 'sports':
        _drawSportsCar(canvas, w, h);
      case 'ambulance':
        _drawAmbulance(canvas, w, h);
      case 'monster':
        _drawMonsterTruck(canvas, w, h);
      case 'bus':
        _drawBus(canvas, w, h);
      case 'rocket':
        _drawRocketCar(canvas, w, h);
      default:
        _drawSedan(canvas, w, h);
    }
  }

  // 1. 승용차 (Sedan)
  void _drawSedan(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;
    final bodyRect = Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.80, h * 0.32);

    // Shadow & Body
    _drawShadow(canvas, bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), bodyPaint);

    // Cabin
    final cabinPath = Path()
      ..moveTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.38, h * 0.22)
      ..quadraticBezierTo(w * 0.42, h * 0.20, w * 0.50, h * 0.20)
      ..lineTo(w * 0.70, h * 0.20)
      ..quadraticBezierTo(w * 0.76, h * 0.22, w * 0.80, h * 0.44)
      ..close();
    canvas.drawPath(cabinPath, bodyPaint);

    // Windows
    _drawWindow(canvas, Rect.fromLTWH(w * 0.38, h * 0.23, w * 0.18, h * 0.20));
    _drawWindow(canvas, Rect.fromLTWH(w * 0.58, h * 0.23, w * 0.18, h * 0.20));

    // Door line & Handle
    canvas.drawLine(Offset(w * 0.57, h * 0.23), Offset(w * 0.57, h * 0.72), Paint()..color = Colors.black26..strokeWidth = 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.52, h * 0.50, 10, 4), const Radius.circular(2)), Paint()..color = Colors.white70);

    _drawLightsAndCutouts(canvas, w, h, bodyRect);
  }

  // 2. 트럭 (Truck) — 운전석 캐빈 + 오픈 적재함(Cargo Bed) + 배기통 굴뚝
  void _drawTruck(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;

    // 배기통 굴뚝 (Exhaust Pipe Stack)
    final pipePaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.56, h * 0.12, 10, h * 0.35), const Radius.circular(3)), pipePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.54, h * 0.10, 14, 6), const Radius.circular(2)), pipePaint);

    // 앞쪽 운전석 캐빈 (Tall Front Cab)
    final cabRect = Rect.fromLTWH(w * 0.58, h * 0.18, w * 0.32, h * 0.58);
    _drawShadow(canvas, Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.80, h * 0.32));
    canvas.drawRRect(RRect.fromRectAndRadius(cabRect, const Radius.circular(16)), bodyPaint);

    // 캐빈 전면 유리
    _drawWindow(canvas, Rect.fromLTWH(w * 0.62, h * 0.22, w * 0.24, h * 0.24));

    // 뒤쪽 화물 적재함 (Open Cargo Bed)
    final bedRect = Rect.fromLTWH(w * 0.10, h * 0.38, w * 0.46, h * 0.38);
    final bedPaint = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawRRect(RRect.fromRectAndRadius(bedRect, const Radius.circular(12)), bedPaint);

    // 적재함 리브/스트라이프 라인 (Steel ribs)
    final ribPaint = Paint()..color = Colors.black12..strokeWidth = 2.5;
    for (double x = w * 0.16; x < w * 0.52; x += w * 0.10) {
      canvas.drawLine(Offset(x, h * 0.40), Offset(x, h * 0.72), ribPaint);
    }

    // 적재함 상단 가드레일
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.09, h * 0.36, w * 0.48, 6), const Radius.circular(3)), Paint()..color = const Color(0xFF64748B));

    _drawLightsAndCutouts(canvas, w, h, Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.80, h * 0.32));
  }

  // 3. 경찰차 (Police Car) — 흑백 투톤 + POLICE 배지 + 범퍼 가드
  void _drawPoliceCar(Canvas canvas, double w, double h) {
    final darkPaint = Paint()..color = const Color(0xFF0F172A);
    final whitePaint = Paint()..color = Colors.white;

    final bodyRect = Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.80, h * 0.32);
    _drawShadow(canvas, bodyRect);

    // Front/Rear Black body
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), darkPaint);

    // Center White Door Section (경찰차 특유의 도어 화이트 도색)
    final doorRect = Rect.fromLTWH(w * 0.36, h * 0.44, w * 0.34, h * 0.32);
    canvas.drawRect(doorRect, whitePaint);

    // Police Star Badge & Text
    canvas.drawCircle(Offset(w * 0.53, h * 0.58), 12, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(Offset(w * 0.53, h * 0.58), 9, Paint()..color = const Color(0xFF1E293B));

    // Cabin
    final cabinPath = Path()
      ..moveTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.80, h * 0.44)
      ..close();
    canvas.drawPath(cabinPath, darkPaint);

    // White Roof top
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.20, w * 0.36, 6), const Radius.circular(3)), whitePaint);

    // Windows
    _drawWindow(canvas, Rect.fromLTWH(w * 0.38, h * 0.24, w * 0.16, h * 0.19));
    _drawWindow(canvas, Rect.fromLTWH(w * 0.56, h * 0.24, w * 0.16, h * 0.19));

    // Front Push-Bar (경찰 범퍼 가드)
    final pushBar = Paint()..color = const Color(0xFF475569)..strokeWidth = 4;
    canvas.drawLine(Offset(w * 0.90, h * 0.44), Offset(w * 0.90, h * 0.72), pushBar);
    canvas.drawLine(Offset(w * 0.86, h * 0.52), Offset(w * 0.92, h * 0.52), pushBar);

    _drawLightsAndCutouts(canvas, w, h, bodyRect);
  }

  // 4. 스포츠카 (Sports Car) — 낮고 날렵한 유선형 + GT 리어 스포일러 + 레이싱 스트라이프
  void _drawSportsCar(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;

    // 대형 리어 스포일러 (Large GT Spoiler)
    final spoilerPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(w * 0.12, h * 0.30, 6, h * 0.18), spoilerPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.30, 6, h * 0.18), spoilerPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.26, w * 0.16, 8), const Radius.circular(3)), spoilerPaint);

    // 낮고 슬릭한 차체 (Low aerodynamic wedge body)
    final bodyRect = Rect.fromLTWH(w * 0.08, h * 0.48, w * 0.84, h * 0.28);
    _drawShadow(canvas, bodyRect);

    final sportsPath = Path()
      ..moveTo(w * 0.08, h * 0.60)
      ..lineTo(w * 0.12, h * 0.46)
      ..lineTo(w * 0.34, h * 0.44)
      ..lineTo(w * 0.52, h * 0.26) // 극도로 누운 윈드실드
      ..lineTo(w * 0.68, h * 0.26)
      ..lineTo(w * 0.88, h * 0.52) // 뾰족한 노즈
      ..lineTo(w * 0.92, h * 0.66)
      ..lineTo(w * 0.08, h * 0.66)
      ..close();
    canvas.drawPath(sportsPath, bodyPaint);

    // 레이싱 스트라이프 (White Racing Stripes)
    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawRect(Rect.fromLTWH(w * 0.10, h * 0.52, w * 0.80, 5), stripePaint);

    // 슬릭 윈드실드 (Sleek Tinted Window)
    final winPath = Path()
      ..moveTo(w * 0.48, h * 0.43)
      ..lineTo(w * 0.54, h * 0.28)
      ..lineTo(w * 0.66, h * 0.28)
      ..lineTo(w * 0.68, h * 0.43)
      ..close();
    canvas.drawPath(winPath, Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85));

    // 측면 공기 흡입구 (Side Intake Vent)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.55, 18, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF0F172A));

    _drawLightsAndCutouts(canvas, w, h, bodyRect);
  }

  // 5. 구급차 (Ambulance) — 사각 박스형 + 빨간 십자가(➕) + 엠뷸런스 스트라이프
  void _drawAmbulance(Canvas canvas, double w, double h) {
    final whitePaint = Paint()..color = Colors.white;

    final bodyRect = Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.78, h * 0.32);
    _drawShadow(canvas, bodyRect);

    // Boxy Tall Ambulance Body
    final ambPath = Path()
      ..moveTo(w * 0.10, h * 0.24)
      ..lineTo(w * 0.68, h * 0.24)
      ..lineTo(w * 0.84, h * 0.42) // Front angled windshield line
      ..lineTo(w * 0.88, h * 0.56)
      ..lineTo(w * 0.88, h * 0.74)
      ..lineTo(w * 0.10, h * 0.74)
      ..close();
    canvas.drawPath(ambPath, whitePaint);

    // Red Emergency Stripe
    final redPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRect(Rect.fromLTWH(w * 0.10, h * 0.50, w * 0.78, 10), redPaint);

    // Red Medical Cross (➕)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.38, h * 0.36), width: 8, height: 24), const Radius.circular(2)), redPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.38, h * 0.36), width: 24, height: 8), const Radius.circular(2)), redPaint);

    // Driver & Patient Windows
    _drawWindow(canvas, Rect.fromLTWH(w * 0.64, h * 0.28, w * 0.18, h * 0.18));
    _drawWindow(canvas, Rect.fromLTWH(w * 0.16, h * 0.28, w * 0.14, h * 0.16));

    _drawLightsAndCutouts(canvas, w, h, bodyRect);
  }

  // 6. 몬스터 트럭 (Monster Truck) — 높은 지상고 + 메탈 롤케이지 + 쇼바 프레임
  void _drawMonsterTruck(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;

    // Heavy Suspension Shocks & Tubular Subframe
    final framePaint = Paint()..color = const Color(0xFF475569)..strokeWidth = 5..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.26, h * 0.78), Offset(w * 0.40, h * 0.58), framePaint);
    canvas.drawLine(Offset(w * 0.74, h * 0.78), Offset(w * 0.60, h * 0.58), framePaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.68), Offset(w * 0.78, h * 0.68), framePaint);

    // Coil Springs (노란 쇼바 서스펜션)
    final springPaint = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 4;
    canvas.drawLine(Offset(w * 0.26, h * 0.64), Offset(w * 0.26, h * 0.76), springPaint);
    canvas.drawLine(Offset(w * 0.74, h * 0.64), Offset(w * 0.74, h * 0.76), springPaint);

    // High Body Shell
    final bodyRect = Rect.fromLTWH(w * 0.14, h * 0.32, w * 0.72, h * 0.30);
    _drawShadow(canvas, bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), bodyPaint);

    // Roll Cage Bars (지붕 위 파이프 롤케이지)
    final rollCage = Paint()..color = const Color(0xFF0F172A)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.32, h * 0.32), Offset(w * 0.42, h * 0.14), rollCage);
    canvas.drawLine(Offset(w * 0.68, h * 0.32), Offset(w * 0.60, h * 0.14), rollCage);
    canvas.drawLine(Offset(w * 0.40, h * 0.14), Offset(w * 0.62, h * 0.14), rollCage);

    // Windows
    _drawWindow(canvas, Rect.fromLTWH(w * 0.44, h * 0.18, w * 0.22, h * 0.18));

    // Flame Decal On Body
    canvas.drawCircle(Offset(bodyRect.right - 2, bodyRect.center.dy), 7, Paint()..color = const Color(0xFFFFD166));

    // Wheel Well Cutouts
    final wheelWellPaint = Paint()..color = Colors.black.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(w * 0.26, bodyRect.bottom + 4), 22, wheelWellPaint);
    canvas.drawCircle(Offset(w * 0.74, bodyRect.bottom + 4), 22, wheelWellPaint);
  }

  // 7. 버스 (Bus) — 긴 2단 차체 + 4연속 승객 창문 + 전면 도어 라인
  void _drawBus(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;

    final bodyRect = Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.84, h * 0.58);
    _drawShadow(canvas, Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.84, h * 0.32));

    // Giant Box Body
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(18)), bodyPaint);

    // Front Route Header Display (노선 전광판)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.74, h * 0.22, w * 0.14, 10), const Radius.circular(3)), Paint()..color = const Color(0xFF0F172A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.76, h * 0.24, w * 0.10, 6), const Radius.circular(2)), Paint()..color = const Color(0xFF00E676));

    // 4 Sequential Passenger Windows (파노라마 연속 창문)
    for (int i = 0; i < 4; i++) {
      final winLeft = w * 0.14 + i * (w * 0.17);
      _drawWindow(canvas, Rect.fromLTWH(winLeft, h * 0.28, w * 0.14, h * 0.20));
    }

    // Driver Front Windshield
    _drawWindow(canvas, Rect.fromLTWH(w * 0.74, h * 0.34, w * 0.14, h * 0.22));

    // Passenger Door Line (앞문)
    canvas.drawLine(Offset(w * 0.72, h * 0.28), Offset(w * 0.72, h * 0.74), Paint()..color = Colors.black26..strokeWidth = 2.5);

    _drawLightsAndCutouts(canvas, w, h, Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.84, h * 0.32));
  }

  // 8. 로켓차 (Rocket Car) — 뾰족한 원뿔 노즈콘 + 원통형 동체 + 델타 날개 핀 + 후방 분사구
  void _drawRocketCar(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;

    // Rear Jet Thruster Exhaust Nozzle (후방 분사구)
    final nozzlePaint = Paint()..color = const Color(0xFF475569);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.46, w * 0.12, h * 0.24), const Radius.circular(4)), nozzlePaint);

    // Delta Fin Wings (위아래 델타 꼬리날개)
    final finPath = Path()
      ..moveTo(w * 0.12, h * 0.46)
      ..lineTo(w * 0.08, h * 0.20)
      ..lineTo(w * 0.32, h * 0.46)
      ..close();
    canvas.drawPath(finPath, Paint()..color = const Color(0xFFFF9F1C));

    final bottomFin = Path()
      ..moveTo(w * 0.12, h * 0.70)
      ..lineTo(w * 0.08, h * 0.86)
      ..lineTo(w * 0.32, h * 0.70)
      ..close();
    canvas.drawPath(bottomFin, Paint()..color = const Color(0xFFFF9F1C));

    // Fuselage Body + Sharp Nosecone
    _drawShadow(canvas, Rect.fromLTWH(w * 0.12, h * 0.44, w * 0.80, h * 0.28));

    final rocketPath = Path()
      ..moveTo(w * 0.14, h * 0.44)
      ..lineTo(w * 0.68, h * 0.44)
      ..quadraticBezierTo(w * 0.86, h * 0.48, w * 0.94, h * 0.58) // Sharp nose tip
      ..quadraticBezierTo(w * 0.86, h * 0.68, w * 0.68, h * 0.72)
      ..lineTo(w * 0.14, h * 0.72)
      ..close();
    canvas.drawPath(rocketPath, bodyPaint);

    // Round Cockpit Bubble Dome (우주 돔 콕핏)
    final domeRect = Rect.fromLTWH(w * 0.42, h * 0.26, w * 0.26, h * 0.26);
    canvas.drawArc(domeRect, pi, pi, true, Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.85));
    canvas.drawArc(domeRect, pi, pi, false, Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke);

    _drawLightsAndCutouts(canvas, w, h, Rect.fromLTWH(w * 0.14, h * 0.44, w * 0.76, h * 0.28));
  }

  // ─── 공통 헬퍼 메서드 ────────────────────────────────────────────────────────

  void _drawShadow(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.translate(0, 6), const Radius.circular(16)),
      Paint()..color = Colors.black.withValues(alpha: 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  void _drawWindow(Canvas canvas, Rect winRect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(winRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.88),
    );
    // Window shine
    canvas.drawLine(
      Offset(winRect.left + 4, winRect.top + 4),
      Offset(winRect.left + 4, winRect.bottom - 4),
      Paint()..color = Colors.white.withValues(alpha: 0.7)..strokeWidth = 2..style = PaintingStyle.stroke,
    );
  }

  void _drawLightsAndCutouts(Canvas canvas, double w, double h, Rect bodyRect) {
    // Headlight
    canvas.drawCircle(Offset(bodyRect.right - 2, bodyRect.center.dy), 6, Paint()..color = const Color(0xFFFFD166));
    // Taillight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bodyRect.left + 4, bodyRect.center.dy), width: 6, height: 12), const Radius.circular(2)),
      Paint()..color = const Color(0xFFEF4444),
    );

    // Wheel Well Cutout Guides
    final wheelWellPaint = Paint()..color = Colors.black.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(w * 0.26, bodyRect.bottom + 2), 17, wheelWellPaint);
    canvas.drawCircle(Offset(w * 0.74, bodyRect.bottom + 2), 17, wheelWellPaint);

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)),
      Paint()..color = Colors.black.withValues(alpha: 0.12)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ChassisPainter old) => old.chassisId != chassisId || old.color != color;
}

/// 헤드라이트가 전방 도로를 비추는 반투명 조명 빔
class _HeadlightBeamPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height * 0.7)
      ..close();

    final lightGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        const Color(0xFFFFD166).withValues(alpha: 0.45),
        const Color(0xFFFFD166).withValues(alpha: 0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = lightGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 시운전 배경 애니메이션 — 4단계 패럴랙스 고화질 도시 & 자연 파노라마
class _TestDrivePainter extends CustomPainter {
  final double progress;
  final double cloudProgress;

  _TestDrivePainter({required this.progress, required this.cloudProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 총 주행 월드 가로폭 (3200px 파노라마)
    const double worldLength = 3200.0;
    final double worldScroll = progress * worldLength;

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 1: 원경 산맥 & 구릉 (Distant Purple Mountains) (속도 0.12x)
    // ─────────────────────────────────────────────────────────────────────────
    final mountainScroll = (worldScroll * 0.12) % (w * 1.5);
    _drawMountains(canvas, w, h, mountainScroll);

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 2: 원경 스카이라인 & 현수교 (Distant City Skyline) (속도 0.35x)
    // ─────────────────────────────────────────────────────────────────────────
    final skylineScroll = (worldScroll * 0.35);
    _drawCitySkyline(canvas, w, h, skylineScroll);

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 3: 중경 풍경 (타운하우스, 상점, 풍차, 벚꽃/녹음수, 가로등) (속도 0.85x)
    // ─────────────────────────────────────────────────────────────────────────
    final midScroll = (worldScroll * 0.85);
    _drawMidgroundTownAndPark(canvas, w, h, midScroll);

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 4: 근경 도로 (고급 아스팔트 고속도로 + 차선 + 인도 + 가드레일) (속도 1.8x)
    // ─────────────────────────────────────────────────────────────────────────
    final roadScroll = (worldScroll * 1.8);
    _drawHighwayRoad(canvas, w, h, roadScroll);
  }

  // 1. 원경 산맥 (Distant Mountains with Snow Peaks)
  void _drawMountains(Canvas canvas, double w, double h, double scroll) {
    final mountainPaint1 = Paint()..color = const Color(0xFFC7D2FE).withValues(alpha: 0.7);
    final mountainPaint2 = Paint()..color = const Color(0xFFA5B4FC).withValues(alpha: 0.85);
    final snowPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);

    for (int page = -1; page <= 2; page++) {
      final baseOffsetX = page * (w * 1.5) - scroll;

      // 뒷산
      final path1 = Path()
        ..moveTo(baseOffsetX, h * 0.58)
        ..lineTo(baseOffsetX + w * 0.3, h * 0.28)
        ..lineTo(baseOffsetX + w * 0.6, h * 0.58)
        ..lineTo(baseOffsetX + w * 1.0, h * 0.24)
        ..lineTo(baseOffsetX + w * 1.5, h * 0.58)
        ..close();
      canvas.drawPath(path1, mountainPaint1);

      // 눈 덮인 봉우리 (Snow peak 1)
      final snow1 = Path()
        ..moveTo(baseOffsetX + w * 0.24, h * 0.34)
        ..lineTo(baseOffsetX + w * 0.30, h * 0.28)
        ..lineTo(baseOffsetX + w * 0.36, h * 0.34)
        ..close();
      canvas.drawPath(snow1, snowPaint);

      // 앞산
      final path2 = Path()
        ..moveTo(baseOffsetX - w * 0.2, h * 0.58)
        ..lineTo(baseOffsetX + w * 0.15, h * 0.36)
        ..lineTo(baseOffsetX + w * 0.45, h * 0.58)
        ..lineTo(baseOffsetX + w * 0.85, h * 0.32)
        ..lineTo(baseOffsetX + w * 1.3, h * 0.58)
        ..close();
      canvas.drawPath(path2, mountainPaint2);
    }
  }

  // 2. 원경 도시 스카이라인 (City Skyline & Suspension Bridge)
  void _drawCitySkyline(Canvas canvas, double w, double h, double scroll) {
    final buildingPaint = Paint()..color = const Color(0xFF93C5FD).withValues(alpha: 0.6);
    final towerPaint = Paint()..color = const Color(0xFF60A5FA).withValues(alpha: 0.75);
    final windowLight = Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.7);

    final double patternW = 900.0;
    final int startIdx = ((scroll - 200) / patternW).floor();
    final int endIdx = ((scroll + w + 200) / patternW).ceil();

    for (int i = startIdx; i <= endIdx; i++) {
      final originX = i * patternW - scroll;

      // Skyscraper 1 (Glass Tower)
      _drawSkyscraper(canvas, Offset(originX + 50, h * 0.56), 65, h * 0.26, buildingPaint, windowLight);
      // Radio Mast Tower
      _drawRadioTower(canvas, Offset(originX + 130, h * 0.56), h * 0.30, towerPaint);
      // Skyscraper 2 (Modern Stepped Tower)
      _drawSteppedTower(canvas, Offset(originX + 170, h * 0.56), 80, h * 0.28, buildingPaint, windowLight);
      // Skyscraper 3 (Cylinder Dome)
      _drawDomeTower(canvas, Offset(originX + 280, h * 0.56), 60, h * 0.22, buildingPaint);
      // Grand Suspension Bridge Towers & Cables
      _drawSuspensionBridge(canvas, Offset(originX + 370, h * 0.56), 240, h * 0.24, towerPaint);
      // Skyscraper 4 (Twin Spire Tower)
      _drawTwinTower(canvas, Offset(originX + 650, h * 0.56), 75, h * 0.27, buildingPaint, windowLight);
      // Skyscraper 5 (Curved Financial Tower)
      _drawSkyscraper(canvas, Offset(originX + 760, h * 0.56), 70, h * 0.24, buildingPaint, windowLight);
    }
  }

  void _drawSkyscraper(Canvas canvas, Offset base, double bw, double bh, Paint bodyPaint, Paint winPaint) {
    final rect = Rect.fromLTWH(base.dx, base.dy - bh, bw, bh);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bodyPaint);
    // Glowing window grid
    for (double y = rect.top + 10; y < rect.bottom - 12; y += 14) {
      for (double x = rect.left + 8; x < rect.right - 8; x += 12) {
        canvas.drawRect(Rect.fromLTWH(x, y, 6, 7), winPaint);
      }
    }
  }

  void _drawSteppedTower(Canvas canvas, Offset base, double bw, double bh, Paint bodyPaint, Paint winPaint) {
    final rect1 = Rect.fromLTWH(base.dx, base.dy - bh * 0.65, bw, bh * 0.65);
    final rect2 = Rect.fromLTWH(base.dx + bw * 0.15, base.dy - bh, bw * 0.7, bh * 0.35);
    canvas.drawRect(rect1, bodyPaint);
    canvas.drawRect(rect2, bodyPaint);
    // Antennas
    canvas.drawLine(Offset(base.dx + bw / 2, base.dy - bh), Offset(base.dx + bw / 2, base.dy - bh - 16), Paint()..color = const Color(0xFF3B82F6)..strokeWidth = 2);
    canvas.drawCircle(Offset(base.dx + bw / 2, base.dy - bh - 16), 3, Paint()..color = Colors.redAccent);
  }

  void _drawDomeTower(Canvas canvas, Offset base, double bw, double bh, Paint bodyPaint) {
    final rect = Rect.fromLTWH(base.dx, base.dy - bh * 0.85, bw, bh * 0.85);
    canvas.drawRect(rect, bodyPaint);
    canvas.drawArc(Rect.fromLTWH(base.dx, base.dy - bh, bw, bh * 0.3), pi, pi, true, bodyPaint);
  }

  void _drawTwinTower(Canvas canvas, Offset base, double bw, double bh, Paint bodyPaint, Paint winPaint) {
    final colW = bw * 0.42;
    canvas.drawRect(Rect.fromLTWH(base.dx, base.dy - bh, colW, bh), bodyPaint);
    canvas.drawRect(Rect.fromLTWH(base.dx + bw - colW, base.dy - bh, colW, bh), bodyPaint);
    // Skybridge connecting twin towers
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + colW, base.dy - bh * 0.6, bw - colW * 2, 8), const Radius.circular(2)), bodyPaint);
  }

  void _drawRadioTower(Canvas canvas, Offset base, double height, Paint paint) {
    final p = paint..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawLine(base, Offset(base.dx + 12, base.dy - height), p);
    canvas.drawLine(Offset(base.dx + 24, base.dy), Offset(base.dx + 12, base.dy - height), p);
    for (double y = base.dy - 12; y > base.dy - height; y -= 16) {
      canvas.drawLine(Offset(base.dx + 4, y), Offset(base.dx + 20, y), p);
    }
    // Red beacon
    canvas.drawCircle(Offset(base.dx + 12, base.dy - height), 3.5, Paint()..color = const Color(0xFFEF4444));
  }

  void _drawSuspensionBridge(Canvas canvas, Offset base, double bw, double bh, Paint paint) {
    final p = paint..strokeWidth = 3..style = PaintingStyle.stroke;
    final t1X = base.dx + bw * 0.25;
    final t2X = base.dx + bw * 0.75;
    final deckY = base.dy - 14;

    // Towers
    canvas.drawLine(Offset(t1X, base.dy), Offset(t1X, base.dy - bh), p);
    canvas.drawLine(Offset(t2X, base.dy), Offset(t2X, base.dy - bh), p);

    // Deck
    canvas.drawLine(Offset(base.dx, deckY), Offset(base.dx + bw, deckY), paint..strokeWidth = 4);

    // Main Suspension Cable
    final cablePath = Path()
      ..moveTo(base.dx, deckY)
      ..lineTo(t1X, base.dy - bh)
      ..quadraticBezierTo(base.dx + bw / 2, deckY + 4, t2X, base.dy - bh)
      ..lineTo(base.dx + bw, deckY);
    canvas.drawPath(cablePath, paint..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  // 3. 중경 풍경 (Town Houses, Stores, Windmills, Lush Trees, Streetlamps)
  void _drawMidgroundTownAndPark(Canvas canvas, double w, double h, double scroll) {
    // Green grass hill layer
    final hillPaint = Paint()..color = const Color(0xFF4ADE80);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.55, w, h * 0.15), hillPaint);

    final double patternW = 1000.0;
    final int startIdx = ((scroll - 250) / patternW).floor();
    final int endIdx = ((scroll + w + 250) / patternW).ceil();

    for (int i = startIdx; i <= endIdx; i++) {
      final originX = i * patternW - scroll;

      // 1. Colorful Toy Store (토이 스토어)
      _drawToyStore(canvas, Offset(originX + 30, h * 0.58));
      // 2. Oak Tree (풍성한 참나무)
      _drawLushOakTree(canvas, Offset(originX + 150, h * 0.58), 65);
      // 3. Windmill (풍차)
      _drawWindmill(canvas, Offset(originX + 230, h * 0.58), h * 0.20, scroll);
      // 4. Bakery with Chimney & Awning (베이커리 카페)
      _drawBakeryCafe(canvas, Offset(originX + 330, h * 0.58));
      // 5. Cherry Blossom Tree (화사한 벚꽃나무)
      _drawCherryTree(canvas, Offset(originX + 460, h * 0.58), 60);
      // 6. Modern Auto Showroom (자동차 전시장)
      _drawAutoShowroom(canvas, Offset(originX + 540, h * 0.58));
      // 7. Streetlamp with light pool (가로등)
      _drawStreetLamp(canvas, Offset(originX + 680, h * 0.58), 54);
      // 8. Fire Station (소방서 차고)
      _drawFireStation(canvas, Offset(originX + 740, h * 0.58));
      // 9. Pine Tree (침엽수)
      _drawPineTree(canvas, Offset(originX + 880, h * 0.58), 58);
      // 10. Kids Zone / Speed Sign (교통 표지판)
      _drawTrafficSign(canvas, Offset(originX + 950, h * 0.58), '🚸');
    }
  }

  void _drawToyStore(Canvas canvas, Offset base) {
    const bw = 85.0;
    const bh = 55.0;
    // Building wall
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx, base.dy - bh, bw, bh), const Radius.circular(6)), Paint()..color = const Color(0xFFFEF08A));
    // Blue Roof
    final roof = Path()
      ..moveTo(base.dx - 6, base.dy - bh)
      ..lineTo(base.dx + bw / 2, base.dy - bh - 22)
      ..lineTo(base.dx + bw + 6, base.dy - bh)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF38BDF8));
    // Striped Awning
    _drawAwning(canvas, Rect.fromLTWH(base.dx + 8, base.dy - bh + 14, bw - 16, 12), const Color(0xFFFF5964), Colors.white);
    // Display Window with Teddy Bear
    canvas.drawRect(Rect.fromLTWH(base.dx + 12, base.dy - 26, 32, 22), Paint()..color = const Color(0xFFE0F2FE));
    canvas.drawRect(Rect.fromLTWH(base.dx + 12, base.dy - 26, 32, 22), Paint()..color = const Color(0xFF94A3B8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Door
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + 52, base.dy - 32, 22, 32), const Radius.circular(4)), Paint()..color = const Color(0xFFF97316));
  }

  void _drawBakeryCafe(Canvas canvas, Offset base) {
    const bw = 90.0;
    const bh = 58.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx, base.dy - bh, bw, bh), const Radius.circular(6)), Paint()..color = const Color(0xFFFFEDD5));
    // Chimney & Smoke
    canvas.drawRect(Rect.fromLTWH(base.dx + 12, base.dy - bh - 26, 12, 20), Paint()..color = const Color(0xFFEA580C));
    canvas.drawCircle(Offset(base.dx + 18, base.dy - bh - 32), 6, Paint()..color = Colors.white.withValues(alpha: 0.6));
    canvas.drawCircle(Offset(base.dx + 24, base.dy - bh - 42), 8, Paint()..color = Colors.white.withValues(alpha: 0.4));
    // Red Roof
    final roof = Path()
      ..moveTo(base.dx - 6, base.dy - bh)
      ..lineTo(base.dx + bw / 2, base.dy - bh - 20)
      ..lineTo(base.dx + bw + 6, base.dy - bh)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFDC2626));
    // Striped Awning
    _drawAwning(canvas, Rect.fromLTWH(base.dx + 10, base.dy - bh + 16, bw - 20, 12), const Color(0xFFF59E0B), Colors.white);
    // Bakery window
    canvas.drawRect(Rect.fromLTWH(base.dx + 14, base.dy - 24, 34, 20), Paint()..color = const Color(0xFFBAE6FD));
  }

  void _drawAutoShowroom(Canvas canvas, Offset base) {
    const bw = 100.0;
    const bh = 52.0;
    // Modern Glass Wall
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx, base.dy - bh, bw, bh), const Radius.circular(8)), Paint()..color = const Color(0xFF1E293B));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + 4, base.dy - bh + 4, bw - 8, bh - 8), const Radius.circular(6)), Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.45));
    // Top Sign Banner
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx, base.dy - bh - 8, bw, 12), const Radius.circular(3)), Paint()..color = const Color(0xFFEF4444));
  }

  void _drawFireStation(Canvas canvas, Offset base) {
    const bw = 90.0;
    const bh = 60.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx, base.dy - bh, bw, bh), const Radius.circular(6)), Paint()..color = const Color(0xFFE2E8F0));
    // 2 Red Garage Rollers
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + 8, base.dy - 40, 32, 40), const Radius.circular(4)), Paint()..color = const Color(0xFFDC2626));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(base.dx + 48, base.dy - 40, 32, 40), const Radius.circular(4)), Paint()..color = const Color(0xFFDC2626));
    // Garage ribs
    for (double y = base.dy - 34; y < base.dy; y += 8) {
      canvas.drawLine(Offset(base.dx + 8, y), Offset(base.dx + 40, y), Paint()..color = Colors.black26);
      canvas.drawLine(Offset(base.dx + 48, y), Offset(base.dx + 80, y), Paint()..color = Colors.black26);
    }
  }

  void _drawAwning(Canvas canvas, Rect rect, Color c1, Color c2) {
    final stripeW = rect.width / 6;
    for (int s = 0; s < 6; s++) {
      final stripeRect = Rect.fromLTWH(rect.left + s * stripeW, rect.top, stripeW, rect.height);
      canvas.drawRect(stripeRect, Paint()..color = (s % 2 == 0) ? c1 : c2);
    }
  }

  void _drawLushOakTree(Canvas canvas, Offset base, double size) {
    // Trunk
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy - size * 0.3), width: 10, height: size * 0.6), const Radius.circular(4)), Paint()..color = const Color(0xFF78350F));
    // 3 Overlapping Foliage Blobs
    canvas.drawCircle(Offset(base.dx, base.dy - size * 0.7), size * 0.38, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(base.dx - size * 0.22, base.dy - size * 0.55), size * 0.30, Paint()..color = const Color(0xFF16A34A));
    canvas.drawCircle(Offset(base.dx + size * 0.22, base.dy - size * 0.55), size * 0.32, Paint()..color = const Color(0xFF22C55E));
  }

  void _drawCherryTree(Canvas canvas, Offset base, double size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy - size * 0.3), width: 8, height: size * 0.6), const Radius.circular(3)), Paint()..color = const Color(0xFF5C2B14));
    // Pink Sakura foliage
    canvas.drawCircle(Offset(base.dx, base.dy - size * 0.7), size * 0.36, Paint()..color = const Color(0xFFF472B6));
    canvas.drawCircle(Offset(base.dx - size * 0.2, base.dy - size * 0.52), size * 0.28, Paint()..color = const Color(0xFFFBCFE8));
    canvas.drawCircle(Offset(base.dx + size * 0.2, base.dy - size * 0.52), size * 0.30, Paint()..color = const Color(0xFFF43F5E));
  }

  void _drawPineTree(Canvas canvas, Offset base, double size) {
    canvas.drawRect(Rect.fromLTWH(base.dx - 4, base.dy - 16, 8, 16), Paint()..color = const Color(0xFF78350F));
    final p = Paint()..color = const Color(0xFF166534);
    for (int tier = 0; tier < 3; tier++) {
      final tierY = base.dy - 12 - tier * (size * 0.28);
      final tierW = (size * 0.5) * (1.0 - tier * 0.22);
      final path = Path()
        ..moveTo(base.dx - tierW, tierY)
        ..lineTo(base.dx, tierY - size * 0.34)
        ..lineTo(base.dx + tierW, tierY)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  void _drawWindmill(Canvas canvas, Offset base, double height, double scroll) {
    // Tower
    final tower = Path()
      ..moveTo(base.dx - 8, base.dy)
      ..lineTo(base.dx - 3, base.dy - height)
      ..lineTo(base.dx + 3, base.dy - height)
      ..lineTo(base.dx + 8, base.dy)
      ..close();
    canvas.drawPath(tower, Paint()..color = Colors.white);
    // Rotor Hub
    final hubCenter = Offset(base.dx, base.dy - height);
    canvas.drawCircle(hubCenter, 4, Paint()..color = const Color(0xFF64748B));
    // 3 Turning Blades
    final bladeAngle = scroll * 0.04;
    for (int b = 0; b < 3; b++) {
      final angle = bladeAngle + b * (2 * pi / 3);
      final tip = hubCenter + Offset(cos(angle) * 32, sin(angle) * 32);
      canvas.drawLine(hubCenter, tip, Paint()..color = Colors.white..strokeWidth = 3);
    }
  }

  void _drawStreetLamp(Canvas canvas, Offset base, double height) {
    final postPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 2.5;
    canvas.drawLine(base, Offset(base.dx, base.dy - height), postPaint);
    canvas.drawLine(Offset(base.dx, base.dy - height), Offset(base.dx + 12, base.dy - height + 4), postPaint);
    // Lamp Head
    canvas.drawCircle(Offset(base.dx + 12, base.dy - height + 6), 5, Paint()..color = const Color(0xFFFFD166));
    // Warm Light Cone
    final cone = Path()
      ..moveTo(base.dx + 12, base.dy - height + 8)
      ..lineTo(base.dx + 2, base.dy)
      ..lineTo(base.dx + 24, base.dy)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFFFD166).withValues(alpha: 0.15));
  }

  void _drawTrafficSign(Canvas canvas, Offset base, String emoji) {
    canvas.drawLine(base, Offset(base.dx, base.dy - 36), Paint()..color = const Color(0xFF64748B)..strokeWidth = 2.5);
    canvas.drawCircle(Offset(base.dx, base.dy - 44), 11, Paint()..color = const Color(0xFFFFCA28));
  }

  // 4. 근경 고속도로 (Realistic Asphalt Highway, Continuous Center Dashes & Curbs)
  void _drawHighwayRoad(Canvas canvas, double w, double h, double scroll) {
    final roadTop = h * 0.65;
    final roadBottom = h * 0.88;
    final roadH = roadBottom - roadTop;

    // Sidewalk pavement curb (인도 보도블럭 베이스)
    canvas.drawRect(Rect.fromLTWH(0, roadTop - 14, w, 14), Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawRect(Rect.fromLTWH(0, roadTop - 4, w, 4), Paint()..color = const Color(0xFF94A3B8));

    // Asphalt Main Surface (고급 아스팔트)
    canvas.drawRect(Rect.fromLTWH(0, roadTop, w, roadH), Paint()..color = const Color(0xFF1E293B));

    // Road Texture Grain Gradient
    final asphaltGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF334155),
        const Color(0xFF1E293B),
        const Color(0xFF0F172A),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, roadTop, w, roadH),
      Paint()..shader = asphaltGrad.createShader(Rect.fromLTWH(0, roadTop, w, roadH)),
    );

    // Continuous Scrolling Dashed Yellow Center Lines (순방향 이동)
    final double dashLength = 36.0;
    final double dashGap = 24.0;
    final double dashCycle = dashLength + dashGap; // 60px
    final double dashOffset = scroll % dashCycle;

    final dashPaint = Paint()..color = const Color(0xFFFFD166);
    final catEyePaint = Paint()..color = const Color(0xFFFF9F1C);

    for (double x = -dashOffset - dashCycle; x < w + dashCycle; x += dashCycle) {
      // Dashed lane
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, roadTop + roadH * 0.48, dashLength, 5), const Radius.circular(2.5)),
        dashPaint,
      );
      // Reflective Cat-Eye Stud (야간 반사 표지병)
      canvas.drawCircle(Offset(x + dashLength / 2, roadTop + roadH * 0.48 + 2.5), 2.5, catEyePaint);
    }

    // Top & Bottom Solid White Edge Lines
    final edgePaint = Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 3.5;
    canvas.drawLine(Offset(0, roadTop + 4), Offset(w, roadTop + 4), edgePaint);
    canvas.drawLine(Offset(0, roadBottom - 4), Offset(w, roadBottom - 4), edgePaint);

    // Modern Guardrail with Red/White Reflectors (상단 안전 가드레일)
    final railY = roadTop - 12;
    canvas.drawLine(Offset(0, railY), Offset(w, railY), Paint()..color = const Color(0xFFE2E8F0)..strokeWidth = 3);
    for (double x = -(scroll % 80); x < w + 80; x += 80) {
      // Guardrail post
      canvas.drawLine(Offset(x, railY), Offset(x, roadTop), Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 3.5);
      // Red/White Chevron Reflector
      canvas.drawRect(Rect.fromLTWH(x - 4, railY - 4, 8, 8), Paint()..color = const Color(0xFFEF4444));
      canvas.drawRect(Rect.fromLTWH(x - 2, railY - 4, 4, 8), Paint()..color = Colors.white);
    }

    // Bottom Grass & Flower Border
    canvas.drawRect(Rect.fromLTWH(0, roadBottom, w, h - roadBottom), Paint()..color = const Color(0xFF22C55E));
    for (double x = -(scroll % 50); x < w + 50; x += 50) {
      canvas.drawCircle(Offset(x + 12, roadBottom + 12), 4, Paint()..color = const Color(0xFFFF6EB4));
      canvas.drawCircle(Offset(x + 32, roadBottom + 16), 3.5, Paint()..color = const Color(0xFFFFD166));
    }
  }

  @override
  bool shouldRepaint(covariant _TestDrivePainter old) =>
      old.progress != progress || old.cloudProgress != cloudProgress;
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE PAINTERS
// ═══════════════════════════════════════════════════════════════════════════════

class _SparkleParticle {
  Offset pos;
  Offset vel;
  double life;
  Color color;
  _SparkleParticle({required this.pos, required this.vel, required this.life, required this.color});
}

class _ConfettiDot {
  Offset pos;
  Offset vel;
  Color color;
  double size;
  _ConfettiDot({required this.pos, required this.vel, required this.color, required this.size});
}

class _SparklePainter extends CustomPainter {
  final List<_SparkleParticle> sparkles;
  _SparklePainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0, 1))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, 3 + s.life * 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) => true;
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiDot> confetti;
  _ConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in confetti) {
      canvas.drawCircle(c.pos, c.size, Paint()..color = c.color);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}
