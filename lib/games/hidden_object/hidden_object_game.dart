import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/theme/app_fonts.dart';

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

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
];

// ─────────────────────────────────────────────
// Main Game Widget
// ─────────────────────────────────────────────

class HiddenObjectGame extends StatefulWidget {
  const HiddenObjectGame({super.key});

  @override
  State<HiddenObjectGame> createState() => _HiddenObjectGameState();
}

class _HiddenObjectGameState extends State<HiddenObjectGame> with TickerProviderStateMixin {
  final Random _random = Random();
  late ConfettiController _confettiController;
  late AnimationController _ambientCtrl;

  int _currentLevel = 1; // 1, 2, 3
  List<HiddenItem> _items = [];
  List<String> _targets = [];
  int _foundCount = 0;
  bool _isLevelClear = false;


  // Hint
  bool _isHintActive = false;
  String? _hintEmoji;

  _LevelTheme get _currentTheme => _themes[_currentLevel - 1];

  int get _targetCount {
    if (_currentLevel == 1) return 3;
    if (_currentLevel == 2) return 4;
    return 5;
  }

  int get _scatterCount {
    if (_currentLevel == 1) return 30;
    if (_currentLevel == 2) return 40;
    return 50;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _startLevel(_currentLevel);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  void _startLevel(int level) {
    setState(() {
      _currentLevel = level;
      _isLevelClear = false;
      _foundCount = 0;
      _isHintActive = false;
      _hintEmoji = null;
      _items.clear();
      _targets.clear();

      final theme = _themes[level - 1];

      // Theme-specific ambient entrance sound
      if (level == 1) {
        AudioManager.instance.playChime(); // 숲속 청아한 새소리/샤라랑
      } else if (level == 2) {
        AudioManager.instance.playSplash(); // 바닷속 보글보글 수중음
      } else {
        AudioManager.instance.playMagicUnfoldSuccess(); // 우주 신비로운 몽환음
      }

      // Pick targets
      final targetPool = List<String>.from(theme.targetEmojis)..shuffle(_random);
      _targets = targetPool.take(_targetCount).toList();

      // 1. Place target items first with distinct positions
      final List<HiddenItem> targetItems = [];
      for (String target in _targets) {
        double px = 0, py = 0;
        bool valid = false;
        int attempts = 0;
        while (!valid && attempts < 50) {
          attempts++;
          px = 0.12 + _random.nextDouble() * 0.76;
          py = 0.10 + _random.nextDouble() * 0.75;
          valid = !targetItems.any((t) => (t.x - px).abs() < 0.15 && (t.y - py).abs() < 0.15);
        }
        targetItems.add(HiddenItem(
          emoji: target,
          x: px,
          y: py,
          size: 42.0 + _random.nextDouble() * 16.0,
          angle: (_random.nextDouble() - 0.5) * 0.6,
          isTarget: true,
        ));
      }

      // 2. Generate scatter items with distance check from targets
      final List<HiddenItem> scatterItems = [];
      for (int i = 0; i < _scatterCount; i++) {
        final emoji = theme.scatterEmojis[_random.nextInt(theme.scatterEmojis.length)];
        double sx = 0, sy = 0;
        bool valid = false;
        int attempts = 0;
        while (!valid && attempts < 30) {
          attempts++;
          sx = 0.05 + _random.nextDouble() * 0.90;
          sy = 0.05 + _random.nextDouble() * 0.85;
          // Avoid target items overlap
          valid = !targetItems.any((t) => (t.x - sx).abs() < 0.10 && (t.y - sy).abs() < 0.10);
        }
        scatterItems.add(HiddenItem(
          emoji: emoji,
          x: sx,
          y: sy,
          size: 30.0 + _random.nextDouble() * 20.0,
          angle: (_random.nextDouble() - 0.5) * 1.2,
        ));
      }

      // Scatter items rendered first, Target items ALWAYS rendered ON TOP!
      _items = [...scatterItems, ...targetItems];
    });
  }

  void _onItemTap(HiddenItem item) {
    if (item.isFound || _isLevelClear) return;

    if (item.isTarget) {
      AudioManager.instance.playChime();
      HapticFeedback.mediumImpact();
      setState(() {
        item.isFound = true;
        _foundCount = _targets.where((t) => _items.any((i) => i.emoji == t && i.isFound)).length;
      });
      _checkWinCondition();
    } else {
      AudioManager.instance.playClick();
      HapticFeedback.lightImpact();
    }
  }

  void _checkWinCondition() {
    if (_foundCount >= _targets.length && !_isLevelClear) {
      setState(() {
        _isLevelClear = true;
      });

      // 터지는 소리 대신 아기자기 부드러운 축하 사운드 재생
      AudioManager.instance.playMagicUnfoldSuccess();

      // 중간 레벨(레벨 1, 2)은 팝업창 없이 1.2초 후 다음 레벨로 자연스럽게 전환!
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;

        if (_currentLevel < 3) {
          _startLevel(_currentLevel + 1);
        } else {
          _showVictoryDialog();
        }
      });
    }
  }



  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: KidsTheme.toyDecoration(color: Colors.white, borderRadius: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟 🌟 🌟', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text('모든 레벨 클리어!',
                style: AppFonts.jua(fontSize: 28, color: KidsTheme.orange, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KidsTheme.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                  _startLevel(1);
                },
                child: Text('다시 하기 🔄',
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;
    final bool isDark = _currentLevel == 3;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌲🌊🚀 주제별 맞춤 테마 아기자기 배경 렌더러
          _ThemeBackgroundWidget(
            level: _currentLevel,
            ambientVal: _ambientCtrl.value,
          ),
          
          // ── Play Area ────────────────────────────────────────────────
          Positioned.fill(
              top: 85,
              bottom: 120,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _ambientCtrl,
                    builder: (context, _) {
                      return Stack(
                        children: _items.map((item) {
                          final isHinted = _isHintActive && item.isTarget &&
                              item.emoji == _hintEmoji && !item.isFound;
                          final double dy = item.isTarget ? 0 :
                              sin((_ambientCtrl.value * pi * 2) + (item.x * 10)) * 2.0;
                          return Positioned(
                            left: item.x * constraints.maxWidth - (item.size / 2),
                            top:  item.y * constraints.maxHeight - (item.size / 2) + dy,
                            child: _HiddenItemWidget(
                              item: item,
                              isHinted: isHinted,
                              onTap: () => _onItemTap(item),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Row 1: 뒤로가기 | 테마이름+레벨 | 힌트+타이머 ──
                      Row(
                        children: [
                          // 뒤로가기
                          GestureDetector(
                            onTap: () {
                              AudioManager.instance.playClick();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.5),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                )],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 테마 이름 + 레벨 뱃지
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.12)
                                    : Colors.white.withOpacity(0.82),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(isDark ? 0.2 : 0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                )],
                              ),
                              child: Row(
                                children: [
                                  Text(theme.icon,
                                    style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(theme.name,
                                      style: GoogleFonts.jua(
                                        fontSize: 17,
                                        color: isDark ? Colors.white : const Color(0xFF37474F),
                                        height: 1.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 레벨 뱃지
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(
                                        color: const Color(0xFFFFB300).withOpacity(0.5),
                                        blurRadius: 6,
                                      )],
                                    ),
                                    child: Text(
                                      'Lv $_currentLevel',
                                      style: GoogleFonts.jua(
                                        fontSize: 14, color: Colors.white, height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Target Bar ─────────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildTargetBar(isDark),
              ),
            ),



            // ── Confetti ──────────────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTargetBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFB74D), width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "찾아야 할 것들" 캡슐 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7043), Color(0xFFFFB74D)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔍', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(
                  '찾아야 할 친구들  ($_foundCount / ${_targets.length})',
                  style: GoogleFonts.jua(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 아이템 카드들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _targets.map((target) {
              final isFound = _items.any((i) => i.emoji == target && i.isFound);
              return _buildTargetCard(target, isFound, isDark);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(String emoji, bool isFound, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      width: isFound ? 66 : 64,
      height: isFound ? 66 : 64,
      decoration: BoxDecoration(
        gradient: isFound
            ? const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF26A69A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isFound ? Colors.white : const Color(0xFFFFD54F),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: isFound
                ? const Color(0xFF66BB6A).withValues(alpha: 0.4)
                : Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: isFound ? 0.4 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: _AnimatedCreatureWidget(
              emoji: emoji,
              size: isFound ? 28 : 34,
              timeMs: DateTime.now().millisecondsSinceEpoch / 1000.0,
              isFound: false,
            ),
          ),
          if (isFound)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D32), size: 24),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Theme Specific Custom Background Painters
// ─────────────────────────────────────────────

class _ThemeBackgroundWidget extends StatelessWidget {
  final int level;
  final double ambientVal;

  const _ThemeBackgroundWidget({
    required this.level,
    required this.ambientVal,
  });

  @override
  Widget build(BuildContext context) {
    if (level == 1) {
      return CustomPaint(
        painter: _ForestBackgroundPainter(ambientVal: ambientVal),
      );
    } else if (level == 2) {
      return CustomPaint(
        painter: _OceanBackgroundPainter(ambientVal: ambientVal),
      );
    } else {
      return CustomPaint(
        painter: _SpaceBackgroundPainter(ambientVal: ambientVal),
      );
    }
  }
}

// 🌲 Level 1: 숲속 탐험 배경 렌더러 (동화 속 초록 동산과 나무들)
class _ForestBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _ForestBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    // Sky Gradient
    final Rect rect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // Sun & Rays
    final Paint sunPaint = Paint()..color = const Color(0xFFFFF176).withValues(alpha: 0.6);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 60, sunPaint);

    // Hills
    final Paint hillPaint1 = Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.8);
    final Path hill1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.32, size.width * 0.6, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.48, size.width, size.height * 0.38)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill1, hillPaint1);

    final Paint hillPaint2 = Paint()..color = const Color(0xFF66BB6A);
    final Path hill2 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.48, size.width * 0.75, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.62, size.width, size.height * 0.54)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill2, hillPaint2);

    // Trees
    _drawTree(canvas, Offset(size.width * 0.12, size.height * 0.42), 40);
    _drawTree(canvas, Offset(size.width * 0.82, size.height * 0.45), 46);
    _drawTree(canvas, Offset(size.width * 0.92, size.height * 0.48), 36);
  }

  void _drawTree(Canvas canvas, Offset pos, double r) {
    final Paint trunk = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(Rect.fromLTWH(pos.dx - r * 0.2, pos.dy, r * 0.4, r * 1.2), trunk);
    final Paint leaves = Paint()..color = const Color(0xFF388E3C);
    canvas.drawCircle(Offset(pos.dx, pos.dy - r * 0.3), r, leaves);
    canvas.drawCircle(Offset(pos.dx - r * 0.4, pos.dy + r * 0.1), r * 0.7, leaves);
    canvas.drawCircle(Offset(pos.dx + r * 0.4, pos.dy + r * 0.1), r * 0.7, leaves);
  }

  @override
  bool shouldRepaint(covariant _ForestBackgroundPainter oldDelegate) => true;
}

// 🌊 Level 2: 바닷속 모험 배경 렌더러 (에메랄드 해저와 빛 내림)
class _OceanBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _OceanBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF80DEEA), Color(0xFF26C6DA), Color(0xFF0097A7), Color(0xFF006064)],
      ).createShader(rect);
    canvas.drawRect(rect, oceanPaint);

    // Sunlight Rays
    final Paint rayPaint = Paint()..color = Colors.white.withValues(alpha: 0.12);
    final Path ray = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.65, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..close();
    canvas.drawPath(ray, rayPaint);

    // Sea floor
    final Paint floorPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.85);
    final Path floor = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.8, size.width, size.height * 0.88)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(floor, floorPaint);
  }

  @override
  bool shouldRepaint(covariant _OceanBackgroundPainter oldDelegate) => true;
}

