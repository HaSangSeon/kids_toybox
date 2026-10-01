part of '../car_builder_game.dart';

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

