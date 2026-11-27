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
// Claw Machine Game — 두근두근 인형 뽑기 크레인! (6~7세 척척 도전 놀이)
// 프리미엄 3D UFO 아케이드 캐비닛 + 진자 흔들림 물리 + 에어점프 섞기 + 자석 파워 + 인형별 음성 도감
// ─────────────────────────────────────────────────────────────────────────────

enum ClawState {
  idle,
  descending,
  grabbing,
  ascending,
  returningToChute,
  releasing,
}

class _PrizeDoll {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final Color lightColor;
  final bool isGoldenCapsule;
  double normX; // 0.23 ~ 0.90 (왼쪽 0.0~0.20는 배출구 Chute 영역)
  double normY; // 0.65 ~ 0.77 (볼풀장 진열 높이)
  double baseNormY;
  double vy; // 에어점프 섞기 시 수직 속도
  double bobPhase;
  double moveSpeed;

  _PrizeDoll({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.lightColor,
    required this.normX,
    required this.normY,
    this.isGoldenCapsule = false,
    this.bobPhase = 0.0,
    this.moveSpeed = 0.0,
  })  : baseNormY = normY,
        vy = 0.0;
}

class _ClawSparkle {
  double x, y, vx, vy, size, life, rotation, vRot;
  Color color;
  int kind; // 0: star, 1: heart, 2: sparkle orb

  _ClawSparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
    required this.rotation,
    required this.vRot,
    this.kind = 0,
  });
}

class ClawMachineGame extends StatefulWidget {
  const ClawMachineGame({super.key});

  @override
  State<ClawMachineGame> createState() => _ClawMachineGameState();
}

