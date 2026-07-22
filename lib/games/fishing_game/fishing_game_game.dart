import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

// ── 바다 깊이 구역 (Zone) ──
enum OceanZone {
  sunlight('햇살 가득 구역 ☀️', [Color(0xFFE0F7FA), Color(0xFF4FC3F7)]),
  twilight('푸른 황혼 구역 🌊', [Color(0xFF0288D1), Color(0xFF01579B)]),
  abyssal('신비한 심해 구역 🌌', [Color(0xFF0D47A1), Color(0xFF000A21)]);

  final String name;
  final List<Color> colors;
  const OceanZone(this.name, this.colors);
}

// ── 물고기 어종 정의 ──
class FishSpecies {
  final String id;
  final String emoji;
  final String name;
  final OceanZone zone;
  final int points;
  final double baseSpeed;

  const FishSpecies({
    required this.id,
    required this.emoji,
    required this.name,
    required this.zone,
    required this.points,
    required this.baseSpeed,
  });
}

const List<FishSpecies> _speciesList = [
  // 1구역 (햇살)
  FishSpecies(id: 'clown', emoji: '🐠', name: '니모(흰동가리)', zone: OceanZone.sunlight, points: 10, baseSpeed: 90.0),
  FishSpecies(id: 'tang', emoji: '🐟', name: '도리(블루탱)', zone: OceanZone.sunlight, points: 10, baseSpeed: 100.0),
  FishSpecies(id: 'star', emoji: '⭐', name: '알록달록 불가사리', zone: OceanZone.sunlight, points: 15, baseSpeed: 40.0),
  FishSpecies(id: 'puffer', emoji: '🐡', name: '가시 복어', zone: OceanZone.sunlight, points: 15, baseSpeed: 60.0),
  // 2구역 (황혼)
  FishSpecies(id: 'turtle', emoji: '🐢', name: '느긋한 바다거북', zone: OceanZone.twilight, points: 20, baseSpeed: 50.0),
  FishSpecies(id: 'squid', emoji: '🦑', name: '하늘하늘 오징어', zone: OceanZone.twilight, points: 20, baseSpeed: 110.0),
  FishSpecies(id: 'crab', emoji: '🦀', name: '옆으로 꽃게', zone: OceanZone.twilight, points: 20, baseSpeed: 70.0),
  FishSpecies(id: 'shrimp', emoji: '🦐', name: '아기 새우', zone: OceanZone.twilight, points: 25, baseSpeed: 130.0),
  // 3구역 (심해)
  FishSpecies(id: 'jelly', emoji: '🪼', name: '야광 해파리', zone: OceanZone.abyssal, points: 30, baseSpeed: 80.0),
  FishSpecies(id: 'octopus', emoji: '🐙', name: '재주꾼 문어', zone: OceanZone.abyssal, points: 30, baseSpeed: 90.0),
  FishSpecies(id: 'dolphin', emoji: '🐬', name: '분홍 돌고래', zone: OceanZone.abyssal, points: 50, baseSpeed: 160.0),
  FishSpecies(id: 'whale', emoji: '🐳', name: '아기 고래', zone: OceanZone.abyssal, points: 50, baseSpeed: 120.0),
];

// ── 쓰레기/장애물 종류 ──
const _trashList = [
  {'emoji': '🪨', 'name': '바위'},
  {'emoji': '👟', 'name': '낡은 장화'},
  {'emoji': '🥫', 'name': '빈 캔'},
];

// ── 생물 인스턴스 ──
class FishInstance {
  final String id;
  final FishSpecies? species; // null 이면 방해물/상어/쓰레기
  final String emoji;
  final String name;
  double x;
  double y;
  double speed;
  final bool isGood;
  bool isCaught;
  final double scale;

  // 3D 입체 수영 및 헤엄치기 물리 속성
  final double zDepth; // 0.65 (깊은 배경) ~ 1.35 (전경)
  double swimTimer;
  final double swimPhase;
  double lastBubbleTime;

