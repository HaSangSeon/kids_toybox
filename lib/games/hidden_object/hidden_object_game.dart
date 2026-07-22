import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

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

  // Timer & Stars
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  int? _earnedStars;

  // Hint
  bool _isHintActive = false;
  String? _hintEmoji;

  // Level-up overlay
  bool _showLevelUp = false;
  int _nextLevelForOverlay = 0;

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
    _gameTimer?.cancel();
    super.dispose();
  }

  int _getStarCount() {
    int fast = 20, medium = 40;
    if (_currentLevel == 2) { fast = 30; medium = 60; }
    if (_currentLevel == 3) { fast = 40; medium = 80; }
    if (_elapsedSeconds <= fast) return 3;
    if (_elapsedSeconds <= medium) return 2;
    return 1;
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _elapsedSeconds = 0;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _elapsedSeconds++);
    });
  }

  void _startLevel(int level) {
    _gameTimer?.cancel();

    setState(() {
      _currentLevel = level;
      _isLevelClear = false;
      _foundCount = 0;
      _earnedStars = null;
      _isHintActive = false;
      _hintEmoji = null;
      _items.clear();
      _targets.clear();

      final theme = _themes[level - 1];

      // Pick targets
      final targetPool = List<String>.from(theme.targetEmojis)..shuffle(_random);
      _targets = targetPool.take(_targetCount).toList();

      // Generate scatter items
      for (int i = 0; i < _scatterCount; i++) {
        final emoji = theme.scatterEmojis[_random.nextInt(theme.scatterEmojis.length)];
        _items.add(HiddenItem(
          emoji: emoji,
          x: 0.05 + _random.nextDouble() * 0.9,
          y: 0.05 + _random.nextDouble() * 0.85,
          size: 32.0 + _random.nextDouble() * 24.0,
          angle: (_random.nextDouble() - 0.5) * 1.2,
        ));
      }

      // Place target items among scatter
      for (String target in _targets) {
        _items.add(HiddenItem(
          emoji: target,
          x: 0.08 + _random.nextDouble() * 0.84,
          y: 0.08 + _random.nextDouble() * 0.8,
          size: 36.0 + _random.nextDouble() * 20.0,
          angle: (_random.nextDouble() - 0.5) * 1.0,
          isTarget: true,
        ));
      }

      _items.shuffle(_random);
    });

    _startTimer();
  }

  void _onItemTap(HiddenItem item) {
    if (item.isFound || _isLevelClear) return;

    if (item.isTarget) {
      AudioManager.instance.playSuccess();
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
      _gameTimer?.cancel();
      final stars = _getStarCount();

      setState(() {
        _isLevelClear = true;
        _earnedStars = stars;
      });

      if (stars == 3) _confettiController.play();
      AudioManager.instance.playPop();

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() => _earnedStars = null);

        if (_currentLevel < 3) {
          _showLevelUpOverlay(_currentLevel + 1);
        } else {
          _confettiController.play();
          _showVictoryDialog();
        }
      });
    }
  }

  void _useHint() {
    if (_isLevelClear || _isHintActive) return;

    final unfound = _targets.where((t) => !_items.any((i) => i.emoji == t && i.isFound)).toList();
    if (unfound.isEmpty) return;

    AudioManager.instance.playColorSelect();
    setState(() {
      _isHintActive = true;
      _hintEmoji = unfound.first;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() { _isHintActive = false; _hintEmoji = null; });
    });
  }

  void _showLevelUpOverlay(int nextLevel) {
    setState(() { _showLevelUp = true; _nextLevelForOverlay = nextLevel; });
    AudioManager.instance.playPop();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _showLevelUp = false);
      _startLevel(nextLevel);
    });
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
                style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.orange, fontWeight: FontWeight.bold)),
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
    final int medium = (_currentLevel == 1) ? 40 : (_currentLevel == 2) ? 60 : 80;
    final int fast   = (_currentLevel == 1) ? 20 : (_currentLevel == 2) ? 30 : 40;
    final int stars3Threshold = fast;
    final int stars2Threshold = medium;

    // 타이머 바 비율 (medium 기준, 초과하면 1.0)
    final double timerRatio = (_elapsedSeconds / medium).clamp(0.0, 1.0);
    final Color timerColor = Color.lerp(
      const Color(0xFF00C853), const Color(0xFFFF1744), timerRatio)!;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.bgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // ── Play Area ────────────────────────────────────────────────
            Positioned.fill(
              top: 140,
              bottom: 130,
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
                          const SizedBox(width: 10),

                          // 힌트 버튼
                          GestureDetector(
                            onTap: _useHint,
                            child: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isHintActive
                                      ? [const Color(0xFF9E9E9E), const Color(0xFF757575)]
                                      : [const Color(0xFFFFE082), const Color(0xFFFFB300)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFFFFB300).withOpacity(0.5),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                )],
                              ),
                              child: const Center(
                                child: Text('🪄', style: TextStyle(fontSize: 22)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Row 2: 별 3개 + 타이머 진행바 ──────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(isDark ? 0.15 : 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // 별 3개
                            _buildStar(isLit: _elapsedSeconds <= stars2Threshold),
                            const SizedBox(width: 4),
                            _buildStar(isLit: _elapsedSeconds <= stars2Threshold),
                            const SizedBox(width: 4),
                            _buildStar(isLit: _elapsedSeconds <= stars3Threshold),
                            const SizedBox(width: 10),
                            // 타이머 진행바
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: timerRatio,
                                  minHeight: 10,
                                  backgroundColor: Colors.black.withOpacity(0.12),
                                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 초 표시
                            Container(
                              width: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: timerColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: timerColor.withOpacity(0.4), width: 1),
                              ),
                              child: Text(
                                '${_elapsedSeconds}s',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jua(
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF37474F),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
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

            // ── Star earned overlay ───────────────────────────────────────
            if (_earnedStars != null)
              _StarOverlay(starCount: _earnedStars!),

            // ── Level-up overlay ──────────────────────────────────────────
            if (_showLevelUp)
              _LevelUpOverlay(
                nextLevel: _nextLevelForOverlay,
                theme: _themes[_nextLevelForOverlay - 1],
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
      ),
    );
  }

  Widget _buildTargetBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withOpacity(0.14), Colors.white.withOpacity(0.06)]
              : [Colors.white.withOpacity(0.92), Colors.white.withOpacity(0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(isDark ? 0.2 : 0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "찾아야 할 것들" 라벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '찾아야 할 것들  ($_foundCount / ${_targets.length})',
                style: GoogleFonts.jua(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF546E7A),
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
      width: isFound ? 66 : 62,
      height: isFound ? 66 : 62,
      decoration: BoxDecoration(
        gradient: isFound
            ? const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDark
                    ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.06)]
                    : [const Color(0xFFF8F9FF), const Color(0xFFEEF2FF)],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFound
              ? const Color(0xFF00E676)
              : (isDark ? Colors.white.withOpacity(0.3) : const Color(0xFFBBDEFB)),
          width: 2.5,
        ),
        boxShadow: isFound
            ? [
                BoxShadow(
                  color: const Color(0xFF00C853).withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            opacity: isFound ? 0.35 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Text(emoji,
              style: TextStyle(fontSize: isFound ? 26 : 30)),
          ),
          if (isFound)
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildStar({required bool isLit}) {
    return AnimatedScale(
      scale: isLit ? 1.15 : 0.85,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: AnimatedOpacity(
        opacity: isLit ? 1.0 : 0.25,
        duration: const Duration(milliseconds: 300),
        child: Text('⭐',
          style: TextStyle(
            fontSize: 22,
            shadows: isLit
                ? const [Shadow(color: Colors.orange, blurRadius: 12)]
                : null,
          )),
      ),
    );
  }
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

class _HiddenItemWidgetState extends State<_HiddenItemWidget> with SingleTickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

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
  }

  @override
  void dispose() { _shakeCtrl.dispose(); super.dispose(); }

  void _handleTap() {
    widget.onTap();
    if (!widget.item.isTarget && !widget.item.isFound) {
      _shakeCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            animation: _shakeAnim,
            builder: (context, child) {
              return Transform.rotate(
                angle: widget.item.angle + _shakeAnim.value,
                child: Container(
                  decoration: widget.isHinted ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 8),
                    ],
                  ) : null,
                  child: child,
                ),
              );
            },
            child: Text(widget.item.emoji, style: TextStyle(fontSize: widget.item.size)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Star Overlay
// ─────────────────────────────────────────────

class _StarOverlay extends StatefulWidget {
  final int starCount;
  const _StarOverlay({required this.starCount});

  @override
  State<_StarOverlay> createState() => _StarOverlayState();
}

class _StarOverlayState extends State<_StarOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('클리어! 🎉', style: GoogleFonts.jua(fontSize: 30, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final isLit = i < widget.starCount;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(isLit ? '⭐' : '☆',
                      style: TextStyle(fontSize: isLit ? 40 : 36, color: isLit ? null : Colors.white38)),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Level-Up Overlay
// ─────────────────────────────────────────────

class _LevelUpOverlay extends StatefulWidget {
  final int nextLevel;
  final _LevelTheme theme;
  const _LevelUpOverlay({required this.nextLevel, required this.theme});

  @override
  State<_LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<_LevelUpOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: 0.75 * _ctrl.value),
          child: Center(
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Level ${widget.nextLevel}',
                    style: GoogleFonts.outfit(fontSize: 52, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${widget.theme.icon} ${widget.theme.name}',
                    style: GoogleFonts.jua(fontSize: 32, color: Colors.yellowAccent,
                      shadows: [const Shadow(color: Colors.deepOrange, blurRadius: 10)])),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