class _ClawMachineGameState extends State<ClawMachineGame>
    with TickerProviderStateMixin {
  static const List<
      ({
        String id,
        String name,
        String emoji,
        Color color,
        Color light
      })> _catalog = [
    (
      id: 'bear',
      name: '곰돌이 인형',
      emoji: '🧸',
      color: Color(0xFFA1887F),
      light: Color(0xFFD7CCC8),
    ),
    (
      id: 'unicorn',
      name: '유니콘 인형',
      emoji: '🦄',
      color: Color(0xFFF48FB1),
      light: Color(0xFFFCE4EC),
    ),
    (
      id: 'trex',
      name: '공룡 인형',
      emoji: '🦖',
      color: Color(0xFF66BB6A),
      light: Color(0xFFC8E6C9),
    ),
    (
      id: 'rabbit',
      name: '토끼 인형',
      emoji: '🐰',
      color: Color(0xFFFF80AB),
      light: Color(0xFFF8BBD0),
    ),
    (
      id: 'robot',
      name: '로봇 인형',
      emoji: '🤖',
      color: Color(0xFF42A5F5),
      light: Color(0xFFBBDEFB),
    ),
    (
      id: 'penguin',
      name: '펭귄 인형',
      emoji: '🐧',
      color: Color(0xFF26C6DA),
      light: Color(0xFFB2EBF2),
    ),
    (
      id: 'puppy',
      name: '강아지 인형',
      emoji: '🐶',
      color: Color(0xFFFFB74D),
      light: Color(0xFFFFE0B2),
    ),
    (
      id: 'kitty',
      name: '고양이 인형',
      emoji: '🐱',
      color: Color(0xFFFF8A65),
      light: Color(0xFFFFCCBC),
    ),
    (
      id: 'octopus',
      name: '문어 인형',
      emoji: '🐙',
      color: Color(0xFFAB47BC),
      light: Color(0xFFE1BEE7),
    ),
    (
      id: 'alien',
      name: '우주인 인형',
      emoji: '👾',
      color: Color(0xFF7E57C2),
      light: Color(0xFFD1C4E9),
    ),
  ];

  late ConfettiController _confettiCtrl;
  late Ticker _gameTicker;

  final Random _rng = Random();
  final List<_PrizeDoll> _prizes = [];
  final List<_ClawSparkle> _sparkles = [];
  final Set<String> _collectedIds = {};

  int _level = 1;
  int _totalStars = 0;
  int _stageCatchCount = 0;
  int _stageTargetCount = 2;
  String _missionPrizeId = 'bear';
  bool _showingStageClear = false;
  bool _isMagnetActive = false; // ⚡ 무지개 자석 찬스

  // 방금 뽑은 인형 쇼케이스 팝업 배너
  _PrizeDoll? _justCaughtBannerPrize;
  Timer? _bannerTimer;

  // 크레인 물리 상태 (normX: 0.11 ~ 0.90, normY: 0.16 ~ 0.77)
  double _clawX = 0.56;
  double _clawY = 0.16;
  double _clawOpenAngle = 0.46; // 0.14 (닫힘) ~ 0.56 (열림)
  double _clawSwingAngle = 0.0; // 진자 흔들림 각도
  double _clawSwingVel = 0.0;
  ClawState _clawState = ClawState.idle;
  _PrizeDoll? _grabbedPrize;
  double _moveDir = 0.0; // -1.0 (좌), 0.0 (정지), 1.0 (우)
  double _elapsed = 0.0;

  String _shibaSpeech = '조준 레이저(🎯)를 인형에 맞추고 "집게 내리기!"를 눌러봐 멍! 🕹️';
  bool _isShibaCelebrating = false;
  Timer? _shibaTimer;

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
    _bannerTimer?.cancel();
    _shibaTimer?.cancel();
    _gameTicker.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _setupStage({bool playIntro = false}) {
    _prizes.clear();
    _stageCatchCount = 0;
    _stageTargetCount = (_level <= 2) ? 2 : 3;
    _showingStageClear = false;
    _clawState = ClawState.idle;
    _clawX = 0.56;
    _clawY = 0.16;
    _clawOpenAngle = 0.46;
    _clawSwingAngle = 0.0;
    _clawSwingVel = 0.0;
    _grabbedPrize = null;

    final shuffled = List.of(_catalog)..shuffle(_rng);
    final count = min(5 + (_level ~/ 2), 7);
    final selected = shuffled.take(count).toList();
    _missionPrizeId = selected.first.id;

    for (int i = 0; i < selected.length; i++) {
      final item = selected[i];
      final slotX = 0.26 + (i / max(1, selected.length - 1)) * 0.62;
      final jitterX = (_rng.nextDouble() - 0.5) * 0.03;
      final rowY = (i % 2 == 0) ? 0.74 : 0.67;
      final speed = _level >= 2
          ? ((i % 2 == 0 ? 1 : -1) * (0.035 + _level * 0.005))
          : 0.0;

      _prizes.add(_PrizeDoll(
        id: item.id,
        name: item.name,
        emoji: item.emoji,
        color: item.color,
        lightColor: item.light,
        normX: (slotX + jitterX).clamp(0.25, 0.89),
        normY: rowY,
        bobPhase: i * 0.9,
        moveSpeed: speed.clamp(-0.12, 0.12),
      ));
    }

    // 황금 서프라이즈 캡슐 1개 추가
    _prizes.add(_PrizeDoll(
      id: 'capsule',
      name: '황금 캡슐',
      emoji: '🎁',
      color: const Color(0xFFFFCA28),
      lightColor: const Color(0xFFFFF59D),
      normX: 0.58,
      normY: 0.71,
      isGoldenCapsule: true,
      bobPhase: 1.5,
      moveSpeed: 0.06,
    ));

    final missionItem = _catalog.firstWhere((e) => e.id == _missionPrizeId);
    _shibaSpeech =
        '🎯 미션: ${missionItem.emoji} ${missionItem.name} 포함 $_stageTargetCount개를 뽑아봐 멍!';

    setState(() {});

    if (playIntro) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          AudioManager.instance.playVoice('audio/voice_claw_intro.wav');
        }
      });
    }
  }

  /// 🌪️ 에어점프 인형 통통 섞기
  void _triggerAirShuffle() {
    if (_clawState != ClawState.idle || _prizes.isEmpty) return;
    HapticFeedback.mediumImpact();
    AudioManager.instance.playClawShuffleBounce();

    setState(() {
      for (final p in _prizes) {
        p.vy = -0.65 - _rng.nextDouble() * 0.45;
        p.moveSpeed = (_rng.nextBool() ? 1 : -1) * (0.06 + _rng.nextDouble() * 0.08);
      }
    });
    _setShibaSpeech('🌪️ 푸슈우웅~! 인형들이 통통 점프해서 위치가 바뀌었어 멍!', celebrate: true);
  }

  /// ⚡ 자석 파워 토글
  void _toggleMagnetPower() {
    HapticFeedback.selectionClick();
    AudioManager.instance.playRacingItemStar();
    setState(() {
      _isMagnetActive = !_isMagnetActive;
    });
    _setShibaSpeech(
      _isMagnetActive
          ? '⚡ 무지개 자석 집게 ON! 근처 인형이 집게로 쏙 끌려와 멍!'
          : '자석 집게를 껐어! 정밀 조준으로 뽑아봐 멍! 🎯',
      celebrate: _isMagnetActive,
    );
  }

  void _updateGame(double dt) {
    if (_showingStageClear) return;

    // 1. 스파클 파티클 업데이트
    if (_sparkles.isNotEmpty) {
      for (final s in _sparkles) {
        s.x += s.vx;
        s.y += s.vy;
        s.vy += 0.12;
        s.rotation += s.vRot;
        s.life -= 0.026;
      }
      _sparkles.removeWhere((s) => s.life <= 0);
    }

    // 2. 집게 진자 흔들림(Pendulum) 물리 감쇠
    const springK = 22.0;
    const damping = 0.88;
    _clawSwingVel += (-springK * _clawSwingAngle) * dt;
    _clawSwingVel *= damping;
    _clawSwingAngle += _clawSwingVel * dt;

    // 3. 인형들의 컨베이어 이동 & 에어점프 중력 물리
    for (final p in _prizes) {
      if (p == _grabbedPrize) continue;
      if (p.moveSpeed != 0) {
        p.normX += p.moveSpeed * dt;
        if (p.normX < 0.25) {
          p.normX = 0.25;
          p.moveSpeed = p.moveSpeed.abs();
        } else if (p.normX > 0.89) {
          p.normX = 0.89;
          p.moveSpeed = -p.moveSpeed.abs();
        }
      }
      if (p.vy != 0 || p.normY < p.baseNormY) {
        p.normY += p.vy * dt;
        p.vy += 2.2 * dt; // 중력
        if (p.normY >= p.baseNormY) {
          p.normY = p.baseNormY;
          if (p.vy > 0.18) {
            p.vy = -p.vy * 0.38; // 통통 바운스
          } else {
            p.vy = 0.0;
          }
        }
      }
    }

    // 4. 크레인 상태 머신
    switch (_clawState) {
      case ClawState.idle:
        if (_moveDir != 0) {
          final prevX = _clawX;
          _clawX = (_clawX + _moveDir * 0.48 * dt).clamp(0.24, 0.89);
          if ((_clawX - prevX).abs() > 0.0001) {
            _clawSwingVel += -_moveDir * 1.4 * dt;
          }
        }
        break;

      case ClawState.descending:
        _clawOpenAngle = (_clawOpenAngle + 0.45 * dt).clamp(0.14, 0.56);
        _clawY += 0.60 * dt;

        // 자석 모드일 때 가장 가까운 인형이 집게 X축으로 살짝 끌려옴
        if (_isMagnetActive && _prizes.isNotEmpty) {
          _PrizeDoll? nearest;
          double minD = 999.0;
          for (final p in _prizes) {
            final d = (p.normX - _clawX).abs();
            if (d < minD) {
              minD = d;
              nearest = p;
            }
          }
          if (nearest != null && minD < 0.18) {
            nearest.normX += (_clawX - nearest.normX) * 4.2 * dt;
          }
        }

        // 인형과 충돌/도달 검사
        _PrizeDoll? hitPrize;
        double bestDist = 999.0;
        final grabRadiusX = _isMagnetActive ? 0.105 : 0.085;
        for (final p in _prizes) {
          final dx = (p.normX - _clawX).abs();
          final dy = (p.normY - _clawY).abs();
          if (dx < grabRadiusX && dy < 0.095) {
            final d = sqrt(dx * dx + dy * dy);
            if (d < bestDist) {
              bestDist = d;
              hitPrize = p;
            }
          }
        }

        if (hitPrize != null || _clawY >= 0.75) {
          _grabbedPrize = hitPrize;
          _clawState = ClawState.grabbing;
          if (hitPrize != null) {
            HapticFeedback.heavyImpact();
            AudioManager.instance.playClawGrabSuccess(hitPrize.id);
            _clawSwingVel = 0.8;
            _setShibaSpeech(
              '찰칵! ${hitPrize.emoji} ${hitPrize.name}(을)를 꽉 잡았어 멍! 올라온다~ ✨',
              celebrate: true,
            );
          } else {
            HapticFeedback.lightImpact();
            AudioManager.instance.playClawMiss();
            _setShibaSpeech(
              '앗, 살짝 빗나갔어 멍! 초록색 🎯 LOCK ON 표시가 뜰 때 내려봐!',
              celebrate: false,
            );
          }
        }
        break;

      case ClawState.grabbing:
        _clawOpenAngle -= 1.05 * dt;
        if (_grabbedPrize != null) {
          _grabbedPrize!.normX = _clawX;
          _grabbedPrize!.normY = _clawY + 0.045;
        }
        if (_clawOpenAngle <= 0.15) {
          _clawOpenAngle = 0.15;
          _clawState = ClawState.ascending;
        }
        break;

      case ClawState.ascending:
        _clawY -= 0.56 * dt;
        if (_grabbedPrize != null) {
          _grabbedPrize!.normX = _clawX + sin(_clawSwingAngle) * 0.02;
          _grabbedPrize!.normY = _clawY + 0.045;
        }
        if (_clawY <= 0.16) {
          _clawY = 0.16;
          if (_grabbedPrize != null) {
            _clawState = ClawState.returningToChute;
          } else {
            _clawOpenAngle = 0.46;
            _clawState = ClawState.idle;
          }
        }
        break;

      case ClawState.returningToChute:
        _clawX -= 0.54 * dt;
        _clawSwingVel += 0.55 * dt;
        if (_grabbedPrize != null) {
          _grabbedPrize!.normX = _clawX + sin(_clawSwingAngle) * 0.025;
          _grabbedPrize!.normY = _clawY + 0.045;
        }
        if (_clawX <= 0.115) {
          _clawX = 0.115;
          _clawState = ClawState.releasing;
        }
        break;

      case ClawState.releasing:
        _clawOpenAngle = (_clawOpenAngle + 1.15 * dt).clamp(0.15, 0.55);
        if (_grabbedPrize != null) {
          _grabbedPrize!.normY += 1.15 * dt;
          if (_grabbedPrize!.normY >= 0.78) {
            _onPrizeDelivered(_grabbedPrize!);
            _grabbedPrize = null;
          }
        } else {
          _clawX = 0.56;
          _clawState = ClawState.idle;
        }
        break;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _triggerClawDrop() {
    if (_clawState != ClawState.idle || _showingStageClear) return;
    HapticFeedback.mediumImpact();
    AudioManager.instance.playClawDescend();
    setState(() {
      _moveDir = 0.0;
      _clawState = ClawState.descending;
    });
  }

  void _onPrizeDelivered(_PrizeDoll prize) {
    _prizes.remove(prize);
    final isMission = prize.id == _missionPrizeId;
    final isCapsule = prize.isGoldenCapsule;

    HapticFeedback.heavyImpact();
    AudioManager.instance.playClawPrizeDrop(
      prizeId: prize.id,
      isMission: isMission,
      isCapsule: isCapsule,
    );

    final size = MediaQuery.maybeOf(context)?.size ?? const Size(380, 760);
    _spawnChuteSparkles(Offset(size.width * 0.18, size.height * 0.56), prize.color);

    _bannerTimer?.cancel();
    setState(() {
      if (!isCapsule) {
        _collectedIds.add(prize.id);
      }
      _justCaughtBannerPrize = prize;
      _stageCatchCount++;
      _totalStars += (isMission || isCapsule) ? 3 : 1;
      _clawX = 0.56;
      _clawState = ClawState.idle;
    });

    _bannerTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _justCaughtBannerPrize = null);
      }
    });

    if (isMission) {
      _setShibaSpeech(
        '🎯 미션 인형 ${prize.emoji} ${prize.name} 뽑기 대성공! 보너스 ⭐+3!',
        celebrate: true,
      );
      if (_prizes.isNotEmpty) {
        final nextDoll = _prizes.firstWhere(
          (p) => !p.isGoldenCapsule,
          orElse: () => _prizes.first,
        );
        _missionPrizeId = nextDoll.id;
      }
    } else if (isCapsule) {
      _setShibaSpeech(
        '🎁 우와! 황금 캡슐에서 보너스 별 ⭐+3개가 쏟아졌어 멍!',
        celebrate: true,
      );
    } else {
      _setShibaSpeech(
        '🎉 ${prize.emoji} ${prize.name} 획득! 아래 인형 도감에 쏙 들어갔어 멍!',
        celebrate: true,
      );
    }

    if (_stageCatchCount >= _stageTargetCount || _prizes.isEmpty) {
      _confettiCtrl.play();
      Future.delayed(const Duration(milliseconds: 850), () {
        if (mounted) {
          setState(() => _showingStageClear = true);
        }
      });
    }
  }

  void _spawnChuteSparkles(Offset center, Color baseColor) {
    final palette = [
      baseColor,
      const Color(0xFFFFD54F),
      const Color(0xFFFF4081),
      const Color(0xFF40C4FF),
      const Color(0xFF69F0AE),
    ];
    for (int i = 0; i < 24; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 2.5 + _rng.nextDouble() * 5.8;
      _sparkles.add(_ClawSparkle(
        x: center.dx,
        y: center.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 2.2,
        size: 7 + _rng.nextDouble() * 7,
        life: 1.0,
        color: palette[i % palette.length],
        rotation: _rng.nextDouble() * pi,
        vRot: (_rng.nextDouble() - 0.5) * 0.2,
        kind: i % 3,
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
    final missionItem = _catalog.firstWhere(
      (e) => e.id == _missionPrizeId,
      orElse: () => _catalog.first,
    );

    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFDFF4FF),
                Color(0xFFFFF0F7),
                Color(0xFFFFF8DC),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 0. 아기자기한 카니발 아케이드 놀이방 배경 (가랜드, 풍선, 구름, 관람차, 반짝이 별)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CarnivalArcadeRoomBackgroundPainter(
                      elapsed: _elapsed,
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 4),
                    _buildMascotAndMissionBar(missionItem),
                    const SizedBox(height: 6),

                    // 메인 인형 뽑기 3D UFO 아케이드 캐비닛
                    Expanded(
                      child: Center(
                        child: _buildArcadeCabinet(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 아케이드 조종 패드 (좌·우 + 집게 내리기 + 통통 섞기 + 자석 파워)
                    _buildControlDeck(),
                    const SizedBox(height: 6),

                    // 뽑은 인형 도감 진열장 (터치 시 한국어 이름 음성 재생!)
                    _buildCollectedShelf(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // 스파클 파티클 오버레이
              if (_sparkles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ClawSparkleOverlayPainter(sparkles: _sparkles),
                    ),
                  ),
                ),

              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiCtrl,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 38,
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
                border: Border.all(color: const Color(0xFFCE93D8), width: 2),
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
                  color: Color(0xFF8E24AA),
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
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFCE93D8), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x144A148C),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛸', style: TextStyle(fontSize: 17)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '두근두근 인형 뽑기',
                      style: GoogleFonts.jua(
                        fontSize: 17,
                        color: const Color(0xFF4A148C),
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
                colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '$_level단계 ($_stageCatchCount/$_stageTargetCount)',
              style: GoogleFonts.jua(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotAndMissionBar(
      ({String id, String name, String emoji, Color color, Color light})
          missionItem) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClawDollVoice(missionItem.id);
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
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCE93D8), width: 1.5),
              ),
              child: Text(
                _shibaSpeech,
                style: GoogleFonts.jua(
                  fontSize: 12.5,
                  color: const Color(0xFF4A148C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              AudioManager.instance.playClawDollVoice(missionItem.id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(missionItem.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '미션🔊',
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

  Widget _buildArcadeCabinet() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = min(constraints.maxWidth - 22, 425.0);
        final maxH = min(constraints.maxHeight, 435.0);

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            if (_clawState != ClawState.idle) return;
            setState(() {
              final deltaNorm = details.delta.dx / maxW;
              _clawX = (_clawX + deltaNorm).clamp(0.24, 0.89);
              _clawSwingVel =
                  (_clawSwingVel - deltaNorm * 14.0).clamp(-1.8, 1.8);
            });
          },
          child: Container(
            width: maxW,
            height: maxH,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF281B4E),
                  Color(0xFF39286B),
                  Color(0xFF4A2E7E),
                ],
              ),
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFFFF4081), width: 6),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFFAD1457),
                  offset: Offset(0, 7),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Color(0x38311B92),
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
                    painter: _ClawMachineCabinetPainter(
                      clawX: _clawX,
                      clawY: _clawY,
                      clawOpenAngle: _clawOpenAngle,
                      clawSwingAngle: _clawSwingAngle,
                      prizes: _prizes,
                      grabbedPrize: _grabbedPrize,
                      missionPrizeId: _missionPrizeId,
                      isMagnetActive: _isMagnetActive,
                      elapsed: _elapsed,
                    ),
                  ),

                  // 방금 뽑은 인형 토스트: 집게(상단)를 전혀 가리지 않도록 좌하단 경품 출구(Chute) 위에 컴팩트하게 팝업!
                  if (_justCaughtBannerPrize != null)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: IgnorePointer(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1.0),
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) {
                            return Transform.scale(
                              scale: scale,
                              alignment: Alignment.bottomLeft,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF59D), Color(0xFFFFCA28)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: Colors.white, width: 2.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x44000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _justCaughtBannerPrize!.emoji,
                                  style: const TextStyle(fontSize: 19),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_justCaughtBannerPrize!.name} 획득! ✨',
                                  style: GoogleFonts.jua(
                                    fontSize: 12.5,
                                    color: const Color(0xFF4A148C),
                                  ),
                                ),
                              ],
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

  Widget _buildControlDeck() {
    final isIdle = _clawState == ClawState.idle;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F6), Color(0xFFFCE4EC)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFF80AB), width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFD81B60),
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ◀ 왼쪽 이동 버튼
          GestureDetector(
            onTapDown: (_) {
              if (!isIdle) return;
              AudioManager.instance.playClawMove();
              HapticFeedback.selectionClick();
              setState(() {
                _moveDir = -1.0;
                _clawX = (_clawX - 0.055).clamp(0.24, 0.89);
                _clawSwingVel = 0.55;
              });
            },
            onTapUp: (_) => setState(() => _moveDir = 0.0),
            onTapCancel: () => setState(() => _moveDir = 0.0),
            child: _buildArcadeCircleButton(
              icon: Icons.arrow_back_rounded,
              colors: const [Color(0xFF29B6F6), Color(0xFF0277BD)],
              enabled: isIdle,
            ),
          ),
          const SizedBox(width: 8),

          // ▶ 오른쪽 이동 버튼
          GestureDetector(
            onTapDown: (_) {
              if (!isIdle) return;
              AudioManager.instance.playClawMove();
              HapticFeedback.selectionClick();
              setState(() {
                _moveDir = 1.0;
                _clawX = (_clawX + 0.055).clamp(0.24, 0.89);
                _clawSwingVel = -0.55;
              });
            },
            onTapUp: (_) => setState(() => _moveDir = 0.0),
            onTapCancel: () => setState(() => _moveDir = 0.0),
            child: _buildArcadeCircleButton(
              icon: Icons.arrow_forward_rounded,
              colors: const [Color(0xFF29B6F6), Color(0xFF0277BD)],
              enabled: isIdle,
            ),
          ),
          const SizedBox(width: 10),

          // 🎯 중앙 집게 내리기 빅 돔 버튼
          Expanded(
            child: GestureDetector(
              onTap: _triggerClawDrop,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIdle
                        ? const [Color(0xFFFF4081), Color(0xFFC51162)]
                        : const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isIdle ? const Color(0x66C51162) : Colors.black12,
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        isIdle ? '집게 내리기!' : '작동 중...',
                        style: GoogleFonts.jua(
                          fontSize: 15.5,
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
          const SizedBox(width: 8),

          // 🌪️ 에어점프 인형 통통 섞기 버튼
          GestureDetector(
            onTap: _triggerAirShuffle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌪️', style: TextStyle(fontSize: 15)),
                  Text(
                    '섞기',
                    style: GoogleFonts.jua(fontSize: 10.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // ⚡ 무지개 자석 파워 버튼
          GestureDetector(
            onTap: _toggleMagnetPower,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isMagnetActive
                      ? const [Color(0xFFFFCA28), Color(0xFFFF6F00)]
                      : const [Color(0xFF9575CD), Color(0xFF5E35B1)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isMagnetActive ? '🧲' : '⚡',
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    _isMagnetActive ? '자석ON' : '자석',
                    style: GoogleFonts.jua(fontSize: 10.5, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArcadeCircleButton({
    required IconData icon,
    required List<Color> colors,
    required bool enabled,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: enabled
              ? colors
              : const [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
        ),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330288D1),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildCollectedShelf() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD54F), width: 2.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            Text(
              '🏆 도감 (${_collectedIds.length}/${_catalog.length}) 🔊: ',
              style: GoogleFonts.jua(
                fontSize: 12,
                color: const Color(0xFF5D4037),
              ),
            ),
            const SizedBox(width: 4),
            ..._catalog.map((item) {
              final owned = _collectedIds.contains(item.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    AudioManager.instance.playClawDollVoice(item.id);
                    _setShibaSpeech(
                      owned
                          ? '🎉 내가 뽑은 ${item.emoji} ${item.name}이야 멍! 멋지지?'
                          : '🎯 아직 안 뽑은 ${item.emoji} ${item.name}이야! 뽑아보자 멍!',
                      celebrate: owned,
                    );
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: owned ? item.light : Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: owned ? item.color : Colors.grey.shade300,
                        width: owned ? 2.0 : 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: owned ? 1.0 : 0.30,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStageClearOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            constraints: const BoxConstraints(maxWidth: 350),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFFD54F), width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 140,
                  height: 55,
                  child: RiveAnimation.asset(
                    'assets/rive/rating.riv',
                    animations: ['5_stars'],
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_level단계 인형 뽑기 성공!',
                  style: GoogleFonts.jua(
                    fontSize: 25,
                    color: KidsTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '인형을 척척 잘 뽑았어요! 총 ⭐ $_totalStars개',
                  style: GoogleFonts.jua(
                    fontSize: 14,
                    color: KidsTheme.textLight,
                  ),
                ),
                const SizedBox(height: 18),
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
                        colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '다음 단계 도전! 🛸',
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
// High-End 3D UFO Arcade Cabinet Painter
// (네온 마키 전구, 스포트라이트, 알록달록 볼풀장, 2톤 가샤폰 캡슐, UFO 비행접시 집게, 아크릴 배출구)
// ─────────────────────────────────────────────────────────────────────────────

class _ClawMachineCabinetPainter extends CustomPainter {
  final double clawX;
  final double clawY;
  final double clawOpenAngle;
  final double clawSwingAngle;
  final List<_PrizeDoll> prizes;
  final _PrizeDoll? grabbedPrize;
  final String missionPrizeId;
  final bool isMagnetActive;
  final double elapsed;

  _ClawMachineCabinetPainter({
    required this.clawX,
    required this.clawY,
    required this.clawOpenAngle,
    required this.clawSwingAngle,
    required this.prizes,
    required this.grabbedPrize,
    required this.missionPrizeId,
    required this.isMagnetActive,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 내부 밤하늘/천장 스포트라이트 빔 & 반짝이 배경 별
    _drawInteriorBackdrop(canvas, size);

    // 2. 바닥 알록달록 볼풀장(Ball Pit) & 쿠션 진열대
    _drawBallPitFloor(canvas, size);

    // 3. 좌측 네온 아크릴 경품 배출구 (Prize Chute)
    _drawNeonPrizeChute(canvas, size);

    // 4. 수직 조준 레이저 & 정조준(LOCK ON) 표시
    _PrizeDoll? targetedPrize;
    double bestDx = 999.0;
    for (final p in prizes) {
      if (p == grabbedPrize) continue;
      final dx = (p.normX - clawX).abs();
      if (dx < 0.068 && dx < bestDx) {
        bestDx = dx;
        targetedPrize = p;
      }
    }

    final laserX = w * clawX;
    final isLockedOn = targetedPrize != null;
    final laserColor = isLockedOn
        ? const Color(0xFF00E676)
        : (isMagnetActive ? const Color(0xFFFFD54F) : const Color(0xFFFF4081));

    final laserPaint = Paint()
      ..color = laserColor.withValues(alpha: isLockedOn ? 0.65 : 0.35)
      ..strokeWidth = isLockedOn ? 3.0 : 2.0;
    for (double y = h * clawY + 30; y < h * 0.78; y += 9) {
      canvas.drawLine(Offset(laserX, y), Offset(laserX, y + 5), laserPaint);
    }

    // 5. 3D 가샤폰 캡슐 & 인형 렌더링
    for (final p in prizes) {
      final isGrabbed = p == grabbedPrize;
      final isTarget = p == targetedPrize;
      final px = w * p.normX;
      final bob = isGrabbed ? 0.0 : sin(elapsed * 3.2 + p.bobPhase) * 2.5;
      final targetJump = isTarget ? -sin(elapsed * 8.0).abs() * 5.0 : 0.0;
      final py = h * p.normY + bob + targetJump;
      final isMission = p.id == missionPrizeId;

      canvas.save();
      canvas.translate(px, py);
      if (isGrabbed) {
        canvas.rotate(clawSwingAngle * 0.6);
      }

      // 미션 인형 / 황금 캡슐 / 정조준 후광
      if (isTarget || isMission || p.isGoldenCapsule) {
        canvas.drawCircle(
          Offset.zero,
          33,
          Paint()
            ..color = (isTarget
                    ? const Color(0xFF00E676)
                    : const Color(0xFFFFD54F))
                .withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
        );
      }

      final radius = 26.0;

      // 바닥 그림자
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 24), width: 42, height: 12),
        Paint()..color = Colors.black.withValues(alpha: 0.25),
      );

      // 하단 컬러 반구 (Gashapon Capsule Bottom Bowl)
      final bottomArcRect = Rect.fromCircle(center: Offset.zero, radius: radius);
      canvas.drawArc(
        bottomArcRect,
        0,
        pi,
        true,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              p.color,
              Color.lerp(p.color, Colors.black, 0.25)!,
            ],
          ).createShader(bottomArcRect),
      );

      // 상단 투명 글래스 돔 (Gashapon Transparent Top Dome)
      canvas.drawArc(
        bottomArcRect,
        pi,
        pi,
        true,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.45),
            radius: 0.9,
            colors: [
              Colors.white.withValues(alpha: 0.92),
              p.lightColor.withValues(alpha: 0.78),
              p.color.withValues(alpha: 0.45),
            ],
          ).createShader(bottomArcRect),
      );

      // 캡슐 중앙 골드/화이트 벨트 링
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0, 2), width: radius * 2.02, height: 4.5),
          const Radius.circular(3),
        ),
        Paint()
          ..color = p.isGoldenCapsule
              ? const Color(0xFFFF8F00)
              : Colors.white.withValues(alpha: 0.85),
      );

      // 인형 이모지
      final tp = TextPainter(
        text: TextSpan(
          text: p.emoji,
          style: const TextStyle(fontSize: 28),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 - 2));

      // 캡슐 외곽 테두리 & 유리 광택 호
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..color = isTarget
              ? const Color(0xFF00E676)
              : (isMission ? const Color(0xFFFFCA28) : Colors.white)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (isTarget || isMission) ? 3.0 : 2.0,
      );

      // 좌상단 캡슐 유리 하이라이트
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-10, -13), width: 11, height: 6),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      // 정조준 LOCK ON 또는 미션 배지
      if (isTarget) {
        final lockTp = TextPainter(
          text: TextSpan(
            text: '🎯OK!',
            style: GoogleFonts.jua(
              fontSize: 10.5,
              color: const Color(0xFF00E676),
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 3),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        lockTp.paint(canvas, Offset(-lockTp.width / 2, -radius - 15));
      } else if (isMission) {
        final badgeTp = TextPainter(
          text: const TextSpan(
            text: '⭐미션',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFF59D),
              shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgeTp.paint(canvas, Offset(-badgeTp.width / 2, -radius - 14));
      }

      canvas.restore();
    }

    // 6. 상단 크레인 레일 & 3D UFO 비행접시 크레인 집게
    _drawUfoClawAssembly(canvas, size, isLockedOn);

    // 7. 상단 네온 마키 헤더 & 반짝이는 전구 림
    _drawTopNeonMarquee(canvas, size);

    // 8. 전면 유리창 사선 반사 하이라이트
    final glassReflection = Path()
      ..moveTo(w * 0.80, 0)
      ..lineTo(w * 0.91, 0)
      ..lineTo(w * 0.64, h)
      ..lineTo(w * 0.53, h)
      ..close();
    canvas.drawPath(
      glassReflection,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  void _drawInteriorBackdrop(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 0. 화사한 동화 놀이공원 파스텔 그라데이션 내부 벽면
    final bgRect = Rect.fromLTWH(0, 0, w, h * 0.78);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF39286B),
            Color(0xFF5E3B8C),
            Color(0xFF8E54A8),
            Color(0xFFF48FB1),
          ],
          stops: [0.0, 0.38, 0.72, 1.0],
        ).createShader(bgRect),
    );

    // 1. 배경 중앙 은은한 5색 파스텔 무지개 아치
    const rainbowColors = [
      Color(0x38FF8A80),
      Color(0x38FFD180),
      Color(0x38FFFF8D),
      Color(0x38B9F6CA),
      Color(0x3880D8FF),
    ];
    for (int i = 0; i < rainbowColors.length; i++) {
      final r = w * (0.48 - i * 0.032);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.56, h * 0.68), radius: r),
        pi,
        pi,
        false,
        Paint()
          ..color = rainbowColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0,
      );
    }

    // 2. 천장 회전하는 놀이공원 대관람차(Ferris Wheel) 실루엣 (우측 뒤편)
    final wheelCenter = Offset(w * 0.76, h * 0.44);
    const wheelR = 46.0;
    final wheelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(wheelCenter, wheelR, wheelPaint);
    canvas.drawCircle(wheelCenter, wheelR * 0.22, wheelPaint);
    // 관람차 지지대
    canvas.drawLine(
      wheelCenter,
      Offset(wheelCenter.dx - 24, h * 0.76),
      wheelPaint..strokeWidth = 2.6,
    );
    canvas.drawLine(
      wheelCenter,
      Offset(wheelCenter.dx + 24, h * 0.76),
      wheelPaint,
    );
    // 회전하는 관람차 스포크 & 파스텔 곤돌라
    const gondolaColors = [
      Color(0xFFFF80AB),
      Color(0xFFFFD54F),
      Color(0xFF4FC3F7),
      Color(0xFF69F0AE),
    ];
    for (int i = 0; i < 8; i++) {
      final angle = elapsed * 0.45 + (i * pi / 4);
      final gx = wheelCenter.dx + cos(angle) * wheelR;
      final gy = wheelCenter.dy + sin(angle) * wheelR;
      canvas.drawLine(
        wheelCenter,
        Offset(gx, gy),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.16)
          ..strokeWidth = 1.4,
      );
      canvas.drawCircle(
        Offset(gx, gy),
        5.5,
        Paint()
          ..color =
              gondolaColors[i % gondolaColors.length].withValues(alpha: 0.48),
      );
    }

    // 3. 좌측 뒤편 동화 속 미니 성(Castle) 실루엣 & 몽실몽실 구름
    final castleColor = const Color(0xFFE1BEE7).withValues(alpha: 0.22);
    final castlePaint = Paint()..color = castleColor;
    canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.56, 38, h * 0.21), castlePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.48, 14, h * 0.29), castlePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.36, h * 0.48, 14, h * 0.29), castlePaint);
    final roof1 = Path()
      ..moveTo(w * 0.21, h * 0.48)
      ..lineTo(w * 0.29, h * 0.39)
      ..lineTo(w * 0.31, h * 0.48)
      ..close();
    final roof2 = Path()
      ..moveTo(w * 0.35, h * 0.48)
      ..lineTo(w * 0.38, h * 0.39)
      ..lineTo(w * 0.43, h * 0.48)
      ..close();
    canvas.drawPath(roof1, castlePaint);
    canvas.drawPath(roof2, castlePaint);

    // 4. 내부 하단 몽실몽실 파스텔 구름 능선
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 7; i++) {
      final cx = w * (0.20 + i * 0.13);
      final cy = h * 0.74 + sin(elapsed * 1.8 + i) * 3.0;
      canvas.drawCircle(Offset(cx, cy), 22 + (i % 2) * 6.0, cloudPaint);
    }

    // 5. 천장 스포트라이트 원뿔 빔 2개
    for (final bx in [w * 0.35, w * 0.72]) {
      final beamPath = Path()
        ..moveTo(bx - 18, h * 0.08)
        ..lineTo(bx + 18, h * 0.08)
        ..lineTo(bx + 90, h * 0.78)
        ..lineTo(bx - 90, h * 0.78)
        ..close();
      canvas.drawPath(
        beamPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF59D).withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
    }

    // 6. 배경 반짝이는 4각 별 & 미니 별
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final sx = w * (0.08 + (i * 0.068) % 0.86);
      final sy = h * (0.15 + (i % 4) * 0.11);
      final twinkle = 0.35 + 0.55 * ((sin(elapsed * 3.5 + i) + 1) / 2);
      starPaint.color =
          (i % 3 == 0 ? const Color(0xFFFFF59D) : Colors.white)
              .withValues(alpha: twinkle);
      canvas.drawCircle(Offset(sx, sy), (i % 2 == 0) ? 2.4 : 1.6, starPaint);
    }
  }

  void _drawBallPitFloor(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final floorRect = Rect.fromLTWH(0, h * 0.77, w, h * 0.23);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E35B1), Color(0xFF311B92)],
        ).createShader(floorRect),
    );

    // 알록달록 볼풀장 미니 공들
    const ballColors = [
      Color(0xFFFF80AB),
      Color(0xFFFFD54F),
      Color(0xFF4FC3F7),
      Color(0xFF69F0AE),
      Color(0xFFEA80FC),
      Color(0xFFFFAB91),
    ];
    for (int row = 0; row < 2; row++) {
      for (int i = 0; i < 16; i++) {
        final bx = w * 0.22 + i * (w * 0.78 / 15) + (row.isOdd ? 8 : 0);
        final by = h * (0.785 + row * 0.045);
        final bc = ballColors[(i + row * 3) % ballColors.length];
        canvas.drawCircle(
          Offset(bx, by),
          10.5,
          Paint()..color = bc.withValues(alpha: 0.75),
        );
        canvas.drawCircle(
          Offset(bx - 3, by - 3),
          3.0,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }
  }

  void _drawNeonPrizeChute(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final chuteRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.025, h * 0.58, w * 0.18, h * 0.38),
      const Radius.circular(16),
    );

    // 출구 내부 어두운 홀
    canvas.drawRRect(
      chuteRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A102E), Color(0xFF2E1C4E)],
        ).createShader(chuteRect.outerRect),
    );

    // 네온 테두리
    canvas.drawRRect(
      chuteRect,
      Paint()
        ..color = const Color(0xFFFFCA28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2,
    );

    // 출구 플랩 도어
    final flapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, h * 0.74, w * 0.15, h * 0.18),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      flapRect,
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );

    final chuteTp = TextPainter(
      text: TextSpan(
        text: '🎁 출구\n⬇\nPUSH',
        style: GoogleFonts.jua(
          fontSize: 11.5,
          color: const Color(0xFFFFF59D),
          height: 1.25,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    chuteTp.paint(
      canvas,
      Offset(w * 0.115 - chuteTp.width / 2, h * 0.63),
    );
  }

  void _drawUfoClawAssembly(Canvas canvas, Size size, bool isLockedOn) {
    final w = size.width;
    final h = size.height;

    // 1. 상단 크롬 레일 바
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.095, w, 9),
      Paint()..color = const Color(0xFF78909C),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.095, w, 3.5),
      Paint()..color = const Color(0xFFECEFF1),
    );

    final cx = w * clawX;
    final cy = h * clawY;

    // 2. 강철 코일 와이어 케이블
    canvas.drawLine(
      Offset(cx, h * 0.11),
      Offset(cx, cy),
      Paint()
        ..color = const Color(0xFFCFD8DC)
        ..strokeWidth = 4.0,
    );
    canvas.drawLine(
      Offset(cx - 1, h * 0.11),
      Offset(cx - 1, cy),
      Paint()
        ..color = const Color(0xFF546E7A)
        ..strokeWidth = 1.5,
    );

    // 3. 상단 UFO 비행접시 트롤리 카트
    final trolleyCenter = Offset(cx, h * 0.105);
    canvas.drawOval(
      Rect.fromCenter(center: trolleyCenter, width: 54, height: 22),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF80AB), Color(0xFFD81B60)],
        ).createShader(
            Rect.fromCenter(center: trolleyCenter, width: 54, height: 22)),
    );
    canvas.drawOval(
      Rect.fromCenter(center: trolleyCenter, width: 54, height: 22),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // 트롤리 LED 램프 3개
    final ledColor = isLockedOn
        ? const Color(0xFF00E676)
        : const Color(0xFFFFF59D);
    for (final dx in [-14.0, 0.0, 14.0]) {
      canvas.drawCircle(
        Offset(cx + dx, h * 0.105),
        3.2,
        Paint()..color = ledColor,
      );
    }

    // 4. 회전·진자 물리 적용된 UFO 집게 헤드 & 3관절 메탈 집게발
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(clawSwingAngle);

    // 자석 모드일 때 무지개 자기장 파동 링
    if (isMagnetActive) {
      final pulseR = 26.0 + sin(elapsed * 8.0) * 6.0;
      canvas.drawCircle(
        const Offset(0, 18),
        pulseR,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    final outerArmPaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerArmPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final gripPadPaint = Paint()
      ..color = const Color(0xFFFF4081)
      ..style = PaintingStyle.fill;

    // 왼쪽 관절 집게발
    canvas.save();
    canvas.rotate(clawOpenAngle);
    final leftProng = Path()
      ..moveTo(-4, 0)
      ..lineTo(-22, 16)
      ..lineTo(-11, 36);
    canvas.drawPath(leftProng, outerArmPaint);
    canvas.drawPath(leftProng, innerArmPaint);
    canvas.drawCircle(const Offset(-22, 16), 4.0, Paint()..color = const Color(0xFFFFCA28));
    canvas.drawCircle(const Offset(-11, 36), 4.8, gripPadPaint);
    canvas.restore();

    // 오른쪽 관절 집게발
    canvas.save();
    canvas.rotate(-clawOpenAngle);
    final rightProng = Path()
      ..moveTo(4, 0)
      ..lineTo(22, 16)
      ..lineTo(11, 36);
    canvas.drawPath(rightProng, outerArmPaint);
    canvas.drawPath(rightProng, innerArmPaint);
    canvas.drawCircle(const Offset(22, 16), 4.0, Paint()..color = const Color(0xFFFFCA28));
    canvas.drawCircle(const Offset(11, 36), 4.8, gripPadPaint);
    canvas.restore();

    // 중앙 UFO 실린더 허브
    final hubRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 30, height: 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      hubRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)],
        ).createShader(hubRect.outerRect),
    );
    canvas.drawRRect(
      hubRect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      Offset.zero,
      4.5,
      Paint()..color = isLockedOn ? const Color(0xFF00E676) : Colors.white,
    );

    canvas.restore();
  }

  void _drawTopNeonMarquee(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final marqueeRect = Rect.fromLTWH(0, 0, w, h * 0.085);
    canvas.drawRect(
      marqueeRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFAD1457), Color(0xFF6A1B9A), Color(0xFFAD1457)],
        ).createShader(marqueeRect),
    );

    // 반짝이는 아케이드 전구 12개
    const int bulbCount = 12;
    final phase = (elapsed * 4).floor();
    for (int i = 0; i < bulbCount; i++) {
      final bx = w * (0.05 + i * (0.90 / (bulbCount - 1)));
      final by = h * 0.042;
      final isLit = (i + phase) % 2 == 0;
      canvas.drawCircle(
        Offset(bx, by),
        isLit ? 4.2 : 3.0,
        Paint()
          ..color = isLit
              ? const Color(0xFFFFF59D)
              : const Color(0xFFFF80AB).withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClawMachineCabinetPainter old) => true;
}

