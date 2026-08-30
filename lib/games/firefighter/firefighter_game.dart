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
  final List<Offset> _roadItems = []; // 소방차 주행 엔진음 타이머

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
    AudioManager.instance.stopFireSiren();
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

    // Update Flame Phases, Embers & Smoke

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

    // 노즐 조준 각도 계산 (기본 위쪽 -90도, 터치 시 터치 지점을 향해 회전)
    double nozzleAngle = -pi / 2;
    if (_touchPos != null) {
      final nozzleBaseGlobalX = screenWidth * 0.5;
      final nozzleBaseGlobalY = screenHeight - 65;
      final dx = _touchPos!.dx - nozzleBaseGlobalX;
      final dy = _touchPos!.dy - nozzleBaseGlobalY;
      // 터치 각도 제한 (좌우 65도 범위 내로 자연스럽게 조준)
      final rawAngle = atan2(dy, dx);
      nozzleAngle = rawAngle.clamp(-pi * 0.85, -pi * 0.15);
    }

    return SizedBox(
      width: screenWidth,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 💧 실감나는 중장비 소방 호스 & 황동 관창 노즐 & 소방관
          Positioned.fill(
            child: CustomPaint(
              painter: _FireHosePainter(
                nozzleAngle: nozzleAngle,
                isSpraying: _isSpraying,
                screenWidth: screenWidth,
              ),
            ),
          ),

          // 💬 하단 진압 안내 및 상태 뱃지
          Positioned(
            bottom: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _isSpraying
                    ? const Color(0xFF0284C7).withValues(alpha: 0.92)
                    : const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSpraying ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isSpraying
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isSpraying ? '💦' : '🎯', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    _isSpraying ? '고압 물대포 발사 중!' : '불이 난 곳을 터치하여 진압하세요!',
                    style: GoogleFonts.jua(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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

  // 1. 도심 아파트 (Modern City Apartment with Balconies & Garden)
  void _drawApartment(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1-1. 배경 거리 환경 (Sidewalk & Streetlamps)
    final sidewalkPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.04, h * 0.74, w * 0.96, h * 0.78), const Radius.circular(8)), sidewalkPaint);

    final left = w * 0.12;
    final right = w * 0.88;
    final top = h * 0.23;
    final bottom = h * 0.74;

    // 1-2. 아파트 본체 그림자
    final shadowRect = RRect.fromRectAndRadius(Rect.fromLTRB(left + 6, top + 8, right + 6, bottom + 8), const Radius.circular(18));
    canvas.drawRRect(shadowRect, Paint()..color = Colors.black.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // 1-3. 아파트 메인 벽체 (따뜻한 테라코타 & 크림 투톤)
    final bodyRRect = RRect.fromRectAndRadius(Rect.fromLTRB(left, top, right, bottom), const Radius.circular(16));
    final bodyGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    ).createShader(Rect.fromLTRB(left, top, right, bottom));
    canvas.drawRRect(bodyRRect, Paint()..shader = bodyGrad);

    // 사이드 음영 필라 (Side Accent Pillars)
    final pillarPaint = Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(left, top, left + 14, bottom), const Radius.circular(6)), pillarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(right - 14, top, right, bottom), const Radius.circular(6)), pillarPaint);

    // 1-4. 옥상 테라스 지붕 & 안테나
    final roofPath = Path()
      ..moveTo(left - 16, top)
      ..lineTo(right + 16, top)
      ..lineTo(right + 4, top - 24)
      ..lineTo(left - 4, top - 24)
      ..close();
    final roofGrad = const LinearGradient(
      colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
    ).createShader(Rect.fromLTWH(left - 16, top - 24, right - left + 32, 24));
    canvas.drawPath(roofPath, Paint()..shader = roofGrad);

    // 옥상 안테나 & 태양광 패널
    final metalPaint = Paint()..color = const Color(0xFF64748B)..strokeWidth = 2.5;
    canvas.drawLine(Offset(left + 35, top - 24), Offset(left + 35, top - 46), metalPaint);
    canvas.drawCircle(Offset(left + 35, top - 46), 4, Paint()..color = const Color(0xFFEF4444));
    canvas.drawRect(Rect.fromLTWH(right - 55, top - 38, 36, 14), Paint()..color = const Color(0xFF1E3A8A));

    // 1-5. 3단 창문 & 베란다 발코니 그리드 (Windows & Flower Balconies)
    final winWidth = (right - left) * 0.32;
    final winHeight = (bottom - top) * 0.20;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final wx = left + 24 + col * (winWidth + 26);
        final wy = top + 18 + row * (winHeight + 22);

        // 창틀 (Window Frame)
        final frameRRect = RRect.fromRectAndRadius(Rect.fromLTRB(wx, wy, wx + winWidth, wy + winHeight), const Radius.circular(10));
        canvas.drawRRect(frameRRect, Paint()..color = const Color(0xFF0284C7));

        // 유리창 (Glass with Specular Shine)
        final glassRRect = RRect.fromRectAndRadius(Rect.fromLTRB(wx + 3.5, wy + 3.5, wx + winWidth - 3.5, wy + winHeight - 3.5), const Radius.circular(8));
        final glassGrad = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
        ).createShader(Rect.fromLTRB(wx, wy, wx + winWidth, wy + winHeight));
        canvas.drawRRect(glassRRect, Paint()..shader = glassGrad);

        // 창문 십자 프레임
        final barPaint = Paint()..color = Colors.white.withValues(alpha: 0.9)..strokeWidth = 2;
        canvas.drawLine(Offset(wx + winWidth * 0.5, wy + 4), Offset(wx + winWidth * 0.5, wy + winHeight - 4), barPaint);
        canvas.drawLine(Offset(wx + 4, wy + winHeight * 0.5), Offset(wx + winWidth - 4, wy + winHeight * 0.5), barPaint);

        // 발코니 화분 난간 (Balcony Railing & Flowers)
        final balconyY = wy + winHeight - 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(wx - 2, balconyY, wx + winWidth + 2, balconyY + 10), const Radius.circular(4)),
          Paint()..color = const Color(0xFF334155),
        );
        // 귀여운 화분 꽃들 (🌸 🌼 🌺)
        canvas.drawCircle(Offset(wx + winWidth * 0.25, balconyY - 2), 4, Paint()..color = const Color(0xFFEC4899));
        canvas.drawCircle(Offset(wx + winWidth * 0.50, balconyY - 3), 4.5, Paint()..color = const Color(0xFFFBBF24));
        canvas.drawCircle(Offset(wx + winWidth * 0.75, balconyY - 2), 4, Paint()..color = const Color(0xFFF43F5E));
      }
    }

    // 1-6. 1층 메인 도어 & 캔디 스트라이프 어닝 (Entrance Door & Awning)
    final doorX = w * 0.5;
    final doorRect = RRect.fromRectAndRadius(Rect.fromLTRB(doorX - 22, bottom - 36, doorX + 22, bottom), const Radius.circular(8));
    canvas.drawRRect(doorRect, Paint()..color = const Color(0xFF9A3412));
    canvas.drawCircle(Offset(doorX + 12, bottom - 18), 3, Paint()..color = const Color(0xFFFBBF24)); // 금색 손잡이
  }

  // 2. 동화 속 숲속 오두막 (Cozy Forest Cabin with Giant Trees & Wildflowers)
  void _drawForest(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 2-1. 숲속 맑은 언덕 잔디 (Rolling Green Hills)
    final hillPath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.35, h * 0.65, w * 0.65, h * 0.72)
      ..quadraticBezierTo(w * 0.85, h * 0.76, w, h * 0.70)
      ..lineTo(w, h * 0.80)
      ..lineTo(0, h * 0.80)
      ..close();
    canvas.drawPath(hillPath, Paint()..color = const Color(0xFF15803D));

    // 2-2. 좌측 울창한 단풍 참나무 (Giant Oak Tree)
    final trunkPaint = Paint()..color = const Color(0xFF78350F);
    final trunkPath1 = Path()
      ..moveTo(w * 0.18, h * 0.74)
      ..lineTo(w * 0.24, h * 0.42)
      ..lineTo(w * 0.34, h * 0.42)
      ..lineTo(w * 0.38, h * 0.74)
      ..close();
    canvas.drawPath(trunkPath1, trunkPaint);

    // 참나무 3중 풍성한 볼륨 잎사귀
    canvas.drawCircle(Offset(w * 0.28, h * 0.38), w * 0.20, Paint()..color = const Color(0xFF166534));
    canvas.drawCircle(Offset(w * 0.22, h * 0.34), w * 0.16, Paint()..color = const Color(0xFF15803D));
    canvas.drawCircle(Offset(w * 0.32, h * 0.30), w * 0.15, Paint()..color = const Color(0xFF22C55E));
    canvas.drawCircle(Offset(w * 0.28, h * 0.28), w * 0.12, Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.6));

    // 2-3. 우측 단풍나무 (Golden Orange Autumn Tree)
    final trunkPath2 = Path()
      ..moveTo(w * 0.64, h * 0.74)
      ..lineTo(w * 0.68, h * 0.44)
      ..lineTo(w * 0.76, h * 0.44)
      ..lineTo(w * 0.80, h * 0.74)
      ..close();
    canvas.drawPath(trunkPath2, trunkPaint);

    canvas.drawCircle(Offset(w * 0.72, h * 0.40), w * 0.18, Paint()..color = const Color(0xFFC2410C));
    canvas.drawCircle(Offset(w * 0.76, h * 0.34), w * 0.15, Paint()..color = const Color(0xFFEA580C));
    canvas.drawCircle(Offset(w * 0.68, h * 0.32), w * 0.14, Paint()..color = const Color(0xFFF97316));
    canvas.drawCircle(Offset(w * 0.72, h * 0.28), w * 0.10, Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.7));

    // 2-4. 중앙 아늑한 통나무 오두막 (Cozy Log Cabin)
    final cabinLeft = w * 0.34;
    final cabinRight = w * 0.66;
    final cabinTop = h * 0.46;
    final cabinBottom = h * 0.74;

    // 통나무 벽체
    final cabinRRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinLeft, cabinTop, cabinRight, cabinBottom), const Radius.circular(12));
    canvas.drawRRect(cabinRRect, Paint()..color = const Color(0xFFB45309));

    // 통나무 결 라인
    for (double y = cabinTop + 10; y < cabinBottom; y += 12) {
      canvas.drawLine(Offset(cabinLeft, y), Offset(cabinRight, y), Paint()..color = const Color(0xFF78350F)..strokeWidth = 2);
    }

    // 벽돌 굴뚝 & 모락모락 연기 (Chimney & Puffs)
    canvas.drawRect(Rect.fromLTWH(cabinRight - 22, cabinTop - 28, 14, 28), Paint()..color = const Color(0xFF991B1B));
    canvas.drawCircle(Offset(cabinRight - 15, cabinTop - 34), 6, Paint()..color = Colors.white70);
    canvas.drawCircle(Offset(cabinRight - 10, cabinTop - 44), 9, Paint()..color = Colors.white54);

    // 오두막 삼각형 삼나무 지붕 (Cedar Shingle Roof)
    final roofCabin = Path()
      ..moveTo(cabinLeft - 14, cabinTop)
      ..lineTo(w * 0.50, cabinTop - 36)
      ..lineTo(cabinRight + 14, cabinTop)
      ..close();
    final cabinRoofGrad = const LinearGradient(
      colors: [Color(0xFF991B1B), Color(0xFFB91C1C), Color(0xFF7F1D1D)],
    ).createShader(Rect.fromLTRB(cabinLeft - 14, cabinTop - 36, cabinRight + 14, cabinTop));
    canvas.drawPath(roofCabin, Paint()..shader = cabinRoofGrad);

    // 따스한 창문 & 현관문
    final winRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinLeft + 12, cabinTop + 14, cabinLeft + 36, cabinTop + 36), const Radius.circular(6));
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFFFEF08A));
    canvas.drawRRect(winRect, Paint()..color = const Color(0xFF78350F)..style = PaintingStyle.stroke..strokeWidth = 2);

    final doorRRect = RRect.fromRectAndRadius(Rect.fromLTRB(cabinRight - 36, cabinBottom - 36, cabinRight - 12, cabinBottom), const Radius.circular(6));
    canvas.drawRRect(doorRRect, Paint()..color = const Color(0xFF78350F));
    canvas.drawCircle(Offset(cabinRight - 30, cabinBottom - 18), 2.5, Paint()..color = const Color(0xFFFBBF24));

    // 2-5. 숲속 꽃 & 버섯 디테일 (🍄 🌸)
    canvas.drawCircle(Offset(w * 0.20, h * 0.72), 6, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(w * 0.20, h * 0.70), 2, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.82, h * 0.73), 5, Paint()..color = const Color(0xFFF43F5E));
  }

  // 3. 판타지 마법 성 (Grand Magic Castle with Spire Turrets & Royal Banners)
  void _drawCastle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 3-1. 성채 돌벽 베이스
    final stoneGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE), Color(0xFFC4B5FD)],
    );

    final turretGrad = const LinearGradient(
      colors: [Color(0xFFC084FC), Color(0xFFA855F7), Color(0xFF9333EA)],
    );

    final roofGrad = const LinearGradient(
      colors: [Color(0xFFFB7185), Color(0xFFF43F5E), Color(0xFFE11D48)],
    );

    // 3-2. 중앙 거대 마법 본탑 (Grand Keep)
    final keepLeft = w * 0.32;
    final keepRight = w * 0.68;
    final keepTop = h * 0.24;
    final keepBottom = h * 0.75;

    final keepRect = RRect.fromRectAndRadius(Rect.fromLTRB(keepLeft, keepTop, keepRight, keepBottom), const Radius.circular(14));
    canvas.drawRRect(keepRect, Paint()..shader = stoneGrad.createShader(Rect.fromLTRB(keepLeft, keepTop, keepRight, keepBottom)));

    // 중앙 크레넬레이션 성벽 배틀먼트 (Crenellations)
    for (double x = keepLeft; x < keepRight - 10; x += 16) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x, keepTop - 8, x + 10, keepTop), const Radius.circular(3)), Paint()..color = const Color(0xFFDDD6FE));
    }

    // 중앙 원뿔 고딕 첨탑 (Gothic Spire Roof)
    final centerRoof = Path()
      ..moveTo(keepLeft - 8, keepTop - 8)
      ..lineTo(w * 0.50, h * 0.10) // 뾰족한 첨탑
      ..lineTo(keepRight + 8, keepTop - 8)
      ..close();
    canvas.drawPath(centerRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(keepLeft - 8, h * 0.10, keepRight + 8, keepTop)));

    // 첨탑 꼭대기 황금 마법 구슬 & 펄럭이는 깃발 (Golden Orb & Royal Banner)
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), 6, Paint()..color = const Color(0xFFFFD700));
    final bannerPath = Path()
      ..moveTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.50 + 22, h * 0.10 + 6)
      ..lineTo(w * 0.50, h * 0.10 + 14)
      ..close();
    canvas.drawPath(bannerPath, Paint()..color = const Color(0xFFFBBF24));

    // 3-3. 좌우 사이드 마법 타워 (Left & Right Turrets)
    final leftTurretRect = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.10, h * 0.36, w * 0.30, keepBottom), const Radius.circular(12));
    canvas.drawRRect(leftTurretRect, Paint()..shader = turretGrad.createShader(Rect.fromLTRB(w * 0.10, h * 0.36, w * 0.30, keepBottom)));

    final leftRoof = Path()
      ..moveTo(w * 0.08, h * 0.36)
      ..lineTo(w * 0.20, h * 0.22)
      ..lineTo(w * 0.32, h * 0.36)
      ..close();
    canvas.drawPath(leftRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(w * 0.08, h * 0.22, w * 0.32, h * 0.36)));

    final rightTurretRect = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.70, h * 0.36, w * 0.90, keepBottom), const Radius.circular(12));
    canvas.drawRRect(rightTurretRect, Paint()..shader = turretGrad.createShader(Rect.fromLTRB(w * 0.70, h * 0.36, w * 0.90, keepBottom)));

    final rightRoof = Path()
      ..moveTo(w * 0.68, h * 0.36)
      ..lineTo(w * 0.80, h * 0.22)
      ..lineTo(w * 0.92, h * 0.36)
      ..close();
    canvas.drawPath(rightRoof, Paint()..shader = roofGrad.createShader(Rect.fromLTRB(w * 0.68, h * 0.22, w * 0.92, h * 0.36)));

    // 3-4. 아치형 골드 스테인드글라스 창문들 (Arched Windows)
    _drawArchedWindow(canvas, Offset(w * 0.50, h * 0.32), 28, 44);
    _drawArchedWindow(canvas, Offset(w * 0.20, h * 0.44), 20, 32);
    _drawArchedWindow(canvas, Offset(w * 0.80, h * 0.44), 20, 32);

    // 3-5. 성문 거대 도개교 (Royal Castle Gate & Portcullis)
    final gatePath = Path()
      ..moveTo(w * 0.42, keepBottom)
      ..lineTo(w * 0.42, keepBottom - 38)
      ..quadraticBezierTo(w * 0.50, keepBottom - 50, w * 0.58, keepBottom - 38)
      ..lineTo(w * 0.58, keepBottom)
      ..close();
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFF475569));
    canvas.drawPath(gatePath, Paint()..color = const Color(0xFFFBBF24)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  void _drawArchedWindow(Canvas canvas, Offset center, double width, double height) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final path = Path()
      ..moveTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top + width * 0.5)
      ..arcToPoint(Offset(rect.right, rect.top + width * 0.5), radius: Radius.circular(width * 0.5))
      ..lineTo(rect.right, rect.bottom)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF38BDF8));
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  // 4. 달콤한 디저트 베이커리 (Sweet Strawberry Bakery with Cupcake Rooftop & Awning)
  void _drawBakery(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final left = w * 0.12;
    final right = w * 0.88;
    final top = h * 0.26;
    final bottom = h * 0.75;

    // 4-1. 생크림 핑크 벽체
    final wallRRect = RRect.fromRectAndRadius(Rect.fromLTRB(left, top, right, bottom), const Radius.circular(20));
    final wallGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF1F2), Color(0xFFFFE4E6), Color(0xFFFECDD3)],
    ).createShader(Rect.fromLTRB(left, top, right, bottom));
    canvas.drawRRect(wallRRect, Paint()..shader = wallGrad);
    canvas.drawRRect(wallRRect, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 3);

    // 4-2. 옥상 초대형 딸기 컵케이크 조형물 (Giant Strawberry Cupcake Signboard)
    final cupcakeX = w * 0.5;
    final cupcakeY = top - 20;

    // 컵케이크 컵 베이스
    final cupPath = Path()
      ..moveTo(cupcakeX - 32, cupcakeY + 16)
      ..lineTo(cupcakeX - 24, cupcakeY + 36)
      ..lineTo(cupcakeX + 24, cupcakeY + 36)
      ..lineTo(cupcakeX + 32, cupcakeY + 16)
      ..close();
    canvas.drawPath(cupPath, Paint()..color = const Color(0xFFF59E0B));

    // 폭신한 핑크 크림 돔
    canvas.drawCircle(Offset(cupcakeX - 18, cupcakeY + 8), 20, Paint()..color = const Color(0xFFFF69B4));
    canvas.drawCircle(Offset(cupcakeX + 18, cupcakeY + 8), 20, Paint()..color = const Color(0xFFFF69B4));
    canvas.drawCircle(Offset(cupcakeX, cupcakeY - 4), 26, Paint()..color = const Color(0xFFFF1493));

    // 꼭대기 빨간 체리 (Glossy Red Cherry)
    canvas.drawCircle(Offset(cupcakeX, cupcakeY - 26), 11, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(cupcakeX - 3, cupcakeY - 29), 3, Paint()..color = Colors.white70);

    // 4-3. 캔디 스트라이프 어닝 (Pink & White Ruffled Awning)
    final awningWidth = (right - left) / 7;
    for (int i = 0; i < 7; i++) {
      final awLeft = left + (i * awningWidth);
      final awColor = i.isEven ? const Color(0xFFF43F5E) : Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(awLeft, top + 14, awLeft + awningWidth, top + 42), const Radius.circular(8)),
        Paint()..color = awColor,
      );
    }

    // 4-4. 디저트 진열 파노라마 쇼케이스 창문
    final winRRect1 = RRect.fromRectAndRadius(Rect.fromLTRB(left + 16, top + 52, w * 0.46, bottom - 18), const Radius.circular(12));
    final winRRect2 = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.54, top + 52, right - 16, bottom - 18), const Radius.circular(12));
    final showcasePaint = Paint()..color = const Color(0xFFBAE6FD).withValues(alpha: 0.85);

    canvas.drawRRect(winRRect1, showcasePaint);
    canvas.drawRRect(winRRect2, showcasePaint);
    canvas.drawRRect(winRRect1, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRRect(winRRect2, Paint()..color = const Color(0xFFFB7185)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  // 5. 미래형 우주 런치패드 기지 (Cybernetic Space Launch Station)
  void _drawSpaceStation(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // 5-1. 발사대 트러스 타워 구조물 (Launch Gantry Towers)
    final gantryPaint = Paint()..color = const Color(0xFF334155)..strokeWidth = 3..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(centerX - 100, h * 0.28, 28, h * 0.48), gantryPaint);
    canvas.drawRect(Rect.fromLTWH(centerX + 72, h * 0.28, 28, h * 0.48), gantryPaint);

    // 트러스 X 크로스 브레이스
    for (double y = h * 0.28; y < h * 0.74; y += 24) {
      canvas.drawLine(Offset(centerX - 100, y), Offset(centerX - 72, y + 24), gantryPaint);
      canvas.drawLine(Offset(centerX + 72, y), Offset(centerX + 100, y + 24), gantryPaint);
    }

    // 5-2. 푸른 태양광 솔라 윙 (Solar Panel Wings)
    final solarPaint = Paint()..color = const Color(0xFF1E3A8A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX - 135, h * 0.44, centerX - 50, h * 0.56), const Radius.circular(8)), solarPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX + 50, h * 0.44, centerX + 135, h * 0.56), const Radius.circular(8)), solarPaint);

    // 5-3. 메인 우주선 동체 (Aerospace Shuttle Body)
    final rocketPath = Path()
      ..moveTo(centerX, h * 0.16) // Sharp Nose Cone
      ..lineTo(centerX + 40, h * 0.30)
      ..lineTo(centerX + 40, h * 0.72)
      ..lineTo(centerX - 40, h * 0.72)
      ..lineTo(centerX - 40, h * 0.30)
      ..close();
    final rocketGrad = const LinearGradient(
      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ).createShader(Rect.fromLTWH(centerX - 40, h * 0.16, 80, h * 0.56));
    canvas.drawPath(rocketPath, Paint()..shader = rocketGrad);
    canvas.drawPath(rocketPath, Paint()..color = const Color(0xFF00F2FE)..style = PaintingStyle.stroke..strokeWidth = 3);

    // 미래형 원형 돔 콕핏 윈도우 (Neon Cockpit Window)
    canvas.drawCircle(Offset(centerX, h * 0.36), 18, Paint()..color = const Color(0xFF0284C7));
    canvas.drawCircle(Offset(centerX, h * 0.36), 18, Paint()..color = const Color(0xFF38BDF8)..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  // 6. 모험의 해적 범선 (Legendary Pirate Galleon Ship)
  void _drawPirateShip(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;

    // 6-1. 넘실거리는 바다 파도 (Ocean Waves with Foam)
    final wavePath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.50, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.66, w, h * 0.70)
      ..lineTo(w, h * 0.80)
      ..lineTo(0, h * 0.80)
      ..close();
    canvas.drawPath(wavePath, Paint()..color = const Color(0xFF0284C7));

    // 6-2. 묵직한 목조 선체 (Heavy Wooden Ship Hull)
    final hullPath = Path()
      ..moveTo(w * 0.12, h * 0.50) // 높은 선수 (Bow)
      ..lineTo(w * 0.88, h * 0.48) // 높은 선미 (Stern)
      ..lineTo(w * 0.78, h * 0.72)
      ..lineTo(w * 0.22, h * 0.72)
      ..close();
    final woodGrad = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF9A3412), Color(0xFF78350F), Color(0xFF451A03)],
    ).createShader(Rect.fromLTRB(w * 0.12, h * 0.48, w * 0.88, h * 0.72));
    canvas.drawPath(hullPath, Paint()..shader = woodGrad);

    // 황금 포문 라인 (Gold Cannon Ports)
    for (double x = w * 0.28; x <= w * 0.72; x += 32) {
      canvas.drawCircle(Offset(x, h * 0.58), 6, Paint()..color = const Color(0xFF1E293B));
      canvas.drawCircle(Offset(x, h * 0.58), 6, Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // 6-3. 웅장한 중앙 돛대 & 펄럭이는 메인 돛 (Grand Ship Mast & Billowing Sail)
    canvas.drawRect(Rect.fromLTWH(centerX - 7, h * 0.18, 14, h * 0.38), Paint()..color = const Color(0xFF451A03));

    // 메인 돛 (Billowing Canvas Sail)
    final sailPath = Path()
      ..moveTo(centerX - 65, h * 0.24)
      ..quadraticBezierTo(centerX, h * 0.28, centerX + 65, h * 0.24)
      ..lineTo(centerX + 75, h * 0.44)
      ..quadraticBezierTo(centerX, h * 0.49, centerX - 75, h * 0.44)
      ..close();
    final sailGrad = const LinearGradient(
      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFFDE68A)],
    ).createShader(Rect.fromLTRB(centerX - 75, h * 0.24, centerX + 75, h * 0.49));
    canvas.drawPath(sailPath, Paint()..shader = sailGrad);

    // 돛 위 해적 엠블럼 (Skull Decal)
    canvas.drawCircle(Offset(centerX, h * 0.34), 9, Paint()..color = const Color(0xFF1E293B));
    canvas.drawCircle(Offset(centerX, h * 0.34), 6, Paint()..color = Colors.white);

    // 꼭대기 망루 (Crow's Nest & Pirate Flag)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(centerX - 18, h * 0.18, centerX + 18, h * 0.23), const Radius.circular(4)), Paint()..color = const Color(0xFF78350F));
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
      final nozzleBaseX = size.width * 0.5;
      final nozzleBaseY = size.height - 65;
      final dx = touchPos!.dx - nozzleBaseX;
      final dy = touchPos!.dy - nozzleBaseY;
      final angle = atan2(dy, dx).clamp(-pi * 0.85, -pi * 0.15);
      final nozzleTip = Offset(nozzleBaseX + cos(angle) * 54, nozzleBaseY + sin(angle) * 54);
      _drawWaterJetStream(canvas, nozzleTip, touchPos!);
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

