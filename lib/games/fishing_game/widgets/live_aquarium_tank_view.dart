part of '../fishing_game_game.dart';

// ════════════════════════════════════════════
// ── 인터랙티브 살아있는 수족관 위젯 ──
// ════════════════════════════════════════════
class _LiveAquariumTankView extends StatefulWidget {
  final List<FishSpecies> fishes;
  const _LiveAquariumTankView({required this.fishes});

  @override
  State<_LiveAquariumTankView> createState() => _LiveAquariumTankViewState();
}

class _SimFish {
  final FishSpecies species;
  double x;
  double y;
  double vx;
  double vy;
  double swimTimer;
  _SimFish({
    required this.species,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    this.swimTimer = 0.0,
  });
}

class _TankFood {
  double x;
  double y;
  double vy = 45.0;
  double life = 1.0;
  _TankFood({required this.x, required this.y});
}

class _LiveAquariumTankViewState extends State<_LiveAquariumTankView> with SingleTickerProviderStateMixin {
  late Ticker _tankTicker;
  Duration _lastTick = Duration.zero;

  final List<_SimFish> _simFishes = [];
  final List<_TankFood> _tankFoods = [];
  final List<ScorePopup> _tankPopups = [];
  final Random _random = Random();
  Size _tankSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _tankTicker = createTicker(_onTankTick);
  }

  void _initSimFishes() {
    _simFishes.clear();
    // 최대 16마리까지 수족관에 유영
    final displayFishes = widget.fishes.take(16).toList();
    for (var sp in displayFishes) {
      final vx = (_random.nextDouble() * 40 + 30) * (_random.nextBool() ? 1 : -1);
      final vy = (_random.nextDouble() * 20 - 10);
      _simFishes.add(_SimFish(
        species: sp,
        x: _random.nextDouble() * (_tankSize.width - 60) + 30,
        y: _random.nextDouble() * (_tankSize.height - 100) + 40,
        vx: vx,
        vy: vy,
        swimTimer: _random.nextDouble() * 10,
      ));
    }
  }

  void _onTankTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (dt > 0.1 || _tankSize == Size.zero) return;

    setState(() {
      // 먹이 낙하
      for (var food in _tankFoods) {
        food.y += food.vy * dt;
        food.life -= dt * 0.15;
      }
      _tankFoods.removeWhere((f) => f.life <= 0 || f.y > _tankSize.height - 40);

      // 물고기 유영 및 먹이 먹기
      for (var fish in _simFishes) {
        fish.swimTimer += dt * 3.0;

        // 먹이가 있으면 가장 가까운 먹이를 향해 유영
        if (_tankFoods.isNotEmpty) {
          final target = _tankFoods.first;
          final dx = target.x - fish.x;
          final dy = target.y - fish.y;
          fish.vx += (dx > 0 ? 80 : -80) * dt;
          fish.vy += (dy > 0 ? 50 : -50) * dt;

          if (dx.abs() < 24 && dy.abs() < 24) {
            target.life = 0;
            AudioManager.instance.playFishBite();
            _tankPopups.add(ScorePopup(
              x: fish.x,
              y: fish.y - 15,
              text: '냠! 💖',
              color: Colors.pinkAccent,
            ));
          }
        }

        fish.vx = fish.vx.clamp(-80.0, 80.0);
        fish.vy = fish.vy.clamp(-40.0, 40.0);

        fish.x += fish.vx * dt;
        fish.y += fish.vy * dt;

        // 벽 반사
        if (fish.x < 30) {
          fish.x = 30;
          fish.vx = fish.vx.abs();
        } else if (fish.x > _tankSize.width - 30) {
          fish.x = _tankSize.width - 30;
          fish.vx = -fish.vx.abs();
        }

        if (fish.y < 30) {
          fish.y = 30;
          fish.vy = fish.vy.abs();
        } else if (fish.y > _tankSize.height - 50) {
          fish.y = _tankSize.height - 50;
          fish.vy = -fish.vy.abs();
        }
      }

      // 팝업 업데이트
      for (var p in _tankPopups) {
        p.y -= 30 * dt;
        p.life -= dt * 1.5;
      }
      _tankPopups.removeWhere((p) => p.life <= 0);
    });
  }

  void _dropTankFood(Offset pos) {
    AudioManager.instance.playPaintDrop();
    HapticFeedback.lightImpact();
    setState(() {
      _tankFoods.add(_TankFood(x: pos.dx, y: pos.dy));
    });
  }

  @override
  void dispose() {
    _tankTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fishes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎣', style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              Text(
                '아직 잡은 물고기가 없어요!\n바다에서 물고기를 낚아보세요!',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(fontSize: 18, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_tankSize != Size(constraints.maxWidth, constraints.maxHeight)) {
          _tankSize = Size(constraints.maxWidth, constraints.maxHeight);
          _initSimFishes();
          if (!_tankTicker.isTicking) {
            _tankTicker.start();
          }
        }

        return GestureDetector(
          onTapDown: (details) => _dropTankFood(details.localPosition),
          child: Stack(
            children: [
              // 수족관 물 그래디언트 배경
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF0097A7)],
                  ),
                ),
              ),

              // 수족관 바닥 모래 & 산호 장식
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 45,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE0B2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text('🪸', style: TextStyle(fontSize: 22)),
                      Text('🌿', style: TextStyle(fontSize: 24)),
                      Text('🐚', style: TextStyle(fontSize: 18)),
                      Text('🪸', style: TextStyle(fontSize: 22)),
                      Text('🌿', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),

              // 상단 안내 배너
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      '👆 수족관을 터치해서 맛있는 밥(🍤)을 줘보세요!',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.cyan.shade900),
                    ),
                  ),
                ),
              ),

              // 먹이 아이콘들
              ..._tankFoods.map((f) => Positioned(
                left: f.x - 10,
                top: f.y - 10,
                child: Opacity(
                  opacity: f.life.clamp(0.0, 1.0),
                  child: const Text('🍤', style: TextStyle(fontSize: 18)),
                ),
              )),

              // 유영하는 물고기들
              ..._simFishes.map((f) {
                final facingLeft = f.vx < 0;
                return Positioned(
                  left: f.x - 22,
                  top: f.y - 18,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(facingLeft ? 1.0 : -1.0, 1.0, 1.0),
                    child: Text(f.species.emoji, style: const TextStyle(fontSize: 34)),
                  ),
                );
              }),

              // 냠냠 팝업
              ..._tankPopups.map((p) => Positioned(
                left: p.x - 30,
                top: p.y,
                child: Opacity(
                  opacity: p.life.clamp(0.0, 1.0),
                  child: Text(
                    p.text,
                    style: GoogleFonts.jua(
                      fontSize: 16,
                      color: p.color,
                      shadows: const [Shadow(color: Colors.white, blurRadius: 4)],
                    ),
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
