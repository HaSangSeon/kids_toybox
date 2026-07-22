import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

enum BalloonType {
  normal,
  fast,
  bomb,
  freeze,
  spiky,
}

class Balloon {
  final int id;
  final double startX;
  double y; 
  final Color color;
  final double size;
  final double speed;
  final double swayAmount;
  final double swaySpeed;
  double timeAlive = 0;
  bool isPopped = false;
  final BalloonType type;
  
  double get currentX => startX + sin(timeAlive * swaySpeed) * swayAmount;

  Balloon({
    required this.id,
    required this.startX,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.swayAmount,
    required this.swaySpeed,
    required this.type,
  });
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double life = 1.0;
  final double decay;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.decay,
  });
}

class FloatingText {
  double x;
  double y;
  String text;
  double life = 1.0;
  final double decay = 0.02;

  FloatingText({
    required this.x,
    required this.y,
    required this.text,
  });
}

class GameEngine extends ChangeNotifier {
  final List<Balloon> balloons = [];
  final List<Particle> particles = [];
  final List<FloatingText> floatingTexts = [];
  
  int stage = 1;
  int stageScore = 0;
  int totalScore = 0;
  int lives = 3; // Heart count: 3 Lives
  bool isStageCleared = false;
  bool isGameOver = false;

  bool isCountingDown = false;
  int countdown = 3;
  double countdownTimer = 3.0;

  int idCounter = 0;
  DateTime lastSpawnTime = DateTime.now();
  final Random random = Random();

  final List<Color> balloonColors = [
    KidsTheme.red, KidsTheme.orange, KidsTheme.yellow, 
    KidsTheme.green, KidsTheme.blue, KidsTheme.purple, KidsTheme.pink,
  ];

  double freezeTimer = 0.0;
  double timeCounter = 0.0;

  int get targetScore {
    if (stage == 1) return 100;
    if (stage == 2) return 150;
    if (stage == 3) return 200;
    if (stage == 4) return 250;
    return 300;
  }

  void loseLife() {
    if (isGameOver || isStageCleared) return;
    lives--;
    AudioManager.instance.playDamage();
    HapticFeedback.vibrate(); // Heavy vibration on health loss!
    
    if (lives <= 0) {
      isGameOver = true;
      AudioManager.instance.playGameOver();
      _saveHighScore();
    }
    notifyListeners();
  }

  void _saveHighScore() {
    if (totalScore == 0) return; // Don't save zero scores

    final box = Hive.box('high_scores_box');
    final List<dynamic> rawList = box.get('scores_list', defaultValue: []) as List<dynamic>;
    
    // Map to mutable maps
    final List<Map<String, dynamic>> list = rawList.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();

    // Add current entry
    list.add({
      'score': totalScore,
      'stage': stage,
      'date': DateTime.now().toIso8601String(),
    });

    // Sort descending by score
    list.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    // Keep top 5
    if (list.length > 5) {
      list.removeRange(5, list.length);
    }

    box.put('scores_list', list);
  }

