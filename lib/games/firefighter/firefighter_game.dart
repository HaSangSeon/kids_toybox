import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum FireGamePhase {
  missionSelect, // 미션 선택
  dispatch,      // 🚨 긴급 출동 질주
  extinguish,    // 🔥 물대포 화재 진압
  rescue,        // 🪜/🛟 동물 친구 에어매트 구출
  celebrate,     // 🎉 명예 소방관 배지 & 무지개 분수
}

class FireSpot {
  final int id;
  final String label;
  final Offset relativePos; // (0.0~1.0, 0.0~1.0)
  final double radius;
  double hp; // 100.0 -> 0.0
  bool isExtinguished;
  final String? trappedAnimal; // 동물 이모지 (예: 🐱)
  final String? animalName;

  double flamePhase;

  FireSpot({
    required this.id,
    required this.label,
    required this.relativePos,
    required this.radius,
    this.hp = 100.0,
    this.isExtinguished = false,
    this.trappedAnimal,
    this.animalName,
    this.flamePhase = 0.0,
  });
}

class FireMission {
  final int id;
  final String title;
  final String subTitle;
  final String emoji;
  final List<Color> skyGradient;
  final String buildingType; // 'apartment', 'forest', 'castle'
  final List<FireSpot> spots;
  final String rescuedAnimal;
  final String rescuedAnimalName;
  final String clearComment;

  FireMission({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.emoji,
    required this.skyGradient,
    required this.buildingType,
    required this.spots,
    required this.rescuedAnimal,
    required this.rescuedAnimalName,
    required this.clearComment,
  });
}

List<FireMission> _buildMissions() {
  return [
    FireMission(
      id: 1,
      title: '도심 아파트 큰불 진압',
      subTitle: '3층 창문에 아기 고양이가 갇혔어요! 삐뽀삐뽀!',
      emoji: '🏢',
      skyGradient: [const Color(0xFF60A5FA), const Color(0xFF93C5FD), const Color(0xFFE0F2FE)],
      buildingType: 'apartment',
      rescuedAnimal: '🐱',
      rescuedAnimalName: '아기 고양이 나비',
      clearComment: '야옹~ 고마워요 소방관님! 시원한 물로 불을 다 껐어요! 💖',
      spots: [
        FireSpot(id: 1, label: '3층 옥상', relativePos: const Offset(0.50, 0.30), radius: 42, flamePhase: 0.1),
        FireSpot(id: 2, label: '2층 왼쪽 창문', relativePos: const Offset(0.30, 0.46), radius: 38, flamePhase: 0.4),
        FireSpot(id: 3, label: '2층 오른쪽 창문', relativePos: const Offset(0.70, 0.46), radius: 38, trappedAnimal: '🐱', animalName: '아기 고양이', flamePhase: 0.7),
        FireSpot(id: 4, label: '1층 왼쪽 창문', relativePos: const Offset(0.30, 0.63), radius: 36, flamePhase: 0.2),
        FireSpot(id: 5, label: '1층 현관 입구', relativePos: const Offset(0.70, 0.63), radius: 36, flamePhase: 0.9),
      ],
    ),
    FireMission(
      id: 2,
      title: '푸른 숲속 산불 진압',
      subTitle: '숲속 큰 나무들이 불타고 있어요! 다람쥐를 구해요!',
      emoji: '🌲',
      skyGradient: [const Color(0xFF38BDF8), const Color(0xFF7DD3FC), const Color(0xFFF0FDF4)],
      buildingType: 'forest',
      rescuedAnimal: '🐿️',
      rescuedAnimalName: '꼬마 다람쥐 람이',
      clearComment: '찍찍! 숲속 친구들이 모두 안전해졌어요! 최고예요! 🌳',
      spots: [
        FireSpot(id: 1, label: '큰 참나무 꼭대기', relativePos: const Offset(0.30, 0.32), radius: 42, flamePhase: 0.3),
        FireSpot(id: 2, label: '단풍나무 가지', relativePos: const Offset(0.70, 0.34), radius: 40, trappedAnimal: '🐿️', animalName: '꼬마 다람쥐', flamePhase: 0.6),
        FireSpot(id: 3, label: '가운데 오두막집', relativePos: const Offset(0.50, 0.50), radius: 44, flamePhase: 0.1),
        FireSpot(id: 4, label: '풀숲 모닥불', relativePos: const Offset(0.24, 0.64), radius: 36, flamePhase: 0.8),
        FireSpot(id: 5, label: '오른쪽 덤불', relativePos: const Offset(0.76, 0.64), radius: 36, flamePhase: 0.5),
      ],
    ),
    FireMission(
      id: 3,
      title: '놀이동산 마법 성 구출',
      subTitle: '동화 속 성탑에 불이 났어요! 강아지를 구출해요!',
      emoji: '🏰',
      skyGradient: [const Color(0xFFA78BFA), const Color(0xFFC4B5FD), const Color(0xFFFDF4FF)],
      buildingType: 'castle',
      rescuedAnimal: '🐶',
      rescuedAnimalName: '용감한 강아지 멍이',
      clearComment: '멍멍! 마법 성이 반짝반짝 되살아났어요! 영웅 소방관 만세! 👑',
      spots: [
        FireSpot(id: 1, label: '중앙 높은 시계탑', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '왼쪽 뾰족탑', relativePos: const Offset(0.24, 0.42), radius: 38, flamePhase: 0.5),
        FireSpot(id: 3, label: '오른쪽 전망탑', relativePos: const Offset(0.76, 0.42), radius: 38, trappedAnimal: '🐶', animalName: '강아지 멍이', flamePhase: 0.8),
        FireSpot(id: 4, label: '성문 왼쪽 테라스', relativePos: const Offset(0.32, 0.60), radius: 36, flamePhase: 0.3),
        FireSpot(id: 5, label: '성문 오른쪽 테라스', relativePos: const Offset(0.68, 0.60), radius: 36, flamePhase: 0.7),
      ],
    ),
    FireMission(
      id: 4,
      title: '달콤한 빵집 구출 작전',
      subTitle: '달콤한 컵케이크 빵집에 불이 났어요! 곰돌이를 구해요!',
      emoji: '🧁',
      skyGradient: [const Color(0xFFFFB4A2), const Color(0xFFFFCDB2), const Color(0xFFFFF1E6)],
      buildingType: 'bakery',
      rescuedAnimal: '🐻',
      rescuedAnimalName: '아기 곰 곰이',
      clearComment: '달콤한 디저트 빵집을 안전하게 지켜줘서 고마워요! 🥐💖',
      spots: [
        FireSpot(id: 1, label: '컵케이크 옥상 간판', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '2층 딸기 창문', relativePos: const Offset(0.28, 0.44), radius: 38, flamePhase: 0.5),
        FireSpot(id: 3, label: '2층 초코 테라스', relativePos: const Offset(0.72, 0.44), radius: 38, trappedAnimal: '🐻', animalName: '아기 곰', flamePhase: 0.8),
        FireSpot(id: 4, label: '1층 빵 진열대', relativePos: const Offset(0.28, 0.62), radius: 36, flamePhase: 0.3),
        FireSpot(id: 5, label: '1층 오븐 출입구', relativePos: const Offset(0.72, 0.62), radius: 36, flamePhase: 0.6),
      ],
    ),
    FireMission(
      id: 5,
      title: '우주 로켓 기지 구출',
      subTitle: '발사대 우주선에 불꽃이 튀었어요! 우주 판다를 구해요!',
      emoji: '🚀',
      skyGradient: [const Color(0xFF3A6073), const Color(0xFF3A7BD5), const Color(0xFFE0EAFC)],
      buildingType: 'space',
      rescuedAnimal: '🐼',
      rescuedAnimalName: '우주비행사 판다',
      clearComment: '우주 탐사 로켓을 무사히 지켜냈어요! 판다도 신나요! 🚀✨',
      spots: [
        FireSpot(id: 1, label: '로켓 맨꼭대기 첨탑', relativePos: const Offset(0.50, 0.26), radius: 42, flamePhase: 0.1),
        FireSpot(id: 2, label: '우주선 왼쪽 날개', relativePos: const Offset(0.24, 0.42), radius: 40, flamePhase: 0.4),
        FireSpot(id: 3, label: '조종실 창문', relativePos: const Offset(0.76, 0.42), radius: 40, trappedAnimal: '🐼', animalName: '우주 판다', flamePhase: 0.7),
        FireSpot(id: 4, label: '부스터 엔진 1호', relativePos: const Offset(0.32, 0.62), radius: 38, flamePhase: 0.3),
        FireSpot(id: 5, label: '부스터 엔진 2호', relativePos: const Offset(0.68, 0.62), radius: 38, flamePhase: 0.9),
      ],
    ),
    FireMission(
      id: 6,
      title: '바다 위 보물선 구출',
      subTitle: '푸른 바다 위 멋진 해적선에 불이 났어요! 아기 사자를 구해요!',
      emoji: '🚢',
      skyGradient: [const Color(0xFF00B4DB), const Color(0xFF0083B0), const Color(0xFFE8F5E9)],
      buildingType: 'ship',
      rescuedAnimal: '🦁',
      rescuedAnimalName: '꼬마 선장 사자',
      clearComment: '어흥~! 바다의 보물선을 멋지게 구출했어요! 소방관님 최고! 🏴‍☠️👑',
      spots: [
        FireSpot(id: 1, label: '해적선 돛대 꼭대기', relativePos: const Offset(0.50, 0.28), radius: 44, flamePhase: 0.2),
        FireSpot(id: 2, label: '선장실 전망창', relativePos: const Offset(0.26, 0.44), radius: 38, trappedAnimal: '🦁', animalName: '꼬마 사자', flamePhase: 0.6),
        FireSpot(id: 3, label: '해적 깃발 돛', relativePos: const Offset(0.74, 0.44), radius: 40, flamePhase: 0.3),
        FireSpot(id: 4, label: '대포 발사 갑판', relativePos: const Offset(0.28, 0.62), radius: 36, flamePhase: 0.8),
        FireSpot(id: 5, label: '보물 상자 창고', relativePos: const Offset(0.72, 0.62), radius: 36, flamePhase: 0.5),
      ],
    ),
  ];
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLE SYSTEMS (Water Jet, Splashes, Embers, Smoke, Steam, Confetti)
// ═══════════════════════════════════════════════════════════════════════════════

class _WaterSplash {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;

  _WaterSplash({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.color,
  });
}

class _SteamParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  double maxLife;

  _SteamParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _EmberParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  Color color;

  _EmberParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.color,
  });
}

