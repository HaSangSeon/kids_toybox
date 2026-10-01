part of '../firefighter_game.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum FireGamePhase {
  missionSelect, // 미션 선택
  dispatch,      // 🚨 긴급 출동 질주
  extinguish,    // 🔥 물대포 화재 진압
  rescue,        // 🪜/🛟 동물 친구 에어매트 구출
  celebrate,     // 🎉 명예 소방관 배지 & 무지개 분수
}

class FireSpot {
  final int id;
  final String label;
  final Offset relativePos; // (0.0~1.0, 0.0~1.0)
  final double radius;
  double hp; // 100.0 -> 0.0
  bool isExtinguished;
  final String? trappedAnimal; // 동물 이모지 (예: 🐱)
  final String? animalName;

  double flamePhase;

  FireSpot({
    required this.id,
    required this.label,
    required this.relativePos,
    required this.radius,
    this.hp = 100.0,
    this.isExtinguished = false,
    this.trappedAnimal,
    this.animalName,
    this.flamePhase = 0.0,
  });
}

class FireMission {
  final int id;
  final String title;
  final String subTitle;
  final String emoji;
  final List<Color> skyGradient;
  final String buildingType; // 'apartment', 'forest', 'castle'
  final List<FireSpot> spots;
  final String rescuedAnimal;
  final String rescuedAnimalName;
  final String clearComment;

  FireMission({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.emoji,
    required this.skyGradient,
    required this.buildingType,
    required this.spots,
    required this.rescuedAnimal,
    required this.rescuedAnimalName,
    required this.clearComment,
  });
}

