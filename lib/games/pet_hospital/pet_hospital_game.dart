import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

import 'dart:ui' as ui;

part 'models/pet_hospital_models.dart';
part 'painters/pet_hospital_painters.dart';

class PetHospitalGame extends StatefulWidget {
  const PetHospitalGame({super.key});

  @override
  State<PetHospitalGame> createState() => _PetHospitalGameState();
}

class _PetHospitalGameState extends State<PetHospitalGame> with TickerProviderStateMixin {
  late List<_PatientData> _patients;
  late _PatientData _currentPatient;
  HospitalStep _step = HospitalStep.selectPatient;

  // Active Patient Live Progress
  late List<_ThornItem> _liveThorns;
  late List<_WoundItem> _liveWounds;
  double _currentTemp = 38.5;
  bool _isHeartbeatChecked = false;
  bool _isTempChecked = false;
  _BandaidPreset _selectedBandaid = _kBandaids[0];
  bool _isIcePackApplied = false;
  bool _isSyrupFed = false;
  bool _isTreatFed = false;

  // Dialogue
  String? _customDialogue;

  // Animation Controllers
  late AnimationController _bgDriftCtrl;   // Active ambient hospital background drift
  late AnimationController _idleCtrl;      // Continuous gentle breathing and ear twitch
  late AnimationController _heartbeatCtrl; // Heart pumping
  late AnimationController _pulseCtrl;     // Glowing target indicator pulse
  late AnimationController _jumpCtrl;      // Victory jump
  late AnimationController _ecgCtrl;       // Hospital monitor line sweep
  late AnimationController _tearCtrl;      // Tear drops falling when crying

  final List<_LiveParticle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _patients = _buildPatientList();
    _currentPatient = _patients[0];
    _initPatientData(_currentPatient);