class _SmokeParticle {
  Offset pos;
  Offset vel;
  double radius;
  double life;
  double maxLife;

  _SmokeParticle({
    required this.pos,
    required this.vel,
    required this.radius,
    required this.life,
    required this.maxLife,
  });
}

class _ConfettiParticle {
  Offset pos;
  Offset vel;
  double size;
  Color color;
  double rotation;
  double rotSpeed;

  _ConfettiParticle({
    required this.pos,
    required this.vel,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotSpeed,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN GAME WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class FirefighterGame extends StatefulWidget {
  const FirefighterGame({super.key});

  @override
  State<FirefighterGame> createState() => _FirefighterGameState();
}

class _FirefighterGameState extends State<FirefighterGame>
    with TickerProviderStateMixin {
  FireGamePhase _phase = FireGamePhase.missionSelect;
  late List<FireMission> _missions;
  late FireMission _currentMission;

  // Background Cloud & Sun Animation
  late AnimationController _cloudAnimCtrl;
  late AnimationController _sunAnimCtrl;

  // Dispatch Phase variables
  late AnimationController _dispatchAnimCtrl;
  late AnimationController _sirenLightCtrl;
  late AnimationController _truckBounceCtrl;
  double _dispatchProgress = 0.0;
  final List<Offset> _roadItems = [];
  DateTime _lastEngineSoundTime = DateTime.now(); // 소방차 주행 엔진음 타이머

  // Extinguish Phase variables
  late AnimationController _gameLoopCtrl;
  final Random _rng = Random();
  Offset? _touchPos;
  bool _isSpraying = false;
  final List<_WaterSplash> _splashes = [];
  final List<_SteamParticle> _steamParticles = [];
  final List<_EmberParticle> _embers = [];
  final List<_SmokeParticle> _smokes = [];
  DateTime _lastWaterSoundTime = DateTime.now();
  DateTime _lastSteamSoundTime = DateTime.now();

  // Rescue Phase variables
  double _trampolineX = 0.5;
  double _fallingAnimalX = 0.5;
  double _fallingAnimalY = 0.24;
  double _fallingVelocityY = 0.005;
  int _bounceCount = 0;
  bool _isRescued = false;
  late AnimationController _rescueCheerCtrl;

  // Celebrate Phase variables
  final List<_ConfettiParticle> _confetti = [];
  late AnimationController _celebrateCtrl;

  @override
  void initState() {
    super.initState();
    _missions = _buildMissions();
    _currentMission = _missions[0];

    _cloudAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _sunAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _sirenLightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..repeat(reverse: true);

    _truckBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);

    _dispatchAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _gameLoopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _gameLoopCtrl.addListener(_updatePhysics);

    _rescueCheerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    AudioManager.instance.stopFireSiren();
    _cloudAnimCtrl.dispose();
    _sunAnimCtrl.dispose();
    _sirenLightCtrl.dispose();
    _truckBounceCtrl.dispose();
    _dispatchAnimCtrl.dispose();
    _gameLoopCtrl.dispose();
    _rescueCheerCtrl.dispose();
    _celebrateCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MISSION MANAGEMENT & FLOW
  // ─────────────────────────────────────────────────────────────────────────────

  void _startMission(FireMission mission) {
    setState(() {
      _currentMission = mission;
      for (final spot in _currentMission.spots) {
        spot.hp = 100.0;
        spot.isExtinguished = false;
      }
      _splashes.clear();
      _steamParticles.clear();
      _embers.clear();
      _smokes.clear();
      _confetti.clear();
      _isRescued = false;
      _bounceCount = 0;
      _fallingAnimalY = 0.24;
      _fallingAnimalX = 0.5;
      _fallingVelocityY = 0.005;
      _phase = FireGamePhase.dispatch;
      _dispatchProgress = 0.0;
      _generateRoadItems();
    });

    // Authentic Fire Engine Siren ("삐뽀~ 삐뽀~")
    AudioManager.instance.playFireSiren();

    _dispatchAnimCtrl.reset();
    _dispatchAnimCtrl.duration = const Duration(seconds: 4);
    _dispatchAnimCtrl.forward();

    _dispatchAnimCtrl.addListener(() {
      if (mounted && _phase == FireGamePhase.dispatch) {
        setState(() {
          _dispatchProgress = _dispatchAnimCtrl.value;
        });
        if (_dispatchAnimCtrl.isCompleted) {
          _arriveAtScene();
        }
      }
    });
  }

  void _generateRoadItems() {
    _roadItems.clear();
    for (int i = 0; i < 6; i++) {
      _roadItems.add(Offset(0.18 + (i * 0.14), _rng.nextDouble() * 0.4 + 0.3));
    }
  }

  void _arriveAtScene() {
    if (_phase != FireGamePhase.dispatch) return;
    HapticFeedback.mediumImpact();
    AudioManager.instance.playCrash();
    setState(() {
      _phase = FireGamePhase.extinguish;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 60FPS PHYSICS UPDATE (Water Jet, Realistic Flames, Splashes, Smoke, Steam)
  // ─────────────────────────────────────────────────────────────────────────────

  void _updatePhysics() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;

    // 🚒 소방차 주행 중 엔진음 재생 (dispatch 페이즈)
    if (_phase == FireGamePhase.dispatch) {
      final now = DateTime.now();
      if (now.difference(_lastEngineSoundTime).inMilliseconds > 900) {
        _lastEngineSoundTime = now;
        AudioManager.instance.playEngine();
      }
    }

    // Update Flame Phases, Embers & Smoke
    if (_phase == FireGamePhase.extinguish) {
      for (final spot in _currentMission.spots) {
        spot.flamePhase += 0.09;
        if (!spot.isExtinguished) {
          final spotCenter = Offset(
            spot.relativePos.dx * screenSize.width,
            spot.relativePos.dy * screenSize.height,
          );

          // Flying Embers
          if (_embers.length < 35 && _rng.nextDouble() < 0.4) {
            _embers.add(_EmberParticle(
              pos: spotCenter + Offset((_rng.nextDouble() - 0.5) * spot.radius * 1.1, (_rng.nextDouble() - 0.5) * spot.radius * 0.5),
              vel: Offset((_rng.nextDouble() - 0.5) * 2.2, -_rng.nextDouble() * 3.5 - 1.2),
              radius: 2.0 + _rng.nextDouble() * 2.5,
              life: 1.0,
              color: _rng.nextBool() ? const Color(0xFFFFD54F) : const Color(0xFFFF5722),
            ));
          }

          // Billowing Smoke
          if (_smokes.length < 25 && _rng.nextDouble() < 0.25) {
            _smokes.add(_SmokeParticle(
              pos: spotCenter + Offset((_rng.nextDouble() - 0.5) * spot.radius * 0.8, -spot.radius * 0.6),
              vel: Offset((_rng.nextDouble() - 0.5) * 1.4, -_rng.nextDouble() * 2.0 - 1.0),
              radius: 12.0 + _rng.nextDouble() * 14.0,
              life: 1.0,
              maxLife: 1.0,
            ));
          }
        }
      }

      for (int i = _embers.length - 1; i >= 0; i--) {
        final ember = _embers[i];
        ember.pos += ember.vel;
        ember.life -= 0.035;
        if (ember.life <= 0) _embers.removeAt(i);
      }

      for (int i = _smokes.length - 1; i >= 0; i--) {
        final smoke = _smokes[i];
        smoke.pos += smoke.vel;
        smoke.radius += 0.4;
        smoke.life -= 0.025;
        if (smoke.life <= 0) _smokes.removeAt(i);
      }
    }

    // High Pressure Water Jet & Target Impact Detection
    if (_phase == FireGamePhase.extinguish) {
      if (_isSpraying && _touchPos != null) {
        final now = DateTime.now();
        if (now.difference(_lastWaterSoundTime).inMilliseconds > 180) {
          _lastWaterSoundTime = now;
          AudioManager.instance.playFireHoseSpray();
        }

        // Spawn Impact Splashes at Touch Point
        for (int i = 0; i < 4; i++) {
          final splashAngle = _rng.nextDouble() * 2 * pi;
          final splashSpeed = _rng.nextDouble() * 7.0 + 3.0;
          _splashes.add(_WaterSplash(
            pos: _touchPos! + Offset((_rng.nextDouble() - 0.5) * 12, (_rng.nextDouble() - 0.5) * 12),
            vel: Offset(cos(splashAngle) * splashSpeed, sin(splashAngle) * splashSpeed - 2.0),
            radius: 3.5 + _rng.nextDouble() * 4.0,
            life: 1.0,
            color: const Color(0xFF38BDF8),
          ));
        }

        // Check if Water Stream / Impact hits any Fire Spot
        if (_phase == FireGamePhase.extinguish) {
          for (final spot in _currentMission.spots) {
            if (!spot.isExtinguished) {
              final spotCenter = Offset(
                spot.relativePos.dx * screenSize.width,
                spot.relativePos.dy * screenSize.height,
              );
              final d = (_touchPos! - spotCenter).distance;
              if (d < spot.radius + 28) {
                // Hit Fire!
                spot.hp -= 2.0;

                // Spawn Sizzling Steam
                _steamParticles.add(_SteamParticle(
                  pos: _touchPos!,
                  vel: Offset((_rng.nextDouble() - 0.5) * 3.0, -_rng.nextDouble() * 3.5 - 1.5),
                  radius: 12.0 + _rng.nextDouble() * 12.0,
                  life: 1.0,
                  maxLife: 1.0,
                ));

                if (now.difference(_lastSteamSoundTime).inMilliseconds > 220) {
                  _lastSteamSoundTime = now;
                  AudioManager.instance.playFireSteamHiss();
                  HapticFeedback.selectionClick();
                }

                if (spot.hp <= 0 && !spot.isExtinguished) {
                  spot.hp = 0;
                  spot.isExtinguished = true;
                  AudioManager.instance.playFireExtinguishPop();
                  HapticFeedback.mediumImpact();
                  _checkAllFiresExtinguished();
                }
              }
            }
          }
        }
      }

      // Update Splashes
      for (int i = _splashes.length - 1; i >= 0; i--) {
        final s = _splashes[i];
        s.pos += s.vel;
        s.vel = Offset(s.vel.dx * 0.96, s.vel.dy + 0.35); // gravity
        s.life -= 0.035;
        if (s.life <= 0) _splashes.removeAt(i);
      }

      // Update Steam
      for (int i = _steamParticles.length - 1; i >= 0; i--) {
        final steam = _steamParticles[i];
        steam.pos += steam.vel;
        steam.radius += 0.6;
        steam.life -= 0.04;
        if (steam.life <= 0) _steamParticles.removeAt(i);
      }
    }

    // Rescue Phase
    if (_phase == FireGamePhase.rescue && !_isRescued) {
      _fallingAnimalY += _fallingVelocityY;
      _fallingVelocityY += 0.00035;

      if (_fallingAnimalY >= 0.70 && _fallingAnimalY <= 0.78) {
        final diff = (_fallingAnimalX - _trampolineX).abs();
        if (diff < 0.16) {
          _bounceCount++;
          AudioManager.instance.playBoing();
          HapticFeedback.heavyImpact();

          if (_bounceCount >= 2) {
            _isRescued = true;
            _fallingAnimalY = 0.74;
            _rescueCheerCtrl.forward(from: 0.0);
            AudioManager.instance.playFireRescueCheer(_currentMission.rescuedAnimal);
            Future.delayed(const Duration(milliseconds: 1400), () {
              _completeMission();
            });
          } else {
            _fallingVelocityY = -0.013;
            _fallingAnimalX += (_rng.nextDouble() - 0.5) * 0.08;
            _fallingAnimalX = _fallingAnimalX.clamp(0.2, 0.8);
          }
        }
      } else if (_fallingAnimalY > 0.85) {
        _bounceCount++;
        _isRescued = true;
        _fallingAnimalY = 0.74;
        _rescueCheerCtrl.forward(from: 0.0);
        AudioManager.instance.playFireRescueCheer(_currentMission.rescuedAnimal);
        Future.delayed(const Duration(milliseconds: 1400), () {
          _completeMission();
        });
      }
    }

    // Confetti
    if (_phase == FireGamePhase.celebrate) {
      if (_confetti.length < 50 && _rng.nextDouble() < 0.3) {
        final colors = [Colors.redAccent, Colors.amber, Colors.lightGreenAccent, Colors.cyanAccent, Colors.pinkAccent, Colors.purpleAccent, Colors.white];
        _confetti.add(_ConfettiParticle(
          pos: Offset(_rng.nextDouble() * screenSize.width, -10),
          vel: Offset((_rng.nextDouble() - 0.5) * 3, _rng.nextDouble() * 4 + 2),
          size: _rng.nextDouble() * 8 + 6,
          color: colors[_rng.nextInt(colors.length)],
          rotation: _rng.nextDouble() * 2 * pi,
          rotSpeed: (_rng.nextDouble() - 0.5) * 0.2,
        ));
      }

      for (int i = _confetti.length - 1; i >= 0; i--) {
        final c = _confetti[i];
        c.pos += c.vel;
        c.rotation += c.rotSpeed;
        if (c.pos.dy > screenSize.height) _confetti.removeAt(i);
      }
    }

    setState(() {});
  }

  void _checkAllFiresExtinguished() {
    final allClear = _currentMission.spots.every((s) => s.isExtinguished);
    if (allClear) {
      HapticFeedback.heavyImpact();
      AudioManager.instance.playTraceSuccess();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _phase = FireGamePhase.rescue;
            _fallingAnimalY = 0.24;
            _fallingAnimalX = 0.5;
            _fallingVelocityY = 0.004;
            _bounceCount = 0;
            _isRescued = false;
          });
        }
      });
    }
  }

