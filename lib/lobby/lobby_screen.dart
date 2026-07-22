import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/kids_theme.dart';
import '../core/audio/audio_manager.dart';
import '../games/balloon_pop/balloon_pop_game.dart';
import '../games/shape_coloring/shape_coloring_game.dart';
import '../games/hidden_object/hidden_object_game.dart';
import '../games/spot_difference/spot_difference_game.dart';
import '../games/memory_match/memory_match_game.dart';
import '../games/fruit_slicer/fruit_slicer_game.dart';
import '../games/feed_animals/feed_animals_game.dart';
import '../games/whack_a_mole/whack_a_mole_game.dart';
import '../games/dino_jump/dino_jump_game.dart';
import '../games/brick_breaker/brick_breaker_game.dart';
import '../games/xylophone/xylophone_game.dart';
import '../games/bubble_pop/bubble_pop_game.dart';
import '../games/burger_maker/burger_maker_game.dart';
import '../games/tower_builder/tower_builder_game.dart';
import '../games/mini_racing/mini_racing_game.dart';
import '../games/fishing_game/fishing_game_game.dart';
import '../games/connect_dots/connect_dots_game.dart';
import '../games/tracing/tracing_game.dart';
import '../games/jigsaw_puzzle/jigsaw_puzzle_game.dart';
import '../games/maze_escape/maze_escape_game.dart';
import '../games/block_builder/block_builder_game.dart';
import '../games/pacman/pacman_game.dart';
import '../games/snake/snake_game.dart';
import '../core/data/player_data_manager.dart';
import 'gacha_shop_screen.dart';
import '../core/widgets/skin_select_modal.dart';
import '../core/widgets/pacman_icon.dart';

// ─── Background cloud painter ────────────────────────────────────────────────
class _CloudPainter extends CustomPainter {
  final double animValue;
  _CloudPainter(this.animValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    // Draw a few soft cloud blobs at fixed relative positions
    _drawCloud(canvas, paint, size, 0.10, 0.08, 60, animValue * 6);
    _drawCloud(canvas, paint, size, 0.75, 0.05, 50, -animValue * 5);
    _drawCloud(canvas, paint, size, 0.40, 0.18, 40, animValue * 4);
    _drawCloud(canvas, paint, size, 0.85, 0.22, 35, -animValue * 3);
    _drawCloud(canvas, paint, size, 0.20, 0.30, 28, animValue * 3.5);
  }

