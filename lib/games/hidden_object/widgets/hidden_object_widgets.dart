part of '../hidden_object_game.dart';

class _ThemeBackgroundWidget extends StatelessWidget {
  final int level;
  final double ambientVal;

  const _ThemeBackgroundWidget({
    required this.level,
    required this.ambientVal,
  });

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case 1:
        return CustomPaint(painter: _ForestBackgroundPainter(ambientVal: ambientVal));
      case 2:
        return CustomPaint(painter: _OceanBackgroundPainter(ambientVal: ambientVal));
      case 3:
        return CustomPaint(painter: _SpaceBackgroundPainter(ambientVal: ambientVal));
      case 4:
        return CustomPaint(painter: _DinoBackgroundPainter(ambientVal: ambientVal));
      case 5:
        return CustomPaint(painter: _CandyBackgroundPainter(ambientVal: ambientVal));
      case 6:
        return CustomPaint(painter: _FarmBackgroundPainter(ambientVal: ambientVal));
      case 7:
        return CustomPaint(painter: _CastleBackgroundPainter(ambientVal: ambientVal));
      case 9:
        return CustomPaint(painter: _WinterBackgroundPainter(ambientVal: ambientVal));
      case 10:
        return CustomPaint(painter: _SpookyBackgroundPainter(ambientVal: ambientVal));
      case 11:
        return CustomPaint(painter: _JungleBackgroundPainter(ambientVal: ambientVal));
      case 12:
        return CustomPaint(painter: _MagicForestBackgroundPainter(ambientVal: ambientVal));
      case 8:
      default:
        return CustomPaint(painter: _ParkBackgroundPainter(ambientVal: ambientVal));
    }
  }
}

// 🌲 Level 1: 숲속 탐험 배경 렌더러 (동화 속 초록 동산과 반딧불이)
class _HiddenItemWidget extends StatefulWidget {
  final HiddenItem item;
  final bool isHinted;
  final VoidCallback onTap;

  const _HiddenItemWidget({required this.item, required this.isHinted, required this.onTap});

  @override
  State<_HiddenItemWidget> createState() => _HiddenItemWidgetState();
}

class _HiddenItemWidgetState extends State<_HiddenItemWidget> with TickerProviderStateMixin {
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late AnimationController _animCtrl;

