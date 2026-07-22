import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/audio/audio_manager.dart';
import '../core/theme/kids_theme.dart';
import 'lobby_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _cloudCtrl;

  @override
  void initState() {
    super.initState();

    // 1. Logo Elastic Bounce Animation
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    // 2. 1.5-second Progress Bar Animation
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // 3. Floating Clouds Animation
    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Play welcome sound effect
    AudioManager.instance.playChime();

    // Navigate to Lobby after exactly 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (context, animation, secondaryAnimation) => const LobbyScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
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
    _cloudCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 동화속 하늘 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0F7FA), // Soft cyan sky
                  Color(0xFFFFF9C4), // Warm pastel yellow
                  Color(0xFFFFECB3), // Soft cream amber
                  Color(0xFFFFD180), // Warm peach
                ],
                stops: [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // ☁️ 둥실둥실 구름 & 별무리 배경
          AnimatedBuilder(
            animation: _cloudCtrl,
            builder: (context, child) {
              final val = _cloudCtrl.value;
              return Stack(
                children: [
                  Positioned(
                    left: (val * 400) % 450 - 80,
                    top: 80,
                    child: const Opacity(opacity: 0.7, child: Text('☁️', style: TextStyle(fontSize: 60))),
                  ),
                  Positioned(
                    right: (val * 350) % 420 - 70,
                    top: 180,
                    child: const Opacity(opacity: 0.6, child: Text('☁️', style: TextStyle(fontSize: 48))),
                  ),
                  Positioned(
                    left: 50 + sin(val * 2 * pi) * 20,
                    top: 240,
                    child: const Opacity(opacity: 0.8, child: Text('✨', style: TextStyle(fontSize: 32))),
                  ),
                  Positioned(
                    right: 60 + cos(val * 2 * pi) * 25,
                    top: 120,
                    child: const Opacity(opacity: 0.75, child: Text('⭐', style: TextStyle(fontSize: 28))),
                  ),
                  Positioned(
                    left: 200 + sin(val * 3 * pi) * 25,
                    top: 150,
                    child: const Opacity(opacity: 0.7, child: Text('🎈', style: TextStyle(fontSize: 34))),
                  ),
                ],
              );
            },
          ),

          // 🧸 메인 3D 로고 & 타이틀 & 로딩바
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3D 로고 카드 (Bounce Scale)
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _logoCtrl,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    width: 170,
                    height: 170,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: KidsTheme.orange.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text('🧸', style: TextStyle(fontSize: 80)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 타이틀
                Text(
                  '키즈 토이 박스',
                  style: GoogleFonts.jua(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..style = PaintingStyle.fill
                      ..color = KidsTheme.purple,
                    shadows: const [
                      Shadow(
                        color: Colors.white,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                      Shadow(
                        color: Colors.black12,
                        offset: Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 서브 캐치프레이즈 캡슐
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    '✨ 미니 게임 천국 ✨',
                    style: GoogleFonts.jua(
                      fontSize: 16,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // 1.5초 로딩바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressCtrl,
                        builder: (context, child) {
                          return Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: _progressCtrl.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9F1C), Color(0xFFFFBF00)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '신나는 장난감 세상 준비 중...',
                        style: GoogleFonts.jua(
                          fontSize: 15,
                          color: KidsTheme.textDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
