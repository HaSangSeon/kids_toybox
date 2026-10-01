part of '../pet_hospital_game.dart';

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
      darkColor: const Color(0xFF0097A7), // Deep vibrant teal border
      faceColor: const Color(0xFFE0F7FA),
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
      darkColor: const Color(0xFF263238), // Bold dark charcoal black
      faceColor: const Color(0xFFECEFF1),
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
    _PatientData(
      id: 'tiger',
      name: '아기 호랑이 호치',
      emoji: '🐯',
      title: '정글 덤불에 발이 콕콕!',
      symptom: '정글에서 신나게 뛰놀다 가시가 콕콕 박히고 열이 나요! 어흥~ 🐯',
      bodyColor: const Color(0xFFFF9800), // Vibrant tiger orange
      darkColor: const Color(0xFFE65100), // Deep orange border
      faceColor: const Color(0xFFFFE0B2),
      bellyColor: const Color(0xFFFFF8E1),
      earColor: const Color(0xFFE65100),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.6,
      thorns: [
        _ThornItem(id: 0, label: '오른쪽 귀', pos: const Offset(228, 88), angle: 0.3),
        _ThornItem(id: 1, label: '왼쪽 앞발', pos: const Offset(115, 260), angle: -0.2),
        _ThornItem(id: 2, label: '용맹한 꼬리', pos: const Offset(260, 190), angle: 0.35),
      ],
      wounds: [
        _WoundItem(id: 0, label: '통통한 배', pos: const Offset(160, 205), width: 54, height: 32),
        _WoundItem(id: 1, label: '왼쪽 볼', pos: const Offset(105, 140), width: 44, height: 28),
      ],
      thankMessage: '호치 발이 하나도 안 아파요! 씩씩하게 어흥~ 고마워요! 🐯🧡',
    ),
    _PatientData(
      id: 'penguin',
      name: '아기 펭귄 핑구',
      emoji: '🐧',
      title: '얼음 미끄럼틀 타다 쿵!',
      symptom: '얼음 미끄럼틀을 타다 쿵 넘어져서 날개가 긁혔어요! 뒤뚱뒤뚱~ 🐧',
      bodyColor: const Color(0xFF263238), // Dark tuxedo blue-charcoal
      darkColor: const Color(0xFF000A12), // Jet black border
      faceColor: const Color(0xFFECEFF1),
      bellyColor: const Color(0xFFFFFFFF),
      earColor: const Color(0xFFFFB300),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.8,
      thorns: [
        _ThornItem(id: 0, label: '오른쪽 날개', pos: const Offset(255, 170), angle: 0.3),
        _ThornItem(id: 1, label: '왼쪽 발', pos: const Offset(125, 275), angle: -0.2),
      ],
      wounds: [
        _WoundItem(id: 0, label: '둥근 배', pos: const Offset(160, 200), width: 54, height: 32),
        _WoundItem(id: 1, label: '부리 옆', pos: const Offset(195, 135), width: 44, height: 28),
      ],
      thankMessage: '얼음처럼 시원하고 날개가 가벼워요! 뒤뚱뒤뚱 춤출게요~ 🐧❄️',
    ),
    _PatientData(
      id: 'lion',
      name: '아기 사자 레오',
      emoji: '🦁',
      title: '가시덤불에 걸렸어요!',
      symptom: '사바나 초원에서 달리기하다 가시덤불에 걸려 열이 나요! 크앙~ 🦁',
      bodyColor: const Color(0xFFFFB74D), // Golden lion fur
      darkColor: const Color(0xFFBF360C), // Deep terracotta brown
      faceColor: const Color(0xFFFFF3E0),
      bellyColor: const Color(0xFFFFE082),
      earColor: const Color(0xFFD84315),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.5,
      thorns: [
        _ThornItem(id: 0, label: '풍성한 갈기', pos: const Offset(245, 95), angle: 0.3),
        _ThornItem(id: 1, label: '꼬리 술', pos: const Offset(65, 200), angle: -0.35),
        _ThornItem(id: 2, label: '오른발', pos: const Offset(195, 265), angle: 0.2),
      ],
      wounds: [
        _WoundItem(id: 0, label: '가슴', pos: const Offset(155, 195), width: 54, height: 32),
        _WoundItem(id: 1, label: '오른쪽 볼', pos: const Offset(205, 140), width: 44, height: 28),
      ],
      thankMessage: '갈기도 찰랑찰랑! 용감한 백수의 왕 레오 출동해요! 🦁👑',
    ),
    _PatientData(
      id: 'koala',
      name: '아기 코알라 코코',
      emoji: '🐨',
      title: '나무에서 졸다가 쿵!',
      symptom: '유칼립투스 나무에서 졸다가 쿵 떨어져서 상처가 났어요! 쿨쿨~ 🐨',
      bodyColor: const Color(0xFF90A4AE), // Soft eucalyptus gray
      darkColor: const Color(0xFF37474F), // Slate gray border
      faceColor: const Color(0xFFECEFF1),
      bellyColor: const Color(0xFFCFD8DC),
      earColor: const Color(0xFF455A64),
      eyeColor: const Color(0xFF212121),
      initialTemp: 38.4,
      thorns: [
        _ThornItem(id: 0, label: '복슬복슬 귀', pos: const Offset(105, 75), angle: -0.3),
        _ThornItem(id: 1, label: '오른손', pos: const Offset(245, 175), angle: 0.25),
      ],
      wounds: [
        _WoundItem(id: 0, label: '둥근 배', pos: const Offset(160, 205), width: 54, height: 32),
        _WoundItem(id: 1, label: '왼쪽 뺨', pos: const Offset(115, 140), width: 44, height: 28),
      ],
      thankMessage: '초록 잎사귀처럼 상쾌해요! 꼬옥 안아줄게요 고마워요! 🐨🌿',
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

