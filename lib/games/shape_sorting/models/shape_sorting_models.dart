part of '../shape_sorting_game.dart';

/// 도형 테마 카테고리
enum ShapeThemeCategory {
  all('🎲 전체 믹스', '모든 모양을 섞어서 놀아요!', Color(0xFFFF9800)),
  shapes('🔷 기본 모양', '동그라미, 세모, 네모 등 기본 도형', Color(0xFF29B6F6)),
  animals('🐻 동물 친구', '곰돌이, 토끼, 고양이, 물고기, 아기 새', Color(0xFFFF7043)),
  vehicles('🚗 탈것·건물', '자동차, 돛단배, 우리 집, 멋진 성', Color(0xFFAB47BC)),
  nature('🌸 자연·식물', '예쁜 꽃, 푸른 나무, 몽실 구름', Color(0xFF66BB6A));

  final String label;
  final String description;
  final Color accentColor;
  const ShapeThemeCategory(this.label, this.description, this.accentColor);
}

/// 도형 종류
enum ShapeType {
  // 기본 도형
  circle,
  square,
  triangle,
  star,
  heart,
  diamond,
  hexagon,
  pentagon,
  cross,
  moon,
  // 동물
  bear,
  rabbit,
  cat,
  fish,
  bird,
  // 자연 & 식물
  flower,
  tree,
  cloud,
  // 탈것
  car,
  boat,
  // 건물
  house,
  castle,
}

/// 도형 메타데이터 (4~5세 눈높이 의성어/의태어 수식어 포함)
class _ShapeInfo {
  final ShapeType type;
  final String label;
  final String funTitle;
  final String emoji;
  final Color color;
  final Color shadowColor;
  final Color lightColor;
  final ShapeThemeCategory category;

  const _ShapeInfo({
    required this.type,
    required this.label,
    required this.funTitle,
    required this.emoji,
    required this.color,
    required this.shadowColor,
    required this.lightColor,
    this.category = ShapeThemeCategory.shapes,
  });
}

/// 성공 시 팡 터지는 마법 파티클 (별, 하트, 반짝이 원)
class _SparkleParticle {
  double x, y, vx, vy, size, life, rotation, vRot;
  Color color;
  int kind; // 0: star, 1: heart, 2: sparkle circle

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
    this.rotation = 0.0,
    this.vRot = 0.08,
    this.kind = 0,
  });
}
