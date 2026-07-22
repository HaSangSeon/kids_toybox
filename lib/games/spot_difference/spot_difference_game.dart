import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/data/player_data_manager.dart';

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
  late AnimationController _ambientCtrl;
  late AnimationController _bgAnimCtrl;

  List<SceneElement> _baseScene = [];
  List<SceneElement> _bottomScene = [];
  List<int> _differenceIds = [];
  List<int> _foundDifferenceIds = [];
  List<Map<String, dynamic>> _wrongTaps = [];
  bool _isGameOver = false;

  final List<String> _swapPool = ["🍏", "🐱", "🌹", "🛸", "🐝", "🦆", "🐢", "🍄", "🧸", "🦄"];

  List<Color> _currentBg = [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)];
  Color _currentGround = const Color(0xFFC8E6C9);

  final List<List<String>> _themes = [
    ["☀️", "☁️", "🌲", "🌳", "🏠", "🍎", "🐶", "🦋", "🌻", "🌷", "🎈", "🐦", "🚗"], // 동화 공원
    ["🌙", "⭐", "✨", "👾", "🚀", "🛸", "🌍", "👨‍🚀", "🛰️", "☄️", "🪐"], // 신비 우주
    ["☀️", "☁️", "⛵", "🐟", "🐠", "🦀", "🐙", "🐬", "🐚", "🐳", "🏝️"], // 시원 바다
    ["☀️", "☁️", "🌵", "🐫", "🐍", "🦂", "🏜️", "🌴", "🦅", "🦎"], // 황금 사막
    ["☀️", "☁️", "🚜", "🐄", "🐖", "🐔", "🏚️", "🌽", "🌻", "🐴", "🐑"], // 동물 농장
  ];

  final List<List<Color>> _backgrounds = [
    [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)], // 공원 (하늘)
    [const Color(0xFF311B92), Color(0xFF4A148C)], // 우주 (보라 밤하늘)
    [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)], // 바다 (에메랄드)
    [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)], // 사막 (크림 파스텔)
    [const Color(0xFFF1F8E9), const Color(0xFFDCEDC8)], // 농장 (연두 파스텔)
  ];

  final List<Color> _groundColors = [
    const Color(0xFFAED581), // 공원 풀밭
    const Color(0xFF7E57C2), // 우주 행성 표면
    const Color(0xFFFFE082), // 바다 모래사장
    const Color(0xFFFFCC80), // 사막 언덕
    const Color(0xFF9CCC65), // 농장 잔디
  ];

  // Combo System
  DateTime? _lastTapTime;
  String? _comboMessage;
  
  // Hint System
  bool _isHintFlying = false;
  Offset? _hintTargetOffset;

  // Round System (3 rounds)
  int _currentRound = 1;
  static const int _totalRounds = 3;
  bool _showRoundOverlay = false;
  int _nextRoundForOverlay = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _ambientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _bgAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _startNewGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _ambientCtrl.dispose();
    _bgAnimCtrl.dispose();
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
      
      for (int row = 0; row < 4; row++) {
        for (int col = 0; col < 4; col++) {
           final emoji = currentThemePool[_random.nextInt(currentThemePool.length)];
           final x = (col + 0.2 + _random.nextDouble() * 0.6) / 4.0; 
           final y = (row + 0.2 + _random.nextDouble() * 0.6) / 4.0;
           final size = 35.0 + _random.nextDouble() * 25.0;
           final angle = (_random.nextDouble() - 0.5) * 0.8;
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

  // 🎯 틀린 곳 터치 판정
  void _onCanvasTap(double relX, double relY) {
    if (_isGameOver) return;

    int? foundDiffId;
    for (int diffId in _differenceIds) {
      if (_foundDifferenceIds.contains(diffId)) continue;
      final element = _baseScene.firstWhere((e) => e.id == diffId);
      final dx = element.x - relX;
      final dy = element.y - relY;
      final distSq = dx * dx + dy * dy;
      if (distSq < 0.018) { 
        foundDiffId = diffId;
        break;
      }
    }

    if (foundDiffId != null) {
      // 🌟 틀린 곳 정답 클릭! -> 청아하고 상쾌한 딩동 챠임음!
      AudioManager.instance.playCardMatch();
      HapticFeedback.mediumImpact();
      
      // 콤보 시스템
      final now = DateTime.now();
      if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds <= 4) {
        final combos = ["참 잘했어요! ✨", "대단해! 🎯", "우와! 🚀"];
        setState(() {
          _comboMessage = combos[_random.nextInt(combos.length)];
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) setState(() => _comboMessage = null);
        });
      }
      _lastTapTime = now;

      setState(() {
        _foundDifferenceIds.add(foundDiffId!);
        _isHintFlying = false;
        if (_foundDifferenceIds.length >= _differenceIds.length) {
          _isGameOver = true;
          if (_currentRound < _totalRounds) {
            AudioManager.instance.playLevelComplete();
            Future.delayed(const Duration(milliseconds: 800), () {
              if (!mounted) return;
              _showRoundTransition(_currentRound + 1);
            });
          } else {
            // All 3 rounds cleared!
            PlayerDataManager.instance.addStarCoin(2);
            _confettiController.play();
            AudioManager.instance.playLevelComplete();
            Future.delayed(const Duration(milliseconds: 1000), _showVictoryDialog);
          }
        }
      });
    } else {
      // 🐣 오답 터치! -> 아이들이 좋아하는 귀여운 보잉 사운드!
      AudioManager.instance.playCardMismatch();
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
      
      Future.delayed(const Duration(milliseconds: 900), () {
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
    
    int? hintId;
    for (int id in _differenceIds) {
      if (!_foundDifferenceIds.contains(id)) {
        hintId = id;
        break;
      }
    }
    
    if (hintId != null) {
      final element = _baseScene.firstWhere((e) => e.id == hintId);
      AudioManager.instance.playChime();
      HapticFeedback.heavyImpact();

      setState(() {
        _isHintFlying = true;
        _hintTargetOffset = Offset(
          element.x * constraints.maxWidth,
          element.y * constraints.maxHeight,
        );
      });
    }
  }

  void _showRoundTransition(int nextRound) {
    setState(() {
      _showRoundOverlay = true;
      _nextRoundForOverlay = nextRound;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
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
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFD700), width: 4),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 🌟 🏆', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text(
                '모든 틀린그림 찾기 성공!',
                style: GoogleFonts.jua(
                  fontSize: 26,
                  color: KidsTheme.purple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3개 라운드를 모두 맞췄어요! (+2 별코인)',
                style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                  _startNewGame(resetRound: true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: Text(
                    '다시 도전하기 🔄',
                    style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
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
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentBg,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                // 바닥 언덕 라인
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight * 0.28,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _currentGround,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
                
                // 배경 동적 요소 (구름/물고기/별 애니메이션)
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
                        dx = (_ambientCtrl.value - 0.5) * 20.0;
                        dy = sin(_ambientCtrl.value * pi * 2) * 4.0;
                      } else if (isStar) {
                        opacity = 0.6 + (_ambientCtrl.value * 0.4);
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

                // 정답 동그라미 뱃지
                ..._foundDifferenceIds.map((diffId) {
                  final element = _baseScene.firstWhere((e) => e.id == diffId);
                  return Positioned(
                    left: element.x * constraints.maxWidth - 36,
                    top: element.y * constraints.maxHeight - 36,
                    child: const _CorrectMark(),
                  );
                }).toList(),

                // 오답 ❌ 표시
                if (isInteractive) ..._wrongTaps.map((wt) {
                  return Positioned(
                    left: (wt['x'] as double) * constraints.maxWidth - 28,
                    top: (wt['y'] as double) * constraints.maxHeight - 28,
                    child: const _WrongMark(),
                  );
                }).toList(),
                
                // 🪄 요술봉 힌트
                if (isInteractive && _isHintFlying && _hintTargetOffset != null)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 1200),
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 3D 동화 속 무지개 배경
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE0F7FA), // Sky cyan
                      Color.lerp(const Color(0xFFFFF9C4), const Color(0xFFFFE0B2), _bgAnimCtrl.value)!, // Warm cream
                      const Color(0xFFFCE4EC), // Soft pink
                    ],
                  ),
                ),
              );
            },
          ),

          // ☁️ 둥둥 구름 & 🎈 풍선 무드 요소
          AnimatedBuilder(
            animation: _bgAnimCtrl,
            builder: (context, child) {
              final val = _bgAnimCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    left: 15 + val * 25,
                    top: 65,
                    child: const Opacity(opacity: 0.6, child: Text('☁️', style: TextStyle(fontSize: 46))),
                  ),
                  Positioned(
                    right: 25 + val * 35,
                    top: 130,
                    child: const Opacity(opacity: 0.5, child: Text('☁️', style: TextStyle(fontSize: 38))),
                  ),
                  Positioned(
                    right: 160 + val * 15,
                    top: 80,
                    child: const Opacity(opacity: 0.6, child: Text('🎈', style: TextStyle(fontSize: 32))),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // 3D Glassmorphic 프리미엄 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // 🏠 뒤로가기 버튼
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
                            
                            // 🎨 메인 타이틀
                            Expanded(
                              child: Center(
                                child: Text(
                                  '틀린그림 찾기 🔍 (Lv $_currentRound/$_totalRounds)',
                                  style: GoogleFonts.jua(
                                    fontSize: 19,
                                    foreground: Paint()
                                      ..style = PaintingStyle.fill
                                      ..color = KidsTheme.purple,
                                    shadows: const [
                                      Shadow(color: Colors.white, offset: Offset(1.5, 1.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ⭐ 별코인 카운터
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
                                        style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // 🪄 힌트 요술봉 버튼
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return GestureDetector(
                                  onTap: () => _useHint(constraints),
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
                                );
                              }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2개 분할 그림 캔버스 영역 (Top: 원본, Bottom: 틀린 그림 터치 영역)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Column(
                      children: [
                        // 상단 원본 그림
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildSceneCanvas(_baseScene, isInteractive: false, isTop: true),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('원본 그림 🖼️', style: GoogleFonts.jua(fontSize: 13, color: KidsTheme.textDark)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // 하단 틀린 그림 터치 영역
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildSceneCanvas(_bottomScene, isInteractive: true, isTop: false),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9F43),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('틀린곳 3개 찾기! 🔍', style: GoogleFonts.jua(fontSize: 13, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Round Transition Overlay
          if (_showRoundOverlay)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Round $_nextRoundForOverlay',
                      style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다음 라운드 시작! 🚀',
                      style: GoogleFonts.jua(
                        fontSize: 32,
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Confetti
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ctrl.forward();
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
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFF4757), width: 4),
          color: const Color(0xFFFF4757).withValues(alpha: 0.2),
          boxShadow: const [BoxShadow(color: Color(0xFFFF4757), blurRadius: 10)],
        ),
        child: const Center(
          child: Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 36),
        ),
      ),
    );
  }
}

class _WrongMark extends StatelessWidget {
  const _WrongMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent, width: 3),
        color: Colors.redAccent.withValues(alpha: 0.25),
      ),
      child: const Center(
        child: Icon(Icons.close_rounded, color: Colors.redAccent, size: 36),
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
            fontSize: 48,
            color: Colors.yellowAccent,
            shadows: [
              const Shadow(color: Colors.deepOrange, offset: Offset(3, 3), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
