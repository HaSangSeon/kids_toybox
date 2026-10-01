part of '../car_wash_game.dart';

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

