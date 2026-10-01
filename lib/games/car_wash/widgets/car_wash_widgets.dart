part of '../car_wash_game.dart';

class _CarSelectTile extends StatelessWidget {
  final _Vehicle vehicle;
  final VoidCallback onTap;

  const _CarSelectTile({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              vehicle.bodyColor.withValues(alpha: 0.25),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: vehicle.bodyColor.withValues(alpha: 0.6), width: 3),
          boxShadow: [
            BoxShadow(
              color: vehicle.bodyColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(vehicle.emoji, style: const TextStyle(fontSize: 62)),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        vehicle.label,
                        style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.textDark, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Mud badge indicating dirty status
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF795548),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text('먼지 퐁퐁! 💩', style: GoogleFonts.jua(fontSize: 9, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarCanvas extends StatelessWidget {
  final _Vehicle vehicle;
  final _WashStep step;
  final List<double> dirtGrid;
  final List<double> soapGrid;
  final List<double> wetGrid;
  final List<double> shineGrid;
  final List<_Droplet> drops;
  final List<_Bubble> bubbles;
  final List<_Spark> sparks;
  final List<_Sticker> stickers;
  final int gridN;
  final Offset? toolPos;
  final bool isToolActive;
  final double idlePhase;

  const _CarCanvas({
    required this.vehicle,
    required this.step,
    required this.dirtGrid,
    required this.soapGrid,
    required this.wetGrid,
    required this.shineGrid,
    required this.drops,
    required this.bubbles,
    required this.sparks,
    required this.stickers,
    required this.gridN,
    required this.toolPos,
    required this.isToolActive,
    required this.idlePhase,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Car Emoji + Masked Dirt + Masked Wet + Masked Soap + Masked Shine (Strictly clipped to car silhouette)
        Positioned.fill(
          child: CustomPaint(
            painter: _CarMaskedPainter(
              vehicle: vehicle,
              step: step,
              dirtGrid: dirtGrid,
              soapGrid: soapGrid,
              wetGrid: wetGrid,
              shineGrid: shineGrid,
              gridN: gridN,
            ),
          ),
        ),

        // Droplets + bubbles + sparks (water drops & sparks floating)
        Positioned.fill(
          child: CustomPaint(
            painter: _ParticlePainter(drops: drops, bubbles: bubbles, sparks: sparks),
          ),
        ),

        // Stickers
        for (final s in stickers)
          Positioned.fill(
            child: IgnorePointer(
              child: FractionallySizedBox(
                alignment: Alignment(s.rel.dx * 2 - 1, s.rel.dy * 2 - 1),
                widthFactor: 0.18,
                heightFactor: 0.32,
                child: FittedBox(
                  child: Text(s.emoji, style: const TextStyle(fontSize: 100)),
                ),
              ),
            ),
          ),

        // Real-time Dynamic Interactive Wash Tool (Hose Gun / Foam Brush / Shower / Microfiber Towel)
        if (step == _WashStep.water || step == _WashStep.soap || step == _WashStep.rinse || step == _WashStep.dry)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WashToolPainter(
                  step: step,
                  toolPos: toolPos,
                  isActive: isToolActive,
                  idlePhase: idlePhase,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Car Masked Painter (Alpha Silhouette Clipping) ───────────────────────────
class _StepBanner extends StatelessWidget {
  final String text;
  final Color color;
  const _StepBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.jua(fontSize: 20, color: Colors.white,
          shadows: [const Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
        ),
      ),
    );
  }
}

// ── Big Button ─────────────────────────────────────────────────────────────────
class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Text(label, style: GoogleFonts.jua(fontSize: 20, color: Colors.white)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔥 PREMIUM PHOTOREALISTIC WASH TOOL PAINTER (Full metallic, gradient, shadow)
// ═══════════════════════════════════════════════════════════════════════════════

class _CarWashBayBackground extends StatelessWidget {
  final _WashStep step;
  final double idlePhase;
  final double groundH;

  const _CarWashBayBackground({
    required this.step,
    required this.idlePhase,
    required this.groundH,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CarWashBayPainter(
        step: step,
        idlePhase: idlePhase,
        groundH: groundH,
      ),
    );
  }
}