// 🚀 Level 3: 우주 탐사 배경 렌더러 (오로라 성운 & 은하수)
class _SpaceBackgroundPainter extends CustomPainter {
  final double ambientVal;
  _SpaceBackgroundPainter({required this.ambientVal});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint spacePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C), Color(0xFF0D47A1)],
      ).createShader(rect);
    canvas.drawRect(rect, spacePaint);

    // Nebula Glow
    final Paint nebula = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.3), 120, nebula);
  }

  @override
  bool shouldRepaint(covariant _SpaceBackgroundPainter oldDelegate) => true;
}

// ─────────────────────────────────────────────
// Hidden Item Widget with Wiggle & Hint Glow
// ─────────────────────────────────────────────

class _HiddenItemWidget extends StatefulWidget {
  final HiddenItem item;
  final bool isHinted;
  final VoidCallback onTap;

  const _HiddenItemWidget({required this.item, required this.isHinted, required this.onTap});

  @override
  State<_HiddenItemWidget> createState() => _HiddenItemWidgetState();
}

class _HiddenItemWidgetState extends State<_HiddenItemWidget> with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late AnimationController _animCtrl;

  // Creature movement types
  bool get _isButterfly => ['🦋', '🐝', '🕊️', '🦉', '🐞'].contains(widget.item.emoji);
  bool get _isFish => ['🐠', '🐳', '🐬', '🐙', '🦀', '🦈', '🐡'].contains(widget.item.emoji);
  bool get _isAnimal => ['🦊', '🐰', '🐿️', '🐻', '🐹'].contains(widget.item.emoji);
  bool get _isSpaceObj => ['👽', '🛸', '🚀', '👨‍🚀', '🤖', '🛰️'].contains(widget.item.emoji);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // Continuous creature animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isButterfly ? 1200 : _isFish ? 2500 : _isAnimal ? 1600 : 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    if (!widget.item.isTarget && !widget.item.isFound) {
      _shakeCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double timeMs = DateTime.now().millisecondsSinceEpoch / 1000.0;

    return AnimatedScale(
      scale: widget.item.isFound ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInBack,
      child: AnimatedOpacity(
        opacity: widget.item.isFound ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shakeAnim, _animCtrl]),
            builder: (context, child) {
              final double t = _animCtrl.value;

              // Creature-specific realistic dynamic physics
              double offsetX = 0.0;
              double offsetY = 0.0;
              double scaleX = 1.0;
              double scaleY = 1.0;
              double skewX = 0.0;
              double rotation = widget.item.angle + _shakeAnim.value;
              Matrix4 transformMatrix = Matrix4.identity();

              if (_isButterfly) {
                // 🦋 나비/벌/새: 3D 날개 입체 펄럭임 (3D Perspective Flapping & S-Curve Flight)
                offsetX = sin(timeMs * 2.5) * 16.0;
                offsetY = cos(timeMs * 3.0) * 10.0;
                rotation += sin(timeMs * 2.5) * 0.12;

                // 3D Perspective Rotation for Wing Flap
                final double wingAngle = sin(timeMs * 18.0) * 0.75;
                transformMatrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.003) // Perspective distortion
                  ..rotateY(wingAngle);
              } else if (_isFish) {
                // 🐠 물고기/돌고래: 꼬리 살랑살랑 파동 유영 (Sinusoidal Tail Wiggle & Dynamic Swim)
                final double swimDirection = sin(timeMs * 1.2) > 0 ? 1.0 : -1.0;
                offsetX = (t - 0.5) * 36.0;
                offsetY = sin(timeMs * 2.5) * 6.0;
                scaleX = swimDirection;

                // Tail & Fin Wiggle Wave Distortion
                skewX = sin(timeMs * 10.0) * 0.18;
                rotation += sin(timeMs * 8.0) * 0.08;
              } else if (_isAnimal) {
                // 🦊 짐승/동물: 실감 나는 걸음걸이 (Walking Gait Cycle)
                final double walkCycle = sin(timeMs * 9.0);
                final double walkStep = (walkCycle).abs();

                offsetX = (t - 0.5) * 32.0;
                scaleY = 1.0 - (walkStep * 0.12);
                scaleX = 1.0 + (walkStep * 0.08);

                offsetY = -walkStep * 8.0;
                rotation += walkCycle * 0.14;
                skewX = walkCycle * 0.08;
              } else if (_isSpaceObj) {
                // 👽 외계인/우주선: 무중력 두둥실 플로팅
                offsetX = cos(timeMs * 1.5) * 15.0;
                offsetY = sin(timeMs * 1.5) * 15.0;
                rotation += sin(timeMs * 1.0) * 0.25;
              } else if (['🍃', '🍂', '🌿', '🌻', '🌷', '☘️', '🍄'].contains(widget.item.emoji)) {
                // 🍃 잎사귀/꽃/바람: 바람에 나풀나풀 흩날리며 춤추는 살랑살랑 모션
                final double phase = (widget.item.x * 20);
                offsetX = sin(timeMs * 2.0 + phase) * 12.0;
                offsetY = cos(timeMs * 1.8 + phase) * 6.0;
                rotation += sin(timeMs * 3.0 + phase) * 0.25;
              } else if (['🫧', '🌊', '🪸', '🐚', '💎'].contains(widget.item.emoji)) {
                // 🫧 거품/바닷속 보석: 수중에서 퐁퐁 솟아오르고 두둥실 피어나는 모션
                final double phase = (widget.item.y * 15);
                offsetY = sin(timeMs * 3.5 + phase) * 10.0;
                scaleX = 0.9 + 0.2 * sin(timeMs * 4.0 + phase);
                scaleY = 0.9 + 0.2 * cos(timeMs * 4.0 + phase);
              } else if (['⭐', '✨', '💫', '🌟', '🪐', '🌙', '🔮'].contains(widget.item.emoji)) {
                // ⭐ 별/반짝이: 우주 속에서 핑글핑글 반짝이며 두둥실 부유하는 트윈클 모션
                final double phase = (widget.item.x * 30);
                offsetX = sin(timeMs * 1.5 + phase) * 10.0;
                offsetY = cos(timeMs * 1.5 + phase) * 10.0;
                rotation += (timeMs * 0.8 + phase) % (pi * 2);
                scaleX = 0.85 + 0.3 * sin(timeMs * 5.0 + phase);
                scaleY = 0.85 + 0.3 * sin(timeMs * 5.0 + phase);
              }

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transformMatrix,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.skew(skewX, 0.0),
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.transparent,
                          decoration: widget.isHinted
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellowAccent.withValues(alpha: 0.8),
                                      blurRadius: 20,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                )
                              : null,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: _AnimatedCreatureWidget(
              emoji: widget.item.emoji,
              size: widget.item.size,
              timeMs: timeMs,
              isFound: widget.item.isFound,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Multi-Part Animated Creature Renderer
// ─────────────────────────────────────────────

class _AnimatedCreatureWidget extends StatelessWidget {
  final String emoji;
  final double size;
  final double timeMs;
  final bool isFound;

  const _AnimatedCreatureWidget({
    required this.emoji,
    required this.size,
    required this.timeMs,
    required this.isFound,
  });

  @override
  Widget build(BuildContext context) {
    if (emoji == '🦉' || emoji == '🕊️' || emoji == '🦅') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _OwlPainter(timeMs: timeMs),
      );
    } else if (emoji == '🐰') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _RabbitPainter(timeMs: timeMs),
      );
    } else if (emoji == '🦊') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _FoxPainter(timeMs: timeMs),
      );
    } else if (['🐠', '🐬', '🐳', '🦈'].contains(emoji)) {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _FishPainter(timeMs: timeMs, emoji: emoji),
      );
    }

    // Fallback cute emoji
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}

