part of '../car_wash_game.dart';

extension _CarWashDrivingExtension on _CarWashGameState {
  // ── Road Driving Screen ──────────────────────────────────────────────────
  Widget _buildRoadDrivingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF29B6F6),
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full-screen Parallax Scenery (Sky, Sun, Clouds, Hills, Town, Trees, Cheering Animals, Road)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _honkCar,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RoadDrivingSceneryPainter(
                    scrollX: _roadScrollX,
                    bouncePhase: _drivingBouncePhase,
                    isBoosting: _isBoosting,
                    vehicle: _car,
                    stickers: _stickers,
                    jumpOffset: _carJumpOffset,
                    drivingSparks: _drivingSparks,
                    honkBubbleText: _honkBubbleText,
                  ),
                ),
              ),
            ),

            // 2. Top HUD Bar (Explicitly positioned at top of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildDrivingHud(),
            ),

            // 3. Interactive Kid Driving Control Buttons (Bottom)
            _buildDrivingControls(),

            // 4. Celebration Modal Dialog
            if (_showFinishDialog)
              Positioned.fill(
                child: _buildCelebrationModal(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingHud() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            // Cute Back to Car Wash Button
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                _reset();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.25),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '세차장',
                      style: GoogleFonts.jua(
                        fontSize: 15,
                        color: const Color(0xFF0277BD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Cute Vehicle Badge Title: e.g. "🚌 버스 씽씽!", "🚓 경찰차 씽씽!"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF57C00).withValues(alpha: 0.25),
                    blurRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_car.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    '${_car.label} 씽씽!',
                    style: GoogleFonts.jua(
                      fontSize: 16,
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Cute Sound Toggle Button
            GestureDetector(
              onTap: () => _safeSetState(() => AudioManager.instance.toggleSound()),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withValues(alpha: 0.25),
                      blurRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFF0288D1),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingControls() {
    // Dynamic vehicle sound button label & icon across all vehicle types!
    final (hornIcon, hornLabel) = switch (_car.id) {
      'police' => ('🚨', '사이렌!'),
      'fire' => ('🚒', '출동!'),
      'ambulance' => ('🚑', '삐뽀!'),
      'bus' => ('🚌', '빵빵!'),
      'racing' => ('🏎️', '부릉!'),
      'monster' => ('🛻', '쿠쿵!'),
      'tractor' => ('🚜', '탈탈!'),
      'taxi' => ('🚕', '손님타요!'),
      'suv' => ('🚙', '씽씽!'),
      _ => ('📢', '빵빵!'),
    };

    return Positioned.fill(
      child: SafeArea(
        child: Stack(
          children: [
            // 1. Celebration / Wash Finish Modal Button (Top Right)
            Positioned(
              top: 90,
              right: 16,
              child: _buildDrivingToyButton(
                icon: '🏆',
                label: '세차 완성!',
                bgColors: [const Color(0xFFB9F6CA), const Color(0xFF00E676)],
                shadowColor: const Color(0xFF00B248),
                textColor: const Color(0xFF1B5E20),
                isHighlight: true,
                onTap: () {
                  AudioManager.instance.playSuccessSound('audio/chime.wav', rate: 1.2);
                  _spawnConfetti();
                  _safeSetState(() => _showFinishDialog = true);
                },
              ),
            ),

            // 2. Vehicle Specific Horn / Siren Action Button (Bottom Left)
            Positioned(
              bottom: 32,
              left: 24,
              child: _buildDrivingToyButton(
                icon: hornIcon,
                label: hornLabel,
                bgColors: [const Color(0xFFFFF59D), const Color(0xFFFFD54F)],
                shadowColor: const Color(0xFFFFA000),
                textColor: const Color(0xFF5D4037),
                onTap: _honkCar,
              ),
            ),

            // 3. Speed Booster Button (Bottom Right)
            Positioned(
              bottom: 32,
              right: 24,
              child: _buildDrivingToyButton(
                icon: _isBoosting ? '🔥' : '⚡',
                label: _isBoosting ? '터보!' : '부스터!',
                bgColors: _isBoosting
                    ? [const Color(0xFFFF8A80), const Color(0xFFFF5252)]
                    : [const Color(0xFFFFCCBC), const Color(0xFFFF7043)],
                shadowColor: _isBoosting ? const Color(0xFFD50000) : const Color(0xFFD84315),
                textColor: _isBoosting ? Colors.white : const Color(0xFFBF360C),
                onTap: _triggerBooster,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrivingToyButton({
    required String icon,
    required String label,
    required List<Color> bgColors,
    required Color shadowColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: () {
        AudioManager.instance.playClick();
        onTap();
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 0,
              offset: const Offset(0, 3.5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text(icon, style: TextStyle(fontSize: isHighlight ? 21 : 18)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jua(
                  fontSize: isHighlight ? 15.5 : 14.0,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A237E), Color(0xFF0288D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.amber, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆✨🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 10),
              Text(
                '우와! 완벽한 세차 성공!',
                style: GoogleFonts.jua(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${_car.label}이(가) 반짝반짝 빛나요!\n신나게 도로를 달렸어요! 🌟',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        _safeSetState(() => _showFinishDialog = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26A69A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('🛣️ 계속 달리기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        AudioManager.instance.playClick();
                        _reset();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7043),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('🚗 다른 차 씻기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Complete Screen ────────────────────────────────────────────────────────
  Widget _buildCompleteScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF7C4DFF), Color(0xFF00BCD4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _ConfettiPainter(_confetti)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉✨🚿', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 16),
                Text('우와! 완벽한 세차 끝!',
                  style: GoogleFonts.jua(fontSize: 34, color: Colors.white, shadows: [
                    const Shadow(color: Colors.black38, offset: Offset(0, 3), blurRadius: 8),
                  ]),
                ),
                const SizedBox(height: 10),
                Text('차이가 깨끗해져서 기분이 참 좋아!',
                  style: GoogleFonts.jua(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 36),
                _BigButton(
                  label: '🚗 다른 차 또 씻기!',
                  color: const Color(0xFFFF7043),
                  onTap: _reset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
