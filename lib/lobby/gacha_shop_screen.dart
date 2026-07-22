import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../core/theme/kids_theme.dart';
import '../core/audio/audio_manager.dart';
import '../core/data/player_data_manager.dart';

// ── 구슬 파티클 모델 ──────────────────────────────────────────────────────────
class _Marble {
  double x, y, vx, vy, radius;
  Color color;

  _Marble({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });
}

// ── 구슬 물리 시뮬레이션 페인터 ───────────────────────────────────────────────
class _MarblePainter extends CustomPainter {
  final List<_Marble> marbles;
  final double time;

  _MarblePainter(this.marbles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marbles) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(m.color, Colors.white, 0.6)!,
            m.color,
            m.color.withAlpha(180),
          ],
          stops: const [0.0, 0.5, 1.0],
          center: const Alignment(-0.3, -0.3),
        ).createShader(Rect.fromCircle(center: Offset(m.x, m.y), radius: m.radius));

      canvas.drawCircle(Offset(m.x, m.y), m.radius, paint);

      // 하이라이트
      final highlightPaint = Paint()
        ..color = Colors.white.withAlpha(180)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(m.x - m.radius * 0.3, m.y - m.radius * 0.3),
        m.radius * 0.28,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_MarblePainter old) => true;
}

class GachaShopScreen extends StatefulWidget {
  const GachaShopScreen({super.key});

  @override
  State<GachaShopScreen> createState() => _GachaShopScreenState();
}

