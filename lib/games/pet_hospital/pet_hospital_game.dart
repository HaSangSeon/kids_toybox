import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════


part 'models/pet_hospital_models.dart';
part 'painters/pet_hospital_painters.dart';

part 'widgets/pet_hospital_stage_widgets.dart';
part 'widgets/pet_hospital_treatment_widgets.dart';
part 'widgets/pet_hospital_tool_trays.dart';

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

  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
