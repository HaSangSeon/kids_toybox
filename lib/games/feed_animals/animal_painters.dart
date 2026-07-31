import 'dart:math';
import 'package:flutter/material.dart';

// ───────────────────────────────────────────────────────────────
//  동물별 얼굴 이모지 + 자연스러운 고개 까딱 / 흔들림 애니메이션
//  카드 배경색은 각 동물별로 따로 정의 (토끼 흰색 배경 문제 해결)
// ───────────────────────────────────────────────────────────────

/// 동물 이름 → 카드 배경 그라디언트 색상 (동물 털 색에 어울리는 파스텔)
LinearGradient animalCardGradient(String animalName, bool isFed) {
  if (isFed) {
    return const LinearGradient(
      colors: [Color(0xFFE8FFE8), Color(0xFFB9F6CA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  final Map<String, List<Color>> colorMap = {
    'dog':      [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], // 따뜻한 크림
    'cat':      [Color(0xFFFFF9C4), Color(0xFFFFF176)], // 황금 노랑
    'rabbit':   [Color(0xFFE8EAF6), Color(0xFFC5CAE9)], // 연보라 (흰 토끼 대비)
    'bear':     [Color(0xFFEFEBE9), Color(0xFFD7CCC8)], // 따뜻한 갈색 연
    'monkey':   [Color(0xFFFFF8E1), Color(0xFFFFECB3)], // 연황토
    'panda':    [Color(0xFFF5F5F5), Color(0xFFE0E0E0)], // 연회색
    'fox':      [Color(0xFFFBE9E7), Color(0xFFFFCCBC)], // 주황 연
    'lion':     [Color(0xFFFFF8E1), Color(0xFFFFECB3)], // 황금 연
    'elephant': [Color(0xFFECEFF1), Color(0xFFCFD8DC)], // 파란 회색
    'frog':     [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // 연초록
    'parrot':   [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // 연파랑
    'penguin':  [Color(0xFFE8EAF6), Color(0xFFC5CAE9)], // 파란 회색
    'mouse':    [Color(0xFFFCE4EC), Color(0xFFF8BBD9)], // 연핑크
    'squirrel': [Color(0xFFFBE9E7), Color(0xFFFFCCBC)], // 연갈색
    'cow':      [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // 연파랑
    'pig':      [Color(0xFFFCE4EC), Color(0xFFF8BBD9)], // 핑크
    'giraffe':  [Color(0xFFFFFDE7), Color(0xFFFFF9C4)], // 연노랑
    'hippo':    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)], // 연보라
    'hedgehog': [Color(0xFFEFEBE9), Color(0xFFD7CCC8)], // 갈색 연
    'chick':    [Color(0xFFFFFDE7), Color(0xFFFFF9C4)], // 병아리 노랑
  };
  final colors = colorMap[animalName] ?? [Color(0xFFF3E5F5), Color(0xFFE1BEE7)];
  return LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// 동물 이름 → 얼굴 이모지
String animalFaceEmoji(String animalName, String fallbackEmoji) {
  const faceMap = {
    'dog':      '🐶',
    'cat':      '🐱',
    'rabbit':   '🐰',
    'bear':     '🐻',
    'monkey':   '🐵',
    'panda':    '🐼',
    'fox':      '🦊',
    'lion':     '🦁',
    'elephant': '🐘',
    'frog':     '🐸',
    'parrot':   '🦜',
    'penguin':  '🐧',
    'mouse':    '🐭',
    'squirrel': '🐿️',
    'cow':      '🐮',
    'pig':      '🐷',
    'giraffe':  '🦒',
    'hippo':    '🦛',
    'hedgehog': '🦔',
    'chick':    '🐥',
  };
  return faceMap[animalName] ?? fallbackEmoji;
}

/// 동물별 자연스러운 얼굴 애니메이션 위젯
Widget buildAnimatedAnimal(
  String animalName,
  double size,
  Animation<double> anim, {
  bool isHovering = false,
  bool isFed = false,
}) {
  return AnimatedBuilder(
    animation: anim,
    builder: (context, child) {
      final t = anim.value; // 0.0 ~ 1.0 looping

      // 동물별 개성 있는 움직임
      final animData = _getAnimalAnimData(animalName, t, isHovering, isFed);

      return Transform.translate(
        offset: animData.translate,
        child: Transform.rotate(
          angle: animData.rotation,
          child: Transform.scale(
            scale: animData.scale,
            child: Text(
              animalFaceEmoji(animalName, '🐾'),
              style: TextStyle(
                fontSize: size,
                // 이모지 그림자로 카드 배경과 분리감 줌
                shadows: const [
                  Shadow(
                    offset: Offset(1, 2),
                    blurRadius: 4,
                    color: Color(0x33000000),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _AnimData {
  final Offset translate;
  final double rotation;
  final double scale;

  _AnimData({
    this.translate = Offset.zero,
    this.rotation = 0.0,
    this.scale = 1.0,
  });
}

_AnimData _getAnimalAnimData(String name, double t, bool isHovering, bool isFed) {
  final phase = t * 2 * pi;
  final slowSin = sin(phase);          // 느린 파동
  final fastSin = sin(phase * 3);      // 빠른 파동
  final bobAbs = sin(phase).abs();     // 통통 양수 파동

  // fed: 기쁨으로 통통 점프
  if (isFed) {
    return _AnimData(
      translate: Offset(0, -bobAbs * 4),
      rotation: slowSin * 0.08,
      scale: 1.05 + bobAbs * 0.06,
    );
  }

  // hovering: 두근두근 기대감 (크게 + 살짝 떨림)
  if (isHovering) {
    return _AnimData(
      translate: Offset(fastSin * 1.5, -2),
      rotation: fastSin * 0.06,
      scale: 1.12,
    );
  }

  // 동물별 고유 대기 애니메이션
  switch (name) {
    case 'dog': // 강아지: 신나게 고개 흔들흔들
      return _AnimData(
        translate: Offset(0, slowSin * 2.5),
        rotation: fastSin * 0.1, // 빠르게 살랑살랑
        scale: 1.0,
      );

    case 'cat': // 고양이: 도도하게 느릿느릿 고개 기울기
      return _AnimData(
        translate: Offset(0, slowSin * 1.5),
        rotation: slowSin * 0.08,
        scale: 1.0,
      );

    case 'rabbit': // 토끼: 위아래로 쫑긋쫑긋
      return _AnimData(
        translate: Offset(0, slowSin * 3.0),
        rotation: slowSin * 0.05,
        scale: 1.0 + bobAbs * 0.04,
      );

    case 'bear': // 곰: 좌우로 느릿하게 흔들기
      return _AnimData(
        translate: Offset(slowSin * 2.5, 0),
        rotation: slowSin * 0.07,
        scale: 1.0,
      );

    case 'monkey': // 원숭이: 신나게 위아래 방방
      return _AnimData(
        translate: Offset(fastSin * 1.5, -bobAbs * 4),
        rotation: fastSin * 0.1,
        scale: 1.0,
      );

    case 'panda': // 판다: 졸린듯 느릿하게 고개 숙이기
      return _AnimData(
        translate: Offset(0, slowSin * 1.5),
        rotation: slowSin * 0.12,
        scale: 1.0,
      );

    case 'fox': // 여우: 영리하게 고개 살짝 기울기
      return _AnimData(
        translate: Offset(0, slowSin * 2),
        rotation: slowSin * 0.1,
        scale: 1.0,
      );

    case 'lion': // 사자: 위엄있게 느린 흔들기
      return _AnimData(
        translate: Offset(slowSin * 2, 0),
        rotation: slowSin * 0.06,
        scale: 1.0 + slowSin.abs() * 0.02,
      );

    case 'elephant': // 코끼리: 무겁게 좌우로 느릿
      return _AnimData(
        translate: Offset(slowSin * 3, slowSin * 1.5),
        rotation: slowSin * 0.06,
        scale: 1.0,
      );

    case 'frog': // 개구리: 펄쩍 점프 (bobAbs)
      return _AnimData(
        translate: Offset(0, -bobAbs * 5),
        rotation: 0,
        scale: 1.0 + (1 - bobAbs) * 0.04,
      );

    case 'penguin': // 펭귄: 뒤뚱뒤뚱 좌우
      return _AnimData(
        translate: Offset(slowSin * 3, 0),
        rotation: slowSin * 0.12,
        scale: 1.0,
      );

    case 'mouse': // 쥐: 작고 빠르게 두리번
      return _AnimData(
        translate: Offset(fastSin * 2, slowSin * 1.5),
        rotation: fastSin * 0.08,
        scale: 1.0,
      );

    case 'pig': // 돼지: 통통하게 위아래 흔들기
      return _AnimData(
        translate: Offset(0, bobAbs * 2.5),
        rotation: slowSin * 0.05,
        scale: 1.0 + bobAbs * 0.03,
      );

    case 'giraffe': // 기린: 긴 목으로 좌우 흔들
      return _AnimData(
        translate: Offset(slowSin * 3.5, 0),
        rotation: slowSin * 0.09,
        scale: 1.0,
      );

    case 'chick': // 병아리: 빠르게 위아래 쫑알쫑알
      return _AnimData(
        translate: Offset(0, -bobAbs * 4),
        rotation: fastSin * 0.08,
        scale: 1.0,
      );

    default:
      return _AnimData(
        translate: Offset(0, slowSin * 2),
        rotation: slowSin * 0.06,
        scale: 1.0,
      );
  }
}
