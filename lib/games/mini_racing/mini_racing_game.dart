import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/data/player_data_manager.dart';
import 'package:audioplayers/audioplayers.dart';

// ── 슈퍼카 스킨 ──
enum SupercarSkin {
  ferrari('페라리 🏎️', 'Ferrari Red GT', Color(0xFFE50914), Color(0xFF111111), '🛡️'),
  bmw('비엠더블유 ⚡', 'BMW M Sport', Color(0xFF0066B1), Colors.white, '🔵'),
  benz('벤츠 ⭐', 'Benz Silver GT', Color(0xFFD0D5DD), Color(0xFF333333), '⭐'),
  lambo('람보르기니 🔥', 'Lambo Yellow', Color(0xFFFFD600), Color(0xFF1A1A1A), '🐂'),
  porsche('포르쉐 🖤', 'Porsche Stealth', Color(0xFF212121), Color(0xFFFFD700), '👑');

  final String name;
  final String title;
  final Color mainColor;
  final Color accentColor;
  final String badgeEmoji;

  const SupercarSkin(this.name, this.title, this.mainColor, this.accentColor, this.badgeEmoji);
}

class SelectedCar {
  final SupercarSkin? supercar;
  final String? emojiToy;

  SelectedCar({this.supercar, this.emojiToy});

  bool get isSupercar => supercar != null;
  bool get isEmoji => emojiToy != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedCar &&
          runtimeType == other.runtimeType &&
          supercar == other.supercar &&
          emojiToy == other.emojiToy;

  @override
  int get hashCode => supercar.hashCode ^ emojiToy.hashCode;
}

