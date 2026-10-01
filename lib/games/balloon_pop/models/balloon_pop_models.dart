part of '../balloon_pop_game.dart';

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
    if (stage == 1) return 200;
    if (stage == 2) return 350;
    if (stage == 3) return 550;
    if (stage == 4) return 800;
    if (stage == 5) return 1200;
    return 1200 + (stage - 5) * 400;
  }

  void loseLife() {
    // Endless mode: No game over!
    lives = 3;
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
      p.vy += 0.003; // Gravity (increased for punchier pop feel)
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

  int comboCount = 0;
  DateTime? lastPopTime;

  void popBalloon(Balloon balloon) {
    if (balloon.isPopped || isStageCleared || isGameOver) return;
    
    balloon.isPopped = true;
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    if (lastPopTime != null && now.difference(lastPopTime!).inMilliseconds < 900) {
      comboCount++;
    } else {
      comboCount = 1;
    }
    lastPopTime = now;

    int points = 0;
    Color particleColor = balloon.color;
    String floatText = "";

    switch (balloon.type) {
      case BalloonType.normal:
        AudioManager.instance.playPop();
        points = comboCount >= 5 ? 15 : 10;
        floatText = comboCount >= 5 ? "+15 🔥 FEVER!" : (comboCount >= 2 ? "+10 ⚡x$comboCount" : "+10");
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
        AudioManager.instance.playBoing();
        points = 15;
        floatText = "반짝! 🌟";
        particleColor = const Color(0xFFFFD700);
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
      // AudioManager.instance.playSuccess(); // 사운드가 너무 시끄럽다는 피드백으로 제거
      HapticFeedback.heavyImpact();
      _saveHighScore();
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

  void setStage(int newStage) {
    stage = newStage.clamp(1, 5);
    stageScore = 0;
    isStageCleared = false;
    isGameOver = false;
    isCountingDown = true;
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
    stageScore = 0;
    totalScore = 0;
    lives = 3;
    isStageCleared = false;
    isGameOver = false;
    isCountingDown = true;
    countdown = 3;
    countdownTimer = 3.0;
    freezeTimer = 0.0;
    balloons.clear();
    particles.clear();
    floatingTexts.clear();
    notifyListeners();
  }
}

