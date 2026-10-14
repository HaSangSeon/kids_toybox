part of '../pet_hospital_game.dart';

extension _PetHospitalToolTraysExtension on _PetHospitalGameState {
  Widget _buildBottomToolTray() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyan.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _buildToolTrayContent(),
    );
  }

  Widget _buildToolTrayContent() {
    switch (_step) {
      case HospitalStep.diagnose:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '청진기와 체온계를 손가락으로 드래그해서 몸에 대주세요! 🩺🌡️',
              style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF006064), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDraggableActionToolButton(
                  dragData: 'stethoscope',
                  icon: '🩺',
                  title: '청진기',
                  subtitle: _isHeartbeatChecked ? '콩닥 확인 완료!' : '배로 드래그 👆',
                  isDone: _isHeartbeatChecked,
                  onTap: _onCheckHeartbeat,
                ),
                _buildDraggableActionToolButton(
                  dragData: 'thermometer',
                  icon: '🌡️',
                  title: '체온계',
                  subtitle: _isTempChecked ? '${_currentTemp.toStringAsFixed(1)}℃ 완료!' : '이마로 드래그 👆',
                  isDone: _isTempChecked,
                  onTap: _onCheckTemperature,
                ),
              ],
            ),
          ],
        );

      case HospitalStep.pluckThorns:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✂️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              '환자의 몸에 박힌 가시를 톡 눌러 뽑아주세요!',
              style: GoogleFonts.jua(fontSize: 14.5, color: const Color(0xFF00838F), fontWeight: FontWeight.bold),
            ),
          ],
        );

      case HospitalStep.disinfect:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧴', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              '빨간 상처 부위를 톡톡 눌러서 소독해요!',
              style: GoogleFonts.jua(fontSize: 14.5, color: const Color(0xFF00838F), fontWeight: FontWeight.bold),
            ),
          ],
        );

      case HospitalStep.applyBandaid:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '원하는 밴드를 고른 후 상처 자리를 찰칵 눌러주세요!',
              style: GoogleFonts.jua(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: _kBandaids.map((b) {
                    final isSelected = _selectedBandaid.emoji == b.emoji;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          AudioManager.instance.playClick();
                          _safeSetState(() => _selectedBandaid = b);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? b.color.withValues(alpha: 0.18) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? b.color : Colors.grey.shade300,
                              width: isSelected ? 3.0 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: b.color.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(b.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Text(
                                b.name,
                                style: GoogleFonts.jua(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.grey.shade900 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );

      case HospitalStep.coolAndSyrup:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionToolButton(
              icon: '🧊',
              title: '얼음팩',
              subtitle: _isIcePackApplied ? '36.5℃ 정상!' : '이마에 얹기',
              isDone: _isIcePackApplied,
              onTap: _applyIcePack,
            ),
            _buildActionToolButton(
              icon: '🥄',
              title: '딸기 물약',
              subtitle: _isSyrupFed ? '꿀꺽 완치!' : '입에 주기',
              isDone: _isSyrupFed,
              onTap: _feedSyrup,
            ),
          ],
        );

      case HospitalStep.complete:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: _feedVictoryTreat,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF9800)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🍭', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      _isTreatFed ? '사탕 먹기 완료! ✨' : '칭찬 사탕 주기 🍬',
                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _resetGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00897B)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.teal.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏥', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      '다음 환자 진료 ➡️',
                      style: GoogleFonts.jua(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDraggableActionToolButton({
    required String dragData,
    required String icon,
    required String title,
    String? subtitle,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    final buttonContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.shade50 : Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone ? Colors.green.shade400 : const Color(0xFF00ACC1),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDone ? Colors.green.withValues(alpha: 0.15) : Colors.cyan.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.jua(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDone ? Colors.green.shade700 : const Color(0xFF00838F),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.jua(
                    fontSize: 10,
                    color: isDone ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          if (isDone) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
          ],
        ],
      ),
    );

    if (isDone) {
      return buttonContent;
    }

    return Draggable<String>(
      data: dragData,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00ACC1), width: 4.0),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withValues(alpha: 0.6),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 42)),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: buttonContent,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: buttonContent,
      ),
    );
  }

  Widget _buildActionToolButton({
    required String icon,
    required String title,
    String? subtitle,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isDone ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade50 : Colors.cyan.shade50,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDone ? Colors.green.shade400 : const Color(0xFF00ACC1),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDone ? Colors.green.withValues(alpha: 0.15) : Colors.cyan.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jua(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDone ? Colors.green.shade700 : const Color(0xFF00838F),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.jua(
                      fontSize: 11,
                      color: isDone ? Colors.green.shade600 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            if (isDone) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