class SupercarPainter extends CustomPainter {
  final SupercarSkin skin;
  SupercarPainter({required this.skin});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Drop Shadow under the car
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 6, w - 8, h - 4),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    // 2. 4 Performance Racing Tires (Black rubber with silver rims)
    final tirePaint = Paint()..color = const Color(0xFF1A1A1A);
    const tireW = 9.0;
    const tireH = 20.0;
    
    // Front tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, h * 0.18, tireW, tireH), const Radius.circular(4)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - tireW - 1, h * 0.18, tireW, tireH), const Radius.circular(4)), tirePaint);
    // Rear tires
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, h * 0.70, tireW, tireH), const Radius.circular(4)), tirePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - tireW - 1, h * 0.70, tireW, tireH), const Radius.circular(4)), tirePaint);

    // 3. Aerodynamic Brand Silhouette Body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          skin.mainColor,
          Color.lerp(skin.mainColor, Colors.white, 0.25)!,
          skin.mainColor,
          Color.lerp(skin.mainColor, Colors.black, 0.3)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(4, 0, w - 8, h));

    final bodyPath = Path();
    if (skin == SupercarSkin.lambo) {
      // Angular stealth wedge shape
      bodyPath.moveTo(w * 0.5, 0);
      bodyPath.lineTo(w - 3, h * 0.16);
      bodyPath.lineTo(w - 2, h * 0.45);
      bodyPath.lineTo(w - 6, h * 0.85);
      bodyPath.lineTo(w - 2, h);
      bodyPath.lineTo(2, h);
      bodyPath.lineTo(6, h * 0.85);
      bodyPath.lineTo(2, h * 0.45);
      bodyPath.lineTo(3, h * 0.16);
      bodyPath.close();
    } else {
      // Curve aerodynamic sports body
      bodyPath.moveTo(w * 0.5, 0);
      bodyPath.cubicTo(w * 0.85, 2, w - 5, h * 0.12, w - 5, h * 0.22);
      bodyPath.cubicTo(w - 3, h * 0.45, w - 4, h * 0.65, w - 5, h * 0.85);
      bodyPath.quadraticBezierTo(w - 4, h, w * 0.75, h);
      bodyPath.lineTo(w * 0.25, h);
      bodyPath.quadraticBezierTo(4, h, 5, h * 0.85);
      bodyPath.cubicTo(4, h * 0.65, 3, h * 0.45, 5, h * 0.22);
      bodyPath.cubicTo(5, h * 0.12, w * 0.15, 2, w * 0.5, 0);
      bodyPath.close();
    }

    canvas.drawPath(bodyPath, bodyPaint);

    // Body Outline Highlight
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(bodyPath, outlinePaint);

    // 4. Brand Specific Front Grille & Racing Stripes
    if (skin == SupercarSkin.bmw) {
      // BMW M Racing Stripes
      final stripe1 = Paint()..color = const Color(0xFF0099FF);
      final stripe2 = Paint()..color = const Color(0xFF003399);
      final stripe3 = Paint()..color = const Color(0xFFFF0000);
      canvas.drawRect(Rect.fromLTWH(w * 0.38, 4, 3, h - 12), stripe1);
      canvas.drawRect(Rect.fromLTWH(w * 0.43, 4, 3, h - 12), stripe2);
      canvas.drawRect(Rect.fromLTWH(w * 0.48, 4, 3, h - 12), stripe3);

      // BMW Signature Twin Kidney Grille (쌍둥이 키드니 그릴)
      final grilleBorder = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;
      final grilleBg = Paint()..color = Colors.black;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 2, 10, 6), const Radius.circular(3)), grilleBg);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, 2, 10, 6), const Radius.circular(3)), grilleBorder);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, 2, 10, 6), const Radius.circular(3)), grilleBg);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, 2, 10, 6), const Radius.circular(3)), grilleBorder);

    } else if (skin == SupercarSkin.benz) {
      // Mercedes Panamericana Chrome Grille
      final grilleBg = Paint()..color = Colors.black;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, 2, w * 0.44, 6), const Radius.circular(3)), grilleBg);
      final chromeLine = Paint()..color = const Color(0xFFE0E0E0)..strokeWidth = 1.2;
      for (double x = w * 0.32; x <= w * 0.68; x += 3.5) {
        canvas.drawLine(Offset(x, 2), Offset(x, 8), chromeLine);
      }

    } else if (skin == SupercarSkin.ferrari) {
      // Ferrari Carbon Hood Vent Slit
      final stripePaint = Paint()..color = skin.accentColor;
      canvas.drawRect(Rect.fromLTWH(w * 0.45, 4, w * 0.10, h - 12), stripePaint);

      final ventPaint = Paint()..color = const Color(0xFF151515);
      final ventPath = Path();
      ventPath.moveTo(w * 0.35, 8);
      ventPath.lineTo(w * 0.65, 8);
      ventPath.lineTo(w * 0.58, 14);
      ventPath.lineTo(w * 0.42, 14);
      ventPath.close();
      canvas.drawPath(ventPath, ventPaint);

    } else if (skin == SupercarSkin.porsche) {
      // Porsche GT Stripe
      final stripePaint = Paint()..color = skin.accentColor;
      canvas.drawRect(Rect.fromLTWH(w * 0.44, 4, w * 0.12, h - 12), stripePaint);
    }

    // 5. Curved Windshield & Glass Cabin (Tinted glass)
    final glassPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF152238),
          const Color(0xFF2B3A4A),
          const Color(0xFF101820),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(10, h * 0.25, w - 20, h * 0.45));

    final cabinPath = Path();
    cabinPath.moveTo(w * 0.25, h * 0.26);
    cabinPath.quadraticBezierTo(w * 0.5, h * 0.23, w * 0.75, h * 0.26);
    cabinPath.lineTo(w * 0.82, h * 0.65);
    cabinPath.quadraticBezierTo(w * 0.5, h * 0.68, w * 0.18, h * 0.65);
    cabinPath.close();

    canvas.drawPath(cabinPath, glassPaint);

    // Glass Reflection Shininess
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(w * 0.3, h * 0.3), Offset(w * 0.45, h * 0.42), shinePaint);

    // Side Mirrors
    final mirrorPaint = Paint()..color = skin.mainColor;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1, h * 0.28, 5, 9), const Radius.circular(2)), mirrorPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 6, h * 0.28, 5, 9), const Radius.circular(2)), mirrorPaint);

    // 6. Brand Emblem Badge on Hood
    final textPainter = TextPainter(
      text: TextSpan(text: skin.badgeEmoji, style: const TextStyle(fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w * 0.5 - 5, 14));

    // 7. Headlights (Brand Specific)
    final headlightPaint = Paint()
      ..color = const Color(0xFFE0F7FA)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    if (skin == SupercarSkin.porsche) {
      // Porsche Oval Frog-Eye Headlights
      canvas.drawOval(Rect.fromLTWH(8, 4, 10, 8), headlightPaint);
      canvas.drawOval(Rect.fromLTWH(w - 18, 4, 10, 8), headlightPaint);
    } else {
      // Standard LED Lights
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(9, 4, 9, 5), const Radius.circular(3)), headlightPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w - 18, 4, 9, 5), const Radius.circular(3)), headlightPaint);
    }

    // 8. Rear Taillights & GT Spoiler Wing
    final tailLightPaint = Paint()..color = const Color(0xFFFF1744);
    if (skin == SupercarSkin.porsche) {
      // Porsche Continuous LED Rear Lightbar
      canvas.drawRect(Rect.fromLTWH(4, h - 5, w - 8, 3), tailLightPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(8, h - 4, 10, 3), tailLightPaint);
      canvas.drawRect(Rect.fromLTWH(w - 18, h - 4, 10, 3), tailLightPaint);
    }

    // GT Wing Spoiler
    final spoilerPaint = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, h - 7, w - 8, 4), const Radius.circular(2)), spoilerPaint);
  }

  @override
  bool shouldRepaint(covariant SupercarPainter oldDelegate) => oldDelegate.skin != skin;
}

