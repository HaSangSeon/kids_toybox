import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Cotton Candy Game — 빙글빙글 무지개 솜사탕 가게! (3~5세 톡톡 쉬운 놀이)
// 프리미엄 파스텔 스위트 부티크 배경 + 황동·에나멜 3D 솜사탕 카트 + 손님 리액션 & 다층 구름 솜사탕
// ─────────────────────────────────────────────────────────────────────────────

enum CottonShapeType {
  cloud('☁️ 구름', '몽실몽실 구름 모양'),
  rabbit('🐰 토끼', '깡충깡충 토끼 모양'),
  bear('🐻 곰돌이', '포근포근 곰돌이 모양'),
  heart('💖 하트', '사랑해 하트 모양'),
  star('⭐ 별', '반짝반짝 별 모양');

  final String label;
  final String desc;
  const CottonShapeType(this.label, this.desc);
}

class _SugarFlavor {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color lightColor;
  final Color deepColor;

  const _SugarFlavor({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.deepColor,
  });
}

class _SugarThreadParticle {
  double angle;
  double radius;
  Color color;
  double life = 1.0;

  _SugarThreadParticle({
    required this.angle,
    required this.radius,
    required this.color,
  });
}

class _SweetSparkle {
  double x, y, vx, vy, size, life, rotation, vRot;
  Color color;
  int kind; // 0: star, 1: heart, 2: sugar crystal

  _SweetSparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
    this.rotation = 0.0,
    this.vRot = 0.08,
    this.kind = 0,
  });
}

class CottonCandyGame extends StatefulWidget {
  const CottonCandyGame({super.key});

  @override
  State<CottonCandyGame> createState() => _CottonCandyGameState();
}

