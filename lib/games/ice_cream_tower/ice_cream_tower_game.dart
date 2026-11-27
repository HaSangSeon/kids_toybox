import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ice Cream Tower Game — 차곡차곡 아이스크림 타워! (6~7세 척척 도전 놀이)
// 아기자기한 파스텔 젤라또 가게에서 동물 손님의 주문서를 보고
// 바삭한 와플 콘을 움직여 스쿱·시럽·토핑을 차곡차곡 쌓아 서빙하는 3D 밸런스 타이쿤
// ─────────────────────────────────────────────────────────────────────────────

class _IceCreamFlavor {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color lightColor;
  final Color darkColor;
  final Color chipColor;

  const _IceCreamFlavor({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.darkColor,
    required this.chipColor,
  });
}

class _GelatoCustomer {
  final String id;
  final String name;
  final String emoji;
  final Color badgeColor;

  const _GelatoCustomer({
    required this.id,
    required this.name,
    required this.emoji,
    required this.badgeColor,
  });
}

class _FallingItem {
  final _IceCreamFlavor flavor;
  final bool isTopping;
  final bool isObstacle; // 🧊 차가운 얼음
  final bool isRainbowBonus;
  double normX; // 0.14 ~ 0.86
  double normY; // 0.0 ~ 1.0
  double speed;
  double wobblePhase;

  _FallingItem({
    required this.flavor,
    required this.normX,
    required this.normY,
    required this.speed,
    this.isTopping = false,
    this.isObstacle = false,
    this.isRainbowBonus = false,
    this.wobblePhase = 0.0,
  });
}

class _StackedScoop {
  final _IceCreamFlavor flavor;
  final bool isTopping;
  final bool isPerfect;
  final bool hasSyrup;
  final double offsetX; // 콘 중심 대비 약간 어긋나게 쌓인 오프셋
  double squish; // 착지 순간 말랑하게 눌리는 애니메이션 값

  _StackedScoop({
    required this.flavor,
    required this.offsetX,
    this.isTopping = false,
    this.isPerfect = false,
    this.hasSyrup = false,
    this.squish = 0.28,
  });
}

class _SplashParticle {
  double x; // 0.0 ~ 1.0
  double y; // 0.0 ~ 1.0
  double vx;
  double vy;
  double life; // 1.0 -> 0.0
  final Color color;
  final double radius;

  _SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.radius,
  }) : life = 1.0;
}

class _FloatingPopup {
  double x;
  double y;
  double life; // 1.0 -> 0.0
  final String text;
  final Color color;

  _FloatingPopup({
    required this.x,
    required this.y,
    required this.text,
    required this.color,
  }) : life = 1.0;
}

class IceCreamTowerGame extends StatefulWidget {
  const IceCreamTowerGame({super.key});

  @override
  State<IceCreamTowerGame> createState() => _IceCreamTowerGameState();
}

