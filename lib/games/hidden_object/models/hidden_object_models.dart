part of '../hidden_object_game.dart';

class _LevelTheme {
  final String name;
  final String icon;
  final List<String> scatterEmojis;
  final List<String> targetEmojis;
  final List<Color> bgGradient;

  const _LevelTheme({
    required this.name,
    required this.icon,
    required this.scatterEmojis,
    required this.targetEmojis,
    required this.bgGradient,
  });
}

class HiddenItem {
  final String emoji;
  final double x;
  final double y;
  final double size;
  final double angle;
  bool isFound;
  bool isTarget;

  HiddenItem({
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    this.isFound = false,
    this.isTarget = false,
  });
}

// ─────────────────────────────────────────────
// Theme Data
// ─────────────────────────────────────────────

const List<_LevelTheme> _themes = [
  _LevelTheme(
    name: '숲속 탐험',
    icon: '🌲',
    scatterEmojis: ['🌲', '🌳', '🍃', '🍂', '🌿', '🍄', '🌻', '🌷', '🪨', '☘️'],
    targetEmojis: ['🐿️', '🦊', '🐰', '🦉', '🐻', '🦋'],
    bgGradient: [Color(0xFF81C784), Color(0xFFA5D6A7)],
  ),
  _LevelTheme(
    name: '바닷속 모험',
    icon: '🌊',
    scatterEmojis: ['🌊', '🫧', '🪸', '🐚', '🪨', '🌿', '💎', '⭐', '🫧', '🌀'],
    targetEmojis: ['🐙', '🦀', '🐠', '🐳', '🦈', '🐬'],
    bgGradient: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
  ),
  _LevelTheme(
    name: '우주 탐사',
    icon: '🚀',
    scatterEmojis: ['⭐', '✨', '💫', '🌟', '☁️', '🌀', '💎', '🔮', '🪐', '🌙'],
    targetEmojis: ['👽', '🛸', '🚀', '👨‍🚀', '🤖', '🛰️'],
    bgGradient: [Color(0xFF1A237E), Color(0xFF311B92)],
  ),
  _LevelTheme(
    name: '공룡 섬',
    icon: '🦕',
    scatterEmojis: ['🌵', '🪨', '🌿', '🪵', '🌋', '🌴', '🔥', '🍃', '🪨', '🌱'],
    targetEmojis: ['🦕', '🦖', '🐊', '🥚', '🦴', '🦎'],
    bgGradient: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
  ),
  _LevelTheme(
    name: '과자 나라',
    icon: '🍭',
    scatterEmojis: ['🍬', '🍭', '🍫', '🍩', '🧁', '🍦', '🍨', '🍿', '🍧', '🍡'],
    targetEmojis: ['🎂', '🍪', '🧇', '🍓', '🍰', '🍒'],
    bgGradient: [Color(0xFFFF80AB), Color(0xFFC2185B)],
  ),
  _LevelTheme(
    name: '신나는 농장',
    icon: '🚜',
    scatterEmojis: ['🚜', '🌾', '🌽', '🥕', '🍎', '🌻', '🪵', '🎃', '🥦', '🍉'],
    targetEmojis: ['🐮', '🐷', '🐥', '🐴', '🐑', '🐶'],
    bgGradient: [Color(0xFFFFB74D), Color(0xFFF57C00)],
  ),
  _LevelTheme(
    name: '장난감 성',
    icon: '🏰',
    scatterEmojis: ['🏰', '⭐', '✨', '💎', '👑', '🪄', '🔮', '🔑', '🎁', '🎈'],
    targetEmojis: ['👸', '🤴', '🦄', '🐲', '⚔️', '🪞'],
    bgGradient: [Color(0xFF7986CB), Color(0xFF303F9F)],
  ),
  _LevelTheme(
    name: '놀이공원',
    icon: '🎠',
    scatterEmojis: ['🎈', '🎠', '🎡', '🎢', '🍿', '🎪', '🎆', '🍦', '🎫', '🎉'],
    targetEmojis: ['🤡', '🧸', '🎁', '👑', '🪄', '🎭'],
    bgGradient: [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
  ),
  _LevelTheme(
    name: '눈송이 마을',
    icon: '⛄',
    scatterEmojis: ['❄️', '🧊', '🎄', '🎁', '🧣', '🧤', '🎿', '⛸️', '🛷', '🌨️'],
    targetEmojis: ['⛄', '🐧', '🐻‍❄️', '🦌', '🦉', '🐺'],
    bgGradient: [Color(0xFF81D4FA), Color(0xFF0277BD)],
  ),
  _LevelTheme(
    name: '유령의 집',
    icon: '👻',
    scatterEmojis: ['🎃', '🕸️', '🕷️', '🍬', '🍫', '🕯️', '💀', '👽', '🧛', '🧟'],
    targetEmojis: ['👻', '🦇', '🐈‍⬛', '🦉', '👹', '🤖'],
    bgGradient: [Color(0xFF4527A0), Color(0xFF1B5E20)],
  ),
  _LevelTheme(
    name: '정글 사파리',
    icon: '🦁',
    scatterEmojis: ['🌴', '🌿', '🥥', '🍌', '🥭', '🍍', '🌺', '🐍', '🐸', '🐢'],
    targetEmojis: ['🦁', '🐒', '🐯', '🐘', '🦒', '🦓'],
    bgGradient: [Color(0xFFAED581), Color(0xFF33691E)],
  ),
  _LevelTheme(
    name: '마법의 숲',
    icon: '🧚',
    scatterEmojis: ['🍄', '🌸', '🌼', '🌷', '🌿', '💎', '🔮', '🪞', '👑', '💍'],
    targetEmojis: ['🧚', '🦄', '🦋', '🦢', '🦚', '🕊️'],
    bgGradient: [Color(0xFFF48FB1), Color(0xFF880E4F)],
  ),
];

