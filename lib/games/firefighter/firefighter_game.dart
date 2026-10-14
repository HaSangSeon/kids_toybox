import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

part 'models/firefighter_models.dart';
part 'painters/firefighter_painters.dart';

part 'widgets/firefighter_stage_widgets.dart';
part 'widgets/firefighter_mission_widgets.dart';
part 'widgets/firefighter_action_widgets.dart';

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

  // Dispatch Phase & Rive Booster variables
  late AnimationController _dispatchAnimCtrl;
  late AnimationController _sirenLightCtrl;
  late AnimationController _truckBounceCtrl;
  double _dispatchProgress = 0.0;
  final List<Offset> _roadItems = [];
  final List<_BoosterParticle> _boosterParticles = [];
  bool _isBoosterActive = false;
  int _rewardChestTapCount = 0;

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
      _boosterParticles.clear();
      _isBoosterActive = false;
      _rewardChestTapCount = 0;
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
      _isBoosterActive = false;
      _phase = FireGamePhase.extinguish;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 60FPS PHYSICS UPDATE (Water Jet, Realistic Flames, Splashes, Smoke, Steam)
  // ─────────────────────────────────────────────────────────────────────────────

  void _updatePhysics() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;

    // Dispatch Phase: Update Booster Exhaust Particles
    if (_phase == FireGamePhase.dispatch) {
      final width = screenSize.width;
      final truckX = (_dispatchProgress * (width - 140)).clamp(15.0, width - 150);
      final roadY = screenSize.height - 210;

      if (_dispatchAnimCtrl.isAnimating) {
        final spawnChance = _isBoosterActive ? 1.0 : 0.6;
        if (_rng.nextDouble() < spawnChance) {
          final colors = _isBoosterActive
              ? [const Color(0xFFFF3366), const Color(0xFFFF9900), const Color(0xFFFFEE00), const Color(0xFF00E5FF)]
              : [const Color(0xFFFF6D00), const Color(0xFFFFAB00), const Color(0xFF90A4AE)];
          _boosterParticles.add(_BoosterParticle(
            pos: Offset(truckX - 4, roadY + 45 + (_rng.nextDouble() - 0.5) * 8),
            vel: Offset(-_rng.nextDouble() * (_isBoosterActive ? 7.0 : 3.5) - 2.5, (_rng.nextDouble() - 0.5) * 1.5),
            radius: _isBoosterActive ? 6.0 + _rng.nextDouble() * 5.0 : 3.5 + _rng.nextDouble() * 3.0,
            life: 1.0,
            color: colors[_rng.nextInt(colors.length)],
          ));
        }
      }

      for (int i = _boosterParticles.length - 1; i >= 0; i--) {
        final p = _boosterParticles[i];
        p.pos += p.vel;
        p.radius *= 0.95;
        p.life -= 0.04;
        if (p.life <= 0 || p.radius <= 0.6) {
          _boosterParticles.removeAt(i);
        }
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

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