class _IceCreamTowerGameState extends State<IceCreamTowerGame>
    with TickerProviderStateMixin {
  static const List<_IceCreamFlavor> _flavors = [
    _IceCreamFlavor(
      id: 'strawberry',
      name: '딸기',
      emoji: '🍓',
      color: Color(0xFFFF6090),
      lightColor: Color(0xFFFCE4EC),
      darkColor: Color(0xFFC2185B),
      chipColor: Color(0xFFAD1457),
    ),
    _IceCreamFlavor(
      id: 'choco',
      name: '초코',
      emoji: '🍫',
      color: Color(0xFF795548),
      lightColor: Color(0xFFD7CCC8),
      darkColor: Color(0xFF3E2723),
      chipColor: Color(0xFF27140E),
    ),
    _IceCreamFlavor(
      id: 'mint',
      name: '민트초코',
      emoji: '🌿',
      color: Color(0xFF26A69A),
      lightColor: Color(0xFFE0F2F1),
      darkColor: Color(0xFF00695C),
      chipColor: Color(0xFF3E2723),
    ),
    _IceCreamFlavor(
      id: 'vanilla',
      name: '바닐라',
      emoji: '🍦',
      color: Color(0xFFFFEE58),
      lightColor: Color(0xFFFFFDE7),
      darkColor: Color(0xFFFBC02D),
      chipColor: Color(0xFFFF8F00),
    ),
    _IceCreamFlavor(
      id: 'mango',
      name: '망고',
      emoji: '🥭',
      color: Color(0xFFFFB300),
      lightColor: Color(0xFFFFF8E1),
      darkColor: Color(0xFFE65100),
      chipColor: Color(0xFFBF360C),
    ),
    _IceCreamFlavor(
      id: 'grape',
      name: '포도',
      emoji: '🍇',
      color: Color(0xFFAB47BC),
      lightColor: Color(0xFFF3E5F5),
      darkColor: Color(0xFF6A1B9A),
      chipColor: Color(0xFF4A148C),
    ),
  ];

  static const _IceCreamFlavor _toppingFlavor = _IceCreamFlavor(
    id: 'topping',
    name: '체리토핑',
    emoji: '🍒',
    color: Color(0xFFFF5252),
    lightColor: Color(0xFFFFCDD2),
    darkColor: Color(0xFFB71C1C),
    chipColor: Color(0xFF880E4F),
  );

  static const _IceCreamFlavor _rainbowFlavor = _IceCreamFlavor(
    id: 'rainbow',
    name: '레인보우',
    emoji: '🌈',
    color: Color(0xFFFF4081),
    lightColor: Color(0xFFFFF59D),
    darkColor: Color(0xFF7C4DFF),
    chipColor: Color(0xFF00E5FF),
  );

  static const _IceCreamFlavor _iceObstacleFlavor = _IceCreamFlavor(
    id: 'ice',
    name: '얼음',
    emoji: '🧊',
    color: Color(0xFF81D4FA),
    lightColor: Color(0xFFE1F5FE),
    darkColor: Color(0xFF0288D1),
    chipColor: Color(0xFF01579B),
  );

  static const List<_GelatoCustomer> _customers = [
    _GelatoCustomer(
      id: 'rabbit',
      name: '토끼 손님',
      emoji: '🐰',
      badgeColor: Color(0xFFFF80AB),
    ),
    _GelatoCustomer(
      id: 'bear',
      name: '곰돌이 손님',
      emoji: '🐻',
      badgeColor: Color(0xFFFFB74D),
    ),
    _GelatoCustomer(
      id: 'penguin',
      name: '펭귄 손님',
      emoji: '🐧',
      badgeColor: Color(0xFF4FC3F7),
    ),
    _GelatoCustomer(
      id: 'dog',
      name: '강아지 손님',
      emoji: '🐶',
      badgeColor: Color(0xFFFFD54F),
    ),
    _GelatoCustomer(
      id: 'cat',
      name: '고양이 손님',
      emoji: '🐱',
      badgeColor: Color(0xFFBA68C8),
    ),
    _GelatoCustomer(
      id: 'unicorn',
      name: '유니콘 손님',
      emoji: '🦄',
      badgeColor: Color(0xFF7E57C2),
    ),
  ];

  late ConfettiController _confettiCtrl;
  late Ticker _gameTicker;

  final Random _rng = Random();
  final List<_FallingItem> _fallingItems = [];
  final List<_StackedScoop> _stackedScoops = [];
  final List<_IceCreamFlavor> _orderRecipe = [];
  final List<_SplashParticle> _particles = [];
  final List<_FloatingPopup> _popups = [];

  int _level = 1;
  int _totalStars = 0;
  int _comboCount = 0;
  bool _showingStageClear = false;
  int _tastingBites = 0; // 클리어 팝업에서 손님에게 냠냠 먹여주기 단계 (0~3)

  double _coneX = 0.50; // 0.16 ~ 0.84
  double _moveDir = 0.0;
  double _towerSwayAngle = 0.0;
  double _towerSwayVel = 0.0;
  double _spawnTimer = 0.0;
  double _elapsed = 0.0;
  double _lastDragSoundTime = 0.0;

  // 상단 3D 아이스크림 디스펜서 머신 상태
  double _dispenserX = 0.50;
  double _dispenserTargetX = 0.50;
  double _dispenserSquish = 0.0;
  _IceCreamFlavor _dispenserPreviewFlavor = _flavors[0];

  // 시럽 & 스프링클 부스터 연출
  double _syrupBoostFlash = 0.0;

  // 좌하단 깔끔한 획득 토스트 (플레이 화면을 가리지 않음)
  String? _toastText;
  Timer? _toastTimer;

  String _shibaSpeech = '🎯 표시된 주문 스쿱을 콘으로 차곡차곡 받아봐 멍! 🍦';
  bool _isShibaCelebrating = false;
  Timer? _shibaTimer;

  _GelatoCustomer get _currentCustomer =>
      _customers[(_level - 1) % _customers.length];

  int get _targetScoopCount => min(3 + (_level ~/ 2), 6);

  _IceCreamFlavor? get _nextRequiredFlavor {
    final idx = _stackedScoops.length;
    if (idx < _orderRecipe.length) {
      return _orderRecipe[idx];
    }
    return _toppingFlavor;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 2));

    _setupStage(playIntro: true);

    _gameTicker = createTicker((_) {
      const dt = 0.016;
      _elapsed += dt;
      _updateGame(dt);
    })..start();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _shibaTimer?.cancel();
    _gameTicker.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _setupStage({bool playIntro = false}) {
    _fallingItems.clear();
    _stackedScoops.clear();
    _orderRecipe.clear();
    _particles.clear();
    _popups.clear();
    _showingStageClear = false;
    _tastingBites = 0;
    _comboCount = 0;
    _coneX = 0.50;
    _towerSwayAngle = 0.0;
    _towerSwayVel = 0.0;
    _spawnTimer = 0.35;
    _dispenserX = 0.50;
    _dispenserTargetX = 0.50;
    _dispenserSquish = 0.0;

    final count = _targetScoopCount;
    for (int i = 0; i < count; i++) {
      _orderRecipe.add(_flavors[_rng.nextInt(_flavors.length)]);
    }

    final first = _orderRecipe.first;
    _dispenserPreviewFlavor = first;
    _shibaSpeech =
        '${_currentCustomer.emoji} ${_currentCustomer.name} 주문! 1층은 ${first.emoji}${first.name} 맛이야 멍!';

    setState(() {});

    if (playIntro) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          AudioManager.instance.playVoice('audio/voice_ice_intro.wav');
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) {
          AudioManager.instance.playVoice('audio/voice_ice_order.wav');
        }
      });
    }
  }

  void _spawnNextFallingItem() {
    final needed = _nextRequiredFlavor;
    final needToppingNow = _stackedScoops.length >= _orderRecipe.length;

    final roll = _rng.nextDouble();
    final x = (0.18 + _rng.nextDouble() * 0.64).clamp(0.18, 0.82);
    final baseSpeed = (0.31 + _level * 0.022).clamp(0.31, 0.50);

    _dispenserTargetX = x;
    _dispenserX = x;
    _dispenserSquish = 0.35;
    AudioManager.instance.playIceCreamDispenserPop();

    if (needToppingNow) {
      _dispenserPreviewFlavor = _toppingFlavor;
      _fallingItems.add(_FallingItem(
        flavor: _toppingFlavor,
        normX: x,
        normY: 0.13,
        speed: baseSpeed,
        isTopping: true,
        wobblePhase: _rng.nextDouble() * pi,
      ));
      return;
    }

    if (roll < 0.64 && needed != null) {
      _dispenserPreviewFlavor = needed;
      _fallingItems.add(_FallingItem(
        flavor: needed,
        normX: x,
        normY: 0.13,
        speed: baseSpeed,
        wobblePhase: _rng.nextDouble() * pi,
      ));
    } else if (roll < 0.78) {
      _dispenserPreviewFlavor = _rainbowFlavor;
      _fallingItems.add(_FallingItem(
        flavor: _rainbowFlavor,
        normX: x,
        normY: 0.13,
        speed: baseSpeed * 1.04,
        isRainbowBonus: true,
        wobblePhase: _rng.nextDouble() * pi,
      ));
    } else if (roll < 0.89 || _level == 1) {
      final randomFl = _flavors[_rng.nextInt(_flavors.length)];
      _dispenserPreviewFlavor = randomFl;
      _fallingItems.add(_FallingItem(
        flavor: randomFl,
        normX: x,
        normY: 0.13,
        speed: baseSpeed,
        wobblePhase: _rng.nextDouble() * pi,
      ));
    } else {
      _dispenserPreviewFlavor = _iceObstacleFlavor;
      _fallingItems.add(_FallingItem(
        flavor: _iceObstacleFlavor,
        normX: x,
        normY: 0.13,
        speed: baseSpeed * 1.06,
        isObstacle: true,
        wobblePhase: _rng.nextDouble() * pi,
      ));
    }
  }

  void _spawnSplashParticles({
    required double normX,
    required double normY,
    required Color color,
    int count = 14,
  }) {
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _rng.nextDouble() * 0.4;
      final spd = 0.15 + _rng.nextDouble() * 0.35;
      _particles.add(_SplashParticle(
        x: normX,
        y: normY,
        vx: cos(angle) * spd,
        vy: sin(angle) * spd - 0.18,
        color: i.isEven ? color : const Color(0xFFFFD54F),
        radius: 3.0 + _rng.nextDouble() * 3.5,
      ));
    }
  }

  void _updateGame(double dt) {
    if (_showingStageClear) return;

    // 1. 콘 좌우 이동 및 타워 관성 흔들림 물리
    if (_moveDir != 0) {
      final prevX = _coneX;
      _coneX = (_coneX + _moveDir * 0.56 * dt).clamp(0.16, 0.84);
      final dx = _coneX - prevX;
      _towerSwayVel -= dx * 16.0;
    }

    _towerSwayVel += (-18.0 * _towerSwayAngle) * dt;
    _towerSwayVel *= 0.88;
    _towerSwayAngle = (_towerSwayAngle + _towerSwayVel * dt).clamp(-0.24, 0.24);

    // 2. 디스펜서 노즐 반동 및 시럽 부스트 플래시 복원
    if (_dispenserSquish > 0.002) {
      _dispenserSquish *= 0.82;
    }
    if (_syrupBoostFlash > 0.005) {
      _syrupBoostFlash *= 0.88;
    }
    _dispenserX += (_dispenserTargetX - _dispenserX) * 0.18;

    // 3. 쌓인 스쿱 말랑 눌림 복원
    for (final s in _stackedScoops) {
      if (s.squish > 0.002) {
        s.squish *= 0.84;
      }
    }

    // 4. 크림 스플래시 파티클 & 플로팅 팝업 업데이트
    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 0.75 * dt; // 중력
      p.life -= dt * 1.65;
    }
    _particles.removeWhere((p) => p.life <= 0);

    for (final pop in _popups) {
      pop.y -= 0.11 * dt;
      pop.life -= dt * 1.25;
    }
    _popups.removeWhere((pop) => pop.life <= 0);

    // 5. 스폰 타이머
    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnTimer = (1.15 - _level * 0.04).clamp(0.75, 1.15);
      _spawnNextFallingItem();
    }

    // 6. 현재 타워 꼭대기 착지 Y좌표 계산
    final stackTopNormY =
        (0.74 - _stackedScoops.length * 0.074).clamp(0.26, 0.74);

    final toRemove = <_FallingItem>[];
    for (final item in _fallingItems) {
      item.normY += item.speed * dt;

      // 타워 꼭대기와 충돌 검사
      final dy = (item.normY - stackTopNormY).abs();
      final topX =
          _coneX + sin(_towerSwayAngle) * (_stackedScoops.length * 0.015);
      final dx = (item.normX - topX).abs();

      if (dy < 0.056 && dx < 0.108) {
        toRemove.add(item);
        _onItemCaught(item, item.normX - topX, topX, stackTopNormY);
      } else if (item.normY > 0.94) {
        toRemove.add(item);
      }
    }
    _fallingItems.removeWhere((e) => toRemove.contains(e));

    if (mounted) setState(() {});
  }

  void _onItemCaught(
    _FallingItem item,
    double relOffsetX,
    double catchNormX,
    double catchNormY,
  ) {
    if (item.isObstacle) {
      HapticFeedback.lightImpact();
      AudioManager.instance.playIceCreamObstacleHit();
      _comboCount = 0;
      _towerSwayVel += (_rng.nextBool() ? 1 : -1) * 1.6;
      _spawnSplashParticles(
        normX: catchNormX,
        normY: catchNormY,
        color: const Color(0xFF81D4FA),
        count: 12,
      );
      _popups.add(_FloatingPopup(
        x: catchNormX,
        y: catchNormY - 0.04,
        text: '🧊 앗 차가워!',
        color: const Color(0xFF0277BD),
      ));
      _setShibaSpeech('🥶 앗! 차가운 얼음이야! 얼음은 살짝 피해봐 멍!', celebrate: false);
      _showCleanToast('🧊 앗, 차가운 얼음!');
      return;
    }

    HapticFeedback.mediumImpact();
    final needed = _nextRequiredFlavor;
    final isExactOrder =
        item.isRainbowBonus || item.isTopping || (needed?.id == item.flavor.id);
    final isPerfectCenter = relOffsetX.abs() < 0.032;

    if (isExactOrder) {
      _comboCount++;
    } else {
      _comboCount = 1;
    }

    final starGain = (isExactOrder ? 2 : 1) + (isPerfectCenter ? 1 : 0);

    setState(() {
      _stackedScoops.add(_StackedScoop(
        flavor: item.flavor,
        offsetX: (relOffsetX * 0.42).clamp(-0.035, 0.035),
        isTopping: item.isTopping,
        isPerfect: isPerfectCenter,
        hasSyrup: item.isRainbowBonus || isPerfectCenter,
        squish: 0.30,
      ));
      _towerSwayVel += relOffsetX * 7.8;
      _totalStars += starGain;
    });

    _spawnSplashParticles(
      normX: catchNormX,
      normY: catchNormY,
      color: item.flavor.color,
      count: isPerfectCenter ? 20 : 12,
    );

    _popups.add(_FloatingPopup(
      x: catchNormX,
      y: catchNormY - 0.05,
      text: item.isRainbowBonus
          ? '🌈 레인보우! ⭐+$starGain'
          : isPerfectCenter
              ? '👑 PERFECT! ⭐+$starGain'
              : '${item.flavor.emoji} 쫀득! ⭐+$starGain',
      color: isPerfectCenter
          ? const Color(0xFFD81B60)
          : const Color(0xFF00695C),
    ));

    AudioManager.instance.playIceCreamScoopCatch(
      flavorId: item.flavor.id,
      stackCount: _stackedScoops.length,
      isTopping: item.isTopping,
      isExactOrder: isExactOrder,
      isPerfectCenter: isPerfectCenter,
      isRainbowBonus: item.isRainbowBonus,
      customerAnimalId: _currentCustomer.id,
    );

    _showCleanToast(
      '${item.flavor.emoji} ${item.flavor.name} ${item.isTopping ? "완성!" : "${_stackedScoops.length}단!"} ${isPerfectCenter ? "👑퍼펙트" : ""} ⭐+$starGain',
    );

    // 체리 토핑까지 올렸거나 목표 단수+1 도달 시 스테이지 클리어!
    if (item.isTopping || _stackedScoops.length > _orderRecipe.length) {
      _confettiCtrl.play();
      HapticFeedback.heavyImpact();
      AudioManager.instance.playIceCreamBellFinish();
      _setShibaSpeech(
        '🔔 띵동! ${_currentCustomer.emoji} ${_currentCustomer.name}의 ${_orderRecipe.length}단 아이스크림 완성! 최고야 멍!',
        celebrate: true,
      );
      Future.delayed(const Duration(milliseconds: 950), () {
        if (mounted) {
          setState(() => _showingStageClear = true);
        }
      });
    } else {
      final next = _nextRequiredFlavor;
      if (next != null) {
        _setShibaSpeech(
          isPerfectCenter
              ? '👑 와우 정중앙 퍼펙트! 다음은 ${next.emoji} ${next.name} 차례야 멍!'
              : '철썩! 맛있겠다! 다음은 ${next.emoji} ${next.name} 받아봐 멍! 🎯',
          celebrate: true,
        );
      }
    }
  }

  /// 🍫 시럽 & 스프링클 톡톡 버튼: 현재 쌓인 타워에 초코/딸기 시럽을 뿌려주고 흔들림을 안정화!
  void _onSyrupSprinkleBoost() {
    HapticFeedback.mediumImpact();
    AudioManager.instance.playIceCreamSyrupDrizzle(speak: true);

    setState(() {
      _syrupBoostFlash = 1.0;
      _towerSwayAngle *= 0.25;
      _towerSwayVel = 0.0;
      _totalStars += 1;

      for (int i = 0; i < _stackedScoops.length; i++) {
        final old = _stackedScoops[i];
        _stackedScoops[i] = _StackedScoop(
          flavor: old.flavor,
          offsetX: old.offsetX * 0.5, // 중심 정렬 보정!
          isTopping: old.isTopping,
          isPerfect: true,
          hasSyrup: true,
          squish: 0.22,
        );
      }
    });

    final topY = (0.74 - _stackedScoops.length * 0.074).clamp(0.28, 0.72);
    _spawnSplashParticles(
      normX: _coneX,
      normY: topY,
      color: const Color(0xFFFF4081),
      count: 22,
    );
    _popups.add(_FloatingPopup(
      x: _coneX,
      y: topY - 0.05,
      text: '🍯 달콤 시럽 톡톡! ⭐+1',
      color: const Color(0xFFD81B60),
    ));
    _showCleanToast('🍯 달콤한 시럽 & 스프링클 톡톡! 타워 균형 안정! ⭐+1');
  }

  void _showCleanToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toastText = text);
    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _toastText = null);
    });
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
                Color(0xFFD4F5F5),
                Color(0xFFFFEEF4),
                Color(0xFFFFF6D6),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 1. 아기자기한 파스텔 젤라또 가게 & 거리 풍경 배경
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter:
                        _IceCreamParlorBackgroundPainter(elapsed: _elapsed),
                  ),
                ),
              ),

              // 2. 메인 레이아웃
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    _buildMascotAndOrderStrip(),
                    const SizedBox(height: 6),

                    // 메인 아이스크림 캐치 스테이지
                    Expanded(
                      child: Center(
                        child: _buildCatchArena(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 하단 좌우 컨트롤 & 시럽 토핑 & 주문 안내 바
                    _buildControlBar(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 40,
                ),
              ),

              if (_showingStageClear) _buildStageClearOverlay(),
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
                border: Border.all(color: const Color(0xFF4DB6AC), width: 2.2),
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
                  color: Color(0xFF00897B),
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
                  colors: [Color(0xFFFFFFFF), Color(0xFFFFF8F9)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFF80AB), width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18E91E63),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🍨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '차곡차곡 아이스크림 타워',
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
                          Border.all(color: const Color(0xFFFFB74D), width: 1.4),
                    ),
                    child: Text(
                      '⭐ $_totalStars',
                      style: GoogleFonts.jua(
                        fontSize: 12,
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
              '$_level단계',
              style: GoogleFonts.jua(
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotAndOrderStrip() {
    final customer = _currentCustomer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // 동물 손님 & 시바 도우미 듀오 배지
          GestureDetector(
            onTap: () {
              AudioManager.instance.playIceCreamBellFinish();
              _setShibaSpeech(
                '${customer.emoji} ${customer.name}이 맛있는 ${_orderRecipe.length}단 아이스크림을 기다려요 멍!',
                celebrate: true,
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
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
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: customer.badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      customer.emoji,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF80CBC4), width: 1.8),
              ),
              child: Text(
                _shibaSpeech,
                style: GoogleFonts.jua(
                  fontSize: 12,
                  color: const Color(0xFF004D40),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 컴팩트 주문서 티켓 스트립 (터치하면 주문 안내 음성!)
          GestureDetector(
            onTap: () {
              final next = _nextRequiredFlavor;
              if (next != null) {
                if (next.id == 'topping') {
                  AudioManager.instance.playVoice('audio/voice_ice_topping.wav');
                } else {
                  AudioManager.instance
                      .playVoice('audio/voice_ice_${next.id}.wav');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB74D), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_orderRecipe.length, (idx) {
                    final fl = _orderRecipe[idx];
                    final isDone = idx < _stackedScoops.length;
                    final isCurrent = idx == _stackedScoops.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? const Color(0xFFFFCA28)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Opacity(
                          opacity: isDone ? 0.35 : 1.0,
                          child: Text(
                            fl.emoji,
                            style: TextStyle(fontSize: isCurrent ? 16 : 13),
                          ),
                        ),
                      ),
                    );
                  }),
                  const Text('🍒', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatchArena() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = min(constraints.maxWidth - 22, 425.0);
        final maxH = min(constraints.maxHeight, 445.0);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              final deltaNorm = details.delta.dx / maxW;
              _coneX = (_coneX + deltaNorm).clamp(0.16, 0.84);
              _towerSwayVel =
                  (_towerSwayVel - deltaNorm * 12.0).clamp(-1.6, 1.6);
            });
            if (_elapsed - _lastDragSoundTime > 0.22 &&
                details.delta.dx.abs() > 2.5) {
              _lastDragSoundTime = _elapsed;
              AudioManager.instance.playIceCreamConeMove();
            }
          },
          child: Container(
            width: maxW,
            height: maxH,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFBFD),
                  Color(0xFFF0FBF9),
                  Color(0xFFFFF5E4),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFFFF80AB), width: 5.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFD81B60),
                  offset: Offset(0, 6),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x28880E4F),
                  offset: Offset(0, 14),
                  blurRadius: 22,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _IceCreamTowerScenePainter(
                      coneX: _coneX,
                      towerSwayAngle: _towerSwayAngle,
                      fallingItems: _fallingItems,
                      stackedScoops: _stackedScoops,
                      particles: _particles,
                      popups: _popups,
                      nextRequiredFlavor: _nextRequiredFlavor,
                      dispenserX: _dispenserX,
                      dispenserSquish: _dispenserSquish,
                      dispenserPreviewFlavor: _dispenserPreviewFlavor,
                      customer: _currentCustomer,
                      syrupBoostFlash: _syrupBoostFlash,
                      comboCount: _comboCount,
                      elapsed: _elapsed,
                    ),
                  ),

                  // 우상단 달콤 시럽 & 스프링클 부스터 버튼
                  Positioned(
                    top: 38,
                    right: 10,
                    child: GestureDetector(
                      onTap: _onSyrupSprinkleBoost,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33D81B60),
                              offset: Offset(0, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🍯', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              '시럽 톡톡!',
                              style: GoogleFonts.jua(
                                fontSize: 11.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 좌하단 컴팩트 토스트 (타워와 떨어지는 스쿱을 가리지 않음!)
                  if (_toastText != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFF59D).withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFFF8F00), width: 2),
                          ),
                          child: Text(
                            _toastText!,
                            style: GoogleFonts.jua(
                              fontSize: 12.5,
                              color: const Color(0xFF4E342E),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlBar() {
    final next = _nextRequiredFlavor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFF80AB), width: 3),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              AudioManager.instance.playIceCreamConeMove();
              setState(() {
                _moveDir = -1.0;
                _coneX = (_coneX - 0.07).clamp(0.16, 0.84);
                _towerSwayVel = 0.5;
              });
            },
            onTapUp: (_) => setState(() => _moveDir = 0.0),
            onTapCancel: () => setState(() => _moveDir = 0.0),
            child: _buildMoveButton(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _onSyrupSprinkleBoost,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFCE4EC), Color(0xFFE0F2F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: const Color(0xFFF48FB1), width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      next?.emoji ?? '🍒',
                      style: const TextStyle(fontSize: 19),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '이번 순서: ${next?.name ?? "체리토핑"} (${_stackedScoops.length}/${_orderRecipe.length + 1}단)',
                        style: GoogleFonts.jua(
                          fontSize: 13.5,
                          color: const Color(0xFF880E4F),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTapDown: (_) {
              HapticFeedback.selectionClick();
              AudioManager.instance.playIceCreamConeMove();
              setState(() {
                _moveDir = 1.0;
                _coneX = (_coneX + 0.07).clamp(0.16, 0.84);
                _towerSwayVel = -0.5;
              });
            },
            onTapUp: (_) => setState(() => _moveDir = 0.0),
            onTapCancel: () => setState(() => _moveDir = 0.0),
            child: _buildMoveButton(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveButton(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF80AB), Color(0xFFD81B60)],
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33D81B60),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }

  Widget _buildStageClearOverlay() {
    final customer = _currentCustomer;
    final isAllEaten = _tastingBites >= 3;

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            constraints: const BoxConstraints(maxWidth: 360),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFF80AB), width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 140,
                  height: 50,
                  child: RiveAnimation.asset(
                    'assets/rive/rating.riv',
                    animations: ['5_stars'],
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_level단계 젤라또 타워 완성!',
                  style: GoogleFonts.jua(
                    fontSize: 24,
                    color: KidsTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),

                // 동물 손님에게 아이스크림 냠냠 먹여주기 인터랙티브 영역
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFCE4EC)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: const Color(0xFFFFB74D), width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            customer.emoji,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isAllEaten
                                ? '😋💗'
                                : (_tastingBites > 0 ? '😮🍨' : '🍦✨'),
                            style: const TextStyle(fontSize: 34),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAllEaten
                            ? '${customer.name}: "차갑고 달콤해서 정말 행복해! 고마워!"'
                            : '${customer.name}에게 완성한 아이스크림을 한 입 줘볼까요? ($_tastingBites/3)',
                        style: GoogleFonts.jua(
                          fontSize: 13.5,
                          color: const Color(0xFF880E4F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (!isAllEaten) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() => _tastingBites++);
                            AudioManager.instance.playIceCreamCustomerBite(
                              animalId: customer.id,
                              isFinalBite: _tastingBites >= 3,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF80AB), Color(0xFFF50057)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '🍨 손님에게 냠냠 한 입 주기!',
                              style: GoogleFonts.jua(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    setState(() => _level++);
                    _setupStage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '다음 손님 주문 받기! 🔔',
                      style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D Gelato Parlor Interior, Dispenser Nozzle, Customer Booth & Swaying Tower
// ─────────────────────────────────────────────────────────────────────────────

class _IceCreamTowerScenePainter extends CustomPainter {
  final double coneX;
  final double towerSwayAngle;
  final List<_FallingItem> fallingItems;
  final List<_StackedScoop> stackedScoops;
  final List<_SplashParticle> particles;
  final List<_FloatingPopup> popups;
  final _IceCreamFlavor? nextRequiredFlavor;
  final double dispenserX;
  final double dispenserSquish;
  final _IceCreamFlavor dispenserPreviewFlavor;
  final _GelatoCustomer customer;
  final double syrupBoostFlash;
  final int comboCount;
  final double elapsed;

  _IceCreamTowerScenePainter({
    required this.coneX,
    required this.towerSwayAngle,
    required this.fallingItems,
    required this.stackedScoops,
    required this.particles,
    required this.popups,
    required this.nextRequiredFlavor,
    required this.dispenserX,
    required this.dispenserSquish,
    required this.dispenserPreviewFlavor,
    required this.customer,
    required this.syrupBoostFlash,
    required this.comboCount,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 아기자기한 젤라또 가게 실내 배경 (아치형 창문, 파스텔 가랜드, 진열장, 손님 창구)
    _drawGelatoShopInterior(canvas, w, h);

    // 2. 천장 레일 & 3D 황동/민트 아이스크림 디스펜서 머신 노즐
    _drawCeilingDispenser(canvas, w, h);

    // 3. 위에서 떨어지는 스쿱 & 토핑 & 얼음 렌더링
    for (final item in fallingItems) {
      final ix = w * item.normX + sin(elapsed * 4.0 + item.wobblePhase) * 4.0;
      final iy = h * item.normY;
      final isRecommended = !item.isObstacle &&
          (item.isRainbowBonus ||
              item.isTopping ||
              item.flavor.id == nextRequiredFlavor?.id);

      canvas.save();
      canvas.translate(ix, iy);

      if (isRecommended) {
        canvas.drawCircle(
          Offset.zero,
          31,
          Paint()
            ..color = const Color(0xFFFFCA28).withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      _draw3DScoopBall(
        canvas,
        radius: 23,
        flavor: item.flavor,
        isTopping: item.isTopping,
        isObstacle: item.isObstacle,
        hasSyrup: item.isRainbowBonus,
        hasFace: !item.isObstacle,
      );

      if (isRecommended) {
        final badgeTp = TextPainter(
          text: TextSpan(
            text: item.isRainbowBonus ? '🌈보너스!' : '🎯순서!',
            style: GoogleFonts.jua(
              fontSize: 10.5,
              color: const Color(0xFFD81B60),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgeTp.paint(canvas, Offset(-badgeTp.width / 2, -36));
      }

      canvas.restore();
    }

    // 4. 바삭한 3D 격자 와플 콘 & 차곡차곡 쌓인 아이스크림 타워
    final cx = w * coneX;
    final coneTopY = h * 0.77;

    // 4-A. 콘 아래 핑크/골드 페이퍼 홀더 슬리브 & 와플 콘 본체
    final conePath = Path()
      ..moveTo(cx - 29, coneTopY)
      ..lineTo(cx + 29, coneTopY)
      ..lineTo(cx, h * 0.96)
      ..close();
    canvas.drawPath(
      conePath,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFE8BE74),
            Color(0xFFC99549),
            Color(0xFFA6783D),
          ],
        ).createShader(Rect.fromLTRB(cx - 29, coneTopY, cx + 29, h * 0.96)),
    );

    // 와플 격자 무늬
    canvas.save();
    canvas.clipPath(conePath);
    final waffleGridPaint = Paint()
      ..color = const Color(0xFF6D4C41).withValues(alpha: 0.36)
      ..strokeWidth = 1.5;
    for (int i = -4; i <= 4; i++) {
      canvas.drawLine(
        Offset(cx + i * 10 - 15, coneTopY),
        Offset(cx + i * 10 + 15, h * 0.96),
        waffleGridPaint,
      );
      canvas.drawLine(
        Offset(cx + i * 10 + 15, coneTopY),
        Offset(cx + i * 10 - 15, h * 0.96),
        waffleGridPaint,
      );
    }

    // 귀여운 스트라이프 종이 콘 홀더
    final sleevePath = Path()
      ..moveTo(cx - 19, coneTopY + (h * 0.19) * 0.34)
      ..lineTo(cx + 19, coneTopY + (h * 0.19) * 0.34)
      ..lineTo(cx + 7, coneTopY + (h * 0.19) * 0.76)
      ..lineTo(cx - 7, coneTopY + (h * 0.19) * 0.76)
      ..close();
    canvas.drawPath(sleevePath, Paint()..color = const Color(0xFFFF80AB));
    canvas.restore();

    // 와플 콘 상단 림 + 화이트 초코 스프링클 테두리
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, coneTopY), width: 62, height: 11),
        const Radius.circular(5.5),
      ),
      Paint()..color = const Color(0xFFD7A86E),
    );

    // 4-B. 차곡차곡 쌓인 아이스크림 스쿱 타워 (높이 올라갈수록 흔들림 적용)
    for (int i = 0; i < stackedScoops.length; i++) {
      final sc = stackedScoops[i];
      final levelFactor = (i + 1).toDouble();
      final swayX = sin(towerSwayAngle) * (levelFactor * 8.5);
      final sx = cx + sc.offsetX * w + swayX;
      final sy = coneTopY - 16 - (i * 29.0);

      canvas.save();
      canvas.translate(sx, sy);
      canvas.rotate(towerSwayAngle * 0.35);
      canvas.scale(1.0 + sc.squish, 1.0 - sc.squish * 0.65);

      _draw3DScoopBall(
        canvas,
        radius: sc.isTopping ? 18 : 25,
        flavor: sc.flavor,
        isTopping: sc.isTopping,
        isObstacle: false,
        hasSyrup: sc.hasSyrup,
        hasFace: i == stackedScoops.length - 1,
      );

      // 양옆에 바삭한 웨하스 롤 스틱 데코 (맨 위 스쿱에 장식)
      if (i == stackedScoops.length - 1 && !sc.isTopping) {
        final waferPaint = Paint()..color = const Color(0xFFD7A86E);
        canvas.save();
        canvas.translate(18, -14);
        canvas.rotate(0.45);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -12, 6, 18),
            const Radius.circular(3),
          ),
          waferPaint,
        );
        canvas.restore();
      }

      canvas.restore();
    }

    // 5. 크림 스플래시 & 스프링클 파티클 렌더링
    for (final p in particles) {
      final alpha = p.life.clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(p.x * w, p.y * h),
        p.radius * alpha,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }

    // 6. 플로팅 텍스트 팝업 ("👑 PERFECT!", "🍓 쫀득!")
    for (final pop in popups) {
      final alpha = pop.life.clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: pop.text,
          style: GoogleFonts.jua(
            fontSize: 13.5,
            color: pop.color.withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(pop.x * w - tp.width / 2, pop.y * h));
    }
  }

  void _drawGelatoShopInterior(Canvas canvas, double w, double h) {
    // 1. 파스텔 스트라이프 벽지 (은은한 핑크/크림 세로 스트라이프)
    const wallStripes = 11;
    final sw = w / wallStripes;
    for (int i = 0; i < wallStripes; i++) {
      if (i.isEven) {
        canvas.drawRect(
          Rect.fromLTWH(i * sw, 0, sw, h * 0.78),
          Paint()..color = const Color(0x14FF80AB),
        );
      }
    }

    // 2. 아치형 파리의 젤라또 가게 창문 & 바깥 풍경 (구름, 열기구)
    final winRect =
        Rect.fromCenter(center: Offset(w * 0.25, h * 0.34), width: 92, height: 115);
    final winRRect = RRect.fromRectAndCorners(
      winRect,
      topLeft: const Radius.circular(46),
      topRight: const Radius.circular(46),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );
    canvas.drawRRect(
      winRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        ).createShader(winRect),
    );
    // 창문 안 둥실둥실 구름
    final cloudX = winRect.left + 26 + sin(elapsed * 0.7) * 8;
    canvas.drawCircle(
      Offset(cloudX, winRect.top + 38),
      12,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(cloudX + 11, winRect.top + 40),
      10,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    // 창틀 프레임
    canvas.drawRRect(
      winRRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // 3. 우측 동물 손님 주문 부스 ("GELATO ORDER" 창구)
    final boothCenter = Offset(w * 0.78, h * 0.36);
    final boothRect =
        Rect.fromCenter(center: boothCenter, width: 92, height: 102);
    final boothRRect =
        RRect.fromRectAndRadius(boothRect, const Radius.circular(20));
    canvas.drawRRect(
      boothRRect,
      Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      boothRRect,
      Paint()
        ..color = const Color(0xFFFFB74D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 손님 캐릭터가 들썩이며 기대하는 모션
    final bounceY = sin(elapsed * 4.2) * 3.0;
    final custTp = TextPainter(
      text: TextSpan(
        text: customer.emoji,
        style: const TextStyle(fontSize: 34),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    custTp.paint(
      canvas,
      Offset(boothCenter.dx - custTp.width / 2, boothCenter.dy - 24 + bounceY),
    );

    final labelTp = TextPainter(
      text: TextSpan(
        text: '${customer.name} 💗',
        style: GoogleFonts.jua(
          fontSize: 10.5,
          color: const Color(0xFF880E4F),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelTp.paint(
      canvas,
      Offset(boothCenter.dx - labelTp.width / 2, boothRect.bottom - 20),
    );

    // 4. 하단 체커보드 타일 바닥 & 대리석 젤라또 쇼케이스 카운터
    final counterTop = h * 0.78;
    canvas.drawRect(
      Rect.fromLTWH(0, counterTop, w, h - counterTop),
      Paint()..color = const Color(0xFFFFF0F5),
    );

    // 파스텔 민트/화이트 체커보드 타일
    const cols = 10;
    final tileW = w / cols;
    final tileH = (h - counterTop) / 2;
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(c * tileW, counterTop + r * tileH, tileW, tileH),
            Paint()..color = const Color(0x284DB6AC),
          );
        }
      }
    }
    // 카운터 상단 골드/민트 몰딩 라인
    canvas.drawLine(
      Offset(0, counterTop),
      Offset(w, counterTop),
      Paint()
        ..color = const Color(0xFF80CBC4)
        ..strokeWidth = 3,
    );

    // 5. 상단 민트/핑크 스캘럽 어닝(차양) & 반짝이는 전구 가랜드
    const stripeCount = 9;
    final aw = w / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final c = i.isEven
          ? const Color(0xFF4DB6AC).withValues(alpha: 0.85)
          : const Color(0xFFFF80AB).withValues(alpha: 0.85);
      final path = Path()
        ..moveTo(i * aw, 0)
        ..lineTo((i + 1) * aw, 0)
        ..lineTo((i + 1) * aw, 22)
        ..quadraticBezierTo((i + 0.5) * aw, 35, i * aw, 22)
        ..close();
      canvas.drawPath(path, Paint()..color = c);

      // 어닝 아래 반짝이는 웜화이트/골드 꼬마전구
      final glowOn = ((i + (elapsed * 3).floor()) % 2 == 0);
      canvas.drawCircle(
        Offset((i + 0.5) * aw, 29),
        glowOn ? 4.2 : 3.2,
        Paint()
          ..color = glowOn
              ? const Color(0xFFFFF59D)
              : const Color(0xFFFFCC80).withValues(alpha: 0.7),
      );
    }
  }

  void _drawCeilingDispenser(Canvas canvas, double w, double h) {
    final dx = w * dispenserX;
    const railY = 34.0;

    // 수평 황동 레일
    canvas.drawLine(
      const Offset(24, railY),
      Offset(w - 24, railY),
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.65)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // 3D 아이스크림 디스펜서 노즐 본체 (스쿱이 발사될 때 통통 눌리는 애니메이션)
    canvas.save();
    canvas.translate(dx, railY);
    canvas.scale(1.0 + dispenserSquish * 0.4, 1.0 - dispenserSquish * 0.35);

    // 상단 돔 호퍼 (다음 맛 컬러 미리보기)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -4, 40, 22),
        const Radius.circular(10),
      ),
      Paint()..color = dispenserPreviewFlavor.color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -4, 40, 22),
        const Radius.circular(10),
      ),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // 하단 크롬/골드 추출구 퍼널
    final nozzlePath = Path()
      ..moveTo(-13, 18)
      ..lineTo(13, 18)
      ..lineTo(8, 29)
      ..lineTo(-8, 29)
      ..close();
    canvas.drawPath(nozzlePath, Paint()..color = const Color(0xFFFFD54F));

    canvas.restore();
  }

  void _draw3DScoopBall(
    Canvas canvas, {
    required double radius,
    required _IceCreamFlavor flavor,
    required bool isTopping,
    required bool isObstacle,
    required bool hasSyrup,
    required bool hasFace,
  }) {
    if (isTopping || isObstacle) {
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..color = flavor.lightColor
          ..style = PaintingStyle.fill,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: flavor.emoji,
          style: TextStyle(fontSize: radius * 1.35),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      return;
    }

    // 스쿱 반구 + 하단 크림 물결 프릴 (Scalloped Cream Edge)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.32, -0.38),
        radius: 0.98,
        colors: [
          Colors.white,
          flavor.lightColor,
          flavor.color,
          flavor.darkColor,
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawCircle(Offset.zero, radius, bodyPaint);
    for (int i = -2; i <= 2; i++) {
      canvas.drawCircle(
        Offset(i * (radius * 0.38), radius * 0.62),
        radius * 0.33,
        bodyPaint,
      );
    }

    // 좌상단 윤기나는 젤라또 글로시 하이라이트
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * 0.35, -radius * 0.38),
        width: radius * 0.42,
        height: radius * 0.24,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    // 시럽 드리즐 (퍼펙트 착지 또는 시럽 부스트 시 스쿱 위에 흐르는 달콤한 초코/딸기 시럽)
    if (hasSyrup) {
      final syrupPath = Path()
        ..moveTo(-radius * 0.65, -radius * 0.35)
        ..quadraticBezierTo(
            -radius * 0.32, radius * 0.05, -radius * 0.15, -radius * 0.45)
        ..quadraticBezierTo(
            radius * 0.10, radius * 0.15, radius * 0.35, -radius * 0.40)
        ..quadraticBezierTo(
            radius * 0.55, -radius * 0.05, radius * 0.65, -radius * 0.30);
      canvas.drawPath(
        syrupPath,
        Paint()
          ..color = flavor.id == 'choco'
              ? const Color(0xFFFF4081)
              : const Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 알록달록 스프링클 알갱이
    final sprinkleColors = [
      flavor.chipColor,
      const Color(0xFFFF4081),
      const Color(0xFF00E5FF),
      const Color(0xFFFFEA00),
    ];
    final pts = [
      Offset(-radius * 0.48, -radius * 0.25),
      Offset(radius * 0.45, -radius * 0.32),
      Offset(-radius * 0.54, radius * 0.15),
      Offset(radius * 0.52, radius * 0.16),
    ];
    for (int k = 0; k < pts.length; k++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pts[k], width: 5.5, height: 2.8),
          const Radius.circular(1.5),
        ),
        Paint()..color = sprinkleColors[k % sprinkleColors.length],
      );
    }

    if (hasFace) {
      final eyePaint = Paint()..color = const Color(0xFF3E2723);
      canvas.drawCircle(Offset(-radius * 0.30, -2), 3.4, eyePaint);
      canvas.drawCircle(Offset(radius * 0.30, -2), 3.4, eyePaint);
      // 반짝이는 눈동자 하이라이트 & 발그레한 볼터치
      canvas.drawCircle(
        Offset(-radius * 0.30 - 1, -3),
        1.1,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(radius * 0.30 - 1, -3),
        1.1,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(-radius * 0.45, 3),
        3.2,
        Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        Offset(radius * 0.45, 3),
        3.2,
        Paint()..color = const Color(0xFFFF80AB).withValues(alpha: 0.55),
      );

      final smile = Path()
        ..moveTo(-5, 4)
        ..quadraticBezierTo(0, 9.5, 5, 4);
      canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFF3E2723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _IceCreamTowerScenePainter oldDelegate) => true;
}

