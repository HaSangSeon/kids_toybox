part of '../pet_hospital_game.dart';

extension _PetHospitalTreatmentExtension on _PetHospitalGameState {
  Widget _buildTreatmentStage() {
    return Column(
      children: [
        // Dialogue Banner
        _buildDialogueBanner(),

        // Medical Hospital Stage Canvas with FittedBox
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: _buildPatientInteractiveCanvas(),
            ),
          ),
        ),

        // Bottom Tool Tray
        _buildBottomToolTray(),
      ],
    );
  }

  Widget _buildDialogueBanner() {
    final text = _customDialogue ?? _currentPatient.symptom;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF80DEEA), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(_currentPatient.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.jua(
                fontSize: 13.5,
                color: const Color(0xFF006064),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Patient Interactive Body Canvas (360x380 Large Hospital Scene) ─────────

  // ── Patient Interactive Body Canvas (Clean Nordic Clinic Scene) ───────────

  Widget _buildPatientInteractiveCanvas() {
    const canvasW = 350.0;
    const canvasH = 440.0;

    return AnimatedBuilder(
      animation: _jumpCtrl,
      builder: (context, child) {
        final jumpOffset = _step == HospitalStep.complete ? sin(_jumpCtrl.value * pi) * 20 : 0.0;
        return Transform.translate(
          offset: Offset(0, -jumpOffset),
          child: child,
        );
      },
      child: SizedBox(
        width: canvasW,
        height: canvasH,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 1. Warm & Clean Minimalist Clinic Examination Mat
            _buildLargeHospitalRoomScene(),

            // 2. Master Nordic Vector Animal Patient (Scaled up 1.25x for big, adorable presence)
            _buildLargeAliveAnimalPatient(),

            // 3. Elegant Stethoscope Target (On Chest / Tummy - Natural placement)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 85,
                top: 220,
                width: 90,
                height: 90,
                child: _buildHeartbeatTarget(),
              ),

            // 4. Elegant Thermometer Target (On Forehead - Unobtrusive)
            if (_step == HospitalStep.diagnose)
              Positioned(
                left: 175,
                top: 42,
                width: 90,
                height: 90,
                child: _buildThermometerTarget(),
              ),

            // 5. Cute Cartoon Ice Pack on Forehead
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 36,
                child: _buildRealisticIcePack(),
              ),

            // 6. Sweet Syrup Spoon on Mouth
            if (_step == HospitalStep.coolAndSyrup)
              Positioned(
                top: 145,
                child: _buildSyrupMouthTarget(),
              ),

            // 7. Harmonious Storybook Wounds & Band-aids (소독 단계부터 나타남 - 진찰/가시 단계에서는 숨김!)
            if (_step != HospitalStep.diagnose && _step != HospitalStep.pluckThorns)
              ..._liveWounds.map((w) => _buildRealisticWound(w)),

            // 8. Harmonious Cartoon Thorns (가시 뽑기 단계에서만 집중 노출!)
            if (_step == HospitalStep.pluckThorns)
              ..._liveThorns.map((t) => _buildRealisticThorn(t)),

            // 9. Sparkles & Particles
            ..._particles.map((p) => Positioned(
                  left: p.pos.dx - (p.size / 2),
                  top: p.pos.dy - (p.size / 2),
                  child: Opacity(
                    opacity: p.opacity,
                    child: Text(p.text, style: TextStyle(fontSize: p.size, color: p.color)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ── Warm & Clean Minimalist Clinic Background (최적의 대비 & 포근한 색감) ───

  Widget _buildLargeHospitalRoomScene() {
    return Container(
      width: 335,
      height: 425,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Soothing soft pastel mint clinic background
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xFFA5D6A7), width: 3.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4), // Warm cozy yellow pastel towel
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFE082), width: 1.8),
        ),
      ),
    );
  }

  // ── Master Nordic Vector Animal Character ─────────────────────────────────

  Widget _buildLargeAliveAnimalPatient() {
    final patient = _currentPatient;
    final isHappy = _step == HospitalStep.complete;
    final isFever = _currentTemp > 37.5 && !_isIcePackApplied;
    final isSad = !isHappy && (isFever || _liveWounds.any((w) => !w.isBandaidApplied));
    final isOpenMouth = _step == HospitalStep.coolAndSyrup && !_isSyrupFed;

    return AnimatedBuilder(
      animation: _idleCtrl,
      builder: (context, child) {
        // 동물 모습을 화면에 꽉 차게 1.25배 크게 렌더링!
        final breatheScale = (1.0 + (_idleCtrl.value * 0.02)) * 1.25;

        return Transform.scale(
          scale: breatheScale,
          child: SizedBox(
            width: 320,
            height: 340,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 1. Master Nordic Animal Canvas (동물별 완벽한 시그니처 실루엣 & 일러스트)
                CustomPaint(
                  size: const Size(320, 340),
                  painter: _NordicAnimalIllustrationPainter(
                    patient: patient,
                    idleProgress: _idleCtrl.value,
                    isHappy: isHappy,
                    isFever: isFever,
                    isSad: isSad,
                    isOpenMouth: isOpenMouth,
                  ),
                ),

                // 2. Animated crying tear drops when hurt / sick
                if (isSad)
                  AnimatedBuilder(
                    animation: _tearCtrl,
                    builder: (context, child) {
                      final tearY = 145 + (_tearCtrl.value * 18);
                      final tearOpacity = (1.0 - _tearCtrl.value).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Positioned(
                            top: tearY,
                            left: 105,
                            child: Opacity(
                              opacity: tearOpacity,
                              child: const Text('💧', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          Positioned(
                            top: tearY,
                            right: 105,
                            child: Opacity(
                              opacity: tearOpacity,
                              child: const Text('💧', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeartbeatTarget() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == 'stethoscope',
      onAcceptWithDetails: (details) {
        if (details.data == 'stethoscope') {
          _onCheckHeartbeat();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onCheckHeartbeat,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                if (_isHeartbeatChecked) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '정상 ❤️',
                          style: GoogleFonts.jua(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  );
                }

                final scale = isHovered ? 1.25 : (1.0 + _pulseCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: (isHovered ? const Color(0xFFE0F7FA) : const Color(0xFFFFF0F5)).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHovered ? const Color(0xFF00ACC1) : const Color(0xFFFF4081),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isHovered ? Colors.cyan : Colors.pinkAccent).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isHovered ? '🩺' : '❤️',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pinkAccent, width: 1),
                        ),
                        child: Text(
                          '청진기 🩺',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.pink, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Step 2 Target: Thermometer on Forehead (Clean & Subtle) ────────────────

  Widget _buildThermometerTarget() {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data == 'thermometer',
      onAcceptWithDetails: (details) {
        if (details.data == 'thermometer') {
          _onCheckTemperature();
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _onCheckTemperature,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                if (_isTempChecked) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.green.withValues(alpha: 0.2), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${_currentTemp.toStringAsFixed(1)}℃',
                          style: GoogleFonts.jua(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  );
                }

                final scale = isHovered ? 1.25 : (1.0 + _pulseCtrl.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: (isHovered ? const Color(0xFFFFF8E1) : const Color(0xFFFFF3E0)).withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isHovered ? const Color(0xFFFFA000) : const Color(0xFFFFB300),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isHovered ? '🌡️' : '🌡️',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade800, width: 1),
                        ),
                        child: Text(
                          '체온계 🌡️',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ── Step 6 Clean Target: Ice Pack on Forehead ──────────────────────────────

  Widget _buildRealisticIcePack() {
    return GestureDetector(
      onTap: _applyIcePack,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isIcePackApplied ? 1.0 : (1.0 + _pulseCtrl.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: _isIcePackApplied
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00ACC1), width: 2.0),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.25), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🧊', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Text(
                          '36.5℃ 정상!',
                          style: GoogleFonts.jua(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF006064)),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00ACC1), width: 2.4),
                      boxShadow: [
                        BoxShadow(color: Colors.cyan.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🧊', style: TextStyle(fontSize: 24)),
                  ),
          );
        },
      ),
    );
  }

  // ── Step 6 Clean Target: Syrup on Mouth ────────────────────────────────────

  Widget _buildSyrupMouthTarget() {
    return GestureDetector(
      onTap: _feedSyrup,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = _isSyrupFed ? 1.0 : (1.0 + _pulseCtrl.value * 0.15);
          return Transform.scale(
            scale: scale,
            child: _isSyrupFed
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.pinkAccent, width: 2.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💖', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 3),
                        Text('꿀꺽!', style: GoogleFonts.jua(fontSize: 12, color: Colors.pink.shade800, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE91E63), width: 2.4),
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withValues(alpha: 0.35), blurRadius: 8),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text('🥄', style: TextStyle(fontSize: 22)),
                  ),
          );
        },
      ),
    );
  }

  // ── Highly Visible & Easy-to-Tap Cartoon Thorn ────────────────────────────

  Widget _buildRealisticThorn(_ThornItem thorn) {
    if (thorn.isPlucked) return const SizedBox.shrink();

    final isPluckStep = _step == HospitalStep.pluckThorns;

    return Positioned(
      left: thorn.pos.dx - 30,
      top: thorn.pos.dy - 30,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isPluckStep) {
            _pluckThorn(thorn);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final scale = isPluckStep ? (1.0 + _pulseCtrl.value * 0.20) : 1.0;
            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. 선명한 황금빛 펄싱 아우라 링 (어떤 털 색상에서도 1초 만에 눈에 띔)
                    if (isPluckStep)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFF176).withValues(alpha: 0.75),
                          border: Border.all(color: const Color(0xFFFF8F00), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                    // 2. 큼직하고 또렷한 가시 벡터 그래픽
                    Transform.rotate(
                      angle: thorn.angle,
                      child: CustomPaint(
                        size: const Size(28, 40),
                        painter: _NordicThornPainter(),
                      ),
                    ),

                    // 3. 핀셋 터치 유도 미니 뱃지 (✂️ 콕!)
                    if (isPluckStep)
                      Positioned(
                        top: -8,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6F00),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 4),
                            ],
                          ),
                          child: const Text(
                            '✂️ 쏙!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Harmonious Storybook Wound & Band-aid ──────────────────────────────────

  Widget _buildRealisticWound(_WoundItem wound) {
    final isDisinfectStep = _step == HospitalStep.disinfect && wound.healProgress < 1.0;
    final isBandaidStep = _step == HospitalStep.applyBandaid && !wound.isBandaidApplied;

    return Positioned(
      left: wound.pos.dx - (wound.width / 2),
      top: wound.pos.dy - (wound.height / 2),
      child: GestureDetector(
        onTap: () {
          if (_step == HospitalStep.disinfect) {
            _onDisinfectWound(wound);
          } else if (_step == HospitalStep.applyBandaid) {
            _applyBandaidToWound(wound);
          }
        },
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final isPulsing = isDisinfectStep || isBandaidStep;
            final scale = isPulsing ? (1.0 + _pulseCtrl.value * 0.18) : 1.0;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: wound.width + 24,
                height: wound.height + 24,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // 소독 또는 밴드 붙이기 단계 펄싱 아우라
                    if (isDisinfectStep)
                      Container(
                        width: wound.width + 16,
                        height: wound.height + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF80DEEA).withValues(alpha: 0.5),
                          border: Border.all(color: const Color(0xFF00ACC1), width: 2.2),
                        ),
                      )
                    else if (isBandaidStep)
                      Container(
                        width: wound.width + 16,
                        height: wound.height + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF80AB).withValues(alpha: 0.45),
                          border: Border.all(color: const Color(0xFFFF4081), width: 2.2),
                        ),
                      ),

                    // Applied Cute Band-aid
                    if (wound.isBandaidApplied)
                      _buildRealisticBandaidWidget(
                        emoji: wound.bandaidEmoji ?? '❤️',
                        color: wound.bandaidColor ?? const Color(0xFFFF5252),
                        width: wound.width + 8,
                        height: wound.height + 2,
                      )
                    // Disinfected/healed clean skin with sparkle
                    else if (wound.healProgress >= 1.0)
                      Container(
                        width: wound.width,
                        height: wound.height,
                        alignment: Alignment.center,
                        child: const Text('✨', style: TextStyle(fontSize: 22)),
                      )
                    // Cartoon Scratch Abrasion
                    else
                      CustomPaint(
                        size: Size(wound.width, wound.height),
                        painter: _NordicScratchPainter(
                          healProgress: wound.healProgress,
                          isHighlight: isDisinfectStep,
                        ),
                      ),

                    // 안내 미니 뱃지 (🧴 톡! 또는 🩹 착!)
                    if (isDisinfectStep)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00838F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Text(
                            '🧴 톡!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else if (isBandaidStep)
                      Positioned(
                        top: -8,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD81B60),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Text(
                            '🩹 착!',
                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Cute Pastel Nordic Band-aid Widget ────────────────────────────────────

  Widget _buildRealisticBandaidWidget({
    required String emoji,
    required Color color,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Soft cream fabric
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: Colors.orange.shade200, shape: BoxShape.circle))),
          ),
          Container(
            width: width * 0.48,
            height: height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.0),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  // ── Bottom Interactive Tool Tray ──────────────────────────────────────────

}
