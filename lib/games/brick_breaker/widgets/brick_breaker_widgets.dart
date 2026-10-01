part of '../brick_breaker_game.dart';


class _ActiveItemChip extends StatelessWidget {
  final String label;
  final double secs;
  final Color color;

  const _ActiveItemChip({required this.label, required this.secs, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        '$label ${secs.toStringAsFixed(1)}s',
        style: GoogleFonts.jua(fontSize: 11, color: Colors.white),
      ),
    );
  }
}

