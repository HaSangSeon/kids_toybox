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
      bodyColor: const Color(0xFFC49A6C), // Warm caramel camel brown
      darkColor: const Color(0xFF6D4C41), // Chocolate brown
      faceColor: const Color(0xFFC49A6C),
      bellyColor: const Color(0xFFEFEBE9),
      earColor: const Color(0xFF6D4C41),  // Dark floppy ears
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.6,
      thorns: [
        _ThornItem(id: 0, label: '오른쪽 귀', pos: const Offset(238, 120), angle: 0.35),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(136, 265), angle: -0.2),
        _ThornItem(id: 2, label: '귀여운 꼬리', pos: const Offset(65, 205), angle: -0.4),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(160, 200), width: 54, height: 32),
        _WoundItem(id: 1, label: '오른쪽 볼', pos: const Offset(205, 140), width: 44, height: 28),
      ],
      thankMessage: '의사 선생님 덕분에 하나도 안 아파요! 꼬리 살랑살랑 고마워요! 🐶💖',
    ),
    _PatientData(
      id: 'cat',
      name: '아기 고양이 나비',
      emoji: '🐱',
      title: '콜록콜록 감기에 걸렸어요!',
      symptom: '차가운 아이스크림을 먹고 열이 펄펄 나요! 야옹~ 🐱',
      bodyColor: const Color(0xFF90A4AE), // Chic cool gray
      darkColor: const Color(0xFF455A64),
      faceColor: const Color(0xFF90A4AE),
      bellyColor: const Color(0xFFCFD8DC),
      earColor: const Color(0xFFCFD8DC),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.9,
      thorns: [
        _ThornItem(id: 0, label: '우아한 꼬리', pos: const Offset(255, 190), angle: 0.4),
        _ThornItem(id: 1, label: '왼쪽 볼', pos: const Offset(105, 140), angle: -0.3),
      ],
      wounds: [
        _WoundItem(id: 0, label: '폭신한 배', pos: const Offset(156, 195), width: 54, height: 32),
        _WoundItem(id: 1, label: '오른쪽 앞발', pos: const Offset(176, 265), width: 44, height: 28),
      ],
      thankMessage: '열도 내리고 콧물도 쏙 들어갔어요! 골골송 선물할게요~ 🐱🌸',
    ),
    _PatientData(
      id: 'bear',
      name: '곰돌이 몽이',
      emoji: '🐻',
      title: '벌한테 쏘여서 부었어요!',
      symptom: '달콤한 꿀을 먹다가 벌침이 콕 박히고 퉁퉁 부었어요! 몽몽 🐻',
      bodyColor: const Color(0xFF795548), // Deep warm bear brown
      darkColor: const Color(0xFF4E342E),
      faceColor: const Color(0xFFD7CCC8), // Light cream snout
      bellyColor: const Color(0xFF8D6E63),
      earColor: const Color(0xFF5D4037),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.5,
      thorns: [
        _ThornItem(id: 0, label: '오른쪽 곰 귀', pos: const Offset(228, 88), angle: 0.3),
        _ThornItem(id: 1, label: '왼쪽 손', pos: const Offset(65, 170), angle: -0.4),
        _ThornItem(id: 2, label: '오른쪽 손', pos: const Offset(255, 170), angle: 0.4),
      ],
      wounds: [
        _WoundItem(id: 0, label: '왼쪽 배', pos: const Offset(130, 205), width: 50, height: 30),
        _WoundItem(id: 1, label: '오른쪽 배', pos: const Offset(190, 205), width: 50, height: 30),
      ],
      thankMessage: '벌침도 다 빠지고 붓기가 싹 가라앉았어요! 몽이 힘이 불끈! 🐻🍯',
    ),
    _PatientData(
      id: 'rabbit',
      name: '토끼 토리',
      emoji: '🐰',
      title: '나뭇가지에 긁혔어요!',
      symptom: '당근 밭에서 신나게 뛰다가 나뭇가지에 긁히고 열이 나요! 🐰',
      bodyColor: const Color(0xFFB2EBF2), // Refreshing soft pastel mint-sky
      darkColor: const Color(0xFF4DD0E1),
      faceColor: const Color(0xFFB2EBF2),
      bellyColor: const Color(0xFFFFFFFF),
      earColor: const Color(0xFFFFFFFF),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.4,
      thorns: [
        _ThornItem(id: 0, label: '쫑긋한 귀', pos: const Offset(125, 45), angle: -0.15),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(132, 185), angle: -0.25),
        _ThornItem(id: 2, label: '오른쪽 발', pos: const Offset(205, 285), angle: 0.3),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(160, 205), width: 54, height: 32),
        _WoundItem(id: 1, label: '왼쪽 볼', pos: const Offset(115, 145), width: 44, height: 28),
      ],
      thankMessage: '예쁜 반창고 붙여줘서 고마워요! 깡총깡총 신나요! 🐰🥕',
    ),
    _PatientData(
      id: 'panda',
      name: '아기 판다 바오',
      emoji: '🐼',
      title: '대나무 숲에서 쿵 굴렀어요!',
      symptom: '대나무 숲에서 데굴데굴 구르다 가시가 박히고 열이 나요! 🐼🎋',
      bodyColor: const Color(0xFFFAFAFA), // Crisp pure white
      darkColor: const Color(0xFF263238), // Dark charcoal black
      faceColor: const Color(0xFFB0BEC5),
      bellyColor: const Color(0xFFFFFFFF),
      earColor: const Color(0xFF263238),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.7,
      thorns: [
        _ThornItem(id: 0, label: '동글 판다 귀', pos: const Offset(228, 88), angle: 0.3),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(65, 170), angle: -0.35),
        _ThornItem(id: 2, label: '오른쪽 발', pos: const Offset(205, 290), angle: 0.25),
      ],
      wounds: [
        _WoundItem(id: 0, label: '하얀 배', pos: const Offset(160, 205), width: 54, height: 32),
        _WoundItem(id: 1, label: '왼쪽 볼', pos: const Offset(110, 150), width: 44, height: 28),
      ],
      thankMessage: '대나무 잎처럼 시원하고 개운해요! 바오 쿵덕쿵덕 신나요! 🐼🎋',
    ),
    _PatientData(
      id: 'fox',
      name: '아기 여우 루루',
      emoji: '🦊',
      title: '장미 덤불에 꼬리가 콕콕!',
      symptom: '나비 잡으러 장미 덤불에 들어갔다가 가시가 박히고 열이 나요! 🦊🌸',
      bodyColor: const Color(0xFFFF8A65), // Soft warm coral orange
      darkColor: const Color(0xFFD84315), // Dark fox terracotta
      faceColor: const Color(0xFFFF8A65),
      bellyColor: const Color(0xFFFFF8E1), // Cream muzzle & bib
      earColor: const Color(0xFF3E2723),  // Chocolate ear tips
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.5,
      thorns: [
        _ThornItem(id: 0, label: '왼쪽 뾰족 귀', pos: const Offset(95, 75), angle: -0.3),
        _ThornItem(id: 1, label: '풍성한 꼬리', pos: const Offset(260, 190), angle: 0.4),
        _ThornItem(id: 2, label: '오른쪽 앞발', pos: const Offset(180, 265), angle: 0.2),
      ],
      wounds: [
        _WoundItem(id: 0, label: '폭신한 배', pos: const Offset(155, 200), width: 54, height: 32),
        _WoundItem(id: 1, label: '오른쪽 볼', pos: const Offset(205, 140), width: 44, height: 28),
      ],
      thankMessage: '풍성한 꼬리를 살랑살랑 흔들며 인사해요! 루루 행복해요! 🦊🍁',
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

  // ── Patient Interactive Body Canvas (Clean Nordic Clinic Scene) ───────────

  Widget _buildPatientInteractiveCanvas() {
    const canvasW = 340.0;
    const canvasH = 360.0;

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

            // 2. Master Nordic Vector Animal Patient
            _buildLargeAliveAnimalPatient(),

            // 3. Elegant Stethoscope Target (On Chest / Tummy)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 115,
                top: 155,
                width: 90,
                height: 90,
                child: _buildHeartbeatTarget(),
              ),

            // 4. Elegant Thermometer Target (On Forehead)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 115,
                top: 75,
                width: 90,
                height: 90,
                child: _buildThermometerTarget(),
              ),

            // 5. Cute Cartoon Ice Pack on Forehead
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 65,
                child: _buildRealisticIcePack(),
              ),

            // 6. Sweet Syrup Spoon on Mouth
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 135,
                child: _buildSyrupMouthTarget(),
              ),

            // 7. Harmonious Storybook Wounds & Band-aids
            ..._liveWounds.map((w) => _buildRealisticWound(w)),

            // 8. Harmonious Cartoon Thorns
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
      width: 325,
      height: 345,
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
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4), // Warm cozy yellow pastel towel
          borderRadius: BorderRadius.circular(20),
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
        final breatheScale = 1.0 + (_idleCtrl.value * 0.02);

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
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      color: (isHovered ? const Color(0xFFE0F7FA) : const Color(0xFFFFF0F5)).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHovered ? const Color(0xFF00ACC1) : const Color(0xFFFF4081),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isHovered ? Colors.cyan : Colors.pinkAccent).withValues(alpha: 0.35),
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
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (isHovered ? const Color(0xFFFFF8E1) : const Color(0xFFFFF3E0)).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHovered ? const Color(0xFFFFA000) : const Color(0xFFFFB300),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isHovered ? '🌡️' : '✨',
                      style: const TextStyle(fontSize: 24),
                    ),
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

  // ── Harmonious Cartoon Thorn ───────────────────────────────────────────────

  Widget _buildRealisticThorn(_ThornItem thorn) {
    if (thorn.isPlucked) return const SizedBox.shrink();

    final isPluckStep = _step == HospitalStep.pluckThorns;

    return Positioned(
      left: thorn.pos.dx - 18,
      top: thorn.pos.dy - 18,
      child: GestureDetector(
        onTap: () {
          if (isPluckStep) {
            _pluckThorn(thorn);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = isPluckStep ? (1.0 + _pulseCtrl.value * 0.18) : 1.0;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (isPluckStep)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFE082).withValues(alpha: 0.4),
                        ),
                      ),
                    Transform.rotate(
                      angle: thorn.angle,
                      child: CustomPaint(
                        size: const Size(18, 28),
                        painter: _NordicThornPainter(),
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
            final scale = isPulsing ? (1.0 + _pulseCtrl.value * 0.15) : 1.0;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: wound.width + 10,
                height: wound.height + 10,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Applied Cute Band-aid
                    if (wound.isBandaidApplied)
                      _buildRealisticBandaidWidget(
                        emoji: wound.bandaidEmoji ?? '❤️',
                        color: wound.bandaidColor ?? const Color(0xFFFF5252),
                        width: wound.width + 6,
                        height: wound.height + 2,
                      )
                    // Disinfected/healed clean skin with sparkle
                    else if (wound.healProgress >= 1.0)
                      Container(
                        width: wound.width,
                        height: wound.height,
                        alignment: Alignment.center,
                        child: const Text('✨', style: TextStyle(fontSize: 20)),
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

// ── 🌟 Nordic Vector Animal Master Painter (완벽한 동물별 실루엣 일러스트) ──────

class _NordicAnimalIllustrationPainter extends CustomPainter {
  final _PatientData patient;
  final double idleProgress;
  final bool isHappy;
  final bool isFever;
  final bool isSad;
  final bool isOpenMouth;

  _NordicAnimalIllustrationPainter({
    required this.patient,
    required this.idleProgress,
    required this.isHappy,
    required this.isFever,
    required this.isSad,
    required this.isOpenMouth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final breathe = sin(idleProgress * 2 * pi) * 2.5;

    switch (patient.id) {
      case 'rabbit':
        _drawBunny(canvas, size, cx, cy, breathe);
        break;
      case 'bear':
        _drawBear(canvas, size, cx, cy, breathe);
        break;
      case 'dog':
        _drawDog(canvas, size, cx, cy, breathe);
        break;
      case 'panda':
        _drawPanda(canvas, size, cx, cy, breathe);
        break;
      case 'fox':
        _drawFox(canvas, size, cx, cy, breathe);
        break;
      case 'cat':
      default:
        _drawCat(canvas, size, cx, cy, breathe);
        break;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐰 1. BUNNY (하늘빛 조약돌 바디 + 쫑긋한 롱 토끼 귀 + 앙증맞은 앞발)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawBunny(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // ── 1. Long Bunny Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 45, 95);
    leftEarPath.cubicTo(cx - 50, 45, cx - 48, 12, cx - 35, 12);
    leftEarPath.cubicTo(cx - 22, 12, cx - 22, 45, cx - 18, 90);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    // Left Ear Inner White
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 40, 90);
    leftEarInner.cubicTo(cx - 44, 48, cx - 42, 20, cx - 35, 20);
    leftEarInner.cubicTo(cx - 28, 20, cx - 28, 48, cx - 24, 85);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, whitePaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 18, 90);
    rightEarPath.cubicTo(cx + 22, 45, cx + 22, 12, cx + 35, 12);
    rightEarPath.cubicTo(cx + 48, 12, cx + 50, 45, cx + 45, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    // Right Ear Inner White
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 24, 85);
    rightEarInner.cubicTo(cx + 28, 48, cx + 28, 20, cx + 35, 20);
    rightEarInner.cubicTo(cx + 42, 20, cx + 44, 48, cx + 40, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, whitePaint);

    // ── 2. Little Feet at Bottom ──
    final leftFoot = Path()
      ..moveTo(cx - 65, 290)
      ..cubicTo(cx - 85, 305, cx - 45, 310, cx - 40, 295)
      ..close();
    canvas.drawPath(leftFoot, bodyPaint);

    final rightFoot = Path()
      ..moveTo(cx + 40, 295)
      ..cubicTo(cx + 45, 310, cx + 85, 305, cx + 65, 290)
      ..close();
    canvas.drawPath(rightFoot, bodyPaint);

    // ── 3. Smooth Pear/Teardrop Body ──
    final bodyPath = Path();
    bodyPath.moveTo(cx - 48, 92 - breathe);
    bodyPath.cubicTo(cx - 65, 130, cx - 72, 180, cx - 80, 240);
    bodyPath.cubicTo(cx - 85, 285, cx + 85, 285, cx + 80, 240);
    bodyPath.cubicTo(cx + 72, 180, cx + 65, 130, cx + 48, 92 - breathe);
    bodyPath.cubicTo(cx + 30, 72 - breathe, cx - 30, 72 - breathe, cx - 48, 92 - breathe);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Crisp outline for high visibility
    final outlinePaint = Paint()
      ..color = const Color(0xFF4FC3F7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftEarPath, outlinePaint);
    canvas.drawPath(rightEarPath, outlinePaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // ── 4. Front Tucked Paws ──
    final leftPaw = Path()
      ..moveTo(cx - 28, 175)
      ..cubicTo(cx - 40, 185, cx - 32, 200, cx - 22, 192);
    canvas.drawPath(leftPaw, strokePaint);

    final rightPaw = Path()
      ..moveTo(cx + 28, 175)
      ..cubicTo(cx + 40, 185, cx + 32, 200, cx + 22, 192);
    canvas.drawPath(rightPaw, strokePaint);

    // ── 5. Facial Features (Eyes, Nose, Mouth) ──
    _drawBeadEyes(canvas, cx - 30, 135, cx + 30, 135, 6.5);
    _drawNordicNoseMouth(canvas, cx, 145, const Color(0xFF263238), isTiny: true);
    _drawCheekBlush(canvas, cx - 48, 146, cx + 48, 146, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐻 2. BEAR (듬직하고 둥근 갈색 체형 + 동그란 곰 귀 + 밝은 머즐)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawBear(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final muzzlePaint = Paint()..color = const Color(0xFFD7CCC8)..style = PaintingStyle.fill;
    final earInnerPaint = Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.fill;

    // ── 1. Round Bear Ears ──
    canvas.drawCircle(Offset(cx - 68, 88), 24, bodyPaint);
    canvas.drawCircle(Offset(cx - 68, 88), 13, earInnerPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 24, bodyPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 13, earInnerPaint);

    // ── 2. Stout Bear Feet ──
    final leftFoot = Path()
      ..moveTo(cx - 60, 280)
      ..cubicTo(cx - 75, 315, cx - 35, 318, cx - 30, 285)
      ..close();
    canvas.drawPath(leftFoot, bodyPaint);

    final rightFoot = Path()
      ..moveTo(cx + 30, 285)
      ..cubicTo(cx + 35, 318, cx + 75, 315, cx + 60, 280)
      ..close();
    canvas.drawPath(rightFoot, bodyPaint);

    // ── 3. Stubby Side Arms ──
    final leftArm = Path()
      ..moveTo(cx - 75, 145)
      ..cubicTo(cx - 110, 160, cx - 112, 190, cx - 78, 195)
      ..close();
    canvas.drawPath(leftArm, bodyPaint);

    final rightArm = Path()
      ..moveTo(cx + 75, 145)
      ..cubicTo(cx + 110, 160, cx + 112, 190, cx + 78, 195)
      ..close();
    canvas.drawPath(rightArm, bodyPaint);

    // ── 4. Chunky Rounded Bear Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 180, height: 210),
      const Radius.circular(85),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 5. Muzzle & Face ──
    // Cream Snout
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 148), width: 48, height: 36),
      muzzlePaint,
    );

    _drawBeadEyes(canvas, cx - 38, 122, cx + 38, 122, 7.0);
    _drawNordicNoseMouth(canvas, cx, 142, const Color(0xFF212121), isTiny: false);
    _drawCheekBlush(canvas, cx - 55, 138, cx + 55, 138, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐶 3. DOG (카라멜 바디 + 축 늘어진 초코색 귀 + 앙증맞은 말린 꼬리 + 앞다리)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawDog(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final earPaint = Paint()..color = const Color(0xFF6D4C41)..style = PaintingStyle.fill;
    final legStrokePaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // ── 1. Curled-up Puppy Tail on the Left ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx - 70, 240)
      ..cubicTo(cx - 105, 245, cx - 118, 205, cx - 95, 190);
    canvas.drawPath(tailPath, tailPaint);

    // ── 2. Floppy Chocolate Puppy Ears ──
    // Left Ear: starts near head top, curves outward and droops down with rounded lobe
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 55, 95);
    leftEarPath.cubicTo(cx - 100, 85, cx - 105, 145, cx - 88, 155);
    leftEarPath.cubicTo(cx - 72, 162, cx - 68, 125, cx - 50, 115);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, earPaint);

    // Right Ear: mirrors to the right
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 55, 95);
    rightEarPath.cubicTo(cx + 100, 85, cx + 105, 145, cx + 88, 155);
    rightEarPath.cubicTo(cx + 72, 162, cx + 68, 125, cx + 50, 115);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, earPaint);

    // ── 3. Smooth Rounded Dog Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 165, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Two Vertical Front Legs ──
    canvas.drawLine(Offset(cx - 24, 215), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 24, 215), Offset(cx + 24, 285), legStrokePaint);
    // Paw arches
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 22, height: 16), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 24, 285), width: 22, height: 16), 0, pi, false, legStrokePaint);

    // ── 5. Facial Features ──
    _drawBeadEyes(canvas, cx - 34, 125, cx + 34, 125, 7.0);
    _drawNordicNoseMouth(canvas, cx, 140, const Color(0xFF212121), isTiny: false);
    _drawCheekBlush(canvas, cx - 50, 138, cx + 50, 138, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐱 4. CAT (세련된 그레이 바디 + 뾰족 냥이 귀 + 우아한 꼬리 + 양볼 수염)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawCat(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final earInnerPaint = Paint()..color = const Color(0xFFCFD8DC)..style = PaintingStyle.fill;
    final whiskerPaint = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final legStrokePaint = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // ── 1. Elegant Cat Tail on the Right ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 65, 240)
      ..cubicTo(cx + 105, 245, cx + 115, 200, cx + 98, 175);
    canvas.drawPath(tailPath, tailPaint);

    // ── 2. Triangular Pointy Cat Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 62, 95);
    leftEarPath.lineTo(cx - 68, 48); // sharp tip
    leftEarPath.lineTo(cx - 24, 82);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);
    // Left Ear Inner
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 58, 90);
    leftEarInner.lineTo(cx - 63, 58);
    leftEarInner.lineTo(cx - 32, 82);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, earInnerPaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 24, 82);
    rightEarPath.lineTo(cx + 68, 48); // sharp tip
    rightEarPath.lineTo(cx + 62, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);
    // Right Ear Inner
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 32, 82);
    rightEarInner.lineTo(cx + 63, 58);
    rightEarInner.lineTo(cx + 58, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, earInnerPaint);

    // ── 3. Smooth Cylindrical Cat Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 4, 185 - (breathe * 0.5)), width: 160, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Two Neat Front Paws ──
    canvas.drawLine(Offset(cx - 24, 220), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 16, 220), Offset(cx + 16, 285), legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 16, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);

    // ── 5. Whiskers (3 lines on each side) ──
    // Left whiskers
    canvas.drawLine(Offset(cx - 38, 134), Offset(cx - 68, 128), whiskerPaint);
    canvas.drawLine(Offset(cx - 40, 140), Offset(cx - 72, 140), whiskerPaint);
    canvas.drawLine(Offset(cx - 38, 146), Offset(cx - 68, 152), whiskerPaint);
    // Right whiskers
    canvas.drawLine(Offset(cx + 30, 134), Offset(cx + 60, 128), whiskerPaint);
    canvas.drawLine(Offset(cx + 32, 140), Offset(cx + 64, 140), whiskerPaint);
    canvas.drawLine(Offset(cx + 30, 146), Offset(cx + 60, 152), whiskerPaint);

    // ── 6. Facial Features ──
    _drawBeadEyes(canvas, cx - 28, 125, cx + 20, 125, 6.5);
    _drawNordicNoseMouth(canvas, cx - 4, 138, const Color(0xFF37474F), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 140, cx + 36, 140, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🐼 5. PANDA (새하얀 둥근 바디 + 까만 판다 귀 & 눈가 패치 + 까만 팔다리)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawPanda(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final darkPaint = Paint()..color = const Color(0xFF263238)..style = PaintingStyle.fill;
    final eyePatchPaint = Paint()..color = const Color(0xFF37474F)..style = PaintingStyle.fill;

    // ── 1. Round Dark Charcoal Panda Ears ──
    canvas.drawCircle(Offset(cx - 68, 88), 24, darkPaint);
    canvas.drawCircle(Offset(cx + 68, 88), 24, darkPaint);

    // ── 2. Stout Black Feet ──
    final leftFoot = Path()
      ..moveTo(cx - 60, 280)
      ..cubicTo(cx - 75, 315, cx - 35, 318, cx - 30, 285)
      ..close();
    canvas.drawPath(leftFoot, darkPaint);

    final rightFoot = Path()
      ..moveTo(cx + 30, 285)
      ..cubicTo(cx + 35, 318, cx + 75, 315, cx + 60, 280)
      ..close();
    canvas.drawPath(rightFoot, darkPaint);

    // ── 3. Black Panda Side Arms ──
    final leftArm = Path()
      ..moveTo(cx - 75, 145)
      ..cubicTo(cx - 110, 160, cx - 112, 190, cx - 78, 195)
      ..close();
    canvas.drawPath(leftArm, darkPaint);

    final rightArm = Path()
      ..moveTo(cx + 75, 145)
      ..cubicTo(cx + 110, 160, cx + 112, 190, cx + 78, 195)
      ..close();
    canvas.drawPath(rightArm, darkPaint);

    // ── 4. Chunky Soft White Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, 185 - (breathe * 0.5)), width: 180, height: 210),
      const Radius.circular(85),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Soft contour outline for high visibility
    final contourPaint = Paint()
      ..color = const Color(0xFF78909C)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bodyRRect, contourPaint);

    // Subtle dark shoulder band
    final vestPaint = Paint()
      ..color = const Color(0xFF263238).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, 190), width: 155, height: 45), vestPaint);

    // ── 5. Iconic Tilted Panda Eye Patches ──
    // Left eye patch
    canvas.save();
    canvas.translate(cx - 36, 125);
    canvas.rotate(-0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 34, height: 26), eyePatchPaint);
    canvas.restore();

    // Right eye patch
    canvas.save();
    canvas.translate(cx + 36, 125);
    canvas.rotate(0.25);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 34, height: 26), eyePatchPaint);
    canvas.restore();

    // ── 6. Eyes, Nose & Blush ──
    _drawBeadEyes(canvas, cx - 36, 124, cx + 36, 124, 6.0);
    _drawNordicNoseMouth(canvas, cx, 142, const Color(0xFF212121), isTiny: true);
    _drawCheekBlush(canvas, cx - 55, 145, cx + 55, 145, isFever: isFever);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 🦊 6. FOX (따뜻한 코랄 오렌지 바디 + 뾰족 귀 & 초코 팁 + 풍성한 하얀 꼬리 끝)
  // ──────────────────────────────────────────────────────────────────────────
  void _drawFox(Canvas canvas, Size size, double cx, double cy, double breathe) {
    final bodyPaint = Paint()..color = patient.bodyColor..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = const Color(0xFFFFF8E1)..style = PaintingStyle.fill;
    final darkTipPaint = Paint()..color = const Color(0xFF3E2723)..style = PaintingStyle.fill;
    final legStrokePaint = Paint()
      ..color = const Color(0xFFBF360C)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    // ── 1. Big Bushy Fox Tail with White Tip on the Right ──
    final tailPaint = Paint()
      ..color = patient.bodyColor
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tailPath = Path()
      ..moveTo(cx + 60, 240)
      ..cubicTo(cx + 115, 245, cx + 125, 185, cx + 98, 160);
    canvas.drawPath(tailPath, tailPaint);

    // Bushy white tail tip
    final tipPaint = Paint()
      ..color = const Color(0xFFFFF8E1)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final tipPath = Path()
      ..moveTo(cx + 110, 185)
      ..quadraticBezierTo(cx + 108, 170, cx + 98, 160);
    canvas.drawPath(tipPath, tipPaint);

    // ── 2. Triangular Pointed Fox Ears ──
    // Left Ear
    final leftEarPath = Path();
    leftEarPath.moveTo(cx - 64, 95);
    leftEarPath.lineTo(cx - 72, 42); // sharp tip
    leftEarPath.lineTo(cx - 22, 80);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, bodyPaint);

    // Left Ear Dark Tip
    final leftTip = Path();
    leftTip.moveTo(cx - 68, 62);
    leftTip.lineTo(cx - 72, 42);
    leftTip.lineTo(cx - 52, 58);
    leftTip.close();
    canvas.drawPath(leftTip, darkTipPaint);

    // Left Ear Inner Cream
    final leftEarInner = Path();
    leftEarInner.moveTo(cx - 60, 90);
    leftEarInner.lineTo(cx - 65, 62);
    leftEarInner.lineTo(cx - 30, 80);
    leftEarInner.close();
    canvas.drawPath(leftEarInner, whitePaint);

    // Right Ear
    final rightEarPath = Path();
    rightEarPath.moveTo(cx + 22, 80);
    rightEarPath.lineTo(cx + 72, 42); // sharp tip
    rightEarPath.lineTo(cx + 64, 95);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, bodyPaint);

    // Right Ear Dark Tip
    final rightTip = Path();
    rightTip.moveTo(cx + 52, 58);
    rightTip.lineTo(cx + 72, 42);
    rightTip.lineTo(cx + 68, 62);
    rightTip.close();
    canvas.drawPath(rightTip, darkTipPaint);

    // Right Ear Inner Cream
    final rightEarInner = Path();
    rightEarInner.moveTo(cx + 30, 80);
    rightEarInner.lineTo(cx + 65, 62);
    rightEarInner.lineTo(cx + 60, 90);
    rightEarInner.close();
    canvas.drawPath(rightEarInner, whitePaint);

    // ── 3. Smooth Cylindrical Fox Body ──
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 2, 185 - (breathe * 0.5)), width: 165, height: 205),
      const Radius.circular(75),
    );
    canvas.drawRRect(bodyRRect, bodyPaint);

    // ── 4. Fluffy White Muzzle / Bib ──
    final bibPath = Path();
    bibPath.moveTo(cx - 2, 140);
    bibPath.quadraticBezierTo(cx - 38, 148, cx - 25, 175);
    bibPath.quadraticBezierTo(cx - 2, 205, cx + 25, 175);
    bibPath.quadraticBezierTo(cx + 38, 148, cx - 2, 140);
    bibPath.close();
    canvas.drawPath(bibPath, whitePaint);

    // ── 5. Front Paws ──
    canvas.drawLine(Offset(cx - 24, 220), Offset(cx - 24, 285), legStrokePaint);
    canvas.drawLine(Offset(cx + 18, 220), Offset(cx + 18, 285), legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 24, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 18, 285), width: 18, height: 14), 0, pi, false, legStrokePaint);

    // ── 6. Facial Features ──
    _drawBeadEyes(canvas, cx - 28, 124, cx + 24, 124, 6.5);
    _drawNordicNoseMouth(canvas, cx - 2, 138, const Color(0xFF212121), isTiny: true);
    _drawCheekBlush(canvas, cx - 44, 142, cx + 40, 142, isFever: isFever);
  }

  // ── Helper: Cute Glossy Bead Eyes (초롱초롱 구슬 눈) ──────────────────────
  void _drawBeadEyes(Canvas canvas, double leftX, double leftY, double rightX, double rightY, double radius) {
    if (isHappy) {
      final happyPaint = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // Left happy eye
      final leftPath = Path()..moveTo(leftX - radius, leftY + 2)..quadraticBezierTo(leftX, leftY - radius, leftX + radius, leftY + 2);
      canvas.drawPath(leftPath, happyPaint);
      // Right happy eye
      final rightPath = Path()..moveTo(rightX - radius, rightY + 2)..quadraticBezierTo(rightX, rightY - radius, rightX + radius, rightY + 2);
      canvas.drawPath(rightPath, happyPaint);
      return;
    }

    final eyePaint = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final shinePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Left Eye
    canvas.drawCircle(Offset(leftX, leftY), radius, eyePaint);
    canvas.drawCircle(Offset(leftX - (radius * 0.3), leftY - (radius * 0.3)), radius * 0.4, shinePaint);
    canvas.drawCircle(Offset(leftX + (radius * 0.35), leftY + (radius * 0.35)), radius * 0.2, shinePaint);

    // Right Eye
    canvas.drawCircle(Offset(rightX, rightY), radius, eyePaint);
    canvas.drawCircle(Offset(rightX - (radius * 0.3), rightY - (radius * 0.3)), radius * 0.4, shinePaint);
    canvas.drawCircle(Offset(rightX + (radius * 0.35), rightY + (radius * 0.35)), radius * 0.2, shinePaint);
  }

  // ── Helper: Nordic Dainty Nose & 'ㅅ' Mouth (심플 앙증 코 & 입) ──────────
  void _drawNordicNoseMouth(Canvas canvas, double cx, double cy, Color color, {required bool isTiny}) {
    if (isOpenMouth) {
      // Big open mouth for syrup
      final openMouthPaint = Paint()..color = const Color(0xFF880E4F)..style = PaintingStyle.fill;
      final mouthPath = Path()
        ..moveTo(cx - 10, cy + 2)
        ..quadraticBezierTo(cx, cy + 18, cx + 10, cy + 2)
        ..close();
      canvas.drawPath(mouthPath, openMouthPaint);
      final tonguePaint = Paint()..color = const Color(0xFFFF4081)..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 10), width: 12, height: 7), tonguePaint);
      return;
    }

    final nosePaint = Paint()..color = color..style = PaintingStyle.fill;
    final mouthPaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final nw = isTiny ? 7.0 : 11.0;
    final nh = isTiny ? 5.0 : 7.5;

    // Small rounded nose
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: nw * 2, height: nh * 2), Radius.circular(nh)),
      nosePaint,
    );

    // 'ㅅ' mouth
    final mouthY = cy + nh;
    canvas.drawLine(Offset(cx, mouthY), Offset(cx, mouthY + 3.5), mouthPaint);

    final mouthPath = Path();
    if (isHappy) {
      mouthPath.moveTo(cx - 7, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx - 3.5, mouthY + 8, cx, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx + 3.5, mouthY + 8, cx + 7, mouthY + 3.5);
    } else if (isSad) {
      mouthPath.moveTo(cx - 6, mouthY + 7);
      mouthPath.quadraticBezierTo(cx - 3, mouthY + 3, cx, mouthY + 5.5);
      mouthPath.quadraticBezierTo(cx + 3, mouthY + 3, cx + 6, mouthY + 7);
    } else {
      mouthPath.moveTo(cx - 6, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx - 3, mouthY + 7, cx, mouthY + 3.5);
      mouthPath.quadraticBezierTo(cx + 3, mouthY + 7, cx + 6, mouthY + 3.5);
    }
    canvas.drawPath(mouthPath, mouthPaint);
  }

  // ── Helper: Soft Cheek Blush (발그레 볼터치) ──────────────────────────────
  void _drawCheekBlush(Canvas canvas, double leftX, double leftY, double rightX, double rightY, {required bool isFever}) {
    final blushColor = (isFever ? const Color(0xFFFF5252) : const Color(0xFFFF8DA1)).withValues(alpha: isFever ? 0.75 : 0.45);
    final blushPaint = Paint()..color = blushColor..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(center: Offset(leftX, leftY), width: 22, height: 14), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(rightX, rightY), width: 22, height: 14), blushPaint);
  }

  @override
  bool shouldRepaint(covariant _NordicAnimalIllustrationPainter oldDelegate) =>
      oldDelegate.patient.id != patient.id ||
      oldDelegate.idleProgress != idleProgress ||
      oldDelegate.isHappy != isHappy ||
      oldDelegate.isFever != isFever ||
      oldDelegate.isSad != isSad ||
      oldDelegate.isOpenMouth != isOpenMouth;
}