  FishInstance({
    required this.id,
    this.species,
    required this.emoji,
    required this.name,
    required this.x,
    required this.y,
    required this.speed,
    required this.isGood,
    this.isCaught = false,
    this.scale = 1.0,
    double? zDepth,
    double? swimPhase,
  }) : zDepth = zDepth ?? (0.65 + Random().nextDouble() * 0.7),
       swimPhase = swimPhase ?? (Random().nextDouble() * pi * 2),
       swimTimer = Random().nextDouble() * 10,
       lastBubbleTime = 0;

  double get renderY => y + (isCaught ? 0 : sin(swimPhase + swimTimer * 3.5) * 8.0);

  Rect get rect => Rect.fromCenter(
    center: Offset(x, renderY),
    width: 55 * scale * zDepth,
    height: 40 * scale * zDepth,
  );
}

// ── 물보라 파티클 ──
class SplashParticle {
  double x, y, vx, vy, life;
  final Color color;
  SplashParticle({required this.x, required this.y, required this.vx, required this.vy, required this.color, this.life = 1.0});
}

// ── 점수 팝업 ──
class ScorePopup {
  double x, y, life;
  final String text;
  final Color color;
  ScorePopup({required this.x, required this.y, required this.text, required this.color, this.life = 1.0});
}

// ════════════════════════════════════════════
class FishingGame extends StatefulWidget {
  final String hookEmoji;
  const FishingGame({super.key, this.hookEmoji = '🎣'});

  @override
  State<FishingGame> createState() => _FishingGameState();
}

