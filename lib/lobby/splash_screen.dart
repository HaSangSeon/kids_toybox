import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'lobby_screen.dart';

// ── 솟구치는 미니게임 아이콘 아이템 ──
class _BurstingItem {
  final String emoji;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double speed;
  final double delay;
  final double rotateDir;

  _BurstingItem({
    required this.emoji,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.speed,
    required this.delay,
    required this.rotateDir,
  });
}

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 메인 로고 애니메이션
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotate;

  // 로딩 프로그레스 (2.4초)
  late AnimationController _progressCtrl;

  // 배경 및 솟구치는 미니게임 파티클 루프
  late AnimationController _burstCtrl;

  // 텍스트 페이드 & 슬라이드
  late AnimationController _textCtrl;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  final List<_BurstingItem> _burstItems = [];
  final Random _rng = Random();

  static const List<String> _toyEmojis = [
    '🎮', '🧸', '🚀', '🎨', '🧩', '🎯', '🏎️', '🔮', '🦄', '🎈', '🍬', '🍰', '🐶', '🐱', '🌈', '🎁'
  ];

  @override
  void initState() {
    super.initState();

    // 솟구쳐 오르는 미니게임 장난감 파티클 24개 생성
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi + (_rng.nextDouble() - 0.5) * 0.4;
      final dist = 140.0 + _rng.nextDouble() * 220.0;
      _burstItems.add(_BurstingItem(
        emoji: _toyEmojis[i % _toyEmojis.length],
        startX: 0.5,
        startY: 0.52,
        endX: 0.5 + cos(angle) * (dist / 400.0),
        endY: 0.52 + sin(angle) * (dist / 600.0),
        size: 28 + _rng.nextDouble() * 26,
        speed: 0.7 + _rng.nextDouble() * 0.5,
        delay: _rng.nextDouble() * 0.35,
        rotateDir: _rng.nextBool() ? 1.0 : -1.0,
      ));
    }

    // 히어로 로고 탄성 바운스
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut);
    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoCtrl.forward();

    // 솟구치는 아이콘 루프
    _burstCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    // 텍스트 애니메이션
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _textOpacity = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // 프로그레스 바 (3.2초)
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textCtrl.forward();
    });

    // 3.2초 후 로비로 이동
    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (context, animation, secondaryAnimation) => const LobbyScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _progressCtrl.dispose();
    _burstCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 🎨 1. 전체화면 3D 무지개 오로라 아트워크 ────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _FullScreenToyBoxPainter(animProgress: _burstCtrl),
            ),
          ),

          // ── 🧸 2. 마법 상자에서 사방으로 솟구쳐 떠오르는 미니게임 아이콘 ───────
          AnimatedBuilder(
            animation: _burstCtrl,
            builder: (context, child) {
              final t = _burstCtrl.value;
              return Stack(
                children: _burstItems.map((item) {
                  final progress = ((t - item.delay) % 1.0) * item.speed;
                  final clampedP = progress.clamp(0.0, 1.0);

                  final curX = item.startX + (item.endX - item.startX) * clampedP;
                  final curY = item.startY + (item.endY - item.startY) * clampedP - (sin(clampedP * pi) * 0.08);

                  final opacity = (clampedP < 0.2 ? clampedP / 0.2 : (1.0 - clampedP)).clamp(0.0, 1.0);
                  final scale = 0.5 + sin(clampedP * pi) * 0.7;
                  final rotateAngle = clampedP * pi * 2 * item.rotateDir;

                  return Positioned(
                    left: curX * size.width - (item.size / 2),
                    top: curY * size.height - (item.size / 2),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Transform.rotate(
                          angle: rotateAngle,
                          child: Text(
                            item.emoji,
                            style: TextStyle(
                              fontSize: item.size,
                              shadows: const [
                                Shadow(color: Colors.white, blurRadius: 10),
                                Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // ── 🏰 3. 화면 중앙 히어로 타이틀 & 마법 보물상자 ───────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D 엠보싱 마법 보물 상자 아이콘
                ScaleTransition(
                  scale: _logoScale,
                  child: RotationTransition(
                    turns: _logoRotate,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFF9C4), Color(0xFFFFB300)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 4.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade600.withValues(alpha: 0.5),
                            blurRadius: 32,
                            spreadRadius: 4,
                            offset: const Offset(0, 10),
                          ),
                          const BoxShadow(color: Colors.white, blurRadius: 16),
                        ],
                      ),
                      child: const Center(
                        child: Text('🎁', style: TextStyle(fontSize: 72)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 3D 엠보싱 타이틀 & 캡슐 뱃지
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        // 입체 타이틀
                        Stack(
                          children: [
                            // 텍스트 외곽 테두리 및 그림자
                            Text(
                              '키즈 토이 박스',
                              style: GoogleFonts.jua(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 7
                                  ..color = Colors.white,
                              ),
                            ),
                            // 메인 텍스트 그라디언트
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFFE040FB), Color(0xFFFF4081)],
                              ).createShader(bounds),
                              child: Text(
                                '키즈 토이 박스',
                                style: GoogleFonts.jua(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 캐치프레이즈 고급 젤리 뱃지
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5252), Color(0xFFFF9800)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade800.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🎠 ', style: TextStyle(fontSize: 16)),
                              Text(
                                '신나는 22가지 미니게임 세상!',
                                style: GoogleFonts.jua(
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Text(' 🚀', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 💎 4. 하단 3D 크리스탈 프로그레스 바 & 퍼센티지 ─────────────────
          Positioned(
            left: 36,
            right: 36,
            bottom: 60,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, child) {
                      return _CrystalProgressBar(value: _progressCtrl.value);
                    },
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder: (context, child) {
                      final pct = (_progressCtrl.value * 100).toInt();
                      return Text(
                        '장난감 상자가 열리고 있어요! 🚀 $pct%',
                        style: GoogleFonts.jua(
                          fontSize: 16,
                          color: const Color(0xFF5E35B1),
                          shadows: const [
                            Shadow(color: Colors.white, blurRadius: 4),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 🎨 전체화면 3D 파스텔 무지개 & 오로라 CustomPainter
// ══════════════════════════════════════════════════════════════════════════════

class _FullScreenToyBoxPainter extends CustomPainter {
  final Animation<double> animProgress;
  _FullScreenToyBoxPainter({required this.animProgress}) : super(repaint: animProgress);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 메인 배경 그라디언트 (화사하고 몽환적인 파스텔 무지개)
    final bgRect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8EAF6), // Soft indigo sky
          Color(0xFFF3E5F5), // Pastel lavender
          Color(0xFFE0F7FA), // Soft cyan
          Color(0xFFFFF8E1), // Warm cream
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. 무지개 아치 (상단 대형 무지개)
    final rainbowCenter = Offset(size.width / 2, size.height * 0.32);
    final rainbowColors = [
      const Color(0xFFFF8A80).withValues(alpha: 0.35),
      const Color(0xFFFFD54F).withValues(alpha: 0.35),
      const Color(0xFF81C784).withValues(alpha: 0.35),
      const Color(0xFF4FC3F7).withValues(alpha: 0.35),
      const Color(0xFFBA68C8).withValues(alpha: 0.35),
    ];

    for (int i = 0; i < rainbowColors.length; i++) {
      final r = size.width * 0.6 + (i * 14.0);
      final rPaint = Paint()
        ..color = rainbowColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0;
      canvas.drawCircle(rainbowCenter, r, rPaint);
    }

    // 3. 중앙 오로라 광원 뿜어져 나옴
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.65),
          const Color(0xFFFFF9C4).withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.5), radius: size.width * 0.55));
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.5), size.width * 0.55, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _FullScreenToyBoxPainter oldDelegate) => true;
}

// ══════════════════════════════════════════════════════════════════════════════
// 💎 3D 크리스탈 젤리 프로그레스 바
// ══════════════════════════════════════════════════════════════════════════════

class _CrystalProgressBar extends StatelessWidget {
  final double value;
  const _CrystalProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fillW = constraints.maxWidth * value.clamp(0.0, 1.0);
          return Stack(
            children: [
              // 채워지는 3D 무지개 젤리 바
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: fillW,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFFE040FB), Color(0xFFFF4081)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE040FB).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