  List<Map<String, dynamic>> getHighScores() {
    final box = Hive.box('high_scores_box');
    final List<dynamic> rawList = box.get('scores_list', defaultValue: []) as List<dynamic>;
    return rawList.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  void update(double dt) {
    bool dirty = false;
    timeCounter += dt;

    // Update Particles
    for (var p in particles) {
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.001; // Gravity
      p.life -= p.decay;
      dirty = true;
    }
    particles.removeWhere((p) => p.life <= 0);

    // Update Floating Texts
    for (var t in floatingTexts) {
      t.y -= 0.003;
      t.life -= t.decay;
      dirty = true;
    }
    floatingTexts.removeWhere((t) => t.life <= 0);

    if (isStageCleared || isGameOver) {
      if (dirty) notifyListeners();
      return;
    }

    if (isCountingDown) {
      countdownTimer -= dt;
      int currentCount = countdownTimer.ceil();
      if (currentCount != countdown) {
        countdown = currentCount;
        if (countdown > 0) {
          // Play a classic countdown tick (pitch shifted click!)
          AudioManager.instance.playEffect('audio/click.wav', rate: 1.55);
        } else {
          // Play clean high start beep (pitch shifted click!)
          AudioManager.instance.playEffect('audio/click.wav', rate: 2.0);
        }
        dirty = true;
      }
      if (countdownTimer <= 0) {
        isCountingDown = false;
        lastSpawnTime = DateTime.now();
        dirty = true;
      }
      if (dirty) notifyListeners();
      return;
    }

    // Update Freeze Timer
    if (freezeTimer > 0) {
      freezeTimer -= dt;
      if (freezeTimer < 0) freezeTimer = 0;
      dirty = true;
    }

    // Update Balloons
    final speedFactor = freezeTimer > 0 ? 0.25 : 1.0;
    for (var balloon in balloons) {
      if (!balloon.isPopped) {
        balloon.y -= balloon.speed * speedFactor; 
        balloon.timeAlive += dt;
        dirty = true;
      }
    }
    int initialBalloons = balloons.length;
    balloons.removeWhere((b) {
      if (b.y < -0.15 && !b.isPopped) {
        // Lose life ONLY if normal or fast balloon escapes
        if (b.type == BalloonType.normal || b.type == BalloonType.fast) {
          loseLife();
        }
        return true;
      }
      return b.isPopped;
    });
    if (initialBalloons != balloons.length) dirty = true;

    // Dynamic Spawner Interval and Max Balloons based on current stage
    final int spawnIntervalMs = max(180, 1500 - (stage - 1) * 350);
    final int maxBalloons = min(45, 5 + (stage - 1) * 8);

    if (DateTime.now().difference(lastSpawnTime).inMilliseconds > spawnIntervalMs) {
      if (balloons.length < maxBalloons) {
        _spawnBalloon();
      }
      lastSpawnTime = DateTime.now();
      dirty = true;
    }

    if (dirty) {
      notifyListeners();
    }
  }

  void _spawnBalloon() {
    final double rand = random.nextDouble();
    BalloonType type = BalloonType.normal;
    // Stage 1 has fewer special balloons
    final double bombChance = stage == 1 ? 0.05 : 0.09;
    final double freezeChance = stage == 1 ? 0.05 : 0.08;
    final double spikyChance = stage == 1 ? 0.04 : 0.09;
    final double fastChance = min(0.30, 0.12 + (stage - 1) * 0.03);

    if (rand < fastChance) {
      type = BalloonType.fast;
    } else if (rand < fastChance + bombChance) {
      type = BalloonType.bomb;
    } else if (rand < fastChance + bombChance + freezeChance) {
      type = BalloonType.freeze;
    } else if (rand < fastChance + bombChance + freezeChance + spikyChance) {
      type = BalloonType.spiky;
    }

    // Difficulty metrics grow based on current stage
    final double speedScale = 1.0 + (stage - 1) * 0.18;
    final double baseSpeed = (random.nextDouble() * 0.0012 + 0.0012) * speedScale;

    final double sizeScale = max(0.6, 1.0 - (stage - 1) * 0.05);
    final double baseSize = (random.nextDouble() * 30 + 65) * sizeScale;

    double finalSize = baseSize;
    double finalSpeed = baseSpeed;
    Color color = balloonColors[random.nextInt(balloonColors.length)];

    if (type == BalloonType.fast) {
      finalSize = baseSize * 0.85;
      finalSpeed = baseSpeed * 2.2;
      color = const Color(0xFFFFD54F); // Golden
    } else if (type == BalloonType.bomb) {
      finalSize = baseSize * 1.15;
      color = const Color(0xFFFF5252); // Red bomb
    } else if (type == BalloonType.freeze) {
      finalSize = baseSize * 0.95;
      color = const Color(0xFF40C4FF); // Blue freeze
    } else if (type == BalloonType.spiky) {
      finalSize = baseSize * 1.0;
      color = const Color(0xFF7C4DFF); // Purple Spiky
    }

    balloons.add(
      Balloon(
        id: idCounter++,
        startX: random.nextDouble() * 0.8 + 0.1, 
        y: 1.2, 
        color: color,
        size: finalSize, 
        speed: finalSpeed, 
        swayAmount: random.nextDouble() * 0.08 + 0.04, 
        swaySpeed: random.nextDouble() * 1.8 + 0.8,
        type: type,
      ),
    );
  }

  void popBalloon(Balloon balloon) {
    if (balloon.isPopped || isStageCleared || isGameOver) return;
    
    balloon.isPopped = true;
    HapticFeedback.lightImpact();

    int points = 0;
    Color particleColor = balloon.color;
    String floatText = "";

    switch (balloon.type) {
      case BalloonType.normal:
        AudioManager.instance.playPop();
        points = 10;
        floatText = "+10";
        break;
      case BalloonType.fast:
        AudioManager.instance.playLightningPop();
        points = 20;
        floatText = "+20 ⚡";
        particleColor = const Color(0xFFFFD54F);
        break;
      case BalloonType.bomb:
        AudioManager.instance.playCrash(); // Bomb explosion sound
        points = 15;
        floatText = "폭탄 💣";
        particleColor = const Color(0xFFFF9100);
        
        // Circular chain explosion (popping balloons within 0.25 coordinate radius)
        final bx = balloon.currentX;
        final by = balloon.y;
        final toPop = <Balloon>[];
        for (var other in balloons) {
          if (other == balloon || other.isPopped) continue;
          final dx = other.currentX - bx;
          final dy = other.y - by;
          final dist = sqrt(dx*dx + dy*dy);
          if (dist < 0.25) {
            toPop.add(other);
          }
        }
        for (var b in toPop) {
          popBalloon(b);
        }
        break;
      case BalloonType.freeze:
        AudioManager.instance.playBoing(); // freeze sound
        points = 10;
        floatText = "빙결 ❄️";
        particleColor = const Color(0xFF80DEEA);
        freezeTimer = 4.5;
        break;
      case BalloonType.spiky:
        loseLife();
        points = 0;
        floatText = "아야! 💥";
        particleColor = const Color(0xFFE040FB);
        break;
    }

    stageScore += points;
    totalScore += points;
    
    // Spawn particles
    final particleCount = balloon.type == BalloonType.bomb ? 35 : 20;
    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(
        x: balloon.currentX,
        y: balloon.y,
        vx: (random.nextDouble() - 0.5) * 0.04, 
        vy: (random.nextDouble() - 0.5) * 0.04 - (balloon.type == BalloonType.bomb ? 0.02 : 0.01), 
        color: particleColor,
        size: random.nextDouble() * 8 + 4,
        decay: random.nextDouble() * 0.02 + 0.02,
      ));
    }