// ── 🦉 Owl Painter (Flapping Wings + Big Eyes + Body) ───────────────────────
class _OwlPainter extends CustomPainter {
  final double timeMs;
  _OwlPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.32;

    // Body Paint
    final Paint bodyPaint = Paint()..color = const Color(0xFF8D6E63);
    final Paint bellyPaint = Paint()..color = const Color(0xFFFFF8E1);
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black87;
    final Paint beakPaint = Paint()..color = const Color(0xFFFFB300);
    final Paint wingPaint = Paint()..color = const Color(0xFF6D4C41);

    // 1. Wings (Flapping Wings)
    final double flap = sin(timeMs * 16.0) * 0.45; // Wing flap angle

    // Left Wing
    canvas.save();
    canvas.translate(cx - r * 0.7, cy - r * 0.2);
    canvas.rotate(-0.3 - flap);
    final Path leftWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(-r * 1.1, -r * 0.4, -r * 1.2, r * 0.8, 0, r * 0.6)
      ..close();
    canvas.drawPath(leftWing, wingPaint);
    canvas.restore();

    // Right Wing
    canvas.save();
    canvas.translate(cx + r * 0.7, cy - r * 0.2);
    canvas.rotate(0.3 + flap);
    final Path rightWing = Path()
      ..moveTo(0, 0)
      ..cubicTo(r * 1.1, -r * 0.4, r * 1.2, r * 0.8, 0, r * 0.6)
      ..close();
    canvas.drawPath(rightWing, wingPaint);
    canvas.restore();

