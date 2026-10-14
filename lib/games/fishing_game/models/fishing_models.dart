part of '../fishing_game_game.dart';

// ── 바다 깊이 구역 (Zone) ──
enum OceanZone {
  sunlight('햇살 가득 구역 ☀️', [Color(0xFFE0F7FA), Color(0xFF4FC3F7)]),
  twilight('푸른 황혼 구역 🌊', [Color(0xFF0288D1), Color(0xFF01579B)]),
  abyssal('신비한 심해 구역 🌌', [Color(0xFF0D47A1), Color(0xFF000A21)]);

  final String name;
  final List<Color> colors;
  const OceanZone(this.name, this.colors);
}

// ── 물고기 어종 정의 ──
class FishSpecies {
  final String id;
  final String emoji;
  final String name;
  final OceanZone zone;
  final int points;
  final double baseSpeed;
  final bool isRare;
  final String funFact; // ✨ 아이들을 위한 교육용 상식

  const FishSpecies({
    required this.id,
    required this.emoji,
    required this.name,
    required this.zone,
    required this.points,
    required this.baseSpeed,
    this.isRare = false,
    required this.funFact,
  });
}

const List<FishSpecies> _speciesList = [
  // 1구역 (햇살 구역 ☀️)
  FishSpecies(
    id: 'clown',
    emoji: '🐠',
    name: '니모(흰동가리)',
    zone: OceanZone.sunlight,
    points: 10,
    baseSpeed: 90.0,
    funFact: '말미잘의 독에 걸리지 않고 친구처럼 함께 살아요! 🪸',
  ),
  FishSpecies(
    id: 'tang',
    emoji: '🐟',
    name: '도리(블루탱)',
    zone: OceanZone.sunlight,
    points: 10,
    baseSpeed: 100.0,
    funFact: '위험에 처하면 산호 틈에 쏙 숨어 죽은 척을 한대요! 🐠',
  ),
  FishSpecies(
    id: 'star',
    emoji: '⭐',
    name: '알록달록 불가사리',
    zone: OceanZone.sunlight,
    points: 15,
    baseSpeed: 40.0,
    funFact: '다리가 잘려도 다시 쑥쑥 자라나는 신비한 재생력을 가졌어요! ⭐',
  ),
  FishSpecies(
    id: 'puffer',
    emoji: '🐡',
    name: '가시 복어',
    zone: OceanZone.sunlight,
    points: 15,
    baseSpeed: 60.0,
    funFact: '놀라면 물과 공기를 잔뜩 들이마셔 공처럼 빵빵해져요! 🐡',
  ),
  FishSpecies(
    id: 'goldfish',
    emoji: '✨',
    name: '황금빛 해파리',
    zone: OceanZone.sunlight,
    points: 100,
    baseSpeed: 120.0,
    isRare: true,
    funFact: '햇살 구역의 수호신! 몸 전체가 황금빛으로 눈부시게 빛나요! 🌟',
  ),

  // 2구역 (황혼 구역 🌊)
  FishSpecies(
    id: 'turtle',
    emoji: '🐢',
    name: '느긋한 바다거북',
    zone: OceanZone.twilight,
    points: 20,
    baseSpeed: 50.0,
    funFact: '넓고 깊은 바다를 여행하며 100년 넘게 장수하는 친구예요! 🐢',
  ),
  FishSpecies(
    id: 'squid',
    emoji: '🦑',
    name: '하늘하늘 오징어',
    zone: OceanZone.twilight,
    points: 20,
    baseSpeed: 110.0,
    funFact: '검은 먹물을 뿜어 적의 눈을 가리고 로켓처럼 슝 도망쳐요! 🦑',
  ),
  FishSpecies(
    id: 'crab',
    emoji: '🦀',
    name: '옆으로 꽃게',
    zone: OceanZone.twilight,
    points: 20,
    baseSpeed: 70.0,
    funFact: '양쪽 집게발로 싹둑싹둑! 옆으로 씩씩하게 걸어 다녀요! 🦀',
  ),
  FishSpecies(
    id: 'shrimp',
    emoji: '🦐',
    name: '아기 새우',
    zone: OceanZone.twilight,
    points: 25,
    baseSpeed: 130.0,
    funFact: '투명한 몸을 가지고 꼬리를 튕겨 1초 만에 튕겨 날아가요! 🦐',
  ),
  FishSpecies(
    id: 'whaleshark',
    emoji: '🦈',
    name: '멋진 고래상어',
    zone: OceanZone.twilight,
    points: 150,
    baseSpeed: 140.0,
    isRare: true,
    funFact: '세상에서 가장 큰 어류이지만 온순해서 작은 플랑크톤만 먹어요! 🦈',
  ),

  // 3구역 (심해 구역 🌌)
  FishSpecies(
    id: 'jelly',
    emoji: '🪼',
    name: '야광 해파리',
    zone: OceanZone.abyssal,
    points: 30,
    baseSpeed: 80.0,
    funFact: '깜깜한 깊은 바다에서 스스로 영롱한 형광빛을 비춰줘요! 🪼',
  ),
  FishSpecies(
    id: 'octopus',
    emoji: '🐙',
    name: '재주꾼 문어',
    zone: OceanZone.abyssal,
    points: 30,
    baseSpeed: 90.0,
    funFact: '심장이 3개나 있고 피부 색깔과 모양을 카멜레온처럼 변신해요! 🐙',
  ),
  FishSpecies(
    id: 'dolphin',
    emoji: '🐬',
    name: '분홍 돌고래',
    zone: OceanZone.abyssal,
    points: 50,
    baseSpeed: 160.0,
    funFact: '초음파로 친구들과 대화하며 물 위로 높이 뛰어올라 춤춰요! 🐬',
  ),
  FishSpecies(
    id: 'whale',
    emoji: '🐳',
    name: '아기 고래',
    zone: OceanZone.abyssal,
    points: 50,
    baseSpeed: 120.0,
    funFact: '숨을 쉴 때 머리 위의 숨구멍으로 시원한 물기둥을 뿜어요! 🐳',
  ),
  FishSpecies(
    id: 'giantwhale',
    emoji: '🐋',
    name: '거대한 대왕고래',
    zone: OceanZone.abyssal,
    points: 200,
    baseSpeed: 80.0,
    isRare: true,
    funFact: '지구 역사상 가장 큰 동물! 심장 크기만 작은 자동차만 하대요! 🐋',
  ),
];