    if (floatText.isNotEmpty) {
      floatingTexts.add(FloatingText(
        x: balloon.currentX,
        y: balloon.y,
        text: floatText,
      ));
    }
    
    // Check Stage Clear condition
    if (stageScore >= targetScore) {
      isStageCleared = true;
      AudioManager.instance.playSuccess();
      HapticFeedback.heavyImpact();
    }
    
    notifyListeners();
  }

  void nextStage() {
    stage++;
    stageScore = 0;
    isStageCleared = false;
    isCountingDown = false;
    countdown = 3;
    countdownTimer = 3.0;
    freezeTimer = 0.0;
    balloons.clear();
    particles.clear();
    floatingTexts.clear();
    lastSpawnTime = DateTime.now();
    notifyListeners();
  }

  void reset() {
    stage = 1;
    stageScore = 0;
    totalScore = 0;
    lives = 3;
    isStageCleared = false;
    isGameOver = false;
    isCountingDown = false;
    countdown = 3;
    countdownTimer = 3.0;
    freezeTimer = 0.0;
    balloons.clear();
    particles.clear();
    floatingTexts.clear();
    notifyListeners();
  }
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                    Container(
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
                              AudioManager.instance.playEffect('audio/click.wav');
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
                          
                          // Central Info (Stage & Score)
                          Expanded(
                            child: ListenableBuilder(
                              listenable: _engine,
                              builder: (context, child) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_engine.stage}단계 🎈',
                                      style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
                                    ),
                                    Text(
                                      '목표: ${_engine.stageScore} / ${_engine.targetScore} (누적: ${_engine.totalScore}점)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KidsTheme.orange),
                                    ),
                                  ],
                                );
                              }
                            ),
                          ),
                          
                          // Hearts
                          ListenableBuilder(
                            listenable: _engine,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (index) {
                                  final isHeartActive = index < _engine.lives;
                                  return Icon(
                                    Icons.favorite,
                                    color: isHeartActive ? KidsTheme.red : Colors.grey.shade300,
                                    size: 24,
                                  );
                                }),
                              );
                            }
                          ),
                          const SizedBox(width: 12),
                          
                          // Refresh Button
                          GestureDetector(
                            onTap: () {
                              AudioManager.instance.playEffect('audio/click.wav');
                              _engine.reset();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: KidsTheme.green.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh, color: KidsTheme.green, size: 28),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
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
                                    color: KidsTheme.borderDark.withOpacity(0.5),
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

            // Stage Clear Bouncy Overlay
            ListenableBuilder(
              listenable: _engine,
              builder: (context, child) {
                if (!_engine.isStageCleared) return const SizedBox.shrink();

                return Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.55),
                    child: Center(
                      child: ScaleTransition(
                        scale: _clearScaleAnimation,
                        child: Container(
                          width: 300,
                          padding: const EdgeInsets.all(28),
                          decoration: KidsTheme.toyDecoration(
                            color: Colors.white,
                            borderRadius: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '참 잘했어요! 👍',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: KidsTheme.pink,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${_engine.stage}단계 통과! 🎉',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: KidsTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '누적 점수: ${_engine.totalScore} 점 🏆',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: KidsTheme.orange,
                                ),
                              ),
                              const SizedBox(height: 24),
                              GestureDetector(
                                onTap: () {
                                  AudioManager.instance.playEffect('audio/click.wav');
                                  HapticFeedback.mediumImpact();
                                  _engine.nextStage();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: KidsTheme.toyDecoration(
                                    color: KidsTheme.green,
                                    borderRadius: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '다음 단계로! (${_engine.stage + 1}단계) 🚀',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
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
                          width: 320,
                          padding: const EdgeInsets.all(32),
                          decoration: KidsTheme.toyDecoration(
                            color: Colors.white,
                            borderRadius: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '풍선이 도망갔어요! 😢',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KidsTheme.textLight),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '게임 종료 🎈',
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: KidsTheme.red),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9C4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '도달한 단계: ${_engine.stage}단계',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KidsTheme.orange),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '내가 모은 점수: ${_engine.totalScore} 점',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: KidsTheme.textDark),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playEffect('audio/click.wav');
                                        HapticFeedback.mediumImpact();
                                        Navigator.of(context).pop();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: KidsTheme.toyDecoration(color: KidsTheme.red, borderRadius: 20),
                                        child: const Center(
                                          child: Text('그만하기 🏠', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        AudioManager.instance.playEffect('audio/click.wav');
                                        HapticFeedback.mediumImpact();
                                        _engine.reset();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        decoration: KidsTheme.toyDecoration(color: KidsTheme.green, borderRadius: 20),
                                        child: const Center(
                                          child: Text('다시하기 🔄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
                );
              }
            ),

          ],
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final GameEngine engine;

  _GamePainter({required this.engine}) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);

    // Draw Balloons
    for (var balloon in engine.balloons) {
      if (balloon.isPopped) continue;
      final centerX = balloon.currentX * size.width;
      final centerY = balloon.y * size.height;
      _drawBalloon(canvas, centerX, centerY, balloon.size, balloon.color, balloon.type);
    }

    // Draw Freeze Overlay if frozen
    if (engine.freezeTimer > 0) {
      final freezePaint = Paint()
        ..color = const Color(0x3340C4FF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, freezePaint);

      // Draw thin frosty frame
      final framePaint = Paint()
        ..color = const Color(0x8080DEEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      canvas.drawRect(Offset.zero & size, framePaint);
      
      // Draw snowflake indicator at the top
      final textSpan = TextSpan(
        text: '❄️ 시간 천천히! (${engine.freezeTimer.toStringAsFixed(1)}초)',
        style: GoogleFonts.jua(fontSize: 20, color: Colors.blue.shade800),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 210));
    }

    // Draw Particles
    for (var p in engine.particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), p.size / 2, paint);
    }

    // Draw Floating Texts
    for (var t in engine.floatingTexts) {
      final tx = t.x * size.width;
      final ty = t.y * size.height;
      
      final textSpan = TextSpan(
        text: t.text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: KidsTheme.orange.withValues(alpha: t.life.clamp(0.0, 1.0)),
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: t.life.clamp(0.0, 1.0)), blurRadius: 4, offset: const Offset(0, 0)),
            Shadow(color: Colors.white.withValues(alpha: t.life.clamp(0.0, 1.0)), blurRadius: 4, offset: const Offset(1, 1)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(tx - (textPainter.width / 2), ty - (textPainter.height / 2)));
    }
  }

  void _drawBalloon(Canvas canvas, double cx, double cy, double bSize, Color color, BalloonType type) {
    final width = bSize;
    final height = bSize * 1.3;
    final top = cy - height / 2;
    final left = cx - width / 2;

    final paint = Paint()..color = color..style = PaintingStyle.fill;
    
    // Borders based on type
    Color borderColor = KidsTheme.borderDark;
    double borderWidth = 3;
    if (type == BalloonType.fast) {
      borderColor = const Color(0xFFFFA000);
      borderWidth = 5;
    } else if (type == BalloonType.bomb) {
      borderColor = const Color(0xFFD50000);
      borderWidth = 4.5;
    } else if (type == BalloonType.freeze) {
      borderColor = const Color(0xFF00B0FF);
      borderWidth = 4;
    } else if (type == BalloonType.spiky) {
      borderColor = const Color(0xFF4A148C);
      borderWidth = 4;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.5)..style = PaintingStyle.fill;

    // Glowing auras
    if (type == BalloonType.fast) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9;
      canvas.drawOval(Rect.fromLTWH(left - 2, top - 2, width + 4, (width * 1.1) + 4), glowPaint);
    } else if (type == BalloonType.bomb) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF5252).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawOval(Rect.fromLTWH(left - 1, top - 1, width + 2, (width * 1.1) + 2), glowPaint);
    } else if (type == BalloonType.freeze) {
      final glowPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawOval(Rect.fromLTWH(left - 1, top - 1, width + 2, (width * 1.1) + 2), glowPaint);
    }

    final rect = Rect.fromLTWH(left, top, width, width * 1.1);
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, borderPaint);

    final highlightRect = Rect.fromLTWH(left + width * 0.2, top + width * 0.15, width * 0.25, width * 0.35);
    canvas.drawOval(highlightRect, highlightPaint);

    // Knot
    final path = Path();
    final knotY = top + width * 1.1;
    final knotWidth = width * 0.15;
    path.moveTo(cx, knotY);
    path.lineTo(cx - knotWidth, knotY + width * 0.1);
    path.lineTo(cx + knotWidth, knotY + width * 0.1);
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    // String
    final stringPaint = Paint()..color = KidsTheme.borderDark..style = PaintingStyle.stroke..strokeWidth = 2;
    final stringPath = Path();
    stringPath.moveTo(cx, knotY + width * 0.1);
    stringPath.cubicTo(cx - 10, knotY + width * 0.3, cx + 10, knotY + width * 0.5, cx, cy + height / 2);
    canvas.drawPath(stringPath, stringPaint);

    // Draw indicators inside balloon
    if (type == BalloonType.fast) {
      final lightningPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      final lp = Path();
      final double lx = cx;
      final double ly = cy - 3;
      lp.moveTo(lx + 2, ly - 12);
      lp.lineTo(lx - 8, ly + 2);
      lp.lineTo(lx - 2, ly + 2);
      lp.lineTo(lx - 4, ly + 12);
      lp.lineTo(lx + 8, ly - 2);
      lp.lineTo(lx + 2, ly - 2);
      lp.close();
      canvas.drawPath(lp, lightningPaint);
      canvas.drawPath(lp, Paint()..color = const Color(0xFFFFA000)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    } else if (type == BalloonType.bomb) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '💣', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    } else if (type == BalloonType.freeze) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '❄️', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    } else if (type == BalloonType.spiky) {
      final textPainter = TextPainter(
        text: const TextSpan(text: '💀', style: TextStyle(fontSize: 22)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // Engine dictates repaint

  void _drawBackground(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Rainbow
    final rainbowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final colors = [
      const Color(0xFFFF8A80),
      const Color(0xFFFFD180),
      const Color(0xFFFFFF8D),
      const Color(0xFFA7FFEB),
      const Color(0xFF80D8FF),
      const Color(0xFFEA80FC),
    ];
    final center = Offset(w * 0.5, h * 0.6);
    for (int i = 0; i < colors.length; i++) {
      final r = w * 0.45 - i * 8;
      if (r > 0) {
        rainbowPaint.color = colors[i].withValues(alpha: 0.15);
        canvas.drawArc(
          Rect.fromCenter(center: center, width: r * 2, height: r * 1.1),
          pi,
          pi,
          false,
          rainbowPaint,
        );
      }
    }

    // 2. Smiling Sun ☀️
    final double sunScale = 1.0 + sin(engine.timeCounter * 1.5) * 0.05;
    final double sunX = w * 0.85;
    final double sunY = 160;
    
    // Draw sun rays/glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 45 * sunScale, glowPaint);

    final sunPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 30 * sunScale, sunPaint);
    
    // Sun smiley face (eye, eye, smile)
    final facePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX - 8 * sunScale, sunY - 5 * sunScale), 3, facePaint);
    canvas.drawCircle(Offset(sunX + 8 * sunScale, sunY - 5 * sunScale), 3, facePaint);
    
    final smilePaint = Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(sunX, sunY + 3 * sunScale), width: 14 * sunScale, height: 10 * sunScale),
      0,
      pi,
      false,
      smilePaint,
    );

    // 3. Clouds moving horizontally
    _drawCloud(canvas, Offset((w * 0.15 + engine.timeCounter * 10) % (w + 160) - 80, 240), 1.0);
    _drawCloud(canvas, Offset((w * 0.65 + engine.timeCounter * 6) % (w + 180) - 90, 310), 0.85);

    // 4. Flying Birds
    final double bird1X = (w * 0.9 - engine.timeCounter * 22) % (w + 80) - 40;
    final double bird1Y = 220 + sin(engine.timeCounter * 2.5) * 12;
    canvas.save();
    canvas.translate(bird1X, bird1Y);
    canvas.scale(1.0, 0.70 + sin(engine.timeCounter * 16) * 0.30); // 쫀득한 날개짓 물리
    _drawText(canvas, '🕊️', Offset.zero, 26);
    canvas.restore();

    final double bird2X = (w * 0.3 - engine.timeCounter * 16) % (w + 80) - 40;
    final double bird2Y = 280 + cos(engine.timeCounter * 1.8) * 10;
    canvas.save();
    canvas.translate(bird2X, bird2Y);
    canvas.scale(1.0, 0.70 + cos(engine.timeCounter * 12) * 0.30);
    _drawText(canvas, '🕊️', Offset.zero, 20);
    canvas.restore();

    // 5. Cute Green Grass at the Bottom
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
      ).createShader(Rect.fromLTRB(0, h * 0.88, w, h));
    final grassPath = Path()
      ..moveTo(0, h * 0.90)
      ..quadraticBezierTo(w * 0.25, h * 0.87, w * 0.5, h * 0.89)
      ..quadraticBezierTo(w * 0.75, h * 0.91, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(grassPath, grassPaint);
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    final double r = 24 * scale;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(Offset(center.dx - r * 0.7, center.dy + r * 0.2), r * 0.75, paint);
    canvas.drawCircle(Offset(center.dx + r * 0.7, center.dy + r * 0.2), r * 0.75, paint);
    canvas.drawCircle(Offset(center.dx - r * 1.2, center.dy + r * 0.4), r * 0.5, paint);
    canvas.drawCircle(Offset(center.dx + r * 1.2, center.dy + r * 0.4), r * 0.5, paint);
    // flat bottom
    canvas.drawRect(
      Rect.fromLTRB(center.dx - r * 1.2, center.dy + r * 0.1, center.dx + r * 1.2, center.dy + r * 0.9),
      paint,
    );
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2));
  }
}
