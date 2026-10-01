part of '../brick_breaker_game.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

class Ball {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  bool isFireball; // 불공: 벽돌을 관통

  Ball({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.radius = 14,
    this.isFireball = false,
  });

  Rect get rect => Rect.fromCircle(center: Offset(x, y), radius: radius);
}

class Paddle {
  double x;
  double y;
  double width;
  double height;

  Paddle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: width, height: height);
}

/// 벽돌 타입: HP 1~2 & 특수 연쇄 폭탄 벽돌
enum BrickType { normal, tough, bomb }

class Brick {
  double left;
  double top;
  double width;
  double height;
  int hp;         // 남은 체력 (최대 2방으로 시원함 유지)
  int maxHp;      // 최대 체력
  bool isDestroyed;
  Color color;
  String emoji;
  BrickType type;
  // 깨질 때 아이템 드롭 확률 (0~1), 0이면 드롭 없음
  double dropChance;
  // 깨질 때 떨어트릴 아이템 타입
  ItemType? dropItem;

  Brick({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.hp,
    required this.color,
    required this.emoji,
    required this.type,
    this.isDestroyed = false,
    this.dropChance = 0.0,
    this.dropItem,
  }) : maxHp = hp;

  Rect get rect => Rect.fromLTWH(left, top, width, height);
}

// ─────────────────────────────────────────────────────────────────────────────
// 아이템
// ─────────────────────────────────────────────────────────────────────────────

enum ItemType { multiBall, widePaddle, slowBall, fireball }

class DroppedItem {
  double x;
  double y;
  double vy;
  ItemType type;
  bool collected;
  bool missed;
  final double size = 36.0;

  DroppedItem({
    required this.x,
    required this.y,
    required this.type,
    this.vy = 160,
    this.collected = false,
    this.missed = false,
  });

  String get emoji => switch (type) {
    ItemType.multiBall  => '🎱',
    ItemType.widePaddle => '↔️',
    ItemType.slowBall   => '🐢',
    ItemType.fireball   => '🔥',
  };

  String get label => switch (type) {
    ItemType.multiBall  => '멀티볼!',
    ItemType.widePaddle => '패들확장!',
    ItemType.slowBall   => '슬로우!',
    ItemType.fireball   => '파이어볼!',
  };

  Color get color => switch (type) {
    ItemType.multiBall  => const Color(0xFF7C4DFF),
    ItemType.widePaddle => const Color(0xFF00BCD4),
    ItemType.slowBall   => const Color(0xFF4CAF50),
    ItemType.fireball   => const Color(0xFFFF5722),
  };

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: size, height: size);
}

// ─────────────────────────────────────────────────────────────────────────────
// 파티클
// ─────────────────────────────────────────────────────────────────────────────

class BrickParticle {
  double x, y;
  double vx, vy;
  double size;
  double opacity;
  Color color;

  BrickParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.opacity = 1.0,
  });

  void update(double dt) {
    x  += vx * dt;
    y  += vy * dt;
    vy += 400 * dt; // gravity
    opacity -= 2.2 * dt;
    if (opacity < 0) opacity = 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 팝업 텍스트
// ─────────────────────────────────────────────────────────────────────────────

class ScorePopup {
  double x, y;
  double vy;
  double opacity;
  String text;
  Color color;

  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
    this.vy = -80,
    this.opacity = 1.0,
  });

  void update(double dt) {
    y += vy * dt;
    opacity -= 1.8 * dt;
    if (opacity < 0) opacity = 0;
  }
}