class _ClawSparkleOverlayPainter extends CustomPainter {
  final List<_ClawSparkle> sparkles;

  _ClawSparkleOverlayPainter({required this.sparkles});

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
      canvas.drawCircle(Offset.zero, s.size * 0.65, paint);
      canvas.drawCircle(
        Offset(-s.size * 0.18, -s.size * 0.18),
        s.size * 0.22,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ClawSparkleOverlayPainter oldDelegate) => true;
}

/// 캐비닛 바깥 화면 전체를 꾸며주는 아기자기한 카니발 아케이드 놀이방 배경 페인터
/// (파스텔 도트 벽지, 상단 축제 가랜드, 둥실둥실 풍선, 미소 구름, 반짝이 별, 파스텔 언덕)
class _CarnivalArcadeRoomBackgroundPainter extends CustomPainter {
  final double elapsed;

  _CarnivalArcadeRoomBackgroundPainter({required this.elapsed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 파스텔 도트 패턴 벽지
    const dotColors = [
      Color(0x22FF80AB),
      Color(0x224FC3F7),
      Color(0x22FFD54F),
      Color(0x22BA68C8),
      Color(0x2269F0AE),
    ];
    final dotPaint = Paint()..style = PaintingStyle.fill;
    const step = 42.0;
    int rowIdx = 0;
    for (double y = 44; y < h - 40; y += step) {
      final isOdd = rowIdx.isOdd;
      for (double x = isOdd ? step : step / 2; x < w; x += step) {
        dotPaint.color = dotColors[(rowIdx + (x ~/ step)) % dotColors.length];
        canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      }
      rowIdx++;
    }

    // 2. 상단 카니발 가랜드 깃발 (Bunting Flags)
    const flagColors = [
      Color(0xFFFF80AB),
      Color(0xFFFFCA28),
      Color(0xFF4FC3F7),
      Color(0xFFAB47BC),
      Color(0xFF66BB6A),
      Color(0xFFFF7043),
    ];
    final stringPath = Path()
      ..moveTo(-10, 10)
      ..quadraticBezierTo(w * 0.5, 34, w + 10, 10);
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    const int flagCount = 9;
    final flagW = w / (flagCount + 0.6);
    final flagH = flagW * 0.9;
    for (int i = 0; i < flagCount; i++) {
      final t = (i + 0.8) / (flagCount + 0.6);
      final fx = t * w;
      final fy = (1 - t) * (1 - t) * 10 + 2 * (1 - t) * t * 34 + t * t * 10;
      final sway = sin(elapsed * 2.2 + i * 0.7) * 2.5;
      final flagPath = Path()
        ..moveTo(fx - flagW * 0.44, fy)
        ..lineTo(fx + flagW * 0.44, fy)
        ..lineTo(fx + sway, fy + flagH)
        ..close();
      canvas.drawPath(
        flagPath,
        Paint()
          ..color = flagColors[i % flagColors.length].withValues(alpha: 0.82),
      );
    }

    // 3. 좌·우에 둥실둥실 떠다니는 파스텔 구름
    _drawSoftCloud(
      canvas,
      Offset(w * 0.14, h * 0.16 + sin(elapsed * 1.4) * 5),
      78,
      40,
    );
    _drawSoftCloud(
      canvas,
      Offset(w * 0.86, h * 0.19 + cos(elapsed * 1.4) * 5),
      72,
      36,
    );

    // 4. 둥실둥실 떠다니는 카니발 풍선 (좌·우 가장자리)
    _drawFloatingBalloon(
      canvas,
      Offset(w * 0.07, h * 0.36 + sin(elapsed * 2.0) * 8),
      const Color(0xFFFF80AB),
      15,
    );
    _drawFloatingBalloon(
      canvas,
      Offset(w * 0.93, h * 0.33 + cos(elapsed * 2.1 + 1.0) * 8),
      const Color(0xFF4FC3F7),
      16,
    );
    _drawFloatingBalloon(
      canvas,
      Offset(w * 0.06, h * 0.66 + cos(elapsed * 1.8 + 2.0) * 7),
      const Color(0xFFFFCA28),
      14,
    );
    _drawFloatingBalloon(
      canvas,
      Offset(w * 0.94, h * 0.68 + sin(elapsed * 1.9 + 1.5) * 7),
      const Color(0xFFBA68C8),
      15,
    );

    // 5. 하단 파스텔 동화 언덕 & 아케이드 바닥
    final hill1 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 85)
      ..quadraticBezierTo(w * 0.35, h - 120, w * 0.75, h - 75)
      ..quadraticBezierTo(w * 0.9, h - 55, w, h - 68)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      hill1,
      Paint()..color = const Color(0xFFE1BEE7).withValues(alpha: 0.45),
    );