class _FishingGameState extends State<FishingGame> with TickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  // 애니메이션 컨트롤러
  late AnimationController _boatBobController;   // 배 상하 흔들림
  late AnimationController _cloudDriftController; // 구름 들리기
  late Animation<double> _boatBobAnim;
  late Animation<double> _cloudDriftAnim;

  // 게임 제어
  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isStageClear = false;
  bool _showCatalog = false;

  int _score = 0;
  int _lives = 3;
  int _stage = 1;          // 1=햇살, 2=황혼, 3=심해
  int _catchCount = 0;     // 이번 스테이지에서 낚은 물고기 수

  // 스테이지별 목표 수
  static const List<int> _stageTargets = [5, 7, 10];
  static const List<String> _stageNames = ['☀️ 햇살 구역', '🌊 황혼 구역', '🌌 심해 구역'];
  static const List<Color> _stageColors = [Color(0xFF0288D1), Color(0xFF01579B), Color(0xFF0D47A1)];
  // 스테이지별 하늘/바다 테마
  static const List<List<Color>> _stageSkyColors = [
    [Color(0xFFB3E5FC), Color(0xFF81D4FA)],
    [Color(0xFFFF8A65), Color(0xFFD84315)],
    [Color(0xFF1A237E), Color(0xFF0D0D2B)],
  ];
  static const List<String> _stageWeather = ['☁️', '🌥️', '⭐'];
  static const List<String> _stageSunEmoji = ['☀️', '🌅', '🌙'];

  static const List<List<Color>> _stageOceanColors = [
    [Color(0xFF4FC3F7), Color(0xFF0288D1)],
    [Color(0xFF1565C0), Color(0xFF0D47A1)],
    [Color(0xFF0A1628), Color(0xFF000510)],
  ];

  Size _screenSize = Size.zero;

  // 낚시배 (수면 고정 배경) & 낚싯바늘 (유저 컨트롤)
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
  final List<ScorePopup> _popups = [];

  final Random _random = Random();
  late Box _scoreBox;
  List<String> _caughtFishIds = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _scoreBox = Hive.box('high_scores_box');
    _loadCaughtFish();

    // 배 상하 흔들림 (3초 주기)
    _boatBobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _boatBobAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _boatBobController, curve: Curves.easeInOut),
    );

    // 구름 상하좌우 이동 (20초 주기)
    _cloudDriftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudDriftAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_cloudDriftController);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _boatBobController.dispose();
    _cloudDriftController.dispose();
    super.dispose();
  }

  void _loadCaughtFish() {
    final list = _scoreBox.get('caught_fish_list', defaultValue: <dynamic>[]);
    _caughtFishIds = List<String>.from(list);
  }

  void _saveCaughtFish(String id) {
    if (!_caughtFishIds.contains(id)) {
      setState(() {
        _caughtFishIds.add(id);
      });
      _scoreBox.put('caught_fish_list', _caughtFishIds);
    }
  }

  void _startGame(Size size) {
    _screenSize = size;
    _score = 0;
    _lives = 3;
    _stage = 1;
    _catchCount = 0;
    _isStageClear = false;
    _boatX = _screenSize.width / 2;
    _hookX = _screenSize.width / 2;
    _targetHookX = _screenSize.width / 2;
    _hookY = _screenSize.height > 0 ? _screenSize.height * 0.28 - 15 : 120.0;
    _isHookDropping = false;
    _isHookReturning = false;
    _caughtItem = null;
    _fishes.clear();
    _particles.clear();
    _popups.clear();
    _isPlaying = true;
    _isGameOver = false;
    _showCatalog = false;

    // 초기 물고기 떼 생성
    for (int i = 0; i < 8; i++) {
      _spawnFish(initial: true);
    }

    if (!_ticker.isTicking) {
      _ticker.start();
    }
    setState(() {});
  }

  void _nextStage() {
    if (_stage >= 3) {
      // 모든 3스테이지 클리어 시 완전 클리어!
      setState(() {
        _isGameOver = true;
        _isPlaying = false;
        _isStageClear = true; // 클리어 상태로 게임오버 오버레이 표시
      });
      AudioManager.instance.playFishCatch();
      return;
    }
    setState(() {
      _stage++;
      _catchCount = 0;
      _isStageClear = false;
      _lives = 3; // 스테이지가 오르면 하트 회복
      _fishes.clear();
      _particles.clear();
      _popups.clear();
    });
    for (int i = 0; i < 8; i++) {
      _spawnFish(initial: true);
    }
    AudioManager.instance.playFishCatch();
  }

  // ── 물고기 스폰 ──
  void _spawnFish({bool initial = false}) {
    if (_screenSize == Size.zero) return;

    // 수심 영역 (수심 30% 아래부터 깊이에 따라 바다 구분)
    final waterTop = _screenSize.height * 0.28;
    final waterBottom = _screenSize.height - 80;
    final waterHeight = waterBottom - waterTop;

    final y = _random.nextDouble() * (waterHeight - 60) + waterTop + 30;
    final ratio = (y - waterTop) / waterHeight; // 0.0 ~ 1.0 수심 비율

    // 수심에 맞는 구역(Zone)과 어종 선정
    OceanZone zone;
    if (ratio < 0.35) {
      zone = OceanZone.sunlight;
    } else if (ratio < 0.7) {
      zone = OceanZone.twilight;
    } else {
      zone = OceanZone.abyssal;
    }

    final isTrash = _random.nextDouble() < 0.10 + (_stage - 1) * 0.05; // 스테이지 오를수록 쓰레기 더 많이
    final isShark = !isTrash && _random.nextDouble() < 0.08 + (_stage - 1) * 0.05; // 스테이지 오를수록 상어 더 많이

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
      final speed = (_random.nextDouble() * 110 + 90) * (_random.nextBool() ? 1 : -1);
      final x = speed > 0 ? -120.0 : _screenSize.width + 120.0;
      item = FishInstance(
        id: id,
        emoji: '🦈',
        name: '무서운 상어',
        x: x,
        y: y,
        speed: speed,
        isGood: false,
        scale: 1.5, // 상어는 거대하게
      );
    } else {
      // 일반 물고기 선별
      final candidates = _speciesList.where((element) => element.zone == zone).toList();
      final species = candidates[_random.nextInt(candidates.length)];
      final speed = (species.baseSpeed + _random.nextDouble() * 40) * (_random.nextBool() ? 1 : -1);
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
        scale: species.points > 30 ? 1.3 : 1.0,
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

  // ── Ticker 루프 ──
  void _onTick(Duration elapsed) {
    if (!_isPlaying || _isGameOver || _screenSize == Size.zero) return;

    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    if (dt > 0.1) return;

    setState(() {
      // 1. 배는 수면 중앙에 고정 (상하 흔들림 적용)
      _boatX = _screenSize.width / 2;

      // 2. 낚싯바늘은 유저 터치/드래그 목표치로 부드럽게 이동
      _hookX += (_targetHookX - _hookX) * 0.25;

      // 3. 물고기 리스폰 및 갱신
      if (_fishes.length < 9 && _random.nextDouble() < 0.03) {
        _spawnFish();
      }

      for (var fish in _fishes) {
        if (!fish.isCaught) {
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
          // 낚인 물고기는 바늘을 따라 움직임 (3D 파닥파닥)
          fish.x = _hookX;
          fish.y = _hookY + 15;
          fish.swimTimer += dt * 8.0;
        }
      }

      // 화면 이탈 물고기 정량 삭제
      _fishes.removeWhere((f) => !f.isCaught && (f.x < -160 || f.x > _screenSize.width + 160));

      // 4. 낚싯바늘 물리
      if (_isHookDropping) {
        _hookY += 480 * dt; // 빠른 낙하
        // 수면 통과 시 물보라 사운드 1회 재생
        final waterSurfaceY = _screenSize.height * 0.28;
        if (!_playedWaterSplash && _hookY >= waterSurfaceY) {
          _playedWaterSplash = true;
          AudioManager.instance.playFishPlunge(); // 첨벙! 물 입수 소리
        }
        // 바다 최하단 한계선 도달 시 강제 컴백
        if (_hookY > _screenSize.height - 80) {
          _isHookDropping = false;
          _isHookReturning = true;
        } else if (_caughtItem == null) {
          // 물고기 충돌 판정
          final hookRect = Rect.fromCenter(center: Offset(_hookX, _hookY), width: 25, height: 25);
          for (var fish in _fishes) {
            if (!fish.isCaught && fish.rect.overlaps(hookRect)) {
              fish.isCaught = true;
              _caughtItem = fish;
              _isHookDropping = false;
              _isHookReturning = true;
              HapticFeedback.vibrate();
              AudioManager.instance.playFishBite(); // 뽀글! 입질 소리
              break;
            }
          }
        }
      } else if (_isHookReturning) {
        // 무언가 물렸으면 감아올릴 때 무거우므로 느려짐
        final reelSpeed = _caughtItem != null ? 240.0 : 420.0;
        _hookY -= reelSpeed * dt;

        // 물 위(배 밑 수면)에 도달 시
        final restY = _screenSize.height * 0.28 - 15;
        if (_hookY <= restY) {
          _hookY = restY;
          _isHookReturning = false;

          if (_caughtItem != null) {
            final double splashY = _screenSize.height * 0.28; // 수면 높이
            _createSplash(_hookX, splashY, 15, Colors.white);
            _handleCatch(_caughtItem!);
            _fishes.remove(_caughtItem);
            _caughtItem = null;
          }
        }
      }

      // 4. 파티클 이펙트 업데이트
      for (var p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 220 * dt; // 중력
        p.life -= dt * 1.5;
      }
      _particles.removeWhere((p) => p.life <= 0);

      // 5. 팝업 업데이트
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
      _score += species.points;
      _saveCaughtFish(species.id); // 도감 저장
      _catchCount++;
      AudioManager.instance.playFishCatch(); // 짜릿한 낚아올림 성공음
      HapticFeedback.mediumImpact();

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: '${species.name} 낚았다! +${species.points}점',
        color: Colors.amberAccent.shade700,
      ));

      // 스테이지 클리어 체크
      final target = _stageTargets[_stage - 1];
      if (_catchCount >= target) {
        setState(() => _isStageClear = true);
        _isPlaying = false;
      }
    } else {
      // 상어나 쓰레기를 건졌을 때
      _lives--;
      AudioManager.instance.playFishOhNo(); // 아이쿠~ 실망음
      HapticFeedback.heavyImpact();

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: '${item.name}! 하트 1개 감소 😢',
        color: KidsTheme.red,
      ));

      if (_lives <= 0) {
        _isGameOver = true;
        _isPlaying = false;
        AudioManager.instance.playGameOver();
      }
    }
  }

  // ── 터치 제어 (유저 드래그로 낚싯바늘 이동) ──
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPlaying || _isGameOver) return;
    setState(() {
      _targetHookX = (_targetHookX + details.delta.dx).clamp(30.0, _screenSize.width - 30.0);
    });
  }

  // ── 바늘 투하 버튼 ──
  void _dropHook() {
    if (!_isPlaying || _isGameOver || _isHookDropping || _isHookReturning) return;
    AudioManager.instance.playFishReel(); // 릴 감기 찰칵 소리
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
              _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
              _boatX = _screenSize.width / 2;
              _hookX = _screenSize.width / 2;
              _targetHookX = _screenSize.width / 2;
            }

          return Stack(
            children: [
              // ── 바다 3단계 레이어 배경 ──
              Positioned.fill(child: _buildOceanBackground()),

              // ── 물고기 떼 (3D 깊이 순 정렬 및 3D 꼬리 꿀렁임 수영) ──
              ...(() {
                final sortedFishes = List<FishInstance>.from(_fishes)
                  ..sort((a, b) => a.zDepth.compareTo(b.zDepth));

                return sortedFishes.map((fish) {
                  final facingLeft = fish.speed < 0;
                  final effectiveScale = fish.scale * fish.zDepth;

                  // 꼬리 흔들기 (Tail Wag & Wave Wiggle)
                  final tailWiggle = sin(fish.swimPhase + fish.swimTimer * 7.5);
                  final pitchAngle = fish.isCaught
                      ? sin(fish.swimTimer * 12) * 0.4
                      : cos(fish.swimPhase + fish.swimTimer * 3.5) * 0.12;

                  // 3D 원근감 회전 행렬
                  final matrix = Matrix4.diagonal3Values(facingLeft ? -1.0 : 1.0, 1.0, 1.0)
                    ..setEntry(3, 2, 0.003) // Perspective distortion
                    ..rotateY(fish.isCaught ? sin(fish.swimTimer * 10) * 0.8 : tailWiggle * 0.35)
                    ..rotateZ(fish.isCaught ? (facingLeft ? pi / 2 : -pi / 2) + pitchAngle : pitchAngle);

                  // 3D 심해 수심 그림자
                  final shadowOffset = Offset(
                    facingLeft ? 4.0 * fish.zDepth : -4.0 * fish.zDepth,
                    5.0 * fish.zDepth,
                  );
                  final opacity = (fish.zDepth * 0.75 + 0.25).clamp(0.45, 1.0);

                  return Positioned(
                    left: fish.x - (30 * effectiveScale),
                    top: fish.renderY - (20 * effectiveScale),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: matrix,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 3D 입체 수중 그림자
                            Transform.translate(
                              offset: shadowOffset,
                              child: Text(
                                fish.emoji,
                                style: TextStyle(
                                  fontSize: 38 * effectiveScale,
                                  color: Colors.black.withValues(alpha: 0.22),
                                ),
                              ),
                            ),
                            // 물고기 꼬리 및 몸통 꿀렁임 스큐(Shear) 3D 애니메이션
                            Transform(
                              alignment: facingLeft ? Alignment.centerRight : Alignment.centerLeft,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.002)
                                ..setEntry(0, 1, tailWiggle * 0.14),
                              child: Text(
                                fish.emoji,
                                style: TextStyle(fontSize: 38 * effectiveScale),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              }()),

              // ── 낚싯배 (배경 고정) & 낚싯줄 / 낚싯바늘 ──
              Builder(
                builder: (context) {
                  final boatY = _screenSize.height * 0.28 - 45 + _boatBobAnim.value;
                  final boatRodTop = Offset(_boatX, boatY + 25);
                  final hookPos = Offset(_hookX, _hookY);

                  return Stack(
                    children: [
                      // ── 낚싯배 ⛵ (수면 중앙에 떠 있는 배경 이미지) ──
                      Positioned(
                        left: _boatX - 35,
                        top: boatY,
                        child: const Text('⛵', style: TextStyle(fontSize: 62)),
                      ),

                      // ── 낚싯줄 (배 -> 낚싯바늘 동적 연결) ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: FishingLinePainter(
                            start: boatRodTop,
                            end: hookPos,
                          ),
                        ),
                      ),

                      // ── 낚싯바늘 🪝 (유저가 직접 조종하는 바늘) ──
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

              // ── 터치 드래그 및 수면 터치 영역 ──
              Positioned.fill(
                child: GestureDetector(
                  onTapDown: (_) => _dropHook(),
                  onPanUpdate: _onPanUpdate,
                  behavior: HitTestBehavior.translucent,
                ),
              ),

              // ── 파티클 및 스코어 팝업 ──
              ..._particles.map((p) => Positioned(
                left: p.x - 3,
                top: p.y - 3,
                child: Opacity(
                  opacity: p.life.clamp(0.0, 1.0),
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                ),
              )),

              ..._popups.map((p) => Positioned(
                left: p.x - 100,
                width: 200,
                top: p.y,
                child: Opacity(
                  opacity: p.life.clamp(0.0, 1.0),
                  child: Center(
                    child: Text(
                      p.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jua(fontSize: 18, color: p.color, shadows: [const Shadow(color: Colors.white, blurRadius: 6)]),
                    ),
                  ),
                ),
              )),

              // ── 던지기(🪝) 고대비 플로팅 버튼 ──
              if (_isPlaying && !_isGameOver && !_isHookDropping && !_isHookReturning)
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _dropHook(),
                      onTap: _dropHook,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                        decoration: BoxDecoration(
                          color: KidsTheme.orange,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 6)),
                            const BoxShadow(color: Colors.white24, blurRadius: 4, offset: Offset(0, -2))
                          ],
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪝', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 10),
                            Text('찌 던지기!', style: GoogleFonts.jua(fontSize: 26, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // ── 통합 헤더 대시보드 (버튼/진행도 겹침 없는 깔끔한 카드) ──
              Positioned(
                top: 6,
                left: 10,
                right: 10,
                child: _buildHeaderCard(),
              ),

              // ── 시작 대기 화면 오버레이 ──
              if (!_isPlaying && !_isGameOver && !_isStageClear && !_showCatalog) _buildStartOverlay(),

              // ── 스테이지 클리어 오버레이 ──
              if (_isStageClear && !_isGameOver && !_showCatalog) _buildStageClearOverlay(),

              // ── 게임 오버 (전체 클리어 또는 상어에 짼) 오버레이 ──
              if (_isGameOver && !_showCatalog) _buildGameOverOverlay(),

              // ── 바다 도감 슬라이드 팝업 오버레이 ──
              if (_showCatalog) _buildCatalogOverlay(),
            ],
          );
        },
      ),
    ),
    );
  }

  // ── 헤더 카드 위젯 (통합 글래스모피즘 뷰) ──
  Widget _buildHeaderCard() {
    final target = _stageTargets[_stage - 1];
    final progress = (_catchCount / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 상단 툴바 행 ──
          Row(
            children: [
              // 뒤로가기
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                },
                onTap: () {
                  AudioManager.instance.playClick();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: KidsTheme.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KidsTheme.red.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new_rounded, color: KidsTheme.red, size: 16),
                      const SizedBox(width: 4),
                      Text('나가기', style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.red)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 도감 버튼
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  setState(() => _showCatalog = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('${_caughtFishIds.length}/${_speciesList.length}',
                          style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFF7C3AED))),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 점수 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: KidsTheme.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('⭐ $_score', style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.orange)),
              ),
              const SizedBox(width: 6),
              // 하트
              Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(
                      index < _lives ? '❤️' : '🖤',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (_isPlaying) ...[
            const SizedBox(height: 6),
            // ── 하단 진행도 행 ──
            Row(
              children: [
                Text(
                  _stageNames[_stage - 1],
                  style: GoogleFonts.jua(fontSize: 11, color: _stageColors[_stage - 1]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: LayoutBuilder(
                      builder: (ctx, bc) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: bc.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: _stageColors[_stage - 1],
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [_stageColors[_stage - 1], Colors.cyanAccent],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '📁 $_catchCount/${_stageTargets[_stage - 1]}',
                  style: GoogleFonts.jua(fontSize: 11, color: KidsTheme.textDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── 스테이지별 업데이트되는 바다 배경 ──
  Widget _buildOceanBackground() {
    final si = _stage - 1;
    final skyColors = _stageSkyColors[si];
    final oceanColors = _stageOceanColors[si];
    final weatherEmoji = _stageWeather[si];
    final sunEmoji = _stageSunEmoji[si];

    return Column(
      children: [
        // ── 하늘 영역 (28%) ──
        Expanded(
          flex: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: skyColors,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
              // ── 태양/노을/달 위치 (헤더 아래 하늘 공간) ──
              Positioned(
                top: 75,
                right: 16,
                child: Text(sunEmoji, style: const TextStyle(fontSize: 26)),
              ),
              // 구름 1: 헤더 아래에서 느리게 흐름
              AnimatedBuilder(
                animation: _cloudDriftAnim,
                builder: (ctx, child) {
                  final screenW = _screenSize.width > 0 ? _screenSize.width : 400;
                  final offset = (_cloudDriftAnim.value * screenW * 1.3) - screenW * 0.15;
                  return Positioned(
                    left: offset % (screenW + 80) - 80,
                    top: 80,
                    child: Text(weatherEmoji, style: TextStyle(
                      fontSize: 32,
                      color: si == 2 ? Colors.white54 : Colors.white,
                    )),
                  );
                },
              ),
              // 구름 2: 조금 빠르게
              AnimatedBuilder(
                animation: _cloudDriftAnim,
                builder: (ctx, child) {
                  final screenW = _screenSize.width > 0 ? _screenSize.width : 400;
                  final offset = ((_cloudDriftAnim.value + 0.5) * screenW * 1.3) - screenW * 0.15;
                  return Positioned(
                    left: offset % (screenW + 60) - 60,
                    top: 96,
                    child: Text(weatherEmoji, style: TextStyle(
                      fontSize: 22,
                      color: si == 2 ? Colors.white38 : Colors.white70,
                    )),
                  );
                },
              ),
                // 스테이지 화산 야광 파티클 (심해 스테이지만)
                if (si == 2)
                  ...List.generate(6, (i) => Positioned(
                    left: (i * 55.0 + 20).toDouble(),
                    top: 8 + (i % 3) * 10.0,
                    child: Text('✨', style: TextStyle(fontSize: 12 + (i % 3) * 4.0)),
                  )),
              ],
            ),
          ),
        ),
        // ── 바다 영역 (72%) ──
        Expanded(
          flex: 72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: oceanColors,
              ),
            ),
            child: Stack(
              children: [
                // 수면선 파도 장식
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 스테이지 전용 해저 생물 장식
                if (si == 0) ...[
                  // 햇살: 산호와 해초를 아래에
                  const Positioned(bottom: 20, left: 30, child: Text('🪮', style: TextStyle(fontSize: 22))),
                  const Positioned(bottom: 10, left: 90, child: Text('🐠', style: TextStyle(fontSize: 16))),
                  const Positioned(bottom: 25, right: 40, child: Text('🐚', style: TextStyle(fontSize: 20))),
                ],
                if (si == 1) ...[
                  // 황혼: 수초와 해파리
                  const Positioned(bottom: 30, left: 20, child: Text('🫨', style: TextStyle(fontSize: 24))),
                  const Positioned(bottom: 15, right: 50, child: Text('🐡', style: TextStyle(fontSize: 18))),
                ],
                if (si == 2) ...[
                  // 심해: 어둠속 신비로운 장식
                  const Positioned(bottom: 35, left: 15, child: Text('🪼', style: TextStyle(fontSize: 26))),
                  const Positioned(bottom: 20, left: 80, child: Text('✨', style: TextStyle(fontSize: 14))),
                  const Positioned(bottom: 40, right: 25, child: Text('🐙', style: TextStyle(fontSize: 22))),
                  const Positioned(bottom: 10, right: 80, child: Text('✨', style: TextStyle(fontSize: 10))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 시작 화면 오버레이 ──
  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.blue, width: 6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⛵🎣', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text('신나는 바다 낚시', style: GoogleFonts.jua(fontSize: 34, color: KidsTheme.blue)),
                const SizedBox(height: 12),
                Text('배를 드래그해서 움직이고,\n던지기 버튼으로 찌를 내려요!', textAlign: TextAlign.center, style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark)),
                const SizedBox(height: 6),
                Text('⚠️ 상어와 바다 쓰레기는 피해요!', style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.red)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: KidsTheme.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('🎯 스테이지 목표', style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.blue)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('☀️ ${_stageTargets[0]}마리', style: GoogleFonts.jua(fontSize: 12, color: _stageColors[0])),
                          Text('🌊 ${_stageTargets[1]}마리', style: GoogleFonts.jua(fontSize: 12, color: _stageColors[1])),
                          Text('🌌 ${_stageTargets[2]}마리', style: GoogleFonts.jua(fontSize: 12, color: _stageColors[2])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showCatalog = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: KidsTheme.purple, borderRadius: BorderRadius.circular(20)),
                        child: Text('📖 도감', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _startGame(_screenSize),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(color: KidsTheme.green, borderRadius: BorderRadius.circular(20)),
                        child: Text('출발! 🚀', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 스테이지 클리어 오버레이 ──
  Widget _buildStageClearOverlay() {
    final nextStageName = _stage < 3 ? _stageNames[_stage] : null;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.green, width: 6),
              boxShadow: [BoxShadow(color: KidsTheme.green.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_stageNames[_stage - 1], style: GoogleFonts.jua(fontSize: 18, color: _stageColors[_stage - 1])),
                const SizedBox(height: 8),
                const Text('🎉🌟🎉', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                Text('스테이지 클리어!', style: GoogleFonts.jua(fontSize: 36, color: KidsTheme.green)),
                const SizedBox(height: 6),
                Text(
                  '${_stageTargets[_stage - 1]}마리를 모두 낙았어요! 홍수!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text('누적 점수: $_score 점 ⭐', style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.orange)),
                if (nextStageName != null) ...
                  [
                    const SizedBox(height: 4),
                    Text('다음: $nextStageName 진입!', style: GoogleFonts.jua(fontSize: 14, color: _stageColors[_stage])),
                    Text('다음 단계는 상어와 쓰레기가 더 많아요!', style: GoogleFonts.jua(fontSize: 12, color: Colors.grey)),
                  ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    setState(() => _isStageClear = false);
                    _isPlaying = true;
                    _nextStage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: KidsTheme.green.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Text(
                      nextStageName != null ? '다음 바다로! 🚤➡️' : '최종 점수 확인! 🏆',
                      style: GoogleFonts.jua(fontSize: 22, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 게임 오버 오버레이 ──
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.orange, width: 5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('☠️🦈', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text('조심하세요!', style: GoogleFonts.jua(fontSize: 34, color: KidsTheme.red)),
                const SizedBox(height: 8),
                Text('바다가 험해져 낚시가 끝났어요.', style: GoogleFonts.jua(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('최종 점수: $_score 점 ⭐', style: GoogleFonts.jua(fontSize: 24, color: KidsTheme.textDark)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showCatalog = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(color: KidsTheme.purple, borderRadius: BorderRadius.circular(20)),
                        child: Text('📖 도감 확인', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _startGame(_screenSize),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(color: KidsTheme.green, borderRadius: BorderRadius.circular(20)),
                        child: Text('다시 도전! 🔄', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 바다 도감(Fish Book) 팝업 오버레이 ──
  Widget _buildCatalogOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5FE),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.purple, width: 6),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📖 바다 생물 도감 (${_caughtFishIds.length} / ${_speciesList.length})', style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.purple)),
                    GestureDetector(
                      onTap: () => setState(() => _showCatalog = false),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.close, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _speciesList.length,
                    itemBuilder: (context, index) {
                      final species = _speciesList[index];
                      final isCaught = _caughtFishIds.contains(species.id);

                      return Container(
                        decoration: BoxDecoration(
                          color: isCaught ? Colors.white : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCaught ? KidsTheme.purple.withValues(alpha: 0.6) : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isCaught ? species.emoji : '❓',
                              style: TextStyle(fontSize: 32, color: isCaught ? null : Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                isCaught ? species.name : '미확인 생물',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jua(fontSize: 10, color: isCaught ? KidsTheme.textDark : Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCaught)
                              Text(
                                '${species.points}점',
                                style: GoogleFonts.jua(fontSize: 9, color: KidsTheme.orange),
                              ),
                          ],
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
    );
  }
}

// ── 낚싯줄 커스텀 페인터 ──
class FishingLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  FishingLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // 낚싯줄 곡선 (배에서 낚싯바늘로 살짝 처지는 자연스러운 곡선)
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2 + 6;
    path.quadraticBezierTo(midX, midY, end.dx, end.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant FishingLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
