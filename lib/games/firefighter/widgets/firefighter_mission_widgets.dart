part of '../firefighter_game.dart';

extension _FirefighterMissionExtension on _FirefighterGameState {
  // ─────────────────────────────────────────────────────────────────────────────
  // 1. MISSION SELECT VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildMissionSelectView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: KidsTheme.toyDecoration(
              color: Colors.white,
              borderRadius: 22,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Container(
                      color: const Color(0xFFFFF3E0),
                      child: const RiveAnimation.asset(
                        'assets/rive/dog.riv',
                        artboard: 'Shiba',
                        animations: ['Anim_shiba'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '삐뽀삐뽀! 긴급 출동 미션!',
                            style: GoogleFonts.jua(fontSize: 19, color: const Color(0xFFFF5964)),
                          ),
                          const SizedBox(width: 4),
                          const Text('🚨', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Rive 3D ✨', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '도움이 필요한 곳을 골라 출동해요! 💦',
                              style: GoogleFonts.jua(fontSize: 12.5, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _missions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final m = _missions[index];
                final isDog = m.rescuedAnimal == '🐶';
                final isRocket = m.emoji == '🚀';

                return GestureDetector(
                  onTap: () => _startMission(m),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: KidsTheme.toyDecoration(
                      color: Colors.white,
                      borderRadius: 22,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [m.skyGradient.first, m.skyGradient.last],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isDog)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: const RiveAnimation.asset(
                                    'assets/rive/dog.riv',
                                    artboard: 'Shiba',
                                    animations: ['Anim_shiba'],
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (isRocket)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: const RiveAnimation.asset(
                                    'assets/rive/rocket.riv',
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                Text(m.emoji, style: const TextStyle(fontSize: 32)),

                              if (isDog || isRocket)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDog ? const Color(0xFFFF5722) : const Color(0xFF0284C7),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      isDog ? 'Rive ✨' : '로켓 🚀',
                                      style: const TextStyle(fontSize: 7.5, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5964),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '미션 0${m.id}',
                                      style: GoogleFonts.jua(fontSize: 11, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '구출: ${m.rescuedAnimal}',
                                    style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFFF9F1C)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                m.title,
                                style: GoogleFonts.jua(fontSize: 17, color: const Color(0xFF2B2D42)),
                              ),
                              Text(
                                m.subTitle,
                                style: GoogleFonts.jua(fontSize: 12, color: const Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Text('출동!', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. DISPATCH VIEW
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildDispatchView() {
    final width = MediaQuery.of(context).size.width;
    final truckX = (_dispatchProgress * (width - 150)).clamp(15.0, width - 160);

    return Stack(
      children: [
        Positioned(
          top: 8,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: KidsTheme.toyDecoration(
              color: Colors.white,
              borderRadius: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      _isBoosterActive ? '⚡ 초고속 부스터 발동! 🚀' : '긴급 출동 중! 삐용~ 삐용~!',
                      style: GoogleFonts.jua(
                        fontSize: 20,
                        color: _isBoosterActive ? const Color(0xFFFF1744) : const Color(0xFFFF3366),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('🚨', style: TextStyle(fontSize: 22)),
                  ],
                ),
                Text(
                  '소방차를 탭해서 부스터 가속을 해보세요! 💨',
                  style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),

        // Road with animated Fire Engine
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              border: Border(
                top: BorderSide(color: Color(0xFF94A3B8), width: 5),
                bottom: BorderSide(color: Color(0xFF1E293B), width: 8),
              ),
            ),
            child: Stack(
              children: [
                // Road dashes
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      8,
                      (index) => Container(
                        width: 32,
                        height: 7,
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Collectable Water Drops
                for (int i = 0; i < _roadItems.length; i++)
                  Positioned(
                    left: _roadItems[i].dx * width,
                    top: _roadItems[i].dy * 120 + 20,
                    child: GestureDetector(
                      onTap: () {
                        AudioManager.instance.playDecalStamp();
                        HapticFeedback.lightImpact();
                        _safeSetState(() {
                          _roadItems.removeAt(i);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('💧', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                  ),

                // Booster Particles Trail
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BoosterParticlesPainter(_boosterParticles),
                    ),
                  ),
                ),

                // High-End Rive Fire Engine Truck
                Positioned(
                  left: truckX,
                  top: 24 + (_truckBounceCtrl.value * 5),
                  child: GestureDetector(
                    onTap: () {
                      AudioManager.instance.playFireSiren();
                      HapticFeedback.heavyImpact();
                      _safeSetState(() {
                        _isBoosterActive = true;
                      });
                      _dispatchAnimCtrl.duration = const Duration(seconds: 2);
                    },
                    child: _buildFireEngineTruck(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Controls (Booster & Arrival)
        Positioned(
          bottom: 16,
          left: 20,
          right: 20,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioManager.instance.playFireSiren();
                    HapticFeedback.heavyImpact();
                    _safeSetState(() {
                      _isBoosterActive = true;
                    });
                    _dispatchAnimCtrl.duration = const Duration(seconds: 2);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: KidsTheme.toyDecoration(
                      color: const Color(0xFFFF5964),
                      borderRadius: 18,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🚀', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '부스터 가속! 💨',
                            style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _arriveAtScene,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: KidsTheme.toyDecoration(
                      color: const Color(0xFF06D6A0),
                      borderRadius: 18,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🚨', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '현장 도착! ➡️',
                            style: GoogleFonts.jua(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFireEngineTruck() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Dual Siren Flashing LED Beacon Bar
        AnimatedBuilder(
          animation: _sirenLightCtrl,
          builder: (context, child) {
            final isRed = _sirenLightCtrl.value > 0.5;
            return Container(
              width: 44,
              height: 14,
              decoration: BoxDecoration(
                color: isRed ? const Color(0xFFFF1744) : const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: (isRed ? const Color(0xFFFF1744) : const Color(0xFF00E5FF)).withValues(alpha: 0.9),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRed ? Colors.white : const Color(0xFFFF1744),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRed ? const Color(0xFF00E5FF) : Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 2),

        // 2. Fire Engine Main Body with Rive Driver Mascot
        SizedBox(
          width: 140,
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Truck Body Shape
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                top: 10,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF2A4B), Color(0xFFD50000), Color(0xFF990000)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Lower Yellow/White Safety Hazard Chevron Stripes
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFFB300), Color(0xFFFFD54F)],
                            ),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                          ),
                        ),
                      ),
                      // Text Emblem
                      Positioned(
                        left: 12,
                        top: 24,
                        child: Row(
                          children: [
                            const Text('💧', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 2),
                            Text(
                              '119 소방대',
                              style: GoogleFonts.jua(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Rive Shiba Firefighter in Driver Window
              Positioned(
                right: 14,
                top: 0,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
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
                    // Cute Firefighter helmet badge on top
                    Positioned(
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('🧑‍🚒', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),

              // Chrome Front Bumper / Headlight
              Positioned(
                right: -4,
                bottom: 16,
                child: Container(
                  width: 10,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.amberAccent,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Wheels (Spinning with Dispatch Progress)
              Positioned(
                left: 18,
                bottom: 0,
                child: _buildTruckWheel(),
              ),
              Positioned(
                right: 22,
                bottom: 0,
                child: _buildTruckWheel(),
              ),

              // Booster Flame Trail (when booster active)
              if (_isBoosterActive)
                Positioned(
                  left: -22,
                  top: 26,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFFFF3366), Color(0xFFFF9900)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🔥💨', style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTruckWheel() {
    return Transform.rotate(
      angle: _dispatchProgress * 24.0 * pi,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF94A3B8), width: 3.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
