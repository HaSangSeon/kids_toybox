part of '../fishing_game_game.dart';

extension _FishingGameStageExtension on _FishingGameState {
  // ── 헤더 카드 위젯 ──
  Widget _buildHeaderCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 뒤로가기 버튼
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.red.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, color: KidsTheme.red, size: 14),
                  const SizedBox(width: 4),
                  Text('그만하기', style: GoogleFonts.jua(fontSize: 13, color: KidsTheme.red)),
                ],
              ),
            ),
          ),
        ),

        // 내 수족관 & 도감 버튼 (잡은 마릿수 뱃지 표시)
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AudioManager.instance.playClick();
              _safeSetState(() => _showAquariumModal = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐠', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '수족관&도감 (${_caughtSpeciesIds.length}/${_speciesList.length})',
                    style: GoogleFonts.jua(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 바다 바꾸기 버튼
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              AudioManager.instance.playClick();
              _safeSetState(() => _showZoneSelect = true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _stageColors[_stage - 1], width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🗺️ 바다', style: GoogleFonts.jua(fontSize: 13, color: _stageColors[_stage - 1])),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down_rounded, color: _stageColors[_stage - 1], size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 시바 선장과 멋진 원목 낚시선 ──
  Widget _buildFishingBoat(double boatY) {
    return SizedBox(
      width: 115,
      height: 75,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 시바 선장의 말풍선 (상황별 반응)
          Positioned(
            top: -24,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                _isShibaCelebrating
                    ? '월척이다 멍! 🐶🎉'
                    : (_isHookDropping ? '물려라 멍! 🎣' : '물고기야 모여라~ 🐟'),
                style: GoogleFonts.jua(fontSize: 11, color: Colors.brown.shade800),
              ),
            ),
          ),

          // 낚싯대 (카본 로드)
          Positioned(
            left: 45,
            top: 2,
            child: Transform.rotate(
              angle: -0.45,
              child: Container(
                width: 6,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF424242), Color(0xFF212121)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.amberAccent, width: 0.8),
                ),
              ),
            ),
          ),

          // Rive 시바 선장 (assets/rive/dog.riv)
          Positioned(
            left: 12,
            top: 6,
            width: 48,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: RiveAnimation.asset(
                'assets/rive/dog.riv',
                artboard: 'Shiba',
                animations: [_isShibaCelebrating ? 'WinEndState' : 'Anim_shiba'],
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 선장 모자 👨‍✈️
          Positioned(
            left: 20,
            top: 0,
            child: const Text('👨‍✈️', style: TextStyle(fontSize: 16)),
          ),

          // 원목 선체 (보트 하단)
          Positioned(
            bottom: 0,
            left: 0,
            right: 10,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(28),
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Text('🛟', style: TextStyle(fontSize: 14)), // 구명환
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 12,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('TOYBOX', style: GoogleFonts.jua(fontSize: 7, color: Colors.brown.shade900)),
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

  // ── 하단 플로팅 미끼 뿌리기 버튼 ──
  Widget _buildBaitButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: _throwBait,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.4),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍞', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('미끼 뿌리기', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
                  Text('물고기가 모여요!', style: GoogleFonts.jua(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 바다 배경 ──
  Widget _buildOceanBackground() {
    final si = _stage - 1;
    final skyColors = _stageSkyColors[si];
    final oceanColors = _stageOceanColors[si];
    final weatherEmoji = _stageWeather[si];
    final sunEmoji = _stageSunEmoji[si];

    return Column(
      children: [
        // 하늘 영역 (28%)
        Expanded(
          flex: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: skyColors,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 75,
                  right: 16,
                  child: Text(sunEmoji, style: const TextStyle(fontSize: 26)),
                ),
                AnimatedBuilder(
                  animation: _cloudDriftAnim,
                  builder: (ctx, child) {
                    final screenW = _screenSize.width > 0 ? _screenSize.width : 400;
                    final offset = (_cloudDriftAnim.value * screenW * 1.3) - screenW * 0.15;
                    return Positioned(
                      left: offset % (screenW + 80) - 80,
                      top: 80,
                      child: Text(weatherEmoji, style: TextStyle(
                        fontSize: 32,
                        color: si == 2 ? Colors.white54 : Colors.white,
                      )),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _cloudDriftAnim,
                  builder: (ctx, child) {
                    final screenW = _screenSize.width > 0 ? _screenSize.width : 400;
                    final offset = ((_cloudDriftAnim.value + 0.5) * screenW * 1.3) - screenW * 0.15;
                    return Positioned(
                      left: offset % (screenW + 60) - 60,
                      top: 96,
                      child: Text(weatherEmoji, style: TextStyle(
                        fontSize: 22,
                        color: si == 2 ? Colors.white38 : Colors.white70,
                      )),
                    );
                  },
                ),
                if (si == 2)
                  ...List.generate(6, (i) => Positioned(
                    left: (i * 55.0 + 20).toDouble(),
                    top: 8 + (i % 3) * 10.0,
                    child: Text('✨', style: TextStyle(fontSize: 12 + (i % 3) * 4.0)),
                  )),
              ],
            ),
          ),
        ),
        // 바다 영역 (72%)
        Expanded(
          flex: 72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: oceanColors,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                if (si == 0) ...[
                  const Positioned(bottom: 20, left: 30, child: Text('🪸', style: TextStyle(fontSize: 22))),
                  const Positioned(bottom: 10, left: 90, child: Text('🐠', style: TextStyle(fontSize: 16))),
                  const Positioned(bottom: 25, right: 40, child: Text('🐚', style: TextStyle(fontSize: 20))),
                ],
                if (si == 1) ...[
                  const Positioned(bottom: 30, left: 20, child: Text('🌿', style: TextStyle(fontSize: 24))),
                  const Positioned(bottom: 15, right: 50, child: Text('🐡', style: TextStyle(fontSize: 18))),
                ],
                if (si == 2) ...[
                  const Positioned(bottom: 35, left: 15, child: Text('🪼', style: TextStyle(fontSize: 26))),
                  const Positioned(bottom: 20, left: 80, child: Text('✨', style: TextStyle(fontSize: 14))),
                  const Positioned(bottom: 40, right: 25, child: Text('🐙', style: TextStyle(fontSize: 22))),
                  const Positioned(bottom: 10, right: 80, child: Text('✨', style: TextStyle(fontSize: 10))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 구역 이동 오버레이 ──
  Widget _buildZoneSelectOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _safeSetState(() => _showZoneSelect = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.65),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380, maxHeight: 600),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: KidsTheme.blue, width: 6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('🗺️ 바다 이동', style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.blue)),
                          IconButton(
                            iconSize: 32,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close_rounded, color: Colors.grey),
                            onPressed: () {
                              AudioManager.instance.playClick();
                              _safeSetState(() => _showZoneSelect = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('어떤 바다에서 낚시할까요?', style: GoogleFonts.jua(fontSize: 18, color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                      ...List.generate(3, (index) {
                        final isCurrent = _stage == index + 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              AudioManager.instance.playClick();
                              _safeSetState(() => _showZoneSelect = false);
                              _changeZone(index + 1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              decoration: BoxDecoration(
                                color: isCurrent ? _stageColors[index] : _stageColors[index].withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _stageColors[index], width: 3.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    _stageNames[index],
                                    style: GoogleFonts.jua(
                                      fontSize: 22,
                                      color: isCurrent ? Colors.white : _stageColors[index],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isCurrent)
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