// ── 아이템 / 장애물 타입 ──
enum RacingEntityType {
  star,       // 일반 별 (점수)
  diamond,    // 다이아몬드 (보너스 점수)
  heart,      // 하트 (생명 회복)
  shield,     // 보호막 (장애물 1회 방어)
  rock,       // 바위 (장애물)
  cone,       // 콘 (장애물)
  banana,     // 바나나 (장애물 - 회전 효과)
}

// ── 엔티티 클래스 ──
class RacingEntity {
  final String id;
  double x;
  double y;
  final double width;
  final double height;
  final RacingEntityType type;
  final String emoji;
  bool isCollected;
  double rotation; // 회전 각도

  RacingEntity({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.type,
    required this.emoji,
    this.isCollected = false,
    this.rotation = 0.0,
  });

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: width, height: height);
}

// ── 길가 데코레이션 ──
class RoadsideDecor {
  final String id;
  final double x; // 도로 중심 기준 상대 위치 (-1.0: 왼쪽 풀밭, 1.0: 오른쪽 풀밭)
  double y;
  final String emoji;
  final double scale;

  RoadsideDecor({
    required this.id,
    required this.x,
    required this.y,
    required this.emoji,
    required this.scale,
  });
}

// ── 파티클 ──
class Particle {
  double x, y, vx, vy, life, size;
  Color color;
  Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color,
    required this.life,
    required this.size,
  });
}

// ── 팝업 텍스트 ──
class ScorePopup {
  double x, y, life;
  String text;
  Color color;
  ScorePopup({required this.x, required this.y, required this.text, required this.color, required this.life});
}

// ── 테마 설정 ──
class LevelTheme {
  final String name;
  final Color grassColor;
  final Color roadColor;
  final Color lineColor;
  final List<String> decorEmojis;

  const LevelTheme({
    required this.name,
    required this.grassColor,
    required this.roadColor,
    required this.lineColor,
    required this.decorEmojis,
  });
}

const _themes = [
  LevelTheme(
    name: '초록 숲속 길 🌲',
    grassColor: Color(0xFF81C784),
    roadColor: Color(0xFF546E7A),
    lineColor: Color(0xFFFFEE58),
    decorEmojis: ['🌲', '🌳', '🌸', '🌼', '🍄'],
  ),
  LevelTheme(
    name: '모래 사막 길 🏜️',
    grassColor: Color(0xFFFFD54F),
    roadColor: Color(0xFF78909C),
    lineColor: Colors.white,
    decorEmojis: ['🌵', '🏜️', '🪨', '🐪', '🌾'],
  ),
  LevelTheme(
    name: '얼음 꽁꽁 길 ❄️',
    grassColor: Color(0xFFE0F7FA),
    roadColor: Color(0xFF455A64),
    lineColor: Color(0xFF80DEEA),
    decorEmojis: ['⛄', '❄️', '🌲', '🧊', '🐧'],
  ),
  LevelTheme(
    name: '우주 은하수 길 🌌',
    grassColor: Color(0xFF1A237E),
    roadColor: Color(0xFF263238),
    lineColor: Color(0xFFE040FB),
    decorEmojis: ['👾', '🚀', '🪐', '🌠', '🛸'],
  ),
];

// ════════════════════════════════════════════
class MiniRacingGame extends StatefulWidget {
  final String playerEmoji;
  const MiniRacingGame({super.key, this.playerEmoji = '🏎️'});
  @override
  State<MiniRacingGame> createState() => _MiniRacingGameState();
}

class _MiniRacingGameState extends State<MiniRacingGame> with SingleTickerProviderStateMixin {
  SelectedCar _selectedCar = SelectedCar(supercar: SupercarSkin.ferrari);
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  bool _isPlaying = false;
  bool _isGameOver = false;
  bool _isStarted = false;

  int _score = 0;
  int _lives = 3;
  int _level = 1;
  bool _hasShield = false;

  // 바나나를 먹었을 때의 스핀 타이머
  double _spinTimer = 0.0;

  Size _screenSize = Size.zero;

  // 차 상태 (부드러운 스티어링을 위한 targetX 사용)
  double _carX = 0.0;
  double _targetCarX = 0.0;
  final double _carYOffset = 110.0;
  final double _carWidth = 65.0;
  final double _carHeight = 100.0;

  // 게임 요소들
  final List<RacingEntity> _entities = [];
  final List<RoadsideDecor> _decors = [];
  final List<Particle> _particles = [];
  final List<ScorePopup> _popups = [];

