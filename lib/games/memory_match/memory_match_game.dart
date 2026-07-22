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
  final List<Color> bgGradient;
  final Color cardBackColor;
  final Color cardBorderColor;
  final String cardBackEmoji;
  final String bgEmoji;

  const _LevelTheme({
    required this.name,
    required this.icon,
    required this.emojis,
    required this.bgGradient,
    required this.cardBackColor,
    required this.cardBorderColor,
    required this.cardBackEmoji,
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
    bgGradient: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF4DD0E1)],
    cardBackColor: Color(0xFF29B6F6),
    cardBorderColor: Color(0xFFB3E5FC),
    cardBackEmoji: '🎁', // 마법 보물상자
    bgEmoji: '🫧',
  ),
  _LevelTheme(
    name: '우주 탐험',
    icon: '🚀',
    emojis: ['🌍', '🌙', '⭐', '🛸', '👽', '🪐', '🌟', '☄️'],
    bgGradient: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4A148C)],
    cardBackColor: Color(0xFF7E57C2),
    cardBorderColor: Color(0xFFD1C4E9),
    cardBackEmoji: '🛸', // 유쾌한 UFO
    bgEmoji: '✨',
  ),
  _LevelTheme(
    name: '봄 동산',
    icon: '🌸',
    emojis: ['🌻', '🌷', '🦋', '🐝', '🌈', '🍀', '🐞', '🍓', '🌺', '🎀', '🐣', '🌼'],
    bgGradient: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFF48FB1)],
    cardBackColor: Color(0xFFEC407A),
    cardBorderColor: Color(0xFFFFCDD2),
    cardBackEmoji: '🧸', // 아기 곰돌이
    bgEmoji: '🌸',
  ),
  _LevelTheme(
    name: '동물 농장',
    icon: '🐶',
    emojis: ['🐶', '🐱', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'],
    bgGradient: [Color(0xFFFFF8E1), Color(0xFFFFECB3), Color(0xFFFFE082)],
    cardBackColor: Color(0xFFFFB300),
    cardBorderColor: Color(0xFFFFF59D),
    cardBackEmoji: '🎁', // 신나는 선물상자
    bgEmoji: '🐾',
  ),
  _LevelTheme(
    name: '맛있는 간식',
    icon: '🍓',
    emojis: ['🍔', '🍟', '🍕', '🌭', '🍿', '🍩', '🍪', '🍰', '🧁', '🍫', '🍬', '🍭'],
    bgGradient: [Color(0xFFFBE9E7), Color(0xFFFFCCBC), Color(0xFFFFAB91)],
    cardBackColor: Color(0xFFFF7043),
    cardBorderColor: Color(0xFFFFD180),
    cardBackEmoji: '🍬', // 새콤달콤 사탕
    bgEmoji: '🎈',
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
  late AnimationController _bgAnimCtrl;
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

  _LevelTheme get _currentTheme => _themes[(_currentLevel - 1) % _themes.length];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _startLevel(_currentLevel);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ambientCtrl.dispose();
    _bgAnimCtrl.dispose();
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

      final theme = _themes[(level - 1) % _themes.length];
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

    AudioManager.instance.playCardFlip();
    HapticFeedback.lightImpact();

    if (_flippedIndices.length == 2) {
      _isProcessing = true;
      int idx1 = _flippedIndices[0];
      int idx2 = _flippedIndices[1];

      if (_cards[idx1].emoji == _cards[idx2].emoji) {
        // MATCH!
        _currentCombo++;
        _triggerComboAnimation(_currentCombo);
        AudioManager.instance.playCardMatch();
        HapticFeedback.mediumImpact();

        // Flying card animation
        setState(() {
          _flyingIndices.addAll([idx1, idx2]);
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        setState(() {
          _cards[idx1] = _cards[idx1].copyWith(isMatched: true);
          _cards[idx2] = _cards[idx2].copyWith(isMatched: true);
          _flyingIndices.removeAll([idx1, idx2]);
          _flippedIndices.clear();
          _isProcessing = false;
        });

        // Check level completion
        if (_cards.every((c) => c.isMatched)) {
          _gameTimer?.cancel();
          int stars = _getStarCount();
          PlayerDataManager.instance.addStarCoin(stars);

          setState(() {
            _earnedStars = stars;
          });

          _confettiController.play();
          AudioManager.instance.playLevelComplete();

          Future.delayed(const Duration(seconds: 3), () {
            if (!mounted) return;
            if (_currentLevel < 5) {
              int nextLvl = _currentLevel + 1;
              setState(() {
                _earnedStars = null;
                _showLevelUp = true;
                _nextLevelForOverlay = nextLvl;
              });

              Future.delayed(const Duration(milliseconds: 1800), () {
                if (!mounted) return;
                setState(() => _showLevelUp = false);
                _startLevel(nextLvl);
              });
            } else {
              // Game Complete!
              _startLevel(1);
            }
          });
        }
      } else {
        // NO MATCH - 귀여운 보잉 틀림 사운드 재생
        _currentCombo = 0;
        AudioManager.instance.playCardMismatch();
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() {
          _cards[idx1] = _cards[idx1].copyWith(isFaceUp: false);
          _cards[idx2] = _cards[idx2].copyWith(isFaceUp: false);
          _flippedIndices.clear();
          _isProcessing = false;
        });
      }
    }
  }

  void _triggerComboAnimation(int combo) {
    if (combo >= 2) {
      setState(() {
        if (combo == 2) _comboMessage = '2연속 성공! 🔥';
        else if (combo == 3) _comboMessage = '3연속 대박! ⚡';
        else _comboMessage = '$combo연속 최고! 🚀';
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _comboMessage = null);
      });
    }
  }

  // ─── Magic Hint ───
  void _useHint() async {
    if (_isProcessing || _isMemorizing || _isHintActive) return;

    if (PlayerDataManager.instance.starCoins < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⭐ 별코인이 부족해요!', style: GoogleFonts.jua(fontSize: 16)),
          backgroundColor: KidsTheme.pink,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    PlayerDataManager.instance.spendStarCoins(1);

    AudioManager.instance.playChime();
    HapticFeedback.heavyImpact();
    setState(() => _isHintActive = true);

    // Briefly flip all un-matched cards up
    final unMatchedIndices = <int>[];
    for (int i = 0; i < _cards.length; i++) {
      if (!_cards[i].isMatched && !_cards[i].isFaceUp) {
        unMatchedIndices.add(i);
      }
    }

    setState(() {
      for (int i in unMatchedIndices) {
        _cards[i] = _cards[i].copyWith(isFaceUp: true);
      }
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      for (int i in unMatchedIndices) {
        _cards[i] = _cards[i].copyWith(isFaceUp: false);
      }
      _isHintActive = false;
    });
  }

  int _getGridCrossAxisCount() {
    if (_cards.length <= 4) return 2;
    if (_cards.length <= 8) return 4;
    if (_cards.length <= 12) return 4;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 아기자기하고 액티브한 동적 그라데이션 배경
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              final val = _bgAnimCtrl.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(theme.bgGradient[0], theme.bgGradient[1], val)!,
                      Color.lerp(theme.bgGradient[1], theme.bgGradient[2], val)!,
                      Color.lerp(theme.bgGradient[2], theme.bgGradient[0], val)!,
                    ],
                  ),
                ),
              );
            },
          ),

          // 🎈 둥둥 떠다니는 배경 아기자기 데코레이션 (구름/풍선/별/버블)
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              final val = _bgAnimCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    left: 20 + val * 40,
                    top: 80 - val * 10,
                    child: Opacity(
                      opacity: 0.65,
                      child: Text(theme.bgEmoji, style: const TextStyle(fontSize: 42)),
                    ),
                  ),
                  Positioned(
                    right: 30 + val * 30,
                    top: 130 + val * 15,
                    child: const Opacity(
                      opacity: 0.5,
                      child: Text('☁️', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  Positioned(
                    left: 200 - val * 30,
                    top: 160,
                    child: const Opacity(
                      opacity: 0.6,
                      child: Text('✨', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  Positioned(
                    right: 140 - val * 20,
                    bottom: 120 + val * 25,
                    child: Opacity(
                      opacity: 0.7,
                      child: Text(theme.bgEmoji, style: const TextStyle(fontSize: 38)),
                    ),
                  ),
                  Positioned(
                    left: 40 + val * 20,
                    bottom: 100 - val * 15,
                    child: const Opacity(
                      opacity: 0.55,
                      child: Text('🎈', style: TextStyle(fontSize: 44)),
                    ),
                  ),
                ],
              );
            },
          ),

          // 🎮 메인 게임 화면 UI
          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                const SizedBox(height: 8),
                _buildStarBar(),
                const SizedBox(height: 12),

                // 🎴 카드가 놓이는 메인 게임 영역
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: AnimatedBuilder(
                        animation: _ambientCtrl,
                        builder: (context, child) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _getGridCrossAxisCount(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.82,
                            ),
                            itemCount: _cards.length,
                            itemBuilder: (context, index) {
                              double phase = index * 0.4;
                              double dy = sin((_ambientCtrl.value * pi * 2) + phase) * 4.0;

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
                                        cardBorderColor: theme.cardBorderColor,
                                        cardBackEmoji: theme.cardBackEmoji,
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
              theme: _themes[(_nextLevelForOverlay - 1) % _themes.length],
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
    );
  }

  // ── Header widget ──
  Widget _buildHeader(_LevelTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2.5),
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
            // 뒤로가기 버튼
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.arrow_back, color: KidsTheme.textDark, size: 26),
              ),
            ),
            
            // 중앙 타이틀
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
            
            // 별코인 카운터
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

            // 힌트 요술봉 버튼
            GestureDetector(
              onTap: _useHint,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: KidsTheme.yellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Center(child: Text('🪄', style: TextStyle(fontSize: 22))),
              ),
            ),
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
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2),
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
// 3D 프리미엄 카드 뒷면 & 앞면 위젯 (FlipCardWidget)
// ─────────────────────────────────────────────