// 💧 실감나는 중장비 소방 호스 & 황동/크롬 관창 노즐 & 소방관 캐릭터
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
    final centerX = size.width * 0.5;
    final baseY = size.height - 40.0;

    // 분사 중일 때의 사실적인 수압 반동 진동 (High-Pressure Recoil Shake)
    final recoilJitterX = isSpraying ? (sin(DateTime.now().millisecondsSinceEpoch * 0.08) * 2.0) : 0.0;
    final recoilJitterY = isSpraying ? (cos(DateTime.now().millisecondsSinceEpoch * 0.09) * 1.5) : 0.0;

    final nozzlePivotX = centerX + recoilJitterX;
    final nozzlePivotY = baseY - 25.0 + recoilJitterY;

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 묵직한 고압 소방 호스 (Heavy Fabric/Rubber Fire Hose from Bottom)
    // ─────────────────────────────────────────────────────────────────────────
    // 호스 시작점: 노즐 뒷단 커플러
    final hoseStartOffset = Offset(
      nozzlePivotX - cos(nozzleAngle) * 22,
      nozzlePivotY - sin(nozzleAngle) * 22,
    );

    // 호스 끝점: 화면 아래쪽 바닥 (소방차 펌프 연결부)
    final hoseEndOffset = Offset(centerX + 35, size.height + 25);

    final cp1 = Offset(hoseStartOffset.dx - cos(nozzleAngle) * 45, hoseStartOffset.dy - sin(nozzleAngle) * 45 + 30);
    final cp2 = Offset(centerX + 15, size.height - 5);

    final hosePath = Path()
      ..moveTo(hoseStartOffset.dx, hoseStartOffset.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, hoseEndOffset.dx, hoseEndOffset.dy);

    // 1-1. 호스 바닥 깊은 그림자 (Ground Drop Shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(hosePath, shadowPaint);

    // 1-2. 호스 외피 바디 (진한 소방 레드 캔버스 패브릭 질감)
    final hoseBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFEF4444), // Fire Red
          Color(0xFFB91C1C),
          Color(0xFF7F1D1D),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(hosePath, hoseBodyPaint);

    // 1-3. 호스 안전 반사 스트라이프 라인 (High-Vis Safety Yellow Stripe)
    final stripePaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, stripePaint);

    // 1-4. 호스 상단 빛 반사 하이라이트 (Glossy Specular)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hosePath, highlightPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 든든한 소방관 캐릭터 상체 (Firefighter Body & Helmet)
    // ─────────────────────────────────────────────────────────────────────────
    // 소방관 방화복 상체 (Yellow/Black Turnout Gear)
    final coatRect = Rect.fromCenter(center: Offset(centerX, baseY + 15), width: 84, height: 50);
    canvas.drawRRect(
      RRect.fromRectAndRadius(coatRect, const Radius.circular(16)),
      Paint()..color = const Color(0xFF1E293B),
    );
    // 방화복 반사 띠 (Neon Reflective Band)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY + 8), width: 80, height: 10), const Radius.circular(4)),
      Paint()..color = const Color(0xFFFACC15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY + 8), width: 78, height: 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE2E8F0),
    );

    // 소방관 헬멧 (Fire Helmet)
    canvas.drawCircle(Offset(centerX, baseY - 12), 22, Paint()..color = const Color(0xFFDC2626));
    // 헬멧 챙 (Brim)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY - 2), width: 56, height: 8), const Radius.circular(4)),
      Paint()..color = const Color(0xFF991B1B),
    );
    // 헬멧 골드 뱃지 (Shield Emblem)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, baseY - 16), width: 14, height: 16), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(Offset(centerX, baseY - 16), 3.5, Paint()..color = const Color(0xFF78350F));

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 정밀 회전 조준 황동/크롬 고압 관창 노즐 (Rotational Brass Pistol Nozzle)
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.translate(nozzlePivotX, nozzlePivotY);
    canvas.rotate(nozzleAngle + pi / 2); // 노즐 진행 방향 정렬

    // 3-1. 황동 호스 결합 커플러 (Brass Coupler Collar)
    final couplerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 22), width: 28, height: 16),
      const Radius.circular(4),
    );
    canvas.drawRRect(couplerRect, Paint()..color = const Color(0xFFD97706));
    canvas.drawRRect(couplerRect, Paint()..color = Colors.black.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 3-2. 노즐 본체 메인 배럴 (Chrome & Solid Brass Heavy Barrel)
    final barrelRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, 0), width: 22, height: 38),
      const Radius.circular(5),
    );
    final barrelGradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF92400E),
        Color(0xFFFBBF24),
        Color(0xFFFDE68A),
        Color(0xFFB45309),
      ],
    ).createShader(Rect.fromCenter(center: Offset.zero, width: 22, height: 38));
    canvas.drawRRect(barrelRect, Paint()..shader = barrelGradient);

    // 3-3. 듀얼 인체공학 피스톨 손잡이 (Pistol Grip Handle)
    final handlePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 8), width: 14, height: 26), const Radius.circular(5)),
      handlePaint,
    );
    // 손잡이 미끄럼 방지 홈 (Grip Grooves)
    final gripLine = Paint()..color = const Color(0xFF475569)..strokeWidth = 2;
    canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), gripLine);
    canvas.drawLine(const Offset(-6, 6), const Offset(6, 6), gripLine);
    canvas.drawLine(const Offset(-6, 12), const Offset(6, 12), gripLine);

    // 3-4. 수압 조절 밸브 레버 (Shut-off Ball Valve Lever)
    final leverPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(14, 2), width: 8, height: 22), const Radius.circular(3)),
      leverPaint,
    );
    canvas.drawCircle(const Offset(14, -8), 4.5, Paint()..color = const Color(0xFFB91C1C));

    // 3-5. 노즐 헤드 팁 & 분사 조절 고무 링 (Rubber Bumper Nozzle Tip)
    final tipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(0, -22), width: 26, height: 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(tipRect, Paint()..color = const Color(0xFF1E293B));

    // 황동 방수구 구멍 (Water Orifice Nozzle Hole)
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 16, height: 6),
      Paint()..color = const Color(0xFF0284C7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -28), width: 10, height: 4),
      Paint()..color = const Color(0xFFE0F2FE),
    );

    // 3-6. 분사 시 노즐 끝 고압 수압 아우라 글로우 (Water Jet Muzzle Glow)
    if (isSpraying) {
      canvas.drawCircle(
        const Offset(0, -32),
        16,
        Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        const Offset(0, -32),
        8,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // 3-7. 소방관 방수 장갑 손 (Gloves Holding the Nozzle firmly)
    final glovePaint = Paint()..color = const Color(0xFFF97316);
    canvas.drawCircle(const Offset(-13, 6), 9, glovePaint);
    canvas.drawCircle(const Offset(13, 6), 9, glovePaint);
    canvas.drawCircle(const Offset(-13, 6), 7, Paint()..color = const Color(0xFFC2410C));
    canvas.drawCircle(const Offset(13, 6), 7, Paint()..color = const Color(0xFFC2410C));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FireHosePainter oldDelegate) => true;
}