    _bgDriftCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
    _idleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _ecgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _tearCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _heartbeatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _jumpCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // Particle updater loop
    _idleCtrl.addListener(() {
      if (_particles.isNotEmpty) {
        setState(() {
          for (final p in _particles) {
            p.pos += p.vel;
            p.opacity = (p.opacity - 0.04).clamp(0.0, 1.0);
          }
          _particles.removeWhere((p) => p.opacity <= 0.05);
        });
      }
    });
  }

  void _initPatientData(_PatientData patient) {
    _currentPatient = patient;
    _currentTemp = patient.initialTemp;
    _isHeartbeatChecked = false;
    _isTempChecked = false;
    _isIcePackApplied = false;
    _isSyrupFed = false;
    _isTreatFed = false;
    _customDialogue = null;
    _selectedBandaid = _kBandaids[0];

    _liveThorns = patient.thorns
        .map((t) => _ThornItem(id: t.id, label: t.label, pos: t.pos, angle: t.angle))
        .toList();

    _liveWounds = patient.wounds
        .map((w) => _WoundItem(id: w.id, label: w.label, pos: w.pos, width: w.width, height: w.height))
        .toList();
  }

  @override
  void dispose() {
    _bgDriftCtrl.dispose();
    _idleCtrl.dispose();
    _pulseCtrl.dispose();
    _ecgCtrl.dispose();
    _tearCtrl.dispose();
    _heartbeatCtrl.dispose();
    _jumpCtrl.dispose();
    super.dispose();
  }

  // ── Step Transitions with Soft, Gentle Sounds ───────────────────────────────

  void _playSoftChime() {
    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.35);
  }

  void _selectPatient(_PatientData patient) {
    AudioManager.instance.playClick();
    HapticFeedback.selectionClick();
    setState(() {
      _initPatientData(patient);
      _step = HospitalStep.diagnose;
      _customDialogue = '청진기(🩺)나 체온계(🌡️)를 환자 몸에 대어 진찰해주세요!';
    });
  }

  void _onCheckHeartbeat() {
    if (_isHeartbeatChecked) return;
    AudioManager.instance.playEffect('audio/thud.wav', rate: 1.3);
    HapticFeedback.mediumImpact();

    _heartbeatCtrl.forward().then((_) {
      if (mounted) {
        _heartbeatCtrl.reverse();
        AudioManager.instance.playEffect('audio/thud.wav', rate: 1.4);
      }
    });

    setState(() {
      _isHeartbeatChecked = true;
      _customDialogue = '두근두근! 콩닥콩닥 심장 소리가 건강하게 들려요! ❤️';
    });

    _spawnSparkles(const Offset(180, 255), color: const Color(0xFFFF5252), count: 10, text: '❤️');
    _checkDiagnoseComplete();
  }

  void _onCheckTemperature() {
    if (_isTempChecked) return;
    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.4);
    HapticFeedback.lightImpact();

    setState(() {
      _isTempChecked = true;
      _customDialogue = '삐빅! 열이 ${_currentTemp.toStringAsFixed(1)}℃로 많이 나요! 🌡️😱';
    });

    _spawnSparkles(const Offset(255, 110), color: const Color(0xFFFFB300), count: 8, text: '✨');
    _checkDiagnoseComplete();
  }

  void _checkDiagnoseComplete() {
    if (_isHeartbeatChecked && _isTempChecked) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _playSoftChime();
        setState(() {
          _step = HospitalStep.pluckThorns;
          _customDialogue = '박혀있는 가시를 핀셋으로 톡! 눌러 뽑아주세요! ✂️';
        });
      });
    }
  }

  void _pluckThorn(_ThornItem thorn) {
    if (thorn.isPlucked) return;

    AudioManager.instance.playEffect('audio/bubble_pop.wav', rate: 1.3);
    HapticFeedback.lightImpact();

    setState(() {
      thorn.isPlucked = true;
      _customDialogue = '${thorn.label}의 가시를 쏙 뽑았어요! 시원하다~ 🌵✨';
    });

    _spawnSparkles(thorn.pos, color: const Color(0xFFFFD54F), count: 10, text: '✨');

    // Check all thorns plucked
    if (_liveThorns.every((t) => t.isPlucked)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _playSoftChime();
        setState(() {
          _step = HospitalStep.disinfect;
          _customDialogue = '빨간 상처(💢)를 면봉으로 슥슥 문질러 소독해주세요! 🧴';
        });
      });
    }
  }

  void _onDisinfectWound(_WoundItem wound) {
    if (wound.healProgress >= 1.0) return;

    AudioManager.instance.playPetSpray();
    HapticFeedback.mediumImpact();

    setState(() {
      // 🧴 단 1회 터치로 즉시 100% 소독 완료!
      wound.healProgress = 1.0;
      _customDialogue = '${wound.label} 상처가 깨끗하게 소독되었어요! 🧴✨';
    });

    _spawnSparkles(wound.pos, color: const Color(0xFF81D4FA), count: 12, text: '🫧');
    _spawnSparkles(wound.pos, color: const Color(0xFFFFD54F), count: 8, text: '✨');

    // Check all wounds disinfected
    if (_liveWounds.every((w) => w.healProgress >= 1.0)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _playSoftChime();
        setState(() {
          _step = HospitalStep.applyBandaid;
          _customDialogue = '좋아하는 밴드를 고르고 상처를 찰칵 눌러주세요! 🩹';
        });
      });
    }
  }

  void _applyBandaidToWound(_WoundItem wound) {
    if (wound.isBandaidApplied) return;

    AudioManager.instance.playPetBandaid();
    HapticFeedback.mediumImpact();

    setState(() {
      wound.isBandaidApplied = true;
      wound.bandaidEmoji = _selectedBandaid.emoji;
      wound.bandaidColor = _selectedBandaid.color;
      _customDialogue = '${wound.label}에 ${_selectedBandaid.name}를 착! 붙였어요! 🩹💖';
    });

    _spawnSparkles(wound.pos, color: _selectedBandaid.color, count: 10, text: _selectedBandaid.emoji);

    // Check all bandaids applied
    if (_liveWounds.every((w) => w.isBandaidApplied)) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _playSoftChime();
        setState(() {
          _step = HospitalStep.coolAndSyrup;
          _customDialogue = '이마에 얼음팩(🧊)을 대고 입에 딸기 물약(🥄)을 먹여줘요!';
        });
      });
    }
  }

  void _applyIcePack() {
    if (_isIcePackApplied) return;

    AudioManager.instance.playPetIce();
    HapticFeedback.lightImpact();

    setState(() {
      _isIcePackApplied = true;
      _currentTemp = 36.5;
      _customDialogue = '얼음팩이 시원해서 열이 36.5℃로 뚝 떨어졌어요! 🧊✨';
    });

    _spawnSparkles(const Offset(180, 80), color: const Color(0xFF80DEEA), count: 12, text: '❄️');
    _checkCoolAndSyrupComplete();
  }

  void _feedSyrup() {
    if (_isSyrupFed) return;

    AudioManager.instance.playPetGulp();
    HapticFeedback.mediumImpact();

    setState(() {
      _isSyrupFed = true;
      _customDialogue = '달콤 딸기 물약 꿀꺽! 기운이 펄펄 나요! 🥄😋';
    });

    _spawnSparkles(const Offset(180, 165), color: const Color(0xFFFF4081), count: 12, text: '🍬');
    _checkCoolAndSyrupComplete();
  }

  void _checkCoolAndSyrupComplete() {
    if (_isIcePackApplied && _isSyrupFed) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _completeHospitalTreatment();
      });
    }
  }

  void _completeHospitalTreatment() {
    AudioManager.instance.playPetHeal();

    HapticFeedback.heavyImpact();
    _jumpCtrl.repeat(reverse: true);

    setState(() {
      _step = HospitalStep.complete;
      _customDialogue = _currentPatient.thankMessage;
    });

    // Celebration burst
    for (int i = 0; i < 25; i++) {
      _spawnSparkles(
        Offset(180 + (_rng.nextDouble() - 0.5) * 200, 180 + (_rng.nextDouble() - 0.5) * 200),
        color: Colors.amber,
        count: 1,
        text: ['🎉', '💖', '⭐', '🍭', '✨'][i % 5],
      );
    }
  }

  void _feedVictoryTreat() {
    if (_isTreatFed) return;
    AudioManager.instance.playPetGulp();
    HapticFeedback.heavyImpact();

    setState(() {
      _isTreatFed = true;
      _customDialogue = '달콤한 비타민 사탕 냠냠! 최고예요 의사선생님! 🍭🌟';
    });

    _spawnSparkles(const Offset(180, 165), color: Colors.orange, count: 15, text: '🍭');
  }

  void _spawnSparkles(Offset center, {required Color color, int count = 6, String text = '✨'}) {
    for (int i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * pi;
      final speed = 1.0 + _rng.nextDouble() * 2.5;
      _particles.add(_LiveParticle(
        pos: center,
        size: 14 + _rng.nextDouble() * 12,
        opacity: 1.0,
        color: color,
        text: text,
        vel: Offset(cos(angle) * speed, sin(angle) * speed - 1.0),
      ));
    }
  }

  void _resetGame() {
    AudioManager.instance.playClick();
    _jumpCtrl.stop();
    setState(() {
      _step = HospitalStep.selectPatient;
      _customDialogue = null;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI BUILD WITH ACTIVE ANIMATED BACKGROUND
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Dynamic Active Hospital Room Background (Floating Bubbles & Crosses)
          Positioned.fill(
            child: _buildActiveAnimatedHospitalBackground(),
          ),

          // 2. Main Game UI Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildStepProgressBar(),
                Expanded(
                  child: _step == HospitalStep.selectPatient
                      ? _buildPatientSelectView()
                      : _buildTreatmentStage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Animated Hospital Background ────────────────────────────────────

  Widget _buildActiveAnimatedHospitalBackground() {
    return AnimatedBuilder(
      animation: _bgDriftCtrl,
      builder: (context, child) {
        final t = _bgDriftCtrl.value;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFFE1F5FE)],
            ),
          ),
          child: Stack(
            children: [
              // Floating ambient medical bubbles and pastel crosses
              ...List.generate(7, (i) {
                final startX = (0.12 * i + 0.08) * 380;
                final speed = 1.0 + (i % 3) * 0.4;
                final currentY = 700 - ((t * speed * 700 + (i * 110)) % 750);
                final swayX = startX + sin((t * 2 * pi) + i) * 16;
                final icon = ['🫧', '✚', '✨', '🫧', '✚', '⭐', '🫧'][i];
                final size = [20.0, 16.0, 18.0, 24.0, 16.0, 18.0, 22.0][i];
                final opacity = [0.4, 0.25, 0.45, 0.35, 0.25, 0.4, 0.3][i];

                return Positioned(
                  left: swayX,
                  top: currentY,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(icon, style: TextStyle(fontSize: size, color: const Color(0xFF00ACC1))),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Top Navigation Bar (With Clean Spacing) ────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              if (_step == HospitalStep.selectPatient) {
                Navigator.of(context).pop();
              } else {
                setState(() {
                  _step = HospitalStep.selectPatient;
                  _jumpCtrl.stop();
                });
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00838F), size: 26),
            ),
          ),

          // Title Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '꼬마 동물 병원',
                  style: GoogleFonts.jua(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00838F),
                  ),
                ),
              ],
            ),
          ),

          // Reset / Another Patient Button
          if (_step != HospitalStep.selectPatient)
            GestureDetector(
              onTap: _resetGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔄', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '다른 친구',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Step Progress Indicator ─────────────────────────────────────────────────

  Widget _buildStepProgressBar() {
    if (_step == HospitalStep.selectPatient) return const SizedBox.shrink();

    final steps = [
      {'step': HospitalStep.diagnose, 'emoji': '🩺', 'label': '진찰'},
      {'step': HospitalStep.pluckThorns, 'emoji': '✂️', 'label': '가시'},
      {'step': HospitalStep.disinfect, 'emoji': '🧴', 'label': '소독'},
      {'step': HospitalStep.applyBandaid, 'emoji': '🩹', 'label': '밴드'},
      {'step': HospitalStep.coolAndSyrup, 'emoji': '🧊', 'label': '열/물약'},
      {'step': HospitalStep.complete, 'emoji': '✨', 'label': '완치!'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: steps.map((s) {
          final isCurrent = _step == s['step'];
          final isPassed = _step.index > (s['step'] as HospitalStep).index;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isCurrent ? 30 : 24,
                height: isCurrent ? 30 : 24,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF00ACC1)
                      : (isPassed ? const Color(0xFF80DEEA) : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: Colors.cyan.withValues(alpha: 0.4), blurRadius: 6)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  s['emoji'] as String,
                  style: TextStyle(fontSize: isCurrent ? 15 : 12),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                s['label'] as String,
                style: GoogleFonts.jua(
                  fontSize: 9.5,
                  color: isCurrent ? const Color(0xFF00838F) : Colors.grey.shade600,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: Patient Selection View ─────────────────────────────────────────

  Widget _buildPatientSelectView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '어떤 동물 친구를 치료해줄까요?',
                    style: GoogleFonts.jua(
                      fontSize: 18,
                      color: const Color(0xFF00838F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _patients.map((patient) => _buildPatientSelectCard(patient)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelectCard(_PatientData patient) {
    return GestureDetector(
      onTap: () => _selectPatient(patient),
      child: Container(
        width: 145,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: patient.darkColor, width: 3.2),
          boxShadow: [
            BoxShadow(
              color: patient.darkColor.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: patient.faceColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: patient.darkColor, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(patient.emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 6),
            Text(
              patient.name,
              style: GoogleFonts.jua(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                patient.title,
                style: GoogleFonts.jua(fontSize: 10.5, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: patient.darkColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '치료하기 🩺',
                style: GoogleFonts.jua(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Unified Treatment Stage (No scrolling hijack - 100% Solid & Stable) ──

  Widget _buildTreatmentStage() {
    return Column(
      children: [
        // Dialogue Banner
        _buildDialogueBanner(),

        // Medical Hospital Stage Canvas with FittedBox
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: _buildPatientInteractiveCanvas(),
            ),
          ),
        ),

        // Bottom Tool Tray
        _buildBottomToolTray(),
      ],
    );
  }

  Widget _buildDialogueBanner() {
    final text = _customDialogue ?? _currentPatient.symptom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF80DEEA), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(_currentPatient.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jua(
                fontSize: 13.5,
                color: const Color(0xFF006064),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Patient Interactive Body Canvas (360x380 Large Hospital Scene) ─────────

  // ── Patient Interactive Body Canvas (Clean Nordic Clinic Scene) ───────────

  Widget _buildPatientInteractiveCanvas() {
    const canvasW = 350.0;
    const canvasH = 440.0;

    return AnimatedBuilder(
      animation: _jumpCtrl,
      builder: (context, child) {
        final jumpOffset = _step == HospitalStep.complete ? sin(_jumpCtrl.value * pi) * 20 : 0.0;
        return Transform.translate(
          offset: Offset(0, -jumpOffset),
          child: child,
        );
      },
      child: SizedBox(
        width: canvasW,
        height: canvasH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Warm & Clean Minimalist Clinic Examination Mat
            _buildLargeHospitalRoomScene(),

            // 2. Master Nordic Vector Animal Patient (Scaled up 1.25x for big, adorable presence)
            _buildLargeAliveAnimalPatient(),

            // 3. Elegant Stethoscope Target (On Chest / Tummy - Natural placement)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 85,
                top: 220,
                width: 90,
                height: 90,
                child: _buildHeartbeatTarget(),
              ),

            // 4. Elegant Thermometer Target (On Forehead - Unobtrusive)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 175,
                top: 42,
                width: 90,
                height: 90,
                child: _buildThermometerTarget(),
              ),

            // 5. Cute Cartoon Ice Pack on Forehead
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 36,
                child: _buildRealisticIcePack(),
              ),

            // 6. Sweet Syrup Spoon on Mouth
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 145,
                child: _buildSyrupMouthTarget(),
              ),

            // 7. Harmonious Storybook Wounds & Band-aids (소독 단계부터 나타남 - 진찰/가시 단계에서는 숨김!)
            if (_step != HospitalStep.diagnose && _step != HospitalStep.pluckThorns)
              ..._liveWounds.map((w) => _buildRealisticWound(w)),

            // 8. Harmonious Cartoon Thorns (가시 뽑기 단계에서만 집중 노출!)
            if (_step == HospitalStep.pluckThorns)
              ..._liveThorns.map((t) => _buildRealisticThorn(t)),

            // 9. Sparkles & Particles
            ..._particles.map((p) => Positioned(
                  left: p.pos.dx - (p.size / 2),
                  top: p.pos.dy - (p.size / 2),
                  child: Opacity(
                    opacity: p.opacity,
                    child: Text(p.text, style: TextStyle(fontSize: p.size, color: p.color)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Warm & Clean Minimalist Clinic Background (최적의 대비 & 포근한 색감) ───

  Widget _buildLargeHospitalRoomScene() {
    return Container(
      width: 335,
      height: 425,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Soothing soft pastel mint clinic background
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 3.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4), // Warm cozy yellow pastel towel
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE082), width: 1.8),
        ),
      ),
    );
  }

  // ── Master Nordic Vector Animal Character ─────────────────────────────────

  Widget _buildLargeAliveAnimalPatient() {
    final patient = _currentPatient;
    final isHappy = _step == HospitalStep.complete;
    final isFever = _currentTemp > 37.5 && !_isIcePackApplied;
    final isSad = !isHappy && (isFever || _liveWounds.any((w) => !w.isBandaidApplied));
    final isOpenMouth = _step == HospitalStep.coolAndSyrup && !_isSyrupFed;

    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, child) {
        // 동물 모습을 화면에 꽉 차게 1.25배 크게 렌더링!
        final breatheScale = (1.0 + (_idleCtrl.value * 0.02)) * 1.25;

        return Transform.scale(
          scale: breatheScale,
          child: SizedBox(
            width: 320,
            height: 340,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Master Nordic Animal Canvas (동물별 완벽한 시그니처 실루엣 & 일러스트)
                CustomPaint(
                  size: const Size(320, 340),
                  painter: _NordicAnimalIllustrationPainter(
                    patient: patient,
                    idleProgress: _idleCtrl.value,
                    isHappy: isHappy,
                    isFever: isFever,
                    isSad: isSad,
                    isOpenMouth: isOpenMouth,
                  ),
                ),

                // 2. Animated crying tear drops when hurt / sick
                if (isSad)
                  AnimatedBuilder(
                    animation: _tearCtrl,
                    builder: (context, child) {
                      final tearY = 145 + (_tearCtrl.value * 18);
                      final tearOpacity = (1.0 - _tearCtrl.value).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Positioned(
                            top: tearY,
                            left: 105,
                            child: Opacity(
                              opacity: tearOpacity,
                              child: const Text('💧', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          Positioned(
                            top: tearY,
                            right: 105,
                            child: Opacity(
                              opacity: tearOpacity,
                              child: const Text('💧', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartbeatTarget() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == 'stethoscope',
      onAcceptWithDetails: (details) {
        if (details.data == 'stethoscope') {
          _onCheckHeartbeat();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onCheckHeartbeat,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                if (_isHeartbeatChecked) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '정상 ❤️',
                          style: GoogleFonts.jua(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  );
                }

                final scale = isHovered ? 1.25 : (1.0 + _pulseCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: (isHovered ? const Color(0xFFE0F7FA) : const Color(0xFFFFF0F5)).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHovered ? const Color(0xFF00ACC1) : const Color(0xFFFF4081),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isHovered ? Colors.cyan : Colors.pinkAccent).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isHovered ? '🩺' : '❤️',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pinkAccent, width: 1),
                        ),
                        child: Text(
                          '청진기 🩺',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.pink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Step 2 Target: Thermometer on Forehead (Clean & Subtle) ────────────────

  Widget _buildThermometerTarget() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == 'thermometer',
      onAcceptWithDetails: (details) {
        if (details.data == 'thermometer') {
          _onCheckTemperature();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onCheckTemperature,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                if (_isTempChecked) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentTemp.toStringAsFixed(1)}℃',
                          style: GoogleFonts.jua(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  );
                }

                final scale = isHovered ? 1.25 : (1.0 + _pulseCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: (isHovered ? const Color(0xFFFFF8E1) : const Color(0xFFFFF3E0)).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHovered ? const Color(0xFFFFA000) : const Color(0xFFFFB300),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isHovered ? '🌡️' : '🌡️',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade800, width: 1),
                        ),
                        child: Text(
                          '체온계 🌡️',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Step 6 Clean Target: Ice Pack on Forehead ──────────────────────────────

  Widget _buildRealisticIcePack() {
    return GestureDetector(
      onTap: _applyIcePack,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isIcePackApplied ? 1.0 : (1.0 + _pulseCtrl.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: _isIcePackApplied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00ACC1), width: 2.0),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.25), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🧊', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Text(
                          '36.5℃ 정상!',
                          style: GoogleFonts.jua(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF006064)),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00ACC1), width: 2.4),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🧊', style: TextStyle(fontSize: 24)),
                  ),
          );
        },
      ),
    );
  }

  // ── Step 6 Clean Target: Syrup on Mouth ────────────────────────────────────

  Widget _buildSyrupMouthTarget() {
    return GestureDetector(
      onTap: _feedSyrup,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isSyrupFed ? 1.0 : (1.0 + _pulseCtrl.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: _isSyrupFed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pinkAccent, width: 2.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💖', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 3),
                        Text('꿀꺽!', style: GoogleFonts.jua(fontSize: 12, color: Colors.pink.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE91E63), width: 2.4),
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🥄', style: TextStyle(fontSize: 22)),
                  ),
          );
        },
      ),
    );
  }

  // ── Highly Visible & Easy-to-Tap Cartoon Thorn ────────────────────────────

  Widget _buildRealisticThorn(_ThornItem thorn) {
    if (thorn.isPlucked) return const SizedBox.shrink();

    final isPluckStep = _step == HospitalStep.pluckThorns;

    return Positioned(
      left: thorn.pos.dx - 30,
      top: thorn.pos.dy - 30,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isPluckStep) {
            _pluckThorn(thorn);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = isPluckStep ? (1.0 + _pulseCtrl.value * 0.20) : 1.0;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. 선명한 황금빛 펄싱 아우라 링 (어떤 털 색상에서도 1초 만에 눈에 띔)
                    if (isPluckStep)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFF176).withValues(alpha: 0.75),
                          border: Border.all(color: const Color(0xFFFF8F00), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                    // 2. 큼직하고 또렷한 가시 벡터 그래픽
                    Transform.rotate(
                      angle: thorn.angle,
                      child: CustomPaint(
                        size: const Size(28, 40),
                        painter: _NordicThornPainter(),
                      ),
                    ),

                    // 3. 핀셋 터치 유도 미니 뱃지 (✂️ 콕!)
                    if (isPluckStep)
                      Positioned(
                        top: -8,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            '✂️ 쏙!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Harmonious Storybook Wound & Band-aid ──────────────────────────────────

  Widget _buildRealisticWound(_WoundItem wound) {
    final isDisinfectStep = _step == HospitalStep.disinfect && wound.healProgress < 1.0;
    final isBandaidStep = _step == HospitalStep.applyBandaid && !wound.isBandaidApplied;

    return Positioned(
      left: wound.pos.dx - (wound.width / 2),
      top: wound.pos.dy - (wound.height / 2),
      child: GestureDetector(
        onTap: () {
          if (_step == HospitalStep.disinfect) {
            _onDisinfectWound(wound);
          } else if (_step == HospitalStep.applyBandaid) {
            _applyBandaidToWound(wound);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final isPulsing = isDisinfectStep || isBandaidStep;
            final scale = isPulsing ? (1.0 + _pulseCtrl.value * 0.18) : 1.0;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: wound.width + 24,
                height: wound.height + 24,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 소독 또는 밴드 붙이기 단계 펄싱 아우라
                    if (isDisinfectStep)
                      Container(
                        width: wound.width + 16,
                        height: wound.height + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF80DEEA).withValues(alpha: 0.5),
                          border: Border.all(color: const Color(0xFF00ACC1), width: 2.2),
                        ),
                      )
                    else if (isBandaidStep)
                      Container(
                        width: wound.width + 16,
                        height: wound.height + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF80AB).withValues(alpha: 0.45),
                          border: Border.all(color: const Color(0xFFFF4081), width: 2.2),
                        ),
                      ),

                    // Applied Cute Band-aid
                    if (wound.isBandaidApplied)
                      _buildRealisticBandaidWidget(
                        emoji: wound.bandaidEmoji ?? '❤️',
                        color: wound.bandaidColor ?? const Color(0xFFFF5252),
                        width: wound.width + 8,
                        height: wound.height + 2,
                      )
                    // Disinfected/healed clean skin with sparkle
                    else if (wound.healProgress >= 1.0)
                      Container(
                        width: wound.width,
                        height: wound.height,
                        alignment: Alignment.center,
                        child: const Text('✨', style: TextStyle(fontSize: 22)),
                      )
                    // Cartoon Scratch Abrasion
                    else
                      CustomPaint(
                        size: Size(wound.width, wound.height),
                        painter: _NordicScratchPainter(
                          healProgress: wound.healProgress,
                          isHighlight: isDisinfectStep,
                        ),
                      ),

                    // 안내 미니 뱃지 (🧴 톡! 또는 🩹 착!)
                    if (isDisinfectStep)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00838F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Text(
                            '🧴 톡!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (isBandaidStep)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Text(
                            '🩹 착!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Cute Pastel Nordic Band-aid Widget ────────────────────────────────────

  Widget _buildRealisticBandaidWidget({
    required String emoji,
    required Color color,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Soft cream fabric
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle))),
          ),
          Container(
            width: width * 0.48,
            height: height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Bottom Interactive Tool Tray ──────────────────────────────────────────

  Widget _buildBottomToolTray() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _buildToolTrayContent(),
    );
  }

  Widget _buildToolTrayContent() {
    switch (_step) {
      case HospitalStep.diagnose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '청진기와 체온계를 손가락으로 드래그해서 몸에 대주세요! 🩺🌡️',
              style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF006064), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDraggableActionToolButton(
                  dragData: 'stethoscope',
                  icon: '🩺',
                  title: '청진기',
                  subtitle: _isHeartbeatChecked ? '콩닥 확인 완료!' : '배로 드래그 👆',
                  isDone: _isHeartbeatChecked,
                  onTap: _onCheckHeartbeat,
                ),
                _buildDraggableActionToolButton(
                  dragData: 'thermometer',
                  icon: '🌡️',
                  title: '체온계',
                  subtitle: _isTempChecked ? '${_currentTemp.toStringAsFixed(1)}℃ 완료!' : '이마로 드래그 👆',
                  isDone: _isTempChecked,
                  onTap: _onCheckTemperature,
                ),
              ],
            ),
          ],
        );

      case HospitalStep.pluckThorns:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✂️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              '환자의 몸에 박힌 가시를 톡 눌러 뽑아주세요!',
              style: GoogleFonts.jua(fontSize: 14.5, color: const Color(0xFF00838F), fontWeight: FontWeight.bold),
            ),
          ],
        );

      case HospitalStep.disinfect:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧴', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              '빨간 상처 부위를 톡톡 눌러서 소독해요!',
              style: GoogleFonts.jua(fontSize: 14.5, color: const Color(0xFF00838F), fontWeight: FontWeight.bold),
            ),
          ],
        );

      case HospitalStep.applyBandaid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '원하는 밴드를 고른 후 상처 자리를 찰칵 눌러주세요!',
              style: GoogleFonts.jua(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: _kBandaids.map((b) {
                    final isSelected = _selectedBandaid.emoji == b.emoji;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          setState(() => _selectedBandaid = b);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? b.color.withValues(alpha: 0.18) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? b.color : Colors.grey.shade300,
                              width: isSelected ? 3.0 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: b.color.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(b.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Text(
                                b.name,
                                style: GoogleFonts.jua(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.grey.shade900 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );

      case HospitalStep.coolAndSyrup:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionToolButton(
              icon: '🧊',
              title: '얼음팩',
              subtitle: _isIcePackApplied ? '36.5℃ 정상!' : '이마에 얹기',
              isDone: _isIcePackApplied,
              onTap: _applyIcePack,
            ),
            _buildActionToolButton(
              icon: '🥄',
              title: '딸기 물약',
              subtitle: _isSyrupFed ? '꿀꺽 완치!' : '입에 주기',
              isDone: _isSyrupFed,
              onTap: _feedSyrup,
            ),
          ],
        );

      case HospitalStep.complete:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: _feedVictoryTreat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🍭', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      _isTreatFed ? '사탕 먹기 완료! ✨' : '칭찬 사탕 주기 🍬',
                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _resetGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00897B)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '다음 환자 진료 ➡️',
                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDraggableActionToolButton({
    required String dragData,
    required String icon,
    required String title,
    String? subtitle,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    final buttonContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone ? Colors.green.shade400 : const Color(0xFF00ACC1),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone ? Colors.green.withValues(alpha: 0.15) : Colors.cyan.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.jua(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDone ? Colors.green.shade700 : const Color(0xFF00838F),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.jua(
                    fontSize: 10,
                    color: isDone ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          if (isDone) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          ],
        ],
      ),
    );

    if (isDone) {
      return buttonContent;
    }

    return Draggable<String>(
      data: dragData,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00ACC1), width: 4.0),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 42)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: buttonContent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: buttonContent,
      ),
    );
  }

  Widget _buildActionToolButton({
    required String icon,
    required String title,
    String? subtitle,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade50 : Colors.cyan.shade50,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone ? Colors.green.shade400 : const Color(0xFF00ACC1),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDone ? Colors.green.withValues(alpha: 0.15) : Colors.cyan.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jua(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.green.shade700 : const Color(0xFF00838F),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.jua(
                      fontSize: 11,
                      color: isDone ? Colors.green.shade600 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            if (isDone) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

