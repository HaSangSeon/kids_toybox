import 'dart:math';
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
  final List<int> _foundDifferenceIds = [];
  final List<Map<String, dynamic>> _wrongTaps = [];
  bool _isGameOver = false;
  bool _isTransitioning = false; // 중복 터치 및 라운드 이행 상태 보호

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
    [const Color(0xFFE0F7FA), const Color(0xFFB2EBF2)], // 공원
    [const Color(0xFF311B92), const Color(0xFF4A148C)], // 우주
    [const Color(0xFFE0F7FA), const Color(0xFF80DEEA)], // 바다
    [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)], // 사막
    [const Color(0xFFF1F8E9), const Color(0xFFDCEDC8)], // 농장
  ];

  final List<Color> _groundColors = [
    const Color(0xFFAED581),
    const Color(0xFF7E57C2),
    const Color(0xFFFFE082),
    const Color(0xFFFFCC80),
    const Color(0xFF9CCC65),
  ];

  // Combo System
  DateTime? _lastTapTime;
  String? _comboMessage;

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
      _isTransitioning = false;
      _foundDifferenceIds.clear();
      _wrongTaps.clear();
      _lastTapTime = null;
      _comboMessage = null;

      final int themeIdx = (_currentRound - 1 + _random.nextInt(_themes.length)) % _themes.length;
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

  // 🎯 틀린 곳 터치 판정 (실시간 애니메이션 위치 오프셋 완벽 반영 & 상단/하단 100% 터치 지원!)
  void _onCanvasTap(double relX, double relY, Size containerSize) {
    if (_isGameOver || _isTransitioning) return;

    int? foundDiffId;
    for (int diffId in _differenceIds) {
      if (_foundDifferenceIds.contains(diffId)) continue;
      final element = _baseScene.firstWhere((e) => e.id == diffId);

      // ☁️ 🐟 🦋 등 동적 애니메이션 이동거리(dx) 정밀 보정!
      double ambientDx = 0.0;
      if (["☁️", "🐟", "🐠", "🐬", "🦋"].contains(element.emoji)) {
        ambientDx = ((_ambientCtrl.value - 0.5) * 20.0) / (containerSize.width > 0 ? containerSize.width : 300.0);
      }

      final actualX = element.x + ambientDx;
      final dx = actualX - relX;
      final dy = element.y - relY;
      final distSq = dx * dx + dy * dy;

      // 넉넉하고 아이 친화적인 정답 터치 반경 (distSq < 0.025)
      if (distSq < 0.025) {
        foundDiffId = diffId;
        break;
      }
    }

    if (foundDiffId != null) {
      // 정답!
      AudioManager.instance.playCardMatch();
      HapticFeedback.mediumImpact();

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
      });

      // 3개 틀린 그림 모두 발견 시 레벨 이행
      if (_foundDifferenceIds.length >= _differenceIds.length) {
        _isTransitioning = true; // 중복 입력 방지 락

        if (_currentRound < _totalRounds) {
          AudioManager.instance.playLevelComplete();
          // 1.5초간 축하 링 감상 후 다음 라운드로 안전 이행
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (!mounted) return;
            _showRoundTransition(_currentRound + 1);
          });
        } else {
          // 3개 라운드 모두 최종 클리어!
          setState(() => _isGameOver = true);
          AudioManager.instance.playSuccess();
          PlayerDataManager.instance.addStarCoin(2);
          _confettiController.play();
          
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _showVictoryDialog();
          });
        }
      }
    } else {
      // ❌ 오답
      AudioManager.instance.playCardMismatch();
      HapticFeedback.lightImpact();

      final wrongTap = {'x': relX, 'y': relY};
      setState(() {
        _wrongTaps.add(wrongTap);
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
                '3개 라운드를 모두 맞췄어요! (+2 별코인 획득)',
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
                    '다음 라운드 도전! 🚀',
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
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isInteractive ? (details) {
            final relX = details.localPosition.dx / constraints.maxWidth;
            final relY = details.localPosition.dy / constraints.maxHeight;
            _onCanvasTap(relX, relY, containerSize);
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
                }),

                // 정답 동그라미 뱃지
                ..._foundDifferenceIds.map((diffId) {
                  final element = _baseScene.firstWhere((e) => e.id == diffId);
                  return Positioned(
                    left: element.x * constraints.maxWidth - 36,
                    top: element.y * constraints.maxHeight - 36,
                    child: const _CorrectMark(),
                  );
                }),

                // 오답 ❌ 표시
                if (isInteractive) ..._wrongTaps.map((wt) {
                  return Positioned(
                    left: (wt['x'] as double) * constraints.maxWidth - 28,
                    top: (wt['y'] as double) * constraints.maxHeight - 28,
                    child: const _WrongMark(),
                  );
                }),
                
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
                // 3D 글래스 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
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
                        
                        // 🎨 메인 타이틀 & 레벨 뱃지 (1단계, 2단계...)
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '틀린그림 찾기 🔍',
                                  style: GoogleFonts.jua(
                                    fontSize: 18,
                                    color: KidsTheme.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                  ),
                                  child: Text(
                                    '$_currentRound단계',
                                    style: GoogleFonts.jua(fontSize: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 44), // 대칭 우측 여백
                      ],
                    ),
                  ),
                ),

                // 2개 분할 그림 캔버스 영역 (Top: 원본, Bottom: 틀린 그림 둘 다 100% 터치 가능!)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Column(
                      children: [
                        // 상단 원본 그림 (터치 가능!)
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildSceneCanvas(_baseScene, isInteractive: true, isTop: true),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
                                  ),
                                  child: Text('원본 그림 🖼️', style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF512DA8))),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 하단 비교 그림 (터치 가능!)
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
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFF9800), width: 1.5),
                                  ),
                                  child: Text('틀린곳 찾기 🔍 (${_foundDifferenceIds.length}/3)', style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFE65100))),
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

          // 라운드 전환 애니메이션 오버레이
          if (_showRoundOverlay)
            Container(
              color: Colors.black54,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, val, child) {
                    return Transform.scale(
                      scale: val,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎯 🚀', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 8),
                            Text(
                              '$_nextRoundForOverlay단계 시작! 🎯',
                              style: GoogleFonts.jua(fontSize: 24, color: KidsTheme.purple),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 폭죽 컨페티
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 25,
            ),
          ),
        ],
      ),
    );
  }
}

// 정답 마크 애니메이션
class _CorrectMark extends StatefulWidget {
  const _CorrectMark();

  @override
  State<_CorrectMark> createState() => _CorrectMarkState();
}

class _CorrectMarkState extends State<_CorrectMark> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
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
      scale: _scale,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.amber.shade300.withValues(alpha: 0.25),
              Colors.orange.shade400.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(color: const Color(0xFFFFB300), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade700.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.stars_rounded, color: Color(0xFFFF8F00), size: 46),
        ),
      ),
    );
  }
}

// 오답 마크 애니메이션
class _WrongMark extends StatefulWidget {
  const _WrongMark();

  @override
  State<_WrongMark> createState() => _WrongMarkState();
}

class _WrongMarkState extends State<_WrongMark> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
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
      scale: _scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: const Center(
          child: Text('❌', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}

class _ComboText extends StatelessWidget {
  final String message;
  const _ComboText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade400,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Text(
        message,
        style: GoogleFonts.jua(fontSize: 22, color: Colors.brown.shade900),
      ),
    );
  }
}