// ── Nordic Cartoon Thorn Painter (아기자기한 동화풍 가시) ───────────────────

class _NordicThornPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft stylized cartoon wooden thorn
    final thornPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(w / 2, 0); // Sharp tip
    path.quadraticBezierTo(w * 0.75, h * 0.6, w * 0.85, h);
    path.quadraticBezierTo(w / 2, h * 0.85, w * 0.15, h);
    path.quadraticBezierTo(w * 0.25, h * 0.6, w / 2, 0);
    path.close();

    canvas.drawPath(path, thornPaint);
    canvas.drawPath(path, strokePaint);

    // Cute tiny leaf shoot on the side
    final leafPaint = Paint()..color = const Color(0xFF81C784)..style = PaintingStyle.fill;
    final leafPath = Path();
    leafPath.moveTo(w * 0.7, h * 0.5);
    leafPath.quadraticBezierTo(w * 1.1, h * 0.4, w * 1.15, h * 0.65);
    leafPath.quadraticBezierTo(w * 0.85, h * 0.7, w * 0.7, h * 0.5);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Nordic Cartoon Scratch Painter (동화책 느낌의 깔끔한 상처) ───────────────

class _NordicScratchPainter extends CustomPainter {
  final double healProgress;
  final bool isHighlight;

  _NordicScratchPainter({required this.healProgress, required this.isHighlight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final opacity = (1.0 - healProgress).clamp(0.0, 1.0);

    if (opacity <= 0) return;

    // Soft warm blush under scratch
    final glowPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withValues(alpha: 0.35 * opacity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.1, w * 0.9, h * 0.8), glowPaint);

    // 3 Cute cartoon scratch arcs
    final scratchPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(w * 0.2, h * 0.35)
      ..quadraticBezierTo(w * 0.5, h * 0.25, w * 0.8, h * 0.4);
    canvas.drawPath(path1, scratchPaint);

    final path2 = Path()
      ..moveTo(w * 0.25, h * 0.55)
      ..quadraticBezierTo(w * 0.55, h * 0.48, w * 0.75, h * 0.6);
    canvas.drawPath(path2, scratchPaint);

    final path3 = Path()
      ..moveTo(w * 0.35, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.7, w * 0.65, h * 0.78);
    canvas.drawPath(path3, scratchPaint);

    // Soothing blue ointment gel when healing
    if (healProgress > 0.0) {
      final gelPaint = Paint()
        ..color = const Color(0xFF80DEEA).withValues(alpha: 0.55 * healProgress)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromLTWH(w * 0.15, h * 0.2, w * 0.7, h * 0.6), gelPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NordicScratchPainter oldDelegate) =>
      oldDelegate.healProgress != healProgress || oldDelegate.isHighlight != isHighlight;
}

