part of '../firefighter_game.dart';

extension _FirefighterStageExtension on _FirefighterGameState {
  Widget _buildPhaseContent() {
    switch (_phase) {
      case FireGamePhase.missionSelect:
        return _buildMissionSelectView();
      case FireGamePhase.dispatch:
        return _buildDispatchView();
      case FireGamePhase.extinguish:
        return _buildExtinguishView();
      case FireGamePhase.rescue:
        return _buildRescueView();
      case FireGamePhase.celebrate:
        return _buildCelebrateView();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // DYNAMIC LIVELY SKY BACKGROUND
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildSceneBackground() {
    List<Color> skyColors;
    if (_phase == FireGamePhase.missionSelect) {
      skyColors = const [Color(0xFF67B6FF), Color(0xFFA5E6FF), Color(0xFFFFF9E6)];
    } else {
      skyColors = _currentMission.skyGradient;
    }

    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: skyColors,
        ),
      ),
      child: Stack(
        children: [
          // ☀️ Warm Sunshine
          Positioned(
            top: 14,
            right: 18,
            child: AnimatedBuilder(
              animation: _sunAnimCtrl,
              builder: (context, child) {
                final scale = 1.0 + (_sunAnimCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD166),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD166).withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ☁️ Drifting Fluffy Animated Clouds
          AnimatedBuilder(
            animation: _cloudAnimCtrl,
            builder: (context, child) {
              final progress = _cloudAnimCtrl.value;
              final c1x = (progress * (width + 120)) - 60;
              final c2x = (((progress + 0.5) % 1.0) * (width + 140)) - 70;

              return Stack(
                children: [
                  Positioned(
                    top: 28,
                    left: c1x,
                    child: Opacity(
                      opacity: 0.85,
                      child: Text('☁️', style: TextStyle(fontSize: 44, color: Colors.white.withValues(alpha: 0.95))),
                    ),
                  ),
                  Positioned(
                    top: 72,
                    left: c2x,
                    child: Opacity(
                      opacity: 0.75,
                      child: Text('☁️', style: TextStyle(fontSize: 34, color: Colors.white.withValues(alpha: 0.90))),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UNIFIED TOP APP BAR
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildTopAppBar() {
    final extinguishedCount = _currentMission.spots.where((s) => s.isExtinguished).length;
    final totalSpots = _currentMission.spots.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 🏠 Home / Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AudioManager.instance.playClick();
                if (_phase == FireGamePhase.missionSelect) {
                  Navigator.of(context).pop();
                } else {
                  _safeSetState(() {
                    _phase = FireGamePhase.missionSelect;
                  });
                }
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFF5964), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back_rounded, color: Color(0xFFFF5964), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      _phase == FireGamePhase.missionSelect ? '로비로' : '미션 목록',
                      style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2B2D42)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title or In-Game Extinguish Progress Pill
          if (_phase == FireGamePhase.extinguish)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💧', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '진압: $extinguishedCount / $totalSpots',
                    style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF0284C7)),
                  ),
                ],
              ),
            )
          else
            AnimatedBuilder(
              animation: _sirenLightCtrl,
              builder: (context, child) {
                final isRed = _sirenLightCtrl.value > 0.5;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isRed ? const Color(0xFFFF3366) : const Color(0xFF3399FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isRed ? const Color(0xFFFF3366) : const Color(0xFF3399FF)).withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(isRed ? '🚨' : '🚒', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        '출동! 꼬마 소방대',
                        style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF2B2D42)),
                      ),
                    ],
                  ),
                );
              },
            ),

          // 🔊 Sound Toggle Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _safeSetState(() {
                  AudioManager.instance.toggleSound();
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF9F1C), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFFFF9F1C),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
