import 'dart:math';
import 'package:flutter/material.dart';

class PacmanIcon extends StatefulWidget {
  final double size;
  const PacmanIcon({super.key, this.size = 40.0});

  @override
  State<PacmanIcon> createState() => _PacmanIconState();
}

class _PacmanIconState extends State<PacmanIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PacmanIconPainter(_controller.value),
        );
      },
    );
  }
}

class _PacmanIconPainter extends CustomPainter {
  final double mouthOpenRatio; // 0.0 (closed) to 1.0 (fully open)
  _PacmanIconPainter(this.mouthOpenRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFACC15) // Authentic Pacman Yellow
      ..style = PaintingStyle.fill;

    // Pacman is looking to the right.
    // When mouth is fully open, the slice is 0.25 * pi.
    // To ensure it never looks like a plain yellow circle, don't let it close fully.
    final double maxMouthAngle = 0.22 * pi; 
    final double minMouthAngle = 0.04 * pi;
    final double halfMouthAngle = minMouthAngle + (maxMouthAngle - minMouthAngle) * mouthOpenRatio;

    final double startAngle = halfMouthAngle;
    final double sweepAngle = 2 * pi - (2 * halfMouthAngle);

    // Draw Pacman body (facing right)
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      startAngle,
      sweepAngle,
      true,
      paint,
    );

    // Draw eye (bigger and more visible)
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.25),
      size.width * 0.1,
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(_PacmanIconPainter oldDelegate) =>
      oldDelegate.mouthOpenRatio != mouthOpenRatio;
}
