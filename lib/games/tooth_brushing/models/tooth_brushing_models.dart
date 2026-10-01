part of '../tooth_brushing_game.dart';

enum BrushStep {
  selectAnimal, // 동물 친구 고르기
  eating,       // 간식 먹고 이 더러워지기
  selectPaste,  // 맛있는 치약 고르기
  brushing,     // 쓱싹쓱싹 양치질
  rinsing,      // 가글가글 물로 헹구기
  complete,     // 반짝반짝 축하 & 보상
}

class _AnimalFriend {
  final String id;
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Color faceColor;
  final Color mouthColor;
  final String favoriteSnack;
  final String cheerMessage;
  final String soundPath;

  const _AnimalFriend({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.faceColor,
    required this.mouthColor,
    required this.favoriteSnack,
    required this.cheerMessage,
    required this.soundPath,
  });
}

const List<_AnimalFriend> _kAnimals = [
  _AnimalFriend(
    id: 'croco',
    name: '아기 악어 크롱이',
    emoji: '🐊',
    primaryColor: Color(0xFF66BB6A),
    secondaryColor: Color(0xFF388E3C),
    faceColor: Color(0xFFA5D6A7),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍫 달콤 초콜릿',
    cheerMessage: '우와! 내 이빨이 반짝반짝해! 크아앙~ 고마워! 🐊✨',
    soundPath: 'audio/animal_hippo.wav',
  ),
  _AnimalFriend(
    id: 'hippo',
    name: '하마 포포',
    emoji: '🦛',
    primaryColor: Color(0xFFAB47BC),
    secondaryColor: Color(0xFF7B1FA2),
    faceColor: Color(0xFFCE93D8),
    mouthColor: Color(0xFFFF80AB),
    favoriteSnack: '🍩 딸기 도넛',
    cheerMessage: '와아! 입안이 정말 상쾌해! 하마마~ 고마워! 🦛💖',
    soundPath: 'audio/animal_hippo.wav',
  ),
  _AnimalFriend(
    id: 'tiger',
    name: '아기 호랑이 어흥이',
    emoji: '🐯',
    primaryColor: Color(0xFFFFA726),
    secondaryColor: Color(0xFFF57C00),
    faceColor: Color(0xFFFFCC80),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍭 알록달록 사탕',
    cheerMessage: '어흥! 세균 몬스터를 다 무찔렀어! 최고야! 🐯🔥',
    soundPath: 'audio/animal_lion.wav',
  ),
  _AnimalFriend(
    id: 'bear',
    name: '곰돌이 몽이',
    emoji: '🐻',
    primaryColor: Color(0xFF8D6E63),
    secondaryColor: Color(0xFF5D4037),
    faceColor: Color(0xFFBCAAA4),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍪 달콤 쿠키',
    cheerMessage: '꿀맛 쿠키 먹고 양치까지 완벽해! 몽몽 고마워! 🐻🍯',
    soundPath: 'audio/animal_bear.wav',
  ),
  _AnimalFriend(
    id: 'lion',
    name: '아기 사자 레오',
    emoji: '🦁',
    primaryColor: Color(0xFFFFCA28),
    secondaryColor: Color(0xFFFFA000),
    faceColor: Color(0xFFFFE082),
    mouthColor: Color(0xFFFF8A80),
    favoriteSnack: '🍦 달콤 아이스크림',
    cheerMessage: '으르렁! 사자 왕의 이빨처럼 눈부셔! 🦁👑',
    soundPath: 'audio/animal_lion.wav',
  ),
  _AnimalFriend(
    id: 'rabbit',
    name: '토끼 토리',
    emoji: '🐰',
    primaryColor: Color(0xFFF06292),
    secondaryColor: Color(0xFFC2185B),
    faceColor: Color(0xFFF8BBD0),
    mouthColor: Color(0xFFFF80AB),
    favoriteSnack: '🧁 달콤 컵케이크',
    cheerMessage: '깡총깡총! 새하얀 앞니가 너무 마음에 들어! 🐰🌸',
    soundPath: 'audio/animal_rabbit.wav',
  ),
];

class _Toothpaste {
  final String name;
  final String flavor;
  final String emoji;
  final Color color;
  final Color foamColor;

  const _Toothpaste({
    required this.name,
    required this.flavor,
    required this.emoji,
    required this.color,
    required this.foamColor,
  });
}

const List<_Toothpaste> _kPastes = [
  _Toothpaste(
    name: '딸기 치약',
    flavor: '달콤한 딸기향 🍓',
    emoji: '🍓',
    color: Color(0xFFFF4081),
    foamColor: Color(0xFFFFCDD2),
  ),
  _Toothpaste(
    name: '바나나 치약',
    flavor: '부드러운 바나나향 🍌',
    emoji: '🍌',
    color: Color(0xFFFFD600),
    foamColor: Color(0xFFFFF9C4),
  ),
  _Toothpaste(
    name: '포도 치약',
    flavor: '향긋한 포도향 🍇',
    emoji: '🍇',
    color: Color(0xFFAB47BC),
    foamColor: Color(0xFFE1BEE7),
  ),
  _Toothpaste(
    name: '민트 치약',
    flavor: '시원 상쾌한 민트향 🌿',
    emoji: '🌿',
    color: Color(0xFF26A69A),
    foamColor: Color(0xFFB2DFDB),
  ),
];

class _Snack {
  final String name;
  final String emoji;
  final Color stainColor;

  const _Snack({required this.name, required this.emoji, required this.stainColor});
}

const List<_Snack> _kSnacks = [
  _Snack(name: '초콜릿', emoji: '🍫', stainColor: Color(0xFF5D4037)),
  _Snack(name: '막대사탕', emoji: '🍭', stainColor: Color(0xFFE91E63)),
  _Snack(name: '도넛', emoji: '🍩', stainColor: Color(0xFF8D6E63)),
  _Snack(name: '아이스크림', emoji: '🍦', stainColor: Color(0xFFFFB300)),
  _Snack(name: '쿠키', emoji: '🍪', stainColor: Color(0xFF795548)),
  _Snack(name: '콜라', emoji: '🥤', stainColor: Color(0xFF3E2723)),
];

class _ToothState {
  final int index;
  final bool isTop;
  final double xRatio; // 0.0 ~ 1.0 (relative to 280x280 canvas)
  final double yRatio; // 0.0 ~ 1.0
  final double width;
  final double height;
  double cleanliness; // 0.0 (dirty) ~ 1.0 (clean)
  Color stainColor;
  bool hasMonster;
  String monsterEmoji;

  _ToothState({
    required this.index,
    required this.isTop,
    required this.xRatio,
    required this.yRatio,
    required this.width,
    required this.height,
    this.cleanliness = 0.0,
    this.stainColor = const Color(0xFF5D4037),
    this.hasMonster = true,
    this.monsterEmoji = '👾',
  });
}

class _FoamParticle {
  Offset pos;
  double radius;
  Color color;
  double life; // 1.0 -> 0.0
  _FoamParticle({required this.pos, required this.radius, required this.color, required this.life});
}

class _WaterParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;
  _WaterParticle({required this.pos, required this.vel, required this.radius, required this.life, required this.color});
}

class _Sparkle {
  Offset pos;
  double size;
  double opacity;
  double rotation;
  Color color;
  _Sparkle({required this.pos, required this.size, required this.opacity, required this.rotation, required this.color});
}

// ═══════════════════════════════════════════════════════════════════════════════
// TOOTH BRUSHING GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

