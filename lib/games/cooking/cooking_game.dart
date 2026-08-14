import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/audio/audio_manager.dart';

// ── 재료 ────────────────────────────────────────────────────────────────────
class _Ingredient {
  final String key;
  final String emoji;
  final String label;
  final String category; // 'main', 'veggie', 'sweet', 'base', 'topping'
  const _Ingredient(this.key, this.emoji, this.label, this.category);
}

// ── 요리 결과 ──────────────────────────────────────────────────────────────
class _Dish {
  final String emoji;
  final String name;
  final String description;
  final Color plateColor;
  final String dishType; // 'plate', 'bowl', 'glass', 'tray'
  const _Dish(this.emoji, this.name, this.description, this.plateColor, {this.dishType = 'plate'});
}

// ── 게임 단계 ──────────────────────────────────────────────────────────────
enum _Phase { pick, stir, cooking, result }

// ── 떨어지는 재료 애니메이션 상태 ──────────────────────────────────────────
class _FallingItem {
  final String emoji;
  double progress; // 0→1
  _FallingItem(this.emoji, {this.progress = 0.0});
}

// ════════════════════════════════════════════════════════════════════════════
class CookingGame extends StatefulWidget {
  const CookingGame({super.key});
  @override
  State<CookingGame> createState() => _ColorMixingGameState();
}