    final hill2 = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 46)
      ..quadraticBezierTo(w * 0.3, h - 70, w * 0.65, h - 40)
      ..quadraticBezierTo(w * 0.85, h - 22, w, h - 38)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      hill2,
      Paint()..color = const Color(0xFFFFF59D).withValues(alpha: 0.55),
    );
  }

  void _drawSoftCloud(Canvas canvas, Offset center, double w, double h) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final r = h / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawCircle(Offset(-w * 0.22, 0), r * 0.85, p);
    canvas.drawCircle(Offset(0, -r * 0.28), r * 1.05, p);
    canvas.drawCircle(Offset(w * 0.24, 0), r * 0.8, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, r * 0.2), width: w * 0.85, height: r * 0.85),
        Radius.circular(r * 0.5),
      ),
      p,
    );
    canvas.restore();
  }

  void _drawFloatingBalloon(
      Canvas canvas, Offset center, Color color, double r) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 풍선 끈
    final stringPath = Path()
      ..moveTo(0, r * 1.15)
      ..quadraticBezierTo(4, r * 1.6, -2, r * 2.1);
    canvas.drawPath(
      stringPath,
      Paint()
        ..color = const Color(0xFF90A4AE).withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // 풍선 몸체
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 1.75, height: r * 2.1),
      Paint()..color = color.withValues(alpha: 0.68),
    );
    // 광택
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-r * 0.3, -r * 0.35), width: r * 0.4, height: r * 0.6),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(
          covariant _CarnivalArcadeRoomBackgroundPainter oldDelegate) =>
      oldDelegate.elapsed != elapsed;
}
