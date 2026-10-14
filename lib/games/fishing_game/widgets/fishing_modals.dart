part of '../fishing_game_game.dart';

extension _FishingGameModalsExtension on _FishingGameState {
  // ── 대물 / 신종 물고기 축하 카드 모달 ──
  Widget _buildCelebrationModal() {
    final fish = _celebrationFish!;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 360),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF9C4), Colors.white],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFFFD54F), width: 5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.5),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fish.isRare ? '🌟 전설의 희귀 어종 발견! 🌟' : '🎉 새로운 물고기 도감 등록! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jua(fontSize: 20, color: const Color(0xFFE65100)),
                  ),
                  const SizedBox(height: 16),

                  // 거대 물고기 아이콘
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.shade50,
                      border: Border.all(color: Colors.amber, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(fish.emoji, style: const TextStyle(fontSize: 64)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    fish.name,
                    style: GoogleFonts.jua(fontSize: 24, color: Colors.blue.shade900),
                  ),
                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${fish.zone.name} • +${fish.points}점 🏅',
                      style: GoogleFonts.jua(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 재미있는 교육용 상식 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFE082), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text('재미있는 바다 상식', style: GoogleFonts.jua(fontSize: 14, color: Colors.brown.shade800)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fish.funFact,
                          style: GoogleFonts.jua(fontSize: 13, color: Colors.brown.shade700, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 확인 버튼
                  ElevatedButton(
                    onPressed: () {
                      AudioManager.instance.playClick();
                      _safeSetState(() => _celebrationFish = null);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('수족관에 저장하기 🐠', style: GoogleFonts.jua(fontSize: 17)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 내 수족관 & 물고기 도감 통합 모달 ──
  Widget _buildAquariumModal() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _safeSetState(() => _showAquariumModal = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: const Color(0xFF00ACC1), width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: DefaultTabController(
                    length: 2,
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        backgroundColor: const Color(0xFF00ACC1),
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        title: Text('🐠 내 수족관 & 도감', style: GoogleFonts.jua(fontSize: 22, color: Colors.white)),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              AudioManager.instance.playClick();
                              _safeSetState(() => _showAquariumModal = false);
                            },
                          ),
                        ],
                        bottom: TabBar(
                          indicatorColor: Colors.amberAccent,
                          indicatorWeight: 4,
                          labelStyle: GoogleFonts.jua(fontSize: 16),
                          labelColor: Colors.amberAccent,
                          unselectedLabelColor: Colors.white70,
                          tabs: [
                            Tab(text: '🌊 살아있는 수족관 (${_caughtSpeciesList.length}마리 / 총 $_totalFishCaught마리)'),
                            Tab(text: '📖 물고기 도감 (${_caughtSpeciesIds.length}/${_speciesList.length})'),
                          ],
                        ),
                      ),
                      body: TabBarView(
                        children: [
                          _buildLiveAquariumTab(),
                          _buildFishEncyclopediaTab(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 탭 1: 살아있는 수족관 뷰 ──
  Widget _buildLiveAquariumTab() {
    return _LiveAquariumTankView(
      fishes: _caughtSpeciesList,
    );
  }

  // ── 탭 2: 물고기 도감 뷰 ──
  Widget _buildFishEncyclopediaTab() {
    final progress = _caughtSpeciesIds.length / _speciesList.length;
    final isAllCollected = _caughtSpeciesIds.length == _speciesList.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 수집률 진행바 카드
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.cyan.shade50],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.cyan.shade200, width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('🏆 도감 완성도', style: GoogleFonts.jua(fontSize: 16, color: Colors.cyan.shade900)),
                    Text(
                      '${_caughtSpeciesIds.length} / ${_speciesList.length}종 (${(progress * 100).toInt()}%)',
                      style: GoogleFonts.jua(fontSize: 16, color: Colors.cyan.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00ACC1)),
                  ),
                ),
              ],
            ),
          ),

          // 올클리어 보상 세레머니 (Rive Rating 5-Star & Reward Chest)
          if (isAllCollected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 70,
                    height: 50,
                    child: RiveAnimation.asset(
                      'assets/rive/rating.riv',
                      animations: ['5_stars'],
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('👑 바다의 낚시 마스터!', style: GoogleFonts.jua(fontSize: 15, color: Colors.amber.shade900)),
                        Text('모든 물고기를 수집했어요! 최고예요!', style: GoogleFonts.jua(fontSize: 12, color: Colors.brown)),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 45,
                    height: 45,
                    child: RiveAnimation.asset(
                      'assets/rive/rewards.riv',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 3개 구역별 물고기 카드 그리드
          ...OceanZone.values.map((zone) {
            final zoneSpecies = _speciesList.where((s) => s.zone == zone).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    zone.name,
                    style: GoogleFonts.jua(fontSize: 17, color: zone.colors.last),
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: zoneSpecies.length,
                  itemBuilder: (context, index) {
                    final sp = zoneSpecies[index];
                    final isCaught = _caughtSpeciesIds.contains(sp.id);

                    return GestureDetector(
                      onTap: () {
                        if (isCaught) {
                          AudioManager.instance.playClick();
                          _safeSetState(() => _celebrationFish = sp);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCaught ? Colors.white : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCaught
                                ? (sp.isRare ? Colors.pinkAccent : Colors.cyan.shade300)
                                : Colors.grey.shade300,
                            width: isCaught ? 2.5 : 1,
                          ),
                          boxShadow: isCaught
                              ? [
                                  BoxShadow(
                                    color: (sp.isRare ? Colors.pinkAccent : Colors.cyan)
                                        .withValues(alpha: 0.18),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isCaught ? sp.emoji : '❓',
                              style: TextStyle(
                                fontSize: isCaught ? 36 : 28,
                                color: isCaught ? null : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isCaught ? sp.name : '미발견',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jua(
                                fontSize: 12,
                                color: isCaught ? Colors.grey.shade800 : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isCaught ? '+${sp.points}점' : '???',
                              style: GoogleFonts.jua(
                                fontSize: 10,
                                color: isCaught ? Colors.amber.shade800 : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}