class _CottonCandyGameState extends State<CottonCandyGame>
    with TickerProviderStateMixin {
  static const List<_SugarFlavor> _flavors = [
    _SugarFlavor(
      id: 'strawberry',
      name: '딸기',
      emoji: '🍓',
      color: Color(0xFFFF80AB),
      lightColor: Color(0xFFFCE4EC),
      deepColor: Color(0xFFD81B60),
    ),
    _SugarFlavor(
      id: 'lemon',
      name: '레몬',
      emoji: '🍋',
      color: Color(0xFFFFD54F),
      lightColor: Color(0xFFFFFDE7),
      deepColor: Color(0xFFF57F17),
    ),
    _SugarFlavor(
      id: 'soda',
      name: '소다',
      emoji: '🐳',
      color: Color(0xFF4FC3F7),
      lightColor: Color(0xFFE1F5FE),
      deepColor: Color(0xFF0277BD),
    ),
    _SugarFlavor(
      id: 'grape',
      name: '포도',
      emoji: '🍇',
      color: Color(0xFFBA68C8),
      lightColor: Color(0xFFF3E5F5),
      deepColor: Color(0xFF7B1FA2),
    ),
    _SugarFlavor(
      id: 'mint',
      name: '민트',
      emoji: '🌿',
      color: Color(0xFF4DB6AC),
      lightColor: Color(0xFFE0F2F1),
      deepColor: Color(0xFF00796B),
    ),
  ];

  static const List<({String id, String name, String emoji, String orderLine})>
      _customers = [
    (
      id: 'rabbit',
      name: '아기 토끼',
      emoji: '🐰',
      orderLine: '구름처럼 폭신한 솜사탕 주세요!'
    ),
    (
      id: 'bear',
      name: '아기 곰돌이',
      emoji: '🐻',
      orderLine: '달콤한 무지개 솜사탕 먹고 싶어요!'
    ),
    (
      id: 'dog',
      name: '아기 강아지',
      emoji: '🐶',
      orderLine: '멍멍! 토핑 가득 솜사탕 만들어 주세요!'
    ),
    (
      id: 'cat',
      name: '아기 고양이',
      emoji: '🐱',
      orderLine: '야옹~ 예쁜 모양 솜사탕이 좋아요!'
    ),
    (
      id: 'unicorn',
      name: '아기 유니콘',
      emoji: '🦄',
      orderLine: '반짝반짝 마법 솜사탕을 만들어 줄래요?'
    ),
    (
      id: 'penguin',
      name: '아기 펭귄',
      emoji: '🐧',
      orderLine: '사르르 녹는 달콤 솜사탕 기대돼요!'
    ),
  ];

  static const List<({String emoji, String label})> _toppings = [
    (emoji: '🌈', label: '스프링클'),
    (emoji: '🍓', label: '생딸기'),
    (emoji: '⭐', label: '별사탕'),
    (emoji: '🍪', label: '마카롱'),
    (emoji: '🎀', label: '리본'),
  ];

  late ConfettiController _confettiCtrl;
  late AnimationController _autoSpinCtrl;
  late AnimationController _customerBounceCtrl;
  late AnimationController _feedMotionCtrl; // 솜사탕이 손님 입으로 쏙 올라가 먹여주는 모션!
  late Ticker _ticker;

  final Random _rng = Random();
  final List<_SugarThreadParticle> _threads = [];
  final List<_SweetSparkle> _sparkles = [];

  // 다층 무지개 솜사탕 컬러 레이어
  final List<_SugarFlavor> _fluffLayers = [_flavors[0]];
  _SugarFlavor _activeFlavor = _flavors[0];
  CottonShapeType _selectedShape = CottonShapeType.cloud;
  final Set<String> _equippedToppings = {'🌈'};

  int _customerIdx = 0;
  int _totalStars = 0;
  int _servedCount = 0;

  double _fluffProgress = 0.14; // 0.14 ~ 1.0
  bool _isFluffReady = false;
  int _bitesTaken = 0; // 0 ~ 3
  bool _isFeedingAnimating = false;
  bool _isCustomerMouthOpen = false;
  Offset _manualFeedDragOffset = Offset.zero; // 손가락으로 직접 끌어서 먹여줄 때 오프셋
  double _stickOrbitAngle = 0.0;
  bool _isSpinning = false;
  Offset? _dragHandPos;
  double _elapsed = 0.0;
  DateTime _lastSpinSoundTime = DateTime.fromMillisecondsSinceEpoch(0);

  String _shibaSpeech = '설탕을 고르고 기계를 손가락으로 빙글빙글 문질러 봐 멍! 🍭';
  bool _isShibaCelebrating = false;
  Timer? _shibaTimer;

  ({String id, String name, String emoji, String orderLine})
      get _currentCustomer => _customers[_customerIdx % _customers.length];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));

    _customerBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _feedMotionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _autoSpinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..addListener(() {
        _advanceSpin(0.017, fromDrag: false);
      });

    _ticker = createTicker((_) {
      const dt = 0.016;
      _elapsed += dt;

      if (_threads.isNotEmpty) {
        for (final th in _threads) {
          th.angle += 0.24;
          th.radius += 1.35;
          th.life -= 0.042;
        }
        _threads.removeWhere((th) => th.life <= 0);
      }

      if (_sparkles.isNotEmpty) {
        for (final s in _sparkles) {
          s.x += s.vx;
          s.y += s.vy;
          s.vy += (s.kind == 1) ? -0.05 : 0.11;
          s.rotation += s.vRot;
          s.life -= 0.026;
        }
        _sparkles.removeWhere((s) => s.life <= 0);
      }

      if (mounted) setState(() {});
    })..start();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        AudioManager.instance.playVoice('audio/voice_cotton_intro.wav');
      }
    });
  }

  @override
  void dispose() {
    _shibaTimer?.cancel();
    _ticker.dispose();
    _feedMotionCtrl.dispose();
    _customerBounceCtrl.dispose();
    _autoSpinCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _selectFlavor(_SugarFlavor flavor) {
    HapticFeedback.selectionClick();
    AudioManager.instance.playCottonSugarPour(speak: !_isFluffReady);
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    _spawnSparkles(
      Offset(size.width / 2, size.height * 0.50),
      colorOverride: flavor.color,
      count: 12,
    );

    setState(() {
      _activeFlavor = flavor;
      if (_fluffLayers.last.id != flavor.id) {
        _fluffLayers.add(flavor);
        if (_fluffLayers.length > 5) {
          _fluffLayers.removeAt(0);
        }
      }
    });
    _setShibaSpeech(
      '${flavor.emoji} ${flavor.name} 설탕을 솔솔 부었어! 이제 빙글빙글 돌려봐 멍! ✨',
      celebrate: false,
    );
  }

  void _addRainbowSugar() {
    HapticFeedback.mediumImpact();
    AudioManager.instance.playCottonSugarPour(speak: false);
    AudioManager.instance.playRacingItemStar();
    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    _spawnSparkles(
      Offset(size.width / 2, size.height * 0.48),
      includeHearts: true,
      count: 18,
    );
    setState(() {
      _fluffLayers
        ..clear()
        ..addAll(_flavors);
      _activeFlavor = _flavors[_rng.nextInt(_flavors.length)];
    });
    _setShibaSpeech('🌈 우와! 5가지 무지개 마법 설탕이 층층이 섞였어 멍!', celebrate: true);
  }

  void _advanceSpin(double deltaProgress, {required bool fromDrag}) {
    if (_bitesTaken > 0) return;

    _stickOrbitAngle += 0.25;
    _isSpinning = true;

    for (int i = 0; i < 3; i++) {
      final layerFlavor = _fluffLayers[(i + _threads.length) % _fluffLayers.length];
      _threads.add(_SugarThreadParticle(
        angle: _rng.nextDouble() * 2 * pi,
        radius: 14 + _rng.nextDouble() * 44,
        color: layerFlavor.color,
      ));
    }

    final now = DateTime.now();
    if (now.difference(_lastSpinSoundTime).inMilliseconds >= 240) {
      _lastSpinSoundTime = now;
      HapticFeedback.selectionClick();
      final shouldSpeak =
          !_isFluffReady && _fluffProgress > 0.46 && _fluffProgress < 0.56;
      AudioManager.instance.playCottonSpinStroke(speak: shouldSpeak);
    }

    final prevReady = _isFluffReady;
    _fluffProgress = (_fluffProgress + deltaProgress).clamp(0.14, 1.0);

    if (!prevReady && _fluffProgress >= 1.0) {
      _isFluffReady = true;
      _isSpinning = false;
      _dragHandPos = null;
      _autoSpinCtrl.stop();
      HapticFeedback.heavyImpact();
      AudioManager.instance.playCottonFluffReady();
      _customerBounceCtrl.forward(from: 0.0);
      final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
      _spawnSparkles(
        Offset(size.width / 2, size.height * 0.45),
        includeHearts: true,
        count: 24,
      );
      _setShibaSpeech(
        '🎉 포동포동 솜사탕 완성! 모양·토핑을 꾸미고 손님에게 먹여줘 멍!',
        celebrate: true,
      );
    }
  }

  void _triggerAutoSpin() {
    if (_isFluffReady) {
      _serveBiteToCustomer();
      return;
    }
    _autoSpinCtrl.forward(from: 0.0).whenComplete(() {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _dragHandPos = null;
        });
      }
    });
  }

  void _serveBiteToCustomer() {
    if (!_isFluffReady) {
      _triggerAutoSpin();
      return;
    }
    if (_isFeedingAnimating || _bitesTaken >= 3) return;

    // 1단계: 손님이 "아~" 입을 크게 벌리고 솜사탕 막대기가 손님 입 앞으로 쏙 날아감!
    HapticFeedback.mediumImpact();
    setState(() {
      _isFeedingAnimating = true;
      _isCustomerMouthOpen = true;
      _manualFeedDragOffset = Offset.zero;
    });

    _feedMotionCtrl.forward(from: 0.0);

    // 2단계: 솜사탕이 손님 입에 닿는 순간(260ms) "사르르 앙!" 베어 물고 실제 한 입이 패임!
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _customerBounceCtrl.forward(from: 0.0);

      setState(() {
        _bitesTaken++;
        _isCustomerMouthOpen = false;
      });

      final isFinal = _bitesTaken >= 3;
      AudioManager.instance.playCottonCustomerBite(
        animalId: _currentCustomer.id,
        isFinalBite: isFinal,
      );

      final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
      _spawnSparkles(
        Offset(size.width / 2, size.height * 0.34),
        includeHearts: true,
        count: 24,
      );

      if (!isFinal) {
        final biteReactions = [
          '${_currentCustomer.emoji} "와앙~! 첫 입 베어 물었어요! 구름처럼 달콤해!" (2입 남음)',
          '${_currentCustomer.emoji} "냠냠쩝쩝! 두 입째! 입안에서 사르르 녹아요!" (마지막 1입!)',
        ];
        _setShibaSpeech(
          biteReactions[(_bitesTaken - 1).clamp(0, 1)],
          celebrate: true,
        );
      } else {
        _confettiCtrl.play();
        setState(() {
          _totalStars += 3;
          _servedCount++;
        });
        _setShibaSpeech(
          '💖 우와! ${_currentCustomer.name} 손님이 막대기까지 싹싹 다 먹었어 멍! ⭐+3',
          celebrate: true,
        );
      }
    });

    // 3단계: 막대기가 다시 제자리로 내려오거나, 3입 완식 시 다음 손님 입장
    Future.delayed(const Duration(milliseconds: 620), () {
      if (!mounted) return;
      _feedMotionCtrl.reverse();
      setState(() {
        _isFeedingAnimating = false;
      });

      if (_bitesTaken >= 3) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) _startNewCottonCandy();
        });
      }
    });
  }

  void _startNewCottonCandy() {
    _feedMotionCtrl.reset();
    setState(() {
      _customerIdx++;
      _fluffProgress = 0.14;
      _isFluffReady = false;
      _bitesTaken = 0;
      _isFeedingAnimating = false;
      _isCustomerMouthOpen = false;
      _manualFeedDragOffset = Offset.zero;
      _isSpinning = false;
      _dragHandPos = null;
      _fluffLayers
        ..clear()
        ..add(_activeFlavor);
    });
    _customerBounceCtrl.forward(from: 0.0);
    _setShibaSpeech(
      '${_currentCustomer.emoji} 새로운 ${_currentCustomer.name} 손님이 왔어! 솜사탕을 만들어 줄까 멍? 🍭',
      celebrate: false,
    );
  }

  void _spawnSparkles(
    Offset center, {
    bool includeHearts = false,
    Color? colorOverride,
    int count = 18,
  }) {
    final palette = [
      colorOverride ?? _activeFlavor.color,
      const Color(0xFFFFD54F),
      const Color(0xFFFF4081),
      const Color(0xFF40C4FF),
      const Color(0xFF69F0AE),
    ];
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.0 + _rng.nextDouble() * 5.2;
      _sparkles.add(_SweetSparkle(
        x: center.dx,
        y: center.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2.0,
        size: 7 + _rng.nextDouble() * 7,
        life: 1.0,
        color: palette[i % palette.length],
        rotation: _rng.nextDouble() * pi,
        vRot: (_rng.nextDouble() - 0.5) * 0.18,
        kind: includeHearts && (i % 2 == 0) ? 1 : (i % 3 == 0 ? 0 : 2),
      ));
    }
  }

  void _setShibaSpeech(String text, {required bool celebrate}) {
    _shibaTimer?.cancel();
    setState(() {
      _shibaSpeech = text;
      if (celebrate) _isShibaCelebrating = true;
    });
    if (celebrate) {
      _shibaTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _isShibaCelebrating = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFEEF6),
                Color(0xFFE8F7FF),
                Color(0xFFFFF8E1),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 1. 고급 파스텔 프랑스 디저트 부티크 & 솜사탕 가게 배경
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SweetShopBackgroundPainter(elapsed: _elapsed),
                  ),
                ),
              ),

              // 2. 메인 레이아웃
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    _buildMascotBar(),
                    const SizedBox(height: 6),

                    // 설탕 맛 선택 바 (딸기·레몬·소다·포도·민트·무지개)
                    _buildSugarFlavorBar(),
                    const SizedBox(height: 6),

                    // 메인 3D 솜사탕 카트 & 동물 손님 스테이지
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildCottonMachineStage(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 하단 모양 변경 & 토핑 꾸미기 패널
                    _buildShapeAndToppingPanel(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // 3. 하트·별·설탕결정 파티클 오버레이
              if (_sparkles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SweetSparkleOverlayPainter(sparkles: _sparkles),
                    ),
                  ),
                ),

              // 4. 컨페티
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF80AB), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFFE91E63),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF5F8)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFF80AB), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14880E4F),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍭', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '무지개 솜사탕 가게',
                      style: GoogleFonts.jua(
                        fontSize: 16.5,
                        color: const Color(0xFF880E4F),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFFFFB74D), width: 1.2),
                    ),
                    child: Text(
                      '판매 $_servedCount',
                      style: GoogleFonts.jua(
                        fontSize: 11.5,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF80AB), Color(0xFFD81B60)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '⭐ $_totalStars',
              style: GoogleFonts.jua(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playVoice('audio/voice_cotton_intro.wav');
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: RiveAnimation.asset(
                  'assets/rive/dog.riv',
                  artboard: 'Shiba',
                  animations: [
                    _isShibaCelebrating ? 'WinEndState' : 'Anim_shiba'
                  ],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF80AB), width: 1.5),
              ),
              child: Text(
                _shibaSpeech,
                style: GoogleFonts.jua(
                  fontSize: 12.5,
                  color: const Color(0xFF880E4F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugarFlavorBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ..._flavors.map((fl) {
            final isSelected = _activeFlavor.id == fl.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _selectFlavor(fl),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: [fl.color, fl.deepColor])
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.white : fl.color,
                      width: isSelected ? 2.2 : 1.5,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: fl.deepColor.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fl.emoji, style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 4),
                      Text(
                        '${fl.name} 설탕',
                        style: GoogleFonts.jua(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4E342E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: _addRainbowSugar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF4081),
                    Color(0xFFFFB300),
                    Color(0xFF00B0FF),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FF4081),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌈', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '5색 무지개 설탕',
                    style: GoogleFonts.jua(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCottonMachineStage() {
    final cust = _currentCustomer;
    final pct = ((_fluffProgress - 0.14) / 0.86 * 100).round().clamp(0, 100);

    return Container(
      constraints: const BoxConstraints(maxWidth: 405),
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFFF7FA),
            Color(0xFFFFEEF4),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFFF80AB), width: 4.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD81B60),
            offset: Offset(0, 6),
            blurRadius: 0,
          ),
          BoxShadow(
            color: Color(0x26880E4F),
            offset: Offset(0, 14),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 상단 동물 손님 테이블 & 실시간 리액션 (입 벌리기·볼에 묻은 솜사탕·3입 하트 게이지)
          GestureDetector(
            onTap: _serveBiteToCustomer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isFluffReady
                      ? const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)]
                      : const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _isFluffReady
                      ? const Color(0xFF43A047)
                      : const Color(0xFFFFB74D),
                  width: 2.2,
                ),
              ),
              child: Row(
                children: [
                  // 손님 캐릭터 빅 아바타 (먹여줄 때 입을 "아~" 벌리고 볼에 솜사탕이 묻음!)
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_customerBounceCtrl, _feedMotionCtrl]),
                    builder: (context, child) {
                      final jump =
                          -sin(_customerBounceCtrl.value * pi) * 9.0;
                      final leanScale =
                          1.0 + _feedMotionCtrl.value * 0.14;
                      return Transform.translate(
                        offset: Offset(0, jump),
                        child: Transform.scale(
                          scale: leanScale,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            _bitesTaken > 0
                                ? const Color(0xFFFFCDD2)
                                : const Color(0xFFFFF9C4),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isCustomerMouthOpen
                              ? const Color(0xFFFF4081)
                              : const Color(0xFFFF80AB),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            cust.emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                          // 먹여줄 때 "아~" 크게 벌린 입 표시
                          if (_isCustomerMouthOpen)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 18,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD81B60),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          // 한 입 이상 먹으면 양 볼에 달콤한 솜사탕 크림이 묻음!
                          if (_bitesTaken > 0) ...[
                            Positioned(
                              left: 4,
                              bottom: 14,
                              child: Container(
                                width: 12,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: _activeFlavor.color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 14,
                              child: Container(
                                width: 12,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: _activeFlavor.color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                          ],
                          if (_bitesTaken >= 3)
                            const Positioned(
                              top: -10,
                              child:
                                  Text('👑', style: TextStyle(fontSize: 20)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 손님 대사 & 3입 냠냠 하트 게이지
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${cust.name} 손님',
                                style: GoogleFonts.jua(
                                  fontSize: 14,
                                  color: const Color(0xFF4E342E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (_isFluffReady)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (i) {
                                  final eaten = i < _bitesTaken;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    child: Text(
                                      eaten ? '💖' : '🍭',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEC407A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '감기 $pct%',
                                  style: GoogleFonts.jua(
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isCustomerMouthOpen
                              ? '😮 "아~~ 앙!" (맛있게 받아먹는 중!)'
                              : (_bitesTaken >= 3
                                  ? '😍 "와아~ 싹싹 다 먹었어요! 최고예요! ⭐+3"'
                                  : (_bitesTaken > 0
                                      ? '😋 "사르르 녹아요! 한 입 더 주세요!" (${3 - _bitesTaken}입 남음)'
                                      : (_isFluffReady
                                          ? '🍭 완성! 버튼을 누르거나 손님 입으로 끌어다 주세요!'
                                          : '💬 "${cust.orderLine}"'))),
                          style: GoogleFonts.jua(
                            fontSize: 11.5,
                            color: _isFluffReady
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF795548),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. 중앙 3D 빈티지 황동·에나멜 솜사탕 카트 & 막대기 드래그/먹여주기 영역
          GestureDetector(
            onTap: () {
              if (_isFluffReady) {
                _serveBiteToCustomer();
              } else {
                _triggerAutoSpin();
              }
            },
            onPanStart: (details) {
              if (_isFluffReady) {
                setState(() {
                  _isCustomerMouthOpen = true;
                });
              } else {
                setState(() {
                  _isSpinning = true;
                  _dragHandPos = details.localPosition;
                });
              }
            },
            onPanUpdate: (details) {
              if (_isFluffReady) {
                setState(() {
                  _manualFeedDragOffset += details.delta;
                });
                // 손님 입 쪽(위쪽)으로 45px 이상 끌어올리면 즉시 "앙!" 받아먹음!
                if (_manualFeedDragOffset.dy < -45 && !_isFeedingAnimating) {
                  _serveBiteToCustomer();
                }
                return;
              }
              setState(() {
                _dragHandPos = details.localPosition;
              });
              final dist = details.delta.distance;
              _advanceSpin(dist * 0.0024, fromDrag: true);
            },
            onPanEnd: (_) {
              setState(() {
                _isSpinning = false;
                _dragHandPos = null;
                _isCustomerMouthOpen = false;
                _manualFeedDragOffset = Offset.zero;
              });
            },
            onPanCancel: () {
              setState(() {
                _isSpinning = false;
                _dragHandPos = null;
                _isCustomerMouthOpen = false;
                _manualFeedDragOffset = Offset.zero;
              });
            },
            child: SizedBox(
              width: 265,
              height: 238,
              child: CustomPaint(
                painter: _CottonCandyMachinePainter(
                  fluffLayers: _fluffLayers,
                  activeFlavor: _activeFlavor,
                  shapeType: _selectedShape,
                  equippedToppings: _equippedToppings.toList(),
                  fluffProgress: _fluffProgress,
                  isFluffReady: _isFluffReady,
                  bitesTaken: _bitesTaken,
                  feedProgress: _feedMotionCtrl.value,
                  manualFeedOffset: _manualFeedDragOffset,
                  stickOrbitAngle: _stickOrbitAngle,
                  isSpinning: _isSpinning,
                  dragHandPos: _dragHandPos,
                  threads: _threads,
                  elapsed: _elapsed,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. 하단 액션 버튼 (Flexible/Expanded 구조로 어떤 화면 폭에서도 깨짐 방지!)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap:
                      _isFluffReady ? _serveBiteToCustomer : _triggerAutoSpin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isFluffReady
                            ? const [Color(0xFF66BB6A), Color(0xFF388E3C)]
                            : const [Color(0xFFFF4081), Color(0xFFC51162)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33C51162),
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isFluffReady ? cust.emoji : '🌪️',
                          style: const TextStyle(fontSize: 17),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isFluffReady
                                ? '${cust.name}에게 냠냠 먹여주기!'
                                : '빙글빙글 솜사탕 감기!',
                            style: GoogleFonts.jua(
                              fontSize: 15,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isFluffReady) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _startNewCottonCandy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '새로 만들기',
                      style:
                          GoogleFonts.jua(fontSize: 13.5, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShapeAndToppingPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18795548),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  '모양: ',
                  style: GoogleFonts.jua(
                      fontSize: 12, color: const Color(0xFF6D4C41)),
                ),
                ...CottonShapeType.values.map((sh) {
                  final selected = _selectedShape == sh;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioManager.instance.playChime();
                        setState(() => _selectedShape = sh);
                        _setShibaSpeech(
                          '짜잔! ${sh.desc} 솜사탕으로 변신했어 멍! ✨',
                          celebrate: true,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFF4081)
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : const Color(0xFFFFE082),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          sh.label,
                          style: GoogleFonts.jua(
                            fontSize: 12,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  '토핑: ',
                  style: GoogleFonts.jua(
                      fontSize: 12, color: const Color(0xFF6D4C41)),
                ),
                ..._toppings.map((tp) {
                  final active = _equippedToppings.contains(tp.emoji);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        AudioManager.instance.playDecalStamp();
                        setState(() {
                          if (active) {
                            _equippedToppings.remove(tp.emoji);
                          } else {
                            _equippedToppings.add(tp.emoji);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFFCA28)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? const Color(0xFFFF8F00)
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${tp.emoji} ${tp.label}',
                          style: GoogleFonts.jua(
                            fontSize: 11.5,
                            color: const Color(0xFF4E342E),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Luxury 3D Vintage Brass & Enamel Cotton Candy Cart + Fluffy Cloud Painter
// ─────────────────────────────────────────────────────────────────────────────

class _CottonCandyMachinePainter extends CustomPainter {
  final List<_SugarFlavor> fluffLayers;
  final _SugarFlavor activeFlavor;
  final CottonShapeType shapeType;
  final List<String> equippedToppings;
  final double fluffProgress;
  final bool isFluffReady;
  final int bitesTaken;
  final double feedProgress;
  final Offset manualFeedOffset;
  final double stickOrbitAngle;
  final bool isSpinning;
  final Offset? dragHandPos;
  final List<_SugarThreadParticle> threads;
  final double elapsed;

  _CottonCandyMachinePainter({
    required this.fluffLayers,
    required this.activeFlavor,
    required this.shapeType,
    required this.equippedToppings,
    required this.fluffProgress,
    required this.isFluffReady,
    required this.bitesTaken,
    required this.feedProgress,
    required this.manualFeedOffset,
    required this.stickOrbitAngle,
    required this.isSpinning,
    required this.dragHandPos,
    required this.threads,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bowlCenter = Offset(w * 0.5, h * 0.62);

    // 0. 투명 아크릴 보호 돔 가드 (상단 반구 유리창)
    final domeRect =
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.52), width: w * 0.86, height: h * 0.56);
    canvas.drawArc(
      domeRect,
      pi,
      pi,
      false,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.55),
            const Color(0xFFE1F5FE).withValues(alpha: 0.18),
          ],
        ).createShader(domeRect),
    );
    canvas.drawArc(
      domeRect,
      pi,
      pi,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 1. 빈티지 솜사탕 카트 본체 & 황금 바퀴 (하단)
    _drawVintageCartBase(canvas, size);

    // 2. 3D 에나멜 회전 볼 (Machine Bowl)
    final bowlOuterRect =
        Rect.fromCenter(center: bowlCenter, width: w * 0.90, height: h * 0.38);
    // 볼 하단 입체 두께(립)
    canvas.drawOval(
      bowlOuterRect.shift(const Offset(0, 7)),
      Paint()..color = const Color(0xFFC2185B),
    );
    canvas.drawOval(
      bowlOuterRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF8BBD0),
            Color(0xFFF06292),
          ],
        ).createShader(bowlOuterRect),
    );

    // 볼 안쪽 오목한 회전 팬 & 설탕 소용돌이
    final innerBowlRect =
        Rect.fromCenter(center: bowlCenter, width: w * 0.78, height: h * 0.28);
    canvas.drawOval(
      innerBowlRect,
      Paint()
        ..shader = const RadialGradient(
          colors: [
            Color(0xFF4A148C),
            Color(0xFF880E4F),
            Color(0xFFAD1457),
          ],
        ).createShader(innerBowlRect),
    );

    // 볼 안쪽에서 빙글빙글 도는 파스텔 설탕 실 소용돌이 링
    for (int i = 1; i <= 3; i++) {
      final ringW = w * (0.22 + i * 0.16);
      final ringH = h * (0.07 + i * 0.055);
      final ringFlavor = fluffLayers[i % fluffLayers.length];
      canvas.drawArc(
        Rect.fromCenter(center: bowlCenter, width: ringW, height: ringH),
        elapsed * 4.0 + i * 1.2,
        2.2,
        false,
        Paint()
          ..color = ringFlavor.color.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // 볼 크롬 골드 테두리
    canvas.drawOval(
      bowlOuterRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 3. 중앙 황동 설탕 회전 헤드 (Brass Spinner Head)
    final headRect =
        Rect.fromCenter(center: bowlCenter, width: 48, height: 24);
    canvas.drawOval(
      headRect.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFFE65100),
    );
    canvas.drawOval(
      headRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF59D), Color(0xFFFFCA28), Color(0xFFFF8F00)],
        ).createShader(headRect),
    );
    canvas.drawOval(
      Rect.fromCenter(center: bowlCenter, width: 24, height: 12),
      Paint()..color = activeFlavor.color,
    );

    // 4. 회전 중 뿜어져 나오는 명주실 설탕 가닥들
    for (final th in threads) {
      final tx = bowlCenter.dx + cos(th.angle) * th.radius;
      final ty = bowlCenter.dy + sin(th.angle) * (th.radius * 0.45);
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(tx, ty),
            width: th.radius * 0.95,
            height: th.radius * 0.5),
        th.angle,
        1.5,
        false,
        Paint()
          ..color = th.color.withValues(alpha: (th.life * 0.78).clamp(0.0, 1.0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5. 나무 막대기 & 포동포동 3D 다층 솜사탕 구름 (먹여주기 시 상단 손님 입으로 쏙 올라감!)
    final orbitX = isFluffReady ? 0.0 : cos(stickOrbitAngle) * 22.0;
    final orbitY = isFluffReady ? -12.0 : sin(stickOrbitAngle) * 7.5;

    // 먹여주기 버튼 클릭 시 상단 좌측의 손님 아바타 입 쪽으로 솜사탕이 직접 이동하며 기울어짐!
    final feedDx = -w * 0.24 * feedProgress + manualFeedOffset.dx * 0.65;
    final feedDy = -h * 0.36 * feedProgress + manualFeedOffset.dy * 0.65;
    final feedTilt = -0.35 * feedProgress;

    final candyCenter =
        Offset(w * 0.5 + orbitX + feedDx, h * 0.40 + orbitY + feedDy);

    canvas.save();
    canvas.translate(candyCenter.dx, candyCenter.dy);
    canvas.rotate(feedTilt);

    // 입체 원목 막대기
    final stickRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 58), width: 11, height: 92),
      const Radius.circular(5.5),
    );
    canvas.drawRRect(
      stickRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFD7A86E), Color(0xFFA67B44)],
        ).createShader(stickRect.outerRect),
    );

    // 먹여주는 동안 막대기를 잡고 건네주는 손(🤚) 표시
    if (feedProgress > 0.05 || manualFeedOffset.distance > 6 || bitesTaken > 0) {
      final handTp = TextPainter(
        text: const TextSpan(
          text: '🤚',
          style: TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      handTp.paint(canvas, Offset(-handTp.width / 2 + 8, 56));
    }

    // 3입을 다 먹었을 때: 빈 막대기에 달콤한 솜사탕 부스러기와 '다 먹었어요!' 표시
    if (bitesTaken >= 3) {
      for (final dy in [-12.0, 2.0, 14.0]) {
        canvas.drawCircle(
          Offset(0, dy),
          6.5,
          Paint()..color = activeFlavor.color.withValues(alpha: 0.75),
        );
      }
      final doneTp = TextPainter(
        text: TextSpan(
          text: '😋 완식! ⭐+3',
          style: GoogleFonts.jua(
            fontSize: 15,
            color: const Color(0xFFD81B60),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      doneTp.paint(canvas, Offset(-doneTp.width / 2, -38));
      canvas.restore();
      return;
    }

    final baseRadius = 25.0 + fluffProgress * 55.0;

    // 외곽 몽실몽실 솜사탕 포근한 빛 번짐 (Cotton Floss Halo)
    canvas.drawCircle(
      Offset.zero,
      baseRadius * 1.08,
      Paint()
        ..color = activeFlavor.color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 실제 베어 먹은 이빨 자국(Scalloped Bite Marks) 클리핑!
    // 1입 먹으면 오른쪽 위가 움푹 패이고, 2입 먹으면 왼쪽 위까지 움푹 패임!
    if (bitesTaken > 0) {
      Path fullArea = Path()
        ..addRect(Rect.fromCircle(center: Offset.zero, radius: baseRadius * 2.2));

      // 1번째 베어 문 자국 (우상단 물결 모양 한 입)
      final bite1 = Path()
        ..addOval(Rect.fromCircle(
            center: Offset(baseRadius * 0.58, -baseRadius * 0.48),
            radius: baseRadius * 0.56))
        ..addOval(Rect.fromCircle(
            center: Offset(baseRadius * 0.32, -baseRadius * 0.72),
            radius: baseRadius * 0.44))
        ..addOval(Rect.fromCircle(
            center: Offset(baseRadius * 0.78, -baseRadius * 0.18),
            radius: baseRadius * 0.44));
      fullArea = Path.combine(PathOperation.difference, fullArea, bite1);

      if (bitesTaken >= 2) {
        // 2번째 베어 문 자국 (좌상단까지 크게 한 입 더!)
        final bite2 = Path()
          ..addOval(Rect.fromCircle(
              center: Offset(-baseRadius * 0.55, -baseRadius * 0.45),
              radius: baseRadius * 0.58))
          ..addOval(Rect.fromCircle(
              center: Offset(-baseRadius * 0.25, -baseRadius * 0.72),
              radius: baseRadius * 0.46))
          ..addOval(Rect.fromCircle(
              center: Offset(-baseRadius * 0.76, -baseRadius * 0.12),
              radius: baseRadius * 0.46));
        fullArea = Path.combine(PathOperation.difference, fullArea, bite2);
      }

      canvas.clipPath(fullArea);
    }

    // 모양별 귀/장식 베이스
    _drawShapeEarsOrBase(canvas, baseRadius);

    // 다층 파스텔 구름 퍼프 렌더링
    final layerCount = fluffLayers.length;
    for (int l = 0; l < layerCount; l++) {
      final flavor = fluffLayers[l];
      final layerRatio = 1.0 - (l * 0.14);
      final r = baseRadius * layerRatio;
      _drawFluffyCloudLayer(canvas, r, flavor.color, flavor.lightColor, l);
    }

    // 솜사탕 결 스월(Swirl) 하이라이트
    final swirlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: baseRadius * 0.58),
      -2.2,
      1.8,
      false,
      swirlPaint,
    );

    // 귀여운 초콜릿 눈·볼터치·미소 표정
    if (fluffProgress >= 0.40) {
      _drawKawaiiCandyFace(canvas, baseRadius * 0.72);
    }

    // 장착된 토핑 및 무지개 스프링클
    _drawEquippedToppings(canvas, baseRadius);

    canvas.restore();

    // 6. 손가락으로 감고 있을 때 따라다니는 손(👋) 커서
    if (dragHandPos != null && !isFluffReady) {
      final hp = dragHandPos!;
      final tp = TextPainter(
        text: const TextSpan(
          text: '👋',
          style: TextStyle(fontSize: 32),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(hp.dx - tp.width / 2, hp.dy - tp.height / 2));
    }
  }

  void _drawVintageCartBase(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 카트 몸통
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.84), width: w * 0.66, height: h * 0.24),
      const Radius.circular(18),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF80AB), Color(0xFFEC407A), Color(0xFFC2185B)],
        ).createShader(baseRect.outerRect),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 카트 전면 골드 계기판 (달콤 게이지 & 버튼 램프)
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.85), width: w * 0.44, height: h * 0.13),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      panelRect,
      Paint()..color = const Color(0xFFFFF8E1),
    );
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = const Color(0xFFFFB300)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 계기판 미니 램프 3개
    final lampColors = [
      const Color(0xFFFF4081),
      const Color(0xFFFFCA28),
      const Color(0xFF00E676),
    ];
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(w * (0.40 + i * 0.10), h * 0.85),
        5.5,
        Paint()..color = lampColors[i],
      );
      canvas.drawCircle(
        Offset(w * (0.40 + i * 0.10) - 1.5, h * 0.85 - 1.5),
        1.8,
        Paint()..color = Colors.white,
      );
    }

    // 좌·우 황금 마차 바퀴 (Vintage Spoked Cart Wheels)
    for (final wx in [w * 0.18, w * 0.82]) {
      final wc = Offset(wx, h * 0.88);
      const wr = 19.0;
      canvas.drawCircle(
        wc,
        wr,
        Paint()
          ..color = const Color(0xFFFFB300)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0,
      );
      for (int s = 0; s < 4; s++) {
        final a = s * pi / 4 + (isSpinning ? elapsed * 5 : 0);
        canvas.drawLine(
          Offset(wc.dx - cos(a) * wr, wc.dy - sin(a) * wr),
          Offset(wc.dx + cos(a) * wr, wc.dy + sin(a) * wr),
          Paint()
            ..color = const Color(0xFFFFCA28)
            ..strokeWidth = 2.0,
        );
      }
      canvas.drawCircle(wc, 5.0, Paint()..color = const Color(0xFFD81B60));
    }
  }

  void _drawShapeEarsOrBase(Canvas canvas, double r) {
    final mainFlavor = fluffLayers.first;
    final earPaint = Paint()..color = mainFlavor.color;
    final innerEarPaint = Paint()..color = mainFlavor.lightColor;

    if (shapeType == CottonShapeType.rabbit) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * 0.42, -r * 0.92),
            width: r * 0.44,
            height: r * 0.95),
        earPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.42, -r * 0.92),
            width: r * 0.44,
            height: r * 0.95),
        earPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-r * 0.42, -r * 0.92),
            width: r * 0.22,
            height: r * 0.60),
        innerEarPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(r * 0.42, -r * 0.92),
            width: r * 0.22,
            height: r * 0.60),
        innerEarPaint,
      );
    } else if (shapeType == CottonShapeType.bear) {
      canvas.drawCircle(Offset(-r * 0.68, -r * 0.62), r * 0.36, earPaint);
      canvas.drawCircle(Offset(r * 0.68, -r * 0.62), r * 0.36, earPaint);
      canvas.drawCircle(Offset(-r * 0.68, -r * 0.62), r * 0.18, innerEarPaint);
      canvas.drawCircle(Offset(r * 0.68, -r * 0.62), r * 0.18, innerEarPaint);
    }
  }

  void _drawFluffyCloudLayer(
    Canvas canvas,
    double r,
    Color color,
    Color lightColor,
    int seedOffset,
  ) {
    final puffPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.95,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          lightColor,
          color,
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 1.15));

    if (shapeType == CottonShapeType.heart) {
      final path = Path()
        ..moveTo(0, r * 0.88)
        ..cubicTo(-r * 1.25, r * 0.15, -r * 1.0, -r * 0.95, 0, -r * 0.38)
        ..cubicTo(r * 1.0, -r * 0.95, r * 1.25, r * 0.15, 0, r * 0.88)
        ..close();
      canvas.drawPath(path, puffPaint);
      return;
    }

    if (shapeType == CottonShapeType.star) {
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final a1 = -pi / 2 + (2 * pi * i / 5);
        final a2 = a1 + pi / 5;
        final p1 = Offset(cos(a1) * r * 1.08, sin(a1) * r * 1.08);
        final p2 = Offset(cos(a2) * r * 0.62, sin(a2) * r * 0.62);
        if (i == 0) {
          path.moveTo(p1.dx, p1.dy);
        } else {
          path.lineTo(p1.dx, p1.dy);
        }
        path.lineTo(p2.dx, p2.dy);
      }
      path.close();
      canvas.drawPath(path, puffPaint);
      return;
    }

    const int puffs = 8;
    for (int i = 0; i < puffs; i++) {
      final angle = (2 * pi * i / puffs) + seedOffset * 0.35;
      final px = cos(angle) * r * 0.52;
      final py = sin(angle) * r * 0.44;
      canvas.drawCircle(Offset(px, py), r * 0.54, puffPaint);
    }
    canvas.drawCircle(Offset.zero, r * 0.74, puffPaint);
  }

  void _drawKawaiiCandyFace(Canvas canvas, double r) {
    final chocoPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.fill;
    final blushPaint = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.45);

    final eyeX = r * 0.36;
    canvas.drawCircle(Offset(-eyeX, -4), 5.2, chocoPaint);
    canvas.drawCircle(Offset(eyeX, -4), 5.2, chocoPaint);
    canvas.drawCircle(
        Offset(-eyeX - 1.5, -5.5), 2.0, Paint()..color = Colors.white);
    canvas.drawCircle(
        Offset(eyeX - 1.5, -5.5), 2.0, Paint()..color = Colors.white);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(-eyeX * 1.35, 6), width: 14, height: 7.5),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(eyeX * 1.35, 6), width: 14, height: 7.5),
      blushPaint,
    );

    final smilePath = Path()
      ..moveTo(-7, 4)
      ..quadraticBezierTo(0, 12, 7, 4);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEquippedToppings(Canvas canvas, double r) {
    if (equippedToppings.contains('🌈')) {
      const spColors = [
        Color(0xFFFF4081),
        Color(0xFFFFCA28),
        Color(0xFF00E676),
        Color(0xFF29B6F6),
        Color(0xFFAB47BC),
      ];
      for (int i = 0; i < 16; i++) {
        final a = i * 1.85;
        final dist = r * (0.28 + (i % 3) * 0.20);
        canvas.save();
        canvas.translate(cos(a) * dist, sin(a) * dist * 0.8);
        canvas.rotate(a);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 9, height: 4),
            const Radius.circular(2),
          ),
          Paint()..color = spColors[i % spColors.length],
        );
        canvas.restore();
      }
    }

    final decorations =
        equippedToppings.where((e) => e != '🌈').toList(growable: false);
    final offsets = [
      Offset(-r * 0.55, -r * 0.45),
      Offset(r * 0.55, -r * 0.45),
      Offset(-r * 0.60, r * 0.35),
      Offset(r * 0.60, r * 0.35),
    ];
    for (int i = 0; i < decorations.length && i < offsets.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: decorations[i],
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
            offsets[i].dx - tp.width / 2, offsets[i].dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CottonCandyMachinePainter oldDelegate) => true;
}

