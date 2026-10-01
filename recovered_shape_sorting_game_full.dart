import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';

part 'models/shape_sorting_models.dart';
part 'widgets/shape_sorting_widgets.dart';
part 'painters/shape_sorting_painters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shape Sorting Game — 모양 쏙쏙! (4~5세 톡톡 쉬운 놀이)
// ─────────────────────────────────────────────────────────────────────────────

class ShapeSortingGame extends StatefulWidget {
  const ShapeSortingGame({super.key});

  @override
  State<ShapeSortingGame> createState() => _ShapeSortingGameState();
}

class _ShapeSortingGameState extends State<ShapeSortingGame> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  int _level = 1; // 1 ~ 5 단계
  bool _showingLevelComplete = false;

  late List<_ShapeInfo> _roundShapes;
  late List<ShapeType> _remainingPieces;
  final Set<ShapeType> _filledShapes = {};
  ShapeType? _justSnappedShape;
  final Random _rng = Random();

  static const List<_ShapeInfo> _allShapes = [
    _ShapeInfo(type: ShapeType.triangle, label: '세모', emoji: '🔺', color: Color(0xFFFF5252), shadowColor: Color(0xFFD32F2F)),
    _ShapeInfo(type: ShapeType.square, label: '네모', emoji: '🟧', color: Color(0xFFFF9800), shadowColor: Color(0xFFF57C00)),
    _ShapeInfo(type: ShapeType.circle, label: '동그라미', emoji: '🔵', color: Color(0xFF29B6F6), shadowColor: Color(0xFF0288D1)),
    _ShapeInfo(type: ShapeType.star, label: '별', emoji: '⭐', color: Color(0xFFFFCA28), shadowColor: Color(0xFFFFA000)),
    _ShapeInfo(type: ShapeType.heart, label: '하트', emoji: '❤️', color: Color(0xFFFF4081), shadowColor: Color(0xFFC2185B)),
    _ShapeInfo(type: ShapeType.diamond, label: '마름모', emoji: '💎', color: Color(0xFFAB47BC), shadowColor: Color(0xFF7B1FA2)),
    _ShapeInfo(type: ShapeType.hexagon, label: '육각형', emoji: '⬡', color: Color(0xFF26A69A), shadowColor: Color(0xFF00796B)),
    _ShapeInfo(type: ShapeType.pentagon, label: '오각형', emoji: '⬠', color: Color(0xFF5C6BC0), shadowColor: Color(0xFF3949AB)),
    _ShapeInfo(type: ShapeType.cross, label: '십자', emoji: '➕', color: Color(0xFF66BB6A), shadowColor: Color(0xFF388E3C)),
    _ShapeInfo(type: ShapeType.moon, label: '달', emoji: '🌙', color: Color(0xFF8E24AA), shadowColor: Color(0xFF6A1B9A)),
    _ShapeInfo(type: ShapeType.bear, label: '곰', emoji: '🐻', color: Color(0xFF8D6E63), shadowColor: Color(0xFF5D4037)),
    _ShapeInfo(type: ShapeType.rabbit, label: '토끼', emoji: '🐰', color: Color(0xFFF48FB1), shadowColor: Color(0xFFC2185B)),
    _ShapeInfo(type: ShapeType.cat, label: '고양이', emoji: '🐱', color: Color(0xFFFFB74D), shadowColor: Color(0xFFF57C00)),
    _ShapeInfo(type: ShapeType.fish, label: '물고기', emoji: '🐟', color: Color(0xFF4FC3F7), shadowColor: Color(0xFF0288D1)),
    _ShapeInfo(type: ShapeType.bird, label: '새', emoji: '🐦', color: Color(0xFF81C784), shadowColor: Color(0xFF388E3C)),
    _ShapeInfo(type: ShapeType.flower, label: '꽃', emoji: '🌸', color: Color(0xFFF06292), shadowColor: Color(0xFFC2185B)),
    _ShapeInfo(type: ShapeType.tree, label: '나무', emoji: '🌳', color: Color(0xFF4CAF50), shadowColor: Color(0xFF2E7D32)),
    _ShapeInfo(type: ShapeType.cloud, label: '구름', emoji: '☁️', color: Color(0xFFE0E0E0), shadowColor: Color(0xFF9E9E9E)),
    _ShapeInfo(type: ShapeType.car, label: '자동차', emoji: '🚗', color: Color(0xFFE53935), shadowColor: Color(0xFFB71C1C)),
    _ShapeInfo(type: ShapeType.boat, label: '배', emoji: '⛵', color: Color(0xFF039BE5), shadowColor: Color(0xFF01579B)),
    _ShapeInfo(type: ShapeType.house, label: '집', emoji: '🏠', color: Color(0xFFFFB300), shadowColor: Color(0xFFFF8F00)),
    _ShapeInfo(type: ShapeType.castle, label: '성', emoji: '🏰', color: Color(0xFF9C27B0), shadowColor: Color(0xFF6A1B9A)),
  ];

  int get _shapeCountForLevel {
    switch (_level) {
      case 1: return 2;
      case 2: return 3;
      case 3: return 4;
      case 4: return 5;
      default: return 6;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -3.0, end: 3.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _startNewRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _startNewRound() {
    final count = _shapeCountForLevel;
    final shuffled = List<_ShapeInfo>.from(_allShapes)..shuffle(_rng);
    _roundShapes = shuffled.take(count).toList();

    final pieceTypes = _roundShapes.map((s) => s.type).toList()..shuffle(_rng);
    _remainingPieces = pieceTypes;
    _filledShapes.clear();
    _justSnappedShape = null;
    _showingLevelComplete = false;

    setState(() {});
  }

  void _onShapeSnapped(ShapeType type) {
    AudioManager.instance.playPop();
    setState(() {
      _remainingPieces.remove(type);
      _filledShapes.add(type);
      _justSnappedShape = type;
    });

    if (_remainingPieces.isEmpty) {
      AudioManager.instance.playSuccess();
      _confettiController.play();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() { _showingLevelComplete = true; });
      });
    }
  }

  void _nextRound() {
    if (_level < 5) _level++;
    _startNewRound();
  }

  _ShapeInfo _getShapeInfo(ShapeType type) {
    return _allShapes.firstWhere((s) => s.type == type);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFBEA), Color(0xFFF0F9FF), Color(0xFFFFF0F5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _CharmingPlayroomBackgroundPainter())),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 6),
                    _buildInstructionBanner(),
                    const SizedBox(height: 10),
                    Expanded(child: Center(child: _buildPuzzleBoard())),
                    const SizedBox(height: 12),
                    _buildPieceTray(),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 35,
                  colors: const [Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D), Color(0xFF95E1D3), Color(0xFFFFA07A), Color(0xFFBA68C8)],
                ),
              ),
              if (_showingLevelComplete) _buildCompletionOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF7B7B), Color(0xFFFF4848)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [BoxShadow(color: Color(0xFFC62828), offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('모양 쏙쏙', style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '알맞은 모양을 쏙 넣어봐요! (단계 $_level)',
        style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark),
      ),
    );
  }

  Widget _buildPuzzleBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _roundShapes.length;
        final int crossAxisCount = count <= 3 ? count : (count == 4 ? 2 : 3);
        final double maxBoardW = min(constraints.maxWidth - 32, 420.0);
        final double spacing = 12.0;
        final double totalHSpacing = spacing * (crossAxisCount + 1);
        final double cardWidth = ((maxBoardW - 32) - totalHSpacing) / crossAxisCount;
        final double cardSize = cardWidth.clamp(78.0, 110.0);

        return Container(
          width: maxBoardW,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFFFE082), width: 5),
            boxShadow: const [
              BoxShadow(color: Color(0x228D6E63), offset: Offset(0, 8), blurRadius: 18),
              BoxShadow(color: Colors.white, offset: Offset(0, -3)),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: spacing,
            runSpacing: spacing,
            children: _roundShapes.map((info) => _buildSlotHole(info, cardSize)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSlotHole(_ShapeInfo info, double size) {
    final bool isFilled = _filledShapes.contains(info.type);
    final bool isJustSnapped = _justSnappedShape == info.type;

    return DragTarget<ShapeType>(
      onWillAcceptWithDetails: (details) => details.data == info.type,
      onAcceptWithDetails: (details) => _onShapeSnapped(info.type),
      builder: (context, candidateData, rejectedData) {
        final bool isHovered = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size(size * 0.9, size * 0.9), painter: _SlotHolePainter(info.type)),
              if (isHovered && !isFilled)
                Container(
                  width: size * 0.9,
                  height: size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              if (isFilled)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: isJustSnapped ? 0.0 : 1.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: CustomPaint(
                        size: Size(size * 0.8, size * 0.8),
                        painter: _ChunkyBlockPainter(
                          type: info.type,
                          color: info.color,
                          shadowColor: info.shadowColor,
                          isPlaced: true,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieceTray() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEBE9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7CCC8), width: 4),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _remainingPieces.map((type) {
              final info = _getShapeInfo(type);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedBuilder(
                  animation: _floatAnim,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: Draggable<ShapeType>(
                        data: type,
                        feedback: _buildDraggableFeedback(info),
                        childWhenDragging: Opacity(opacity: 0.3, child: _buildTrayPiece(info)),
                        child: _buildTrayPiece(info),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTrayPiece(_ShapeInfo info) {
    return CustomPaint(
      size: const Size(60, 60),
      painter: _ChunkyBlockPainter(
        type: info.type,
        color: info.color,
        shadowColor: info.shadowColor,
      ),
    );
  }

  Widget _buildDraggableFeedback(_ShapeInfo info) {
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.2,
        child: CustomPaint(
          size: const Size(70, 70),
          painter: _ChunkyBlockPainter(
            type: info.type,
            color: info.color,
            shadowColor: info.shadowColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: KidsTheme.borderDark, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 10), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 10),
                    Text('모든 모양을 쏙쏙 맞췄어요! ❤️', textAlign: TextAlign.center, style: GoogleFonts.jua(fontSize: 24, color: KidsTheme.textDark)),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        _nextRound();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KidsTheme.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(_level < 5 ? '다음 단계로' : '다시 하기', style: GoogleFonts.jua(fontSize: 22)),
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
}
