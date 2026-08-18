import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

enum HospitalStep {
  selectPatient, // 환자 고르기
  diagnose,      // 청진기 & 체온계 진찰
  pluckThorns,   // 핀셋으로 가시 뽑기
  disinfect,     // 소독 면봉으로 상처 문지르기
  applyBandaid,  // 캐릭터 반창고 붙이기
  coolAndSyrup,  // 얼음팩 열내리기 & 달콤 물약 먹이기
  complete,      // 완치 축하 & 칭찬 사탕 선물
}

class _ThornItem {
  final int id;
  final String label;
  final Offset pos; // Relative position in 360x380 canvas
  final double angle;
  bool isPlucked = false;

  _ThornItem({
    required this.id,
    required this.label,
    required this.pos,
    this.angle = 0.3,
  });
}

class _WoundItem {
  final int id;
  final String label;
  final Offset pos; // Relative position in 360x380 canvas
  final double width;
  final double height;
  double healProgress = 0.0; // 0.0 -> 1.0
  String? bandaidEmoji;
  Color? bandaidColor;
  bool isBandaidApplied = false;

  _WoundItem({
    required this.id,
    required this.label,
    required this.pos,
    this.width = 56.0,
    this.height = 36.0,
  });
}

class _PatientData {
  final String id;
  final String name;
  final String emoji;
  final String title;
  final String symptom;
  final Color bodyColor;
  final Color darkColor;
  final Color faceColor;
  final Color bellyColor;
  final Color earColor;
  final Color eyeColor;
  final double initialTemp;
  final List<_ThornItem> thorns;
  final List<_WoundItem> wounds;
  final String thankMessage;

  const _PatientData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.title,
    required this.symptom,
    required this.bodyColor,
    required this.darkColor,
    required this.faceColor,
    required this.bellyColor,
    required this.earColor,
    required this.eyeColor,
    required this.initialTemp,
    required this.thorns,
    required this.wounds,
    required this.thankMessage,
  });
}

