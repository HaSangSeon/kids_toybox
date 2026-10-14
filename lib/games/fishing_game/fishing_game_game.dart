import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';


part 'models/fishing_models.dart';
part 'painters/fishing_painters.dart';
part 'widgets/segmented_fish_widget.dart';
part 'widgets/live_aquarium_tank_view.dart';
part 'widgets/fishing_stage_widgets.dart';
part 'widgets/fishing_modals.dart';

// ════════════════════════════════════════════
class FishingGame extends StatefulWidget {
  final String hookEmoji;
  const FishingGame({super.key, this.hookEmoji = '🪝'});

  @override
  State<FishingGame> createState() => _FishingGameState();
}

class _FishingGameState extends State<FishingGame> with TickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // 애니메이션 컨트롤러
  late AnimationController _boatBobController;   // 배 상하 흔들림
  late AnimationController _cloudDriftController; // 구름 이동
  late Animation<double> _boatBobAnim;
  late Animation<double> _cloudDriftAnim;

  // 게임 제어
  bool _isPlaying = false;
  bool _showZoneSelect = false;
  bool _showAquariumModal = false;
  FishSpecies? _celebrationFish;

  // 시바 선장 리액션 제어
  bool _isShibaCelebrating = false;
  Timer? _shibaCelebrationTimer;

  // 잡은 물고기 및 도감 기록
  final Set<String> _caughtSpeciesIds = {};
  final List<FishSpecies> _caughtSpeciesList = [];
  int _totalFishCaught = 0;

  int _stage = 1; // 1=햇살, 2=황혼, 3=심해

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Size _screenSize = Size.zero;

  // 낚시배 & 낚싯바늘
  double _boatX = 0.0;
  double _hookX = 0.0;
  double _targetHookX = 0.0;
  double _hookY = 120.0;
  bool _isHookDropping = false;
  bool _isHookReturning = false;
  bool _playedWaterSplash = false;
  FishInstance? _caughtItem;

  // 게임 오브젝트들
  final List<FishInstance> _fishes = [];
  final List<SplashParticle> _particles = [];
  final List<BaitParticle> _baitParticles = [];
  final List<ScorePopup> _popups = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

    // 배 상하 흔들림 (2.8초 주기)
    _boatBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _boatBobAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _boatBobController, curve: Curves.easeInOut),
    );

    // 구름 이동 (20초 주기)
    _cloudDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudDriftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_cloudDriftController);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shibaCelebrationTimer?.cancel();
    _boatBobController.dispose();
    _cloudDriftController.dispose();
    super.dispose();
  }

  void _startGame(Size size) {
    _screenSize = size;
    _boatX = _screenSize.width / 2;
    _hookX = _screenSize.width / 2;
    _targetHookX = _screenSize.width / 2;
    _hookY = _screenSize.height > 0 ? _screenSize.height * 0.28 - 15 : 120.0;
    _isHookDropping = false;
    _isHookReturning = false;
    _caughtItem = null;
    _fishes.clear();
    _particles.clear();
    _baitParticles.clear();
    _popups.clear();
    _isPlaying = true;

    // 초기 물고기 떼 생성
    for (int i = 0; i < 8; i++) {
      _spawnFish(initial: true);
    }

    if (!_ticker.isTicking) {
      _ticker.start();
    }
    setState(() {});
  }

  void _changeZone(int newZone) {
    AudioManager.instance.playFishCatch();
    setState(() {
      _stage = newZone;
      _fishes.clear();
      _particles.clear();
      _baitParticles.clear();
      _popups.clear();
    });
    for (int i = 0; i < 8; i++) {
      _spawnFish(initial: true);
    }
  }

  // ── 물고기 스폰 ──
  void _spawnFish({bool initial = false}) {
    if (_screenSize == Size.zero) return;

    final waterTop = _screenSize.height * 0.28;
    final waterBottom = _screenSize.height - 80;
    final waterHeight = waterBottom - waterTop;

    final y = _random.nextDouble() * (waterHeight - 60) + waterTop + 30;
    final ratio = (y - waterTop) / waterHeight;

    OceanZone zone;
    if (ratio < 0.35) {
      zone = OceanZone.sunlight;
    } else if (ratio < 0.7) {
      zone = OceanZone.twilight;
    } else {
      zone = OceanZone.abyssal;
    }

    final isTrash = _random.nextDouble() < 0.10 + (_stage - 1) * 0.05;
    final isShark = !isTrash && _random.nextDouble() < 0.08 + (_stage - 1) * 0.05;

    FishInstance item;
    final id = '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}';

    if (isTrash) {
      final trash = _trashList[_random.nextInt(_trashList.length)];
      final speed = (_random.nextDouble() * 40 + 20) * (_random.nextBool() ? 1 : -1);
      final x = speed > 0 ? -60.0 : _screenSize.width + 60.0;
      item = FishInstance(
        id: id,
        emoji: trash['emoji']!,
        name: trash['name']!,
        x: x,
        y: y,
        speed: speed,
        isGood: false,
        scale: 0.9,
      );
    } else if (isShark) {
      final speed = (_random.nextDouble() * 40 + 50) * (_random.nextBool() ? 1 : -1);
      final x = speed > 0 ? -120.0 : _screenSize.width + 120.0;
      item = FishInstance(
        id: id,
        emoji: '🦈',
        name: '멋진 상어',
        x: x,
        y: y,
        speed: speed,
        isGood: false,
        scale: 1.5,
      );
    } else {
      final allCandidates = _speciesList.where((element) => element.zone == zone).toList();
      final rareCandidates = allCandidates.where((e) => e.isRare).toList();
      final normalCandidates = allCandidates.where((e) => !e.isRare).toList();

      final spawnRare = _random.nextDouble() < 0.08 && rareCandidates.isNotEmpty;
      final candidates = spawnRare ? rareCandidates : normalCandidates;

      final species = candidates[_random.nextInt(candidates.length)];
      final speedMult = species.isRare ? 0.65 : 1.0;
      final speed = (species.baseSpeed * speedMult + _random.nextDouble() * 20) * (_random.nextBool() ? 1 : -1);
      final x = speed > 0 ? -80.0 : _screenSize.width + 80.0;
      item = FishInstance(
        id: id,
        species: species,
        emoji: species.emoji,
        name: species.name,
        x: x,
        y: y,
        speed: speed,
        isGood: true,
        scale: species.isRare ? 1.8 : (species.points > 30 ? 1.3 : 1.0),
      );
    }

    if (initial) {
      item.x = _random.nextDouble() * _screenSize.width;
    }

    _fishes.add(item);
  }

  // ── 물보라 파티클 생성 ──
  void _createSplash(double cx, double cy, int count, Color color) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = _random.nextDouble() * 140 + 40;
      _particles.add(SplashParticle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 50,
        color: color,
      ));
    }
  }

  // ── 미끼 뿌리기 액션 ──
  void _throwBait() {
    if (!_isPlaying) return;
    AudioManager.instance.playPaintDrop();
    HapticFeedback.mediumImpact();

    final spawnX = _hookX;
    final spawnY = _screenSize.height * 0.28;

    for (int i = 0; i < 4; i++) {
      _baitParticles.add(BaitParticle(
        x: (spawnX + (_random.nextDouble() * 50 - 25)).clamp(30.0, _screenSize.width - 30.0),
        y: spawnY + _random.nextDouble() * 15,
        vy: 45.0 + _random.nextDouble() * 30,
        life: 1.0,
      ));
    }

    _createSplash(spawnX, spawnY, 8, Colors.amber.shade200);

    _popups.add(ScorePopup(
      x: spawnX,
      y: spawnY + 20,
      text: '🍞 맛있는 미끼 퐁당! ✨',
      color: Colors.amberAccent.shade400,
    ));

    setState(() {});
  }

  // ── Ticker 루프 ──
  void _onTick(Duration elapsed) {
    if (!_isPlaying || _screenSize == Size.zero) return;

    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    if (dt > 0.1) return;

    setState(() {
      _boatX = _screenSize.width / 2;
      _hookX += (_targetHookX - _hookX) * 0.25;

      // 미끼 물리 및 물고기 유인
      for (var bait in _baitParticles) {
        bait.y += bait.vy * dt;
        bait.life -= dt * 0.18; // 서서히 소멸
      }
      _baitParticles.removeWhere((b) => b.life <= 0 || b.y > _screenSize.height - 70);

      // 물고기 스폰 및 유영
      if (_fishes.length < 9 && _random.nextDouble() < 0.03) {
        _spawnFish();
      }

      for (var fish in _fishes) {
        if (!fish.isCaught) {
          // 미끼가 물속에 있을 때 가까운 물고기가 미끼 방향으로 이끌림
          if (fish.isGood && _baitParticles.isNotEmpty) {
            for (var bait in _baitParticles) {
              final dist = (bait.x - fish.x).abs() + (bait.y - fish.renderY).abs();
              if (dist < 180) {
                fish.attractionTimer = 2.0;
                final dir = bait.x > fish.x ? 1.0 : -1.0;
                fish.speed += dir * 90.0 * dt;
                fish.speed = fish.speed.clamp(-140.0, 140.0);

                // 미끼를 먹었을 때
                if ((fish.x - bait.x).abs() < 24 && (fish.renderY - bait.y).abs() < 24) {
                  bait.life = 0;
                  AudioManager.instance.playFishBite();
                  _createSplash(bait.x, bait.y, 6, Colors.amberAccent);
                  _popups.add(ScorePopup(
                    x: fish.x,
                    y: fish.renderY - 15,
                    text: '냠! 😋',
                    color: Colors.amberAccent,
                  ));
                }
                break;
              }
            }
          }

          if (fish.attractionTimer > 0) {
            fish.attractionTimer -= dt;
          }

          fish.x += fish.speed * (0.75 + 0.25 * fish.zDepth) * dt;
          fish.swimTimer += dt * (fish.speed.abs() / 28.0 + 1.8);

          // 물고기 입에서 뽀글뽀글 거품 발생 효과
          if (fish.isGood && fish.swimTimer - fish.lastBubbleTime > 2.5 + _random.nextDouble() * 2) {
            fish.lastBubbleTime = fish.swimTimer;
            _particles.add(SplashParticle(
              x: fish.x + (fish.speed > 0 ? 20 : -20),
              y: fish.renderY,
              vx: (fish.speed > 0 ? -20 : 20) + (_random.nextDouble() * 10 - 5),
              vy: -25 - _random.nextDouble() * 20,
              color: Colors.white.withValues(alpha: 0.65),
              life: 1.2,
            ));
          }
        } else {
          // 낚인 물고기는 바늘을 따라 감아올려짐
          fish.x = _hookX;
          fish.y = _hookY + 15;
          fish.swimTimer += dt * 8.0;
        }
      }

      // 화면 이탈 물고기 정리
      _fishes.removeWhere((f) => !f.isCaught && (f.x < -160 || f.x > _screenSize.width + 160));

      // 낚싯바늘 물리
      if (_isHookDropping) {
        _hookY += 480 * dt;
        final waterSurfaceY = _screenSize.height * 0.28;
        if (!_playedWaterSplash && _hookY >= waterSurfaceY) {
          _playedWaterSplash = true;
          AudioManager.instance.playFishPlunge();
        }

        if (_hookY > _screenSize.height - 80) {
          _isHookDropping = false;
          _isHookReturning = true;
        } else if (_caughtItem == null) {
          final hookRect = Rect.fromCenter(center: Offset(_hookX, _hookY), width: 25, height: 25);
          for (var fish in _fishes) {
            if (!fish.isCaught && fish.rect.overlaps(hookRect)) {
              fish.isCaught = true;
              _caughtItem = fish;
              _isHookDropping = false;
              _isHookReturning = true;
              HapticFeedback.vibrate();
              AudioManager.instance.playFishBite();
              break;
            }
          }
        }
      } else if (_isHookReturning) {
        final reelSpeed = _caughtItem != null ? 240.0 : 420.0;
        _hookY -= reelSpeed * dt;

        final restY = _screenSize.height * 0.28 - 15;
        if (_hookY <= restY) {
          _hookY = restY;
          _isHookReturning = false;

          if (_caughtItem != null) {
            final double splashY = _screenSize.height * 0.28;
            _createSplash(_hookX, splashY, 15, Colors.white);
            _handleCatch(_caughtItem!);
            _fishes.remove(_caughtItem);
            _caughtItem = null;
          }
        }
      }

      // 파티클 업데이트
      for (var p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 220 * dt;
        p.life -= dt * 1.5;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // 팝업 업데이트
      for (var p in _popups) {
        p.y -= 45 * dt;
        p.life -= dt * 1.5;
      }
      _popups.removeWhere((p) => p.life <= 0);
    });
  }

  // ── 물고기 획득 처리 ──
  void _handleCatch(FishInstance item) {
    if (item.isGood) {
      final species = item.species!;
      final isNewSpecies = !_caughtSpeciesIds.contains(species.id);

      _caughtSpeciesIds.add(species.id);
      _caughtSpeciesList.add(species);
      _totalFishCaught++;

      // 시바 선장 환호 세레머니 트리거
      _triggerShibaCelebration();

      if (species.isRare || isNewSpecies || species.points >= 50) {
        AudioManager.instance.playMagicUnfoldSuccess();
        HapticFeedback.heavyImpact();
        // 대물 / 신종 물고기 축하 팝업 모달
        setState(() {
          _celebrationFish = species;
        });
      } else {
        AudioManager.instance.playFishCatch();
        HapticFeedback.mediumImpact();
      }

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: species.isRare ? '✨ ${species.name} 낚았다! ✨' : '${species.name} 낚았다! 🎣',
        color: species.isRare ? Colors.pinkAccent : Colors.amberAccent.shade700,
      ));
    } else {
      AudioManager.instance.playFishOhNo();
      HapticFeedback.heavyImpact();

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: '아이쿠! ${item.name}! 💦',
        color: KidsTheme.red,
      ));
    }
  }

  void _triggerShibaCelebration() {
    _shibaCelebrationTimer?.cancel();
    setState(() {
      _isShibaCelebrating = true;
    });
    _shibaCelebrationTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _isShibaCelebrating = false;
        });
      }
    });
  }

  // ── 터치 제어 ──
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPlaying) return;
    setState(() {
      _targetHookX = (_targetHookX + details.delta.dx).clamp(30.0, _screenSize.width - 30.0);
    });
  }

  // ── 바늘 투하 버튼 ──
  void _dropHook() {
    if (!_isPlaying || _isHookDropping || _isHookReturning) return;
    AudioManager.instance.playFishReel();
    setState(() {
      _isHookDropping = true;
      _playedWaterSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_screenSize.width != constraints.maxWidth) {
              final isFirstLoad = _screenSize == Size.zero;
              _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
              _boatX = _screenSize.width / 2;
              _hookX = _screenSize.width / 2;
              _targetHookX = _screenSize.width / 2;

              if (isFirstLoad) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_isPlaying) {
                    _startGame(_screenSize);
                  }
                });
              }
            }

            return Stack(
              children: [
                // ── 바다 3단계 레이어 배경 ──
                Positioned.fill(child: IgnorePointer(child: _buildOceanBackground())),

                // ── 물고기 떼 ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: (() {
                        final sortedFishes = List<FishInstance>.from(_fishes)
                          ..sort((a, b) => a.zDepth.compareTo(b.zDepth));

                        return sortedFishes.map((fish) {
                          final facingLeft = fish.speed < 0;
                          final effectiveScale = fish.scale * fish.zDepth;

                          final breathScaleX = 1.0 + 0.04 * sin(fish.swimTimer * 2.5);
                          final breathScaleY = 1.0 - 0.03 * sin(fish.swimTimer * 2.5);
                          final totalRotation = fish.tiltAngle + fish.swayAngle;

                          final shadowOffset = Offset(
                            facingLeft ? -5.0 * fish.zDepth : 5.0 * fish.zDepth,
                            6.0 * fish.zDepth,
                          );
                          final opacity = (fish.zDepth * 0.75 + 0.25).clamp(0.5, 1.0);

                          return Positioned(
                            left: fish.x - (30 * effectiveScale),
                            top: fish.renderY - (20 * effectiveScale),
                            child: Opacity(
                              opacity: opacity,
                              child: Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..rotateZ(facingLeft ? totalRotation : -totalRotation)
                                  ..multiply(Matrix4.diagonal3Values(
                                    facingLeft ? effectiveScale * breathScaleX : -effectiveScale * breathScaleX,
                                    effectiveScale * breathScaleY,
                                    1.0,
                                  )),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 수중 그림자
                                    Transform.translate(
                                      offset: shadowOffset,
                                      child: _SegmentedWigglingFish(
                                        emoji: fish.emoji,
                                        fontSize: 38,
                                        swimTimer: fish.swimTimer,
                                        isLarge: fish.scale >= 1.4,
                                        textColor: Colors.black.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    // 물고기 본체
                                    _SegmentedWigglingFish(
                                      emoji: fish.emoji,
                                      fontSize: 38,
                                      swimTimer: fish.swimTimer,
                                      isLarge: fish.scale >= 1.4,
                                    ),
                                    // 미끼 유인 하트 버블
                                    if (fish.attractionTimer > 0)
                                      Positioned(
                                        top: -16,
                                        left: 12,
                                        child: Text(
                                          '💖',
                                          style: TextStyle(
                                            fontSize: 14 + sin(fish.swimTimer * 8) * 3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList();
                      }()),
                    ),
                  ),
                ),

                // ── 바다 속 가라앉는 미끼(식빵 조각)들 ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _baitParticles.map((b) => Positioned(
                        left: b.x - 10,
                        top: b.y - 10,
                        child: Opacity(
                          opacity: b.life.clamp(0.0, 1.0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber.shade700, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amberAccent.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🍞', style: TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),

                // ── 낚싯배 & 시바 선장 & 낚싯줄 / 낚싯바늘 ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Builder(
                      builder: (context) {
                        final boatY = _screenSize.height * 0.28 - 45 + _boatBobAnim.value;
                        final boatRodTip = Offset(_boatX + 42, boatY + 12);
                        final hookPos = Offset(_hookX, _hookY);

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ── 멋진 원목 낚시선 & 시바 선장 ──
                            Positioned(
                              left: _boatX - 55,
                              top: boatY - 15,
                              child: _buildFishingBoat(boatY),
                            ),

                            // ── 낚싯줄 ──
                            Positioned.fill(
                              child: CustomPaint(
                                painter: FishingLinePainter(
                                  start: boatRodTip,
                                  end: hookPos,
                                ),
                              ),
                            ),

                            // ── 낚싯바늘 🪝 ──
                            Positioned(
                              left: _hookX - 14,
                              top: _hookY - 14,
                              child: Transform.rotate(
                                angle: _caughtItem != null ? 0.2 : 0,
                                child: Text(widget.hookEmoji, style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // ── 터치 드래그 및 수면 터치 영역 ──
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTapDown: (_) => _dropHook(),
                    onPanUpdate: _onPanUpdate,
                    behavior: HitTestBehavior.translucent,
                  ),
                ),

                // ── 파티클 및 팝업 ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        ..._particles.map((p) => Positioned(
                          left: p.x - 3,
                          top: p.y - 3,
                          child: Opacity(
                            opacity: p.life.clamp(0.0, 1.0),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                            ),
                          ),
                        )),
                        ..._popups.map((p) => Positioned(
                          left: p.x - 120,
                          width: 240,
                          top: p.y,
                          child: Opacity(
                            opacity: p.life.clamp(0.0, 1.0),
                            child: Center(
                              child: Text(
                                p.text,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jua(
                                  fontSize: 20,
                                  color: p.color,
                                  shadows: const [Shadow(color: Colors.white, blurRadius: 8)],
                                ),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                // ── 상단 헤더 대시보드 ──
                Positioned(
                  top: 10,
                  left: 12,
                  right: 12,
                  child: _buildHeaderCard(),
                ),

                // ── 하단 플로팅 미끼 뿌리기 버튼 ──
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: _buildBaitButton(),
                ),

                // ── 구역 이동 오버레이 ──
                if (_showZoneSelect) _buildZoneSelectOverlay(),

                // ── 내 수족관 & 물고기 도감 모달 ──
                if (_showAquariumModal) _buildAquariumModal(),

                // ── 대물 / 신종 물고기 축하 카드 모달 ──
                if (_celebrationFish != null) _buildCelebrationModal(),
              ],
            );
          },
        ),
      ),
    );
  }
}