/// 고급 프랑스 디저트 부티크 & 파스텔 캔디 하우스 배경 페인터
/// (3D 스캘럽 어닝 차양막 + 파스텔 스트라이프 벽지 + 미소 짓는 솜사탕 구름 + 마카롱/풍선/반짝이 별 + 파스텔 언덕)
class _SweetShopBackgroundPainter extends CustomPainter {
  final double elapsed;

  _SweetShopBackgroundPainter({required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 은은한 파스텔 부티크 세로 스트라이프 & 도트 벽지
    const stripeCount = 12;
    final sw = w / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(i * sw, 0, sw, h),
          Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.07),
        );
      }
    }

    // 2. 상단 3D 스캘럽 부티크 어닝(Awning) 지붕 + 골드 레이스 트림
    for (int i = 0; i < stripeCount; i++) {
      final isPink = i.isEven;
      final awningPath = Path()
        ..moveTo(i * sw, 0)
        ..lineTo((i + 1) * sw, 0)
        ..lineTo((i + 1) * sw, 26)
        ..quadraticBezierTo((i + 0.5) * sw, 42, i * sw, 26)
        ..close();

      // 그림자
      canvas.drawPath(
        awningPath.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x18880E4F),
      );
      // 어닝 컬러
      canvas.drawPath(
        awningPath,
        Paint()
          ..color = isPink
              ? const Color(0xFFFF80AB).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.85),
      );
      // 어닝 끝 골드 진주 방울
      canvas.drawCircle(
        Offset((i + 0.5) * sw, 35),
        3.0,
        Paint()..color = const Color(0xFFFFCA28),
      );
    }

    // 3. 좌·우에 둥실둥실 떠다니는 미소 짓는 솜사탕 구름
    _drawSmilingCandyCloud(
      canvas,
      Offset(w * 0.14, h * 0.17 + sin(elapsed * 1.5) * 5),
      80,
      42,
      const Color(0xFFFFF0F6),
    );
    _drawSmilingCandyCloud(
      canvas,
      Offset(w * 0.86, h * 0.21 + cos(elapsed * 1.5) * 5),
      74,
      38,
      const Color(0xFFE1F5FE),
    );

    // 4. 배경에 둥실둥실 떠다니는 파스텔 마카롱 & 사탕 버블 (좌·우 가장자리)
    _drawFloatingCandyBubble(
      canvas,
      Offset(w * 0.07, h * 0.38 + sin(elapsed * 2.0) * 6),
      const Color(0xFFFF80AB),
      13,
    );
    _drawFloatingCandyBubble(
      canvas,
      Offset(w * 0.93, h * 0.36 + cos(elapsed * 2.0 + 1.2) * 6),
      const Color(0xFF4FC3F7),
      14,
    );
    _drawFloatingCandyBubble(
      canvas,
      Offset(w * 0.08, h * 0.68 + cos(elapsed * 1.8 + 2.0) * 5),
      const Color(0xFFFFD54F),
      12,
    );
    _drawFloatingCandyBubble(
      canvas,
      Offset(w * 0.92, h * 0.66 + sin(elapsed * 1.9 + 1.5) * 5),
      const Color(0xFFCE93D8),
      13,
    );

    // 5. 반짝이는 4포인트 별들
    _drawTwinkleStar(
      canvas,
      Offset(w * 0.11, h * 0.28),
      12 + sin(elapsed * 3) * 2,
      const Color(0xFFFFCA28),
    );
    _drawTwinkleStar(
      canvas,
      Offset(w * 0.89, h * 0.30),
      11 + cos(elapsed * 3) * 2,
      const Color(0xFFFF80AB),
    );
    _drawTwinkleStar(
      canvas,
      Offset(w * 0.10, h * 0.78),
      10,
      const Color(0xFF4FC3F7),
    );
    _drawTwinkleStar(
      canvas,
      Offset(w * 0.90, h * 0.79),
      11,
      const Color(0xFFBA68C8),
    );

    // 6. 하단 파스텔 동화 언덕 2겹
    final hill1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 88)
      ..quadraticBezierTo(w * 0.35, h - 126, w * 0.74, h - 76)
      ..quadraticBezierTo(w * 0.90, h - 55, w, h - 70)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      hill1,
      Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.42),
    );

    final hill2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 48)
      ..quadraticBezierTo(w * 0.28, h - 72, w * 0.62, h - 42)
      ..quadraticBezierTo(w * 0.84, h - 24, w, h - 40)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      hill2,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.55),
    );
  }

  void _drawSmilingCandyCloud(
      Canvas canvas, Offset center, double w, double h, Color tint) {
    final p = Paint()..color = tint.withValues(alpha: 0.92);
    final r = h / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawCircle(Offset(-w * 0.22, 0), r * 0.85, p);
    canvas.drawCircle(Offset(0, -r * 0.28), r * 1.05, p);
    canvas.drawCircle(Offset(w * 0.24, 0), r * 0.8, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, r * 0.2), width: w * 0.85, height: r * 0.85),
        Radius.circular(r * 0.5),
      ),
      p,
    );
    // 귀여운 눈웃음
    final eyePaint = Paint()
      ..color = const Color(0xFF880E4F).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
        const Rect.fromLTWH(-11, -2, 6, 5), pi, pi, false, eyePaint);
    canvas.drawArc(
        const Rect.fromLTWH(5, -2, 6, 5), pi, pi, false, eyePaint);
    canvas.restore();
  }

  void _drawFloatingCandyBubble(
      Canvas canvas, Offset center, Color color, double r) {
    canvas.drawCircle(
      center,
      r,
      Paint()..color = color.withValues(alpha: 0.38),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(center.dx - r * 0.3, center.dy - r * 0.3),
      r * 0.26,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawTwinkleStar(
      Canvas canvas, Offset center, double size, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final r = size / 2;
    final path = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..quadraticBezierTo(0, 0, 0, r)
      ..quadraticBezierTo(0, 0, -r, 0)
      ..quadraticBezierTo(0, 0, 0, -r)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.82));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SweetShopBackgroundPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}

class _SweetSparkleOverlayPainter extends CustomPainter {
  final List<_SweetSparkle> sparkles;

  _SweetSparkleOverlayPainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      if (s.life <= 0) continue;
      final alpha = s.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = s.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rotation);

      if (s.kind == 1) {
        // 하트 파티클
        final r = s.size * 0.8;
        final hp = Path()
          ..moveTo(0, r * 0.7)
          ..cubicTo(-r * 1.1, r * 0.1, -r * 0.9, -r * 0.8, 0, -r * 0.3)
          ..cubicTo(r * 0.9, -r * 0.8, r * 1.1, r * 0.1, 0, r * 0.7)
          ..close();
        canvas.drawPath(hp, paint);
      } else {
        canvas.drawCircle(Offset.zero, s.size * 0.55, paint);
        canvas.drawCircle(
          Offset(-s.size * 0.16, -s.size * 0.16),
          s.size * 0.2,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SweetSparkleOverlayPainter oldDelegate) => true;
}
