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

/// 차종 ID → 배경 씬 테마 매핑
const Map<String, _SceneTheme> _kChassisScene = {
  'sedan':     _SceneTheme.coastal,   // 해안가 드라이브
  'truck':     _SceneTheme.mountain,  // 산속 도로
  'sports':    _SceneTheme.coastal,   // 해안가 고속도로
  'police':    _SceneTheme.city,      // 맑은 낮 도심 순찰 (검은색 차체가 선명하게 잘 보임)
  'ambulance': _SceneTheme.suburb,    // 주택가 도로
  'monster':   _SceneTheme.offroad,   // 오프로드 황야
  'bus':       _SceneTheme.park,      // 공원 가로수길
  'rocket':    _SceneTheme.space,     // 우주 런치패드
};

enum _SceneTheme { coastal, mountain, city, night, suburb, offroad, park, space }

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

    AudioManager.instance.playSnap();
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

    AudioManager.instance.playSnap();
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
      AudioManager.instance.playVehicleSound(vehicleSound);
      AudioManager.instance.playEngine();
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
                        AudioManager.instance.playSnap();
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

    AudioManager.instance.playSnap();
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
class _SceneBackgroundPainter extends CustomPainter {
  final _SceneTheme theme;
  final double animValue;
  final bool isHovered;

  _SceneBackgroundPainter({
    required this.theme,
    this.animValue = 0.0,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (theme) {
      case _SceneTheme.coastal:
        _paintCoastal(canvas, size);
      case _SceneTheme.mountain:
        _paintMountain(canvas, size);
      case _SceneTheme.city:
        _paintCity(canvas, size);
      case _SceneTheme.night:
        _paintNight(canvas, size);
      case _SceneTheme.suburb:
        _paintSuburb(canvas, size);
      case _SceneTheme.offroad:
        _paintOffroad(canvas, size);
      case _SceneTheme.park:
        _paintPark(canvas, size);
      case _SceneTheme.space:
        _paintSpace(canvas, size);
    }
    // Car ground shadow with breathing pulse
    final shadowPulse = 1.0 + sin(animValue * 2 * pi) * 0.04;
    final shadowRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.77),
      width: size.width * 0.76 * shadowPulse,
      height: 15,
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  // ── 1. 해안가 도로 (넘실거리는 파도 + 활공하는 갈매기 + 반짝이는 태양) ─────────
  void _paintCoastal(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    // Sky gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF0288D1), Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Pulsing Sun with rays
    final sunGlow = 1.0 + sin(animValue * 2 * pi) * 0.08;
    canvas.drawCircle(Offset(w * 0.82, h * 0.18), 34 * sunGlow,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(Offset(w * 0.82, h * 0.18), 24,
      Paint()..color = const Color(0xFFFFEB3B));

    // Distant Living Ocean with Moving Waves
    final seaPath = Path()
      ..moveTo(0, h * 0.50);
    for (double x = 0; x <= w; x += 15) {
      final waveY = h * 0.50 + sin((x / w * 4 * pi) + (animValue * 2 * pi)) * 3;
      seaPath.lineTo(x, waveY);
    }
    seaPath.lineTo(w, h * 0.68);
    seaPath.lineTo(0, h * 0.68);
    seaPath.close();

    canvas.drawPath(seaPath, Paint()..shader = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF0288D1), Color(0xFF01579B)],
    ).createShader(Rect.fromLTWH(0, h * 0.50, w, h * 0.18)));

    // Animated Frothy Wave Crests
    final wavePaint = Paint()..color = Colors.white.withValues(alpha: 0.65)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (int i = 0; i < 2; i++) {
      final baseY = h * (0.54 + i * 0.06);
      final waveCrest = Path()..moveTo(0, baseY);
      for (double x = 0; x <= w; x += 16) {
        final wy = baseY + sin((x / w * 5 * pi) + (animValue * 2 * pi) + (i * pi)) * 2.5;
        waveCrest.lineTo(x, wy);
      }
      canvas.drawPath(waveCrest, wavePaint);
    }

