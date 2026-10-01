import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';



part 'models/hidden_object_models.dart';
part 'widgets/hidden_object_widgets.dart';
part 'painters/hidden_object_painters.dart';

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


  bool _showStageSelect = true; // Open stage selection on game start!
  bool _isHintActive = false;
  String? _hintEmoji;

  _LevelTheme get _currentTheme => _themes[_currentLevel - 1];

  int get _targetCount => 3; // 3 targets max - spacious and toddler-friendly!
  int get _scatterCount => 30;

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

      // 1. Place target items across the entire play area (safely between header and bottom bar)
      final List<HiddenItem> targetItems = [];
      for (String target in _targets) {
        double px = 0, py = 0;
        bool valid = false;
        int attempts = 0;
        while (!valid && attempts < 50) {
          attempts++;
          px = 0.12 + _random.nextDouble() * 0.76;
          py = 0.12 + _random.nextDouble() * 0.76;
          valid = !targetItems.any((t) => (t.x - px).abs() < 0.16 && (t.y - py).abs() < 0.16);
        }
        targetItems.add(HiddenItem(
          emoji: target,
          x: px,
          y: py,
          size: 44.0 + _random.nextDouble() * 14.0,
          angle: (_random.nextDouble() - 0.5) * 0.5,
          isTarget: true,
        ));
      }

      // 2. Generate scatter items across the entire play area
      final List<HiddenItem> scatterItems = [];
      for (int i = 0; i < _scatterCount; i++) {
        final emoji = theme.scatterEmojis[_random.nextInt(theme.scatterEmojis.length)];
        double sx = 0, sy = 0;
        bool valid = false;
        int attempts = 0;
        while (!valid && attempts < 30) {
          attempts++;
          sx = 0.08 + _random.nextDouble() * 0.84;
          sy = 0.08 + _random.nextDouble() * 0.84;
          valid = !targetItems.any((t) => (t.x - sx).abs() < 0.10 && (t.y - sy).abs() < 0.10);
        }
        scatterItems.add(HiddenItem(
          emoji: emoji,
          x: sx,
          y: sy,
          size: 32.0 + _random.nextDouble() * 18.0,
          angle: (_random.nextDouble() - 0.5) * 1.0,
        ));
      }

      // Scatter items rendered first, Target items ALWAYS rendered ON TOP!
      _items = [...scatterItems, ...targetItems];
    });
  }

  void _onItemTap(HiddenItem item) {
    if (item.isFound || _isLevelClear) return;

    if (item.isTarget) {
      AudioManager.instance.playJigsawSnapCorrect();
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

      AudioManager.instance.playMagicUnfoldSuccess();
      _confettiController.play();
    }
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
          
          // ── Play Area (Fully extended between header and bottom bar) ─
          Positioned.fill(
              top: 75,
              bottom: 135,
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
                  child: SingleChildScrollView(
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
                                border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                                boxShadow: [BoxShadow(
                                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.5),
                                  blurRadius: 8, offset: const Offset(0, 3),
                                )],
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 테마 이름 + 레벨 뱃지
                          // 테마 이름 + 레벨 뱃지 (터치 시 단계 선택 창 오픈)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                setState(() {
                                  _showStageSelect = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.18)
                                      : Colors.white.withValues(alpha: 0.90),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Text(theme.icon, style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        theme.name,
                                        style: GoogleFonts.jua(
                                          fontSize: 18,
                                          color: isDark ? Colors.white : const Color(0xFF37474F),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down_circle_rounded, size: 18, color: Colors.orange),
                                  ],
                                ),
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
            ),

            // ── Bottom Target Bar ─────────────────────────────────────────
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: SafeArea(
                top: false,
                child: _buildTargetBar(isDark),
              ),
            ),



            // ── Stage Clear Celebration Overlay ───────────────────────────
            if (_isLevelClear) _buildStageClearOverlay(),

            // ── Stage Select Modal Overlay ─────────────────────────────────
            if (_showStageSelect) _buildStageSelectOverlay(),

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

  // ── Stage Clear Overlay ───────────────────────────────────────────────────
  Widget _buildStageClearOverlay() {
    final bool hasNext = _currentLevel < _themes.length;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉 🥳 🔍', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 12),
                Text(
                  '참 잘했어요!',
                  style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.purple),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentTheme.name} 탐험 성공!',
                  style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFF10AC84)),
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasNext)
                      ElevatedButton(
                        onPressed: () {
                          AudioManager.instance.playClick();
                          _startLevel(_currentLevel + 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KidsTheme.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('🚀 다음 테마 탐험하기!', style: GoogleFonts.jua(fontSize: 18)),
                      ),
                    if (hasNext) const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _isLevelClear = false;
                          _showStageSelect = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsTheme.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('🗺️ 테마 선택하기', style: GoogleFonts.jua(fontSize: 18)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stage Select Overlay ──────────────────────────────────────────────────
  Widget _buildStageSelectOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.70),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 580),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        setState(() {
                          _showStageSelect = false;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: KidsTheme.textDark),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 26)),
                          const SizedBox(width: 6),
                          Text(
                            '탐험 테마 선택',
                            style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36), // Right symmetry spacer
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '놀러 가고 싶은 장소를 마음대로 골라보세요!',
                  style: GoogleFonts.jua(fontSize: 12, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.15,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _themes.length,
                    itemBuilder: (context, index) {
                      final theme = _themes[index];
                      final bool isCurrent = _currentLevel == (index + 1);
                      final Color mainColor = theme.bgGradient.first;

                      return GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          _startLevel(index + 1);
                          setState(() {
                            _showStageSelect = false;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [mainColor.withValues(alpha: 0.9), theme.bgGradient.last],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: isCurrent ? Border.all(color: Colors.yellow, width: 3.5) : null,
                            boxShadow: [
                              BoxShadow(
                                color: mainColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(theme.icon, style: const TextStyle(fontSize: 44)),
                              const SizedBox(height: 4),
                              Text(
                                theme.name,
                                style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFFB74D), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "찾아야 할 것들" 캡슐 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7043), Color(0xFFFFB74D)],
              ),
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 8),
          // 아이템 카드들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
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

