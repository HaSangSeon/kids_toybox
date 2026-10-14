part of '../fishing_game_game.dart';

// ── 낚싯줄 커스텀 페인터 ──
class FishingLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  FishingLinePainter({required this.start, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);

    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2 + 6;
    path.quadraticBezierTo(midX, midY, end.dx, end.dy);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant FishingLinePainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}

