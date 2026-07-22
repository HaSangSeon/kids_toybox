import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

class SpotDifferenceGame extends StatefulWidget {
  const SpotDifferenceGame({super.key});

  @override
  State<SpotDifferenceGame> createState() => _SpotDifferenceGameState();
}

class SceneElement {
  final int id;
  final String emoji;
  final double x; // 0.0 ~ 1.0
  final double y; // 0.0 ~ 1.0
  final double size;
  final double angle;

  SceneElement({
    required this.id,
    required this.emoji,
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
  });

  SceneElement copyWith({String? emoji}) {
    return SceneElement(
      id: id,
      emoji: emoji ?? this.emoji,
      x: x,
      y: y,
      size: size,
      angle: angle,
    );
  }
}

class _SpotDifferenceGameState extends State<SpotDifferenceGame> with TickerProviderStateMixin {
  final Random _random = Random();
  late ConfettiController _confettiController;

  List<SceneElement> _baseScene = [];
  List<SceneElement> _bottomScene = [];
  List<int> _differenceIds = [];
  List<int> _foundDifferenceIds = [];
  List<Map<String, dynamic>> _wrongTaps = [];
  bool _isGameOver = false;

  final List<String> _swapPool = ["🍏", "🐱", "🌹", "🛸", "🐝", "🦆", "🐢", "🍄"];

  List<Color> _currentBg = [Color(0xFF87CEEB), Color(0xFFE0F6FF)];
  Color _currentGround = Color(0xFF9CCC65);

  final List<List<String>> _themes = [
    ["☀️", "☁️", "🌲", "🌳", "🏠", "🍎", "🐶", "🦋", "🌻", "🌷", "🎈", "🐦", "🚗"], // Park
    ["🌙", "⭐", "✨", "👾", "🚀", "🛸", "🌍", "👨‍🚀", "🛰️", "☄️", "🪐"], // Space
    ["☀️", "☁️", "⛵", "🐟", "🐠", "🦀", "🐙", "🐬", "🐚", "🐳", "🏝️"], // Ocean
    ["☀️", "☁️", "🌵", "🐫", "🐍", "🦂", "🏜️", "🌴", "🦅", "🦎"], // Desert
    ["☀️", "☁️", "🚜", "🐄", "🐖", "🐔", "🏚️", "🌽", "🌻", "🐴", "🐑"], // Farm
  ];

  final List<List<Color>> _backgrounds = [
    [Color(0xFF87CEEB), Color(0xFFE0F6FF)], // Park (Sky)
    [Color(0xFF1A237E), Color(0xFF000000)], // Space (Dark)
    [Color(0xFF4FC3F7), Color(0xFF0288D1)], // Ocean (Water)
    [Color(0xFFFFB74D), Color(0xFFFFE082)], // Desert
    [Color(0xFF64B5F6), Color(0xFFBBDEFB)], // Farm (Sky)
  ];

  final List<Color> _groundColors = [
    Color(0xFF9CCC65), // Park grass
    Color(0xFF424242), // Space moon rock
    Color(0xFFFFF59D), // Ocean sand
    Color(0xFFFFCC80), // Desert sand
    Color(0xFFAED581), // Farm grass
  ];

  // Feature: Combo System
  DateTime? _lastTapTime;
  String? _comboMessage;
  
  // Feature: Hint System
  bool _isHintFlying = false;
  Offset? _hintTargetOffset;
  
  // Feature: Ambient Animation
  late AnimationController _ambientCtrl;

