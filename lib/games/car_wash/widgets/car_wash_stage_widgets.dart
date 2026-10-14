part of '../car_wash_game.dart';

extension _CarWashStageExtension on _CarWashGameState {
  // ── 0. Car Select Screen ──────────────────────────────────────────────────
  Widget _buildSelectScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () { AudioManager.instance.playClick(); Navigator.of(context).pop(); },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
                ),
              ),
              const Spacer(),
              Text('🚗 세차장에 어서오세요!',
                style: GoogleFonts.jua(fontSize: 22, color: Colors.white, shadows: [
                  const Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                ]),
              ),
              const Spacer(),
              const SizedBox(width: 44),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text('씻겨줄 먼지 묻은 차를 골라주세요! 🧼',
          style: GoogleFonts.jua(fontSize: 17, color: Colors.white.withValues(alpha: 0.85)),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _kVehicles.length,
                  itemBuilder: (ctx, i) {
                    final v = _kVehicles[i];
                    return _CarSelectTile(
                      vehicle: v,
                      onTap: () => _startDriveIn(v),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── 1. Wash Screen ────────────────────────────────────────────────────────
  Widget _buildWashScreen() {
    return Column(
      children: [
        _buildTopBar(),
        _buildStepIndicator(),

        Expanded(
          child: LayoutBuilder(builder: (ctx, constraints) {
            return _buildCarArea(constraints);
          }),
        ),

        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); _reset(); },
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🧼 ', style: TextStyle(fontSize: 18)),
                Text(
                  '${_car.label} 세차장',
                  style: GoogleFonts.jua(fontSize: 18, color: Colors.white, shadows: [
                    const Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 3),
                  ]),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _safeSetState(() => AudioManager.instance.toggleSound()),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 1.5),
              ),
              child: Icon(
                AudioManager.instance.soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: Colors.white, size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      ('🚿', '물씻기',  _WashStep.water,   const Color(0xFF0288D1)),
      ('🫧', '비누칠',  _WashStep.soap,    const Color(0xFF7E57C2)),
      ('🌊', '헹구기',  _WashStep.rinse,   const Color(0xFF00ACC1)),
      ('🧻', '닦기',    _WashStep.dry,     const Color(0xFFFF7043)),
      ('🎀', '꾸미기',  _WashStep.sticker, const Color(0xFF26A69A)),
    ];

    double progress = 0;
    switch (_step) {
      case _WashStep.water:  progress = _waterProgress; break;
      case _WashStep.soap:   progress = _soapProgress;  break;
      case _WashStep.rinse:  progress = _rinseProgress; break;
      case _WashStep.dry:    progress = _dryProgress;   break;
      default: progress = 1.0;
    }

    final double displayProgress = _stepComplete
        ? 1.0
        : (progress / _advanceThreshold).clamp(0.0, 1.0);
    final int percentInt = (displayProgress * 100).round();

    final stepInfoMap = <_WashStep, (String, Color, Color)>{
      _WashStep.water: ('🚿 물로 먼지와 진흙 씻기', const Color(0xFF0288D1), const Color(0xFF4FC3F7)),
      _WashStep.soap:  ('🫧 골고루 비누 거품 칠하기', const Color(0xFF7E57C2), const Color(0xFFBA68C8)),
      _WashStep.rinse: ('🌊 깨끗하게 거품 헹구기', const Color(0xFF00ACC1), const Color(0xFF4DD0E1)),
      _WashStep.dry:   ('🧻 수건으로 물기 뽀송뽀송 닦기', const Color(0xFFFF7043), const Color(0xFFFFB74D)),
      _WashStep.sticker: ('🎀 예쁜 스티커로 꾸미기', const Color(0xFF26A69A), const Color(0xFF80CBC4)),
    };
    final currentInfo = stepInfoMap[_step] ?? ('🚗 신나는 드라이브', const Color(0xFF43E97B), const Color(0xFF06D6A0));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
          child: SizedBox(
            height: 68,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: steps.map((s) {
                final isCurrent = _step == s.$3;
                final isDone = _step.index > s.$3.index;
                final isNextReady = _stepComplete && (_step.index + 1 == s.$3.index);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: GestureDetector(
                      onTap: isNextReady ? _advanceStep : null,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: isNextReady ? 46 : (isCurrent ? 42 : 34),
                            width:  isNextReady ? 46 : (isCurrent ? 42 : 34),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF43E97B)
                                  : isNextReady || isCurrent
                                      ? s.$4
                                      : Colors.white.withValues(alpha: 0.25),
                              border: Border.all(
                                color: isCurrent || isNextReady ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isNextReady ? [
                                BoxShadow(
                                  color: s.$4.withValues(alpha: 0.8),
                                  blurRadius: 16, spreadRadius: 2,
                                ),
                              ] : isCurrent ? [
                                BoxShadow(color: s.$4.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 2),
                              ] : [],
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : Text(s.$1, style: TextStyle(fontSize: isNextReady ? 22 : (isCurrent ? 20 : 16))),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isNextReady ? '👆 탭!' : s.$2,
                            style: GoogleFonts.jua(
                              fontSize: isNextReady ? 11 : (isCurrent ? 11 : 10),
                              color: isNextReady || isCurrent ? Colors.white : Colors.white60,
                              fontWeight: (isNextReady || isCurrent) ? FontWeight.bold : FontWeight.normal,
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

        // 🌟 Synchronized, Responsive, Crystal-clear Progress Bar with Percentage
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentInfo.$1,
                      style: GoogleFonts.jua(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _stepComplete ? const Color(0xFF43E97B) : currentInfo.$2,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (_stepComplete ? const Color(0xFF43E97B) : currentInfo.$2).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        _stepComplete ? '✨ 100% 완료!' : '$percentInt%',
                        style: GoogleFonts.jua(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        final barW = boxConstraints.maxWidth * displayProgress;
                        return Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: barW,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _stepComplete
                                      ? [const Color(0xFF06D6A0), const Color(0xFF43E97B)]
                                      : [currentInfo.$2, currentInfo.$3],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 1,
                              left: 2,
                              right: 2,
                              height: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }


  Widget _buildCarArea(BoxConstraints constraints) {
    final areaW = constraints.maxWidth;
    final areaH = constraints.maxHeight;
    // 🌟 Significantly enlarged car size for easier touch and more satisfying presence!
    final carW = (areaW * 0.92).clamp(280.0, 520.0);
    final carH = (carW * 0.62).clamp(170.0, 320.0);
    final carL = (areaW - carW) / 2.0;

    // Car sits on the wash bay floor
    final groundH = areaH * 0.28;
    final groundTop = areaH - groundH;
    final carT = (groundTop - carH * 0.76).clamp(10.0, areaH - carH);

    // X offsets for Drive-In and Drive-Out
    final driveInOffsetX = _step == _WashStep.driveIn
        ? _carDriveInX * (areaW + carW + 60)
        : 0.0;
    final driveOutOffsetX = _carDriveCtrl.isAnimating || _driveComplete
        ? -_carDriveX * (areaW + carW + 60)
        : 0.0;

    final totalOffsetX = driveInOffsetX + driveOutOffsetX;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // 🌟 Rich, Fun Kid-Friendly Car Wash Bay Background (Canopy, Sign, Pipes, Rotating Soft Brushes, Tiles, Floor)
        Positioned.fill(
          child: _CarWashBayBackground(
            step: _step,
            idlePhase: _idleToolPhase,
            groundH: groundH,
          ),
        ),

        // Exhaust smoke particles (renders behind car)
        if (_step == _WashStep.driveIn && _smokes.isNotEmpty)
          Positioned(
            left: carL + totalOffsetX + carW * 0.85,
            top: carT + carH * 0.6,
            child: CustomPaint(
              painter: _SmokePainter(_smokes),
            ),
          ),

        // Car interactive container (Emoji + Mud + Soap + Sparks + Real-time Tool)
        Positioned(
          left: carL + totalOffsetX,
          top: carT,
          width: carW,
          height: carH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              _safeSetState(() {
                _requireNewTouch = false;
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onPanUpdate: (d) {
              _safeSetState(() {
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onPanEnd: (_) {
              _safeSetState(() => _isToolActive = false);
            },
            onPanCancel: () {
              _safeSetState(() => _isToolActive = false);
            },
            onTapDown: (d) {
              _safeSetState(() {
                _requireNewTouch = false;
                _isToolActive = true;
                _toolPos = d.localPosition;
              });
              _onDrag(d.localPosition, Size(carW, carH));
            },
            onTapUp: (_) {
              _safeSetState(() => _isToolActive = false);
            },
            onTapCancel: () {
              _safeSetState(() => _isToolActive = false);
            },
            child: _CarCanvas(
              vehicle: _car,
              step: _step,
              dirtGrid: _dirtGrid,
              soapGrid: _soapGrid,
              wetGrid: _wetGrid,
              shineGrid: _shineGrid,
              drops: _drops,
              bubbles: _bubbles,
              sparks: _sparks,
              stickers: _stickers,
              gridN: _gridN,
              toolPos: _toolPos,
              isToolActive: _isToolActive,
              idlePhase: _idleToolPhase,
            ),
          ),
        ),

        // Step complete banner
        if (_bannerText.isNotEmpty)
          Positioned(
            top: areaH * 0.05,
            left: 0, right: 0,
            child: Center(
              child: ScaleTransition(
                scale: _stepBannerAnim,
                child: _StepBanner(text: _bannerText, color: _bannerColor),
              ),
            ),
          ),

        // Confetti overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ConfettiPainter(_confetti),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    const double barHeight = 130.0;

    if (_step == _WashStep.driveIn) {
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          alignment: Alignment.center,
          child: Text(
            '🏎️ 붕붕~ 부우웅! 차가 입장하고 있어요!',
            style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    if (_step == _WashStep.sticker) {
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _car.stickers.length,
                  itemBuilder: (ctx, i) {
                    final selected = i == _selectedStickerIdx;
                    return GestureDetector(
                      onTap: () {
                        AudioManager.instance.playClick();
                        _safeSetState(() => _selectedStickerIdx = i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 48 : 40,
                        height: selected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? KidsTheme.yellow : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: selected ? [
                            BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 8),
                          ] : [],
                        ),
                        child: Center(
                          child: Text(_car.stickers[i], style: TextStyle(fontSize: selected ? 24 : 20)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startDriveOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43E97B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 6,
                    shadowColor: const Color(0xFF43E97B),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🚗', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text('출발! 빵빵~!', style: GoogleFonts.jua(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Text('💨', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hints = <_WashStep, String>{
      _WashStep.water: '💧 손가락으로 쓱쓱 문질러 먼지와 진흙을 깨끗이 씻어내요!',
      _WashStep.soap:  '🫧 자동차 구석구석 문질러 뽀글뽀글 거품을 내봐요!',
      _WashStep.rinse: '🌊 샤워기로 물을 뿌려 비누 거품을 깨끗이 헹궈내요!',
      _WashStep.dry:   '🧻 보들보들 수건으로 쓱싹 문질러 물기를 닦아내요!',
    };

    final nextInfo = <_WashStep, (String, String, Color)>{
      _WashStep.water: ('🫧', '비누 칠하기 시작!', const Color(0xFF7E57C2)),
      _WashStep.soap:  ('🌊', '헹구기 시작!',    const Color(0xFF0288D1)),
      _WashStep.rinse: ('🧻', '수건으로 닦기!',  const Color(0xFFFF7043)),
      _WashStep.dry:   ('🎀', '꾸미기 시작!',    const Color(0xFF26A69A)),
    };

    if (_stepComplete && nextInfo.containsKey(_step)) {
      final info = nextInfo[_step]!;
      return SizedBox(
        height: barHeight,
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          alignment: Alignment.center,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _advanceStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: info.$3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 10,
                shadowColor: info.$3,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(info.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Text(
                    info.$2,
                    style: GoogleFonts.jua(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 26),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: barHeight,
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        alignment: Alignment.center,
        child: Text(
          hints[_step] ?? '',
          textAlign: TextAlign.center,
          style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
