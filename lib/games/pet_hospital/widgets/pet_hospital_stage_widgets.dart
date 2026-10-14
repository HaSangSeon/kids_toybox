part of '../pet_hospital_game.dart';

extension _PetHospitalStageExtension on _PetHospitalGameState {

  // ── Active Animated Hospital Background ────────────────────────────────────

  Widget _buildActiveAnimatedHospitalBackground() {
    return AnimatedBuilder(
      animation: _bgDriftCtrl,
      builder: (context, child) {
        final t = _bgDriftCtrl.value;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFFE1F5FE)],
            ),
          ),
          child: Stack(
            children: [
              // Floating ambient medical bubbles and pastel crosses
              ...List.generate(7, (i) {
                final startX = (0.12 * i + 0.08) * 380;
                final speed = 1.0 + (i % 3) * 0.4;
                final currentY = 700 - ((t * speed * 700 + (i * 110)) % 750);
                final swayX = startX + sin((t * 2 * pi) + i) * 16;
                final icon = ['🫧', '✚', '✨', '🫧', '✚', '⭐', '🫧'][i];
                final size = [20.0, 16.0, 18.0, 24.0, 16.0, 18.0, 22.0][i];
                final opacity = [0.4, 0.25, 0.45, 0.35, 0.25, 0.4, 0.3][i];

                return Positioned(
                  left: swayX,
                  top: currentY,
                  child: Opacity(
                    opacity: opacity,
                    child: Text(icon, style: TextStyle(fontSize: size, color: const Color(0xFF00ACC1))),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Top Navigation Bar (With Clean Spacing) ────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              if (_step == HospitalStep.selectPatient) {
                Navigator.of(context).pop();
              } else {
                _safeSetState(() {
                  _step = HospitalStep.selectPatient;
                  _jumpCtrl.stop();
                });
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF00838F), size: 26),
            ),
          ),

          // Title Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏥', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '꼬마 동물 병원',
                  style: GoogleFonts.jua(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00838F),
                  ),
                ),
              ],
            ),
          ),

          // Reset / Another Patient Button
          if (_step != HospitalStep.selectPatient)
            GestureDetector(
              onTap: _resetGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔄', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '다른 친구',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  // ── Step Progress Indicator ─────────────────────────────────────────────────

  Widget _buildStepProgressBar() {
    if (_step == HospitalStep.selectPatient) return const SizedBox.shrink();

    final steps = [
      {'step': HospitalStep.diagnose, 'emoji': '🩺', 'label': '진찰'},
      {'step': HospitalStep.pluckThorns, 'emoji': '✂️', 'label': '가시'},
      {'step': HospitalStep.disinfect, 'emoji': '🧴', 'label': '소독'},
      {'step': HospitalStep.applyBandaid, 'emoji': '🩹', 'label': '밴드'},
      {'step': HospitalStep.coolAndSyrup, 'emoji': '🧊', 'label': '열/물약'},
      {'step': HospitalStep.complete, 'emoji': '✨', 'label': '완치!'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: steps.map((s) {
          final isCurrent = _step == s['step'];
          final isPassed = _step.index > (s['step'] as HospitalStep).index;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isCurrent ? 30 : 24,
                height: isCurrent ? 30 : 24,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF00ACC1)
                      : (isPassed ? const Color(0xFF80DEEA) : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: Colors.cyan.withValues(alpha: 0.4), blurRadius: 6)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  s['emoji'] as String,
                  style: TextStyle(fontSize: isCurrent ? 15 : 12),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                s['label'] as String,
                style: GoogleFonts.jua(
                  fontSize: 9.5,
                  color: isCurrent ? const Color(0xFF00838F) : Colors.grey.shade600,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Step 1: Patient Selection View ─────────────────────────────────────────

  Widget _buildPatientSelectView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏥', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    '어떤 동물 친구를 치료해줄까요?',
                    style: GoogleFonts.jua(
                      fontSize: 18,
                      color: const Color(0xFF00838F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _patients.map((patient) => _buildPatientSelectCard(patient)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelectCard(_PatientData patient) {
    return GestureDetector(
      onTap: () => _selectPatient(patient),
      child: Container(
        width: 145,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: patient.darkColor, width: 3.2),
          boxShadow: [
            BoxShadow(
              color: patient.darkColor.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: patient.faceColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(color: patient.darkColor, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(patient.emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(height: 6),
            Text(
              patient.name,
              style: GoogleFonts.jua(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                patient.title,
                style: GoogleFonts.jua(fontSize: 10.5, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: patient.darkColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '치료하기 🩺',
                style: GoogleFonts.jua(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Unified Treatment Stage (No scrolling hijack - 100% Solid & Stable) ──

}