    // 2. Main Body
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);
    canvas.drawCircle(Offset(cx, cy + r * 0.2), r * 0.65, bellyPaint);

    // 3. Feet
    final Paint feetPaint = Paint()..color = const Color(0xFFFF8F00)..strokeWidth = 3;
    canvas.drawLine(Offset(cx - r * 0.3, cy + r), Offset(cx - r * 0.3, cy + r * 1.25), feetPaint);
    canvas.drawLine(Offset(cx + r * 0.3, cy + r), Offset(cx + r * 0.3, cy + r * 1.25), feetPaint);

    // 4. Big Eyes
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.25), r * 0.38, eyeWhite);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.25), r * 0.38, eyeWhite);
    canvas.drawCircle(Offset(cx - r * 0.32, cy - r * 0.25), r * 0.18, eyePupil);
    canvas.drawCircle(Offset(cx + r * 0.38, cy - r * 0.25), r * 0.18, eyePupil);

    // Eye shines
    canvas.drawCircle(Offset(cx - r * 0.38, cy - r * 0.32), r * 0.06, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(cx + r * 0.32, cy - r * 0.32), r * 0.06, Paint()..color = Colors.white);

    // 5. Beak
    final Path beak = Path()
      ..moveTo(cx - r * 0.15, cy - r * 0.05)
      ..lineTo(cx + r * 0.15, cy - r * 0.05)
      ..lineTo(cx, cy + r * 0.22)
      ..close();
    canvas.drawPath(beak, beakPaint);
  }

  @override
  bool shouldRepaint(covariant _OwlPainter oldDelegate) => true;
}