class FlipCardWidget extends StatefulWidget {
  final MemoryCardData cardData;
  final Color cardBackColor;
  final Color cardBorderColor;
  final String cardBackEmoji;
  final VoidCallback onTap;

  const FlipCardWidget({
    super.key,
    required this.cardData,
    required this.cardBackColor,
    required this.cardBorderColor,
    required this.cardBackEmoji,
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

  // 🎁 입체감 넘치는 귀여운 3D 장난감 상자 카드 뒷면
  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(widget.cardBackColor, Colors.white, 0.35)!,
            widget.cardBackColor,
            Color.lerp(widget.cardBackColor, Colors.black, 0.15)!,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: widget.cardBackColor.withValues(alpha: 0.4),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Colors.white30,
            offset: Offset(0, 2),
            blurRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 아기자기 도트 패턴
          Positioned(
            left: 8, top: 8,
            child: Text('✨', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
          ),
          Positioned(
            right: 8, bottom: 8,
            child: Text('✨', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7))),
          ),
          // 메인 신나는 장난감/보물상자 에디션 아이콘
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            ),
            child: Center(
              child: Text(
                widget.cardBackEmoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🃏 카드 앞면
  Widget _buildCardFront() {
    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFF9F43), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9F43).withValues(alpha: 0.3),
              offset: const Offset(0, 6),
              blurRadius: 10,
            ),
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
