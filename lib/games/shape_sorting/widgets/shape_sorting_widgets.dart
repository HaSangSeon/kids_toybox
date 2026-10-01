part of '../shape_sorting_game.dart';

/// 원목 고정 핀 (원목 장난감 판 모서리 핀)
class _WoodPeg extends StatelessWidget {
  const _WoodPeg();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFA000), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), offset: Offset(0, 1.5), blurRadius: 1),
        ],
      ),
    );
  }
}

