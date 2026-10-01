import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

import 'dart:ui' as ui;

part 'models/firefighter_models.dart';
part 'painters/firefighter_painters.dart';

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
        painter: _BuildingScenePainter(
          type: type,
          spots: _currentMission.spots,
        ),
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

