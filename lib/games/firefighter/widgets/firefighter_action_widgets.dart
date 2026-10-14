part of '../firefighter_game.dart';

extension _FirefighterActionExtension on _FirefighterGameState {
  // ─────────────────────────────────────────────────────────────────────────────
  // 3. EXTINGUISH VIEW (Spacious & Clean, Real Fire & Hose)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildExtinguishView() {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        _safeSetState(() {
          _isSpraying = true;
          _touchPos = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        _safeSetState(() {
          _touchPos = details.localPosition;
        });
      },
      onPanEnd: (_) {
        _safeSetState(() {
          _isSpraying = false;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Spacious Scene Illustration (Starting comfortably below the header)
          _buildSceneIllustration(),

          // Fire Spots (HP Bars & Animals)
          for (final spot in _currentMission.spots)
            Positioned(
              left: spot.relativePos.dx * screenSize.width - spot.radius,
              top: spot.relativePos.dy * screenSize.height - spot.radius,
              child: _buildFireSpotWidget(spot),
            ),

          // Bottom Firefighter with Realistic Brass Nozzle & Hose
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: _buildRealisticFiremanAndHose(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneIllustration() {
    final type = _currentMission.buildingType;
    return Positioned.fill(
      child: CustomPaint(
        painter: _BuildingScenePainter(
          type: type,
          spots: _currentMission.spots,
        ),
      ),
    );
  }

  Widget _buildFireSpotWidget(FireSpot spot) {
    final isDog = spot.trappedAnimal == '🐶';
    final isRocket = _currentMission.buildingType == 'space' && spot.id == 1;

    if (spot.isExtinguished) {
      return SizedBox(
        width: spot.radius * 2,
        height: spot.radius * 2,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDog) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10),
                    ],
                  ),
                  child: const ClipOval(
                    child: RiveAnimation.asset(
                      'assets/rive/dog.riv',
                      artboard: 'Shiba',
                      animations: ['WinEndState'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF007F),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 4),
                    ],
                  ),
                  child: const Text('살았다! 💖', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ] else if (isRocket) ...[
                const SizedBox(
                  width: 52,
                  height: 52,
                  child: RiveAnimation.asset(
                    'assets/rive/rocket.riv',
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('발사 준비! 🚀', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ] else if (spot.trappedAnimal != null) ...[
                Transform.scale(
                  scale: 1.15,
                  child: Text(spot.trappedAnimal!, style: const TextStyle(fontSize: 36)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF007F),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.4), blurRadius: 4),
                    ],
                  ),
                  child: const Text('살았다! 💖', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                const Text('✨', style: TextStyle(fontSize: 28)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06D6A0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('진압 완료!', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Active Flame & Emotional Trapped Animal Pleading for Help
    final isLowHp = spot.hp < 45.0;
    final textPlea = isLowHp ? '조금만 더! 😃' : '살려줘요! 😭';

    return SizedBox(
      width: spot.radius * 2,
      height: spot.radius * 2,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 🔥 HP 게이지 — 불꽃 바로 위에 배치 (잘 보이도록)
          Positioned(
            top: -28,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.70),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🔥 ${spot.hp.toInt()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white54, width: 0.8),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (spot.hp / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: spot.hp > 60
                              ? [const Color(0xFFFF4500), const Color(0xFFFF8C00)]
                              : spot.hp > 30
                                  ? [const Color(0xFFFF8C00), const Color(0xFFFFD700)]
                                  : [const Color(0xFF00E676), const Color(0xFF69F0AE)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Trapped animal with shivering, teardrops, and crying speech bubble
          if (spot.trappedAnimal != null)
            Positioned(
              top: 15,
              child: Column(
                children: [
                  // Cute Pulsing Speech Bubble
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isLowHp ? Colors.orangeAccent : Colors.redAccent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          textPlea,
                          style: GoogleFonts.jua(fontSize: 10, color: isLowHp ? Colors.deepOrange : Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Shivering Animal Face (Rive Shiba for Dog, Emoji for Others)
                  if (isDog)
                    Transform.translate(
                      offset: Offset(sin(spot.flamePhase * 8.0) * 1.8, 0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 6),
                          ],
                        ),
                        child: const ClipOval(
                          child: RiveAnimation.asset(
                            'assets/rive/dog.riv',
                            artboard: 'Shiba',
                            animations: ['Anim_shiba'],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  else
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Transform.translate(
                          offset: Offset(sin(spot.flamePhase * 8.0) * 1.5, 0),
                          child: Text(spot.trappedAnimal!, style: const TextStyle(fontSize: 28)),
                        ),
                        if (!isLowHp) ...[
                          // Left & Right Splashing Tears
                          Positioned(
                            left: -6,
                            top: 4,
                            child: Transform.rotate(
                              angle: -0.4,
                              child: const Text('💧', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          Positioned(
                            right: -6,
                            top: 4,
                            child: Transform.rotate(
                              angle: 0.4,
                              child: const Text('💧', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

        ],
      ),
    );
  }

  Widget _buildRealisticFiremanAndHose() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 노즐 조준 각도 계산 (기본 위쪽 -90도, 터치 시 터치 지점을 향해 회전)
    double nozzleAngle = -pi / 2;
    if (_touchPos != null) {
      final nozzleBaseGlobalX = screenWidth * 0.5;
      final nozzleBaseGlobalY = screenHeight - 65;
      final dx = _touchPos!.dx - nozzleBaseGlobalX;
      final dy = _touchPos!.dy - nozzleBaseGlobalY;
      // 터치 각도 제한 (좌우 65도 범위 내로 자연스럽게 조준)
      final rawAngle = atan2(dy, dx);
      nozzleAngle = rawAngle.clamp(-pi * 0.85, -pi * 0.15);
    }

    return SizedBox(
      width: screenWidth,
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 💧 실감나는 중장비 소방 호스 & 황동 관창 노즐 & 소방관
          Positioned.fill(
            child: CustomPaint(
              painter: _FireHosePainter(
                nozzleAngle: nozzleAngle,
                isSpraying: _isSpraying,
                screenWidth: screenWidth,
              ),
            ),
          ),

          // 💬 하단 진압 안내 및 상태 뱃지
          Positioned(
            bottom: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _isSpraying
                    ? const Color(0xFF0284C7).withValues(alpha: 0.92)
                    : const Color(0xFF0F172A).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSpraying ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isSpraying
                        ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isSpraying ? '💦' : '🎯', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    _isSpraying ? '고압 물대포 발사 중!' : '불이 난 곳을 터치하여 진압하세요!',
                    style: GoogleFonts.jua(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. RESCUE VIEW (Adorable Parachute & Golden Safety Trampoline)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildRescueView() {
    final screenSize = MediaQuery.of(context).size;
    final animalX = _fallingAnimalX * screenSize.width;
    final animalY = _fallingAnimalY * screenSize.height;
    final trampolinePixelX = _trampolineX * screenSize.width;
    final isDog = _currentMission.rescuedAnimal == '🐶';

    // Gentle pendulum sway while floating down
    final swayAngle = sin(_fallingAnimalY * 20.0) * 0.14;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) {
        _safeSetState(() {
          _trampolineX = (details.localPosition.dx / screenSize.width).clamp(0.15, 0.85);
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildSceneIllustration(),

          // Floating Baby Animal with Parachute & Sparkles
          Positioned(
            left: animalX - (isDog ? 42 : 38),
            top: animalY - (isDog ? 68 : 60),
            child: Transform.rotate(
              angle: _isRescued ? 0.0 : swayAngle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🪂 Colorful Striped Parachute Canopy
                  if (!_isRescued) ...[
                    Container(
                      width: 80,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5964),
                            Color(0xFFFFD166),
                            Color(0xFF06D6A0),
                            Color(0xFF118AB2),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('🪂', style: TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Cute Animal with Sparkles & Heart Reaction (Rive for Dog)
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (isDog)
                        Container(
                          width: _isRescued ? 82 : 64,
                          height: _isRescued ? 82 : 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isRescued ? const Color(0xFFFFB703) : Colors.white,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRescued ? const Color(0xFFFFB703) : Colors.black).withValues(alpha: 0.25),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: RiveAnimation.asset(
                              'assets/rive/dog.riv',
                              artboard: 'Shiba',
                              animations: [_isRescued ? 'WinEndState' : 'Anim_shiba'],
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Text(
                          _currentMission.rescuedAnimal,
                          style: TextStyle(fontSize: _isRescued ? 58 : 46),
                        ),

                      if (!_isRescued)
                        Positioned(
                          top: -12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.pinkAccent, width: 1.5),
                            ),
                            child: Text(
                              _bounceCount > 0 ? '통통~! 🌟' : '받아주세요~!',
                              style: GoogleFonts.jua(fontSize: 11, color: Colors.pink, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (_isRescued)
                        Positioned(
                          top: -14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.pinkAccent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.pink.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('💖', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '구출 성공! 고마워요!',
                                  style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Golden Cushioned Safety Trampoline (Air-Mat)
          Positioned(
            left: trampolinePixelX - 70,
            top: screenSize.height * 0.74,
            child: Column(
              children: [
                Container(
                  width: 140,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFB8500).withValues(alpha: 0.55),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🌟', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '안전 에어매트',
                        style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text('🌟', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🧑‍🚒', style: TextStyle(fontSize: 34)),
                    SizedBox(width: 58),
                    Text('🧑‍🚒', style: TextStyle(fontSize: 34)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. CELEBRATE VIEW (Enhanced with Rive 5-Star, Treasure Chest & Mascot)
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildCelebrateView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildSceneIllustration(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              decoration: KidsTheme.toyDecoration(
                color: Colors.white,
                borderRadius: 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. RIVE 5-STAR RATING CELEBRATION
                  const SizedBox(
                    width: 170,
                    height: 58,
                    child: RiveAnimation.asset(
                      'assets/rive/rating.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🎉 미션 완수! 최고의 소방 영웅! 🏆',
                    style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFFFF3366)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 2. DUAL RIVE CELEBRATION STAGE (Reward Chest + Rescued Shiba Hero)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Rive Reward Chest (Interactive Tap)
                        GestureDetector(
                          onTap: () {
                            AudioManager.instance.playTraceSuccess();
                            HapticFeedback.heavyImpact();
                            _safeSetState(() {
                              _rewardChestTapCount++;
                            });
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 78,
                                    height: 78,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: const ClipOval(
                                      child: RiveAnimation.asset(
                                        'assets/rive/rewards.riv',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  if (_rewardChestTapCount > 0)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5722),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.4), blurRadius: 4),
                                          ],
                                        ),
                                        child: Text(
                                          '+${_rewardChestTapCount * 100} 🏅',
                                          style: GoogleFonts.jua(fontSize: 10, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '보물 상자 탭! 🎁',
                                style: GoogleFonts.jua(fontSize: 11, color: const Color(0xFFD97706)),
                              ),
                            ],
                          ),
                        ),

                        // Center Divider Sparkle
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('✨', style: TextStyle(fontSize: 18)),
                            SizedBox(height: 2),
                            Text('💖', style: TextStyle(fontSize: 16)),
                          ],
                        ),

                        // Rescued Hero Mascot (Rive Shiba in WinEndState)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFFFB703), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const ClipOval(
                                child: RiveAnimation.asset(
                                  'assets/rive/dog.riv',
                                  artboard: 'Shiba',
                                  animations: ['WinEndState'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB703),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '명예 소방견 멍이 🏅',
                                style: GoogleFonts.jua(fontSize: 10, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Clear Comment Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(_currentMission.rescuedAnimal, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentMission.clearComment,
                            style: GoogleFonts.jua(fontSize: 13.5, color: const Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Replay & Next Mission Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          _startMission(_currentMission);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: KidsTheme.toyDecoration(
                            color: const Color(0xFFFF9F1C),
                            borderRadius: 18,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text('다시 하기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          final nextId = (_currentMission.id % _missions.length) + 1;
                          final nextMission = _missions.firstWhere((m) => m.id == nextId);
                          _startMission(nextMission);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          decoration: KidsTheme.toyDecoration(
                            color: const Color(0xFF06D6A0),
                            borderRadius: 18,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('다음 출동! ➡️', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