  // Creature movement types
  bool get _isButterfly => ['🦋', '🐝', '🕊️', '🦉', '🐞', '🦇', '🧚', '🦢', '🦚'].contains(widget.item.emoji);
  bool get _isFish => ['🐠', '🐳', '🐬', '🐙', '🦀', '🦈', '🐡'].contains(widget.item.emoji);
  bool get _isAnimal => ['🦊', '🐰', '🐿️', '🐻', '🐹', '🐧', '🐻‍❄️', '🦌', '🐺', '🐈‍⬛', '🦁', '🐒', '🐯', '🐘', '🦒', '🦓'].contains(widget.item.emoji);
  bool get _isSpaceObj => ['👽', '🛸', '🚀', '👨‍🚀', '🤖', '🛰️', '👻', '⛄'].contains(widget.item.emoji);

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    // Continuous creature animation
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _isButterfly ? 1200 : _isFish ? 2500 : _isAnimal ? 1600 : 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    if (!widget.item.isTarget && !widget.item.isFound) {
      _shakeCtrl.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double timeMs = DateTime.now().millisecondsSinceEpoch / 1000.0;

    return AnimatedScale(
      scale: widget.item.isFound ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInBack,
      child: AnimatedOpacity(
        opacity: widget.item.isFound ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shakeAnim, _animCtrl]),
            builder: (context, child) {
              final double t = _animCtrl.value;

              // Creature-specific realistic dynamic physics
              double offsetX = 0.0;
              double offsetY = 0.0;
              double scaleX = 1.0;
              double scaleY = 1.0;
              double skewX = 0.0;
              double rotation = widget.item.angle + _shakeAnim.value;
              Matrix4 transformMatrix = Matrix4.identity();

              if (_isButterfly) {
                // 🦋 나비/벌/새: 3D 날개 입체 펄럭임 (3D Perspective Flapping & S-Curve Flight)
                offsetX = sin(timeMs * 2.5) * 16.0;
                offsetY = cos(timeMs * 3.0) * 10.0;
                rotation += sin(timeMs * 2.5) * 0.12;

                // 3D Perspective Rotation for Wing Flap
                final double wingAngle = sin(timeMs * 18.0) * 0.75;
                transformMatrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.003) // Perspective distortion
                  ..rotateY(wingAngle);
              } else if (_isFish) {
                // 🐠 물고기/돌고래: 꼬리 살랑살랑 파동 유영 (Sinusoidal Tail Wiggle & Dynamic Swim)
                final double swimDirection = sin(timeMs * 1.2) > 0 ? 1.0 : -1.0;
                offsetX = (t - 0.5) * 36.0;
                offsetY = sin(timeMs * 2.5) * 6.0;
                scaleX = swimDirection;

                // Tail & Fin Wiggle Wave Distortion
                skewX = sin(timeMs * 10.0) * 0.18;
                rotation += sin(timeMs * 8.0) * 0.08;
              } else if (_isAnimal) {
                // 🦊 짐승/동물: 실감 나는 걸음걸이 (Walking Gait Cycle)
                final double walkCycle = sin(timeMs * 9.0);
                final double walkStep = (walkCycle).abs();

                offsetX = (t - 0.5) * 32.0;
                scaleY = 1.0 - (walkStep * 0.12);
                scaleX = 1.0 + (walkStep * 0.08);

                offsetY = -walkStep * 8.0;
                rotation += walkCycle * 0.14;
                skewX = walkCycle * 0.08;
              } else if (_isSpaceObj) {
                // 👽 외계인/우주선: 무중력 두둥실 플로팅
                offsetX = cos(timeMs * 1.5) * 15.0;
                offsetY = sin(timeMs * 1.5) * 15.0;
                rotation += sin(timeMs * 1.0) * 0.25;
              } else if (['🍃', '🍂', '🌿', '🌻', '🌷', '☘️', '🍄'].contains(widget.item.emoji)) {
                // 🍃 잎사귀/꽃/바람: 바람에 나풀나풀 흩날리며 춤추는 살랑살랑 모션
                final double phase = (widget.item.x * 20);
                offsetX = sin(timeMs * 2.0 + phase) * 12.0;
                offsetY = cos(timeMs * 1.8 + phase) * 6.0;
                rotation += sin(timeMs * 3.0 + phase) * 0.25;
              } else if (['🫧', '🌊', '🪸', '🐚', '💎'].contains(widget.item.emoji)) {
                // 🫧 거품/바닷속 보석: 수중에서 퐁퐁 솟아오르고 두둥실 피어나는 모션
                final double phase = (widget.item.y * 15);
                offsetY = sin(timeMs * 3.5 + phase) * 10.0;
                scaleX = 0.9 + 0.2 * sin(timeMs * 4.0 + phase);
                scaleY = 0.9 + 0.2 * cos(timeMs * 4.0 + phase);
              } else if (['⭐', '✨', '💫', '🌟', '🪐', '🌙', '🔮'].contains(widget.item.emoji)) {
                // ⭐ 별/반짝이: 우주 속에서 핑글핑글 반짝이며 두둥실 부유하는 트윈클 모션
                final double phase = (widget.item.x * 30);
                offsetX = sin(timeMs * 1.5 + phase) * 10.0;
                offsetY = cos(timeMs * 1.5 + phase) * 10.0;
                rotation += (timeMs * 0.8 + phase) % (pi * 2);
                scaleX = 0.85 + 0.3 * sin(timeMs * 5.0 + phase);
                scaleY = 0.85 + 0.3 * sin(timeMs * 5.0 + phase);
              }

              return Transform.translate(
                offset: Offset(offsetX, offsetY),
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transformMatrix,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.skew(skewX, 0.0),
                      child: Transform.scale(
                        scaleX: scaleX,
                        scaleY: scaleY,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
padding: const EdgeInsets.all(12),
                          color: Colors.transparent,
                          decoration: widget.isHinted
                              ? BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.yellowAccent.withValues(alpha: 0.8),
                                      blurRadius: 20,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                )
                              : null,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            child: _AnimatedCreatureWidget(
              emoji: widget.item.emoji,
              size: widget.item.size,
              timeMs: timeMs,
              isFound: widget.item.isFound,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Multi-Part Animated Creature Renderer
// ─────────────────────────────────────────────

class _AnimatedCreatureWidget extends StatelessWidget {
  final String emoji;
  final double size;
  final double timeMs;
  final bool isFound;

  const _AnimatedCreatureWidget({
    required this.emoji,
    required this.size,
    required this.timeMs,
    required this.isFound,
  });

  @override
  Widget build(BuildContext context) {
    if (emoji == '🦉' || emoji == '🕊️' || emoji == '🦅') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _OwlPainter(timeMs: timeMs),
      );
    } else if (emoji == '🐰') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _RabbitPainter(timeMs: timeMs),
      );
    } else if (emoji == '🦊') {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _FoxPainter(timeMs: timeMs),
      );
    } else if (['🐠', '🐬', '🐳', '🦈'].contains(emoji)) {
      return CustomPaint(
        size: Size(size * 1.4, size * 1.4),
        painter: _FishPainter(timeMs: timeMs, emoji: emoji),
      );
    }

    // Fallback cute emoji
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}

// ── 🦉 Owl Painter (Flapping Wings + Big Eyes + Body) ───────────────────────