List<_PatientData> _buildPatientList() {
  return [
    _PatientData(
      id: 'dog',
      name: '아기 강아지 멍이',
      emoji: '🐶',
      title: '쿵 넘어져서 가시가 콕콕!',
      symptom: '공놀이하다 풀숲에 넘어져서 가시가 박히고 열이 나요! 멍멍 🐶',
      bodyColor: const Color(0xFFFFA726),
      darkColor: const Color(0xFFE65100),
      faceColor: const Color(0xFFFFE0B2),
      bellyColor: const Color(0xFFFFF3E0),
      earColor: const Color(0xFF8D6E63),
      eyeColor: const Color(0xFF4E342E),
      initialTemp: 38.6,
      thorns: [
        _ThornItem(id: 0, label: '왼쪽 앞발', pos: const Offset(45, 235), angle: -0.4),
        _ThornItem(id: 1, label: '오른쪽 앞발', pos: const Offset(315, 235), angle: 0.4),
        _ThornItem(id: 2, label: '귀여운 귀', pos: const Offset(65, 85), angle: -0.2),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(135, 275), width: 58, height: 38),
        _WoundItem(id: 1, label: '오른쪽 볼', pos: const Offset(250, 160), width: 50, height: 34),
      ],
      thankMessage: '의사 선생님 덕분에 하나도 안 아파요! 꼬리 살랑살랑 고마워요! 🐶💖',
    ),
    _PatientData(
      id: 'cat',
      name: '아기 고양이 나비',
      emoji: '🐱',
      title: '콜록콜록 감기에 걸렸어요!',
      symptom: '차가운 아이스크림을 먹고 열이 펄펄 나요! 야옹~ 🐱',
      bodyColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFD50000),
      faceColor: const Color(0xFFFFCDD2),
      bellyColor: const Color(0xFFFCE4EC),
      earColor: const Color(0xFFF8BBD0),
      eyeColor: const Color(0xFF00897B),
      initialTemp: 38.9,
      thorns: [
        _ThornItem(id: 0, label: '왼쪽 앞발', pos: const Offset(45, 235), angle: -0.4),
        _ThornItem(id: 1, label: '오른쪽 앞발', pos: const Offset(315, 235), angle: 0.4),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(180, 275), width: 60, height: 38),
        _WoundItem(id: 1, label: '왼쪽 볼', pos: const Offset(110, 160), width: 50, height: 34),
      ],
      thankMessage: '열도 내리고 콧물도 쏙 들어갔어요! 골골송 선물할게요~ 🐱🌸',
    ),
    _PatientData(
      id: 'bear',
      name: '곰돌이 몽이',
      emoji: '🐻',
      title: '벌한테 쏘여서 부었어요!',
      symptom: '달콤한 꿀을 먹다가 벌침이 콕 박히고 퉁퉁 부었어요! 몽몽 🐻',
      bodyColor: const Color(0xFF8D6E63),
      darkColor: const Color(0xFF4E342E),
      faceColor: const Color(0xFFD7CCC8),
      bellyColor: const Color(0xFFEFEBE9),
      earColor: const Color(0xFFBCAAA4),
      eyeColor: const Color(0xFF3E2723),
      initialTemp: 38.5,
      thorns: [
        _ThornItem(id: 0, label: '오른쪽 귀', pos: const Offset(295, 75), angle: 0.3),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(45, 235), angle: -0.4),
        _ThornItem(id: 2, label: '오른쪽 앞발', pos: const Offset(315, 235), angle: 0.4),
      ],
      wounds: [
        _WoundItem(id: 0, label: '왼쪽 배', pos: const Offset(145, 275), width: 56, height: 36),
        _WoundItem(id: 1, label: '오른쪽 배', pos: const Offset(215, 275), width: 56, height: 36),
      ],
      thankMessage: '벌침도 다 빠지고 붓기가 싹 가라앉았어요! 몽이 힘이 불끈! 🐻🍯',
    ),
    _PatientData(
      id: 'rabbit',
      name: '토끼 토리',
      emoji: '🐰',
      title: '나뭇가지에 긁혔어요!',
      symptom: '당근 밭에서 신나게 뛰다가 나뭇가지에 긁히고 열이 나요! 🐰',
      bodyColor: const Color(0xFFF48FB1),
      darkColor: const Color(0xFFC2185B),
      faceColor: const Color(0xFFFCE4EC),
      bellyColor: const Color(0xFFFFFFFF),
      earColor: const Color(0xFFF8BBD0),
      eyeColor: const Color(0xFF880E4F),
      initialTemp: 38.4,
      thorns: [
        _ThornItem(id: 0, label: '긴 귀', pos: const Offset(115, 40), angle: -0.15),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(45, 235), angle: -0.4),
        _ThornItem(id: 2, label: '오른쪽 앞발', pos: const Offset(315, 235), angle: 0.4),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(180, 275), width: 60, height: 38),
        _WoundItem(id: 1, label: '왼쪽 볼', pos: const Offset(110, 160), width: 50, height: 34),
      ],
      thankMessage: '예쁜 반창고 붙여줘서 고마워요! 깡총깡총 신나요! 🐰🥕',
    ),
  ];
}

class _BandaidPreset {
  final String emoji;
  final String name;
  final Color color;
  const _BandaidPreset({required this.emoji, required this.name, required this.color});
}

const List<_BandaidPreset> _kBandaids = [
  _BandaidPreset(emoji: '❤️', name: '하트 밴드', color: Color(0xFFFF5252)),
  _BandaidPreset(emoji: '⭐', name: '별빛 밴드', color: Color(0xFFFFD600)),
  _BandaidPreset(emoji: '🐻', name: '곰돌이 밴드', color: Color(0xFF8D6E63)),
  _BandaidPreset(emoji: '🌸', name: '꽃잎 밴드', color: Color(0xFFFF4081)),
  _BandaidPreset(emoji: '🦖', name: '공룡 밴드', color: Color(0xFF4CAF50)),
  _BandaidPreset(emoji: '🌈', name: '무지개 밴드', color: Color(0xFF9C27B0)),
  _BandaidPreset(emoji: '🚗', name: '붕붕 밴드', color: Color(0xFF03A9F4)),
];

