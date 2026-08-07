import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import '../../core/audio/audio_manager.dart';
import '../../core/theme/kids_theme.dart';
import 'animal_painters.dart';

class FeedAnimalsGame extends StatefulWidget {
  const FeedAnimalsGame({super.key});

  @override
  State<FeedAnimalsGame> createState() => _FeedAnimalsGameState();
}

class AnimalMatch {
  final String animal;
  final String food;
  final String animalName;
  bool isFed = false;
  bool isChewing = false;

  AnimalMatch(this.animal, this.food, this.animalName);
}

class _FeedAnimalsGameState extends State<FeedAnimalsGame>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  List<AnimalMatch> _matches = [];
  List<String> _foodsToFeed = [];

  // 20종 다양한 동물 풀 — 덱(Deck) 순환 구조로 중복 최소화
  final List<AnimalMatch> _allPossibleMatches = [
    AnimalMatch('🐶', '🦴', 'dog'),       // 강아지 → 뼈다귀
    AnimalMatch('🐱', '🐟', 'cat'),       // 고양이 → 물고기
    AnimalMatch('🐰', '🥕', 'rabbit'),    // 토끼 → 당근
    AnimalMatch('🐻', '🍯', 'bear'),      // 곰 → 꿀
    AnimalMatch('🐒', '🍌', 'monkey'),    // 원숭이 → 바나나
    AnimalMatch('🐼', '🎋', 'panda'),     // 판다 → 대나무
    AnimalMatch('🦊', '🍇', 'fox'),       // 여우 → 포도
    AnimalMatch('🦁', '🥩', 'lion'),      // 사자 → 고기
    AnimalMatch('🐘', '🍎', 'elephant'),  // 코끼리 → 사과
    AnimalMatch('🐸', '🐛', 'frog'),      // 개구리 → 벌레
    AnimalMatch('🦜', '🥜', 'parrot'),    // 앵무새 → 땅콩/견과류
    AnimalMatch('🐧', '🦑', 'penguin'),   // 펭귄 → 오징어
    AnimalMatch('🐭', '🧀', 'mouse'),     // 쥐 → 치즈
    AnimalMatch('🐿️', '🌰', 'squirrel'),  // 다람쥐 → 도토리
    AnimalMatch('🐮', '🌾', 'cow'),       // 소 → 풀
    AnimalMatch('🐷', '🌽', 'pig'),       // 돼지 → 옥수수
    AnimalMatch('🦒', '🌿', 'giraffe'),   // 기린 → 나뭇잎
    AnimalMatch('🦛', '🍉', 'hippo'),     // 하마 → 수박
    AnimalMatch('🦔', '🍄', 'hedgehog'),  // 고슴도치 → 버섯
    AnimalMatch('🐥', '🍓', 'chick'),     // 병아리 → 딸기
  ];

  // 덱(Deck) 기반 중복 방지 큐
  List<AnimalMatch> _deck = [];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _startRound();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  int _difficultyLevel = 2; // 1: 1단계(2마리), 2: 2단계(3마리), 3: 3단계(4마리), 4: 4단계(5마리)

  int get _animalCount {
    switch (_difficultyLevel) {
      case 1: return 2;
      case 2: return 3;
      case 3: return 4;
      case 4: default: return 5;
    }
  }

  void _startRound() {
    final count = _animalCount;
    if (_deck.length < count) {
      final newDeck = List<AnimalMatch>.from(_allPossibleMatches)..shuffle();
      if (_matches.isNotEmpty) {
        final lastAnimals = _matches.map((m) => m.animal).toSet();
        final nonOverlapping = newDeck.where((m) => !lastAnimals.contains(m.animal)).toList();
        final overlapping = newDeck.where((m) => lastAnimals.contains(m.animal)).toList();
        _deck = [..._deck, ...nonOverlapping, ...overlapping];
      } else {
        _deck = [..._deck, ...newDeck];
      }
    }

    _matches = _deck
        .take(count)
        .map((m) => AnimalMatch(m.animal, m.food, m.animalName))
        .toList();
    _deck.removeRange(0, count);
    _foodsToFeed = _matches.map((m) => m.food).toList()..shuffle();
    setState(() {});
  }

  void _onFoodDropped(String food, AnimalMatch match) {
    if (match.food == food && !match.isFed) {
      AudioManager.instance.playAnimalFeedingSound(match.animalName);
      HapticFeedback.lightImpact();
      setState(() {
        match.isFed = true;
        match.isChewing = true;
        _foodsToFeed.remove(food);

        if (_foodsToFeed.isEmpty) {
          Future.delayed(const Duration(milliseconds: 700), () {
            if (!mounted) return;
            _confettiController.play();
            AudioManager.instance.playFeedAnimalsSuccess();
            _showCompletionDialog();
          });
        }
      });
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            match.isChewing = false;
          });
        }
      });
    } else if (!match.isFed) {
      AudioManager.instance.playDamage();
      HapticFeedback.heavyImpact();
    }
  }

  /// 라운드 성공 시 아기자기한 축하 완성 팝업
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 🥳 🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text(
                '참 잘했어요!',
                style: GoogleFonts.jua(
                  fontSize: 26,
                  color: KidsTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '모든 동물이 배부르게\n맘마를 다 먹었어요! ❤️',
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(
                  fontSize: 16,
                  color: Colors.brown.shade700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  AudioManager.instance.playClick();
                  Navigator.pop(ctx);
                  _startRound();
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: KidsTheme.borderDark, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF2E7D32),
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🚀', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          '다음 한 판 더!',
                          style: GoogleFonts.jua(
                            fontSize: 19,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Animated Nature Background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _NatureBackgroundPainter(_floatAnimation.value),
                  );
                },
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 8),
                  _buildInstructionBanner(),
                  const SizedBox(height: 12),
                  // 동물 카드 그리드 (Wrap)
                  Expanded(
                    child: _buildAnimalsGrid(),
                  ),
                  const SizedBox(height: 8),
                  // 음식 가로 슬라이드
                  _buildFoodTray(),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                colors: const [
                  Color(0xFFFF6B6B),
                  Color(0xFF4ECDC4),
                  Color(0xFFFFE66D),
                  Color(0xFF95E1D3),
                  Color(0xFFF38181),
                  Color(0xFF6BCB77),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 뒤로가기 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8A8A), Color(0xFFFF5252)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFC62828),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          // 중앙 아기자기한 타이틀 뱃지
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '동물 맘마주기',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jua(
                        fontSize: 17,
                        color: KidsTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ⭐ 몇 마리? (단계 선택) 버튼
          GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              _showDifficultyDialog();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KidsTheme.borderDark, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFE65100),
                    offset: Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '몇 마리?',
                    style: GoogleFonts.jua(
                      fontSize: 15,
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

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('⭐ 동물 몇 마리? 🐰', style: GoogleFonts.jua(fontSize: 22, color: KidsTheme.textDark)),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _dialogDiffBtn(setModalState, 1, '1단계\n(동물 2마리)', '⭐ 초간단'),
                      const SizedBox(width: 6),
                      _dialogDiffBtn(setModalState, 2, '2단계\n(동물 3마리)', '⭐⭐ 쉬움'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dialogDiffBtn(setModalState, 3, '3단계\n(동물 4마리)', '⭐⭐⭐ 보통'),
                      const SizedBox(width: 6),
                      _dialogDiffBtn(setModalState, 4, '4단계\n(동물 5마리)', '⭐⭐⭐⭐ 도전'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      AudioManager.instance.playClick();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text('확인 👍', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dialogDiffBtn(StateSetter setModalState, int lvl, String label, String stars) {
    final selected = _difficultyLevel == lvl;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioManager.instance.playClick();
          setModalState(() { _difficultyLevel = lvl; });
          setState(() {
            _deck.clear();
            _startRound();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.orange : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? Colors.deepOrange : Colors.orange.shade200, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stars,
                style: GoogleFonts.jua(fontSize: 11, color: selected ? Colors.white : Colors.deepOrange),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.jua(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.brown.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidsTheme.borderDark, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            '알맞은 맘마를 드래그해서 줘요!',
            style: GoogleFonts.jua(
              fontSize: 18,
              color: KidsTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // -- 동물 카드 그리드 (Wrap 레이아웃) --
  Widget _buildAnimalsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _matches.length;
        // 3마리 이하: 1줄. 4마리: 2x2. 5마리: 3+2
        final crossCount = count <= 3 ? count : (count == 4 ? 2 : 3);
        const spacing = 10.0;
        final totalSpacing = spacing * (crossCount - 1);
        final cardW = ((constraints.maxWidth - 40) - totalSpacing) / crossCount;
        final cardH = cardW * 1.3;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                count,
                (i) => SizedBox(
                  width: cardW,
                  height: cardH,
                  child: _buildAnimalTarget(_matches[i], i),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimalTarget(AnimalMatch match, int index) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => !match.isFed,
      onAcceptWithDetails: (details) => _onFoodDropped(details.data, match),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: isHovering
                ? const LinearGradient(
                    colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : animalCardGradient(match.animalName, match.isFed),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: match.isFed
                  ? const Color(0xFF4CAF50)
                  : isHovering
                      ? KidsTheme.green
                      : KidsTheme.borderDark,
              width: isHovering ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: match.isFed
                    ? const Color(0xFF4CAF50)
                    : isHovering
                        ? KidsTheme.green
                        : KidsTheme.borderDark,
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 동물 얼굴 애니메이션
                  Expanded(
                    child: Center(
                      child: buildAnimatedAnimal(
                        match.animalName,
                        50,
                        _floatController,
                        isHovering: isHovering,
                        isFed: match.isFed,
                      ),
                    ),
                  ),
                  // 동물 이름
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                    child: Text(
                      _animalShortName(match.animalName),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jua(
                        fontSize: 14,
                        color: KidsTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // 배고파요! 말풍선 (위쪽)
              if (!match.isFed)
                Positioned(
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orangeAccent, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(match.food, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 2),
                        Text(
                          '줘요!',
                          style: GoogleFonts.jua(fontSize: 10, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              // 냠냠! 말풍선
              if (match.isFed)
                Positioned(
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF176),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade800, width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💖', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 2),
                        Text(
                          match.isChewing ? '냠냠! 😋' : '맛있다! ❤️',
                          style: GoogleFonts.jua(fontSize: 11, color: Colors.brown.shade900, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              // 완료 체크
              if (match.isFed)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _animalShortName(String name) {
    const map = {
      'dog': '강아지', 'cat': '고양이', 'rabbit': '토끼',
      'bear': '곰', 'monkey': '원숭이', 'panda': '판다',
      'fox': '여우', 'lion': '사자', 'elephant': '코끼리',
      'frog': '개구리', 'parrot': '앵무새', 'penguin': '펭귄',
      'mouse': '쥐', 'squirrel': '다람쥐', 'cow': '소',
      'pig': '돼지', 'giraffe': '기린', 'hippo': '하마',
      'hedgehog': '고슴도치', 'chick': '병아리',
    };
    return map[name] ?? name;
  }


  Widget _buildFoodTray() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: KidsTheme.borderDark, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF5A3A1A),
            offset: Offset(0, 5),
            blurRadius: 0,
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA0714F), Color(0xFF7A4F2D)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              '🍱  맘마 쟁반  (드래그해서 줘요!)',
              style: GoogleFonts.jua(
                fontSize: 14,
                color: Colors.white.withAlpha(230),
              ),
            ),
          ),
          if (_foodsToFeed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade300, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 8),
                      Text(
                        '다 줬어요! 참 잘했어요! ❤️',
                        style: GoogleFonts.jua(
                          fontSize: 19,
                          color: KidsTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // 음식 한 줄 자동 크기 조절 (스크롤 없이 드래그 바로 가능)
            LayoutBuilder(
              builder: (context, constraints) {
                final count = _foodsToFeed.length;
                const spacing = 10.0;
                final totalSpacing = spacing * (count - 1);
                final itemSize = ((constraints.maxWidth - 32) - totalSpacing) / count;
                final clampedSize = itemSize.clamp(48.0, 76.0);
                final fontSize = clampedSize * 0.55;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _foodsToFeed
                        .map((food) => _buildDraggableFood(food, clampedSize, fontSize))
                        .toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableFood(String food, double size, double fontSize) {
    return Draggable<String>(
      data: food,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.25,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
              ],
            ),
            child: Center(
              child: Text(
                food,
                style: TextStyle(fontSize: fontSize + 2, decoration: TextDecoration.none),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: Center(child: Text(food, style: TextStyle(fontSize: fontSize))),
        ),
      ),
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * 0.35),
            child: child,
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(218),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Center(child: Text(food, style: TextStyle(fontSize: fontSize))),
        ),
      ),
    );
  }
}

class _NatureBackgroundPainter extends CustomPainter {
  final double floatOffset;

  _NatureBackgroundPainter(this.floatOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFB8E4FF),
          Color(0xFFD4F0C0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    _drawSun(canvas, Offset(w * 0.85, h * 0.10), floatOffset);

    _drawCloud(canvas, Offset(w * 0.15, h * 0.07 + floatOffset * 0.4), 0.85);
    _drawCloud(canvas, Offset(w * 0.55, h * 0.04 + floatOffset * 0.25), 1.1);
    _drawCloud(canvas, Offset(w * 0.75, h * 0.12 + floatOffset * 0.3), 0.7);

    _drawHill(canvas, size,
        yCenter: h * 0.65, width: w * 1.3, color: const Color(0xFF8BC34A));
    _drawHill(canvas, size,
        xOffset: w * 0.3,
        yCenter: h * 0.70,
        width: w * 1.1,
        color: const Color(0xFF7CB342));

    final groundPaint = Paint()..color = const Color(0xFF558B2F);
    final groundPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.76, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, groundPaint);

    final grassPaint = Paint()..color = const Color(0xFF66BB6A);
    final grassPath = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.5, h * 0.72)
      ..quadraticBezierTo(w * 0.75, h * 0.76, w, h * 0.72)
      ..lineTo(w, h * 0.77)
      ..quadraticBezierTo(w * 0.75, h * 0.81, w * 0.5, h * 0.77)
      ..quadraticBezierTo(w * 0.25, h * 0.73, 0, h * 0.77)
      ..close();
    canvas.drawPath(grassPath, grassPaint);

    _drawTree(canvas, Offset(w * 0.05, h * 0.70));
    _drawTree(canvas, Offset(w * 0.93, h * 0.69));
    _drawTree(canvas, Offset(w * 0.18, h * 0.73), scale: 0.75);
    _drawTree(canvas, Offset(w * 0.82, h * 0.72), scale: 0.8);

    final flowers = [
      Offset(w * 0.12, h * 0.78),
      Offset(w * 0.28, h * 0.82),
      Offset(w * 0.45, h * 0.80),
      Offset(w * 0.60, h * 0.83),
      Offset(w * 0.75, h * 0.79),
      Offset(w * 0.88, h * 0.81),
    ];
    final flowerColors = [
      const Color(0xFFFFEB3B),
      const Color(0xFFFF80AB),
      const Color(0xFF80DEEA),
      const Color(0xFFFFA726),
      const Color(0xFFCE93D8),
      const Color(0xFF80CBC4),
    ];
    for (int i = 0; i < flowers.length; i++) {
      _drawFlower(
        canvas,
        flowers[i].translate(0, floatOffset * (i.isEven ? 0.3 : -0.2)),
        flowerColors[i % flowerColors.length],
      );
    }

    _drawMushroom(canvas, Offset(w * 0.35, h * 0.75));
    _drawMushroom(canvas, Offset(w * 0.68, h * 0.77), small: true);
  }

  void _drawSun(Canvas canvas, Offset center, double pulse) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD54F).withOpacity(0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + pulse * 0.02;
      final start =
          Offset(center.dx + cos(angle) * 22, center.dy + sin(angle) * 22);
      final end =
          Offset(center.dx + cos(angle) * 38, center.dy + sin(angle) * 38);
      canvas.drawLine(start, end, rayPaint);
    }
    canvas.drawCircle(center, 20, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(
        center.translate(-5, -5), 8, Paint()..color = const Color(0xFFFFF9C4));
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withOpacity(0.92);
    final radii = [22.0, 16.0, 18.0, 14.0];
    final offsets = [
      Offset.zero,
      const Offset(-28, 8),
      const Offset(26, 6),
      const Offset(-50, 14),
    ];
    for (int i = 0; i < radii.length; i++) {
      canvas.drawCircle(
          center + offsets[i] * scale, radii[i] * scale, paint);
    }
  }

  void _drawHill(Canvas canvas, Size size,
      {double xOffset = 0,
      required double yCenter,
      required double width,
      required Color color}) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(xOffset, size.height)
      ..quadraticBezierTo(xOffset + width / 2, yCenter - width * 0.25,
          xOffset + width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTree(Canvas canvas, Offset base, {double scale = 1.0}) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: base.translate(0, -20 * scale),
            width: 12 * scale,
            height: 40 * scale),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF795548),
    );
    canvas.drawCircle(
        base.translate(0, -55 * scale), 28 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(-10 * scale, -45 * scale), 20 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(10 * scale, -45 * scale), 22 * scale, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(
        base.translate(0, -65 * scale), 18 * scale, Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawFlower(Canvas canvas, Offset center, Color color) {
    final petalPaint = Paint()..color = color;
    final centerPaint = Paint()..color = const Color(0xFFFFEB3B);
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawCircle(
          center + Offset(cos(angle) * 7, sin(angle) * 7), 5, petalPaint);
    }
    canvas.drawCircle(center, 5, centerPaint);
    canvas.drawLine(center, center.translate(0, 12),
        Paint()
          ..color = const Color(0xFF66BB6A)
          ..strokeWidth = 2);
  }

  void _drawMushroom(Canvas canvas, Offset base, {bool small = false}) {
    final s = small ? 0.7 : 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: base.translate(0, -8 * s),
            width: 14 * s,
            height: 16 * s),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF5F5F5),
    );
    final capPath = Path()
      ..moveTo(base.dx - 18 * s, base.dy - 14 * s)
      ..quadraticBezierTo(
          base.dx, base.dy - 36 * s, base.dx + 18 * s, base.dy - 14 * s)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFFE53935));
    final spotPaint = Paint()..color = Colors.white.withOpacity(0.85);
    canvas.drawCircle(base.translate(-5 * s, -22 * s), 3.5 * s, spotPaint);
    canvas.drawCircle(base.translate(5 * s, -25 * s), 2.5 * s, spotPaint);
    canvas.drawCircle(base.translate(0, -19 * s), 2 * s, spotPaint);
  }

  @override
  bool shouldRepaint(_NatureBackgroundPainter old) =>
      old.floatOffset != floatOffset;
}
