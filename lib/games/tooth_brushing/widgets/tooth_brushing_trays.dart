part of '../tooth_brushing_game.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOOTH BRUSHING BOTTOM TRAYS UI EXTENSION
// ═══════════════════════════════════════════════════════════════════════════════

extension _ToothBrushingTraysExtension on _ToothBrushingGameState {
  Widget _buildBottomTrayContent() {
    switch (_step) {
      case BrushStep.eating:
        return _buildSnackTrayContent();
      case BrushStep.selectPaste:
        return _buildPasteTrayContent();
      case BrushStep.brushing:
        return _buildBrushingTrayContent();
      case BrushStep.rinsing:
        return _buildRinsingTrayContent();
      case BrushStep.complete:
        return _buildCompleteTrayContent();
      default:
        return const SizedBox.shrink();
    }
  }

  // Tray 1: Snack Grid & Ready-to-Brush Button
  Widget _buildSnackTrayContent() {
    if (_hasDecayed) {
      return Column(
        key: const ValueKey('tray_eating_decayed'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('간식을 더 먹이거나, 양치질을 시작해요!', style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          // Compact Snack Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _kSnacks.map((snack) {
                return GestureDetector(
                  onTap: () => _feedSnackWithEffect(snack, GlobalKey()),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade300, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(snack.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(snack.name, style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFF4E342E))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Big Shiny "Go to Brush" Button
          GestureDetector(
            onTap: _goToSelectPaste,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪥', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('치카치카 양치하러 가기!', style: GoogleFonts.jua(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('tray_eating_initial'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👇', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('먹이고 싶은 간식을 콕! 터치해요', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFFE65100), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSnackCardItem(_kSnacks[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildSnackCardItem(_kSnacks[1])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildSnackCardItem(_kSnacks[2])),
            const SizedBox(width: 8),
            Expanded(child: _buildSnackCardItem(_kSnacks[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildSnackCardItem(_Snack snack) {
    final key = GlobalKey();
    final tag = _getSnackTag(snack.name);
    return Builder(
      builder: (context) {
        return GestureDetector(
          key: key,
          onTap: () => _feedSnackWithEffect(snack, key),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFFFF8E1)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFB74D), width: 1.8),
              boxShadow: [
                BoxShadow(color: Colors.orange.withValues(alpha: 0.16), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(snack.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snack.name,
                      style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF4E342E), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      tag,
                      style: GoogleFonts.jua(fontSize: 10, color: const Color(0xFFE65100)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSnackTag(String name) {
    switch (name) {
      case '초콜릿':
        return '달콤 사르르 🍫';
      case '막대사탕':
        return '새콤 롤리팝 🍭';
      case '도넛':
        return '딸기 슈가 🍩';
      case '아이스크림':
        return '바닐라콘 🍦';
      default:
        return '달콤 간식 ✨';
    }
  }

  // Tray 2: 3 Toothpastes
  Widget _buildPasteTrayContent() {
    return Column(
      key: const ValueKey('tray_paste'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('어떤 향기의 치약으로 닦을까요?', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF00695C), fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _kPastes.map((paste) {
            return Expanded(
              child: GestureDetector(
                onTap: () => _onSelectPaste(paste),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: paste.color, width: 2.2),
                    boxShadow: [
                      BoxShadow(color: paste.color.withValues(alpha: 0.22), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: paste.foamColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(paste.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 6),
                      Text(paste.name, style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF263238))),
                      Text(paste.flavor, style: GoogleFonts.jua(fontSize: 10, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Tray 3: Brushing Progress & Guidance
  Widget _buildBrushingTrayContent() {
    final progress = _totalCleanliness;
    return Column(
      key: const ValueKey('tray_brushing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🪥 치카치카 진행률', style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF37474F))),
            Text('${(progress * 100).toInt()}%',
                style: GoogleFonts.jua(fontSize: 16, color: _paste.color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 14,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_paste.color),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _paste.foamColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('동물 친구의 치아를 문질러 거품을 내요! 🫧', style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF004D40))),
            ],
          ),
        ),
      ],
    );
  }

  // Tray 4: Water Rinse Action
  Widget _buildRinsingTrayContent() {
    return Column(
      key: const ValueKey('tray_rinsing'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('물로 거품을 깨끗하게 헹궈주세요! 💧', style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF01579B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            _onRinseSpray(const Offset(140, 140), const Size(280, 280));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF29B6F6), Color(0xFF0288D1)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: const Color(0xFF0288D1).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💧', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text('물 뿌리기 (가글가글 퉤!)', style: GoogleFonts.jua(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tray 5: Complete Reward & Replay (Enhanced with Rive 5-Star Celebration)
  Widget _buildCompleteTrayContent() {
    return Column(
      key: const ValueKey('tray_complete'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // RIVE 5-STAR & REWARD CHEST CELEBRATION
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 58,
              height: 58,
              child: RiveAnimation.asset(
                'assets/rive/rewards.riv',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 140,
              height: 55,
              child: RiveAnimation.asset(
                'assets/rive/rating.riv',
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF66BB6A), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.green.withValues(alpha: 0.15), blurRadius: 6),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                '치아가 보석처럼 반짝반짝! 특급 칭찬해요! 🌟',
                style: GoogleFonts.jua(fontSize: 14, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _resetGame,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF66BB6A), Color(0xFF43A047)]),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: Colors.green.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔄', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('다른 친구 닦아주기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