// ── 🐰 Rabbit Painter (Full Body + 4 Hopping Legs + Long Ears + Tail) ───────
class _RabbitPainter extends CustomPainter {
  final double timeMs;
  _RabbitPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.25;

    final Paint bodyPaint = Paint()..color = const Color(0xFFFAFAFA);
    final Paint earInner = Paint()..color = const Color(0xFFFF80AB);
    final Paint eyePaint = Paint()..color = const Color(0xFF37474F);
    final Paint pinkNose = Paint()..color = const Color(0xFFFF4081);

    final double hop = (sin(timeMs * 10.0)).abs() * r * 0.25;
    final double legAngle = sin(timeMs * 10.0) * 0.4;

    // 1. Long Ears (Ear Wiggle)
    final double earWiggle = sin(timeMs * 8.0) * 0.15;
    
    // Left Ear
    canvas.save();
    canvas.translate(cx - r * 0.35, cy - r * 0.6);
    canvas.rotate(-0.15 + earWiggle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, -r * 1.5, r * 0.4, r * 1.6), Radius.circular(r * 0.2)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.1, -r * 1.3, r * 0.2, r * 1.2), Radius.circular(r * 0.1)), earInner);
    canvas.restore();

    // Right Ear
    canvas.save();
    canvas.translate(cx + r * 0.35, cy - r * 0.6);
    canvas.rotate(0.15 - earWiggle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, -r * 1.5, r * 0.4, r * 1.6), Radius.circular(r * 0.2)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.1, -r * 1.3, r * 0.2, r * 1.2), Radius.circular(r * 0.1)), earInner);
    canvas.restore();

    // 2. Fluffy Tail
    canvas.drawCircle(Offset(cx + r * 0.9, cy + r * 0.4), r * 0.3, bodyPaint);

    // 3. 4 Hopping Legs (Animated Legs)
    final Paint legPaint = Paint()..color = const Color(0xFFF5F5F5);
    
    // Front Legs
    canvas.save();
    canvas.translate(cx - r * 0.4, cy + r * 0.6);
    canvas.rotate(legAngle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.15, 0, r * 0.3, r * 0.7), Radius.circular(r * 0.15)), legPaint);
    canvas.restore();

    // Back Legs
    canvas.save();
    canvas.translate(cx + r * 0.4, cy + r * 0.6);
    canvas.rotate(-legAngle);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-r * 0.2, 0, r * 0.4, r * 0.7), Radius.circular(r * 0.2)), legPaint);
    canvas.restore();

    // 4. Body & Head
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.3 - hop), width: r * 1.5, height: r * 1.3), bodyPaint);
    canvas.drawCircle(Offset(cx, cy - r * 0.2 - hop), r * 0.85, bodyPaint);

    // 5. Cute Eyes & Nose
    canvas.drawCircle(Offset(cx - r * 0.3, cy - r * 0.3 - hop), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx + r * 0.3, cy - r * 0.3 - hop), r * 0.12, eyePaint);
    canvas.drawCircle(Offset(cx, cy - r * 0.15 - hop), r * 0.09, pinkNose);
  }

  @override
  bool shouldRepaint(covariant _RabbitPainter oldDelegate) => true;
}

