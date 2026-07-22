import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/data/player_data_manager.dart';

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

class _LevelTheme {
  final String name;
  final String icon;
  final List<String> emojis;
  final Color backgroundColor;
  final Color cardBackColor;
  final String bgEmoji;

  const _LevelTheme({
    required this.name,
    required this.icon,
    required this.emojis,
    required this.backgroundColor,
    required this.cardBackColor,
    required this.bgEmoji,
  });
}

class MemoryCardData {
  final int id;
  final String emoji;
  final bool isFaceUp;
  final bool isMatched;

  MemoryCardData({
    required this.id,
    required this.emoji,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  MemoryCardData copyWith({bool? isFaceUp, bool? isMatched}) {
    return MemoryCardData(
      id: id,
      emoji: emoji,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}

// ─────────────────────────────────────────────
// Theme Data
// ─────────────────────────────────────────────

const List<_LevelTheme> _themes = [
  _LevelTheme(
    name: '바다 친구들',
    icon: '🌊',
    emojis: ['🐙', '🦀', '🐠', '🐳', '🦈', '🐚', '🦑', '🐬'],
    backgroundColor: Color(0xFFE3F2FD),
    cardBackColor: Color(0xFF42A5F5),
    bgEmoji: '🫧',
  ),
  _LevelTheme(
    name: '우주 탐험',
    icon: '🚀',
    emojis: ['🌍', '🌙', '⭐', '🛸', '👽', '🪐', '🌟', '☄️'],
    backgroundColor: Color(0xFF1A237E),
    cardBackColor: Color(0xFF7C4DFF),
    bgEmoji: '⭐',
  ),
  _LevelTheme(
    name: '봄 동산',
    icon: '🌸',
    emojis: ['🌻', '🌷', '🦋', '🐝', '🌈', '🍀', '🐞', '🍓', '🌺', '🎀', '🐣', '🌼'],
    backgroundColor: Color(0xFFFCE4EC),
    cardBackColor: Color(0xFFEC407A),
    bgEmoji: '🌸',
  ),

  _LevelTheme(
    name: '동물 농장',
    icon: '🐶',
    emojis: ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'],
    backgroundColor: Color(0xFFFFF8E1),
    cardBackColor: Color(0xFFFFCA28),
    bgEmoji: '🐾',
  ),
  _LevelTheme(
    name: '맛있는 간식',
    icon: '🍓',
    emojis: ['🍔', '🍟', '🍕', '🌭', '🍿', '🍩', '🍪', '🍰', '🧁', '🍫', '🍬', '🍭'],
    backgroundColor: Color(0xFFFBE9E7),
    cardBackColor: Color(0xFFFF7043),
    bgEmoji: '✨',
  ),
];

// ─────────────────────────────────────────────
// Main Game Widget
// ─────────────────────────────────────────────

class MemoryMatchGame extends StatefulWidget {
  const MemoryMatchGame({super.key});

  @override
  State<MemoryMatchGame> createState() => _MemoryMatchGameState();
}

class _MemoryMatchGameState extends State<MemoryMatchGame> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _ambientCtrl;
  final Random _random = Random();

  int _currentLevel = 1;
  List<MemoryCardData> _cards = [];

  List<int> _flippedIndices = [];
  bool _isProcessing = false;
  bool _isMemorizing = false;
  bool _isHintActive = false;

  // Combo system
  int _currentCombo = 0;
  String? _comboMessage;

  // Star timer system
  Timer? _gameTimer;
  int _elapsedSeconds = 0;
  int? _earnedStars;

  // Level-up overlay
  bool _showLevelUp = false;
  int _nextLevelForOverlay = 0;

  // Match celebration: indices of cards currently flying away
  Set<int> _flyingIndices = {};

  _LevelTheme get _currentTheme => _themes[_currentLevel - 1];

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

  // ─── Star calculation ───
  int _getStarCount() {
    int thresholdFast = 15;
    int thresholdMedium = 30;
    if (_currentLevel == 2) {
      thresholdFast = 25;
      thresholdMedium = 50;
    } else if (_currentLevel == 3) {
      thresholdFast = 35;
      thresholdMedium = 70;
    }
    if (_elapsedSeconds <= thresholdFast) return 3;
    if (_elapsedSeconds <= thresholdMedium) return 2;
    return 1;
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _elapsedSeconds = 0;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  // ─── Level management ───
  void _startLevel(int level) {
    _gameTimer?.cancel();

    setState(() {
      _currentLevel = level;
      _flippedIndices.clear();
      _isProcessing = false;
      _isMemorizing = true;
      _isHintActive = false;
      _currentCombo = 0;
      _comboMessage = null;
      _earnedStars = null;
      _flyingIndices = {};

      final theme = _themes[level - 1];
      int numCards = 4;
      if (level == 2) numCards = 8;
      if (level == 3) numCards = 12;
      if (level == 4) numCards = 16;
      if (level == 5) numCards = 20;

      int numPairs = numCards ~/ 2;
      final pool = List<String>.from(theme.emojis)..shuffle(_random);
      final selectedEmojis = pool.take(numPairs).toList();

      _cards.clear();
      int idCounter = 0;
      for (String emoji in selectedEmojis) {
        _cards.add(MemoryCardData(id: idCounter++, emoji: emoji, isFaceUp: true));
        _cards.add(MemoryCardData(id: idCounter++, emoji: emoji, isFaceUp: true));
      }
      _cards.shuffle(_random);
    });

    int peekSeconds = 2;
    if (level == 2) peekSeconds = 3;
    if (level == 3) peekSeconds = 4;

    Future.delayed(Duration(seconds: peekSeconds), () {
      if (!mounted || _currentLevel != level) return;
      setState(() {
        for (int i = 0; i < _cards.length; i++) {
          _cards[i] = _cards[i].copyWith(isFaceUp: false);
        }
        _isMemorizing = false;
      });
      _startTimer();
    });
  }

  // ─── Card tap handler ───
  void _onCardTap(int index) async {
    if (_isProcessing || _isMemorizing || _isHintActive ||
        _cards[index].isFaceUp || _cards[index].isMatched ||
        _flyingIndices.contains(index)) return;

    setState(() {
      _cards[index] = _cards[index].copyWith(isFaceUp: true);
      _flippedIndices.add(index);
    });

    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();

    if (_flippedIndices.length == 2) {
      _isProcessing = true;
      final int firstIdx = _flippedIndices[0];
      final int secondIdx = _flippedIndices[1];

      if (_cards[firstIdx].emoji == _cards[secondIdx].emoji) {
        // ── Match Success ──
        AudioManager.instance.playSuccess();
        HapticFeedback.mediumImpact();

        _currentCombo++;
        if (_currentCombo >= 2) {
          final combos = ['$_currentCombo연속!', '퍼펙트! 🤩', '최고야! 🔥', '대단해! 💫'];
          setState(() => _comboMessage = combos[_random.nextInt(combos.length)]);
          AudioManager.instance.playChime();
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted) setState(() => _comboMessage = null);
          });
        }

        // Trigger fly-away celebration
        setState(() {
          _flyingIndices.add(firstIdx);
          _flyingIndices.add(secondIdx);
        });

        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;
        setState(() {
          _cards[firstIdx] = _cards[firstIdx].copyWith(isMatched: true);
          _cards[secondIdx] = _cards[secondIdx].copyWith(isMatched: true);
          _flyingIndices.remove(firstIdx);
          _flyingIndices.remove(secondIdx);
          _flippedIndices.clear();
          _isProcessing = false;
        });

        _checkLevelComplete();
      } else {
        // ── Match Failed ──
        _currentCombo = 0;
        AudioManager.instance.playThud();
        HapticFeedback.lightImpact();

        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;
        setState(() {
          _cards[firstIdx] = _cards[firstIdx].copyWith(isFaceUp: false);
          _cards[secondIdx] = _cards[secondIdx].copyWith(isFaceUp: false);
          _flippedIndices.clear();
          _isProcessing = false;
        });
      }
    }
  }

  // ─── Hint ───
  void _useHint() async {
    if (_isProcessing || _isMemorizing || _isHintActive) return;
    bool hasUnmatched = _cards.any((c) => !c.isMatched && !c.isFaceUp);
    if (!hasUnmatched) return;

    AudioManager.instance.playBoing();

    setState(() {
      _isHintActive = true;
      for (int i = 0; i < _cards.length; i++) {
        if (!_cards[i].isMatched) {
          _cards[i] = _cards[i].copyWith(isFaceUp: true);
        }
      }
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _cards.length; i++) {
        if (!_cards[i].isMatched && !_flippedIndices.contains(i)) {
          _cards[i] = _cards[i].copyWith(isFaceUp: false);
        }
      }
      _isHintActive = false;
    });
  }