class _LiveParticle {
  Offset pos;
  double size;
  double opacity;
  Color color;
  String text;
  Offset vel;

  _LiveParticle({
    required this.pos,
    required this.size,
    required this.opacity,
    required this.color,
    this.text = '✨',
    this.vel = const Offset(0, -1),
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// GAME MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

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

  void _onCheckHeartbeat() async {
    if (_isHeartbeatChecked) return;
    AudioManager.instance.playEffect('audio/thud.wav', rate: 1.3);
    HapticFeedback.mediumImpact();
    await _heartbeatCtrl.forward();
    await _heartbeatCtrl.reverse();
    AudioManager.instance.playEffect('audio/thud.wav', rate: 1.4);

    setState(() {
      _isHeartbeatChecked = true;
      _customDialogue = '두근두근! 콩닥콩닥 심장 소리가 건강하게 들려요! ❤️';
    });

    _spawnSparkles(const Offset(180, 255), color: const Color(0xFFFF5252), count: 8, text: '❤️');
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

    AudioManager.instance.playEffect('audio/car_soap_foam.wav', rate: 1.4);
    HapticFeedback.lightImpact();

    setState(() {
      wound.healProgress = (wound.healProgress + 0.5).clamp(0.0, 1.0);
      if (wound.healProgress >= 1.0) {
        _customDialogue = '${wound.label} 상처가 깨끗하게 소독되었어요! 🧴✨';
      }
    });

    _spawnSparkles(wound.pos, color: const Color(0xFF81D4FA), count: 8, text: '🫧');

    // Check all wounds disinfected
    if (_liveWounds.every((w) => w.healProgress >= 1.0)) {
      Future.delayed(const Duration(milliseconds: 600), () {
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

    AudioManager.instance.playEffect('audio/item_heart.wav', rate: 1.25);
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

    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.3);
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

    AudioManager.instance.playEffect('audio/munch.wav', rate: 1.25);
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
    // Quiet, gentle, joyful fairy chime instead of loud fanfare
    AudioManager.instance.playEffect('audio/chime.wav', rate: 1.25);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      AudioManager.instance.playEffect('audio/item_star.wav', rate: 1.2);
    });

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
    AudioManager.instance.playEffect('audio/item_star.wav', rate: 1.2);
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
          border: Border.all(color: patient.bodyColor.withValues(alpha: 0.6), width: 3),
          boxShadow: [
            BoxShadow(
              color: patient.bodyColor.withValues(alpha: 0.2),
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
                color: patient.faceColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: patient.bodyColor, width: 2.5),
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
                color: patient.bodyColor,
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

  Widget _buildPatientInteractiveCanvas() {
    const canvasW = 360.0;
    const canvasH = 380.0;

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
            // 1. Large Hospital Bed Mat & Pillow Background
            _buildLargeHospitalRoomScene(),

            // 2. Big Animated Chibi Animal Patient (with Illustrated Anime Eyes & Muzzle)
            _buildLargeAliveAnimalPatient(),

            // 3. Heartbeat Diagnosis Target on Tummy / Chest
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 145,
                top: 235,
                child: _buildHeartbeatTarget(),
              ),

            // 4. Thermometer Diagnosis Target on Forehead / Ear
            if (_step == HospitalStep.diagnose)
              Positioned(
                right: 50,
                top: 85,
                child: _buildThermometerTarget(),
              ),

            // 5. Realistic Clean Ice Pack on Forehead
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 60,
                child: _buildRealisticIcePack(),
              ),

            // 6. Sweet Syrup Spoon on Mouth (Clean, uncluttered)
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 165,
                child: _buildSyrupMouthTarget(),
              ),

            // 7. Realistic Wounds & Band-aids
            ..._liveWounds.map((w) => _buildRealisticWound(w)),

            // 8. Realistic Embedded Thorns
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

  // ── Big Hospital Room Bed, Pillow & ECG Monitor Scene ──────────────────────

  Widget _buildLargeHospitalRoomScene() {
    return Container(
      width: 340,
      height: 370,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: const Color(0xFF81C784), width: 4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Large fluffy white pillow
          Positioned(
            top: 15,
            left: 40,
            right: 40,
            height: 95,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),

          // Mini Heart Rate ECG Monitor (Top Right)
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              width: 66,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155), width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 9)),
                      AnimatedBuilder(
                        animation: _heartbeatCtrl,
                        builder: (context, child) => Text(
                          _step == HospitalStep.complete ? '75' : (_isHeartbeatChecked ? '82' : '--'),
                          style: const TextStyle(fontSize: 9, color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _ecgCtrl,
                    builder: (context, child) => CustomPaint(
                      size: const Size(54, 16),
                      painter: _EcgLinePainter(animValue: _ecgCtrl.value),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // IV Drip Bottle (Top Left)
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              width: 22,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4DD0E1), width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('💧', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Big Alive Breathing Chibi Animal Character ─────────────────────────────

  Widget _buildLargeAliveAnimalPatient() {
    final patient = _currentPatient;
    final isHappy = _step == HospitalStep.complete;
    final isFever = _currentTemp > 37.5 && !_isIcePackApplied;

    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, child) {
        final breatheScale = 1.0 + (_idleCtrl.value * 0.025);
        final earAngle = sin(_idleCtrl.value * pi) * 0.04;

        return Transform.scale(
          scale: breatheScale,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── 1. Big Ears ──
              Transform.rotate(
                angle: earAngle,
                child: _buildPatientEars(patient),
              ),

              // ── 2. Little Feet ──
              Positioned(
                bottom: 24,
                left: 105,
                child: _buildPawCircle(patient.bodyColor, patient.faceColor, size: 44),
              ),
              Positioned(
                bottom: 24,
                right: 105,
                child: _buildPawCircle(patient.bodyColor, patient.faceColor, size: 44),
              ),

              // ── 3. Big Plump Body & Tummy (배) ──
              Positioned(
                top: 175,
                child: Container(
                  width: 215,
                  height: 165,
                  decoration: BoxDecoration(
                    color: patient.bodyColor,
                    borderRadius: BorderRadius.circular(75),
                    border: Border.all(color: patient.darkColor, width: 4.5),
                    boxShadow: [
                      BoxShadow(
                        color: patient.darkColor.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 155,
                    height: 120,
                    decoration: BoxDecoration(
                      color: patient.bellyColor,
                      borderRadius: BorderRadius.circular(55),
                    ),
                  ),
                ),
              ),

              // ── 4. Left & Right Paws (양쪽 앞발) ──
              Positioned(
                top: 195,
                left: 20,
                child: _buildPawCircle(patient.bodyColor, patient.faceColor, size: 58),
              ),
              Positioned(
                top: 195,
                right: 20,
                child: _buildPawCircle(patient.bodyColor, patient.faceColor, size: 58),
              ),

              // ── 5. Big Expressive Head & Face ──
              Positioned(
                top: 55,
                child: Container(
                  width: 205,
                  height: 165,
                  decoration: BoxDecoration(
                    color: patient.faceColor,
                    borderRadius: BorderRadius.circular(65),
                    border: Border.all(color: patient.bodyColor, width: 5.5),
                    boxShadow: [
                      BoxShadow(
                        color: patient.bodyColor.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fever red blush / healthy blush
                      Positioned(
                        top: 92,
                        left: 18,
                        child: Container(
                          width: 32,
                          height: 20,
                          decoration: BoxDecoration(
                            color: (isFever ? const Color(0xFFFF5252) : const Color(0xFFFF8DA1)).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 92,
                        right: 18,
                        child: Container(
                          width: 32,
                          height: 20,
                          decoration: BoxDecoration(
                            color: (isFever ? const Color(0xFFFF5252) : const Color(0xFFFF8DA1)).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      // Illustrated Anime Style Eyes (Left & Right)
                      Positioned(
                        top: 55,
                        left: 45,
                        child: CustomPaint(
                          size: const Size(28, 28),
                          painter: _IllustratedEyePainter(
                            isHappy: isHappy,
                            isSad: isFever || _liveWounds.any((w) => !w.isBandaidApplied),
                            eyeColor: patient.eyeColor,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 55,
                        right: 45,
                        child: CustomPaint(
                          size: const Size(28, 28),
                          painter: _IllustratedEyePainter(
                            isHappy: isHappy,
                            isSad: isFever || _liveWounds.any((w) => !w.isBandaidApplied),
                            eyeColor: patient.eyeColor,
                          ),
                        ),
                      ),

                      // Animated crying tear drops when hurt / sick
                      if (!isHappy && (isFever || _liveWounds.any((w) => !w.isBandaidApplied)))
                        AnimatedBuilder(
                          animation: _tearCtrl,
                          builder: (context, child) {
                            final tearY = 78 + (_tearCtrl.value * 20);
                            final tearOpacity = (1.0 - _tearCtrl.value).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                Positioned(
                                  top: tearY,
                                  left: 50,
                                  child: Opacity(
                                    opacity: tearOpacity,
                                    child: const Text('💧', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                Positioned(
                                  top: tearY,
                                  right: 50,
                                  child: Opacity(
                                    opacity: tearOpacity,
                                    child: const Text('💧', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                      // Illustrated Animal Nose & Mouth
                      Positioned(
                        top: 86,
                        child: CustomPaint(
                          size: const Size(40, 36),
                          painter: _IllustratedMouthPainter(
                            isHappy: isHappy,
                            isOpenMouth: _step == HospitalStep.coolAndSyrup && !_isSyrupFed,
                            isSad: !isHappy && (isFever || _liveWounds.any((w) => !w.isBandaidApplied)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPawCircle(Color mainColor, Color padColor, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: mainColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.5,
        height: size * 0.5,
        decoration: BoxDecoration(
          color: padColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildPatientEars(_PatientData patient) {
    if (patient.id == 'rabbit') {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -12,
            left: 95,
            child: _buildBunnyEar(patient.bodyColor, patient.earColor),
          ),
          Positioned(
            top: -12,
            right: 95,
            child: _buildBunnyEar(patient.bodyColor, patient.earColor),
          ),
        ],
      );
    }

    if (patient.id == 'dog') {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 50,
            left: 45,
            child: Container(
              width: 48,
              height: 78,
              decoration: BoxDecoration(
                color: patient.earColor,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 45,
            child: Container(
              width: 48,
              height: 78,
              decoration: BoxDecoration(
                color: patient.earColor,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 38,
          left: 70,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: patient.bodyColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: patient.earColor, shape: BoxShape.circle),
            ),
          ),
        ),
        Positioned(
          top: 38,
          right: 70,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: patient.bodyColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: patient.earColor, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBunnyEar(Color outerColor, Color innerColor) {
    return Container(
      width: 38,
      height: 85,
      decoration: BoxDecoration(
        color: outerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 64,
        decoration: BoxDecoration(
          color: innerColor,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ── Step 2 Target: Heartbeat on Tummy (DragTarget & Tap) ───────────────────

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
          onTap: _onCheckHeartbeat,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _isHeartbeatChecked ? 1.0 : (isHovered ? 1.35 : (1.0 + _pulseCtrl.value * 0.22));
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHeartbeatChecked ? Colors.green.shade50 : (isHovered ? Colors.red.shade100 : Colors.red.shade50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHeartbeatChecked ? Colors.green : Colors.redAccent,
                      width: isHovered ? 4.5 : 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isHeartbeatChecked ? Colors.green : Colors.redAccent).withValues(alpha: isHovered ? 0.6 : 0.4),
                        blurRadius: isHovered ? 16 : 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isHeartbeatChecked ? '✅' : '❤️',
                        style: const TextStyle(fontSize: 30),
                      ),
                      if (!_isHeartbeatChecked)
                        Text(
                          isHovered ? '청진기 닿음!' : '청진기 대기 👆',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Step 2 Target: Thermometer on Forehead (DragTarget & Tap) ──────────────

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
          onTap: _onCheckTemperature,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _isTempChecked ? 1.0 : (isHovered ? 1.35 : (1.0 + _pulseCtrl.value * 0.22));
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isTempChecked ? Colors.green.shade50 : (isHovered ? Colors.amber.shade100 : Colors.amber.shade50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isTempChecked ? Colors.green : Colors.orangeAccent,
                      width: isHovered ? 4.5 : 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isTempChecked ? Colors.green : Colors.orangeAccent).withValues(alpha: isHovered ? 0.6 : 0.4),
                        blurRadius: isHovered ? 16 : 12,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isTempChecked ? '✅' : '🌡️',
                        style: const TextStyle(fontSize: 30),
                      ),
                      if (!_isTempChecked)
                        Text(
                          isHovered ? '체온계 닿음!' : '체온계 대기 👆',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Step 6 Clean Target: Ice Pack on Forehead (No Clutter) ─────────────────

  Widget _buildRealisticIcePack() {
    return GestureDetector(
      onTap: _applyIcePack,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isIcePackApplied ? 1.0 : (1.0 + _pulseCtrl.value * 0.18);
          return Transform.scale(
            scale: scale,
            child: _isIcePackApplied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00ACC1), width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🧊', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(
                          '36.5℃ 정상!',
                          style: GoogleFonts.jua(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF006064)),
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
                      border: Border.all(color: const Color(0xFF00ACC1), width: 3.0),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.4), blurRadius: 10),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🧊', style: TextStyle(fontSize: 26)),
                  ),
          );
        },
      ),
    );
  }

  // ── Step 6 Clean Target: Syrup on Mouth (No Clutter) ────────────────────────

  Widget _buildSyrupMouthTarget() {
    return GestureDetector(
      onTap: _feedSyrup,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isSyrupFed ? 1.0 : (1.0 + _pulseCtrl.value * 0.18);
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
                      border: Border.all(color: const Color(0xFFE91E63), width: 2.8),
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withValues(alpha: 0.4), blurRadius: 10),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🥄', style: TextStyle(fontSize: 24)),
                  ),
          );
        },
      ),
    );
  }

  // ── Realistic Embedded Thorn (진짜 박힌 가시 & 부어오른 자국) ──────────────

  Widget _buildRealisticThorn(_ThornItem thorn) {
    if (thorn.isPlucked) return const SizedBox.shrink();

    final isPluckStep = _step == HospitalStep.pluckThorns;

    return Positioned(
      left: thorn.pos.dx - 26,
      top: thorn.pos.dy - 26,
      child: GestureDetector(
        onTap: () {
          if (isPluckStep) {
            _pluckThorn(thorn);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = isPluckStep ? (1.0 + _pulseCtrl.value * 0.22) : 1.0;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 1. Reddened swollen skin puncture ring
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.shade200.withValues(alpha: 0.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),

                    // 2. Realistic wooden thorn needle rendering with angle
                    Transform.rotate(
                      angle: thorn.angle,
                      child: CustomPaint(
                        size: const Size(22, 32),
                        painter: _RealisticThornPainter(),
                      ),
                    ),

                    // 3. Touch indicator badge
                    if (isPluckStep)
                      Positioned(
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 4),
                            ],
                          ),
                          child: const Text('쏙! 👆', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
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

  // ── Realistic Wound & 3D Adhesive Band-aid (진짜 상처 & 반창고) ──────────────

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
                width: wound.width + 12,
                height: wound.height + 12,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Applied Realistic Band-aid
                    if (wound.isBandaidApplied)
                      _buildRealisticBandaidWidget(
                        emoji: wound.bandaidEmoji ?? '❤️',
                        color: wound.bandaidColor ?? const Color(0xFFFF5252),
                        width: wound.width + 8,
                        height: wound.height + 4,
                      )
                    // Disinfected/healed clean skin with sparkle
                    else if (wound.healProgress >= 1.0)
                      Container(
                        width: wound.width,
                        height: wound.height,
                        decoration: BoxDecoration(
                          color: isBandaidStep ? Colors.yellow.shade100 : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isBandaidStep ? Colors.amber : Colors.cyan,
                            width: 2.5,
                            style: isBandaidStep ? BorderStyle.solid : BorderStyle.none,
                          ),
                          boxShadow: isBandaidStep
                              ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.4), blurRadius: 8)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 22)),
                            if (isBandaidStep)
                              Positioned(
                                bottom: -3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('착! 👆', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      )
                    // Raw/inflamed realistic scratch abrasion
                    else
                      CustomPaint(
                        size: Size(wound.width, wound.height),
                        painter: _RealisticAbrasionPainter(
                          healProgress: wound.healProgress,
                          isHighlight: isDisinfectStep,
                        ),
                        child: isDisinfectStep
                            ? Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('슥삭 👆', style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              )
                            : null,
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

  // ── Realistic Woven 3D Adhesive Band-aid Widget ───────────────────────────

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
        color: const Color(0xFFFFE0B2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (i) => Container(width: 3, height: 3, decoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle))),
          ),
          Container(
            width: width * 0.45,
            height: height * 0.78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 3),
              ],
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
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
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00ACC1), width: 3.5),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(icon, style: const TextStyle(fontSize: 38)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: buttonContent,
      ),
      child: GestureDetector(
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

// ── Illustrated Anime/Pixar Style Eye Painter (진짜 예쁜 동물 눈 렌더링) ────────

class _IllustratedEyePainter extends CustomPainter {
  final bool isHappy;
  final bool isSad;
  final Color eyeColor;

  _IllustratedEyePainter({
    required this.isHappy,
    required this.isSad,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Happy smiling crescent eye
    if (isHappy) {
      final happyPaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(0, h * 0.65);
      path.quadraticBezierTo(w / 2, 0, w, h * 0.65);
      canvas.drawPath(path, happyPaint);
      return;
    }

    // Big glossy anime iris
    final irisPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF212121),
          eyeColor,
          eyeColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), irisPaint);

    // Deep black pupil
    final pupilPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.6), pupilPaint);

    // Big primary specular white catchlight
    final bigShinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.35, h * 0.3), w * 0.22, bigShinePaint);

    // Secondary smaller bounce catchlight
    canvas.drawCircle(Offset(w * 0.68, h * 0.68), w * 0.12, bigShinePaint);

    // Sad / watery lower shimmer
    if (isSad) {
      final waterPaint = Paint()
        ..color = const Color(0xFF81D4FA).withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.4, h * 0.8), w * 0.1, waterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustratedEyePainter oldDelegate) =>
      oldDelegate.isHappy != isHappy || oldDelegate.isSad != isSad || oldDelegate.eyeColor != eyeColor;
}

// ── Illustrated Animal Muzzle & Mouth Painter (진짜 귀여운 코 & 입 렌더링) ───────

class _IllustratedMouthPainter extends CustomPainter {
  final bool isHappy;
  final bool isOpenMouth;
  final bool isSad;

  _IllustratedMouthPainter({
    required this.isHappy,
    required this.isOpenMouth,
    required this.isSad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final centerX = w / 2;

    // 1. Nose (Soft glossy 3D nose)
    final nosePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4E342E), Color(0xFF2E1C14)],
      ).createShader(Rect.fromLTWH(centerX - 10, 0, 20, 13))
      ..style = PaintingStyle.fill;

    final noseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(centerX - 10, 0, 20, 13),
      const Radius.circular(7),
    );
    canvas.drawRRect(noseRRect, nosePaint);

    // Specular white highlight on nose
    final noseShinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(centerX - 6, 2, 6, 3), noseShinePaint);

    // 2. Mouth Lip Lines or Open Mouth for syrup
    if (isOpenMouth) {
      // Big open mouth with pink tongue
      final openMouthPaint = Paint()
        ..color = const Color(0xFF880E4F)
        ..style = PaintingStyle.fill;

      final mouthPath = Path();
      mouthPath.moveTo(centerX - 12, 16);
      mouthPath.quadraticBezierTo(centerX, 36, centerX + 12, 16);
      mouthPath.close();
      canvas.drawPath(mouthPath, openMouthPaint);

      // Tongue
      final tonguePaint = Paint()
        ..color = const Color(0xFFFF4081)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromLTWH(centerX - 8, 24, 16, 10), tonguePaint);
    } else {
      // Illustrated 'ω' smile or trembling mouth
      final lipPaint = Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Vertical line from nose
      canvas.drawLine(Offset(centerX, 13), Offset(centerX, 18), lipPaint);

      final mouthPath = Path();
      if (isHappy) {
        // Broad happy smile
        mouthPath.moveTo(centerX - 12, 18);
        mouthPath.quadraticBezierTo(centerX - 6, 25, centerX, 18);
        mouthPath.quadraticBezierTo(centerX + 6, 25, centerX + 12, 18);
      } else if (isSad) {
        // Sad trembling mouth
        mouthPath.moveTo(centerX - 10, 22);
        mouthPath.quadraticBezierTo(centerX - 5, 17, centerX, 21);
        mouthPath.quadraticBezierTo(centerX + 5, 17, centerX + 10, 22);
      } else {
        // Gentle smiling mouth
        mouthPath.moveTo(centerX - 10, 18);
        mouthPath.quadraticBezierTo(centerX - 5, 23, centerX, 18);
        mouthPath.quadraticBezierTo(centerX + 5, 23, centerX + 10, 18);
      }
      canvas.drawPath(mouthPath, lipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IllustratedMouthPainter oldDelegate) =>
      oldDelegate.isHappy != isHappy || oldDelegate.isOpenMouth != isOpenMouth || oldDelegate.isSad != isSad;
}

// ── Realistic Thorn Painter (진짜 나무 가시 텍스처 & 침 렌더링) ──────────────────

class _RealisticThornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Wood / thorn dark brown body
    final thornPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5D4037), Color(0xFF8D6E63), Color(0xFF3E2723)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w / 2, 0); // Sharp tip
    path.lineTo(w * 0.8, h * 0.7);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.lineTo(w * 0.2, h * 0.7);
    path.close();

    canvas.drawShadow(path, Colors.black, 3.0, false);
    canvas.drawPath(path, thornPaint);

    final spinePaint = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w / 2, 2), Offset(w / 2, h * 0.85), spinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Realistic Abrasion / Scratch Wound Painter (진짜 찰과상 상처 렌더링) ────────

class _RealisticAbrasionPainter extends CustomPainter {
  final double healProgress;
  final bool isHighlight;

  _RealisticAbrasionPainter({required this.healProgress, required this.isHighlight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final opacity = (1.0 - healProgress).clamp(0.0, 1.0);

    final redPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFFE53935).withValues(alpha: 0.8 * opacity),
          Color(0xFFFFCDD2).withValues(alpha: 0.4 * opacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), redPaint);

    final scratchPaint = Paint()
      ..color = Color(0xFFB71C1C).withValues(alpha: 0.9 * opacity)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.2, h * 0.3), Offset(w * 0.8, h * 0.4), scratchPaint);
    canvas.drawLine(Offset(w * 0.25, h * 0.5), Offset(w * 0.75, h * 0.6), scratchPaint);
    canvas.drawLine(Offset(w * 0.35, h * 0.7), Offset(w * 0.65, h * 0.75), scratchPaint);

    if (healProgress > 0.0) {
      final gelPaint = Paint()
        ..color = const Color(0xFF81D4FA).withValues(alpha: 0.5 * healProgress)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.8), gelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticAbrasionPainter oldDelegate) =>
      oldDelegate.healProgress != healProgress || oldDelegate.isHighlight != isHighlight;
}

// ── ECG Line Painter for Heart Monitor ────────────────────────────────────────

class _EcgLinePainter extends CustomPainter {
  final double animValue;
  _EcgLinePainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final midY = h / 2;

    path.moveTo(0, midY);
    path.lineTo(w * 0.25, midY);
    path.lineTo(w * 0.35, midY - 6);
    path.lineTo(w * 0.45, midY + 6);
    path.lineTo(w * 0.55, midY - 8);
    path.lineTo(w * 0.65, midY + 4);
    path.lineTo(w * 0.75, midY);
    path.lineTo(w, midY);

    canvas.drawPath(path, paint);

    final scanX = animValue * w;
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(scanX, midY), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _EcgLinePainter oldDelegate) => oldDelegate.animValue != animValue;
}
