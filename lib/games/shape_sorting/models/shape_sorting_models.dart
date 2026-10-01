part of '../shape_sorting_game.dart';

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

  const _ShapeInfo({
    required this.type,
    required this.label,
    required this.emoji,
    required this.color,
    required this.shadowColor,
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