class _ColorMixingGameState extends State<CookingGame>
    with TickerProviderStateMixin {

  // ── 20가지 다양한 재료 ───────────────────────────────────────────────────
  static const List<_Ingredient> _kIngredients = [
    _Ingredient('tomato',    '🍅', '토마토',  'veggie'),
    _Ingredient('carrot',    '🥕', '당근',    'veggie'),
    _Ingredient('corn',      '🌽', '옥수수',  'veggie'),
    _Ingredient('mushroom',  '🍄', '버섯',    'veggie'),
    _Ingredient('onion',     '🧅', '양파',    'veggie'),
    _Ingredient('egg',       '🥚', '달걀',    'main'),
    _Ingredient('meat',      '🍖', '고기',    'main'),
    _Ingredient('sausage',   '🌭', '소시지',  'main'),
    _Ingredient('shrimp',    '🍤', '새우',    'main'),
    _Ingredient('cheese',    '🧀', '치즈',    'topping'),
    _Ingredient('butter',    '🧈', '버터',    'topping'),
    _Ingredient('rice',      '🍚', '쌀',      'base'),
    _Ingredient('noodle',    '🍜', '면',      'base'),
    _Ingredient('bread',     '🍞', '빵',      'base'),
    _Ingredient('milk',      '🥛', '우유',    'sweet'),
    _Ingredient('chocolate', '🍫', '초콜릿',  'sweet'),
    _Ingredient('banana',    '🍌', '바나나',  'sweet'),
    _Ingredient('strawberry','🍓', '딸기',    'sweet'),
    _Ingredient('apple',     '🍎', '사과',    'sweet'),
    _Ingredient('honey',     '🍯', '꿀',      'topping'),
  ];

  // ── 풍부한 레시피 테이블 ────────────────────────────────────────────────
  static const Map<String, _Dish> _kRecipes = {
    // 1가지 재료 (단품)
    'egg':         _Dish('🍳', '계란 후라이', '노릇노릇 고소한 계란 후라이!', Color(0xFFFFB74D)),
    'meat':        _Dish('🥩', '스테이크', '육즙이 가득한 스테이크!', Color(0xFF8D6E63)),
    'sausage':     _Dish('🌭', '구운 소시지', '톡톡 터지는 소시지 구이!', Color(0xFFFF7043)),
    'shrimp':      _Dish('🍤', '바삭 새우튀김', '바삭바삭 신선한 새우튀김!', Color(0xFFFF9800)),
    'bread':       _Dish('🍞', '갓 구운 빵', '따끈따끈 고소한 빵이에요!', Color(0xFFFFCC80)),
    'rice':        _Dish('🍚', '따끈한 쌀밥', '윤기가 흐르는 흰 쌀밥!', Color(0xFFCFD8DC)),
    'noodle':      _Dish('🍜', '따뜻한 국수', '후루룩 맛있는 국수!', Color(0xFFFFE082)),
    'corn':        _Dish('🌽', '옥수수 구이', '달콤하게 익은 옥수수 구이!', Color(0xFFFFD54F)),
    'mushroom':    _Dish('🍄', '버섯 구이', '향긋하고 건강한 버섯 구이!', Color(0xFFA1887F)),
    'banana':      _Dish('🍌', '구운 바나나', '달콤함이 2배 바나나!', Color(0xFFFFF176)),
    'strawberry':  _Dish('🍓', '생딸기 퐁당', '상큼함 가득 딸기 디저트!', Color(0xFFF48FB1)),
    'chocolate':   _Dish('🍫', '초콜릿 퐁듀', '사르르 녹는 초콜릿!', Color(0xFF6D4C41)),
    'milk':        _Dish('🥛', '따뜻한 우유', '부드럽고 고소한 우유!', Color(0xFFE0F7FA), dishType: 'glass'),
    'cheese':      _Dish('🧀', '구운 치즈', '고소함이 가득한 구운 치즈!', Color(0xFFFFD54F)),
    'tomato':      _Dish('🍅', '토마토 구이', '새콤함이 톡톡 토마토 구이!', Color(0xFFEF5350)),
    'carrot':      _Dish('🥕', '당근 스틱', '아삭아삭 건강한 당근 스틱!', Color(0xFFFF8A65)),
    'apple':       _Dish('🍎', '구운 사과', '달콤 달달 따뜻한 사과!', Color(0xFFE53935)),
    'honey':       _Dish('🍯', '꿀 한 스푼', '달콤함 가득 명품 꿀!', Color(0xFFFFB300), dishType: 'glass'),

    // 2가지 재료
    'butter+corn':       _Dish('🍿', '버터 옥수수', '고소한 버터 향 가득 옥수수!', Color(0xFFFFCA28)),
    'cheese+corn':       _Dish('🌽', '콘치즈', '치즈가 듬뿍 늘어나는 콘치즈!', Color(0xFFFFD54F)),
    'rice+shrimp':       _Dish('🍤', '새우 볶음밥', '탱글탱글 새우가 가득 볶음밥!', Color(0xFFFFB74D), dishType: 'bowl'),
    'noodle+shrimp':     _Dish('🍜', '새우 탕면', '시원하고 고소한 새우 국수!', Color(0xFFFF8A65), dishType: 'bowl'),
    'meat+mushroom':     _Dish('🥩', '버섯 스테이크', '풍미 작렬 버서 얹은 스테이크!', Color(0xFF795548)),
    'bread+butter':      _Dish('🍞', '버터 토스트', '바삭하고 고소한 버터 토스트!', Color(0xFFFFE082), dishType: 'tray'),
    'apple+honey':       _Dish('🍎', '꿀사과 디저트', '달콤함이 팡팡 터지는 꿀사과!', Color(0xFFEF5350)),
    'honey+milk':        _Dish('🥛', '꿀 우유', '달콤하고 따뜻한 꿀 우유!', Color(0xFFFFECB3), dishType: 'glass'),
    'apple+bread':       _Dish('🥧', '애플 파이', '달콤 바삭 달콤 애플 파이!', Color(0xFFFF8A65), dishType: 'tray'),
    'egg+sausage':       _Dish('🍳', '소시지 에그구이', '아침을 든든하게 해주는 소시지 계란!', Color(0xFFFF7043)),
    'onion+sausage':     _Dish('🌭', '양파 소시지 볶음', '달콤 짭조름 소시지 볶음!', Color(0xFFFF7043)),
    'bread+sausage':     _Dish('🌭', '소시지 핫도그', '육즙 팡팡 소시지 핫도그!', Color(0xFFFF7043), dishType: 'tray'),
    'egg+rice':          _Dish('🍳', '달걀 볶음밥', '고소한 달걀 볶음밥이에요!', Color(0xFFFFB74D), dishType: 'bowl'),
    'noodle+tomato':     _Dish('🍝', '토마토 파스타', '새콤달콤 스파게티에요!', Color(0xFFE57373)),
    'bread+cheese':      _Dish('🥪', '치즈 토스트', '치즈가 쭈~욱 늘어나요!', Color(0xFFFFCC02), dishType: 'tray'),
    'chocolate+milk':    _Dish('☕', '핫초코', '따뜻하고 달콤한 핫초코예요!', Color(0xFF8D6E63), dishType: 'glass'),
    'banana+milk':       _Dish('🥤', '바나나 우유', '달콤함 가득 바나나 우유!', Color(0xFFFFE082), dishType: 'glass'),
    'milk+strawberry':   _Dish('🥤', '딸기 우유', '새콤달콤 분홍빛 딸기 우유!', Color(0xFFF48FB1), dishType: 'glass'),
    'bread+meat':        _Dish('🍔', '수제 불고기빵', '고기가 가득 맛있는 빵!', Color(0xFFFF8A65), dishType: 'tray'),
    'bread+egg':         _Dish('🍞', '에그 토스트', '폭신폭신 계란 토스트!', Color(0xFFFFE0B2), dishType: 'tray'),
    'banana+chocolate':  _Dish('🍌', '초코 바나나', '달콤함 폭발 초코 바나나!', Color(0xFF795548)),
    'chocolate+strawberry': _Dish('🍓', '초코 딸기', '달콤한 초콜릿 옷 입은 딸기!', Color(0xFFC62828)),
    'egg+tomato':        _Dish('🍅', '토마토 에그 볶음', '부드럽고 새콤한 토마토 달걀!', Color(0xFFFF7043)),
    'cheese+tomato':     _Dish('🍕', '카프레제 샐러드', '신선한 토마토 치즈 샐러드!', Color(0xFFEF5350)),
    'meat+rice':         _Dish('🍖', '고기 덮밥', '달콤 짭조름 든든한 고기덮밥!', Color(0xFF8D6E63), dishType: 'bowl'),
    'cheese+meat':       _Dish('🥩', '치즈 퐁듀 스테이크', '고소한 치즈가 듬뿍 고기 요리!', Color(0xFFFFB300)),
    'banana+strawberry': _Dish('🍧', '과일 화채', '상큼함 2배 과일 화채!', Color(0xFFFF80AB), dishType: 'bowl'),

    // 3가지 재료
    'butter+cheese+corn': _Dish('🌽', '마약 콘치즈', '고소하고 달콤 끝판왕 콘치즈!', Color(0xFFFFC107)),
    'bread+sausage+tomato': _Dish('🌭', '토마토 핫도그', '상큼 육즙 가득 핫도그!', Color(0xFFFF5722), dishType: 'tray'),
    'egg+rice+shrimp':   _Dish('🍱', '새우 오므라이스', '탱글탱글 새우 오므라이스!', Color(0xFFFF9800), dishType: 'bowl'),
    'apple+honey+milk':  _Dish('🧋', '꿀사과 라떼', '달콤 향긋 꿀사과 라떼!', Color(0xFFFFE082), dishType: 'glass'),
    'bread+cheese+meat': _Dish('🍔', '치즈 버거', '두근두근 수제 치즈 버거!', Color(0xFFFF8F00), dishType: 'tray'),
    'bread+cheese+tomato': _Dish('🍕', '치즈 피자', '치즈가 듬뿍 들어간 피자!', Color(0xFFE53935), dishType: 'tray'),
    'carrot+egg+rice':   _Dish('🍱', '영양 도시락', '예쁘고 맛있는 든든 도시락!', Color(0xFF66BB6A), dishType: 'tray'),
    'banana+milk+strawberry': _Dish('🥤', '과일 스무디', '시원하고 상큼한 과일 스무디!', Color(0xFFEC407A), dishType: 'glass'),
    'bread+cheese+egg':  _Dish('🥪', '에그 치즈 샌드위치', '완벽한 아침식사 토스트!', Color(0xFFFFCA28), dishType: 'tray'),
    'banana+chocolate+milk': _Dish('🧋', '초코 바나나 쉐이크', '진하고 달콤한 쉐이크!', Color(0xFF5D4037), dishType: 'glass'),
    'egg+meat+rice':     _Dish('🍳', '오므라이스', '포근한 계란 옷을 입은 오므라이스!', Color(0xFFFFB300), dishType: 'bowl'),

    // 4가지 재료
    'bread+cheese+meat+tomato': _Dish('🍔', '스페셜 수제버거', '최고급 듬뿍 스페셜 버거!', Color(0xFFE65100), dishType: 'tray'),
    'carrot+egg+meat+rice':     _Dish('🍱', '수퍼 파워 도시락', '힘이 쑥쑥 나는 특별 도시락!', Color(0xFF2E7D32), dishType: 'tray'),
    'apple+banana+chocolate+strawberry': _Dish('🍨', '대왕 모듬과일 파르페', '달콤함 총집합 파르페!', Color(0xFFD81B60), dishType: 'glass'),
  };

  // ── 게임 상태 ──────────────────────────────────────────────────────────
  _Phase _phase = _Phase.pick;
  final List<String> _pot = [];       // 냄비에 넣은 재료 키
  _Dish? _resultDish;
  int _stirCount = 0;
  static const int _stirNeeded = 5;

  // 떨어지는 재료
  _FallingItem? _fallingItem;

  final _rng = Random();

  // ── 애니메이션 ─────────────────────────────────────────────────────────
  late AnimationController _bubbleCtrl;    // 냄비 보글보글
  late AnimationController _fallCtrl;      // 재료 떨어짐
  late AnimationController _cookCtrl;      // 요리중 (2.5초)
  late AnimationController _resultCtrl;    // 결과 팝
  late Animation<double> _resultScale;
  late AnimationController _stirVisualCtrl; // 섞기 시각 피드백
  late AnimationController _steamCtrl;     // 김
  late AnimationController _bgPatternCtrl; // 배경 파티클 애니메이션

  @override
  void initState() {
    super.initState();

    _bubbleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _fallCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fallCtrl.addListener(() {
      if (_fallingItem != null) setState(() => _fallingItem!.progress = _fallCtrl.value);
    });
    _fallCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) setState(() => _fallingItem = null);
    });

    _cookCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _cookCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) _onCookingDone();
    });

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _resultScale = CurvedAnimation(parent: _resultCtrl, curve: Curves.elasticOut);

    _stirVisualCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _steamCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    _bgPatternCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    _fallCtrl.dispose();
    _cookCtrl.dispose();
    _resultCtrl.dispose();
    _stirVisualCtrl.dispose();
    _steamCtrl.dispose();
    _bgPatternCtrl.dispose();
    super.dispose();
  }

  // ── 재료 추가/제거 ─────────────────────────────────────────────────────
  void _addIngredient(int index) {
    if (_phase != _Phase.pick) return;
    final ingredient = _kIngredients[index];

    // 이미 있으면 제거
    if (_pot.contains(ingredient.key)) {
      HapticFeedback.lightImpact();
      setState(() => _pot.remove(ingredient.key));
      AudioManager.instance.playClick();
      return;
    }

    // 최대 4개
    if (_pot.length >= 4) {
      AudioManager.instance.playBoing();
      return;
    }

    HapticFeedback.lightImpact();

    // 떨어지는 애니메이션
    setState(() => _fallingItem = _FallingItem(ingredient.emoji));
    _fallCtrl.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _pot.add(ingredient.key));
      AudioManager.instance.playCookDrop(ingredientKey: ingredient.key);
    });
  }

  // ── 섞기 단계 시작 ────────────────────────────────────────────────────
  void _startStirring() {
    if (_pot.isEmpty) {
      AudioManager.instance.playBoing();
      return;
    }
    setState(() {
      _phase = _Phase.stir;
      _stirCount = 0;
    });
    AudioManager.instance.playCookStir();
  }

  // ── 섞기 탭 ────────────────────────────────────────────────────────────
  void _onStirTap() {
    if (_phase != _Phase.stir) return;

    HapticFeedback.mediumImpact();
    _stirVisualCtrl.forward(from: 0);
    AudioManager.instance.playCookStir();

    setState(() {
      _stirCount++;
      if (_stirCount >= _stirNeeded) {
        _phase = _Phase.cooking;
        _cookCtrl.forward(from: 0);
      }
    });
  }

  // ── 스마트 요리 매칭 알고리즘 ──────────────────────────────────────────────
  _Dish _findBestDish() {
    if (_pot.isEmpty) {
      return const _Dish('🍲', '신비한 탕요리', '맛있는 비밀 재료가 들어갔어요!', Color(0xFF7E57C2));
    }

    final sortedKey = (List<String>.from(_pot)..sort()).join('+');

    // 1. 정확 매칭 확인
    if (_kRecipes.containsKey(sortedKey)) {
      return _kRecipes[sortedKey]!;
    }

    // 2. 부분 매칭 (가장 많은 재료를 포함하는 최적의 레시피 검색)
    _Dish? bestMatch;
    int maxMatchCount = 0;

    for (final entry in _kRecipes.entries) {
      final recipeKeys = entry.key.split('+');
      int matchCount = 0;
      for (final k in _pot) {
        if (recipeKeys.contains(k)) matchCount++;
      }
      if (matchCount > maxMatchCount) {
        maxMatchCount = matchCount;
        bestMatch = entry.value;
      }
    }

    if (bestMatch != null && maxMatchCount >= 1) {
      return bestMatch;
    }

    // 3. 재료 기반 동적 스마트 생성
    final ingredientsList = _pot.map((k) => _kIngredients.firstWhere((i) => i.key == k)).toList();
    final hasSweet = ingredientsList.any((i) => i.category == 'sweet');
    final hasRice = ingredientsList.any((i) => i.key == 'rice');
    final hasNoodle = ingredientsList.any((i) => i.key == 'noodle');
    final hasBread = ingredientsList.any((i) => i.key == 'bread');

    final names = ingredientsList.map((i) => i.label).join(' ');
    
    if (hasSweet) {
      return _Dish(
        '🍨',
        '$names 디저트',
        '달콤하고 맛있는 쉐이크&디저트 완성!',
        const Color(0xFFEC407A),
        dishType: 'glass',
      );
    } else if (hasRice) {
      return _Dish(
        '🍛',
        '$names 덮밥',
        '든든하고 고소한 특별 덮밥 완성!',
        const Color(0xFFFFB74D),
        dishType: 'bowl',
      );
    } else if (hasNoodle) {
      return _Dish(
        '🍝',
        '$names 국수',
        '후루룩 짭조름 맛있는 면 요리!',
        const Color(0xFFE57373),
        dishType: 'bowl',
      );
    } else if (hasBread) {
      return _Dish(
        '🥪',
        '$names 샌드위치',
        '바삭하고 푸짐한 수제 샌드위치!',
        const Color(0xFFFFCC02),
        dishType: 'tray',
      );
    }

    return _Dish(
      '🥘',
      '$names 요리',
      '내가 만든 세상에 단 하나뿐인 특선 요리!',
      const Color(0xFFFFA726),
      dishType: 'plate',
    );
  }

  // ── 요리 완료 ──────────────────────────────────────────────────────────
  void _onCookingDone() {
    final dish = _findBestDish();

    setState(() {
      _phase = _Phase.result;
      _resultDish = dish;
    });

    _resultCtrl.forward(from: 0);
    AudioManager.instance.playCookComplete();
  }

  // ── 다시하기 ──────────────────────────────────────────────────────────
  void _reset() {
    setState(() {
      _phase = _Phase.pick;
      _pot.clear();
      _resultDish = null;
      _stirCount = 0;
      _fallingItem = null;
    });
    _cookCtrl.reset();
    _resultCtrl.reset();
    AudioManager.instance.playClick();
    HapticFeedback.lightImpact();
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            // ── 아기자기한 주방 파스텔 배경 커스텀 페인터 ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgPatternCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _KitchenBackgroundPainter(animValue: _bgPatternCtrl.value),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 4),
                  _buildStatusBanner(),
                  const SizedBox(height: 4),
                  // 메인 영역: 냄비 or 완성 접시
                  Expanded(child: _buildMainArea()),
                  const SizedBox(height: 4),
                  // 하단: 재료 팔레트 or 버튼
                  _buildBottomArea(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 헤더 ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () { AudioManager.instance.playClick(); Navigator.pop(context); },
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFFE65100)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🍳 요리사 놀이', style: GoogleFonts.jua(fontSize: 22, color: const Color(0xFFBF360C))),
                Text('재료를 콕콕 골라 맛있는 요리를 만들어요!', style: GoogleFonts.jua(fontSize: 13, color: Colors.brown.shade400)),
              ],
            ),
          ),
          // 냄비 속 재료 미리보기
          if (_pot.isNotEmpty && _phase == _Phase.pick)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: _pot.map((key) {
                final ing = _kIngredients.firstWhere((i) => i.key == key);
                return Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(ing.emoji, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ── 상태 배너 ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner() {
    String text;
    Color bgColor;

    switch (_phase) {
      case _Phase.pick:
        text = _pot.isEmpty
            ? '👇 아래 20가지 재료 중 1개 이상 골라봐요!'
            : '재료 ${_pot.length}개 선택! (요리 시작 가능!)';
        bgColor = Colors.orange.shade50;
      case _Phase.stir:
        text = '🥄 냄비를 톡톡 눌러서 섞어봐요! (${_stirCount}/$_stirNeeded)';
        bgColor = Colors.amber.shade50;
      case _Phase.cooking:
        text = '🔥 부글부글 요리하는 중... 잠깐만 기다려요!';
        bgColor = Colors.red.shade50;
      case _Phase.result:
        text = '✨ 우와! 맛있는 요리가 완성되었어요!';
        bgColor = Colors.green.shade50;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 8)],
      ),
      child: Text(
        text,
        style: GoogleFonts.jua(fontSize: 15, color: const Color(0xFFBF360C)),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── 메인 영역 (냄비 + 결과) ───────────────────────────────────────────
  Widget _buildMainArea() {
    if (_phase == _Phase.result && _resultDish != null) {
      return _buildResultView();
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        // 냄비
        _buildPot(),
        // 떨어지는 재료
        if (_fallingItem != null) _buildFallingIngredient(),
        // 섞기 오버레이
        if (_phase == _Phase.stir) _buildStirOverlay(),
        // 요리중 오버레이
        if (_phase == _Phase.cooking) _buildCookingOverlay(),
      ],
    );
  }

  // ── 냄비 ──────────────────────────────────────────────────────────────
  Widget _buildPot() {
    return AnimatedBuilder(
      animation: Listenable.merge([_bubbleCtrl, _steamCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 250,
          height: 260,
          child: CustomPaint(
            painter: _PotPainter(
              phase: _phase,
              bubblePhase: _bubbleCtrl.value * 2 * pi,
              steamPhase: _steamCtrl.value,
              ingredientEmojis: _pot.map((k) => _kIngredients.firstWhere((i) => i.key == k).emoji).toList(),
              cookProgress: _phase == _Phase.cooking ? _cookCtrl.value : 0,
              rng: _rng,
            ),
          ),
        );
      },
    );
  }

  // ── 떨어지는 재료 ────────────────────────────────────────────────────
  Widget _buildFallingIngredient() {
    if (_fallingItem == null) return const SizedBox.shrink();
    final t = _fallingItem!.progress;
    final y = -80 + t * 200; // 위에서 냄비 안으로
    final scale = 1.2 - t * 0.5;
    final opacity = 1.0 - (t > 0.7 ? (t - 0.7) / 0.3 : 0);

    return Positioned(
      top: 20 + y,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Text(_fallingItem!.emoji, style: const TextStyle(fontSize: 48)),
        ),
      ),
    );
  }

  // ── 섞기 오버레이 ────────────────────────────────────────────────────
  Widget _buildStirOverlay() {
    return GestureDetector(
      onTap: _onStirTap,
      child: AnimatedBuilder(
        animation: _stirVisualCtrl,
        builder: (_, __) {
          final wobble = sin(_stirVisualCtrl.value * pi * 2) * 8;
          return Transform.translate(
            offset: Offset(wobble, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 140),
                // 큰 국자 이모지
                Text('🥄', style: TextStyle(fontSize: 60 + wobble.abs())),
                const SizedBox(height: 12),
                // 프로그레스
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_stirCount / _stirNeeded).clamp(0, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFF6D00)]),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '톡톡! (${_stirNeeded - _stirCount}번 더!)',
                  style: GoogleFonts.jua(fontSize: 18, color: Colors.brown.shade600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── 요리중 오버레이 ──────────────────────────────────────────────────
  Widget _buildCookingOverlay() {
    return AnimatedBuilder(
      animation: _cookCtrl,
      builder: (_, __) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 150),
            // 불꽃 + 타이머
            Text(
              _cookCtrl.value < 0.3 ? '🔥' : _cookCtrl.value < 0.7 ? '🔥🔥' : '🔥🔥🔥',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _cookCtrl.value,
                  minHeight: 16,
                  backgroundColor: Colors.orange.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(Colors.orange, Colors.red, _cookCtrl.value)!,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('부글부글... 🫧', style: GoogleFonts.jua(fontSize: 18, color: Colors.red.shade400)),
          ],
        );
      },
    );
  }

  // ── 결과 화면 (다채로운 완성 접시 및 연출) ───────────────────────────────
  Widget _buildResultView() {
    final dish = _resultDish!;
    final potEmojis = _pot.map((k) => _kIngredients.firstWhere((i) => i.key == k).emoji).toList();

    return AnimatedBuilder(
      animation: _resultScale,
      builder: (_, __) {
        return Center(
          child: Transform.scale(
            scale: 0.4 + _resultScale.value * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 접시 및 서빙 음식 연출
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 후광 글로우
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dish.plateColor.withValues(alpha: 0.25),
                        boxShadow: [
                          BoxShadow(
                            color: dish.plateColor.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                    ),

                    // 접시 모양 (종류별)
                    _buildContainerShape(dish),

                    // 메인 음식 이모지
                    Text(dish.emoji, style: const TextStyle(fontSize: 84)),

                    // 넣은 재료 플레이팅 이모지 (주변 배치)
                    ...List.generate(potEmojis.length, (idx) {
                      final angle = (idx * (2 * pi / potEmojis.length)) - (pi / 2);
                      final radius = 72.0;
                      final dx = radius * cos(angle);
                      final dy = radius * sin(angle);
                      return Transform.translate(
                        offset: Offset(dx, dy),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)],
                          ),
                          child: Text(potEmojis[idx], style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),

                // 요리 이름
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: dish.plateColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: dish.plateColor, width: 2.5),
                  ),
                  child: Text(
                    dish.name,
                    style: GoogleFonts.jua(fontSize: 28, color: const Color(0xFFBF360C)),
                  ),
                ),
                const SizedBox(height: 6),

                // 설명
                Text(
                  dish.description,
                  style: GoogleFonts.jua(fontSize: 16, color: Colors.brown.shade600),
                ),
                const SizedBox(height: 10),

                // 사용된 재료 칩
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: _pot.map((k) {
                    final ing = _kIngredients.firstWhere((i) => i.key == k);
                    return Chip(
                      label: Text('${ing.emoji} ${ing.label}', style: GoogleFonts.jua(fontSize: 12)),
                      backgroundColor: Colors.white,
                      elevation: 2,
                      side: BorderSide(color: dish.plateColor.withValues(alpha: 0.6)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 다시하기 버튼
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFF6D00)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🍳', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text('다시 요리해요!', style: GoogleFonts.jua(fontSize: 18, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 접시/용기 비주얼 빌더
  Widget _buildContainerShape(_Dish dish) {
    switch (dish.dishType) {
      case 'glass':
        return Container(
          width: 150,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            border: Border.all(color: dish.plateColor, width: 6),
          ),
        );
      case 'bowl':
        return Container(
          width: 190,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(90)),
            border: Border.all(color: dish.plateColor, width: 8),
          ),
        );
      case 'tray':
        return Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: const Color(0xFFD7CCC8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF8D6E63), width: 8),
          ),
        );
      case 'plate':
      default:
        return Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: dish.plateColor, width: 8),
          ),
        );
    }
  }

  // ── 하단 영역 ──────────────────────────────────────────────────────────
  Widget _buildBottomArea() {
    if (_phase == _Phase.result) return const SizedBox.shrink();
    if (_phase == _Phase.stir || _phase == _Phase.cooking) {
      return const SizedBox(height: 60); // 빈 공간
    }

    // pick 단계: 20개 재료 팔레트 + 요리하기 버튼
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIngredientGrid(),
        const SizedBox(height: 6),
        _buildCookButton(),
      ],
    );
  }

  // ── 재료 그리드 (큼직한 버튼 & 가로 스크롤) ──────────────────────────────────
  Widget _buildIngredientGrid() {
    Widget buildItem(int index) {
      final ing = _kIngredients[index];
      final inPot = _pot.contains(ing.key);

      return GestureDetector(
        onTap: () => _addIngredient(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: inPot ? 62 : 56,
                height: inPot ? 62 : 56,
                decoration: BoxDecoration(
                  color: inPot ? Colors.orange.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: inPot ? Colors.orange : Colors.orange.shade300,
                    width: inPot ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: inPot ? Colors.orange.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.08),
                      blurRadius: inPot ? 12 : 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(ing.emoji, style: TextStyle(fontSize: inPot ? 30 : 26)),
                    if (inPot)
                      Positioned(
                        top: 2, right: 2,
                        child: Container(
                          width: 18, height: 18,
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Center(child: Text('✕', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                inPot ? '빼기!' : ing.label,
                style: GoogleFonts.jua(
                  fontSize: 12,
                  color: inPot ? Colors.redAccent : Colors.brown.shade800,
                  fontWeight: inPot ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(10, buildItem),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(10, (i) => buildItem(i + 10)),
          ),
        ],
      ),
    );
  }

  // ── 요리하기 버튼 ────────────────────────────────────────────────────
  Widget _buildCookButton() {
    final canCook = _pot.isNotEmpty; // 1개 이상만 넣어도 요리 가능!
    return GestureDetector(
      onTap: canCook ? _startStirring : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        height: 50,
        decoration: BoxDecoration(
          gradient: canCook
              ? const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFF6D00)])
              : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: canCook
              ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(canCook ? '🔥' : '🍳', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              canCook ? '요리 시작!' : '재료를 1개 이상 골라봐요',
              style: GoogleFonts.jua(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 아기자기한 주방 파스텔 배경 CustomPainter ──────────────────────────────
class _KitchenBackgroundPainter extends CustomPainter {
  final double animValue;
  _KitchenBackgroundPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. 따뜻한 주방 파스텔 베이스 그라데이션 (상단 분홍/아이보리, 하단 연민트/크림)
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFFFF8E1), // 따뜻한 연아이보리
        Color(0xFFFFF0F5), // 몽글몽글 연분홍
        Color(0xFFE8F5E9), // 산뜻한 연민트 (하단 대비)
      ],
    );
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..shader = bgGradient.createShader(Rect.fromLTWH(0, 0, w, h)));

    // 2. 귀여운 주방 벽면 핑크&화이트 파스텔 타일 패턴 (상단)
    final tilePaint1 = Paint()..color = Colors.white.withValues(alpha: 0.45);
    final tilePaint2 = Paint()..color = const Color(0xFFFFD1DC).withValues(alpha: 0.30);
    const tileSize = 32.0;

    for (double x = 0; x < w; x += tileSize) {
      for (double y = 0; y < h * 0.42; y += tileSize) {
        final isEven = ((x / tileSize).floor() + (y / tileSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize - 2, tileSize - 2),
          isEven ? tilePaint1 : tilePaint2,
        );
      }
    }

    // 3. 주방 조리대 목재(Wood) 라인 경계선
    final woodPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, 14), woodPaint);

    final woodLinePaint = Paint()
      ..color = const Color(0xFF8D6E63).withValues(alpha: 0.6)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, h * 0.42), Offset(w, h * 0.42), woodLinePaint);
    canvas.drawLine(Offset(0, h * 0.42 + 14), Offset(w, h * 0.42 + 14), woodLinePaint);

    // 4. 떠다니는 아기자기한 파스텔 물방울/하트/별 파티클
    final seedRng = Random(42);
    for (int i = 0; i < 15; i++) {
      final rx = seedRng.nextDouble() * w;
      final baseY = seedRng.nextDouble() * h;
      final speed = 0.4 + seedRng.nextDouble() * 0.6;
      final dy = (baseY - animValue * h * speed) % h;
      final radius = 6.0 + seedRng.nextDouble() * 12.0;
      final colorOpacity = 0.2 + seedRng.nextDouble() * 0.25;

      final pColors = [
        Colors.pinkAccent.withValues(alpha: colorOpacity),
        Colors.amberAccent.withValues(alpha: colorOpacity),
        Colors.lightBlueAccent.withValues(alpha: colorOpacity),
        Colors.lightGreenAccent.withValues(alpha: colorOpacity),
      ];
      final pPaint = Paint()..color = pColors[i % pColors.length];

      canvas.drawCircle(Offset(rx, dy), radius, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _KitchenBackgroundPainter old) => old.animValue != animValue;
}