// ── 🦊 Fox Painter (Full Body + 4 Walking Legs + Fluffy Tail) ───────────────
class _FoxPainter extends CustomPainter {
  final double timeMs;
  _FoxPainter({required this.timeMs});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.25;

    final Paint foxOrange = Paint()..color = const Color(0xFFFF6D00);
    final Paint foxWhite = Paint()..color = Colors.white;
    final Paint foxBlack = Paint()..color = const Color(0xFF263238);

    final double legAngle = sin(timeMs * 12.0) * 0.35;
    final double tailWiggle = sin(timeMs * 6.0) * 0.3;

    // 1. Fluffy Tail
    canvas.save();
    canvas.translate(cx + r * 0.8, cy + r * 0.2);
    canvas.rotate(0.3 + tailWiggle);
    final Path tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(r * 1.2, -r * 0.5, r * 1.4, r * 0.6)
      ..quadraticBezierTo(r * 0.6, r * 1.1, 0, 0)
      ..close();
    canvas.drawPath(tailPath, foxOrange);
    canvas.drawCircle(Offset(r * 1.2, r * 0.2), r * 0.35, foxWhite);
    canvas.restore();

    // 2. 4 Walking Legs
    canvas.save();
    canvas.translate(cx - r * 0.4, cy + r * 0.5);
    canvas.rotate(legAngle);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, 0, r * 0.2, r * 0.8), foxOrange);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, r * 0.5, r * 0.2, r * 0.3), foxBlack);
    canvas.restore();

    canvas.save();
    canvas.translate(cx + r * 0.4, cy + r * 0.5);
    canvas.rotate(-legAngle);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, 0, r * 0.2, r * 0.8), foxOrange);
    canvas.drawRect(Rect.fromLTWH(-r * 0.1, r * 0.5, r * 0.2, r * 0.3), foxBlack);
    canvas.restore();

    // 3. Body & Head
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.2), width: r * 1.6, height: r * 1.1), foxOrange);

    // Fox Triangular Face
    final Path face = Path()
      ..moveTo(cx - r * 0.8, cy - r * 0.5)
      ..lineTo(cx + r * 0.8, cy - r * 0.5)
      ..lineTo(cx, cy + r * 0.4)
      ..close();
    canvas.drawPath(face, foxOrange);

    // White Cheeks
    final Path cheeks = Path()
      ..moveTo(cx - r * 0.7, cy - r * 0.2)
      ..lineTo(cx + r * 0.7, cy - r * 0.2)
      ..lineTo(cx, cy + r * 0.4)
      ..close();
    canvas.drawPath(cheeks, foxWhite);

    // Ears
    canvas.drawCircle(Offset(cx - r * 0.6, cy - r * 0.7), r * 0.3, foxBlack);
    canvas.drawCircle(Offset(cx + r * 0.6, cy - r * 0.7), r * 0.3, foxBlack);

    // Nose & Eyes
    canvas.drawCircle(Offset(cx, cy + r * 0.35), r * 0.12, foxBlack);
    canvas.drawCircle(Offset(cx - r * 0.35, cy - r * 0.2), r * 0.1, foxBlack);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.2), r * 0.1, foxBlack);
  }

  @override
  bool shouldRepaint(covariant _FoxPainter oldDelegate) => true;
}