  // ─── Level complete check ───
  void _checkLevelComplete() {
    bool allMatched = _cards.every((c) => c.isMatched);
    if (!allMatched) return;

    _gameTimer?.cancel();
    final stars = _getStarCount();

    // Reward 1 Star Coin per level cleared
    PlayerDataManager.instance.addStarCoin(1);

    setState(() => _earnedStars = stars);

    if (stars == 3) {
      _confettiController.play();
    }

    AudioManager.instance.playSuccess();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _earnedStars = null);

      if (_currentLevel < 5) {
        // Show level-up overlay then start next level
        _showLevelUpOverlay(_currentLevel + 1);
      } else {
        // All levels cleared!
        _confettiController.play();
        _showVictoryDialog();
      }
    });
  }

  // ─── Level-up overlay ───
  void _showLevelUpOverlay(int nextLevel) {
    setState(() {
      _showLevelUp = true;
      _nextLevelForOverlay = nextLevel;
    });

    AudioManager.instance.playPop();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _showLevelUp = false);
      _startLevel(nextLevel);
    });
  }

  // ─── Victory dialog ───
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
              const Text('🎉 🎉 🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                '정말 똑똑해요!',
                style: GoogleFonts.jua(fontSize: 32, color: KidsTheme.orange, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '모든 레벨을 클리어했어요!',
                style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textLight),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KidsTheme.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: 5,
                ),
                onPressed: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                  _startLevel(1);
                },
                child: Text(
                  '다시 하기 🔄',
                  style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getGridCrossAxisCount() {
    if (_currentLevel == 1) return 2;
    if (_currentLevel == 5) return 4;
    return 4;
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.backgroundColor,
              theme.backgroundColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Floating Background Emojis
            ...List.generate(15, (i) {
              return Positioned(
                left: 20 + (i * 47) % MediaQuery.of(context).size.width,
                top: 50 + (i * 63) % MediaQuery.of(context).size.height,
                child: Opacity(
                  opacity: 0.15,
                  child: Text(
                    theme.bgEmoji,
                    style: TextStyle(fontSize: 30 + (i % 3) * 15.0),
                  ),
                ),
              );
            }),
            SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  _buildHeader(theme),
                  const SizedBox(height: 8),

                  // ── Star display ──
                  _buildStarBar(),
                  const SizedBox(height: 12),

                  // ── Game Board ──
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: AnimatedBuilder(
                          animation: _ambientCtrl,
                          builder: (context, child) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _getGridCrossAxisCount(),
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _cards.length,
                              itemBuilder: (context, index) {
                                double phase = index * 0.5;
                                double dy = sin((_ambientCtrl.value * pi * 2) + phase) * 3.5;

                                final isFlying = _flyingIndices.contains(index);

                                return AnimatedSlide(
                                  offset: isFlying ? const Offset(0, -2.5) : Offset.zero,
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInBack,
                                  child: AnimatedScale(
                                    scale: isFlying ? 0.0 : 1.0,
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInBack,
                                    child: AnimatedRotation(
                                      turns: isFlying ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 600),
                                      child: Transform.translate(
                                        offset: Offset(0, dy),
                                        child: FlipCardWidget(
                                          cardData: _cards[index],
                                          cardBackColor: theme.cardBackColor,
                                          onTap: () => _onCardTap(index),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Combo overlay ──
            if (_comboMessage != null)
              Align(
                alignment: Alignment.center,
                child: _ComboText(message: _comboMessage!),
              ),

            // ── Star earned overlay ──
            if (_earnedStars != null)
              _StarEarnedOverlay(starCount: _earnedStars!),

            // ── Level-up overlay ──
            if (_showLevelUp)
              _LevelUpOverlay(
                nextLevel: _nextLevelForOverlay,
                theme: _themes[_nextLevelForOverlay - 1],
              ),

            // ── Confetti ──
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.pink],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header widget ──
  Widget _buildHeader(_LevelTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            // Back Button
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 28),
              ),
            ),
            
            // Central Title
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${theme.icon} ${theme.name} (Lv $_currentLevel)',
                      style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            
            // Star Coins Counter
            ValueListenableBuilder<int>(
              valueListenable: PlayerDataManager.instance.starCoinsNotifier,
              builder: (context, starCoins, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '$starCoins',
                        style: GoogleFonts.jua(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Hint Button
            GestureDetector(
              onTap: _useHint,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: KidsTheme.yellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: const Center(child: Text('🪄', style: TextStyle(fontSize: 24))),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // ── Star bar widget ──
  Widget _buildStarBar() {
    int thresholdFast = (_currentLevel == 1) ? 15 : (_currentLevel == 2) ? 25 : 35;
    int thresholdMedium = (_currentLevel == 1) ? 30 : (_currentLevel == 2) ? 50 : 70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStar(isLit: _elapsedSeconds <= thresholdMedium),
          const SizedBox(width: 8),
          _buildStar(isLit: _elapsedSeconds <= thresholdMedium),
          const SizedBox(width: 8),
          _buildStar(isLit: _elapsedSeconds <= thresholdFast),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_elapsedSeconds}s',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: KidsTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStar({required bool isLit}) {
    return AnimatedScale(
      scale: isLit ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 300),
      child: AnimatedOpacity(
        opacity: isLit ? 1.0 : 0.3,
        duration: const Duration(milliseconds: 300),
        child: Text(
          '⭐',
          style: TextStyle(fontSize: 28, shadows: isLit ? [
            const Shadow(color: Colors.orange, blurRadius: 12),
          ] : null),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Flip Card Widget (3D)
// ─────────────────────────────────────────────

class FlipCardWidget extends StatefulWidget {
  final MemoryCardData cardData;
  final Color cardBackColor;
  final VoidCallback onTap;

  const FlipCardWidget({
    super.key,
    required this.cardData,
    required this.cardBackColor,
    required this.onTap,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.cardData.isFaceUp) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardData.isFaceUp && !oldWidget.cardData.isFaceUp) {
      _ctrl.forward();
    } else if (!widget.cardData.isFaceUp && oldWidget.cardData.isFaceUp) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardData.isMatched) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final double angle = _flipAnim.value * pi;
          final bool isFront = _flipAnim.value > 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront ? _buildCardFront() : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBackColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.4), size: 36),
      ),
    );
  }

  Widget _buildCardFront() {
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KidsTheme.orange, width: 3.5),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(0, 3), blurRadius: 4),
          ],
        ),
        child: Center(
          child: Text(widget.cardData.emoji, style: const TextStyle(fontSize: 44)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Combo Text Overlay
// ─────────────────────────────────────────────

class _ComboText extends StatefulWidget {
  final String message;
  const _ComboText({required this.message});

  @override
  State<_ComboText> createState() => _ComboTextState();
}

class _ComboTextState extends State<_ComboText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _ctrl.reverse();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
      child: FadeTransition(
        opacity: _ctrl,
        child: Text(
          widget.message,
          style: GoogleFonts.jua(
            fontSize: 56,
            color: Colors.yellowAccent,
            shadows: [
              const Shadow(color: Colors.deepOrange, offset: Offset(3, 3), blurRadius: 6),
              const Shadow(color: Colors.deepOrange, offset: Offset(-2, -2), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Star Earned Overlay
// ─────────────────────────────────────────────

class _StarEarnedOverlay extends StatefulWidget {
  final int starCount;
  const _StarEarnedOverlay({required this.starCount});

  @override
  State<_StarEarnedOverlay> createState() => _StarEarnedOverlayState();
}

class _StarEarnedOverlayState extends State<_StarEarnedOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _balloonScale;
  late Animation<double> _yOffset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    
    _balloonScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 50),
    ]).animate(_ctrl);

    _yOffset = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.fastLinearToSlowEaseIn),
    );

    _ctrl.forward();
    
    // Play sweet chime audio on coin reward display
    Future.microtask(() {
      AudioManager.instance.playChime();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _yOffset.value),
            child: ScaleTransition(
              scale: _balloonScale,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: KidsTheme.yellow, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating balloon & star decoration
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text('🎈', style: TextStyle(fontSize: 70)),
                        Positioned(
                          top: 10,
                          child: Transform.rotate(
                            angle: 0.1,
                            child: const Text('⭐', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '참 잘했어요! 🎉',
                      style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final isLit = i < widget.starCount;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            isLit ? '⭐' : '☆',
                            style: TextStyle(
                              fontSize: isLit ? 36 : 30,
                              color: isLit ? const Color(0xFFFFD700) : Colors.black12,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Gold Coin Reward Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFA500).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⭐', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            '+1 별코인!',
                            style: GoogleFonts.jua(fontSize: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                  Text(
                    'Level ${widget.nextLevel}',
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.theme.icon} ${widget.theme.name}',
                    style: GoogleFonts.jua(
                      fontSize: 36,
                      color: Colors.yellowAccent,
                      shadows: [
                        const Shadow(color: Colors.deepOrange, blurRadius: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