class _GachaShopScreenState extends State<GachaShopScreen>
    with TickerProviderStateMixin {
  final int _gachaCost = 5;

  // Unique skins to collect (Dino, Racing, Fishing, Pacman, Snake)
  final List<String> _availableToys = [
    '🦕', '🐉', '🦄', '🐢', // Dino skins
    '🚓', '🚒', '🚜', '🚑', // Racing skins
    '🧲', '🔱', '🦈', '🦑', // Fishing skins
    '🐥', '🐱', '🐶', '🐸', // Pacman skins
    '🐍', '🐲', '🐊',       // Snake skins (Unicorn 🦄 is already in Dino skins)
  ];

  late ConfettiController _confettiController;

  // ── 구슬 애니메이션 ──
  late AnimationController _marbleCtrl;
  late List<_Marble> _marbles;
  final _random = Random();
  static const _marbleColors = [
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
    Color(0xFFFF7043),
    Color(0xFF00ACC1),
    Color(0xFFEC407A),
  ];

  // ── Pulling 애니메이션 ──
  late AnimationController _shakeCtrl;
  late AnimationController _capsuleCtrl;
  late AnimationController _popCtrl;

  bool _isPulling = false;
  String? _pulledToy;
  bool _showCapsule = false;
  bool _capsulePopped = false;

  double _globeSize = 0;

  @override
  void initState() {
    super.initState();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _marbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateMarbles)
      ..repeat();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _capsuleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Init marbles after first frame so we know globe size
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMarbles());
  }

  void _initMarbles({bool burst = false}) {
    final r = _globeSize > 0 ? _globeSize / 2 : 100.0;
    final cx = r;
    final cy = r;
    _marbles = List.generate(8, (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final dist = burst
          ? (0.1 + _random.nextDouble() * 0.4) * r
          : (0.2 + _random.nextDouble() * 0.5) * r;
      final speed = burst ? (60 + _random.nextDouble() * 80) : (20 + _random.nextDouble() * 40);
      return _Marble(
        x: cx + cos(angle) * dist,
        y: cy + sin(angle) * dist,
        vx: burst ? cos(angle) * speed : ((_random.nextDouble() - 0.5) * 50),
        vy: burst ? sin(angle) * speed : ((_random.nextDouble() - 0.5) * 50),
        radius: 14 + _random.nextDouble() * 8,
        color: _marbleColors[i % _marbleColors.length],
      );
    });
  }

  void _updateMarbles() {
    if (_marbles.isEmpty) return;
    final dt = 1.0 / 60.0;
    final r = _globeSize > 0 ? _globeSize / 2 : 100.0;
    final cx = r;
    final cy = r;
    final isBursting = _isPulling;

    setState(() {
      for (final m in _marbles) {
        m.x += m.vx * dt;
        m.y += m.vy * dt;

        // 중력 (천천히, 뽑는 중에는 더 강하게)
        m.vy += (isBursting ? 220 : 80) * dt;

        // 글로브 경계 충돌 - 안쪽에서 튕김
        final dx = m.x - cx;
        final dy = m.y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final maxDist = r - m.radius - 4;
        if (dist > maxDist) {
          final nx = dx / dist;
          final ny = dy / dist;
          m.x = cx + nx * maxDist;
          m.y = cy + ny * maxDist;
          // 반사 속도 (에너지 손실 적용)
          final dot = m.vx * nx + m.vy * ny;
          m.vx = (m.vx - 1.6 * dot * nx) * 0.82;
          m.vy = (m.vy - 1.6 * dot * ny) * 0.82;
        }

        // 속도 감쇠 (뽑는 중에는 더 빠르게 흔들리도록)
        final damping = isBursting ? 0.99 : 0.98;
        m.vx *= damping;
        m.vy *= damping;

        // 정적 상태에서 약간의 랜덤 지터
        if (!isBursting && _random.nextDouble() < 0.02) {
          m.vx += (_random.nextDouble() - 0.5) * 30;
          m.vy += (_random.nextDouble() - 0.5) * 30;
        }
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _marbleCtrl.dispose();
    _shakeCtrl.dispose();
    _capsuleCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  void _pullGacha() async {
    if (_isPulling) return;

    final currentCoins = PlayerDataManager.instance.starCoins;
    if (currentCoins < _gachaCost) {
      AudioManager.instance.playThud();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '별코인이 부족해요! 게임을 더 하고 와주세요 😢',
            style: GoogleFonts.jua(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          backgroundColor: KidsTheme.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
      return;
    }

    final unlockedToys = PlayerDataManager.instance.unlockedToys;
    final lockedToys = _availableToys.where((t) => !unlockedToys.contains(t)).toList();

    if (lockedToys.isEmpty) {
      AudioManager.instance.playPop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '모든 장난감을 모았어요! 대단해요! 🎉',
            style: GoogleFonts.jua(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          backgroundColor: KidsTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
      return;
    }

    // Deduct coins
    PlayerDataManager.instance.spendStarCoins(_gachaCost);

    setState(() {
      _isPulling = true;
      _pulledToy = null;
      _showCapsule = false;
      _capsulePopped = false;
    });

    // Burst marbles
    _initMarbles(burst: true);

    final selectedToy = lockedToys[_random.nextInt(lockedToys.length)];

    AudioManager.instance.playClick();
    HapticFeedback.heavyImpact();

    // 1. Shake machine
    _shakeCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 900));
    _shakeCtrl.stop();
    _shakeCtrl.reset();

    // 2. Drop capsule
    setState(() => _showCapsule = true);
    AudioManager.instance.playBoing();
    await _capsuleCtrl.forward(from: 0.0);

    // 3. Pop!
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() {
      _capsulePopped = true;
      _pulledToy = selectedToy;
    });

    AudioManager.instance.playSuccess();
    _confettiController.play();
    HapticFeedback.lightImpact();
    await _popCtrl.forward(from: 0.0);

    // Save unlock
    PlayerDataManager.instance.unlockToy(selectedToy);
  }

  void _dismissOverlay() {
    if (!mounted) return;
    setState(() {
      _isPulling = false;
      _pulledToy = null;
      _showCapsule = false;
      _capsulePopped = false;
      _capsuleCtrl.reset();
      _popCtrl.reset();
    });
    _initMarbles(burst: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5FF),
      body: Stack(
        children: [
          // ── Background ──
          Positioned.fill(
            child: CustomPaint(
              painter: _GachaBgPainter(),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildGachaMachine(),
                const SizedBox(height: 16),
                _buildDivider(),
                Expanded(child: _buildCollectionShelf()),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.pink],
            ),
          ),

          // ── 뽑은 장난감 오버레이 (탭하면 닫힘) ──
          if (_capsulePopped && _pulledToy != null)
            GestureDetector(
              onTap: _dismissOverlay,
              behavior: HitTestBehavior.opaque,
              child: _buildPulledToyOverlay(),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (!_isPulling) {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF5B21B6), size: 28),
            ),
          ),
          Text(
            '🎰 장난감 뽑기방',
            style: GoogleFonts.jua(fontSize: 26, color: const Color(0xFF5B21B6)),
          ),
          ValueListenableBuilder<int>(
            valueListenable: PlayerDataManager.instance.starCoinsNotifier,
            builder: (context, coins, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withAlpha(130),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: GoogleFonts.jua(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGachaMachine() {
    return AnimatedBuilder(
      animation: _shakeCtrl,
      builder: (context, child) {
        final dx = sin(_shakeCtrl.value * 4 * pi) * 8;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Column(
        children: [
          // ── 글로브 (구슬이 통통 튀는 유리구) ──
          LayoutBuilder(
            builder: (context, constraints) {
              final size = 230.0;
              if (_globeSize != size) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _globeSize != size) {
                    setState(() => _globeSize = size);
                    _initMarbles();
                  }
                });
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 글로브 외부 글로우
                  Container(
                    width: size + 24,
                    height: size + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFCE93D8).withAlpha(120),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // 글로브 본체
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFF3E5FF),
                          Color(0xFFE1BEE7),
                        ],
                        center: Alignment(-0.2, -0.2),
                      ),
                      border: Border.all(color: const Color(0xFFBA68C8), width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFCE93D8).withAlpha(100),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.white.withAlpha(200),
                          blurRadius: 12,
                          offset: const Offset(-4, -4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: _MarblePainter(_marbles, _marbleCtrl.value),
                      ),
                    ),
                  ),
                  // 글로브 하이라이트 오버레이
                  Positioned(
                    top: 24,
                    left: 50,
                    child: Container(
                      width: 80,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(160),
                            Colors.white.withAlpha(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 뽑히는 캡슐 드롭
                  if (_showCapsule && !_capsulePopped)
                    AnimatedBuilder(
                      animation: _capsuleCtrl,
                      builder: (context, child) {
                        final t = Curves.bounceOut.transform(_capsuleCtrl.value);
                        return Positioned(
                          bottom: 16 + (1 - t) * 80,
                          child: const Text('🥚', style: TextStyle(fontSize: 54)),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 0),
          // ── 하단 받침대 ──
          Container(
            width: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withAlpha(160),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isPulling ? null : _pullGacha,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isPulling ? Colors.grey.shade400 : const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: _isPulling
                            ? []
                            : [
                                const BoxShadow(
                                  color: Color(0xFFC79000),
                                  offset: Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_gachaCost',
                            style: GoogleFonts.jua(
                              fontSize: 22,
                              color: _isPulling ? Colors.white : const Color(0xFF5B21B6),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('⭐', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            _isPulling ? '돌리는 중...' : '돌리기! 🎰',
                            style: GoogleFonts.jua(
                              fontSize: 18,
                              color: _isPulling ? Colors.white : const Color(0xFF5B21B6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 배출구
                  Container(
                    width: 55,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: Colors.grey.shade600, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFFBA68C8).withAlpha(120)]),
                  ))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBA68C8).withAlpha(100)),
            ),
            child: Text(
              '🗂️ 내 장난감 진열대',
              style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFF6A1B9A)),
            ),
          ),
          Expanded(
              child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [const Color(0xFFBA68C8).withAlpha(120), Colors.transparent]),
                  ))),
        ],
      ),
    );
  }

  Widget _buildCollectionShelf() {
    // Category labels with their corresponding toy lists
    final categories = [
      (label: '🦕 공룡 점프', toys: const ['🦕', '🐉', '🦄', '🐢']),
      (label: '🏎️ 자동차', toys: const ['🚓', '🚒', '🚜', '🚑']),
      (label: '🎣 낚시 놀이', toys: const ['🧲', '🔱', '🦈', '🦑']),
      (label: '🟡 팩맨 탐험', toys: const ['🐥', '🐱', '🐶', '🐸']),
      (label: '🐛 지렁이 탐험', toys: const ['🐍', '🐲', '🦄', '🐊']),
    ];

    return ValueListenableBuilder<List<String>>(
      valueListenable: PlayerDataManager.instance.unlockedToysNotifier,
      builder: (context, unlockedToys, child) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: categories.map((cat) {
            final categoryToys = cat.toys;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    cat.label,
                    style: GoogleFonts.jua(fontSize: 18, color: const Color(0xFF6A1B9A)),
                  ),
                ),
                Row(
                  children: categoryToys.map((toy) {
                    final isUnlocked = unlockedToys.contains(toy);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isUnlocked ? Colors.white : Colors.grey.shade200,
                                border: isUnlocked
                                    ? Border.all(color: const Color(0xFFCE93D8), width: 3)
                                    : null,
                                boxShadow: isUnlocked
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFCE93D8).withAlpha(120),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  isUnlocked ? toy : '🔒',
                                  style: TextStyle(
                                    fontSize: isUnlocked ? 32 : 22,
                                    color: isUnlocked ? null : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? const Color(0xFFBA68C8)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  // ── 뽑은 장난감 오버레이 (탭하면 닫힘 - GestureDetector는 build()에서 감쌈) ──
  Widget _buildPulledToyOverlay() {
    return Container(
      color: Colors.black.withAlpha(160),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _popCtrl,
        builder: (context, child) {
          final scale = TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(begin: 0.0, end: 1.4)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
              weight: 40,
            ),
            TweenSequenceItem(
              tween: Tween(begin: 1.4, end: 1.0)
                  .chain(CurveTween(curve: Curves.elasticOut)),
              weight: 60,
            ),
          ]).transform(_popCtrl.value);

          return Transform.scale(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.white, Color(0xFFF3E5FF)],
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withAlpha(160),
                        blurRadius: 40,
                        spreadRadius: 12,
                      ),
                      BoxShadow(
                        color: const Color(0xFF9C27B0).withAlpha(80),
                        blurRadius: 60,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(_pulledToy!, style: const TextStyle(fontSize: 80)),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withAlpha(120),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '새 장난감 획득! 🎉',
                    style: GoogleFonts.jua(fontSize: 22, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '화면을 탭하면 닫힙니다',
                  style: GoogleFonts.jua(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── 배경 페인터 ──────────────────────────────────────────────────────────────
class _GachaBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // 부드러운 보라색 그라디언트 배경
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF3E5FF), Color(0xFFE8EAF6), Color(0xFFEDE7F6)],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 배경 폴카도트 장식
    final dotPaint = Paint()..color = const Color(0xFFCE93D8).withAlpha(25);
    final positions = [
      Offset(size.width * 0.05, size.height * 0.1),
      Offset(size.width * 0.90, size.height * 0.07),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.80, size.height * 0.80),
      Offset(size.width * 0.50, size.height * 0.05),
      Offset(size.width * 0.92, size.height * 0.45),
      Offset(size.width * 0.08, size.height * 0.50),
    ];
    for (final p in positions) {
      canvas.drawCircle(p, 36, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_GachaBgPainter old) => false;
}