class _IceCreamParlorBackgroundPainter extends CustomPainter {
  final double elapsed;

  _IceCreamParlorBackgroundPainter({required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 하늘에 둥실둥실 떠다니는 아이스크림 모양 열기구 & 파스텔 구름
    final cloud1X = (w * 0.18 + sin(elapsed * 0.45) * 18);
    final cloud2X = (w * 0.82 - cos(elapsed * 0.38) * 18);
    _drawFluffyCloud(canvas, Offset(cloud1X, h * 0.14), 26);
    _drawFluffyCloud(canvas, Offset(cloud2X, h * 0.22), 22);

    // 2. 좌우 파스텔 가랜드 플래그(삼각 깃발) & 스프링클 패턴
    const dotColors = [
      Color(0x284DB6AC),
      Color(0x28FF80AB),
      Color(0x28FFD54F),
      Color(0x28BA68C8),
    ];
    for (double y = 60; y < h - 50; y += 46) {
      for (double x = 22; x < w; x += 46) {
        canvas.drawCircle(
          Offset(x, y),
          2.6,
          Paint()..color = dotColors[((x + y) ~/ 46) % dotColors.length],
        );
      }
    }

    // 3. 하단 파스텔 민트 & 스트로베리 크림 언덕
    final backHill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 95)
      ..quadraticBezierTo(w * 0.32, h - 135, w * 0.68, h - 90)
      ..quadraticBezierTo(w * 0.86, h - 70, w, h - 105)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      backHill,
      Paint()..color = const Color(0xFFF8BBD0).withValues(alpha: 0.42),
    );

    final frontHill = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 68)
      ..quadraticBezierTo(w * 0.5, h - 108, w, h - 62)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      frontHill,
      Paint()..color = const Color(0xFFB2DFDB).withValues(alpha: 0.52),
    );
  }

  void _drawFluffyCloud(Canvas canvas, Offset center, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawCircle(center, r, p);
    canvas.drawCircle(center + Offset(-r * 0.7, r * 0.15), r * 0.75, p);
    canvas.drawCircle(center + Offset(r * 0.7, r * 0.15), r * 0.75, p);
  }

  @override
  bool shouldRepaint(covariant _IceCreamParlorBackgroundPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}
