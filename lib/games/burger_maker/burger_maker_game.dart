import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

// ── 재료 정의 ──────────────────────────────────
enum Ingredient {
  bunBottom('🍞', '아래 빵'),
  patty('🥩', '패티'),
  lettuce('🥬', '양상추'),
  cheese('🧀', '치즈'),
  tomato('🍅', '토마토'),
  egg('🍳', '달걀'),
  onion('🧅', '양파'),
  sauce('🧈', '소스'),
  bunTop('🥐', '위 빵');

  final String emoji;
  final String label;
  const Ingredient(this.emoji, this.label);
}

// ── 손님 모델 ──────────────────────────────────
class _Customer {
  final String emoji;
  final List<Ingredient> order;

  _Customer({
    required this.emoji,
    required this.order,
  });
}

// ═══════════════════════════════════════════════
class BurgerMakerGame extends StatefulWidget {
  const BurgerMakerGame({super.key});

  @override
  State<BurgerMakerGame> createState() => _BurgerMakerGameState();
}

class _BurgerMakerGameState extends State<BurgerMakerGame>
    with TickerProviderStateMixin {
  final _rng = Random();

  // 재료 팔레트 (레벨별 사용 재료)
  static const _fillings = [
    Ingredient.patty,
    Ingredient.lettuce,
    Ingredient.cheese,
    Ingredient.tomato,
    Ingredient.egg,
    Ingredient.onion,
    Ingredient.sauce,
  ];

  static const _customerEmojis = ['👦', '👧', '🧒', '👨', '👩', '🧑', '🐱', '🐶'];

  // 게임 상태
  int _score = 0;
  int _level = 1;
  int _combo = 0;
  int _totalServed = 0; // 이번 레벨 서빙 수
  bool _isGameOver = false;

  // 현재 서빙 중인 손님
  _Customer? _activeCustomer;

  // 현재 쌓는 중인 버거 스택
  final List<Ingredient> _stack = [];

  // 애니메이션
  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _successController;
  late AnimationController _hintController;
  late Animation<double> _hintAnim;

  // 레벨 설정
  int get _ordersToLevelUp => 3; // 레벨당 서빙 수 (3개 고정, 빠른 성취감)
  int get _maxFillings => min(1 + (_level ~/ 2), 4); // 재료 최대 수 (최대 4개)

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _hintAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );

    _spawnCustomer();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  // ── 손님 생성 ──
  void _spawnCustomer() {
    setState(() {
      _activeCustomer = _generateCustomer();
      _stack.clear();
    });
  }

  _Customer _generateCustomer() {
    final numFillings = _rng.nextInt(_maxFillings) + 1;
    final availableFillings = _fillings.take(min(3 + _level, _fillings.length)).toList();
    availableFillings.shuffle(_rng);
    final order = [
      Ingredient.bunBottom,
      ...availableFillings.take(numFillings),
      Ingredient.bunTop,
    ];
    return _Customer(
      emoji: _customerEmojis[_rng.nextInt(_customerEmojis.length)],
      order: order,
    );
  }

  // ── 재료 탭 ──
  void _onIngredientTapped(Ingredient ingredient) {
    if (_isGameOver) return;
    final customer = _activeCustomer;
    if (customer == null) return;

    // 현재 쌓아야 할 재료 인덱스
    final nextIdx = _stack.length;
    if (nextIdx >= customer.order.length) return; // 방어 코드 (freeze 버그 방지)

    final expected = customer.order[nextIdx];

    if (ingredient == expected) {
      // ✅ 정답
      setState(() => _stack.add(ingredient));
      AudioManager.instance.playSnap();
      HapticFeedback.selectionClick();

      // 버거 완성 체크
      if (_stack.length == customer.order.length) {
        _onBurgerComplete(customer);
      }
    } else {
      // ❌ 오답
      HapticFeedback.heavyImpact();
      AudioManager.instance.playBoing();
      _shakeController.forward(from: 0);
      // 5세 아이를 위해 스택은 유지하고 콤보만 리셋
      setState(() {
        _combo = 0;
      });
    }
  }

  // ── 버거 완성! ──
  void _onBurgerComplete(_Customer customer) {
    final comboBonus = _combo;
    final earned = 10 + comboBonus; // 시간 보너스 제거

    setState(() {
      _score += earned;
      _combo++;
      _totalServed++;
    });

    AudioManager.instance.playSuccess();
    HapticFeedback.mediumImpact();
    _successController.forward(from: 0);

    // 잠깐 보여주고 다음 손님
    Future.delayed(const Duration(milliseconds: 1500), () { // 성공 여운을 위해 약간 길게
      if (!mounted) return;
      _nextCustomer();
    });
  }

  // ── 다음 손님 ──
  void _nextCustomer() {
    setState(() {
      // 레벨업 체크
      if (_totalServed > 0 && _totalServed % _ordersToLevelUp == 0) {
        _level++;
      }

      _spawnCustomer();
    });
  }

  void _restartGame() {
    setState(() {
      _score = 0;
      _level = 1;
      _combo = 0;
      _totalServed = 0;
      _isGameOver = false;
      _stack.clear();
      _spawnCustomer();
    });
  }

  // ── 현재 주문에서 다음에 넣어야 할 재료 ──
  Ingredient? get _nextRequired {
    final c = _activeCustomer;
    if (c == null || _stack.length >= c.order.length) return null;
    return c.order[_stack.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildSingleCustomer(),
                  const SizedBox(height: 16),
                  _buildBurgerArea(),
                  const Spacer(),
                  _buildIngredientPanel(),
                ],
              ),
              if (_isGameOver) _buildGameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── 헤더 ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); Navigator.of(context).pop(); },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              child: const Icon(Icons.close, color: KidsTheme.textDark, size: 26),
            ),
          ),
          const SizedBox(width: 8),
          Text('햄버거 타이쿤 🍔',
            style: GoogleFonts.jua(fontSize: 26, color: KidsTheme.orange)),
          const Spacer(),
          // 콤보
          if (_combo >= 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: KidsTheme.red, borderRadius: BorderRadius.circular(12)),
              child: Text('🔥 ${_combo}콤보', style: GoogleFonts.jua(fontSize: 15, color: Colors.white)),
            ),
          const SizedBox(width: 8),
          // 점수
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]),
            child: Text('⭐ $_score', style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.textDark)),
          ),
          const SizedBox(width: 8),
          // 레벨
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: KidsTheme.purple, borderRadius: BorderRadius.circular(12)),
            child: Text('Lv.$_level', style: GoogleFonts.jua(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── 단일 손님 표시 ──
  Widget _buildSingleCustomer() {
    final customer = _activeCustomer;
    if (customer == null) return const SizedBox(height: 110);

    return Container(
      height: 110,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KidsTheme.orange, width: 4),
          boxShadow: [BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.2), blurRadius: 12)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(customer.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('배고파요! 햄버거 주세요!', style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textDark)),
                const SizedBox(height: 4),
                Text(
                  '재료 ${customer.order.length}개짜리 버거',
                  style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 버거 조립 영역 ──
  Widget _buildBurgerArea() {
    final customer = _activeCustomer;
    if (customer == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
        ),
        child: Row(
          children: [
            // 주문서
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 주문서', style: GoogleFonts.jua(fontSize: 16, color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: List.generate(customer.order.length, (i) {
                      final done = i < _stack.length;
                      final isNext = i == _stack.length;
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: done ? KidsTheme.green.withValues(alpha: 0.15)
                              : (isNext ? KidsTheme.yellow.withValues(alpha: 0.4) : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isNext ? KidsTheme.orange : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          customer.order[i].emoji,
                          style: TextStyle(
                            fontSize: 22,
                            color: done ? Colors.black : (isNext ? Colors.black : Colors.black38),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 쌓인 버거
            Expanded(
              flex: 3,
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (ctx, child) {
                  final offset = sin(_shakeAnim.value * pi * 6) * 6;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('내 버거', style: GoogleFonts.jua(fontSize: 14, color: Colors.grey.shade600)),
                    Container(
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      child: _stack.isEmpty
                          ? Text('재료를 눌러요!',
                              style: GoogleFonts.jua(fontSize: 13, color: Colors.grey.shade400))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: _stack.reversed
                                  .map((ing) => Text(ing.emoji,
                                      style: const TextStyle(fontSize: 28, height: 0.9)))
                                  .toList(),
                            ),
                    ),
                    // 접시
                    Container(
                      width: 120, height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 재료 패널 ──
  Widget _buildIngredientPanel() {
    final next = _nextRequired;
    // 레벨에 따라 보여줄 재료 수 제한 (처음엔 적게, 나중엔 많이)
    final visibleFillings = _fillings.take(min(3 + _level, _fillings.length)).toList();
    final allIngredients = [Ingredient.bunBottom, ...visibleFillings, Ingredient.bunTop];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            next != null ? '다음에 넣을 재료: ${next.emoji} ${next.label}' : '완성 중...',
            style: GoogleFonts.jua(fontSize: 15, color: KidsTheme.orange),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: allIngredients.map((ing) {
              final isNext = ing == next;
              Widget button = AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isNext
                      ? KidsTheme.yellow.withValues(alpha: 0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isNext ? KidsTheme.orange : Colors.grey.shade200,
                    width: isNext ? 4 : 1.5,
                  ),
                  boxShadow: isNext
                      ? [BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.6), blurRadius: 12)]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ing.emoji, style: const TextStyle(fontSize: 36)),
                    Text(ing.label,
                      style: GoogleFonts.jua(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              );

              if (isNext) {
                button = AnimatedBuilder(
                  animation: _hintAnim,
                  builder: (ctx, child) => Transform.scale(
                    scale: _hintAnim.value,
                    child: child,
                  ),
                  child: button,
                );
              }

              return GestureDetector(
                onTap: () => _onIngredientTapped(ing),
                child: button,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── 게임 오버 ──
  Widget _buildGameOverOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: KidsTheme.orange, width: 5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😅', style: TextStyle(fontSize: 64)),
                Text('게임 오버!', style: GoogleFonts.jua(fontSize: 40, color: KidsTheme.red)),
                const SizedBox(height: 8),
                Text('점수: $_score ⭐', style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark)),
                Text('서빙: $_totalServed개 🍔', style: GoogleFonts.jua(fontSize: 22, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _restartGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(color: KidsTheme.green, borderRadius: BorderRadius.circular(20)),
                    child: Text('다시 하기 🔄', style: GoogleFonts.jua(fontSize: 24, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