  double _roadOffset = 0.0;
  double _speed = 280.0; // px/sec
  final Random _random = Random();

  // 드래그 조작을 위한 변수
  double _dragStartCarX = 0.0;
  double _dragStartGlobalX = 0.0;

  // 전용 엔진 플레이어
  final AudioPlayer _enginePlayer = AudioPlayer();
  double _lastEngineRate = 1.0;
  bool _isEngineReady = false;

  LevelTheme get _theme => _themes[(_level - 1) % _themes.length];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _enginePlayer.setReleaseMode(ReleaseMode.loop);

    // 글로벌 오디오 컨텍스트 설정 (iOS 무음모드 무시 및 소리 섞임 허용)
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback, // playback ensures it plays even on silent mode!
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.defaultToSpeaker,
          },
        ),
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
    } catch (e) {
      debugPrint("AudioContext set failed: $e");
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _enginePlayer.dispose();
    super.dispose();
  }

  /// 선택한 차량에 맞는 엔진 사운드를 루프 재생
  void _startEngineSound() {
    if (!AudioManager.instance.soundEnabled) return;
    _isEngineReady = false;
    _enginePlayer.stop();

    // 선택된 차량별 엔진 사운드 매핑
    String soundFile;
    if (_selectedCar.emojiToy == '🚓') {
      soundFile = 'audio/sound_police.wav';
    } else if (_selectedCar.emojiToy == '🚒') {
      soundFile = 'audio/sound_fire.wav';
    } else if (_selectedCar.emojiToy == '🚜') {
      soundFile = 'audio/sound_tractor.wav';
    } else if (_selectedCar.emojiToy == '🚑') {
      soundFile = 'audio/sound_ambulance.wav';
    } else {
      // 슈퍼카: 자체 합성 엔진 루프 사운드
      soundFile = 'audio/engine_loop.wav';
    }

    _enginePlayer.setReleaseMode(ReleaseMode.loop);
    _enginePlayer.play(AssetSource(soundFile), volume: 0.88).then((_) {
      _isEngineReady = true;
      // 초기 속도 기반 피치 설정
      final rate = (0.9 + (_speed - 280.0) / 400.0).clamp(0.85, 1.7);
      _enginePlayer.setPlaybackRate(rate);
    }).catchError((e) {
      debugPrint("Engine sound play failed: $e");
    });
  }

  void _startGame(Size size, {bool autoStart = false}) {
    _screenSize = size;
    _carX = _screenSize.width / 2;
    _targetCarX = _screenSize.width / 2;
    _score = 0;
    _lives = 3;
    _level = 1;
    _hasShield = false;
    _spinTimer = 0.0;
    _speed = 280.0;
    _entities.clear();
    _decors.clear();
    _particles.clear();
    _popups.clear();
    _isPlaying = true;
    _isGameOver = false;
    _isStarted = autoStart;
    
    if (autoStart) {
      _startEngineSound();
    } else {
      _isEngineReady = false;
      _enginePlayer.stop();
    }

    for (int i = 0; i < 6; i++) {
      _spawnDecor(initialY: _random.nextDouble() * _screenSize.height);
    }

    if (!_ticker.isTicking) {
      _ticker.start();
    }
    setState(() {});
  }

  // ── 엔티티 스폰 ──
  void _spawnEntity() {
    final r = _random.nextDouble();
    RacingEntityType type;
    String emoji;
    double w = 55.0;
    double h = 55.0;

    if (r < 0.40) {
      type = RacingEntityType.star;
      emoji = '⭐';
    } else if (r < 0.50) {
      type = RacingEntityType.diamond;
      emoji = '💎';
    } else if (r < 0.55) {
      type = RacingEntityType.heart;
      emoji = '❤️';
    } else if (r < 0.60) {
      type = RacingEntityType.shield;
      emoji = '🔰';
    } else if (r < 0.75) {
      type = RacingEntityType.banana;
      emoji = '🍌';
    } else if (r < 0.90) {
      type = RacingEntityType.cone;
      emoji = '🚧';
    } else {
      type = RacingEntityType.rock;
      emoji = '🪨';
    }

    // 3차선 위치 계산 (도로 폭은 전체 화면의 80%)
    final roadWidth = _screenSize.width * 0.8;
    final roadLeft = (_screenSize.width - roadWidth) / 2;
    final laneWidth = roadWidth / 3;
    final lane = _random.nextInt(3);
    final x = roadLeft + laneWidth * lane + (laneWidth / 2);

    _entities.add(RacingEntity(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}',
      x: x,
      y: -60,
      width: w,
      height: h,
      type: type,
      emoji: emoji,
    ));
  }

  // ── 길가 데코레이션 스폰 ──
  void _spawnDecor({double? initialY}) {
    final side = _random.nextBool() ? -1.0 : 1.0; // 왼쪽 또는 오른쪽 풀밭
    final roadWidth = _screenSize.width * 0.8;
    
    // 도로 바깥 풀밭 임의의 위치
    double x;
    if (side < 0) {
      x = _random.nextDouble() * ((_screenSize.width - roadWidth) / 2 - 20) + 10;
    } else {
      x = _screenSize.width - (_random.nextDouble() * ((_screenSize.width - roadWidth) / 2 - 20) + 10);
    }

    _decors.add(RoadsideDecor(
      id: '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}',
      x: x,
      y: initialY ?? -80,
      emoji: _theme.decorEmojis[_random.nextInt(_theme.decorEmojis.length)],
      scale: _random.nextDouble() * 0.4 + 0.8,
    ));
  }

  // ── 파티클 효과 ──
  void _spawnParticles(double cx, double cy, int count, Color color) {
    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = _random.nextDouble() * 120 + 40;
      _particles.add(Particle(
        x: cx,
        y: cy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 50,
        color: color,
        life: _random.nextDouble() * 0.4 + 0.4,
        size: _random.nextDouble() * 6 + 4,
      ));
    }
  }

  // ── 팝업 추가 ──
  void _addPopup(double x, double y, String text, Color color) {
    _popups.add(ScorePopup(x: x, y: y, text: text, color: color, life: 1.0));
  }

  // ── 게임 루프 Ticker ──
  void _onTick(Duration elapsed) {
    if (!_isPlaying || _isGameOver || _screenSize == Size.zero || !_isStarted) return;

    if (_lastTime == Duration.zero) {
      _lastTime = elapsed;
      return;
    }

    final double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    if (dt > 0.1) return;

    setState(() {
      // 바나나 회전 타이머 업데이트
      if (_spinTimer > 0) {
        _spinTimer -= dt;
      }

      // 차 X축 부드러운 이동 (Lerp)
      _carX += (_targetCarX - _carX) * 0.18;

      // 도로 스크롤
      _roadOffset += _speed * dt;
      if (_roadOffset > 120) {
        _roadOffset -= 120;
      }

      // 데코레이션 이동 & 스폰
      for (var decor in _decors) {
        decor.y += _speed * dt;
      }
      _decors.removeWhere((d) => d.y > _screenSize.height + 100);
      if (_random.nextDouble() < 0.05) {
        _spawnDecor();
      }

      // 엔티티 이동 & 업데이트
      if (_random.nextDouble() < 0.02 + (_level * 0.005)) {
        _spawnEntity();
      }

      // 엔진 소리 피치 실시간 조절: 속도에 따라 자연스럽게 올라가는 배기음
      if (AudioManager.instance.soundEnabled && _isEngineReady) {
        // 0.85(저속) ~ 1.65(최고속) 범위에서 자연스럽게 상승
        final rate = (0.85 + (_speed - 280.0) / 420.0).clamp(0.85, 1.65);
        if ((rate - _lastEngineRate).abs() > 0.04) {
          _lastEngineRate = rate;
          _enginePlayer.setPlaybackRate(rate).catchError((_) {});
        }
      }

      final carRect = Rect.fromCenter(
        center: Offset(_carX, _screenSize.height - _carYOffset),
        width: _carWidth * 0.75,
        height: _carHeight * 0.75,
      );

      for (var entity in _entities) {
        if (entity.isCollected) continue;

        entity.y += _speed * dt;
        entity.rotation += (entity.type == RacingEntityType.banana ? 3.0 : 1.0) * dt;

        // 충돌 체크
        if (entity.rect.overlaps(carRect)) {
          entity.isCollected = true;
          _handleCollision(entity);
        }
      }
      _entities.removeWhere((e) => e.y > _screenSize.height + 100 || e.isCollected);

      // 파티클 & 팝업 업데이트
      for (var p in _particles) {
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 120 * dt; // 중력
        p.life -= dt * 1.5;
      }
      _particles.removeWhere((p) => p.life <= 0);

      for (var p in _popups) {
        p.y -= 45 * dt;
        p.life -= dt * 1.5;
      }
      _popups.removeWhere((p) => p.life <= 0);
    });
  }

  // ── 충돌 처리 ──
  void _handleCollision(RacingEntity entity) {
    final cx = entity.x;
    final cy = entity.y;

    switch (entity.type) {
      case RacingEntityType.star:
        _score += 10;
        _speed += 3.0; // 속도 소폭 상승
        AudioManager.instance.playRacingItemStar();
        HapticFeedback.lightImpact();
        _spawnParticles(cx, cy, 10, Colors.yellow);
        _addPopup(cx, cy, '+10 ⭐', Colors.yellow.shade800);
        _checkLevelUp();
        break;

      case RacingEntityType.diamond:
        _score += 30;
        _speed += 5.0;
        AudioManager.instance.playRacingItemDiamond();
        HapticFeedback.mediumImpact();
        _spawnParticles(cx, cy, 18, Colors.cyan);
        _addPopup(cx, cy, '💎 대박! +30', Colors.cyan.shade700);
        _checkLevelUp();
        break;

      case RacingEntityType.heart:
        if (_lives < 3) {
          _lives++;
          AudioManager.instance.playRacingItemHeart();
          _spawnParticles(cx, cy, 12, Colors.red);
          _addPopup(cx, cy, '❤️ 생명 충전!', Colors.red);
        } else {
          _score += 15;
          AudioManager.instance.playRacingItemStar();
          _addPopup(cx, cy, '+15 ⭐', Colors.yellow.shade800);
        }
        HapticFeedback.lightImpact();
        break;

      case RacingEntityType.shield:
        _hasShield = true;
        AudioManager.instance.playRacingItemShield();
        HapticFeedback.mediumImpact();
        _spawnParticles(cx, cy, 15, Colors.purpleAccent);
        _addPopup(cx, cy, '🔰 보호막 보디가드!', Colors.purple);
        break;

      case RacingEntityType.banana:
        if (_hasShield) {
          _hasShield = false;
          AudioManager.instance.playRacingItemShield();
          _addPopup(cx, cy, '🔰 보호막 방어!', Colors.purple);
        } else {
          // 스핀 현상
          _spinTimer = 1.0;
          AudioManager.instance.playRacingItemBanana();
          HapticFeedback.heavyImpact();
          _spawnParticles(cx, cy, 12, Colors.yellow.shade600);
          _addPopup(cx, cy, '🌀 뱅글뱅글 바나나!', Colors.orange.shade800);
        }
        break;

      case RacingEntityType.cone:
      case RacingEntityType.rock:
        if (_hasShield) {
          _hasShield = false;
          AudioManager.instance.playBoing();
          _addPopup(cx, cy, '🔰 보호막 방어!', Colors.purple);
        } else {
          _lives--;
          AudioManager.instance.playCrash();
          HapticFeedback.heavyImpact();
          _spawnParticles(cx, cy, 20, Colors.grey);
          _addPopup(cx, cy, '💥 아이쿠!', Colors.red);

          if (_lives <= 0) {
            _isGameOver = true;
            _isPlaying = false;
            _enginePlayer.stop();
            // 충돌 사운드를 다 듣고 나서 게임오버 멜로디가 나오도록 지연 실행
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _isGameOver) {
                AudioManager.instance.playGameOver();
              }
            });
          }
        }
        break;
    }
  }

  // ── 레벨업 ──
  void _checkLevelUp() {
    final nextLevel = (_score ~/ 100) + 1;
    if (nextLevel > _level) {
      setState(() {
        _level = nextLevel;
        _speed += 40.0;
        AudioManager.instance.playSuccess();
        _addPopup(_screenSize.width / 2, _screenSize.height / 2, '🎉 레벨업! Level $_level', Colors.purpleAccent);
      });
    }
  }

  // ── 드래그 입력 ──
  void _onDragStart(DragStartDetails details) {
    if (!_isPlaying || _isGameOver) return;
    _dragStartCarX = _carX;
    _dragStartGlobalX = details.globalPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isPlaying || _isGameOver) return;
    final double dx = details.globalPosition.dx - _dragStartGlobalX;
    setState(() {
      _targetCarX = (_dragStartCarX + dx).clamp(
        _carWidth / 2 + 10,
        _screenSize.width - _carWidth / 2 - 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanStart: _onDragStart,
        onPanUpdate: _onDragUpdate,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          color: _theme.grassColor,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_screenSize.width != constraints.maxWidth) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _startGame(Size(constraints.maxWidth, constraints.maxHeight));
                  }
                });
              }

              final roadWidth = constraints.maxWidth * 0.8;
              final roadLeft = (constraints.maxWidth - roadWidth) / 2;

              return Stack(
                children: [
                  // ── 도로 배경 ──
                  Positioned(
                    left: roadLeft,
                    top: 0,
                    bottom: 0,
                    width: roadWidth,
                    child: Container(
                      color: _theme.roadColor,
                      child: Stack(
                        children: [
                          // 도로 경계선 (왼쪽/오른쪽 라인)
                          Positioned(left: 0, top: 0, bottom: 0, width: 6, child: Container(color: Colors.white70)),
                          Positioned(right: 0, top: 0, bottom: 0, width: 6, child: Container(color: Colors.white70)),

                          // 1차선 분할 점선
                          for (int i = -1; i < 12; i++)
                            Positioned(
                              top: (i * 120) + _roadOffset,
                              left: roadWidth / 3 - 3,
                              child: Container(width: 6, height: 60, color: _theme.lineColor.withValues(alpha: 0.8)),
                            ),

                          // 2차선 분할 점선
                          for (int i = -1; i < 12; i++)
                            Positioned(
                              top: (i * 120) + _roadOffset,
                              left: roadWidth * 2 / 3 - 3,
                              child: Container(width: 6, height: 60, color: _theme.lineColor.withValues(alpha: 0.8)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── 길가 데코레이션 ──
                  ..._decors.map((decor) => Positioned(
                    left: decor.x - 25,
                    top: decor.y - 25,
                    child: Transform.scale(
                      scale: decor.scale,
                      child: Text(decor.emoji, style: const TextStyle(fontSize: 40)),
                    ),
                  )),

                  // ── 아이템 & 장애물 ──
                  ..._entities.where((e) => !e.isCollected).map((e) => Positioned(
                    left: e.x - e.width / 2,
                    top: e.y - e.height / 2,
                    child: Transform.rotate(
                      angle: e.rotation,
                      child: Text(e.emoji, style: const TextStyle(fontSize: 42)),
                    ),
                  )),



                  // ── 자동차 🏎️ ──
                  Positioned(
                    left: _carX - _carWidth / 2,
                    top: constraints.maxHeight - _carYOffset - _carHeight / 2,
                    width: _carWidth,
                    height: _carHeight,
                    child: Transform.rotate(
                      angle: _spinTimer > 0 ? _spinTimer * pi * 4 : 0.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 쉴드 오라
                          if (_hasShield)
                            Container(
                              width: _carWidth + 24,
                              height: _carHeight + 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.purpleAccent, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          // 자동차 본체 (리얼리티 슈퍼카 CustomPaint 또는 장난감 이모티콘)
                          _selectedCar.isSupercar
                              ? CustomPaint(
                                  size: Size(_carWidth, _carHeight),
                                  painter: SupercarPainter(skin: _selectedCar.supercar!),
                                )
                              : Center(
                                  child: Text(
                                    _selectedCar.emojiToy!,
                                    style: const TextStyle(fontSize: 64),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  // ── 파티클 ──
                  ..._particles.map((p) => Positioned(
                    left: p.x - p.size / 2,
                    top: p.y - p.size / 2,
                    child: Opacity(
                      opacity: p.life.clamp(0.0, 1.0),
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(color: p.color, shape: BoxShape.circle),
                      ),
                    ),
                  )),

                  // ── 팝업 점수 ──
                  ..._popups.map((p) => Positioned(
                    left: p.x - 40,
                    top: p.y,
                    child: Opacity(
                      opacity: p.life.clamp(0.0, 1.0),
                      child: Text(
                        p.text,
                        style: GoogleFonts.jua(
                          fontSize: 22,
                          color: p.color,
                          shadows: [const Shadow(color: Colors.white, blurRadius: 4)],
                        ),
                      ),
                    ),
                  )),

                  // ── 헤더 UI (아기자기 & 탭 쉬운 프리미엄 헤더) ──
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. 🏠 홈 버튼 (크고 눌리기 쉬운 사이즈)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _enginePlayer.stop();
                              AudioManager.instance.playClick();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF8A8A), Color(0xFFFF5252)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5252).withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('🏠', style: TextStyle(fontSize: 24)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 2. 중앙: 테마명 + 레벨 뱃지
                          Expanded(
                            child: Container(
                              height: 54,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(27),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 레벨 뱃지
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Lv.$_level',
                                      style: GoogleFonts.jua(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _theme.name,
                                      style: GoogleFonts.jua(
                                        fontSize: 15,
                                        color: KidsTheme.textDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. 점수 + 하트 카드
                          Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '🎯 $_score',
                                  style: GoogleFonts.jua(fontSize: 17, color: KidsTheme.orange, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(3, (index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 1),
                                      child: Opacity(
                                        opacity: index < _lives ? 1.0 : 0.25,
                                        child: const Text('❤️', style: TextStyle(fontSize: 13)),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 게임 오버 레이아웃 (아기자기 & 고급스러운 프리미엄 팝업) ──
                  if (_isGameOver)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(color: const Color(0xFFFF9F1C), width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 4,
                                  offset: Offset(0, -2),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header: Crash & Car Badge
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFFB74D), width: 3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF9F1C).withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _selectedCar.supercar != null
                                              ? _selectedCar.supercar!.name.split(' ').last
                                              : (_selectedCar.emojiToy ?? '🏎️'),
                                          style: const TextStyle(fontSize: 48),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text('💥', style: TextStyle(fontSize: 22)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Title Text
                                  Text(
                                    '쿠웅! 사고가 났어요!',
                                    style: GoogleFonts.jua(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5252),
                                      shadows: const [
                                        Shadow(color: Color(0xFFFFCDD2), offset: Offset(1.5, 1.5), blurRadius: 0),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Score Card Box
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: const Color(0xFFFFE082), width: 2),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🎯', style: TextStyle(fontSize: 22)),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$_score',
                                              style: GoogleFonts.jua(
                                                fontSize: 38,
                                                color: const Color(0xFF2E3A59),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' 점',
                                              style: GoogleFonts.jua(fontSize: 20, color: const Color(0xFF718096)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '🚗 도달 레벨 : Lv.$_level ${_theme.name}',
                                            style: GoogleFonts.jua(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // 3D Action Buttons
                                  Row(
                                    children: [
                                      // Home button
                                      Expanded(
                                        flex: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            _enginePlayer.stop();
                                            AudioManager.instance.playClick();
                                            Navigator.of(context).pop();
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 13),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFFFF8A8A), Color(0xFFFF5252)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: const [
                                                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '🏠 로비로',
                                                style: GoogleFonts.jua(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Restart button
                                      Expanded(
                                        flex: 3,
                                        child: GestureDetector(
                                          onTap: () {
                                            AudioManager.instance.playClick();
                                            _startGame(_screenSize, autoStart: true);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 13),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.white, width: 2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '🏎️ 다시 달리기!',
                                                style: GoogleFonts.jua(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
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
                    ),
                  if (!_isStarted)
                    _buildStartOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 620),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFFF9F1C), width: 4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏎️', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 6),
                      Text(
                        '요리조리 자동차',
                        style: GoogleFonts.jua(fontSize: 26, color: KidsTheme.orange, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 자동차 선택 차고지 (가장 중요하므로 상단 배치) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Row(
                            children: [
                              const Text('🚗', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '출전 자동차 선택',
                                style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF4B5563), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 72,
                          child: ValueListenableBuilder<List<String>>(
                            valueListenable: PlayerDataManager.instance.unlockedToysNotifier,
                            builder: (context, unlockedToys, child) {
                              final racingToys = ['🚓', '🚒', '🚜', '🚑'].where((toy) => unlockedToys.contains(toy)).toList();
                              final totalItems = SupercarSkin.values.length + racingToys.length;

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: totalItems,
                                itemBuilder: (context, index) {
                                  final isSupercar = index < SupercarSkin.values.length;
                                  final SelectedCar carOption = isSupercar
                                      ? SelectedCar(supercar: SupercarSkin.values[index])
                                      : SelectedCar(emojiToy: racingToys[index - SupercarSkin.values.length]);

                                  final isSelected = carOption == _selectedCar;
                                  final mainColor = isSupercar ? carOption.supercar!.mainColor : const Color(0xFF6A1B9A);
                                  final name = isSupercar
                                      ? carOption.supercar!.name.split(' ')[0]
                                      : (carOption.emojiToy == '🚓' ? '경찰차' : carOption.emojiToy == '🚒' ? '소방차' : carOption.emojiToy == '🚜' ? '트랙터' : '구급차');

                                  return GestureDetector(
                                    onTap: () {
                                      AudioManager.instance.playClick();
                                      setState(() {
                                        _selectedCar = carOption;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? mainColor.withValues(alpha: 0.15) : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? mainColor : Colors.grey.shade300,
                                          width: isSelected ? 2.5 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: mainColor.withValues(alpha: 0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 36,
                                            child: isSupercar
                                                ? CustomPaint(painter: SupercarPainter(skin: carOption.supercar!))
                                                : Center(child: Text(carOption.emojiToy!, style: const TextStyle(fontSize: 24))),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            name,
                                            style: GoogleFonts.jua(
                                              fontSize: 10,
                                              color: isSelected ? KidsTheme.textDark : Colors.grey.shade600,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 콤팩트 가이드 (아이템 & 장애물) ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // 득템
                        Row(
                          children: [
                            const Text('⭐💎❤️🔰', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('먹어요! 😋', style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(width: 1, height: 20, color: const Color(0xFFFFD54F)),
                        // 피하기
                        Row(
                          children: [
                            const Text('🪨🚧🍌', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text('피해요! ⚠️', style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── 출발하기 버튼 (언제나 한눈에 바로 보이는 크고 시원한 3D 버튼) ──
                  GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      setState(() {
                        _isStarted = true;
                      });
                      _startEngineSound();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '🏎️ 출발하기! 🚀',
                          style: GoogleFonts.jua(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