  void _drawCloud(Canvas canvas, Paint paint, Size size,
      double xRel, double yRel, double r, double drift) {
    final cx = size.width * xRel + drift;
    final cy = size.height * yRel;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    canvas.drawCircle(Offset(cx + r * 0.7, cy + r * 0.1), r * 0.75, paint);
    canvas.drawCircle(Offset(cx - r * 0.65, cy + r * 0.15), r * 0.65, paint);
    canvas.drawCircle(Offset(cx + r * 0.4, cy - r * 0.3), r * 0.55, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.animValue != animValue;
}

// ─── Star painter ────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final double animValue;
  final List<_StarDot> stars;
  _StarPainter(this.animValue, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = 0.3 + 0.5 * ((sin((animValue * 2 * pi) + s.phase) + 1) / 2);
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(size.width * s.x, size.height * s.y),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.animValue != animValue;
}

class _StarDot {
  final double x, y, radius, phase;
  _StarDot(this.x, this.y, this.radius, this.phase);
}

// ─── Main Lobby Screen ───────────────────────────────────────────────────────
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _bounceController;
  late AnimationController _starController;
  bool _soundOn = true;

  late final List<_StarDot> _stars;

  @override
  void initState() {
    super.initState();

    // Slow drifting clouds
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    // Character bounce
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Star twinkle
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Generate random stars once
    final rng = Random(42);
    _stars = List.generate(18, (_) => _StarDot(
      rng.nextDouble(),
      rng.nextDouble() * 0.35, // top 35% only
      rng.nextDouble() * 2.5 + 1.0,
      rng.nextDouble() * 2 * pi,
    ));
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _bounceController.dispose();
    _starController.dispose();
    super.dispose();
  }

  void _toggleSound() {
    setState(() {
      _soundOn = !_soundOn;
      if (_soundOn) {
        AudioManager.instance.toggleSound();
        AudioManager.instance.playClick();
      } else {
        AudioManager.instance.toggleSound();
      }
    });
  }

  void _showHighScoresDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: KidsTheme.toyDecoration(
              color: Colors.white,
              borderRadius: 30,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🏆 최고 기록 🏆',
                  style: GoogleFonts.jua(
                    fontSize: 32,
                    color: KidsTheme.orange,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: KidsTheme.toyDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: 20,
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow('1위', '9,999점', KidsTheme.yellow),
                      const SizedBox(height: 12),
                      _buildScoreRow('2위', '7,500점', KidsTheme.textLight),
                      const SizedBox(height: 12),
                      _buildScoreRow('3위', '5,200점', KidsTheme.orange),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: KidsTheme.toyDecoration(
                      color: KidsTheme.green,
                      borderRadius: 18,
                    ),
                    child: Center(
                      child: Text(
                        '닫기 닫기! 👍',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreRow(String rank, String score, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.emoji_events, color: color, size: 28),
            const SizedBox(width: 8),
            Text(
              rank,
              style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark),
            ),
          ],
        ),
        Text(
          score,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: KidsTheme.textLight,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Animated sky background ──────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_cloudController, _starController]),
            builder: (_, __) {
              return CustomPaint(
                painter: _StarPainter(_starController.value, _stars),
                child: CustomPaint(
                  painter: _CloudPainter(_cloudController.value),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF9FD8FF), // dreamy sky blue
                          Color(0xFFB8EDFF),
                          Color(0xFFFFE8F5), // soft cotton candy pink
                          Color(0xFFFFF5CC), // warm lemon cream
                        ],
                        stops: [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildGachaMachineWidget(),
                Expanded(child: _buildGamesGrid()),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gacha Machine Widget ──────────────────────────────────────────────────
  Widget _buildGachaMachineWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isPressed = false;
          return GestureDetector(
            onTapDown: (_) => setState(() => isPressed = true),
            onTapUp: (_) {
              setState(() => isPressed = false);
              AudioManager.instance.playClick();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GachaShopScreen()));
            },
            onTapCancel: () => setState(() => isPressed = false),
            child: AnimatedScale(
              scale: isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5FF),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFFBA68C8), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCE93D8).withValues(alpha: 0.6),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Globe part
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFF9C27B0), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Text('⚽🦄🎁', style: TextStyle(fontSize: 22)),
                          Positioned(
                            top: 10,
                            left: 15,
                            child: Container(
                              width: 30,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Base part / Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '장난감 뽑기방',
                            style: GoogleFonts.jua(fontSize: 26, color: const Color(0xFF6A1B9A)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 4),
                                Text(
                                  '별 모아서 팡팡!',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFBA68C8), size: 28),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8338EC).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Sound button
            _buildIconButton(
              icon: _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _soundOn
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFFFC8181),
              onTap: _toggleSound,
            ),

            const SizedBox(width: 8),

            // Center: Cute 3D Toybox Title
            Expanded(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.02).animate(
                  CurvedAnimation(
                    parent: _bounceController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🧸',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '키즈 토이 박스',
                            style: GoogleFonts.jua(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.fill
                                ..color = const Color(0xFFFF5964),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFFFF9F1C),
                                  offset: Offset(1.5, 1.5),
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
                          const SizedBox(width: 4),
                          const Text(
                            '🎁',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Subtitle Capsule Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '✨ 미니 게임 천국 ✨',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Right: Star coins
            ValueListenableBuilder<int>(
              valueListenable: PlayerDataManager.instance.starCoinsNotifier,
              builder: (context, starCoins, child) {
                return _buildStarCoinBadge(starCoins);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildStarCoinBadge(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: GoogleFonts.jua(
              fontSize: 17,
              color: Colors.white,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Games Grid ────────────────────────────────────────────────────────────
  Widget _buildGamesGrid() {
    final games = _gameData();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) => _buildGameTile(games[i]),
    );
  }

  // ── Game Tile ─────────────────────────────────────────────────────────────
  Widget _buildGameTile(_GameData game) {
    return _TappableTile(
      onTap: game.onTap,
      child: Container(
        decoration: KidsTheme.gradientDecoration(
          colors: game.gradientColors,
          borderRadius: 22,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Top-right shine blob
            Positioned(
              top: -16,
              right: -16,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
            ),
            // Bottom-left small blob
            Positioned(
              bottom: -10,
              left: -10,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  game.emoji == '🟡'
                      ? const PacmanIcon(size: 40)
                      : Text(
                          game.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      game.title,
                      style: GoogleFonts.jua(
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.15,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Trophy button (first game only)
            if (game.onTrophyTap != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: game.onTrophyTap,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Game Data ─────────────────────────────────────────────────────────────
  List<_GameData> _gameData() {
    return [
      _GameData(
        title: '풍선 팡팡',
        emoji: '🎈',
        gradientColors: KidsTheme.gameGradients['pink']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BalloonPopGame())); },
        onTrophyTap: () { AudioManager.instance.playClick(); _showHighScoresDialog(context); },
      ),
      _GameData(
        title: '모양 색칠',
        emoji: '🎨',
        gradientColors: KidsTheme.gameGradients['yellow']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShapeColoringGame())); },
      ),
      _GameData(
        title: '숨은 그림',
        emoji: '🔍',
        gradientColors: KidsTheme.gameGradients['blue']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HiddenObjectGame())); },
      ),
      _GameData(
        title: '틀린 그림',
        emoji: '🕵️',
        gradientColors: KidsTheme.gameGradients['purple']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SpotDifferenceGame())); },
      ),
      _GameData(
        title: '짝맞추기',
        emoji: '🃏',
        gradientColors: KidsTheme.gameGradients['orange']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MemoryMatchGame())); },
      ),
      _GameData(
        title: '과일 쓱싹',
        emoji: '🍉',
        gradientColors: KidsTheme.gameGradients['red']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FruitSlicerGame())); },
      ),
      _GameData(
        title: '동물 맘마',
        emoji: '🐰',
        gradientColors: KidsTheme.gameGradients['green']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedAnimalsGame())); },
      ),
      _GameData(
        title: '두더지 잡기',
        emoji: '🐹',
        gradientColors: KidsTheme.gameGradients['brown']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WhackAMoleGame())); },
      ),
      _GameData(
        title: '공룡 점프',
        emoji: '🦖',
        gradientColors: KidsTheme.gameGradients['teal']!,
        onTap: () { 
          SkinSelectModal.show(
            context,
            gameTitle: '공룡 점프',
            defaultSkin: '🦖',
            gameSkins: const ['🦕', '🐉', '🦄', '🐢'],
            onStart: (skin) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => DinoJumpGame(playerEmoji: skin)));
            },
          );
        },
      ),
      _GameData(
        title: '벽돌 깨기',
        emoji: '🧱',
        gradientColors: KidsTheme.gameGradients['indigo']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BrickBreakerGame())); },
      ),
      _GameData(
        title: '실로폰 연주',
        emoji: '🎹',
        gradientColors: KidsTheme.gameGradients['pink']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const XylophoneGame())); },
      ),
      _GameData(
        title: '비눗방울 톡톡',
        emoji: '🫧',
        gradientColors: KidsTheme.gameGradients['blue']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BubblePopGame())); },
      ),
      _GameData(
        title: '햄버거 타이쿤',
        emoji: '🍔',
        gradientColors: KidsTheme.gameGradients['amber']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BurgerMakerGame())); },
      ),
      _GameData(
        title: '탑 쌓기',
        emoji: '🏗️',
        gradientColors: KidsTheme.gameGradients['purple']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TowerBuilderGame())); },
      ),
      _GameData(
        title: '요리조리 자동차',
        emoji: '🏎️',
        gradientColors: KidsTheme.gameGradients['red']!,
        onTap: () { 
          AudioManager.instance.playClick();
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MiniRacingGame()));
        },
      ),
      _GameData(
        title: '낚시 놀이',
        emoji: '🎣',
        gradientColors: KidsTheme.gameGradients['teal']!,
        onTap: () { 
          SkinSelectModal.show(
            context,
            gameTitle: '낚시 놀이',
            defaultSkin: '🎣',
            gameSkins: const ['🧲', '🔱', '🦈', '🦑'],
            onStart: (skin) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => FishingGame(hookEmoji: skin)));
            },
          );
        },
      ),
      _GameData(
        title: '점 잇기',
        emoji: '✏️',
        gradientColors: KidsTheme.gameGradients['lime']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConnectDotsGame())); },
      ),
      _GameData(
        title: '따라 쓰기',
        emoji: '🖍️',
        gradientColors: KidsTheme.gameGradients['yellow']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TracingGame())); },
      ),
      _GameData(
        title: '직소 퍼즐',
        emoji: '🧩',
        gradientColors: KidsTheme.gameGradients['pink']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JigsawPuzzleGame())); },
      ),
      _GameData(
        title: '미로 찾기',
        emoji: '🧀',
        gradientColors: KidsTheme.gameGradients['green']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MazeEscapeGame())); },
      ),
      _GameData(
        title: '블럭 조립',
        emoji: '🧱',
        gradientColors: KidsTheme.gameGradients['orange']!,
        onTap: () { AudioManager.instance.playClick(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BlockBuilderGame())); },
      ),
      _GameData(
        title: '팩맨 탐험',
        emoji: '🟡',
        gradientColors: KidsTheme.gameGradients['amber']!,
        onTap: () {
          SkinSelectModal.show(
            context,
            gameTitle: '팩맨 탐험',
            defaultSkin: '🟡',
            gameSkins: const ['🐥', '🐱', '🐶', '🐸'],
            onStart: (skin) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PacmanGame(playerSkin: skin)));
            },
          );
        },
      ),
      _GameData(
        title: '지렁이 탐험',
        emoji: '🐛',
        gradientColors: KidsTheme.gameGradients['lime']!,
        onTap: () {
          SkinSelectModal.show(
            context,
            gameTitle: '지렁이 탐험',
            defaultSkin: '🐛',
            gameSkins: const ['🐍', '🐲', '🦄', '🐊'],
            onStart: (skin) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => SnakeGame(playerSkin: skin)));
            },
          );
        },
      ),
    ];
  }
}

// ─── Tappable Tile with press animation ──────────────────────────────────────
class _TappableTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TappableTile({required this.child, required this.onTap});

  @override
  State<_TappableTile> createState() => _TappableTileState();
}

class _TappableTileState extends State<_TappableTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─── Game Data Model ──────────────────────────────────────────────────────────
class _GameData {
  final String title;
  final String emoji;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final VoidCallback? onTrophyTap;

  _GameData({
    required this.title,
    required this.emoji,
    required this.gradientColors,
    required this.onTap,
    this.onTrophyTap,
  });
}