List<FireMission> _buildMissions() {
  return [
    FireMission(
      id: 1,
      title: '도심 아파트 큰불 진압',
      subTitle: '3층 창문에 아기 고양이가 갇혔어요! 삐뽀삐뽀!',
      emoji: '🏢',
      skyGradient: [const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFFE0F2FE)],
      buildingType: 'apartment',
      rescuedAnimal: '🐱',
      rescuedAnimalName: '아기 고양이 나비',
      clearComment: '야옹~ 고마워요 소방관님! 시원한 물로 불을 다 껐어요! 💖',
      spots: [
        FireSpot(id: 1, label: '3층 옥상', relativePos: const Offset(0.50, 0.30), radius: 42, flamePhase: 0.1),
        FireSpot(id: 2, label: '2층 왼쪽 창문', relativePos: const Offset(0.30, 0.46), radius: 38, flamePhase: 0.4),
        FireSpot(id: 3, label: '2층 오른쪽 창문', relativePos: const Offset(0.70, 0.46), radius: 38, trappedAnimal: '🐱', animalName: '아기 고양이', flamePhase: 0.7),
        FireSpot(id: 4, label: '1층 왼쪽 창문', relativePos: const Offset(0.30, 0.63), radius: 36, flamePhase: 0.2),
        FireSpot(id: 5, label: '1층 현관 입구', relativePos: const Offset(0.70, 0.63), radius: 36, flamePhase: 0.9),
      ],
    ),
    FireMission(
      id: 2,
      title: '푸른 숲속 산불 진압',
      subTitle: '숲속 큰 나무들이 불타고 있어요! 다람쥐를 구해요!',
      emoji: '🌲',
      skyGradient: [const Color(0xFF38BDF8), const Color(0xFF7DD3FC), const Color(0xFFF0FDF4)],
      buildingType: 'forest',
      rescuedAnimal: '🐿️',
      rescuedAnimalName: '꼬마 다람쥐 람이',
      clearComment: '찍찍! 숲속 친구들이 모두 안전해졌어요! 최고예요! 🌳',
      spots: [
        FireSpot(id: 1, label: '큰 참나무 꼭대기', relativePos: const Offset(0.30, 0.32), radius: 42, flamePhase: 0.3),
        FireSpot(id: 2, label: '단풍나무 가지', relativePos: const Offset(0.70, 0.34), radius: 40, trappedAnimal: '🐿️', animalName: '꼬마 다람쥐', flamePhase: 0.6),
        FireSpot(id: 3, label: '가운데 오두막집', relativePos: const Offset(0.50, 0.50), radius: 44, flamePhase: 0.1),
        FireSpot(id: 4, label: '풀숲 모닥불', relativePos: const Offset(0.24, 0.64), radius: 36, flamePhase: 0.8),
        FireSpot(id: 5, label: '오른쪽 덤불', relativePos: const Offset(0.76, 0.64), radius: 36, flamePhase: 0.5),
      ],
    ),
    FireMission(
      id: 3,
      title: '놀이동산 마법 성 구출',
      subTitle: '동화 속 성탑에 불이 났어요! 강아지를 구출해요!',
      emoji: '🏰',
      skyGradient: [const Color(0xFFA78BFA), const Color(0xFFC4B5FD), const Color(0xFFFDF4FF)],
      buildingType: 'castle',
      rescuedAnimal: '🐶',
      rescuedAnimalName: '용감한 강아지 멍이',
      clearComment: '멍멍! 마법 성이 반짝반짝 되살아났어요! 영웅 소방관 만세! 👑',
      spots: [
        FireSpot(id: 1, label: '중앙 높은 시계탑', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '왼쪽 뾰족탑', relativePos: const Offset(0.24, 0.42), radius: 38, flamePhase: 0.5),
        FireSpot(id: 3, label: '오른쪽 전망탑', relativePos: const Offset(0.76, 0.42), radius: 38, trappedAnimal: '🐶', animalName: '강아지 멍이', flamePhase: 0.8),
        FireSpot(id: 4, label: '성문 왼쪽 테라스', relativePos: const Offset(0.32, 0.60), radius: 36, flamePhase: 0.3),
        FireSpot(id: 5, label: '성문 오른쪽 테라스', relativePos: const Offset(0.68, 0.60), radius: 36, flamePhase: 0.7),
      ],
    ),
    FireMission(
      id: 4,
      title: '달콤한 빵집 구출 작전',
      subTitle: '달콤한 컵케이크 빵집에 불이 났어요! 곰돌이를 구해요!',
      emoji: '🧁',
      skyGradient: [const Color(0xFFFFB4A2), const Color(0xFFFFCDB2), const Color(0xFFFFF1E6)],
      buildingType: 'bakery',
      rescuedAnimal: '🐻',
      rescuedAnimalName: '아기 곰 곰이',
      clearComment: '달콤한 디저트 빵집을 안전하게 지켜줘서 고마워요! 🥐💖',
      spots: [
        FireSpot(id: 1, label: '컵케이크 옥상 간판', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '2층 딸기 창문', relativePos: const Offset(0.28, 0.44), radius: 38, flamePhase: 0.5),
        FireSpot(id: 3, label: '2층 초코 테라스', relativePos: const Offset(0.72, 0.44), radius: 38, trappedAnimal: '🐻', animalName: '아기 곰', flamePhase: 0.8),
        FireSpot(id: 4, label: '1층 빵 진열대', relativePos: const Offset(0.28, 0.62), radius: 36, flamePhase: 0.3),
        FireSpot(id: 5, label: '1층 오븐 출입구', relativePos: const Offset(0.72, 0.62), radius: 36, flamePhase: 0.6),
      ],
    ),
    FireMission(
      id: 5,
      title: '우주 로켓 기지 구출',
      subTitle: '발사대 우주선에 불꽃이 튀었어요! 우주 판다를 구해요!',
      emoji: '🚀',
      skyGradient: [const Color(0xFF3A6073), const Color(0xFF3A7BD5), const Color(0xFFE0EAFC)],
      buildingType: 'space',
      rescuedAnimal: '🐼',
      rescuedAnimalName: '우주비행사 판다',
      clearComment: '우주 탐사 로켓을 무사히 지켜냈어요! 판다도 신나요! 🚀✨',
      spots: [
        FireSpot(id: 1, label: '로켓 맨꼭대기 첨탑', relativePos: const Offset(0.50, 0.26), radius: 42, flamePhase: 0.1),
        FireSpot(id: 2, label: '우주선 왼쪽 날개', relativePos: const Offset(0.24, 0.42), radius: 40, flamePhase: 0.4),
        FireSpot(id: 3, label: '조종실 창문', relativePos: const Offset(0.76, 0.42), radius: 40, trappedAnimal: '🐼', animalName: '우주 판다', flamePhase: 0.7),
        FireSpot(id: 4, label: '부스터 엔진 1호', relativePos: const Offset(0.32, 0.62), radius: 38, flamePhase: 0.3),
        FireSpot(id: 5, label: '부스터 엔진 2호', relativePos: const Offset(0.68, 0.62), radius: 38, flamePhase: 0.9),
      ],
    ),
    FireMission(
      id: 6,
      title: '바다 위 보물선 구출',
      subTitle: '푸른 바다 위 멋진 해적선에 불이 났어요! 아기 사자를 구해요!',
      emoji: '🚢',
      skyGradient: [const Color(0xFF00B4DB), const Color(0xFF0083B0), const Color(0xFFE8F5E9)],
      buildingType: 'ship',
      rescuedAnimal: '🦁',
      rescuedAnimalName: '꼬마 선장 사자',
      clearComment: '어흥~! 바다의 보물선을 멋지게 구출했어요! 소방관님 최고! 🏴‍☠️👑',
      spots: [
        FireSpot(id: 1, label: '해적선 돛대 꼭대기', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '선장실 전망창', relativePos: const Offset(0.26, 0.44), radius: 38, trappedAnimal: '🦁', animalName: '꼬마 사자', flamePhase: 0.6),
        FireSpot(id: 3, label: '해적 깃발 돛', relativePos: const Offset(0.74, 0.44), radius: 40, flamePhase: 0.3),
        FireSpot(id: 4, label: '대포 발사 갑판', relativePos: const Offset(0.28, 0.62), radius: 36, flamePhase: 0.8),
        FireSpot(id: 5, label: '보물 상자 창고', relativePos: const Offset(0.72, 0.62), radius: 36, flamePhase: 0.5),
      ],
    ),
    FireMission(
      id: 7,
      title: '바닷가 등대 구출 작전',
      subTitle: '바위섬 위 하얀 등대에 불이 났어요! 아기 물개를 구해요!',
      emoji: '🗼',
      skyGradient: [const Color(0xFF0284C7), const Color(0xFF38BDF8), const Color(0xFFBAE6FD)],
      buildingType: 'lighthouse',
      rescuedAnimal: '🦭',
      rescuedAnimalName: '아기 물개 포롱이',
      clearComment: '바다의 길잡이 등대를 안전하게 지켜줘서 고마워요! 🦭🌊',
      spots: [
        FireSpot(id: 1, label: '등대 꼭대기 회전 조명실', relativePos: const Offset(0.50, 0.25), radius: 42, flamePhase: 0.1),
        FireSpot(id: 2, label: '등대 나선 관측창', relativePos: const Offset(0.38, 0.44), radius: 38, flamePhase: 0.4),
        FireSpot(id: 3, label: '등대지기 2층 침실', relativePos: const Offset(0.68, 0.44), radius: 38, trappedAnimal: '🦭', animalName: '아기 물개', flamePhase: 0.7),
        FireSpot(id: 4, label: '등대 1층 정문', relativePos: const Offset(0.38, 0.63), radius: 36, flamePhase: 0.2),
        FireSpot(id: 5, label: '바위섬 보급 창고', relativePos: const Offset(0.70, 0.63), radius: 36, flamePhase: 0.8),
      ],
    ),
    FireMission(
      id: 8,
      title: '하늘공항 관제탑 구출',
      subTitle: '비행기들이 착륙하는 관제탑에 불이 났어요! 토끼 기장님을 구해요!',
      emoji: '✈️',
      skyGradient: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6), const Color(0xFF93C5FD)],
      buildingType: 'airport',
      rescuedAnimal: '🐰',
      rescuedAnimalName: '토끼 기장 토토',
      clearComment: '하늘공항 관제탑을 지켜내 비행기들이 무사히 착륙했어요! ✈️🐰',
      spots: [
        FireSpot(id: 1, label: '관제탑 상단 레이더 돔', relativePos: const Offset(0.50, 0.24), radius: 42, flamePhase: 0.2),
        FireSpot(id: 2, label: '유리 관제실 서쪽', relativePos: const Offset(0.32, 0.42), radius: 38, flamePhase: 0.5),
        FireSpot(id: 3, label: '유리 관제실 동쪽', relativePos: const Offset(0.68, 0.42), radius: 38, trappedAnimal: '🐰', animalName: '토끼 기장', flamePhase: 0.8),
        FireSpot(id: 4, label: '1층 비행기 격납고', relativePos: const Offset(0.30, 0.63), radius: 36, flamePhase: 0.3),
        FireSpot(id: 5, label: '활주로 긴급 출동로', relativePos: const Offset(0.70, 0.63), radius: 36, flamePhase: 0.7),
      ],
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE SYSTEMS (Water Jet, Splashes, Embers, Smoke, Steam, Confetti)
// ═══════════════════════════════════════════════════════════════════════════════

class _WaterSplash {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;

  _WaterSplash({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.color,
  });
}

class _SteamParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  double maxLife;

  _SteamParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _EmberParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;

  _EmberParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.color,
  });
}

class _SmokeParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  double maxLife;

  _SmokeParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _ConfettiParticle {
  Offset pos;
  Offset vel;
  double size;
  Color color;
  double rotation;
  double rotSpeed;

  _ConfettiParticle({
    required this.pos,
    required this.vel,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