    // Sandy Beach
    canvas.drawRect(Rect.fromLTWH(0, h * 0.68, w, h * 0.10),
      Paint()..color = const Color(0xFFFFE082));

    // Road
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = const Color(0xFF455A64));
    _drawRoadMarkings(canvas, size, h * 0.88);

    // Flying Animated Seagulls (Flapping Wings across the sky)
    final birdPaint = Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final flapAngle = sin(animValue * 4 * pi) * 4.0;
    for (int i = 0; i < 3; i++) {
      final birdProgress = (animValue + i * 0.33) % 1.0;
      final bx = -20 + birdProgress * (w + 40);
      final by = h * (0.12 + i * 0.07) + sin(birdProgress * 2 * pi) * 6;
      final bCenter = Offset(bx, by);

      // Left wing & Right wing
      final wing = Path()
        ..moveTo(bCenter.dx - 12, bCenter.dy + flapAngle)
        ..quadraticBezierTo(bCenter.dx - 6, bCenter.dy - 6, bCenter.dx, bCenter.dy)
        ..quadraticBezierTo(bCenter.dx + 6, bCenter.dy - 6, bCenter.dx + 12, bCenter.dy + flapAngle);
      canvas.drawPath(wing, birdPaint);
    }

    // Swaying Palm Trees (Slight wind sway)
    final sway = sin(animValue * 2 * pi) * 3;
    _drawPalmTree(canvas, Offset(w * 0.08 + sway, h * 0.70), 0.95);
    _drawPalmTree(canvas, Offset(w * 0.90 - sway * 0.7, h * 0.72), 0.80);
  }

  // ── 2. 산속 도로 (흘러가는 구름 + 맑은 솔바람) ─────────────────────────────
  void _paintMountain(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFFA7F3D0)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Far mountains with snow caps
    _drawMountain(canvas, Offset(w * -0.05, h * 0.55), w * 0.45, h * 0.38, const Color(0xFF64748B));
    _drawMountain(canvas, Offset(w * 0.35, h * 0.48), w * 0.50, h * 0.45, const Color(0xFF475569));
    _drawSnowCap(canvas, Offset(w * 0.60, h * 0.48), w * 0.12);
    _drawMountain(canvas, Offset(w * 0.65, h * 0.52), w * 0.42, h * 0.40, const Color(0xFF64748B));

    // Near Lush Green Hills
    _drawMountain(canvas, Offset(w * -0.10, h * 0.72), w * 0.55, h * 0.38, const Color(0xFF16A34A));
    _drawMountain(canvas, Offset(w * 0.55, h * 0.72), w * 0.60, h * 0.38, const Color(0xFF15803D));

    // Ground & Asphalt Mountain Road
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20),
      Paint()..color = const Color(0xFF22C55E));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22),
      Paint()..color = const Color(0xFF334155));
    _drawRoadMarkings(canvas, size, h * 0.88, color: const Color(0xFFFBBF24));

    // Animated drifting clouds in the mountains
    final cloudX1 = ((animValue * w * 0.8) % (w + 100)) - 50;
    _drawCloud(canvas, Offset(cloudX1, h * 0.12), 0.9);
    final cloudX2 = (((animValue + 0.5) * w * 0.6) % (w + 100)) - 50;
    _drawCloud(canvas, Offset(cloudX2, h * 0.22), 0.7);

    // Pine Trees
    for (final x in [0.04, 0.12, 0.85, 0.93]) {
      _drawPineTree(canvas, Offset(w * x, h * 0.79), 0.85);
    }
  }

  // ── 3. 도시 고속도로 (깜빡이는 창문 불빛 + 가로등) ─────────────────────────
  void _paintCity(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF60A5FA), Color(0xFF93C5FD), Color(0xFFE0F2FE)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Buildings
    final buildingData = [
      [0.0, 0.55, 0.15, 0.45, 0xFF334155],
      [0.12, 0.40, 0.12, 0.60, 0xFF1E293B],
      [0.22, 0.50, 0.10, 0.50, 0xFF475569],
      [0.72, 0.42, 0.13, 0.58, 0xFF1E293B],
      [0.83, 0.50, 0.10, 0.50, 0xFF334155],
      [0.91, 0.44, 0.12, 0.56, 0xFF475569],
    ];
    for (final b in buildingData) {
      final bx = w * b[0]; final by = h * b[1]; final bw = w * b[2]; final bh = h * b[3];
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), Paint()..color = Color(b[4].toInt()));

      // Animated glowing windows
      final winPaint = Paint()..color = const Color(0xFFFEF08A);
      for (double wy = by + 8; wy < by + bh - 10; wy += 14) {
        for (double wx = bx + 5; wx < bx + bw - 5; wx += 12) {
          final isBlinking = ((wx + wy + animValue * 10).toInt() % 5 == 0);
          if (!isBlinking) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 6, 8), winPaint);
          }
        }
      }
    }

    // Sidewalk & Express Road
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.04), Paint()..color = const Color(0xFF94A3B8));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF1E293B));
    _drawRoadMarkings(canvas, size, h * 0.88);

    // Street lamps with glowing aura
    _drawStreetLamp(canvas, Offset(w * 0.06, h * 0.78));
    _drawStreetLamp(canvas, Offset(w * 0.92, h * 0.78));
  }

  // ── 4. 야간 도시 (반짝이는 별빛 + 사이렌 빛 반사) ────────────────────────
  void _paintNight(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF030712), Color(0xFF0F172A), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Twinkling Stars
    final starPaint = Paint()..color = Colors.white;
    final rng = Random(42);
    for (int i = 0; i < 35; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * h * 0.50;
      final twinkle = (sin((animValue * 2 * pi) + (i * 0.8)) + 1.0) / 2.0;
      canvas.drawCircle(Offset(sx, sy), 0.5 + twinkle * 1.5, starPaint..color = Colors.white.withValues(alpha: 0.3 + twinkle * 0.7));
    }

    // Glowing Moon
    final moonGlow = 1.0 + sin(animValue * 2 * pi) * 0.05;
    canvas.drawCircle(Offset(w * 0.82, h * 0.16), 26 * moonGlow,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(Offset(w * 0.82, h * 0.16), 18, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(Offset(w * 0.87, h * 0.14), 15, Paint()..color = const Color(0xFF0F172A));

    // Dark Silhouette Buildings
    final buildingData = [
      [0.0, 0.45, 0.15, 0.55], [0.13, 0.30, 0.12, 0.70],
      [0.24, 0.40, 0.10, 0.60], [0.72, 0.35, 0.13, 0.65],
      [0.84, 0.42, 0.10, 0.58], [0.92, 0.30, 0.10, 0.70],
    ];
    for (final b in buildingData) {
      final bx = w * b[0]; final by = h * b[1]; final bw = w * b[2]; final bh = h * b[3];
      canvas.drawRect(Rect.fromLTWH(bx, by, bw, bh), Paint()..color = const Color(0xFF0B0F19));
      final winPaint = Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.65);
      for (double wy = by + 6; wy < by + bh - 8; wy += 14) {
        for (double wx = bx + 4; wx < bx + bw - 4; wx += 11) {
          if (Random(wx.toInt() + wy.toInt()).nextBool()) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), winPaint);
          }
        }
      }
    }

    // Asphalt Road
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF111827));
    _drawRoadMarkings(canvas, size, h * 0.88, color: const Color(0x99FFFFFF));

    // Alternating Police Siren Glow Effect on City Scene
    final isRedTurn = ((animValue * 6).toInt() % 2 == 0);
    final sirenColor = isRedTurn ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.60),
      60,
      Paint()
        ..color = sirenColor.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  // ── 5. 주택가 도로 (아기자기한 집 + 가로수길) ────────────────────────────
  void _paintSuburb(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF38BDF8), Color(0xFFBAE6FD), Color(0xFF86EFAC)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Cute houses
    _drawHouse(canvas, Offset(w * 0.02, h * 0.70), const Color(0xFFFCA5A5), const Color(0xFFDC2626));
    _drawHouse(canvas, Offset(w * 0.76, h * 0.70), const Color(0xFFFDBA74), const Color(0xFFEA580C));

    // Green Grass & Suburban Street
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.04), Paint()..color = const Color(0xFF22C55E));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF475569));
    _drawRoadMarkings(canvas, size, h * 0.88);

    // Drifting clouds
    final cX = ((animValue * w) % (w + 80)) - 40;
    _drawCloud(canvas, Offset(cX, h * 0.10), 0.85);

    // Round Trees
    _drawRoundTree(canvas, Offset(w * 0.38, h * 0.72), const Color(0xFF16A34A));
    _drawRoundTree(canvas, Offset(w * 0.62, h * 0.74), const Color(0xFF15803D));
  }

  // ── 6. 오프로드 황야 (석양 열기 + 부유하는 흙먼지) ─────────────────────────
  void _paintOffroad(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFEA580C), Color(0xFFF59E0B), Color(0xFFDC2626)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Giant Glowing Sunset
    final sunPulse = 1.0 + sin(animValue * 2 * pi) * 0.06;
    canvas.drawCircle(Offset(w * 0.50, h * 0.52), 48 * sunPulse,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawCircle(Offset(w * 0.50, h * 0.52), 34,
      Paint()..color = const Color(0xFFFEF08A));

    // Cacti
    _drawCactus(canvas, Offset(w * 0.10, h * 0.65));
    _drawCactus(canvas, Offset(w * 0.88, h * 0.68));

    // Rocks & Dirt Road
    final rockPaint = Paint()..color = const Color(0xFF78350F);
    for (final rx in [0.12, 0.35, 0.55, 0.78, 0.92]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(w * rx, h * 0.77), width: w * 0.12, height: h * 0.05), rockPaint);
    }
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF92400E));

    // Tire Tracks
    final trackPaint = Paint()..color = const Color(0xFF451A03)..strokeWidth = 3;
    canvas.drawLine(Offset(0, h * 0.85), Offset(w, h * 0.85), trackPaint);
    canvas.drawLine(Offset(0, h * 0.91), Offset(w, h * 0.91), trackPaint);

    // Floating Dust Clouds
    final dustOffset = sin(animValue * 2 * pi) * 8;
    final dustPaint = Paint()..color = const Color(0xFFFDE68A).withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(w * 0.18 + dustOffset, h * 0.80), 24, dustPaint);
    canvas.drawCircle(Offset(w * 0.82 - dustOffset, h * 0.82), 20, dustPaint);
  }

  // ── 7. 공원 가로수길 (봄바람 꽃잎 + 푸른 나무) ───────────────────────────
  void _paintPark(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF60A5FA), Color(0xFFBAE6FD), Color(0xFF86EFAC)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Clouds
    _drawCloud(canvas, Offset(w * 0.12, h * 0.10), 1.0);
    _drawCloud(canvas, Offset(w * 0.65, h * 0.08), 0.8);

    // Park Road & Grass
    canvas.drawRect(Rect.fromLTWH(0, h * 0.72, w, h * 0.08), Paint()..color = const Color(0xFF22C55E));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF475569));
    _drawRoadMarkings(canvas, size, h * 0.88);

    // Rows of Trees
    for (final x in [0.05, 0.20, 0.78, 0.94]) {
      _drawRoundTree(canvas, Offset(w * x, h * 0.74), const Color(0xFF15803D));
    }

    // Floating colorful flower petals in the spring breeze
    final flowerColors = [const Color(0xFFF472B6), const Color(0xFFFBBF24), const Color(0xFFFB7185)];
    for (int i = 0; i < 8; i++) {
      final pX = ((animValue + i * 0.125) * w) % w;
      final pY = h * 0.70 + sin((animValue * 2 * pi) + i) * 12;
      canvas.drawCircle(Offset(pX, pY), 3.5, Paint()..color = flowerColors[i % flowerColors.length]);
    }
  }

  // ── 8. 우주 런치패드 (빛나는 은하 + 혜성 활공) ───────────────────────────
  void _paintSpace(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF030712), Color(0xFF1E1B4B), Color(0xFF4C1D95)],
      ).createShader(Rect.fromLTWH(0, 0, w, h)));

    // Stars
    final starPaint = Paint()..color = Colors.white;
    final rng = Random(99);
    for (int i = 0; i < 45; i++) {
      final sx = rng.nextDouble() * w;
      final sy = rng.nextDouble() * h * 0.65;
      final pulse = (sin((animValue * 3 * pi) + (i * 0.7)) + 1.0) / 2.0;
      canvas.drawCircle(Offset(sx, sy), 0.8 + pulse * 1.6, starPaint..color = Colors.white.withValues(alpha: 0.3 + pulse * 0.7));
    }

    // Shooting Star (Comet) crossing space
    final cometProgress = (animValue * 1.5) % 1.0;
    if (cometProgress < 0.6) {
      final cometStart = Offset(w * 0.10 + cometProgress * w * 1.2, h * 0.05 + cometProgress * h * 0.4);
      final cometEnd = cometStart + const Offset(-35, -18);
      canvas.drawLine(
        cometStart, cometEnd,
        Paint()..shader = LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.0)]).createShader(Rect.fromPoints(cometStart, cometEnd))..strokeWidth = 2.5,
      );
    }

    // Giant Glowing Planet with Ring
    canvas.drawCircle(Offset(w * 0.80, h * 0.18), 24, Paint()..color = const Color(0xFF8B5CF6));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.80, h * 0.18), width: 56, height: 14),
      Paint()
        ..color = const Color(0xFFC084FC).withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );

    // Launch Pad Surface
    canvas.drawRect(Rect.fromLTWH(0, h * 0.78, w, h * 0.22), Paint()..color = const Color(0xFF1E1B4B));
    final padPaint = Paint()..color = const Color(0xFF8B5CF6).withValues(alpha: 0.6)..strokeWidth = 2;
    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, h * 0.78), Offset(x + 14, h * 1.0), padPaint);
    }

    // Rocket Engine Plasma Glow on Ground
    final plasmaPulse = 1.0 + sin(animValue * 6 * pi) * 0.15;
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.78),
      34 * plasmaPulse,
      Paint()
        ..color = const Color(0xFFF97316).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
  }

  // ── 공통 도우미 메서드 ────────────────────────────────────────────────────

  void _drawRoadMarkings(Canvas canvas, Size size, double y, {Color? color}) {
    final paint = Paint()
      ..color = (color ?? const Color(0xFFFFFFFF)).withValues(alpha: 0.75)
      ..strokeWidth = 3;
    final w = size.width;
    const dashW = 28.0; const gapW = 20.0;
    for (double x = 0; x < w; x += dashW + gapW) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.88);
    for (final d in [
      Offset(0, 0), Offset(14 * scale, -6 * scale),
      Offset(28 * scale, 0), Offset(14 * scale, 4 * scale),
    ]) {
      canvas.drawCircle(center + d, 14 * scale, paint);
    }
  }

  void _drawMountain(Canvas canvas, Offset base, double width, double height, Color color) {
    final path = Path()
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx + width / 2, base.dy - height)
      ..lineTo(base.dx + width, base.dy)..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawSnowCap(Canvas canvas, Offset tip, double width) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - width, tip.dy + width * 1.2)
      ..lineTo(tip.dx + width, tip.dy + width * 1.2)..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.85));
  }

  void _drawPineTree(Canvas canvas, Offset base, double scale) {
    final paint = Paint()..color = const Color(0xFF166534);
    // trunk
    canvas.drawRect(Rect.fromLTWH(base.dx - 3 * scale, base.dy - 6 * scale, 6 * scale, 10 * scale),
      Paint()..color = const Color(0xFF78350F));
    // three triangle layers
    for (int i = 0; i < 3; i++) {
      final ty = base.dy - 12 * scale - i * 18 * scale;
      final tw = (36 - i * 8) * scale;
      final path = Path()
        ..moveTo(base.dx, ty - 20 * scale)
        ..lineTo(base.dx - tw / 2, ty)
        ..lineTo(base.dx + tw / 2, ty)..close();
      canvas.drawPath(path, paint);
    }
  }

  void _drawRoundTree(Canvas canvas, Offset base, Color color) {
    canvas.drawRect(Rect.fromLTWH(base.dx - 3, base.dy - 14, 6, 18), Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(base + const Offset(0, -20), 18, Paint()..color = color);
    canvas.drawCircle(base + const Offset(-10, -14), 13, Paint()..color = color);
    canvas.drawCircle(base + const Offset(10, -14), 13, Paint()..color = color);
  }

  void _drawPalmTree(Canvas canvas, Offset base, double scale) {
    // trunk (curved)
    final trunkPaint = Paint()..color = const Color(0xFF9A3412)..strokeWidth = 5 * scale..style = PaintingStyle.stroke;
    final trunk = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(base.dx + 8 * scale, base.dy - 22 * scale, base.dx + 2 * scale, base.dy - 48 * scale);
    canvas.drawPath(trunk, trunkPaint);
    // leaves
    for (int i = 0; i < 5; i++) {
      final angle = -1.2 + i * 0.6;
      final leafPath = Path()
        ..moveTo(base.dx + 2 * scale, base.dy - 48 * scale)
        ..quadraticBezierTo(
          base.dx + 2 * scale + cos(angle) * 20 * scale,
          base.dy - 48 * scale + sin(angle) * 20 * scale,
          base.dx + 2 * scale + cos(angle) * 36 * scale,
          base.dy - 48 * scale + sin(angle - 0.4) * 10 * scale,
        );
      canvas.drawPath(leafPath, Paint()..color = const Color(0xFF15803D)..strokeWidth = 5 * scale..style = PaintingStyle.stroke);
    }
  }

  void _drawCactus(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0xFF15803D);
    // Main trunk
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - 6, base.dy - 44, 12, 44), const Radius.circular(6)), paint);
    // Left arm
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - 20, base.dy - 32, 14, 8), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx - 22, base.dy - 44, 8, 16), const Radius.circular(4)), paint);
    // Right arm
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx + 6, base.dy - 28, 14, 8), const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(base.dx + 14, base.dy - 40, 8, 16), const Radius.circular(4)), paint);
  }

  void _drawHouse(Canvas canvas, Offset base, Color wallColor, Color roofColor) {
    // Wall
    canvas.drawRect(Rect.fromLTWH(base.dx, base.dy - 30, 58, 30), Paint()..color = wallColor);
    // Roof
    final roof = Path()
      ..moveTo(base.dx - 4, base.dy - 30)
      ..lineTo(base.dx + 29, base.dy - 56)
      ..lineTo(base.dx + 62, base.dy - 30)..close();
    canvas.drawPath(roof, Paint()..color = roofColor);
    // Door
    canvas.drawRect(Rect.fromLTWH(base.dx + 22, base.dy - 18, 14, 18), Paint()..color = const Color(0xFF78350F));
    // Window
    canvas.drawRect(Rect.fromLTWH(base.dx + 6, base.dy - 24, 12, 10), Paint()..color = const Color(0xFF38BDF8));
  }

  void _drawStreetLamp(Canvas canvas, Offset base) {
    final paint = Paint()..color = const Color(0xFF94A3B8)..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawLine(base, base + const Offset(0, -36), paint);
    canvas.drawLine(base + const Offset(0, -36), base + const Offset(12, -44), paint);
    canvas.drawCircle(base + const Offset(12, -44), 5, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawCircle(base + const Offset(12, -44), 12,
      Paint()..color = const Color(0xFFFEF08A).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }

  @override
  bool shouldRepaint(covariant _SceneBackgroundPainter old) =>
      old.theme != theme || old.animValue != animValue || old.isHovered != isHovered;
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

  // 1. 승용차 (Sedan) — 오른쪽이 앞(본넷 & 윈드실드), 왼쪽이 뒤(트렁크)
  void _drawSedan(Canvas canvas, double w, double h) {
    final bodyPaint = Paint()..color = color;
    final bodyRect = Rect.fromLTWH(w * 0.08, h * 0.44, w * 0.84, h * 0.32);

    // Shadow & Body
    _drawShadow(canvas, bodyRect);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), bodyPaint);

    // Cabin (왼쪽 트렁크에서 올라가서, 전면 윈드실드는 완만하게 오른쪽 본넷으로 연결)
    final cabinPath = Path()
      ..moveTo(w * 0.20, h * 0.44) // 트렁크 시작점
      ..lineTo(w * 0.28, h * 0.22) // 뒷유리 (가파른 각도)
      ..lineTo(w * 0.58, h * 0.22) // 루프
      ..quadraticBezierTo(w * 0.68, h * 0.24, w * 0.78, h * 0.44) // 완만하게 뻗는 전면 윈드실드
      ..close();
    canvas.drawPath(cabinPath, bodyPaint);

    // 뒷좌석 창문 & 앞좌석 운전석 창문
    _drawWindow(canvas, Rect.fromLTWH(w * 0.28, h * 0.24, w * 0.18, h * 0.19));
    _drawWindow(canvas, Rect.fromLTWH(w * 0.50, h * 0.24, w * 0.22, h * 0.19));

    // B-Pillar Door line & Chrome Handle
    canvas.drawLine(Offset(w * 0.48, h * 0.24), Offset(w * 0.48, h * 0.72), Paint()..color = Colors.black26..strokeWidth = 2.5);
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

  // 3. 경찰차 (Police Car) — 흑백 투톤 + POLICE 배지 + 범퍼 가드 + 선명한 윤곽선
  void _drawPoliceCar(Canvas canvas, double w, double h) {
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final whitePaint = Paint()..color = Colors.white;
    final outlinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bodyRect = Rect.fromLTWH(w * 0.10, h * 0.44, w * 0.80, h * 0.32);
    _drawShadow(canvas, bodyRect);

    // Front/Rear Black body & high contrast silver outline
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), darkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(16)), outlinePaint);

    // Center White Door Section (경찰차 특유의 도어 화이트 도색)
    final doorRect = Rect.fromLTWH(w * 0.36, h * 0.44, w * 0.34, h * 0.32);
    canvas.drawRect(doorRect, whitePaint);
    canvas.drawRect(doorRect, Paint()..color = const Color(0xFFCBD5E1)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Police Star Badge & Text
    canvas.drawCircle(Offset(w * 0.53, h * 0.58), 12, Paint()..color = const Color(0xFFFFD700));
    canvas.drawCircle(Offset(w * 0.53, h * 0.58), 9, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(w * 0.53, h * 0.58), 4, Paint()..color = const Color(0xFFFFD700));

    // Cabin
    final cabinPath = Path()
      ..moveTo(w * 0.28, h * 0.44)
      ..lineTo(w * 0.38, h * 0.22)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.80, h * 0.44)
      ..close();
    canvas.drawPath(cabinPath, darkPaint);
    canvas.drawPath(cabinPath, outlinePaint);

    // White Roof top
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.20, w * 0.36, 6), const Radius.circular(3)), whitePaint);

    // Windows
    _drawWindow(canvas, Rect.fromLTWH(w * 0.38, h * 0.24, w * 0.16, h * 0.19));
    _drawWindow(canvas, Rect.fromLTWH(w * 0.56, h * 0.24, w * 0.16, h * 0.19));

    // Front Push-Bar (경찰 범퍼 가드 - 눈에 띄는 밝은 크롬 실버)
    final pushBar = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 4;
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
