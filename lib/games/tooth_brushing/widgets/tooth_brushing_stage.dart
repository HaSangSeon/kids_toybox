part of '../tooth_brushing_game.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOOTH BRUSHING STAGE & SELECTION UI EXTENSION
// ═══════════════════════════════════════════════════════════════════════════════

extension _ToothBrushingStageExtension on _ToothBrushingGameState {
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 1. Home Button (Always goes back to Main Lobby)
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.home_rounded, color: Color(0xFFE65100), size: 24),
            ),
          ),

          // 2. Step-by-Step Back Button (Only visible after selecting animal)
          if (_step != BrushStep.selectAnimal) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _onStepBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00897B), size: 20),
              ),
            ),
          ],
          const SizedBox(width: 12),

          // Title & Step Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🪥 치카치카 양치 놀이',
                  style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFF263238)),
                ),
                Text(
                  _getStepTitle(),
                  style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFF00897B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_step) {
      case BrushStep.selectAnimal:
        return '동물 친구를 골라보세요! 🐾';
      case BrushStep.eating:
        return '맛있는 간식을 먹여주세요! 🍩';
      case BrushStep.selectPaste:
        return '좋아하는 치약을 골라봐요! 🍓';
      case BrushStep.brushing:
        return '칫솔로 이를 쓱싹쓱싹 문질러요! 🪥';
      case BrushStep.rinsing:
        return '물로 거품을 시원하게 헹궈요! 💧';
      case BrushStep.complete:
        return '이가 반짝반짝 눈부셔요! 🌟';
    }
  }

  Widget _buildStepProgressBar() {
    final steps = ['동물 선택', '간식 먹기', '치약 선택', '치카치카', '물 헹구기', '반짝반짝'];
    final currentIdx = _step.index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isDone = index < currentIdx;
          final isCurrent = index == currentIdx;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF00ACC1)
                    : (isDone ? const Color(0xFF80CBC4) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBodyContent(BoxConstraints constraints) {
    if (_step == BrushStep.selectAnimal) {
      return _buildAnimalSelectView();
    }
    return _buildUnifiedGameStage(constraints);
  }

  Widget _buildAnimalSelectView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.teal.withValues(alpha: 0.15), blurRadius: 10),
              ],
            ),
            child: Text(
              '양치질이 필요한 동물 친구를 골라주세요! 🦷',
              style: GoogleFonts.jua(fontSize: 17, color: const Color(0xFF00695C)),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _kAnimals.map((animal) {
                  return GestureDetector(
                    onTap: () => _onSelectAnimal(animal),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: animal.primaryColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: animal.primaryColor.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: animal.faceColor.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: animal.id == 'dog'
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(35),
                                        child: const SizedBox(
                                          width: 70,
                                          height: 70,
                                          child: RiveAnimation.asset(
                                            'assets/rive/dog.riv',
                                            artboard: 'Shiba',
                                            animations: ['Anim_shiba'],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Text(animal.emoji, style: const TextStyle(fontSize: 44)),
                              ),
                              if (animal.id == 'dog')
                                Positioned(
                                  top: -6,
                                  right: -12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFFF5722), Color(0xFFFF9800)]),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.4), blurRadius: 6),
                                      ],
                                    ),
                                    child: const Text(
                                      'Rive 3D ✨',
                                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            animal.name,
                            style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFF37474F)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedGameStage(BoxConstraints constraints) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 8),

            // 1. FIXED HEIGHT SPEECH BUBBLE (Exact 54px)
            Container(
              height: 54,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: _animal.primaryColor, width: 2.5),
                boxShadow: [
                  BoxShadow(color: _animal.primaryColor.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _getFixedDialogueText(),
                  key: ValueKey(_getFixedDialogueText()),
                  style: GoogleFonts.jua(fontSize: 16, color: const Color(0xFF263238)),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 2. FIXED CENTER MASCOT (280x280 Canvas ALWAYS at the exact same screen location)
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Base Animal Head
                      _buildAnimalHeadWidget(
                        showDirty: _step == BrushStep.selectPaste || _step == BrushStep.brushing || (_step == BrushStep.eating && _customDialogue != null),
                        openWide: _isMouthOpen,
                        isShining: _step == BrushStep.complete || _isEating,
                      ),

                      // Interactive Layer for Brushing
                      if (_step == BrushStep.brushing) ...[
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            onPanUpdate: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            onPanEnd: (_) => _onBrushPanEnd(),
                            onPanCancel: () => _onBrushPanEnd(),
                            onTapDown: (details) => _onBrushPan(details.localPosition, const Size(280, 280)),
                            onTapUp: (_) => _onBrushPanEnd(),
                            onTapCancel: () => _onBrushPanEnd(),
                            behavior: HitTestBehavior.opaque,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _FoamAndParticlePainter(
                                foams: _foams,
                                sparkles: _sparkles,
                              ),
                            ),
                          ),
                        ),
                        if (_brushTouchPos != null)
                          Positioned(
                            left: _brushTouchPos!.dx - 40,
                            top: _brushTouchPos!.dy - 95,
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _brushWiggleCtrl,
                                builder: (context, child) {
                                  return _BespokeToothbrushWidget(
                                    pasteColor: _paste.color,
                                    wiggleProgress: _brushWiggleCtrl.value,
                                  );
                                },
                              ),
                            ),
                          ),
                      ],

                      // Interactive Layer for Rinsing
                      if (_step == BrushStep.rinsing)
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (details) => _onRinseSpray(details.localPosition, const Size(280, 280)),
                            onPanEnd: (_) => _onRinsePanEnd(),
                            onPanCancel: () => _onRinsePanEnd(),
                            onTapDown: (details) => _onRinseSpray(details.localPosition, const Size(280, 280)),
                            onTapUp: (_) => _onRinsePanEnd(),
                            onTapCancel: () => _onRinsePanEnd(),
                            behavior: HitTestBehavior.opaque,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: _RinsePainter(
                                foams: _foams,
                                waterDrops: _waterDrops,
                              ),
                            ),
                          ),
                        ),

                      // Celebration Sparkles for Complete
                      if (_step == BrushStep.complete) ...[
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _sparkleLoopCtrl,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _CelebrationSparklePainter(progress: _sparkleLoopCtrl.value),
                              );
                            },
                          ),
                        ),
                        if (_animal.id == 'dog')
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.96),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: const RiveAnimation.asset(
                                'assets/rive/dog.riv',
                                artboard: 'Shiba',
                                animations: ['WinEndState'],
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                      ],

                      // Floating Hearts while eating
                      if (_isEating)
                        Positioned(
                          top: -10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('💖', style: TextStyle(fontSize: 28)),
                              SizedBox(width: 40),
                              Text('✨', style: TextStyle(fontSize: 32)),
                              SizedBox(width: 40),
                              Text('😋', style: TextStyle(fontSize: 28)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. FIXED HEIGHT BOTTOM CONTROL TRAY (Exact 190px, never causes jumping)
            Container(
              height: 190,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _getBottomTrayBorderColor(), width: 2.5),
                boxShadow: [
                  BoxShadow(color: _getBottomTrayBorderColor().withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBottomTrayContent(),
              ),
            ),
          ],
        ),

        // Flying Snack Animation
        if (_flyingSnack != null)
          AnimatedBuilder(
            animation: _snackFlyCtrl,
            builder: (context, child) {
              final t = _snackFlyCtrl.value;
              final startY = constraints.maxHeight - 120;
              final targetY = constraints.maxHeight * 0.38;
              final currentY = startY + (targetY - startY) * t;
              final scale = 1.0 + sin(t * pi) * 0.5;
              final rotation = t * pi * 2;

              return Positioned(
                left: (constraints.maxWidth / 2) - 30,
                top: currentY,
                child: Opacity(
                  opacity: (1.0 - (t > 0.85 ? (t - 0.85) / 0.15 : 0.0)).clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        _flyingSnack!.emoji,
                        style: const TextStyle(fontSize: 54),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getFixedDialogueText() {
    if (_customDialogue != null) return _customDialogue!;
    switch (_step) {
      case BrushStep.eating:
        if (_hasDecayed) {
          return '으악! 이에 세균이 생겼어요! 얼른 양치하러 가요! 🪥';
        }
        return '${_animal.name}: "배가 고파요! 달콤한 간식을 주세요~" 😋';
      case BrushStep.selectPaste:
        return '치아에 세균이 생겼어요! 좋아하는 치약을 골라요! 🍓';
      case BrushStep.brushing:
        return '손가락으로 이를 쓱싹쓱싹 문질러요! 🫧';
      case BrushStep.rinsing:
        return '물방울을 쏴아~ 뿌려서 시원하게 헹궈요! 💧';
      case BrushStep.complete:
        return '🎉 치카치카 대성공! 이가 반짝반짝 눈부셔요! ✨';
      default:
        return '';
    }
  }

  Color _getBottomTrayBorderColor() {
    switch (_step) {
      case BrushStep.eating:
        return Colors.orange.shade300;
      case BrushStep.selectPaste:
        return const Color(0xFF80DEEA);
      case BrushStep.brushing:
        return _paste.color;
      case BrushStep.rinsing:
        return const Color(0xFF0288D1);
      case BrushStep.complete:
        return Colors.amber;
      default:
        return Colors.grey.shade300;
    }
  }
}