// ── 쓰레기/장애물 종류 ──
const _trashList = [
  {'emoji': '🪨', 'name': '바위'},
  {'emoji': '👟', 'name': '낡은 장화'},
  {'emoji': '🥫', 'name': '빈 캔'},
];

// ── 생물 인스턴스 ──
class FishInstance {
  final String id;
  final FishSpecies? species; // null 이면 방해물/상어/쓰레기
  final String emoji;
  final String name;
  double x;
  double y;
  double speed;
  final bool isGood;
  bool isCaught;
  final double scale;

  // 부드러운 수영 및 생체 물리학 속성
  final double zDepth; // 0.65 (깊은 배경) ~ 1.35 (전경)
  double swimTimer;
  final double swimPhase;
  double lastBubbleTime;

  // 미끼 유인 효과
  double attractionTimer;

  // 생물 종류별 맞춤 파동 수영 매개변수
  final double waveAmp;
  final double waveFreq;
  final double swayFreq;

  FishInstance({
    required this.id,
    this.species,
    required this.emoji,
    required this.name,
    required this.x,
    required this.y,
    required this.speed,
    required this.isGood,
    this.isCaught = false,
    this.scale = 1.0,
    this.attractionTimer = 0.0,
    double? zDepth,
    double? swimPhase,
  }) : zDepth = zDepth ?? (0.65 + Random().nextDouble() * 0.7),
       swimPhase = swimPhase ?? (Random().nextDouble() * pi * 2),
       swimTimer = Random().nextDouble() * 10,
       lastBubbleTime = 0,
       waveAmp = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 18.0 : 10.0,
       waveFreq = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 1.1 : 2.2,
       swayFreq = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 1.8 : 4.0;

  // 파동에 따른 실시간 Y 위치
  double get renderY => y + (isCaught ? 0 : sin(swimPhase + swimTimer * waveFreq) * waveAmp);

  // 파동 궤적에 따른 자연스러운 기울기 (Tilt / Pitch Angle)
  double get tiltAngle {
    if (isCaught) return 0.0;
    final dy = cos(swimPhase + swimTimer * waveFreq) * waveAmp * waveFreq;
    final facingLeft = speed < 0;
    return atan2(dy, speed.abs() * 0.8) * (facingLeft ? 0.45 : -0.45);
  }

  // 꼬리 및 몸통의 부드러운 헤엄치기 (Sway Angle)
  double get swayAngle => isCaught ? sin(swimTimer * 10.0) * 0.3 : sin(swimPhase * 1.5 + swimTimer * swayFreq) * 0.10;

  Rect get rect => Rect.fromCenter(
    center: Offset(x, renderY),
    width: 60 * scale * zDepth,
    height: 45 * scale * zDepth,
  );
}

// ── 물보라 파티클 ──
class SplashParticle {
  double x, y, vx, vy, life;
  final Color color;
  SplashParticle({required this.x, required this.y, required this.vx, required this.vy, required this.color, this.life = 1.0});
}

// ── 미끼(식빵 조각) 파티클 ──
class BaitParticle {
  double x, y, vy, life;
  BaitParticle({required this.x, required this.y, this.vy = 60.0, this.life = 1.0});
}

// ── 점수/메시지 팝업 ──
class ScorePopup {
  double x, y, life;
  final String text;
  final Color color;
  ScorePopup({required this.x, required this.y, required this.text, required this.color, this.life = 1.0});
}

// ── 스테이지별 테마 및 색상 상수 ──
const List<String> _stageNames = ['☀️ 햇살 구역', '🌊 황혼 구역', '🌌 심해 구역'];
const List<Color> _stageColors = [Color(0xFF0288D1), Color(0xFF01579B), Color(0xFF0D47A1)];

const List<List<Color>> _stageSkyColors = [
  [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
  [Color(0xFFFF8A65), Color(0xFFD84315)],
  [Color(0xFF1A237E), Color(0xFF0D0D2B)],
];
const List<String> _stageWeather = ['☁️', '🌥️', '⭐'];
const List<String> _stageSunEmoji = ['☀️', '🌅', '🌙'];

const List<List<Color>> _stageOceanColors = [
  [Color(0xFF4FC3F7), Color(0xFF0288D1)],
  [Color(0xFF1565C0), Color(0xFF0D47A1)],
  [Color(0xFF0A1628), Color(0xFF000510)],
];
