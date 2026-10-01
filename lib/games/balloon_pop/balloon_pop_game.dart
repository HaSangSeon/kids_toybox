import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
part 'models/balloon_pop_models.dart';
part 'painters/balloon_pop_painters.dart';

class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame> with TickerProviderStateMixin {
  late GameEngine _engine;
  late Ticker _ticker;
  
  late AnimationController _clearController;
  late Animation<double> _clearScaleAnimation;
  
  late AnimationController _gameOverController;
  late Animation<double> _gameOverScaleAnimation;

  bool _wasCleared = false;
  bool _wasGameOver = false;
  bool _showStageSelect = true; // Open stage selection on game start!
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _engine.addListener(_onEngineChanged);
    _ticker = createTicker(_onTick)..start();

    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _clearScaleAnimation = CurvedAnimation(
      parent: _clearController,
      curve: Curves.elasticOut,
    );

    _gameOverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _gameOverScaleAnimation = CurvedAnimation(
      parent: _gameOverController,
      curve: Curves.elasticOut,
    );
  }

  void _onEngineChanged() {
    if (_engine.isStageCleared && !_wasCleared) {
      _wasCleared = true;
      _clearController.forward(from: 0.0);
    } else if (!_engine.isStageCleared && _wasCleared) {
      _wasCleared = false;
      _clearController.reverse();
    }

    if (_engine.isGameOver && !_wasGameOver) {
      _wasGameOver = true;
      _gameOverController.forward(from: 0.0);
    } else if (!_engine.isGameOver && _wasGameOver) {
      _wasGameOver = false;
      _gameOverController.reverse();
    }
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final double dt = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
    _lastElapsed = elapsed;
    _engine.update(dt.clamp(0.0, 0.05));
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineChanged);
    _clearController.dispose();
    _gameOverController.dispose();
    _ticker.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _handleTap(TapDownDetails details, Size size) {
    if (_engine.isStageCleared || _engine.isGameOver) return;

    final tapX = details.localPosition.dx / size.width;
    final tapY = details.localPosition.dy / size.height;

    // Check hit backward so top balloons are popped first
    for (int i = _engine.balloons.length - 1; i >= 0; i--) {
      final balloon = _engine.balloons[i];
      if (balloon.isPopped) continue;

      final bX = balloon.currentX;
      final bY = balloon.y;
      final radiusX = (balloon.size / 2) / size.width;
      final radiusY = ((balloon.size * 1.3) / 2) / size.height;

      // Simple bounding box hit detection
      if ((tapX - bX).abs() < radiusX && (tapY - bY).abs() < radiusY) {
        _engine.popBalloon(balloon);
        break; // Only pop one balloon per tap
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7FA), Color(0xFFFFF9C4)],
          ),
        ),
        child: Stack(
          children: [
            // Game Area using CustomPaint for blazing fast rendering
            LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _handleTap(details, Size(constraints.maxWidth, constraints.maxHeight)),
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: _GamePainter(engine: _engine),
                  ),
                );
              },
            ),


            // Premium Unified Header Panel & Progress Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3 Distinct Floating Header Cards
                    Row(
                      children: [
                        // Left: Back Button Card
                        GestureDetector(
                          onTap: () {
                            AudioManager.instance.playEffect('audio/click.wav');
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: KidsTheme.textDark, size: 24),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Center: Stage Select Pill Card
                        Expanded(
                          child: ListenableBuilder(
                            listenable: _engine,
                            builder: (context, child) {
                              return GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playClick();
                                  setState(() {
                                    _showStageSelect = true;
                                  });
                                },
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.10),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${_engine.stage}단계 🎈',
                                        style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_drop_down_circle_rounded, size: 18, color: Color(0xFFFF9F1C)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Hearts & Refresh Combined Pill Card
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListenableBuilder(
                                listenable: _engine,
                                builder: (context, child) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite, color: KidsTheme.red, size: 18),
                                      const SizedBox(width: 3),
                                      Text(
                                        '무한 팡팡',
                                        style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.textDark),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playEffect('audio/click.wav');
                                  _engine.reset();
                                },
                                child: const Icon(Icons.refresh_rounded, color: KidsTheme.green, size: 24),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    ListenableBuilder(
                      listenable: _engine,
                      builder: (context, child) {
                        final progress = (_engine.stageScore / _engine.targetScore).clamp(0.0, 1.0);
                        return Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: KidsTheme.borderDark, width: 2.5),
                          ),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),

            // Countdown Overlay
            ListenableBuilder(
              listenable: _engine,
              builder: (context, child) {
                if (!_engine.isCountingDown) return const SizedBox.shrink();

                String displayText = _engine.countdown > 0 ? '${_engine.countdown}' : '시작! 🎈';
                Color displayColor = _engine.countdown > 0 ? KidsTheme.orange : KidsTheme.green;

                return Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_engine.countdown),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 550),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: Curves.elasticOut.transform(value) * 1.8,
                            child: Text(
                              displayText,
                              style: TextStyle(
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                color: displayColor,
                                shadows: [
                                  Shadow(
                                    color: KidsTheme.borderDark.withValues(alpha: 0.5),
                                    offset: const Offset(3, 3),
                                    blurRadius: 2,
                                  ),
                                  const Shadow(
                                    color: Colors.white,
                                    offset: Offset(-2, -2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            ),

            // Stage Clear Bouncy Overlay (Clean 3D Popup with Home & Next Stage buttons)
            ListenableBuilder(
              listenable: _engine,
              builder: (context, child) {
                if (!_engine.isStageCleared) return const SizedBox.shrink();

                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: ScaleTransition(
                        scale: _clearScaleAnimation,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 600),
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉 🎈 🏆', style: TextStyle(fontSize: 42)),
                              const SizedBox(height: 10),
                              Text(
                                '참 잘했어요!',
                                style: GoogleFonts.jua(
                                  fontSize: 26,
                                  color: KidsTheme.purple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_engine.stage}단계 미션 성공!',
                                style: GoogleFonts.jua(
                                  fontSize: 20,
                                  color: const Color(0xFF10AC84),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Score Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('누적 점수: ', style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark)),
                                        Text('${_engine.totalScore} 점', style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFFFF6B6B))),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('⭐ 별코인 +1 획득!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Action Buttons: [🏠 메인으로] [🚀 다음 단계]
                              Row(
                                children: [
                                  // 🏠 메인으로
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.mediumImpact();
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        height: 52,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFF6B6B), Color(0xFFEE5253)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                          ],
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '메인으로',
                                                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 🚀 다음 단계로
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.mediumImpact();
                                        _engine.nextStage();
                                      },
                                      child: Container(
                                        height: 52,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                          ],
                                        ),
                                        child: Center(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  '🚀 ${_engine.stage + 1}단계로',
                                                  style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
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
                  ),
                );
              },
            ),

            // Game Over Bouncy Overlay
            ListenableBuilder(
              listenable: _engine,
              builder: (context, child) {
                if (!_engine.isGameOver) return const SizedBox.shrink();

                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: ScaleTransition(
                        scale: _gameOverScaleAnimation,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 320, maxHeight: 600),
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: const Color(0xFFFF6B6B), width: 3),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎈 😢 💥', style: TextStyle(fontSize: 42)),
                              const SizedBox(height: 10),
                              Text(
                                '풍선이 도망갔어요!',
                                style: GoogleFonts.jua(fontSize: 24, color: const Color(0xFFFF4757)),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9C4),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '도달한 단계: ${_engine.stage}단계',
                                      style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '최종 점수: ${_engine.totalScore} 점',
                                      style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFFFF6B6B)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  // 🏠 메인으로
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.mediumImpact();
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF576574), Color(0xFF222F3E)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                          ],
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                                              const SizedBox(width: 4),
                                              Text(
                                                '메인으로',
                                                style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 🔄 다시하기
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playClick();
                                        HapticFeedback.mediumImpact();
                                        _engine.reset();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF1DD1A1), Color(0xFF10AC84)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            '다시하기 🔄',
                                            style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                                          ),
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
                  ),
                );
              },
            ),

            // Stage Select Modal Overlay
            if (_showStageSelect) _buildStageSelectOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Stage Select Overlay (깔끔하고 아기자기한 5단계 통일 디자인) ─────────────
  Widget _buildStageSelectOverlay() {
    final stagesInfo = [
      (
        stage: 1,
        title: '아기 풍선',
        scoreText: '목표 200점',
        icon: '🎈',
        cardBg: const Color(0xFFFFF0F2),
        borderColor: const Color(0xFFFFCDD2),
        badgeColor: const Color(0xFFFF5252),
      ),
      (
        stage: 2,
        title: '황금별 풍선',
        scoreText: '목표 350점',
        icon: '⭐',
        cardBg: const Color(0xFFFFFDE7),
        borderColor: const Color(0xFFFFF59D),
        badgeColor: const Color(0xFFFBC02D),
      ),
      (
        stage: 3,
        title: '바람 슝슝',
        scoreText: '목표 550점',
        icon: '🍃',
        cardBg: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFFA5D6A7),
        badgeColor: const Color(0xFF4CAF50),
      ),
      (
        stage: 4,
        title: '폭탄 조심!',
        scoreText: '목표 800점',
        icon: '💣',
        cardBg: const Color(0xFFFCE4EC),
        borderColor: const Color(0xFFF8BBD0),
        badgeColor: const Color(0xFFE91E63),
      ),
      (
        stage: 5,
        title: '팡팡 챔피언',
        scoreText: '목표 1,200점',
        icon: '👑',
        cardBg: const Color(0xFFEDE7F6),
        borderColor: const Color(0xFFD1C4E9),
        badgeColor: const Color(0xFF7E57C2),
      ),
    ];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFFFD54F), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Cute Gradient Header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(29),
                        topRight: Radius.circular(29),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🎈', style: TextStyle(fontSize: 36)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '어디까지 날아볼까요?',
                                style: GoogleFonts.jua(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '단계를 골라보세요! ✨',
                                style: GoogleFonts.jua(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AudioManager.instance.playClick();
                            setState(() {
                              _showStageSelect = false;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 24, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Stage Cards ──
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: stagesInfo.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final info = stagesInfo[index];
                        final bool isCurrent = _engine.stage == info.stage;

                        return GestureDetector(
                          onTap: () {
                            AudioManager.instance.playClick();
                            _engine.setStage(info.stage);
                            setState(() {
                              _showStageSelect = false;
                            });
                          },
                          child: Container(
                            height: 78,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: info.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCurrent ? info.badgeColor : info.borderColor,
                                width: isCurrent ? 2.5 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: info.badgeColor.withValues(alpha: isCurrent ? 0.22 : 0.08),
                                  blurRadius: isCurrent ? 10 : 4,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Big Round Icon
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: info.badgeColor.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: info.badgeColor.withValues(alpha: 0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(info.icon, style: const TextStyle(fontSize: 30)),
                                ),
                                const SizedBox(width: 14),

                                // Stage Name & Score
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${info.stage}단계 • ${info.title}',
                                        style: GoogleFonts.jua(
                                          fontSize: 18,
                                          color: const Color(0xFF263238),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        info.scoreText,
                                        style: GoogleFonts.jua(
                                          fontSize: 13,
                                          color: const Color(0xFF78909C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Big Play / Selected Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? info.badgeColor : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isCurrent ? null : Border.all(color: info.borderColor, width: 1.5),
                                    boxShadow: isCurrent ? [
                                      BoxShadow(
                                        color: info.badgeColor.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: Text(
                                    isCurrent ? '선택됨 ✨' : '시작 ▶',
                                    style: GoogleFonts.jua(
                                      fontSize: 14,
                                      color: isCurrent ? Colors.white : const Color(0xFF546E7A),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
      ),
    );
  }
}