// ── 🐠 Fish Painter (Wiggling Tail Fin + Body + Eye) ────────────────────────
class _FishPainter extends CustomPainter {
  final double timeMs;
  final String emoji;
  _FishPainter({required this.timeMs, required this.emoji});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width * 0.3;

    final Color fishColor = emoji == '🐬'
        ? const Color(0xFF29B6F6)
        : emoji == '🐳'
            ? const Color(0xFF0288D1)
            : const Color(0xFFFF7043);

    final Paint bodyPaint = Paint()..color = fishColor;
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black87;

    final double tailWiggle = sin(timeMs * 14.0) * 0.35; // Wiggling tail angle

    // 1. Wiggling Tail Fin
    canvas.save();
    canvas.translate(cx + r * 0.8, cy);
    canvas.rotate(tailWiggle);
    final Path tail = Path()
      ..moveTo(0, 0)
      ..lineTo(r * 0.8, -r * 0.6)
      ..quadraticBezierTo(r * 0.5, 0, r * 0.8, r * 0.6)
      ..close();
    canvas.drawPath(tail, bodyPaint);
    canvas.restore();

    // 2. Fish Body
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 1.3), bodyPaint);

    // 3. Eye
    canvas.drawCircle(Offset(cx - r * 0.4, cy - r * 0.2), r * 0.22, eyeWhite);
    canvas.drawCircle(Offset(cx - r * 0.45, cy - r * 0.2), r * 0.11, eyePupil);
  }

  @override
  bool shouldRepaint(covariant _FishPainter oldDelegate) => true;
}




