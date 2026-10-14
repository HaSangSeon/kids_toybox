part of '../fishing_game_game.dart';

// ── 실시간 관절 꼬리 흔들기 물고기 위젯 ──
class _SegmentedWigglingFish extends StatelessWidget {
  final String emoji;
  final double fontSize;
  final double swimTimer;
  final bool isLarge;
  final Color? textColor;

  const _SegmentedWigglingFish({
    required this.emoji,
    required this.fontSize,
    required this.swimTimer,
    this.isLarge = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: fontSize, color: textColor);

    if (emoji == '🪨' || emoji == '👟' || emoji == '🥫' || emoji == '🍾') {
      return Text(emoji, style: style);
    }

    final isVertical = emoji == '🪼' || emoji == '🦑' || emoji == '🐙';
    if (isVertical) {
      const freq = 5.0;
      final sway = sin(swimTimer * freq) * 0.18;
      final pulse = 1.0 + 0.10 * sin(swimTimer * freq);

      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRect(
            clipper: _VerticalSliceClipper(topRatio: 0.0, bottomRatio: 0.55),
            child: Text(emoji, style: style),
          ),
          Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..rotateZ(sway)
              ..multiply(Matrix4.diagonal3Values(1.0, pulse, 1.0)),
            child: ClipRect(
              clipper: _VerticalSliceClipper(topRatio: 0.42, bottomRatio: 1.0),
              child: Text(emoji, style: style),
            ),
          ),
        ],
      );
    }

    final freq = isLarge ? 5.5 : 9.0;
    final maxAngle = isLarge ? 0.22 : 0.35;
    final tailAngle = sin(swimTimer * freq) * maxAngle;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ClipRect(
          clipper: _HorizontalSliceClipper(leftRatio: 0.0, rightRatio: 0.55),
          child: Text(emoji, style: style),
        ),
        Transform(
          alignment: const Alignment(-0.12, 0.0),
          transform: Matrix4.identity()..rotateZ(tailAngle),
          child: ClipRect(
            clipper: _HorizontalSliceClipper(leftRatio: 0.42, rightRatio: 1.0),
            child: Text(emoji, style: style),
          ),
        ),
      ],
    );
  }
}

class _HorizontalSliceClipper extends CustomClipper<Rect> {
  final double leftRatio;
  final double rightRatio;

  _HorizontalSliceClipper({required this.leftRatio, required this.rightRatio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * leftRatio,
      -20,
      size.width * rightRatio,
      size.height + 20,
    );
  }

  @override
  bool shouldReclip(covariant _HorizontalSliceClipper oldDelegate) {
    return oldDelegate.leftRatio != leftRatio || oldDelegate.rightRatio != rightRatio;
  }
}

class _VerticalSliceClipper extends CustomClipper<Rect> {
  final double topRatio;
  final double bottomRatio;

  _VerticalSliceClipper({required this.topRatio, required this.bottomRatio});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      -20,
      size.height * topRatio,
      size.width + 20,
      size.height * bottomRatio,
    );
  }

  @override
  bool shouldReclip(covariant _VerticalSliceClipper oldDelegate) {
    return oldDelegate.topRatio != topRatio || oldDelegate.bottomRatio != bottomRatio;
  }
}