  void _completeMission() {
    setState(() {
      _phase = FireGamePhase.celebrate;
      _isSpraying = false;
      _touchPos = null;
      _splashes.clear();
    });
    AudioManager.instance.playFireMissionVictory();
    HapticFeedback.heavyImpact();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAIN BUILD METHOD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dynamic Animated Sky Background
          _buildSceneBackground(),

          // 2. Structured Layout with SafeArea & Generous Breathing Space
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Unified Top App Bar Header
                _buildTopAppBar(),

                const SizedBox(height: 14),

                // Main Game Phase Content
                Expanded(
                  child: _buildPhaseContent(),
                ),
              ],
            ),
          ),

          // 3. 60FPS Realistic Flames, Smoke, Water Jet Stream, Steam, Splashes & Confetti
          if (_phase == FireGamePhase.extinguish || _phase == FireGamePhase.celebrate)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FireAndWaterEffectsPainter(
                    spots: _currentMission.spots,
                    embers: _embers,
                    smokes: _smokes,
                    splashes: _splashes,
                    steamParticles: _steamParticles,
                    confetti: _confetti,
                    isSpraying: _phase == FireGamePhase.extinguish && _isSpraying,
                    touchPos: _phase == FireGamePhase.extinguish ? _touchPos : null,
                    screenSize: MediaQuery.of(context).size,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case FireGamePhase.missionSelect:
        return _buildMissionSelectView();
      case FireGamePhase.dispatch:
        return _buildDispatchView();
      case FireGamePhase.extinguish:
        return _buildExtinguishView();
      case FireGamePhase.rescue:
        return _buildRescueView();
      case FireGamePhase.celebrate:
        return _buildCelebrateView();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DYNAMIC LIVELY SKY BACKGROUND
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSceneBackground() {
    List<Color> skyColors;
    if (_phase == FireGamePhase.missionSelect) {
      skyColors = const [Color(0xFF67B6FF), Color(0xFFA5E6FF), Color(0xFFFFF9E6)];
    } else {
      skyColors = _currentMission.skyGradient;
    }

    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ),
      ),
      child: Stack(
        children: [
          // ☀️ Warm Sunshine
          Positioned(
            top: 14,
            right: 18,
            child: AnimatedBuilder(
              animation: _sunAnimCtrl,
              builder: (context, child) {
                final scale = 1.0 + (_sunAnimCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD166),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ☁️ Drifting Fluffy Animated Clouds
          AnimatedBuilder(
            animation: _cloudAnimCtrl,
            builder: (context, child) {
              final progress = _cloudAnimCtrl.value;
              final c1x = (progress * (width + 120)) - 60;
              final c2x = (((progress + 0.5) % 1.0) * (width + 140)) - 70;

              return Stack(
                children: [
                  Positioned(
                    top: 28,
                    left: c1x,
                    child: Opacity(
                      opacity: 0.85,
                      child: Text('☁️', style: TextStyle(fontSize: 44, color: Colors.white.withValues(alpha: 0.95))),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: c2x,
                    child: Opacity(
                      opacity: 0.75,
                      child: Text('☁️', style: TextStyle(fontSize: 34, color: Colors.white.withValues(alpha: 0.90))),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UNIFIED TOP APP BAR
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTopAppBar() {
    final extinguishedCount = _currentMission.spots.where((s) => s.isExtinguished).length;
    final totalSpots = _currentMission.spots.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🏠 Home / Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AudioManager.instance.playClick();
                if (_phase == FireGamePhase.missionSelect) {
                  Navigator.of(context).pop();
                } else {
                  setState(() {
                    _phase = FireGamePhase.missionSelect;
                  });
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF5964), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, color: Color(0xFFFF5964), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _phase == FireGamePhase.missionSelect ? '로비로' : '미션 목록',
                      style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2B2D42)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title or In-Game Extinguish Progress Pill
          if (_phase == FireGamePhase.extinguish)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💧', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '진압: $extinguishedCount / $totalSpots',
                    style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF0284C7)),
                  ),
                ],
              ),
            )
          else
            AnimatedBuilder(
              animation: _sirenLightCtrl,
              builder: (context, child) {
                final isRed = _sirenLightCtrl.value > 0.5;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRed ? const Color(0xFFFF3366) : const Color(0xFF3399FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isRed ? const Color(0xFFFF3366) : const Color(0xFF3399FF)).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isRed ? '🚨' : '🚒', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '출동! 꼬마 소방대',
                        style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2B2D42)),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 🔊 Sound Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  AudioManager.instance.toggleSound();
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFFFF9F1C),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. MISSION SELECT VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMissionSelectView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: KidsTheme.toyDecoration(
              color: Colors.white,
              borderRadius: 22,
            ),
            child: Row(
              children: [
                const Text('🚒', style: TextStyle(fontSize: 38)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '삐뽀삐뽀! 긴급 출동 미션!',
                        style: GoogleFonts.jua(fontSize: 20, color: const Color(0xFFFF5964)),
                      ),
                      Text(
                        '도움이 필요한 곳을 골라 출동해주세요! 💦',
                        style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _missions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final m = _missions[index];
                return GestureDetector(
                  onTap: () => _startMission(m),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: KidsTheme.toyDecoration(
                      color: Colors.white,
                      borderRadius: 22,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [m.skyGradient.first, m.skyGradient.last],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Text(m.emoji, style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5964),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '미션 0${m.id}',
                                      style: GoogleFonts.jua(fontSize: 11, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '구출: ${m.rescuedAnimal}',
                                    style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFFF9F1C)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.title,
                                style: GoogleFonts.jua(fontSize: 17, color: const Color(0xFF2B2D42)),
                              ),
                              Text(
                                m.subTitle,
                                style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text('출동!', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                            ],
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DISPATCH VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDispatchView() {
    final width = MediaQuery.of(context).size.width;
    final truckX = (_dispatchProgress * (width - 130)).clamp(15.0, width - 140);

    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: KidsTheme.toyDecoration(
              color: Colors.white,
              borderRadius: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      '긴급 출동 중! 삐용~ 삐용~!',
                      style: GoogleFonts.jua(fontSize: 20, color: const Color(0xFFFF3366)),
                    ),
                    const SizedBox(width: 8),
                    const Text('🚨', style: TextStyle(fontSize: 22)),
                  ],
                ),
                Text(
                  '소방차를 탭해서 부스터 가속을 해보세요! 💨',
                  style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),

        // Road with animated Fire Engine
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          height: 190,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              border: const Border(
                top: BorderSide(color: Color(0xFF94A3B8), width: 5),
                bottom: BorderSide(color: Color(0xFF334155), width: 8),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (index) => Container(
                        width: 30,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                for (int i = 0; i < _roadItems.length; i++)
                  Positioned(
                    left: _roadItems[i].dx * width,
                    top: _roadItems[i].dy * 120,
                    child: GestureDetector(
                      onTap: () {
                        AudioManager.instance.playDecalStamp();
                        HapticFeedback.lightImpact();
                        setState(() {
                          _roadItems.removeAt(i);
                        });
                      },
                      child: const Text('💧', style: TextStyle(fontSize: 26)),
                    ),
                  ),
                Positioned(
                  left: truckX,
                  top: 26 + (_truckBounceCtrl.value * 5),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playFireSiren();
                      HapticFeedback.heavyImpact();
                      _dispatchAnimCtrl.duration = const Duration(seconds: 2);
                    },
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _sirenLightCtrl,
                          builder: (context, child) {
                            final light = _sirenLightCtrl.value > 0.5;
                            return Container(
                              width: 22,
                              height: 12,
                              decoration: BoxDecoration(
                                color: light ? Colors.redAccent : Colors.cyanAccent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (light ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.9),
                                    blurRadius: 12,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(pi),
                          child: const Text('🚒', style: TextStyle(fontSize: 70)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 20,
          left: 40,
          right: 40,
          child: GestureDetector(
            onTap: _arriveAtScene,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: KidsTheme.toyDecoration(
                color: const Color(0xFF06D6A0),
                borderRadius: 20,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '현장 도착! 불 끄러 가기 ➡️',
                      style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. EXTINGUISH VIEW (Spacious & Clean, Real Fire & Hose)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildExtinguishView() {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        setState(() {
          _isSpraying = true;
          _touchPos = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _touchPos = details.localPosition;
        });
      },
      onPanEnd: (_) {
        setState(() {
          _isSpraying = false;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Spacious Scene Illustration (Starting comfortably below the header)
          _buildSceneIllustration(),

          // Fire Spots (HP Bars & Animals)
          for (final spot in _currentMission.spots)
            Positioned(
              left: spot.relativePos.dx * screenSize.width - spot.radius,
              top: spot.relativePos.dy * screenSize.height - spot.radius,
              child: _buildFireSpotWidget(spot),
            ),

          // Bottom Firefighter with Realistic Brass Nozzle & Hose
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: _buildRealisticFiremanAndHose(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneIllustration() {
    final type = _currentMission.buildingType;
    return Positioned.fill(
      child: CustomPaint(
        painter: _BuildingScenePainter(type: type),
      ),
    );
  }

  Widget _buildFireSpotWidget(FireSpot spot) {
    if (spot.isExtinguished) {
      return SizedBox(
        width: spot.radius * 2,
        height: spot.radius * 2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (spot.trappedAnimal != null) ...[
                Transform.scale(
                  scale: 1.15,
                  child: Text(spot.trappedAnimal!, style: const TextStyle(fontSize: 36)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF007F),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 4),
                    ],
                  ),
                  child: const Text('살았다! 💖', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Text('✨', style: TextStyle(fontSize: 28)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('진압 완료!', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Active Flame & Emotional Trapped Animal Pleading for Help
    final isLowHp = spot.hp < 45.0;
    final textPlea = isLowHp ? '조금만 더! 😃' : '살려줘요! 😭';

    return SizedBox(
      width: spot.radius * 2,
      height: spot.radius * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 🔥 HP 게이지 — 불꽃 바로 위에 배치 (잘 보이도록)
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🔥 ${spot.hp.toInt()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white54, width: 0.8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (spot.hp / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: spot.hp > 60
                              ? [const Color(0xFFFF4500), const Color(0xFFFF8C00)]
                              : spot.hp > 30
                                  ? [const Color(0xFFFF8C00), const Color(0xFFFFD700)]
                                  : [const Color(0xFF00E676), const Color(0xFF69F0AE)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trapped animal with shivering, teardrops, and crying speech bubble
          if (spot.trappedAnimal != null)
            Positioned(
              top: 15,
              child: Column(
                children: [
                  // Cute Pulsing Speech Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isLowHp ? Colors.orangeAccent : Colors.redAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          textPlea,
                          style: GoogleFonts.jua(fontSize: 10, color: isLowHp ? Colors.deepOrange : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Shivering Animal Face with Splashing Tears
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(sin(spot.flamePhase * 8.0) * 1.5, 0),
                        child: Text(spot.trappedAnimal!, style: const TextStyle(fontSize: 28)),
                      ),
                      if (!isLowHp) ...[
                        // Left & Right Splashing Tears
                        Positioned(
                          left: -6,
                          top: 4,
                          child: Transform.rotate(
                            angle: -0.4,
                            child: const Text('💧', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: 4,
                          child: Transform.rotate(
                            angle: 0.4,
                            child: const Text('💧', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildRealisticFiremanAndHose() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 노즐 방향 계산
    double nozzleAngle = -pi / 2;
    if (_touchPos != null) {
      final firemanCenterX = screenWidth * 0.5;
      final firemanCenterY = screenHeight * 0.92;
      final dx = _touchPos!.dx - firemanCenterX;
      final dy = _touchPos!.dy - firemanCenterY;
      nozzleAngle = atan2(dy, dx);
    }

    return SizedBox(
      width: screenWidth,
      height: 130,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 💧 구불구불한 실물 소방 호스 (CustomPainter)
          Positioned.fill(
            child: CustomPaint(
              painter: _FireHosePainter(
                nozzleAngle: nozzleAngle,
                isSpraying: _isSpraying,
                screenWidth: screenWidth,
              ),
            ),
          ),

          // 🧑‍🚒 소방관 + 말풍선
          Positioned(
            bottom: 0,
            left: screenWidth * 0.22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('🧑‍🚒', style: TextStyle(fontSize: 52)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                  ),
                  child: Text(
                    _isSpraying ? '솨아아-! 💦' : '터치하여 물대포 발사!',
                    style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. RESCUE VIEW (Adorable Parachute & Golden Safety Trampoline)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRescueView() {
    final screenSize = MediaQuery.of(context).size;
    final animalX = _fallingAnimalX * screenSize.width;
    final animalY = _fallingAnimalY * screenSize.height;
    final trampolinePixelX = _trampolineX * screenSize.width;

    // Gentle pendulum sway while floating down
    final swayAngle = sin(_fallingAnimalY * 20.0) * 0.14;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        setState(() {
          _trampolineX = (details.localPosition.dx / screenSize.width).clamp(0.15, 0.85);
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildSceneIllustration(),

          // Floating Baby Animal with Parachute & Sparkles
          Positioned(
            left: animalX - 38,
            top: animalY - 60,
            child: Transform.rotate(
              angle: _isRescued ? 0.0 : swayAngle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🪂 Colorful Striped Parachute Canopy
                  if (!_isRescued) ...[
                    Container(
                      width: 72,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5964),
                            Color(0xFFFFD166),
                            Color(0xFF06D6A0),
                            Color(0xFF118AB2),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🪂', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Cute Animal with Sparkles & Heart Reaction
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Text(
                        _currentMission.rescuedAnimal,
                        style: TextStyle(fontSize: _isRescued ? 58 : 46),
                      ),
                      if (!_isRescued)
                        Positioned(
                          top: -10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.pinkAccent, width: 1.5),
                            ),
                            child: Text(
                              _bounceCount > 0 ? '통통~! 🌟' : '받아주세요~!',
                              style: GoogleFonts.jua(fontSize: 11, color: Colors.pink, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (_isRescued)
                        Positioned(
                          top: -14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💖', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '구출 성공! 고마워요!',
                                  style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Golden Cushioned Safety Trampoline (Air-Mat)
          Positioned(
            left: trampolinePixelX - 65,
            top: screenSize.height * 0.74,
            child: Column(
              children: [
                Container(
                  width: 130,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFB8500).withValues(alpha: 0.55),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '안전 에어매트',
                        style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text('🌟', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🧑‍🚒', style: TextStyle(fontSize: 34)),
                    SizedBox(width: 48),
                    Text('🧑‍🚒', style: TextStyle(fontSize: 34)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. CELEBRATE VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCelebrateView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildSceneIllustration(),
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: KidsTheme.toyDecoration(
                  color: Colors.white,
                  borderRadius: 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎖️', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 6),
                    Text(
                      '미션 완료! 최고의 소방 영웅!',
                      style: GoogleFonts.jua(fontSize: 23, color: const Color(0xFFFF5964)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentMission.rescuedAnimal, style: const TextStyle(fontSize: 34)),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _currentMission.clearComment,
                              style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          GestureDetector(
                            onTap: () => _startMission(_currentMission),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: KidsTheme.toyDecoration(
                                color: const Color(0xFFFF9F1C),
                                borderRadius: 18,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 4),
                                  Text('다시 하기', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final nextId = (_currentMission.id % _missions.length) + 1;
                              final nextMission = _missions.firstWhere((m) => m.id == nextId);
                              _startMission(nextMission);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: KidsTheme.toyDecoration(
                                color: const Color(0xFF06D6A0),
                                borderRadius: 18,
                              ),
                              child: Row(
                                children: [
                                  Text('다음 출동! ➡️', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
                                ],
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
        ],
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAILED SCENE ILLUSTRATION PAINTER (Spacious Layout)
// ═══════════════════════════════════════════════════════════════════════════════

class _BuildingScenePainter extends CustomPainter {
  final String type;
  _BuildingScenePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    if (type == 'apartment') {
      _drawApartment(canvas, size);
    } else if (type == 'forest') {
      _drawForest(canvas, size);
    } else if (type == 'castle') {
      _drawCastle(canvas, size);
    } else if (type == 'bakery') {
      _drawBakery(canvas, size);
    } else if (type == 'space') {
      _drawSpaceStation(canvas, size);
    } else if (type == 'ship') {
      _drawPirateShip(canvas, size);
    } else {
      _drawApartment(canvas, size);
    }
  }

  void _drawApartment(Canvas canvas, Size size) {
    final buildingPaint = Paint()..color = const Color(0xFFE2E8F0);
    final brickLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.5;
    final roofPaint = Paint()..color = const Color(0xFFEF4444);
    final windowFramePaint = Paint()..color = const Color(0xFF3B82F6);
    final glassPaint = Paint()..color = const Color(0xFFBFDBFE);

    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final top = size.height * 0.25; // Adjusted down for generous breathing room
    final bottom = size.height * 0.76;

    // Red Roof
    final roofPath = Path()
      ..moveTo(left - 12, top)
      ..lineTo(right + 12, top)
      ..lineTo(right - 10, top - 32)
      ..lineTo(left + 10, top - 32)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Building Wall
    final rrect = RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(14));
    canvas.drawRRect(rrect, buildingPaint);

    // Brick Pattern Lines
    for (double y = top + 20; y < bottom; y += 24) {
      canvas.drawLine(Offset(left, y), Offset(right, y), brickLinePaint);
    }

    // Windows Grid (3 rows x 2 cols)
    final winWidth = (right - left) * 0.32;
    final winHeight = (bottom - top) * 0.22;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final wx = left + 22 + col * (winWidth + 24);
        final wy = top + 18 + row * (winHeight + 16);
        final winRRect = RRect.fromLTRBR(wx, wy, wx + winWidth, wy + winHeight, const Radius.circular(10));
        canvas.drawRRect(winRRect, windowFramePaint);
        final innerRRect = RRect.fromLTRBR(wx + 4, wy + 4, wx + winWidth - 4, wy + winHeight - 4, const Radius.circular(8));
        canvas.drawRRect(innerRRect, glassPaint);

        final barPaint = Paint()..color = Colors.white..strokeWidth = 2;
        canvas.drawLine(Offset(wx + winWidth * 0.5, wy + 4), Offset(wx + winWidth * 0.5, wy + winHeight - 4), barPaint);
        canvas.drawLine(Offset(wx + 4, wy + winHeight * 0.5), Offset(wx + winWidth - 4, wy + winHeight * 0.5), barPaint);
      }
    }
  }

  void _drawForest(Canvas canvas, Size size) {
    final trunkPaint = Paint()..color = const Color(0xFF8B5A2B);
    final leavesPaint1 = Paint()..color = const Color(0xFF22C55E);
    final leavesPaint2 = Paint()..color = const Color(0xFF16A34A);

    // Left Giant Oak Tree
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.23, size.height * 0.38, size.width * 0.37, size.height * 0.76, const Radius.circular(8)), trunkPaint);
    canvas.drawCircle(Offset(size.width * 0.30, size.height * 0.32), size.width * 0.24, leavesPaint1);
    canvas.drawCircle(Offset(size.width * 0.24, size.height * 0.36), size.width * 0.16, leavesPaint2);

    // Right Pine Tree
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.63, size.height * 0.40, size.width * 0.77, size.height * 0.76, const Radius.circular(8)), trunkPaint);
    canvas.drawCircle(Offset(size.width * 0.70, size.height * 0.34), size.width * 0.22, leavesPaint2);

    // Cozy Forest Cabin
    final cabinPaint = Paint()..color = const Color(0xFFD97706);
    canvas.drawRRect(
      RRect.fromLTRBR(size.width * 0.36, size.height * 0.48, size.width * 0.64, size.height * 0.76, const Radius.circular(12)),
      cabinPaint,
    );
    final roofCabin = Path()
      ..moveTo(size.width * 0.30, size.height * 0.48)
      ..lineTo(size.width * 0.50, size.height * 0.36)
      ..lineTo(size.width * 0.70, size.height * 0.48)
      ..close();
    canvas.drawPath(roofCabin, Paint()..color = const Color(0xFFB91C1C));
  }

  void _drawCastle(Canvas canvas, Size size) {
    final stonePaint = Paint()..color = const Color(0xFFDDD6FE);
    final turretPaint = Paint()..color = const Color(0xFFC084FC);
    final roofPaint = Paint()..color = const Color(0xFFF43F5E);

    // Center Grand Tower
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.35, size.height * 0.28, size.width * 0.65, size.height * 0.76, const Radius.circular(12)), stonePaint);
    final centerRoof = Path()
      ..moveTo(size.width * 0.32, size.height * 0.28)
      ..lineTo(size.width * 0.50, size.height * 0.14)
      ..lineTo(size.width * 0.68, size.height * 0.28)
      ..close();
    canvas.drawPath(centerRoof, roofPaint);

    // Left Castle Turret
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.12, size.height * 0.38, size.width * 0.32, size.height * 0.76, const Radius.circular(10)), turretPaint);
    final leftRoof = Path()
      ..moveTo(size.width * 0.10, size.height * 0.38)
      ..lineTo(size.width * 0.22, size.height * 0.24)
      ..lineTo(size.width * 0.34, size.height * 0.38)
      ..close();
    canvas.drawPath(leftRoof, roofPaint);

    // Right Castle Turret
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.68, size.height * 0.38, size.width * 0.88, size.height * 0.76, const Radius.circular(10)), turretPaint);
    final rightRoof = Path()
      ..moveTo(size.width * 0.66, size.height * 0.38)
      ..lineTo(size.width * 0.78, size.height * 0.24)
      ..lineTo(size.width * 0.90, size.height * 0.38)
      ..close();
    canvas.drawPath(rightRoof, roofPaint);
  }

  void _drawBakery(Canvas canvas, Size size) {
    final bakeryWallPaint = Paint()..color = const Color(0xFFFFF0F5);
    final creamTrimPaint = Paint()..color = const Color(0xFFFFB6C1);
    final left = size.width * 0.14;
    final right = size.width * 0.86;
    final top = size.height * 0.28;
    final bottom = size.height * 0.76;

    // Main Bakery Wall
    canvas.drawRRect(RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(16)), bakeryWallPaint);
    canvas.drawRRect(RRect.fromLTRBR(left, top, right, bottom, const Radius.circular(16)), Paint()..color = creamTrimPaint.color..style = PaintingStyle.stroke..strokeWidth = 4);

    // Giant Strawberry Cupcake on Roof
    final cupcakePaint = Paint()..color = const Color(0xFFFF69B4);
    canvas.drawCircle(Offset(size.width * 0.5, top - 18), 32, cupcakePaint);
    canvas.drawCircle(Offset(size.width * 0.5, top - 38), 12, Paint()..color = const Color(0xFFFF1744)); // Cherry

    // Red & White Striped Awning
    final awningWidth = (right - left) / 6;
    for (int i = 0; i < 6; i++) {
      final awLeft = left + (i * awningWidth);
      final awColor = i.isEven ? const Color(0xFFFF477E) : Colors.white;
      canvas.drawRRect(
        RRect.fromLTRBR(awLeft, top + 14, awLeft + awningWidth, top + 42, const Radius.circular(6)),
        Paint()..color = awColor,
      );
    }

    // Pastry Windows & Display
    final winPaint = Paint()..color = const Color(0xFFFFE4E1);
    canvas.drawRRect(RRect.fromLTRBR(left + 16, top + 56, size.width * 0.46, bottom - 24, const Radius.circular(12)), winPaint);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.54, top + 56, right - 16, bottom - 24, const Radius.circular(12)), winPaint);
  }

  void _drawSpaceStation(Canvas canvas, Size size) {
    final gantryPaint = Paint()..color = const Color(0xFF475569);
    final rocketBodyPaint = Paint()..color = const Color(0xFFF8FAFC);
    final rocketCyanPaint = Paint()..color = const Color(0xFF00F2FE);

    final centerX = size.width * 0.5;

    // Launch Gantry Towers
    canvas.drawRect(Rect.fromLTWH(centerX - 90, size.height * 0.32, 24, size.height * 0.44), gantryPaint);
    canvas.drawRect(Rect.fromLTWH(centerX + 66, size.height * 0.32, 24, size.height * 0.44), gantryPaint);

    // Solar Wings
    final solarPaint = Paint()..color = const Color(0xFF1E3A8A);
    canvas.drawRRect(RRect.fromLTRBR(centerX - 120, size.height * 0.46, centerX - 50, size.height * 0.56, const Radius.circular(8)), solarPaint);
    canvas.drawRRect(RRect.fromLTRBR(centerX + 50, size.height * 0.46, centerX + 120, size.height * 0.56, const Radius.circular(8)), solarPaint);

    // Main Rocket Body
    final rocketPath = Path()
      ..moveTo(centerX, size.height * 0.20) // Nose cone tip
      ..lineTo(centerX + 36, size.height * 0.32)
      ..lineTo(centerX + 36, size.height * 0.72)
      ..lineTo(centerX - 36, size.height * 0.72)
      ..lineTo(centerX - 36, size.height * 0.32)
      ..close();
    canvas.drawPath(rocketPath, rocketBodyPaint);
    canvas.drawPath(rocketPath, Paint()..color = rocketCyanPaint.color..style = PaintingStyle.stroke..strokeWidth = 3);

    // Cockpit Window (Circular glass)
    canvas.drawCircle(Offset(centerX, size.height * 0.40), 16, Paint()..color = const Color(0xFF0EA5E9));
    canvas.drawCircle(Offset(centerX, size.height * 0.40), 16, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

    // Booster Fire Exhausts
    canvas.drawRRect(RRect.fromLTRBR(centerX - 28, size.height * 0.72, centerX - 8, size.height * 0.76, const Radius.circular(4)), Paint()..color = const Color(0xFFFF9F1C));
    canvas.drawRRect(RRect.fromLTRBR(centerX + 8, size.height * 0.72, centerX + 28, size.height * 0.76, const Radius.circular(4)), Paint()..color = const Color(0xFFFF9F1C));
  }

  void _drawPirateShip(Canvas canvas, Size size) {
    final woodPaint = Paint()..color = const Color(0xFF8B4513);
    final darkWoodPaint = Paint()..color = const Color(0xFF5C2C16);
    final sailPaint = Paint()..color = const Color(0xFFFFFDD0);

    final centerX = size.width * 0.5;

    // Ocean Waves at Base
    final wavePaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawRRect(RRect.fromLTRBR(size.width * 0.05, size.height * 0.70, size.width * 0.95, size.height * 0.78, const Radius.circular(16)), wavePaint);

    // Wooden Ship Hull
    final hullPath = Path()
      ..moveTo(size.width * 0.14, size.height * 0.54)
      ..lineTo(size.width * 0.86, size.height * 0.54)
      ..lineTo(size.width * 0.76, size.height * 0.72)
      ..lineTo(size.width * 0.24, size.height * 0.72)
      ..close();
    canvas.drawPath(hullPath, woodPaint);
    canvas.drawPath(hullPath, Paint()..color = darkWoodPaint.color..style = PaintingStyle.stroke..strokeWidth = 4);

    // Tall Ship Mast
    canvas.drawRect(Rect.fromLTWH(centerX - 6, size.height * 0.24, 12, size.height * 0.36), darkWoodPaint);

    // Billowing Pirate Sail
    final sailPath = Path()
      ..moveTo(centerX - 55, size.height * 0.30)
      ..quadraticBezierTo(centerX, size.height * 0.34, centerX + 55, size.height * 0.30)
      ..lineTo(centerX + 65, size.height * 0.48)
      ..quadraticBezierTo(centerX, size.height * 0.52, centerX - 65, size.height * 0.48)
      ..close();
    canvas.drawPath(sailPath, sailPaint);
    canvas.drawPath(sailPath, Paint()..color = const Color(0xFFD4C5A9)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Crow's Nest at Top
    canvas.drawRRect(RRect.fromLTRBR(centerX - 18, size.height * 0.24, centerX + 18, size.height * 0.28, const Radius.circular(4)), darkWoodPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// REALISTIC FLAME & CONTINUOUS HIGH-PRESSURE WATER JET PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _FireAndWaterEffectsPainter extends CustomPainter {
  final List<FireSpot> spots;
  final List<_EmberParticle> embers;
  final List<_SmokeParticle> smokes;
  final List<_WaterSplash> splashes;
  final List<_SteamParticle> steamParticles;
  final List<_ConfettiParticle> confetti;
  final bool isSpraying;
  final Offset? touchPos;
  final Size screenSize;

  _FireAndWaterEffectsPainter({
    required this.spots,
    required this.embers,
    required this.smokes,
    required this.splashes,
    required this.steamParticles,
    required this.confetti,
    required this.isSpraying,
    required this.touchPos,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Billowing Smoke Clouds
    for (final smoke in smokes) {
      final smokePaint = Paint()
        ..color = const Color(0xFF334155).withValues(alpha: (smoke.life / smoke.maxLife) * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(smoke.pos, smoke.radius, smokePaint);
    }

    // 2. REALISTIC ROARING MULTI-TONGUE FLAMES at each FireSpot
    for (final spot in spots) {
      if (!spot.isExtinguished && spot.hp > 0) {
        final center = Offset(
          spot.relativePos.dx * size.width,
          spot.relativePos.dy * size.height,
        );
        final scale = (0.35 + (spot.hp / 100.0) * 0.65);
        _drawRealisticFire(canvas, center, spot.radius * scale, spot.flamePhase);
      }
    }

    // 3. Flying Glowing Embers (Sparks)
    for (final ember in embers) {
      final emberPaint = Paint()
        ..color = ember.color.withValues(alpha: ember.life)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(ember.pos, ember.radius, emberPaint);
    }

    // 4. REALISTIC CONTINUOUS HIGH-PRESSURE WATER JET STREAM
    if (isSpraying && touchPos != null) {
      final nozzleOrigin = Offset(size.width * 0.5, size.height * 0.88);
      _drawWaterJetStream(canvas, nozzleOrigin, touchPos!);
    }

    // 5. Water Splashes at Impact Point
    for (final s in splashes) {
      final paint = Paint()
        ..color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(s.pos, s.radius, paint);

      final shinePaint = Paint()..color = Colors.white.withValues(alpha: s.life * 0.75);
      canvas.drawCircle(s.pos - Offset(s.radius * 0.3, s.radius * 0.3), s.radius * 0.35, shinePaint);
    }

    // 6. Steam Sizzling Puffs
    for (final steam in steamParticles) {
      final steamPaint = Paint()
        ..color = Colors.white.withValues(alpha: (steam.life / steam.maxLife) * 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(steam.pos, steam.radius, steamPaint);
    }

    // 7. Confetti
    for (final c in confetti) {
      canvas.save();
      canvas.translate(c.pos.dx, c.pos.dy);
      canvas.rotate(c.rotation);
      final cPaint = Paint()..color = c.color;
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.6), cPaint);
      canvas.restore();
    }
  }

  void _drawWaterJetStream(Canvas canvas, Offset origin, Offset target) {
    // Parabolic Midpoint for realistic water arc gravity curve
    final midX = (origin.dx + target.dx) * 0.5;
    final midY = min(origin.dy, target.dy) - (origin.dx - target.dx).abs() * 0.08 - 15;
    final ctrlPoint = Offset(midX, midY);

    // Outer Foaming Blue Water Aura
    final outerWaterPath = Path();
    outerWaterPath.moveTo(origin.dx - 8, origin.dy);
    outerWaterPath.quadraticBezierTo(ctrlPoint.dx - 12, ctrlPoint.dy, target.dx - 14, target.dy);
    outerWaterPath.lineTo(target.dx + 14, target.dy);
    outerWaterPath.quadraticBezierTo(ctrlPoint.dx + 12, ctrlPoint.dy, origin.dx + 8, origin.dy);
    outerWaterPath.close();

    final outerPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(outerWaterPath, outerPaint);

    // Inner High-Pressure White-Cyan Core Beam
    final innerWaterPath = Path();
    innerWaterPath.moveTo(origin.dx - 4, origin.dy);
    innerWaterPath.quadraticBezierTo(ctrlPoint.dx - 5, ctrlPoint.dy, target.dx - 6, target.dy);
    innerWaterPath.lineTo(target.dx + 6, target.dy);
    innerWaterPath.quadraticBezierTo(ctrlPoint.dx + 5, ctrlPoint.dy, origin.dx + 4, origin.dy);
    innerWaterPath.close();

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.white,
          const Color(0xFFE0F2FE),
          const Color(0xFF38BDF8),
        ],
      ).createShader(Rect.fromPoints(origin, target));
    canvas.drawPath(innerWaterPath, innerPaint);

    // Water Splash Shockwave Dome at Target
    final domePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(target, 16, domePaint);

    final cyanDomePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(target, 24, cyanDomePaint);
  }

  void _drawRealisticFire(Canvas canvas, Offset center, double r, double phase) {
    // 1. Fiery Heat Aura / Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.38)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.75);
    canvas.drawCircle(center, r * 1.35, glowPaint);

    // 2. Base Red Fire Outer Boundary
    final outerRedPaint = Paint()..color = const Color(0xFFDC2626);
    _drawFlameShape(canvas, center, r * 1.25, phase, outerRedPaint, tallFactor: 1.35);

    // 3. Middle Dancing Orange Flame Body
    final orangePaint = Paint()..color = const Color(0xFFFF7A00);
    _drawFlameShape(canvas, center + const Offset(0, 3), r * 0.92, phase + 1.3, orangePaint, tallFactor: 1.15);

    // 4. Inner Golden-Yellow Core
    final yellowPaint = Paint()..color = const Color(0xFFFFD500);
    _drawFlameShape(canvas, center + const Offset(0, 6), r * 0.62, phase + 2.6, yellowPaint, tallFactor: 0.95);

    // 5. Incandescent White-Hot Heart
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    _drawFlameShape(canvas, center + const Offset(0, 8), r * 0.32, phase + 3.8, whitePaint, tallFactor: 0.70);
  }

  void _drawFlameShape(Canvas canvas, Offset center, double r, double phase, Paint paint, {required double tallFactor}) {
    final path = Path();
    
    final leftTipX = center.dx - r * 0.62 + sin(phase * 3.2) * (r * 0.18);
    final leftTipY = center.dy - r * (0.85 * tallFactor) + cos(phase * 2.8) * (r * 0.15);

    final centerTipX = center.dx + sin(phase * 4.1) * (r * 0.22);
    final centerTipY = center.dy - r * (1.30 * tallFactor) + cos(phase * 3.5) * (r * 0.20);

    final rightTipX = center.dx + r * 0.62 + sin(phase * 3.6) * (r * 0.18);
    final rightTipY = center.dy - r * (0.90 * tallFactor) + cos(phase * 3.1) * (r * 0.15);

    final bottomY = center.dy + r * 0.55;
    final leftBaseX = center.dx - r * 0.75;
    final rightBaseX = center.dx + r * 0.75;

    path.moveTo(center.dx, bottomY);
    path.cubicTo(leftBaseX, bottomY, leftBaseX - r * 0.1, center.dy, leftTipX, leftTipY);
    path.cubicTo(leftTipX + r * 0.2, leftTipY + r * 0.3, center.dx - r * 0.3, center.dy - r * 0.5, centerTipX, centerTipY);
    path.cubicTo(centerTipX + r * 0.3, centerTipY + r * 0.5, rightTipX - r * 0.2, rightTipY + r * 0.3, rightTipX, rightTipY);
    path.cubicTo(rightBaseX + r * 0.1, center.dy, rightBaseX, bottomY, center.dx, bottomY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FireAndWaterEffectsPainter oldDelegate) => true;
}

// 💧 소방 호스 CustomPainter — 구불구불한 고무 호스 + 황동 노즐
class _FireHosePainter extends CustomPainter {
  final double nozzleAngle;
  final bool isSpraying;
  final double screenWidth;

  _FireHosePainter({
    required this.nozzleAngle,
    required this.isSpraying,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 호스 실릴 시작점: 소방관 위치 (화면 하단 중앙)
    final startX = size.width * 0.38;
    final startY = size.height * 0.42;

    // 노즐 끝 위치 (소방관 손 위)
    final nozzleLength = 55.0;
    final nozzleEndX = startX + cos(nozzleAngle) * nozzleLength;
    final nozzleEndY = startY + sin(nozzleAngle) * nozzleLength;

    // 호스 말림 점 (화면 오른쪽 하단에 말려 있는 호스 들)
    final hoseEndX = size.width * 0.82;
    final hoseEndY = size.height * 0.78;

    // 1번 제어점 — 혼뢰는 켬임
    final cp1x = startX + (hoseEndX - startX) * 0.3;
    final cp1y = startY + 45.0;
    // 2번 제어점
    final cp2x = startX + (hoseEndX - startX) * 0.7;
    final cp2y = startY - 30.0;

    // 호스 본체 (3단 레이어 두께감)
    // 세에어: 흐린 검은 거피 레이어
    final hoseShadowPaint = Paint()
      ..color = const Color(0xFF111827).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final hosePath = Path();
    hosePath.moveTo(nozzleEndX, nozzleEndY);
    hosePath.cubicTo(cp1x, cp1y, cp2x, cp2y, hoseEndX, hoseEndY);

    canvas.drawPath(hosePath, hoseShadowPaint);

    // 호스 메인 바디 — 진한 빨간색 소방 호스
    final hoseBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFDC2626), // 빨간 소방 호스
          Color(0xFFB91C1C),
          Color(0xFF991B1B),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(hosePath, hoseBodyPaint);

    // 호스 반사 하이라이트 (위식 반짝)
    final hoseHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, hoseHighlightPaint);

    // 호스 마디 마디 라인 (주름 텍스쳐)
    final ringlePaint = Paint()
      ..color = const Color(0xFF7F1D1D).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 호스를 따라 5개의 주름 마크 그리기
    for (int i = 1; i <= 5; i++) {
      final t = i / 6.0;
      // 켬임 상의 점 근사
      final bx = _cubicBezierPoint(nozzleEndX, cp1x, cp2x, hoseEndX, t);
      final by = _cubicBezierPoint(nozzleEndY, cp1y, cp2y, hoseEndY, t);
      canvas.drawCircle(Offset(bx, by), 7.5, ringlePaint);
    }

    // 황동 노즐 (Nozzle)
    final nozzlePaint = Paint()..style = PaintingStyle.fill;

    // 노즐 미디 위치
    final nozzleMidX = (startX + nozzleEndX) / 2;
    final nozzleMidY = (startY + nozzleEndY) / 2;

    canvas.save();
    canvas.translate(nozzleMidX, nozzleMidY);
    canvas.rotate(nozzleAngle + pi / 2);

    // 노즐 본체 (원통형 황동)
    final nozzleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 16, height: 50),
      const Radius.circular(7),
    );
    final nozzleGrad = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFFB8860B),
        Color(0xFFFFD700),
        Color(0xFFDAA520),
        Color(0xFF8B6914),
      ],
    ).createShader(Rect.fromCenter(center: Offset.zero, width: 16, height: 50));
    nozzlePaint.shader = nozzleGrad;
    canvas.drawRRect(nozzleRect, nozzlePaint);

    // 노즐 팔 (water outlet)
    nozzlePaint.shader = null;
    nozzlePaint.color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -22), width: 10, height: 10),
        const Radius.circular(3),
      ),
      nozzlePaint,
    );

    // 노즐 반짝이 (specular)
    nozzlePaint.color = Colors.white.withOpacity(0.4);
    canvas.drawRect(
      const Rect.fromLTWH(-4, -20, 3, 36),
      nozzlePaint,
    );

    canvas.restore();
  }

  // 켬설 베지어 상의 점 계산
  double _cubicBezierPoint(double p0, double p1, double p2, double p3, double t) {
    final mt = 1 - t;
    return mt * mt * mt * p0 + 3 * mt * mt * t * p1 + 3 * mt * t * t * p2 + t * t * t * p3;
  }

  @override
  bool shouldRepaint(covariant _FireHosePainter oldDelegate) =>
      oldDelegate.nozzleAngle != nozzleAngle ||
      oldDelegate.isSpraying != isSpraying;
}
