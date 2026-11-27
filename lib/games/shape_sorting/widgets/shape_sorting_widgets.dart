part of '../shape_sorting_game.dart';

/// 고급 원목 장난감 판 모서리 금장/황동 리벳 핀
class _WoodPeg extends StatelessWidget {
  const _WoodPeg();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.35),
          radius: 0.85,
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFCA28),
            Color(0xFFF57F17),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFF8E1), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40795548),
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

/// 말풍선 꼬리 및 아기자기한 사운드 웨이브 배지 위젯
class _VoiceWaveBadge extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _VoiceWaveBadge({
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? const [Color(0xFFFF80AB), Color(0xFFFF4081)]
                : const [Color(0xFFFFCA28), Color(0xFFFFA000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.pink : Colors.amber).withValues(alpha: 0.32),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.volume_up_rounded : Icons.record_voice_over_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '힌트듣기',
              style: GoogleFonts.jua(
                fontSize: 12.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
