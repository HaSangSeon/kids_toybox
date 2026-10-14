part of '../shape_sorting_game.dart';

/// 도형 테마 카테고리
enum ShapeThemeCategory {
  all('🎲 전체 믹스', '모든 모양을 섞어서 놀아요!'),
  shapes('🔷 기본 모양', '동그라미, 세모, 네모 등 기본 도형'),
  animals('🐻 동물 친구', '곰, 토끼, 고양이, 물고기, 새'),
  vehicles('🚗 탈것과 건물', '자동차, 배, 집, 성'),
  nature('🌸 자연과 식물', '꽃, 나무, 구름');

  final String label;
  final String description;
  const ShapeThemeCategory(this.label, this.description);
}

/// 도형 종류
enum ShapeType {
  // 기본 도형
  circle, square, triangle, star, heart, diamond, hexagon, pentagon, cross, moon,
  // 동물
  bear, rabbit, cat, fish, bird,
  // 자연 & 식물
  flower, tree, cloud,
  // 탈것
  car, boat,
  // 건물
  house, castle,
}

/// 도형 메타데이터
class _ShapeInfo {
  final ShapeType type;
  final String label;
  final String emoji;
  final Color color;
  final Color shadowColor;
  final ShapeThemeCategory category;

  const _ShapeInfo({
    required this.type,
    required this.label,
    required this.emoji,
    required this.color,
    required this.shadowColor,
    this.category = ShapeThemeCategory.shapes,
  });
}

/// 성공 시 팡 터지는 파티클
class _SparkleParticle {
  double x, y, vx, vy, size, life;
  Color color;

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}