// ── 냄비 CustomPainter ─────────────────────────────────────────────────────
class _PotPainter extends CustomPainter {
  final _Phase phase;
  final double bubblePhase;
  final double steamPhase;
  final List<String> ingredientEmojis;
  final double cookProgress;
  final Random rng;

  _PotPainter({
    required this.phase,
    required this.bubblePhase,
    required this.steamPhase,
    required this.ingredientEmojis,
    required this.cookProgress,
    required this.rng,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final w = size.width;
    final h = size.height;

    // ── 냄비 그림자 ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.88), width: w * 0.75, height: 30),
      Paint()..color = Colors.black.withValues(alpha: 0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── 냄비 몸통 ──
    final potBody = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.15, h * 0.30, w * 0.70, h * 0.55),
      bottomLeft: const Radius.circular(30),
      bottomRight: const Radius.circular(30),
    );
    canvas.drawRRect(
      potBody,
      Paint()..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF546E7A), Color(0xFF37474F)],
      ).createShader(Rect.fromLTWH(w * 0.15, h * 0.30, w * 0.70, h * 0.55)),
    );

    // ── 냄비 금속 하이라이트 ──
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.15, h * 0.45),
        bottomLeft: const Radius.circular(25),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // ── 냄비 테두리 (상단) ──
    canvas.drawRect(
      Rect.fromLTWH(w * 0.10, h * 0.27, w * 0.80, h * 0.06),
      Paint()..shader = const LinearGradient(
        colors: [Color(0xFF78909C), Color(0xFF546E7A), Color(0xFF78909C)],
      ).createShader(Rect.fromLTWH(w * 0.10, h * 0.27, w * 0.80, h * 0.06)),
    );

    // ── 손잡이 ──
    final handlePaint = Paint()
      ..color = const Color(0xFF455A64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    // 왼쪽 손잡이
    canvas.drawLine(Offset(w * 0.10, h * 0.35), Offset(w * 0.02, h * 0.35), handlePaint);
    canvas.drawCircle(Offset(w * 0.02, h * 0.35), 6, Paint()..color = const Color(0xFF795548));
    // 오른쪽 손잡이
    canvas.drawLine(Offset(w * 0.90, h * 0.35), Offset(w * 0.98, h * 0.35), handlePaint);
    canvas.drawCircle(Offset(w * 0.98, h * 0.35), 6, Paint()..color = const Color(0xFF795548));

    // ── 냄비 내부 (음식/물) ──
    if (ingredientEmojis.isNotEmpty || phase == _Phase.cooking) {
      canvas.save();
      canvas.clipRRect(potBody);

      // 물 / 국물 (배경 연주황색과 명확히 구분되는 딥 붉은/주황 육수 톤)
      final liquidTop = h * 0.38;
      final liquidColor = phase == _Phase.cooking
          ? Color.lerp(const Color(0xFFFF5722), const Color(0xFFD50000), cookProgress)!
          : const Color(0xFFFF6D00); // 대비가 뚜렷한 진한 맛있는 육수 빛깔

      final liqPath = Path();
      liqPath.moveTo(w * 0.15, h * 0.85);
      liqPath.lineTo(w * 0.85, h * 0.85);
      liqPath.lineTo(w * 0.85, liquidTop);
      // 물결
      for (double x = w * 0.85; x >= w * 0.15; x -= 2) {
        final wy = liquidTop + sin((x / w * 3 * pi) + bubblePhase) * 4;
        liqPath.lineTo(x, wy);
      }
      liqPath.close();

      // 액체 채우기
      canvas.drawPath(
        liqPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              liquidColor.withValues(alpha: 0.85),
              liquidColor,
            ],
          ).createShader(Rect.fromLTWH(w * 0.15, liquidTop, w * 0.70, h * 0.50)),
      );

      // 냄비 안쪽 상단 어두운 그림자 (입체감)
      canvas.drawRect(
        Rect.fromLTWH(w * 0.15, h * 0.30, w * 0.70, 18),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.4),
              Colors.black.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(w * 0.15, h * 0.30, w * 0.70, 18)),
      );

      // 기포
      if (phase == _Phase.stir || phase == _Phase.cooking) {
        final bPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
        final seedRng = Random(bubblePhase.toInt() * 3);
        final bubbleCount = phase == _Phase.cooking ? 14 : 7;
        for (int i = 0; i < bubbleCount; i++) {
          final bx = w * (0.20 + seedRng.nextDouble() * 0.60);
          final by = liquidTop + 12 + seedRng.nextDouble() * (h * 0.38);
          canvas.drawCircle(Offset(bx, by), 2.5 + seedRng.nextDouble() * 5, bPaint);
        }
      }

      canvas.restore();
    }

    // ── 재료 이모지 (냄비 안) ──
    if (ingredientEmojis.isNotEmpty && phase != _Phase.cooking) {
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (int i = 0; i < ingredientEmojis.length; i++) {
        tp.text = TextSpan(text: ingredientEmojis[i], style: const TextStyle(fontSize: 30));
        tp.layout();
        final ix = w * 0.25 + (i % 2) * w * 0.30;
        final iy = h * 0.45 + (i ~/ 2) * 35;
        tp.paint(canvas, Offset(ix - tp.width / 2, iy - tp.height / 2));
      }
    }

    // ── 김 (steam) ──
    if (phase == _Phase.cooking || (phase == _Phase.stir && ingredientEmojis.isNotEmpty)) {
      final sPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
      for (int i = 0; i < 5; i++) {
        final sx = cx + (i - 2) * 20.0;
        final offset = sin(steamPhase * 2 * pi + i) * 8;
        final sy = h * 0.22 - steamPhase * 25 - i * 5;
        canvas.drawCircle(Offset(sx + offset, sy), 8 + i * 2, sPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PotPainter old) => true;
}