  // Feature: Round System (3 rounds)
  int _currentRound = 1;
  static const int _totalRounds = 3;
  bool _showRoundOverlay = false;
  int _nextRoundForOverlay = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _startNewGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ambientCtrl.dispose();
    super.dispose();
  }

  void _startNewGame({bool resetRound = true}) {
    setState(() {
      if (resetRound) _currentRound = 1;
      _isGameOver = false;
      _foundDifferenceIds.clear();
      _wrongTaps.clear();
      _lastTapTime = null;
      _comboMessage = null;
      _isHintFlying = false;
      
      final int themeIdx = _random.nextInt(_themes.length);
      final currentThemePool = _themes[themeIdx];
      
      _currentBg = _backgrounds[themeIdx];
      _currentGround = _groundColors[themeIdx];

      List<SceneElement> newScene = [];
      int idCounter = 0;
      
      for(int row=0; row<4; row++){
        for(int col=0; col<4; col++){
           final emoji = currentThemePool[_random.nextInt(currentThemePool.length)];
           final x = (col + 0.2 + _random.nextDouble() * 0.6) / 4.0; 
           final y = (row + 0.2 + _random.nextDouble() * 0.6) / 4.0;
           final size = 35.0 + _random.nextDouble() * 25.0;
           final angle = (_random.nextDouble() - 0.5) * 1.0;
           newScene.add(SceneElement(id: idCounter++, emoji: emoji, x: x, y: y, size: size, angle: angle));
        }
      }
      _baseScene = newScene;

      _bottomScene = List.from(_baseScene);
      
      var ids = _baseScene.map((e) => e.id).toList();
      ids.shuffle();
      _differenceIds = ids.take(3).toList();

      for (int diffId in _differenceIds) {
        int index = _bottomScene.indexWhere((e) => e.id == diffId);
        if (index != -1) {
          if (_random.nextBool()) {
            _bottomScene.removeAt(index);
          } else {
            final String newEmoji = _swapPool[_random.nextInt(_swapPool.length)];
            _bottomScene[index] = _bottomScene[index].copyWith(emoji: newEmoji);
          }
        }
      }
    });
  }

  void _onCanvasTap(double relX, double relY) {
    if (_isGameOver) return;

    int? foundDiffId;
    for (int diffId in _differenceIds) {
      if (_foundDifferenceIds.contains(diffId)) continue;
      final element = _baseScene.firstWhere((e) => e.id == diffId);
      final dx = element.x - relX;
      final dy = element.y - relY;
      final distSq = dx * dx + dy * dy;
      if (distSq < 0.015) { 
        foundDiffId = diffId;
        break;
      }
    }

    if (foundDiffId != null) {
      AudioManager.instance.playSuccess();
      HapticFeedback.mediumImpact();
      
      // Combo Logic
      final now = DateTime.now();
      if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds <= 4) {
        // Trigger Combo!
        final combos = ["최고야! 🤩", "우와! 🚀", "대단해! 🔥"];
        setState(() {
          _comboMessage = combos[_random.nextInt(combos.length)];
        });
        AudioManager.instance.playPop(); // Extra combo sound
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _comboMessage = null);
        });
      }
      _lastTapTime = now;

      setState(() {
        _foundDifferenceIds.add(foundDiffId!);
        _isHintFlying = false; // reset hint
        if (_foundDifferenceIds.length >= _differenceIds.length) {
          _isGameOver = true;
          AudioManager.instance.playPop();
          if (_currentRound < _totalRounds) {
            // Show round transition overlay then start next round
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              _showRoundTransition(_currentRound + 1);
            });
          } else {
            // All rounds cleared!
            _confettiController.play();
            Future.delayed(const Duration(milliseconds: 1000), _showVictoryDialog);
          }
        }
      });
    } else {
      AudioManager.instance.playClick();
      HapticFeedback.lightImpact();
      
      final wrongTap = {
        'x': relX,
        'y': relY,
        'id': DateTime.now().millisecondsSinceEpoch.toString()
      };
      
      setState(() {
        _wrongTaps.add(wrongTap);
        _lastTapTime = null; // break combo
      });
      
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _wrongTaps.remove(wrongTap);
          });
        }
      });
    }
  }

  void _useHint(BoxConstraints constraints) {
    if (_isGameOver || _isHintFlying) return;
    
    // Find a remaining difference
    final remaining = _differenceIds.where((id) => !_foundDifferenceIds.contains(id)).toList();
    if (remaining.isEmpty) return;
    
    AudioManager.instance.playColorSelect(); // Magical sound
    final targetId = remaining.first;
    final element = _baseScene.firstWhere((e) => e.id == targetId);
    
    setState(() {
      _isHintFlying = true;
      _hintTargetOffset = Offset(
        element.x * constraints.maxWidth, 
        element.y * constraints.maxHeight
      );
    });

    // Reset hint after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isHintFlying = false;
        });
      }
    });
  }

  void _showRoundTransition(int nextRound) {
    setState(() {
      _showRoundOverlay = true;
      _nextRoundForOverlay = nextRound;
    });
    AudioManager.instance.playPop();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _showRoundOverlay = false;
        _currentRound = nextRound;
      });
      _startNewGame(resetRound: false);
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
          decoration: KidsTheme.toyDecoration(
            color: Colors.white,
            borderRadius: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌟 🌟 🌟', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                '모든 라운드 클리어!',
                style: GoogleFonts.jua(
                  fontSize: 28,
                  color: KidsTheme.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalRounds라운드를 모두 통과했어요!',
                style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textLight),
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
                  _startNewGame();
                },
                child: Text(
                  '다시 하기 🔄',
                  style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneCanvas(List<SceneElement> sceneElements, {required bool isInteractive, bool isTop = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: isInteractive ? (details) {
            final relX = details.localPosition.dx / constraints.maxWidth;
            final relY = details.localPosition.dy / constraints.maxHeight;
            _onCanvasTap(relX, relY);
          } : null,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentBg,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                // Ground
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight * 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _currentGround,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                  ),
                ),
                
                // Ambient Animated Scene Elements
                ...sceneElements.map((item) {
                  final isCloudOrFish = ["☁️", "🐟", "🐠", "🐬", "🦋"].contains(item.emoji);
                  final isStar = ["⭐", "✨", "☄️"].contains(item.emoji);
                  
                  return AnimatedBuilder(
                    animation: _ambientCtrl,
                    builder: (context, child) {
                      double dx = 0;
                      double dy = 0;
                      double opacity = 1.0;
                      
                      if (isCloudOrFish) {
                        dx = (_ambientCtrl.value - 0.5) * 30.0; // slight drift left-right
                        dy = sin(_ambientCtrl.value * pi * 2) * 5.0; // bobbing
                      } else if (isStar) {
                        opacity = 0.5 + (_ambientCtrl.value * 0.5); // twinkling
                      }
                      
                      return Positioned(
                        left: (item.x * constraints.maxWidth - (item.size / 2)) + dx,
                        top: (item.y * constraints.maxHeight - (item.size / 2)) + dy,
                        child: Opacity(
                          opacity: opacity,
                          child: Transform.rotate(
                            angle: item.angle,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      item.emoji,
                      style: TextStyle(fontSize: item.size),
                    ),
                  );
                }).toList(),

                // Found differences Overlays (Circles)
                ..._foundDifferenceIds.map((diffId) {
                  final element = _baseScene.firstWhere((e) => e.id == diffId);
                  return Positioned(
                    left: element.x * constraints.maxWidth - 40,
                    top: element.y * constraints.maxHeight - 40,
                    child: const _CorrectMark(),
                  );
                }).toList(),

                // Wrong Tap Overlays (X marks)
                if (isInteractive) ..._wrongTaps.map((wt) {
                  return Positioned(
                    left: (wt['x'] as double) * constraints.maxWidth - 30,
                    top: (wt['y'] as double) * constraints.maxHeight - 30,
                    child: const _WrongMark(),
                  );
                }).toList(),
                
                // Magic Hint Wand Flying
                if (isInteractive && _isHintFlying && _hintTargetOffset != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOut,
                    left: _hintTargetOffset!.dx - 20,
                    top: _hintTargetOffset!.dy - 20,
                    child: const Text('🪄', style: TextStyle(fontSize: 40)),
                  ),
                  
                // Combo Text Overlay
                if (isInteractive && _comboMessage != null)
                  Align(
                    alignment: Alignment.center,
                    child: _ComboText(message: _comboMessage!),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Color.lerp(
      const Color(0xFF7C4DFF),
      const Color(0xFF2979FF),
      _currentRound / _totalRounds,
    )!;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF0D2137)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
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
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFFFF6B9D).withOpacity(0.5),
                              blurRadius: 10, offset: const Offset(0, 4),
                            )],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 중앙 정보 패널
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              // 라운드 뱃지
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentColor, accentColor.withOpacity(0.7)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(
                                    color: accentColor.withOpacity(0.5), blurRadius: 8,
                                  )],
                                ),
                                child: Text(
                                  'Round $_currentRound/$_totalRounds',
                                  style: GoogleFonts.jua(fontSize: 14, color: Colors.white, height: 1.1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 라운드 진행 도트
                              ...List.generate(_totalRounds, (i) {
                                final isDone = i < _currentRound - 1;
                                final isCurrent = i == _currentRound - 1;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: isCurrent ? 16 : 10, height: 10,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: isDone
                                          ? const Color(0xFF00C853)
                                          : isCurrent
                                              ? const Color(0xFFFFB300)
                                              : Colors.white.withOpacity(0.2),
                                      boxShadow: isCurrent ? [BoxShadow(
                                        color: const Color(0xFFFFB300).withOpacity(0.6), blurRadius: 6,
                                      )] : null,
                                    ),
                                  ),
                                );
                              }),
                              const Spacer(),
                              // 찾은 하트
                              ...List.generate(_differenceIds.length, (i) {
                                final found = i < _foundDifferenceIds.length;
                                return Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: AnimatedScale(
                                    scale: found ? 1.2 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.elasticOut,
                                    child: Text(found ? '❤️' : '🤍',
                                      style: TextStyle(fontSize: found ? 20 : 18)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 힌트 버튼
                      GestureDetector(
                        onTap: () {
                          final Size sz = MediaQuery.of(context).size;
                          _useHint(BoxConstraints(
                            maxWidth: sz.width - 24,
                            maxHeight: (sz.height - 200) / 2,
                          ));
                        },
                        child: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isHintFlying
                                  ? [const Color(0xFF9E9E9E), const Color(0xFF757575)]
                                  : [const Color(0xFFFFE082), const Color(0xFFFFB300)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFFFFB300).withOpacity(0.5),
                              blurRadius: 10, offset: const Offset(0, 4),
                            )],
                          ),
                          child: const Center(child: Text('💡', style: TextStyle(fontSize: 22))),
                        ),
                      ),
                    ],
                  ),
                ),

                // 위 그림 (원본) — 터치 가능
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.6), width: 3),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.25), blurRadius: 14,
                          )],
                        ),
                        child: Stack(
                          children: [
                            _buildSceneCanvas(_baseScene, isInteractive: true, isTop: true),
                            Positioned(
                              top: 8, left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C4DFF).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('⭐ 원본',
                                  style: GoogleFonts.jua(fontSize: 12, color: Colors.white, height: 1.1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 중앙 배너
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFFF6B9D).withOpacity(0.4), blurRadius: 10,
                      )],
                    ),
                    child: Text(
                      '🔍 다른 부분 ${_foundDifferenceIds.length}/${_differenceIds.length} 찾았어요!',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.white, height: 1.1),
                    ),
                  ),
                ),

                // 아래 그림 (다른것) — 터치 가능
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.6), width: 3),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFFFF6B9D).withOpacity(0.25), blurRadius: 14,
                          )],
                        ),
                        child: Stack(
                          children: [
                            _buildSceneCanvas(_bottomScene, isInteractive: true, isTop: false),
                            Positioned(
                              top: 8, left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('🔍 다른것',
                                  style: GoogleFonts.jua(fontSize: 12, color: Colors.white, height: 1.1)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_showRoundOverlay)
            _RoundOverlay(nextRound: _nextRoundForOverlay, totalRounds: _totalRounds),

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
}

class _CorrectMark extends StatefulWidget {
  const _CorrectMark();
  @override
  State<_CorrectMark> createState() => _CorrectMarkState();
}

class _CorrectMarkState extends State<_CorrectMark> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
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
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.pinkAccent, width: 6),
        ),
      ),
    );
  }
}

class _WrongMark extends StatefulWidget {
  const _WrongMark();
  @override
  State<_WrongMark> createState() => _WrongMarkState();
}

class _WrongMarkState extends State<_WrongMark> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _ctrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
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
        child: const Icon(
          Icons.close_rounded,
          color: Colors.red,
          size: 60,
        ),
      ),
    );
  }
}

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
      Future.delayed(const Duration(milliseconds: 300), () {
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
            fontSize: 60,
            color: Colors.yellowAccent,
            shadows: [
              const Shadow(color: Colors.deepOrange, offset: Offset(3, 3), blurRadius: 5),
              const Shadow(color: Colors.deepOrange, offset: Offset(-3, -3), blurRadius: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundOverlay extends StatelessWidget {
  final int nextRound;
  final int totalRounds;

  const _RoundOverlay({
    required this.nextRound,
    required this.totalRounds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: KidsTheme.orange, width: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '라운드 클리어! 🎉',
                style: GoogleFonts.jua(fontSize: 48, color: KidsTheme.orange),
              ),
              const SizedBox(height: 16),
              Text(
                '다음 라운드: $nextRound / $totalRounds',
                style: GoogleFonts.jua(fontSize: 32, color: KidsTheme.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
