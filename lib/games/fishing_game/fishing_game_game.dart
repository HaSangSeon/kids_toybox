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
  final bool isRare;

  const FishSpecies({
    required this.id,
    required this.emoji,
    required this.name,
    required this.zone,
    required this.points,
    required this.baseSpeed,
    this.isRare = false,
  });
}

const List<FishSpecies> _speciesList = [
  // 1구역 (햇살)
  FishSpecies(id: 'clown', emoji: '🐠', name: '니모(흰동가리)', zone: OceanZone.sunlight, points: 10, baseSpeed: 90.0),
  FishSpecies(id: 'tang', emoji: '🐟', name: '도리(블루탱)', zone: OceanZone.sunlight, points: 10, baseSpeed: 100.0),
  FishSpecies(id: 'star', emoji: '⭐', name: '알록달록 불가사리', zone: OceanZone.sunlight, points: 15, baseSpeed: 40.0),
  FishSpecies(id: 'puffer', emoji: '🐡', name: '가시 복어', zone: OceanZone.sunlight, points: 15, baseSpeed: 60.0),
  FishSpecies(id: 'goldfish', emoji: '✨', name: '황금빛 해파리', zone: OceanZone.sunlight, points: 100, baseSpeed: 120.0, isRare: true),
  // 2구역 (황혼)
  FishSpecies(id: 'turtle', emoji: '🐢', name: '느긋한 바다거북', zone: OceanZone.twilight, points: 20, baseSpeed: 50.0),
  FishSpecies(id: 'squid', emoji: '🦑', name: '하늘하늘 오징어', zone: OceanZone.twilight, points: 20, baseSpeed: 110.0),
  FishSpecies(id: 'crab', emoji: '🦀', name: '옆으로 꽃게', zone: OceanZone.twilight, points: 20, baseSpeed: 70.0),
  FishSpecies(id: 'shrimp', emoji: '🦐', name: '아기 새우', zone: OceanZone.twilight, points: 25, baseSpeed: 130.0),
  FishSpecies(id: 'whaleshark', emoji: '🦈', name: '멋진 고래상어', zone: OceanZone.twilight, points: 150, baseSpeed: 140.0, isRare: true),
  // 3구역 (심해)
  FishSpecies(id: 'jelly', emoji: '🪼', name: '야광 해파리', zone: OceanZone.abyssal, points: 30, baseSpeed: 80.0),
  FishSpecies(id: 'octopus', emoji: '🐙', name: '재주꾼 문어', zone: OceanZone.abyssal, points: 30, baseSpeed: 90.0),
  FishSpecies(id: 'dolphin', emoji: '🐬', name: '분홍 돌고래', zone: OceanZone.abyssal, points: 50, baseSpeed: 160.0),
  FishSpecies(id: 'whale', emoji: '🐳', name: '아기 고래', zone: OceanZone.abyssal, points: 50, baseSpeed: 120.0),
  FishSpecies(id: 'giantwhale', emoji: '🐋', name: '거대한 대왕고래', zone: OceanZone.abyssal, points: 200, baseSpeed: 80.0, isRare: true),
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

  // 부드러운 수영 및 생체 물리학 속성
  final double zDepth; // 0.65 (깊은 배경) ~ 1.35 (전경)
  double swimTimer;
  final double swimPhase;
  double lastBubbleTime;

  // 생물 종류별 맞춤 파동 수영 매개변수
  final double waveAmp;
  final double waveFreq;
  final double swayFreq;

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
       lastBubbleTime = 0,
       waveAmp = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 18.0 : 10.0,
       waveFreq = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 1.1 : 2.2,
       swayFreq = (scale >= 1.4 || emoji == '🐋' || emoji == '🦈' || emoji == '🐬' || emoji == '🐢') ? 1.8 : 4.0;

  // 파동에 따른 실시간 Y 위치
  double get renderY => y + (isCaught ? 0 : sin(swimPhase + swimTimer * waveFreq) * waveAmp);

  // 파동 궤적에 따른 자연스러운 기울기 (Tilt / Pitch Angle)
  double get tiltAngle {
    if (isCaught) return 0.0;
    final dy = cos(swimPhase + swimTimer * waveFreq) * waveAmp * waveFreq;
    final facingLeft = speed < 0;
    return atan2(dy, speed.abs() * 0.8) * (facingLeft ? 0.45 : -0.45);
  }

  // 꼬리 및 몸통의 부드러운 헤엄치기 (Sway Angle)
  double get swayAngle => isCaught ? sin(swimTimer * 10.0) * 0.3 : sin(swimPhase * 1.5 + swimTimer * swayFreq) * 0.10;

  Rect get rect => Rect.fromCenter(
    center: Offset(x, renderY),
    width: 60 * scale * zDepth,
    height: 45 * scale * zDepth,
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
  bool _showZoneSelect = false;

  int _stage = 1;          // 1=햇살, 2=황혼, 3=심해
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

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);

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
      _popups.clear();
    });
    for (int i = 0; i < 8; i++) {
      _spawnFish(initial: true);
    }
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
      // 일반 물고기 선별
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
      if (species.isRare) {
        AudioManager.instance.playMagicUnfoldSuccess(); // 레어 물고기 특별 사운드
        HapticFeedback.heavyImpact();
      } else {
        AudioManager.instance.playFishCatch(); // 낚아올림 성공음
        HapticFeedback.mediumImpact();
      }

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: species.isRare ? '✨ ${species.name} 낚았다! ✨' : '${species.name} 낚았다! 🎣',
        color: species.isRare ? Colors.pinkAccent : Colors.amberAccent.shade700,
      ));
    } else {
      // 상어나 쓰레기를 건졌을 때 (하트 차감 없이 재미있는 아이쿠 팝업)
      AudioManager.instance.playFishOhNo(); // 아이쿠~ 실망음
      HapticFeedback.heavyImpact();

      _popups.add(ScorePopup(
        x: _hookX,
        y: 120,
        text: '아이쿠! ${item.name}! 💦',
        color: KidsTheme.red,
      ));
    }
  }

  // ── 터치 제어 (유저 드래그로 낚싯바늘 이동) ──
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPlaying) return;
    setState(() {
      _targetHookX = (_targetHookX + details.delta.dx).clamp(30.0, _screenSize.width - 30.0);
    });
  }

  // ── 바늘 투하 버튼 ──
  void _dropHook() {
    if (!_isPlaying || _isHookDropping || _isHookReturning) return;
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
              // ── 바다 3단계 레이어 배경 (터치 간섭 방지) ──
              Positioned.fill(child: IgnorePointer(child: _buildOceanBackground())),

              // ── 물고기 떼 (터치 간섭 방지) ──
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

                  // 유기적인 숨쉬기/플렉스 (Scale Breathing)
                  final breathScaleX = 1.0 + 0.04 * sin(fish.swimTimer * 2.5);
                  final breathScaleY = 1.0 - 0.03 * sin(fish.swimTimer * 2.5);

                  // 부드러운 회전 각도 (Wave Tilt + Body Sway)
                  final totalRotation = fish.tiltAngle + fish.swayAngle;

                  // 수중 그림자 위치
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
                          ..scale(
                            facingLeft ? effectiveScale * breathScaleX : -effectiveScale * breathScaleX,
                            effectiveScale * breathScaleY,
                            1.0,
                          ),
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

              // ── 낚싯배 & 낚싯줄 / 낚싯바늘 (터치 간섭 방지) ──
              Positioned.fill(
                child: IgnorePointer(
                  child: Builder(
                builder: (context) {
                  final boatY = _screenSize.height * 0.28 - 45 + _boatBobAnim.value;
                  final boatRodTop = Offset(_boatX, boatY + 25);
                  final hookPos = Offset(_hookX, _hookY);

                  return Stack(
                    children: [
                      // ── 낚싯배 ⛵ ──
                      Positioned(
                        left: _boatX - 35,
                        top: boatY,
                        child: const Text('⛵', style: TextStyle(fontSize: 62)),
                      ),

                      // ── 낚싯줄 ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: FishingLinePainter(
                            start: boatRodTop,
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

              // ── 터치 드래그 및 수면 터치 영역 (헤더 아래 90px부터 반응) ──
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

              // ── 파티클 및 팝업 (터치 간섭 방지) ──
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      ..._particles.map((p) => Positioned(
                        left: p.x - 3,
                        top: p.y - 3,
                        child: Opacity(
                          opacity: p.life.clamp(0.0, 1.0),
                          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
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
                              style: GoogleFonts.jua(fontSize: 20, color: p.color, shadows: [const Shadow(color: Colors.white, blurRadius: 8)]),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),

              // ── 상단 헤더 대시보드 (최상단 독점 터치 레이어) ──
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: _buildHeaderCard(),
              ),

              // ── 구역 이동 오버레이 ──
              if (_showZoneSelect) _buildZoneSelectOverlay(),
            ],
          );
        },
      ),
    ),
    );
  }

  // ── 헤더 카드 위젯 (아담하고 깔끔하게 떨어진 뷰) ──
  Widget _buildHeaderCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 뒤로가기 버튼
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.red.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, color: KidsTheme.red, size: 14),
                  const SizedBox(width: 4),
                  Text('그만하기', style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.red)),
                ],
              ),
            ),
          ),
        ),

        // 바다 바꾸기 버튼
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AudioManager.instance.playClick();
              setState(() => _showZoneSelect = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _stageColors[_stage - 1], width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🗺️ 바다 바꾸기', style: GoogleFonts.jua(fontSize: 14, color: _stageColors[_stage - 1])),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, color: _stageColors[_stage - 1], size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
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

  // ── 구역 이동 오버레이 ──
  Widget _buildZoneSelectOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showZoneSelect = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // 배경 터치 시 다이얼로그 닫힘 방지
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: KidsTheme.blue, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🗺️ 바다 이동', style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.blue)),
                          IconButton(
                            iconSize: 32,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              AudioManager.instance.playClick();
                              setState(() => _showZoneSelect = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('어떤 바다에서 낚시할까요?', style: GoogleFonts.jua(fontSize: 18, color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                      ...List.generate(3, (index) {
                        final isCurrent = _stage == index + 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              AudioManager.instance.playClick();
                              setState(() {
                                _showZoneSelect = false;
                              });
                              _changeZone(index + 1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              decoration: BoxDecoration(
                                color: isCurrent ? _stageColors[index] : _stageColors[index].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _stageColors[index], width: 3.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _stageNames[index],
                                    style: GoogleFonts.jua(fontSize: 24, color: isCurrent ? Colors.white : _stageColors[index]),
                                  ),
                                  const Spacer(),
                                  if (isCurrent)
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
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

// ── 실시간 관절 꼬리 흔들기 물고기 위젯 ──
class _SegmentedWigglingFish extends StatelessWidget {
  final String emoji;
  final double fontSize;
  final double swimTimer;
  final bool isLarge;
  final Color? textColor;

  const _SegmentedWigglingFish({
    required this.emoji,
    required this.fontSize,
    required this.swimTimer,
    this.isLarge = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, color: textColor);

    // 쓰레기나 바위 등 비생물은 흔들림 없음
    if (emoji == '🪨' || emoji == '👞' || emoji == '🥫' || emoji == '🍾') {
      return Text(emoji, style: style);
    }

    // 세로형 생물 (해파리, 오징어, 문어) -> 상하 촉수 펄스 & 살랑살랑
    final isVertical = emoji == '🪼' || emoji == '🦑' || emoji == '🐙';
    if (isVertical) {
      final freq = 5.0;
      final sway = sin(swimTimer * freq) * 0.18;
      final pulse = 1.0 + 0.10 * sin(swimTimer * freq);

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 갓/머리 (상단 55%)
          ClipRect(
            clipper: _VerticalSliceClipper(topRatio: 0.0, bottomRatio: 0.55),
            child: Text(emoji, style: style),
          ),
          // 촉수/다리 (하단 42%~100%) - 관절 회전 및 펄스
          Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..rotateZ(sway)
              ..scale(1.0, pulse, 1.0),
            child: ClipRect(
              clipper: _VerticalSliceClipper(topRatio: 0.42, bottomRatio: 1.0),
              child: Text(emoji, style: style),
            ),
          ),
        ],
      );
    }

    // 가로형 어종 (물고기, 고래, 상어, 거북이 등) -> 몸통과 꼬리가 분리되어 파닥파닥
    final freq = isLarge ? 5.5 : 9.0;
    final maxAngle = isLarge ? 0.22 : 0.35;
    final tailAngle = sin(swimTimer * freq) * maxAngle;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // 1. 머리 및 몸통 (왼쪽 0% ~ 55%)
        ClipRect(
          clipper: _HorizontalSliceClipper(leftRatio: 0.0, rightRatio: 0.55),
          child: Text(emoji, style: style),
        ),
        // 2. 관절 꼬리 (오른쪽 42% ~ 100%) -> 관절 부위 중심 파닥파닥!
        Transform(
          alignment: const Alignment(-0.12, 0.0), // 몸통-꼬리 경계 관절 핀
          transform: Matrix4.identity()..rotateZ(tailAngle),
          child: ClipRect(
            clipper: _HorizontalSliceClipper(leftRatio: 0.42, rightRatio: 1.0),
            child: Text(emoji, style: style),
          ),
        ),
      ],
    );
  }
}

class _HorizontalSliceClipper extends CustomClipper<Rect> {
  final double leftRatio;
  final double rightRatio;

  _HorizontalSliceClipper({required this.leftRatio, required this.rightRatio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * leftRatio,
      -20,
      size.width * rightRatio,
      size.height + 20,
    );
  }

  @override
  bool shouldReclip(covariant _HorizontalSliceClipper oldDelegate) {
    return oldDelegate.leftRatio != leftRatio || oldDelegate.rightRatio != rightRatio;
  }
}

class _VerticalSliceClipper extends CustomClipper<Rect> {
  final double topRatio;
  final double bottomRatio;

  _VerticalSliceClipper({required this.topRatio, required this.bottomRatio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      -20,
      size.height * topRatio,
      size.width + 20,
      size.height * bottomRatio,
    );
  }

  @override
  bool shouldReclip(covariant _VerticalSliceClipper oldDelegate) {
    return oldDelegate.topRatio != topRatio || oldDelegate.bottomRatio != bottomRatio;
  }
}
