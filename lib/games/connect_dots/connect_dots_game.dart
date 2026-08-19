import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

class ConnectDotsGame extends StatefulWidget {
  const ConnectDotsGame({super.key});

  @override
  State<ConnectDotsGame> createState() => _ConnectDotsGameState();
}

class Dot {
  final int number;
  final Offset position;

  Dot(this.number, this.position);
}

class DotPuzzle {
  final String name;
  final String emoji;
  final List<Offset> points;
  final bool isClosed;

  const DotPuzzle(this.name, this.emoji, this.points, {this.isClosed = true});
}

const List<DotPuzzle> _puzzles = [
  DotPuzzle('반짝반짝 별', '⭐', [
    Offset(0.5, 0.05),
    Offset(0.65, 0.38),
    Offset(1.0, 0.38),
    Offset(0.72, 0.6),
    Offset(0.82, 0.95),
    Offset(0.5, 0.75),
    Offset(0.18, 0.95),
    Offset(0.28, 0.6),
    Offset(0.0, 0.38),
    Offset(0.35, 0.38),
  ]),
  DotPuzzle('예쁜 집', '🏠', [
    Offset(0.5, 0.1),
    Offset(0.9, 0.45),
    Offset(0.8, 0.45),
    Offset(0.8, 0.9),
    Offset(0.2, 0.9),
    Offset(0.2, 0.45),
    Offset(0.1, 0.45),
  ]),
  DotPuzzle('물고기', '🐠', [
    Offset(0.9, 0.5), // 입
    Offset(0.6, 0.2), // 등
    Offset(0.2, 0.35), // 꼬리 위
    Offset(0.05, 0.2), // 꼬리 끝 위
    Offset(0.05, 0.8), // 꼬리 끝 아래
    Offset(0.2, 0.65), // 꼬리 아래
    Offset(0.6, 0.8), // 배
  ]),
  DotPuzzle('사랑해 하트', '💖', [
    Offset(0.5, 0.35), // 가운데 쏙 들어간 부분
    Offset(0.75, 0.1), // 오른쪽 위
    Offset(0.95, 0.35), // 오른쪽 끝
    Offset(0.5, 0.9), // 맨 아래 뾰족한 부분
    Offset(0.05, 0.35), // 왼쪽 끝
    Offset(0.25, 0.1), // 왼쪽 위
  ]),
  DotPuzzle('팔랑팔랑 나비', '🦋', [
    Offset(0.5, 0.15), // 머리
    Offset(0.85, 0.25), // 오른쪽 윗날개
    Offset(0.65, 0.5), // 날개 교차점
    Offset(0.95, 0.8), // 오른쪽 아랫날개
    Offset(0.5, 0.95), // 몸통 아래
    Offset(0.05, 0.8), // 왼쪽 아랫날개
    Offset(0.35, 0.5), // 날개 교차점
    Offset(0.15, 0.25), // 왼쪽 윗날개
  ]),
  DotPuzzle('느릿느릿 달팽이', '🐌', [
    Offset(0.2, 0.75), // 꼬리
    Offset(0.5, 0.3), // 등딱지 위
    Offset(0.85, 0.5), // 등딱지 오른쪽
    Offset(0.5, 0.85), // 등딱지 아래
    Offset(0.35, 0.55), // 안쪽 나선
    Offset(0.65, 0.6), // 안쪽 나선 끝
    Offset(0.9, 0.85), // 머리 아래
    Offset(0.95, 0.4), // 더듬이
  ], isClosed: false),
  DotPuzzle('귀여운 고양이', '🐱', [
    Offset(0.2, 0.2), // 왼쪽 귀 끝
    Offset(0.4, 0.3), // 왼쪽 귀 안쪽
    Offset(0.6, 0.3), // 오른쪽 귀 안쪽
    Offset(0.8, 0.2), // 오른쪽 귀 끝
    Offset(0.9, 0.6), // 오른쪽 뺨
    Offset(0.5, 0.9), // 턱
    Offset(0.1, 0.6), // 왼쪽 뺨
  ]),
  DotPuzzle('달콤 아이스크림', '🍦', [
    Offset(0.5, 0.05), // 아이스크림 꼭대기
    Offset(0.85, 0.3), // 오른쪽 크림
    Offset(0.7, 0.5), // 콘 시작 오른쪽
    Offset(0.5, 0.95), // 콘 끝
    Offset(0.3, 0.5), // 콘 시작 왼쪽
    Offset(0.15, 0.3), // 왼쪽 크림
  ]),
  DotPuzzle('빠방 자동차', '🚗', [
    Offset(0.2, 0.5), // 앞 범퍼
    Offset(0.3, 0.3), // 앞 유리 아래
    Offset(0.45, 0.15), // 지붕 앞
    Offset(0.75, 0.15), // 지붕 뒤
    Offset(0.9, 0.35), // 뒤 유리 아래
    Offset(0.95, 0.5), // 뒤 범퍼 위
    Offset(0.95, 0.7), // 뒤 범퍼 아래
    Offset(0.75, 0.7), // 뒷바퀴 뒤
    Offset(0.65, 0.55), // 뒷바퀴 위
    Offset(0.55, 0.7), // 뒷바퀴 앞
    Offset(0.35, 0.7), // 앞바퀴 뒤
    Offset(0.25, 0.55), // 앞바퀴 위
    Offset(0.15, 0.7), // 앞바퀴 앞
    Offset(0.1, 0.6), // 앞 범퍼 아래
  ]),
  DotPuzzle('귀요미 곰돌이', '🧸', [
    Offset(0.2, 0.15), // 왼쪽 귀
    Offset(0.35, 0.3), // 머리 위 왼쪽
    Offset(0.65, 0.3), // 머리 위 오른쪽
    Offset(0.8, 0.15), // 오른쪽 귀
    Offset(0.95, 0.45), // 오른쪽 뺨
    Offset(0.85, 0.75), // 오른쪽 턱
    Offset(0.5, 0.95), // 턱 아래
    Offset(0.15, 0.75), // 왼쪽 턱
    Offset(0.05, 0.45), // 왼쪽 뺨
  ]),
  DotPuzzle('새콤달콤 딸기', '🍓', [
    Offset(0.5, 0.05), // 무성한 잎 꼭대기
    Offset(0.75, 0.18), // 잎 오른쪽
    Offset(0.9, 0.45), // 딸기 어깨 오른쪽
    Offset(0.75, 0.75), // 딸기 아래 오른쪽
    Offset(0.5, 0.95), // 딸기 끝 뾰족한 부분
    Offset(0.25, 0.75), // 딸기 아래 왼쪽
    Offset(0.1, 0.45), // 딸기 어깨 왼쪽
    Offset(0.25, 0.18), // 잎 왼쪽
  ]),
  DotPuzzle('반짝반짝 왕관', '👑', [
    Offset(0.1, 0.8), // 왕관 바닥 왼쪽
    Offset(0.05, 0.25), // 왼쪽 뾰족 봉우리
    Offset(0.3, 0.45), // 왼쪽 꺾임
    Offset(0.5, 0.1), // 중앙 높은 봉우리
    Offset(0.7, 0.45), // 오른쪽 꺾임
    Offset(0.95, 0.25), // 오른쪽 뾰족 봉우리
    Offset(0.9, 0.8), // 왕관 바닥 오른쪽
  ]),
  DotPuzzle('부릉부릉 로켓', '🚀', [
    Offset(0.5, 0.05), // 로켓 제일 꼭대기
    Offset(0.75, 0.35), // 동체 오른쪽
    Offset(0.75, 0.75), // 오른쪽 날개 시작
    Offset(0.95, 0.9), // 오른쪽 날개 끝
    Offset(0.65, 0.85), // 엔진 오른쪽
    Offset(0.35, 0.85), // 엔진 왼쪽
    Offset(0.05, 0.9), // 왼쪽 날개 끝
    Offset(0.25, 0.75), // 왼쪽 날개 시작
    Offset(0.25, 0.35), // 동체 왼쪽
  ]),
  DotPuzzle('알록달록 캔디', '🍬', [
    Offset(0.05, 0.3), // 왼쪽 포장지 상단
    Offset(0.25, 0.45), // 사탕 왼쪽 묶음
    Offset(0.5, 0.25), // 사탕 몸통 위
    Offset(0.75, 0.45), // 사탕 오른쪽 묶음
    Offset(0.95, 0.3), // 오른쪽 포장지 상단
    Offset(0.95, 0.7), // 오른쪽 포장지 하단
    Offset(0.75, 0.55), // 사탕 오른쪽 묶음 아래
    Offset(0.5, 0.75), // 사탕 몸통 아래
    Offset(0.25, 0.55), // 사탕 왼쪽 묶음 아래
    Offset(0.05, 0.7), // 왼쪽 포장지 하단
  ]),
  DotPuzzle('탐스러운 사과', '🍎', [
    Offset(0.5, 0.05), // 줄기 끝
    Offset(0.5, 0.2), // 사과 가운데 파인 부분
    Offset(0.8, 0.15), // 오른쪽 윗 볼록
    Offset(0.95, 0.5), // 오른쪽 뺨
    Offset(0.7, 0.9), // 오른쪽 아래
    Offset(0.5, 0.85), // 사과 아래 파인 부분
    Offset(0.3, 0.9), // 왼쪽 아래
    Offset(0.05, 0.5), // 왼쪽 뺨
    Offset(0.2, 0.15), // 왼쪽 윗 볼록
  ]),
  DotPuzzle('신나는 풍선', '🎈', [
    Offset(0.5, 0.05), // 풍선 꼭대기
    Offset(0.85, 0.25), // 풍선 오른쪽 볼록
    Offset(0.7, 0.65), // 풍선 하단 오른쪽
    Offset(0.55, 0.72), // 묶음 오른쪽
    Offset(0.5, 0.95), // 실 끝
    Offset(0.45, 0.72), // 묶음 왼쪽
    Offset(0.3, 0.65), // 풍선 하단 왼쪽
    Offset(0.15, 0.25), // 풍선 왼쪽 볼록
  ], isClosed: false),
];

// 무지개 색상 배열 - 점을 연결할 때마다 순서대로 사용
const List<Color> _rainbowPalette = [
  Color(0xFFFF4D6D), // 딸기빨강
  Color(0xFFFF8C42), // 당근주황
  Color(0xFFFFD166), // 바나나노랑
  Color(0xFF4ADE80), // 새싹초록
  Color(0xFF38BDF8), // 하늘파랑
  Color(0xFF818CF8), // 라벤더보라
  Color(0xFFF472B6), // 핑크사탕
  Color(0xFF34D399), // 민트초록
  Color(0xFFE879F9), // 매직보라
  Color(0xFFFBBF24), // 황금노랑
  Color(0xFF60A5FA), // 블루베리
  Color(0xFFFC8181), // 장미빨강
];

class _ConnectDotsGameState extends State<ConnectDotsGame> with TickerProviderStateMixin {
  int _score = 0;
  int _level = 1;
  bool _isLevelClear = false;

  List<Dot> _dots = [];
  int _currentDotIndex = 1;

  List<Offset> _completedPoints = [];
  // 각 세그먼트(선 구간)의 무지개 색상 인덱스 추적
  List<int> _segmentColorIndices = [];
  Offset? _currentDragPos;

  final Random _random = Random();
  Size _screenSize = Size.zero;
  
  late DotPuzzle _currentPuzzle;

  // 애니메이션 컨트롤러 (성공, 구름, 새)
  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;
  late AnimationController _bgAnimController;
  late AnimationController _birdAnimController;
  Timer? _autoNextTimer;

  @override
  void initState() {
    super.initState();
    _currentPuzzle = _puzzles[0]; // dummy init
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );

    // 구름 천천히 이동
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // 새 날아가기 및 날갯짓
    _birdAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _successAnimController.dispose();
    _bgAnimController.dispose();
    _birdAnimController.dispose();
    super.dispose();
  }

  void _generateLevel(Size size) {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    _screenSize = size;
    _dots.clear();
    _completedPoints.clear();
    _segmentColorIndices.clear();
    _currentDotIndex = 1;
    _isLevelClear = false;
    _currentDragPos = null;
    _successAnimController.reset();

    // 스테이지 번호 순서대로 퍼즐 제공 (16개 퍼즐 순환)
    _currentPuzzle = _puzzles[(_level - 1) % _puzzles.length];

    double paddingX = 60.0;
    double paddingTop = 140.0;
    double paddingBottom = 100.0;
    
    double availWidth = _screenSize.width - paddingX * 2;
    double availHeight = _screenSize.height - paddingTop - paddingBottom;

    for (int i = 0; i < _currentPuzzle.points.length; i++) {
      final p = _currentPuzzle.points[i];
      _dots.add(Dot(
        i + 1,
        Offset(
          paddingX + p.dx * availWidth,
          paddingTop + p.dy * availHeight,
        ),
      ));
    }
    setState(() {});
  }

  Dot? get _targetDot {
    if (_dots.isEmpty) return null;
    if (_currentDotIndex <= _dots.length) {
      return _dots[_currentDotIndex - 1];
    } else if (_currentPuzzle.isClosed && _currentDotIndex == _dots.length + 1) {
      return _dots[0]; // 마지막 단계: N번 점에서 1번 점으로 닫기
    }
    return null;
  }

  bool get _isGameFinished {
    if (_currentPuzzle.isClosed) {
      return _currentDotIndex > _dots.length + 1;
    } else {
      return _currentDotIndex > _dots.length;
    }
  }

  void _connectTargetDot() {
    final target = _targetDot;
    if (target == null) return;
    
    // 새 세그먼트 색상 인덱스 추가 (완성된 점 수 기준)
    final colorIdx = _completedPoints.isNotEmpty
        ? (_segmentColorIndices.length) % _rainbowPalette.length
        : 0;
    _segmentColorIndices.add(colorIdx);
    _completedPoints.add(target.position);
    _currentDotIndex++;
    
    // 연결될 때마다 음정이 점점 높아지도록 rate 조절
    double pitchRate = 1.0 + (_currentDotIndex * 0.05);
    if (pitchRate > 2.0) pitchRate = 2.0;
    AudioManager.instance.playDotConnect(rate: pitchRate);
    
    HapticFeedback.selectionClick();
    
    if (_isGameFinished) {
      _currentDragPos = null;
      _handleLevelClear();
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isLevelClear || _dots.isEmpty) return;
    
    final touchPos = details.localPosition;

    if (_completedPoints.isEmpty) {
      // 아직 시작하지 않은 상태 (1번 점 터치)
      final dot1 = _dots[0];
      if ((dot1.position - touchPos).distance < 80) {
        _completedPoints.add(dot1.position);
        _currentDotIndex = 2;
        _currentDragPos = touchPos;
        AudioManager.instance.playDotStart();
        HapticFeedback.lightImpact();
        setState(() {});
      }
    } else if (!_isGameFinished) {
      // 이미 일부 점이 연결된 상태
      final lastPoint = _completedPoints.last;
      final target = _targetDot;
      if (target == null) return;

      final distToLast = (lastPoint - touchPos).distance;
      final distToTarget = (target.position - touchPos).distance;

      // 마지막 연결 점 근처 또는 다음 연결할 목표 점 근처를 터치하면 이어받기
      if (distToLast < 90 || distToTarget < 90) {
        _currentDragPos = touchPos;
        setState(() {});

        // 목표 점에 바로 닿았으면 즉시 연결 처리
        if (distToTarget < 50) {
          _connectTargetDot();
          setState(() {});
        }
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isLevelClear || _currentDragPos == null) return;
    
    _currentDragPos = details.localPosition;
    
    final target = _targetDot;
    if (target != null) {
      if ((target.position - _currentDragPos!).distance < 50) {
        _connectTargetDot();
      }
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _currentDragPos = null;
    });
  }

  void _handleLevelClear() {
    _autoNextTimer?.cancel();
    AudioManager.instance.playDotSuccess();
    HapticFeedback.heavyImpact();
    setState(() {
      _isLevelClear = true;
      _score += 10;
    });
    
    _successAnimController.forward();

    // 8초 후 자동 다음 단계 (아이와 부모가 그림을 감상할 충분한 시간 부여)
    _autoNextTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isLevelClear) {
        _nextLevel();
      }
    });
  }

  void _nextLevel() {
    _autoNextTimer?.cancel();
    _autoNextTimer = null;
    if (!mounted) return;
    setState(() {
      _level++;
      _generateLevel(_screenSize);
    });
  }

  List<Color> _getSkyGradients(int level) {
    final themes = [
      // 레벨 1: 파스텔 스카이 블루 & 핑크
      [const Color(0xFFE0F7FA), const Color(0xFFE8EAF6), const Color(0xFFFFF3E0)],
      // 레벨 2: 싱그러운 햇살 초원 하늘
      [const Color(0xFFE0F2F1), const Color(0xFFE8F5E9), const Color(0xFFFFFDE7)],
      // 레벨 3: 솜사탕 노을 하늘
      [const Color(0xFFFFEBEE), const Color(0xFFF3E5F5), const Color(0xFFFFF3E0)],
      // 레벨 4: 몽환적인 라벤더 야경
      [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7), const Color(0xFFE8EAF6)],
      // 레벨 5: 알록달록 무지개 빛 하늘
      [const Color(0xFFE0F7FA), const Color(0xFFFFF9C4), const Color(0xFFFFE0B2)],
    ];
    return themes[(level - 1) % themes.length];
  }

  Widget _buildBackground() {
    final skyColors = _getSkyGradients(_level);

    return AnimatedBuilder(
      animation: Listenable.merge([_bgAnimController, _birdAnimController]),
      builder: (context, child) {
        final cloudProgress = _bgAnimController.value;
        final birdProgress = _birdAnimController.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // 새 1 (파란새 - 왼쪽에서 오른쪽으로)
            final bird1X = (birdProgress * (w + 140)) - 70;
            final bird1Y = 85.0 + sin(birdProgress * 4 * pi) * 14;

            // 새 2 (아기새 - 파란새 바로 뒤를 따라감)
            final bird2X = bird1X - 50;
            final bird2Y = bird1Y + 22;

            // 새 3 (하얀 비둘기 - 오른쪽에서 왼쪽으로)
            final bird3X = w - (((birdProgress + 0.4) % 1.0) * (w + 160)) + 80;
            final bird3Y = 145.0 + cos(birdProgress * 3 * pi) * 12;

            // 두둥실 떠다니는 구름 1, 2, 3 위치 (화면 전체 가로 무한 순환)
            final cloud1X = (cloudProgress * (w + 160)) - 80;
            final cloud2X = w - (((cloudProgress + 0.5) % 1.0) * (w + 180)) + 90;
            final cloud3X = (((cloudProgress + 0.25) % 1.0) * (w + 140)) - 70;

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: skyColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  // 떠다니는 구름 1
                  Positioned(
                    top: 60,
                    left: cloud1X,
                    child: Text(
                      '☁️',
                      style: TextStyle(
                        fontSize: 65,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),

                  // 떠다니는 구름 2
                  Positioned(
                    top: 130,
                    left: cloud2X,
                    child: Text(
                      '☁️',
                      style: TextStyle(
                        fontSize: 80,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                  ),

                  // 떠다니는 구름 3
                  Positioned(
                    bottom: 120,
                    left: cloud3X,
                    child: Text(
                      '☁️',
                      style: TextStyle(
                        fontSize: 70,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),

                  // 🐦 생동감 있게 날갯짓하며 오른쪽으로 날아가는 파란 새
                  Positioned(
                    top: bird1Y,
                    left: bird1X,
                    child: AnimatedFlappingBird(
                      flapProgress: (birdProgress * 22) % 1.0,
                      bodyColor: const Color(0xFF3B82F6),
                      wingColor: const Color(0xFF60A5FA),
                      size: 46,
                      isFacingRight: true,
                    ),
                  ),

                  // 🐤 따라가는 노란 아기새
                  Positioned(
                    top: bird2Y,
                    left: bird2X,
                    child: AnimatedFlappingBird(
                      flapProgress: (birdProgress * 28 + 0.2) % 1.0,
                      bodyColor: const Color(0xFFF59E0B),
                      wingColor: const Color(0xFFFBBF24),
                      size: 32,
                      isFacingRight: true,
                    ),
                  ),

                  // 🕊️ 생동감 있게 날갯짓하며 왼쪽으로 날아가는 하얀 비둘기
                  Positioned(
                    top: bird3Y,
                    left: bird3X,
                    child: AnimatedFlappingBird(
                      flapProgress: (birdProgress * 25 + 0.5) % 1.0,
                      bodyColor: Colors.white,
                      wingColor: const Color(0xFFE2E8F0),
                      size: 48,
                      isFacingRight: false, // 왼쪽 바라보고 날아가기
                    ),
                  ),

                  // 반짝이는 별과 비누방울
                  Positioned(
                    top: 100,
                    right: 120,
                    child: Text(
                      '✨',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.amber.withValues(alpha: 0.5 + 0.4 * sin(cloudProgress * 4 * pi)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 200,
                    left: 70,
                    child: Text(
                      '🌟',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.amber.withValues(alpha: 0.4 + 0.4 * cos(cloudProgress * 3 * pi)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 160,
                    right: 70,
                    child: Text(
                      '🫧',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white.withValues(alpha: 0.6 + 0.3 * sin(cloudProgress * 5 * pi)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로 가기 버튼
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
                border: Border.all(color: const Color(0xFF4D96FF).withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4D96FF).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4D96FF), size: 24),
            ),
          ),

          // 중앙 타이틀 + 스테이지 캡슐
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isLevelClear
                    ? [Colors.white, const Color(0xFFFFF9C4)]
                    : [Colors.white, const Color(0xFFF0F7FF)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isLevelClear ? const Color(0xFFFFD700) : Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isLevelClear ? const Color(0xFFFF9F1C) : const Color(0xFF4D96FF)).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_isLevelClear ? _currentPuzzle.emoji : '🖍️', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  _isLevelClear ? '🎉 ${_currentPuzzle.name} 완~성! 👏' : '점 잇기 놀이',
                  style: GoogleFonts.jua(
                    fontSize: 19,
                    color: const Color(0xFF2B3A4A),
                  ),
                ),
                if (!_isLevelClear) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Stage $_level',
                      style: GoogleFonts.jua(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 우측 균형을 위한 여백
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_screenSize.width != constraints.maxWidth) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _generateLevel(Size(constraints.maxWidth, constraints.maxHeight));
                    }
                  });
                }

                return Stack(
                  children: [
                    // 1. 완성 시 서서히 피어나는 알록달록 일러스트 아트워크
                    if (_isLevelClear)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FadeTransition(
                            opacity: _successAnimController,
                            child: CustomPaint(
                              painter: PuzzleCompletedArtPainter(
                                puzzle: _currentPuzzle,
                                paddingX: 60.0,
                                paddingTop: 140.0,
                                availWidth: constraints.maxWidth - 120.0,
                                availHeight: constraints.maxHeight - 240.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 2. 선 그리기 레이어
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: DotsPainter(
                            completedPoints: _completedPoints,
                            segmentColorIndices: _segmentColorIndices,
                            currentDragPos: _currentDragPos,
                            nextSegmentColorIdx: _segmentColorIndices.length % _rainbowPalette.length,
                          ),
                        ),
                      ),
                    ),

                    // 점 레이어
                    if (!_isLevelClear)
                      ..._dots.map((dot) {
                        final target = _targetDot;
                        final isNext = (target == dot);
                        final dotCompletedIdx = _completedPoints.indexOf(dot.position);
                        final isCompleted = !isNext && dotCompletedIdx >= 0;

                        // 완성된 점은 해당 세그먼트의 무지개 색상으로
                        final dotColor = isCompleted && dotCompletedIdx < _segmentColorIndices.length
                            ? _rainbowPalette[_segmentColorIndices[dotCompletedIdx] % _rainbowPalette.length]
                            : (isNext ? KidsTheme.orange : Colors.white);
                        final glowColor = isCompleted && dotCompletedIdx < _segmentColorIndices.length
                            ? _rainbowPalette[_segmentColorIndices[dotCompletedIdx] % _rainbowPalette.length]
                            : KidsTheme.orange;
                        
                        return Positioned(
                          left: dot.position.dx - 28,
                          top: dot.position.dy - 28,
                          child: IgnorePointer(
                            child: AnimatedScale(
                              scale: isNext ? 1.2 : (isCompleted ? 0.85 : 1.0),
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor,
                                  border: Border.all(
                                    color: isCompleted || isNext ? Colors.white : KidsTheme.borderDark,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    if (isNext || isCompleted)
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.65),
                                        blurRadius: isCompleted ? 12 : 18,
                                        spreadRadius: isCompleted ? 2 : 4,
                                      ),
                                    if (!isNext && !isCompleted)
                                      const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "${dot.number}",
                                    style: GoogleFonts.jua(
                                      fontSize: 26,
                                      color: isCompleted || isNext ? Colors.white : KidsTheme.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                    // 상단 헤더 UI (고급스럽고 아기자기한 디자인)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: _buildHeader(),
                    ),

                    // 클리어 시: 완성된 그림은 100% 가림 없이 시원하게 감상하고, 하단 중앙에 깔끔한 플로팅 [다음 그림 그리기 ➡️] 버튼만 배치
                    if (_isLevelClear)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ScaleTransition(
                            scale: _successScaleAnim,
                            child: GestureDetector(
                              onTap: () {
                                AudioManager.instance.playClick();
                                _nextLevel();
                              },
                              child: Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '다음 그림 그리기 ➡️',
                                      style: GoogleFonts.jua(
                                        fontSize: 19,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 생동감 있게 날갯짓하는 파스텔 Vector 새 위젯 ─────────────────────────────
class AnimatedFlappingBird extends StatelessWidget {
  final double flapProgress; // 0.0 to 1.0 fast wing cycle
  final Color bodyColor;
  final Color wingColor;
  final double size;
  final bool isFacingRight;

  const AnimatedFlappingBird({
    super.key,
    required this.flapProgress,
    required this.bodyColor,
    required this.wingColor,
    this.size = 46.0,
    this.isFacingRight = true,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: isFacingRight ? Matrix4.identity() : Matrix4.diagonal3Values(-1, 1, 1),
      child: CustomPaint(
        size: Size(size, size * 0.65),
        painter: _BirdPainter(
          flapVal: sin(flapProgress * 2 * pi),
          bodyColor: bodyColor,
          wingColor: wingColor,
        ),
      ),
    );
  }
}

class _BirdPainter extends CustomPainter {
  final double flapVal; // -1.0 (wings up) to 1.0 (wings down)
  final Color bodyColor;
  final Color wingColor;

  _BirdPainter({
    required this.flapVal,
    required this.bodyColor,
    required this.wingColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final wingPaint = Paint()
      ..color = wingColor
      ..style = PaintingStyle.fill;

    final wingBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final beakPaint = Paint()
      ..color = const Color(0xFFFF9800) // 주황색 부리
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()..color = const Color(0xFF1E293B);

    final backWingPaint = Paint()
      ..color = wingColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // 1. 뒷날개 (위로 날갯짓할 때 노출)
    final backWingPath = Path()
      ..moveTo(w * 0.45, h * 0.45)
      ..quadraticBezierTo(
        w * 0.35, h * 0.1 - flapVal * (h * 0.35),
        w * 0.15, h * 0.0 - flapVal * (h * 0.4),
      )
      ..quadraticBezierTo(
        w * 0.35, h * 0.35 - flapVal * (h * 0.2),
        w * 0.50, h * 0.55,
      )
      ..close();
    canvas.drawPath(backWingPath, backWingPaint);

    // 2. 꼬리 깃털
    final tailPath = Path()
      ..moveTo(w * 0.25, h * 0.5)
      ..lineTo(w * 0.05, h * 0.32)
      ..lineTo(w * 0.08, h * 0.52)
      ..lineTo(w * 0.02, h * 0.65)
      ..lineTo(w * 0.25, h * 0.6)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);

    // 3. 동글동글 통통한 몸통
    final bodyRect = Rect.fromLTWH(w * 0.2, h * 0.35, w * 0.52, h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(h * 0.2)),
      bodyPaint,
    );

    // 4. 머리
    final headCenter = Offset(w * 0.72, h * 0.42);
    final headRadius = h * 0.26;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);

    // 5. 부리 (오른쪽 전방을 향함)
    final beakPath = Path()
      ..moveTo(w * 0.86, h * 0.36)
      ..lineTo(w * 1.05, h * 0.45)
      ..lineTo(w * 0.86, h * 0.54)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // 6. 똘망똘망한 눈
    canvas.drawCircle(Offset(w * 0.78, h * 0.36), h * 0.07, eyePaint);
    canvas.drawCircle(Offset(w * 0.79, h * 0.34), h * 0.03, Paint()..color = Colors.white);

    // 7. 앞날개 (곡선 날갯짓 애니메이션!)
    final frontWingPath = Path()
      ..moveTo(w * 0.42, h * 0.5)
      ..quadraticBezierTo(
        w * 0.32, h * 0.15 - flapVal * (h * 0.4),
        w * 0.1, h * 0.0 - flapVal * (h * 0.45),
      )
      ..quadraticBezierTo(
        w * 0.32, h * 0.4 - flapVal * (h * 0.2),
        w * 0.55, h * 0.62,
      )
      ..close();

    canvas.drawPath(frontWingPath, wingPaint);
    canvas.drawPath(frontWingPath, wingBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _BirdPainter oldDelegate) {
    return oldDelegate.flapVal != flapVal ||
        oldDelegate.bodyColor != bodyColor ||
        oldDelegate.wingColor != wingColor;
  }
}

class DotsPainter extends CustomPainter {
  final List<Offset> completedPoints;
  final List<int> segmentColorIndices;
  final Offset? currentDragPos;
  final int nextSegmentColorIdx;

  DotsPainter({
    required this.completedPoints,
    required this.segmentColorIndices,
    required this.currentDragPos,
    required this.nextSegmentColorIdx,
  });

  void _drawSegment(Canvas canvas, Offset from, Offset to, Color color) {
    // 1. 글로우 (바깥쪽 부드러운 광채)
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawLine(from, to, glowPaint);

    // 2. 흰색 테두리 (선명도 향상)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, borderPaint);

    // 3. 무지개 색상 메인 라인
    final mainPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, mainPaint);

    // 4. 하이라이트 (윗부분 밝은 빛)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // 선의 약간 위쪽에 하이라이트
    final dx = (to.dy - from.dy);
    final dy = (from.dx - to.dx);
    final len = sqrt(dx * dx + dy * dy);
    if (len > 0) {
      final nx = dx / len * 2.5;
      final ny = dy / len * 2.5;
      canvas.drawLine(
        Offset(from.dx + nx, from.dy + ny),
        Offset(to.dx + nx, to.dy + ny),
        highlightPaint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (completedPoints.isEmpty) return;

    // 완성된 세그먼트 구간별로 무지개 색상으로 각각 그리기
    for (int i = 0; i < completedPoints.length - 1; i++) {
      final colorIdx = i < segmentColorIndices.length
          ? segmentColorIndices[i] % _rainbowPalette.length
          : i % _rainbowPalette.length;
      _drawSegment(
        canvas,
        completedPoints[i],
        completedPoints[i + 1],
        _rainbowPalette[colorIdx],
      );
    }

    // 드래그 중인 라인 (다음 세그먼트 색상으로 미리보기)
    if (currentDragPos != null && completedPoints.isNotEmpty) {
      final nextColor = _rainbowPalette[nextSegmentColorIdx % _rainbowPalette.length];
      // 점선 스타일로 드래그 라인 표시
      final from = completedPoints.last;
      final to = currentDragPos!;
      final dashPaint = Paint()
        ..color = nextColor.withValues(alpha: 0.6)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      // 점선 그리기
      final totalDx = to.dx - from.dx;
      final totalDy = to.dy - from.dy;
      final totalLen = sqrt(totalDx * totalDx + totalDy * totalDy);
      if (totalLen > 0) {
        const dashLen = 16.0;
        const gapLen = 10.0;
        double drawn = 0;
        while (drawn < totalLen) {
          final segEnd = (drawn + dashLen).clamp(0.0, totalLen);
          canvas.drawLine(
            Offset(from.dx + totalDx * drawn / totalLen, from.dy + totalDy * drawn / totalLen),
            Offset(from.dx + totalDx * segEnd / totalLen, from.dy + totalDy * segEnd / totalLen),
            dashPaint,
          );
          drawn += dashLen + gapLen;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotsPainter oldDelegate) {
    return true;
  }
}

// ─── 완성 시 나타나는 사랑스러운 고화질 Vector 일러스트 페인터 ─────────────────
class PuzzleCompletedArtPainter extends CustomPainter {
  final DotPuzzle puzzle;
  final double paddingX;
  final double paddingTop;
  final double availWidth;
  final double availHeight;

  PuzzleCompletedArtPainter({
    required this.puzzle,
    required this.paddingX,
    required this.paddingTop,
    required this.availWidth,
    required this.availHeight,
  });

  Offset pt(double x, double y) => Offset(paddingX + x * availWidth, paddingTop + y * availHeight);

  @override
  void paint(Canvas canvas, Size size) {
    switch (puzzle.emoji) {
      case '🐌':
        _drawSnail(canvas);
        break;
      case '⭐':
        _drawStar(canvas);
        break;
      case '🏠':
        _drawHouse(canvas);
        break;
      case '🐠':
        _drawFish(canvas);
        break;
      case '💖':
        _drawHeart(canvas);
        break;
      case '🦋':
        _drawButterfly(canvas);
        break;
      case '🐱':
        _drawCat(canvas);
        break;
      case '🍦':
        _drawIceCream(canvas);
        break;
      case '🚗':
        _drawCar(canvas);
        break;
      case '🧸':
        _drawBear(canvas);
        break;
      case '🍓':
        _drawStrawberry(canvas);
        break;
      case '👑':
        _drawCrown(canvas);
        break;
      case '🚀':
        _drawRocket(canvas);
        break;
      case '🍬':
        _drawCandy(canvas);
        break;
      case '🍎':
        _drawApple(canvas);
        break;
      case '🎈':
        _drawBalloon(canvas);
        break;
      default:
        _drawGeneric(canvas);
    }
  }

  // 1. 🐌 느릿느릿 달팽이 (귀여운 민트 바디 + 똥글똥글 커다란 나선 등딱지 + 더듬이 눈 & 미소)
  void _drawSnail(Canvas canvas) {
    final bodyPaint = Paint()..color = const Color(0xFFA5D6A7)..style = PaintingStyle.fill;
    final shellPaint = Paint()..color = const Color(0xFFFFB74D)..style = PaintingStyle.fill;
    final swirlPaint = Paint()
      ..color = const Color(0xFFE65100)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eyeWhitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final eyeBlackPaint = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final blushPaint = Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.7)..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    // 1. 앙증맞은 달팽이 바디 (꼬리 -> 배 -> 머리)
    final bodyPath = Path()
      ..moveTo(pt(0.12, 0.78).dx, pt(0.12, 0.78).dy)
      ..cubicTo(pt(0.08, 0.74).dx, pt(0.08, 0.74).dy, pt(0.35, 0.85).dx, pt(0.35, 0.85).dy, pt(0.85, 0.86).dx, pt(0.85, 0.86).dy)
      ..cubicTo(pt(0.96, 0.85).dx, pt(0.96, 0.85).dy, pt(0.98, 0.65).dx, pt(0.98, 0.65).dy, pt(0.90, 0.58).dx, pt(0.90, 0.58).dy)
      ..cubicTo(pt(0.82, 0.62).dx, pt(0.82, 0.62).dy, pt(0.70, 0.72).dx, pt(0.70, 0.72).dy, pt(0.50, 0.75).dx, pt(0.50, 0.75).dy)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // 2. 등딱지 원형 쉘
    final shellCenter = pt(0.48, 0.56);
    final shellRadius = availWidth * 0.26;
    canvas.drawCircle(shellCenter, shellRadius, shellPaint);
    final shellStroke = Paint()
      ..color = const Color(0xFFEF6C00)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(shellCenter, shellRadius, shellStroke);

    // 3. 등딱지 나선 (소용돌이)
    final swirlPath = Path();
    swirlPath.moveTo(shellCenter.dx + shellRadius * 0.75, shellCenter.dy);
    swirlPath.arcTo(Rect.fromCircle(center: shellCenter, radius: shellRadius * 0.75), 0, pi, false);
    swirlPath.arcTo(Rect.fromCircle(center: Offset(shellCenter.dx, shellCenter.dy - shellRadius * 0.1), radius: shellRadius * 0.52), pi, pi, false);
    swirlPath.arcTo(Rect.fromCircle(center: Offset(shellCenter.dx, shellCenter.dy + shellRadius * 0.05), radius: shellRadius * 0.32), 0, pi, false);
    swirlPath.arcTo(Rect.fromCircle(center: shellCenter, radius: shellRadius * 0.15), pi, pi, false);
    canvas.drawPath(swirlPath, swirlPaint);

    // 4. 더듬이 2개 & 왕눈이
    final antennaPaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // 왼쪽 더듬이
    canvas.drawLine(pt(0.88, 0.58), pt(0.85, 0.38), antennaPaint);
    canvas.drawCircle(pt(0.85, 0.38), 10, eyeWhitePaint);
    canvas.drawCircle(pt(0.85, 0.38), 10, strokePaint);
    canvas.drawCircle(pt(0.85, 0.38), 5.5, eyeBlackPaint);
    canvas.drawCircle(pt(0.83, 0.36), 2.2, eyeWhitePaint); // 반짝이

    // 오른쪽 더듬이
    canvas.drawLine(pt(0.92, 0.60), pt(0.96, 0.40), antennaPaint);
    canvas.drawCircle(pt(0.96, 0.40), 10, eyeWhitePaint);
    canvas.drawCircle(pt(0.96, 0.40), 10, strokePaint);
    canvas.drawCircle(pt(0.96, 0.40), 5.5, eyeBlackPaint);
    canvas.drawCircle(pt(0.94, 0.38), 2.2, eyeWhitePaint); // 반짝이

    // 5. 볼터치 & 방긋 미소
    canvas.drawCircle(pt(0.92, 0.68), 7, blushPaint);
    final smilePath = Path()
      ..moveTo(pt(0.92, 0.74).dx, pt(0.92, 0.74).dy)
      ..arcToPoint(pt(0.97, 0.70), radius: const Radius.circular(8), clockwise: false);
    canvas.drawPath(smilePath, swirlPaint..strokeWidth = 3.0);
  }

  // 2. ⭐ 반짝반짝 별
  void _drawStar(Canvas canvas) {
    final fillPaint = Paint()..color = const Color(0xFFFFEE58)..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = const Color(0xFFF57F17)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    final pts = puzzle.points;
    path.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // 얼굴 (눈, 볼터치, 입)
    final eyePaint = Paint()..color = const Color(0xFF212121)..style = PaintingStyle.fill;
    final white = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(pt(0.42, 0.50), 6, eyePaint);
    canvas.drawCircle(pt(0.40, 0.48), 2, white);
    canvas.drawCircle(pt(0.58, 0.50), 6, eyePaint);
    canvas.drawCircle(pt(0.56, 0.48), 2, white);
    canvas.drawCircle(pt(0.36, 0.56), 6, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.6));
    canvas.drawCircle(pt(0.64, 0.56), 6, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.6));
    final smile = Path()..moveTo(pt(0.46, 0.56).dx, pt(0.46, 0.56).dy)..arcToPoint(pt(0.54, 0.56), radius: const Radius.circular(6), clockwise: false);
    canvas.drawPath(smile, Paint()..color = const Color(0xFFE65100)..strokeWidth = 3.0..style = PaintingStyle.stroke);
  }

  // 3. 🏠 예쁜 집
  void _drawHouse(Canvas canvas) {
    // 벽
    canvas.drawRect(Rect.fromLTRB(pt(0.2, 0.45).dx, pt(0.2, 0.45).dy, pt(0.8, 0.9).dx, pt(0.8, 0.9).dy), Paint()..color = const Color(0xFFFFF9C4));
    // 지붕
    final roof = Path()
      ..moveTo(pt(0.5, 0.1).dx, pt(0.5, 0.1).dy)
      ..lineTo(pt(0.9, 0.45).dx, pt(0.9, 0.45).dy)
      ..lineTo(pt(0.1, 0.45).dx, pt(0.1, 0.45).dy)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFEF5350));
    // 굴뚝
    canvas.drawRect(Rect.fromLTRB(pt(0.68, 0.15).dx, pt(0.68, 0.15).dy, pt(0.76, 0.32).dx, pt(0.76, 0.32).dy), Paint()..color = const Color(0xFF8D6E63));
    // 창문 (하늘색 격자)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.35, 0.62), width: 36, height: 36), const Radius.circular(6)), Paint()..color = const Color(0xFF81D4FA));
    // 문 (초콜릿)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.65, 0.72), width: 34, height: 50), const Radius.circular(6)), Paint()..color = const Color(0xFF8D6E63));
    canvas.drawCircle(pt(0.68, 0.72), 3, Paint()..color = const Color(0xFFFFD54F));
  }

  // 4. 🐠 물고기
  void _drawFish(Canvas canvas) {
    final fishBody = Path()
      ..moveTo(pt(0.9, 0.5).dx, pt(0.9, 0.5).dy)
      ..cubicTo(pt(0.7, 0.15).dx, pt(0.7, 0.15).dy, pt(0.2, 0.35).dx, pt(0.2, 0.35).dy, pt(0.05, 0.2).dx, pt(0.05, 0.2).dy)
      ..lineTo(pt(0.05, 0.8).dx, pt(0.05, 0.8).dy)
      ..cubicTo(pt(0.2, 0.65).dx, pt(0.2, 0.65).dy, pt(0.7, 0.85).dx, pt(0.7, 0.85).dy, pt(0.9, 0.5).dx, pt(0.9, 0.5).dy)
      ..close();
    canvas.drawPath(fishBody, Paint()..color = const Color(0xFFFF7043));
    // 흰색 스트라이프
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.55, 0.50), width: 22, height: 75), const Radius.circular(10)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.32, 0.50), width: 18, height: 55), const Radius.circular(8)), Paint()..color = Colors.white);
    // 눈 & 뽀글이
    canvas.drawCircle(pt(0.76, 0.44), 7, Paint()..color = Colors.white);
    canvas.drawCircle(pt(0.76, 0.44), 4, Paint()..color = const Color(0xFF212121));
  }

  // 5. 💖 사랑해 하트
  void _drawHeart(Canvas canvas) {
    final path = Path();
    final pts = puzzle.points;
    path.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    path.cubicTo(pt(pts[1].dx, pts[1].dy).dx, pt(pts[1].dx, pts[1].dy).dy, pt(pts[2].dx, pts[2].dy).dx, pt(pts[2].dx, pts[2].dy).dy, pt(pts[3].dx, pts[3].dy).dx, pt(pts[3].dx, pts[3].dy).dy);
    path.cubicTo(pt(pts[4].dx, pts[4].dy).dx, pt(pts[4].dx, pts[4].dy).dy, pt(pts[5].dx, pts[5].dy).dx, pt(pts[5].dx, pts[5].dy).dy, pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFF4081));
    // 하이라이트 광택
    canvas.drawOval(Rect.fromCenter(center: pt(0.32, 0.28), width: 26, height: 16), Paint()..color = Colors.white.withValues(alpha: 0.6));
    // 얼굴
    canvas.drawCircle(pt(0.42, 0.52), 5, Paint()..color = Colors.white);
    canvas.drawCircle(pt(0.58, 0.52), 5, Paint()..color = Colors.white);
    final smile = Path()..moveTo(pt(0.46, 0.58).dx, pt(0.46, 0.58).dy)..arcToPoint(pt(0.54, 0.58), radius: const Radius.circular(5), clockwise: false);
    canvas.drawPath(smile, Paint()..color = Colors.white..strokeWidth = 3.0..style = PaintingStyle.stroke);
  }

  // 6. 🦋 팔랑팔랑 나비
  void _drawButterfly(Canvas canvas) {
    // 날개 채우기
    final wings = Path();
    final pts = puzzle.points;
    wings.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      wings.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    wings.close();
    canvas.drawPath(wings, Paint()..color = const Color(0xFFBA68C8));
    // 날개 안쪽 무늬
    canvas.drawCircle(pt(0.70, 0.35), 18, Paint()..color = const Color(0xFF4DD0E1));
    canvas.drawCircle(pt(0.30, 0.35), 18, Paint()..color = const Color(0xFF4DD0E1));
    canvas.drawCircle(pt(0.78, 0.70), 12, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(pt(0.22, 0.70), 12, Paint()..color = const Color(0xFFFFD54F));
    // 몸통 & 더듬이
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.5, 0.55), width: 14, height: 90), const Radius.circular(7)), Paint()..color = const Color(0xFF4A148C));
  }

  // 7. 🐱 귀여운 고양이
  void _drawCat(Canvas canvas) {
    final catFace = Path();
    final pts = puzzle.points;
    catFace.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      catFace.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    catFace.close();
    canvas.drawPath(catFace, Paint()..color = const Color(0xFFFFCC80));
    // 핑크 귓속
    canvas.drawPath(Path()..moveTo(pt(0.25, 0.26).dx, pt(0.25, 0.26).dy)..lineTo(pt(0.36, 0.32).dx, pt(0.36, 0.32).dy)..lineTo(pt(0.22, 0.38).dx, pt(0.22, 0.38).dy)..close(), Paint()..color = const Color(0xFFFF80AB));
    canvas.drawPath(Path()..moveTo(pt(0.75, 0.26).dx, pt(0.75, 0.26).dy)..lineTo(pt(0.64, 0.32).dx, pt(0.64, 0.32).dy)..lineTo(pt(0.78, 0.38).dx, pt(0.78, 0.38).dy)..close(), Paint()..color = const Color(0xFFFF80AB));
    // 눈, 코, 수염
    canvas.drawCircle(pt(0.38, 0.52), 6, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(pt(0.62, 0.52), 6, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(pt(0.50, 0.62), 4, Paint()..color = const Color(0xFFFF4081));
    // 수염
    final wPaint = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(pt(0.30, 0.58), pt(0.12, 0.54), wPaint);
    canvas.drawLine(pt(0.30, 0.64), pt(0.12, 0.68), wPaint);
    canvas.drawLine(pt(0.70, 0.58), pt(0.88, 0.54), wPaint);
    canvas.drawLine(pt(0.70, 0.64), pt(0.88, 0.68), wPaint);
  }

  // 8. 🍦 달콤 아이스크림
  void _drawIceCream(Canvas canvas) {
    // 와플콘
    final cone = Path()..moveTo(pt(0.3, 0.5).dx, pt(0.3, 0.5).dy)..lineTo(pt(0.7, 0.5).dx, pt(0.7, 0.5).dy)..lineTo(pt(0.5, 0.95).dx, pt(0.5, 0.95).dy)..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFFFB74D));
    // 크림 스쿱
    final cream = Path()..moveTo(pt(0.3, 0.5).dx, pt(0.3, 0.5).dy)..cubicTo(pt(0.1, 0.25).dx, pt(0.1, 0.25).dy, pt(0.5, 0.05).dx, pt(0.5, 0.05).dy, pt(0.85, 0.25).dx, pt(0.85, 0.25).dy)..lineTo(pt(0.7, 0.5).dx, pt(0.7, 0.5).dy)..close();
    canvas.drawPath(cream, Paint()..color = const Color(0xFFFF80AB));
    // 체리
    canvas.drawCircle(pt(0.5, 0.12), 12, Paint()..color = const Color(0xFFD50000));
  }

  // 9. 🚗 빠방 자동차
  void _drawCar(Canvas canvas) {
    // 차체
    final car = Path();
    final pts = puzzle.points;
    car.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      car.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    car.close();
    canvas.drawPath(car, Paint()..color = const Color(0xFFE53935));
    // 창문
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.48, 0.32), width: 34, height: 24), const Radius.circular(5)), Paint()..color = const Color(0xFF81D4FA));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pt(0.68, 0.32), width: 30, height: 24), const Radius.circular(5)), Paint()..color = const Color(0xFF81D4FA));
    // 바퀴
    canvas.drawCircle(pt(0.25, 0.68), 16, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(pt(0.25, 0.68), 7, Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawCircle(pt(0.65, 0.68), 16, Paint()..color = const Color(0xFF263238));
    canvas.drawCircle(pt(0.65, 0.68), 7, Paint()..color = const Color(0xFFCFD8DC));
    // 헤드라이트
    canvas.drawCircle(pt(0.14, 0.52), 6, Paint()..color = const Color(0xFFFFEB3B));
  }

  // 10. 🧸 곰돌이
  void _drawBear(Canvas canvas) {
    final head = Path();
    final pts = puzzle.points;
    head.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      head.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    head.close();
    canvas.drawPath(head, Paint()..color = const Color(0xFF8D6E63));
    // 머즐
    canvas.drawOval(Rect.fromCenter(center: pt(0.5, 0.66), width: 48, height: 36), Paint()..color = const Color(0xFFD7CCC8));
    canvas.drawOval(Rect.fromCenter(center: pt(0.5, 0.62), width: 14, height: 10), Paint()..color = const Color(0xFF3E2723));
    // 눈 & 볼터치
    canvas.drawCircle(pt(0.36, 0.50), 6, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(pt(0.64, 0.50), 6, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(pt(0.28, 0.60), 8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.6));
    canvas.drawCircle(pt(0.72, 0.60), 8, Paint()..color = const Color(0xFFFF8A80).withValues(alpha: 0.6));
  }

  // 11. 🍓 딸기
  void _drawStrawberry(Canvas canvas) {
    final body = Path()..moveTo(pt(0.25, 0.18).dx, pt(0.25, 0.18).dy)..cubicTo(pt(0.05, 0.45).dx, pt(0.05, 0.45).dy, pt(0.25, 0.85).dx, pt(0.25, 0.85).dy, pt(0.5, 0.95).dx, pt(0.5, 0.95).dy)..cubicTo(pt(0.75, 0.85).dx, pt(0.75, 0.85).dy, pt(0.95, 0.45).dx, pt(0.95, 0.45).dy, pt(0.75, 0.18).dx, pt(0.75, 0.18).dy)..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE53935));
    // 꼭지 잎
    final leaf = Path()..moveTo(pt(0.5, 0.05).dx, pt(0.5, 0.05).dy)..lineTo(pt(0.75, 0.18).dx, pt(0.75, 0.18).dy)..lineTo(pt(0.5, 0.22).dx, pt(0.5, 0.22).dy)..lineTo(pt(0.25, 0.18).dx, pt(0.25, 0.18).dy)..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF43A047));
    // 씨앗
    final seed = Paint()..color = const Color(0xFFFFEE58);
    for (double y = 0.35; y <= 0.75; y += 0.12) {
      for (double x = 0.32; x <= 0.68; x += 0.14) {
        canvas.drawCircle(pt(x, y), 2.5, seed);
      }
    }
  }

  // 12. 👑 왕관
  void _drawCrown(Canvas canvas) {
    final crown = Path();
    final pts = puzzle.points;
    crown.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      crown.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    crown.close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD54F));
    // 보석들
    canvas.drawCircle(pt(0.05, 0.25), 8, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(pt(0.5, 0.1), 10, Paint()..color = const Color(0xFF1E88E5));
    canvas.drawCircle(pt(0.95, 0.25), 8, Paint()..color = const Color(0xFF43A047));
  }

  // 13. 🚀 로켓
  void _drawRocket(Canvas canvas) {
    final rocket = Path();
    final pts = puzzle.points;
    rocket.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      rocket.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    rocket.close();
    canvas.drawPath(rocket, Paint()..color = const Color(0xFFECEFF1));
    // 창문
    canvas.drawCircle(pt(0.5, 0.45), 18, Paint()..color = const Color(0xFF81D4FA));
    canvas.drawCircle(pt(0.5, 0.45), 18, Paint()..color = const Color(0xFF0288D1)..strokeWidth = 3..style = PaintingStyle.stroke);
    // 불꽃
    final flame = Path()..moveTo(pt(0.40, 0.85).dx, pt(0.40, 0.85).dy)..lineTo(pt(0.5, 0.98).dx, pt(0.5, 0.98).dy)..lineTo(pt(0.60, 0.85).dx, pt(0.60, 0.85).dy)..close();
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFF9100));
  }

  // 14. 🍬 캔디
  void _drawCandy(Canvas canvas) {
    final candy = Path();
    final pts = puzzle.points;
    candy.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      candy.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    candy.close();
    canvas.drawPath(candy, Paint()..color = const Color(0xFFFF80AB));
    canvas.drawCircle(pt(0.5, 0.5), availWidth * 0.22, Paint()..color = const Color(0xFFF48FB1));
    canvas.drawCircle(pt(0.5, 0.5), availWidth * 0.12, Paint()..color = Colors.white);
  }

  // 15. 🍎 사과
  void _drawApple(Canvas canvas) {
    final apple = Path()..moveTo(pt(0.5, 0.2).dx, pt(0.5, 0.2).dy)..cubicTo(pt(0.85, 0.1).dx, pt(0.85, 0.1).dy, pt(1.0, 0.5).dx, pt(1.0, 0.5).dy, pt(0.7, 0.9).dx, pt(0.7, 0.9).dy)..cubicTo(pt(0.5, 0.85).dx, pt(0.5, 0.85).dy, pt(0.3, 0.9).dx, pt(0.3, 0.9).dy, pt(0.0, 0.5).dx, pt(0.0, 0.5).dy)..cubicTo(pt(0.15, 0.1).dx, pt(0.15, 0.1).dy, pt(0.5, 0.2).dx, pt(0.5, 0.2).dy, pt(0.5, 0.2).dx, pt(0.5, 0.2).dy)..close();
    canvas.drawPath(apple, Paint()..color = const Color(0xFFE53935));
    // 잎 & 줄기
    canvas.drawLine(pt(0.5, 0.2), pt(0.5, 0.05), Paint()..color = const Color(0xFF5D4037)..strokeWidth = 5..strokeCap = StrokeCap.round);
    final leaf = Path()..moveTo(pt(0.5, 0.12).dx, pt(0.5, 0.12).dy)..cubicTo(pt(0.68, 0.02).dx, pt(0.68, 0.02).dy, pt(0.75, 0.18).dx, pt(0.75, 0.18).dy, pt(0.5, 0.12).dx, pt(0.5, 0.12).dy)..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF43A047));
    // 광택
    canvas.drawOval(Rect.fromCenter(center: pt(0.32, 0.35), width: 22, height: 14), Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  // 16. 🎈 풍선
  void _drawBalloon(Canvas canvas) {
    canvas.drawOval(Rect.fromCenter(center: pt(0.5, 0.45), width: availWidth * 0.65, height: availHeight * 0.55), Paint()..color = const Color(0xFFFF5252));
    // 매듭
    final knot = Path()..moveTo(pt(0.46, 0.72).dx, pt(0.46, 0.72).dy)..lineTo(pt(0.54, 0.72).dx, pt(0.54, 0.72).dy)..lineTo(pt(0.5, 0.76).dx, pt(0.5, 0.76).dy)..close();
    canvas.drawPath(knot, Paint()..color = const Color(0xFFD32F2F));
    // 실
    final string = Path()..moveTo(pt(0.5, 0.76).dx, pt(0.5, 0.76).dy)..cubicTo(pt(0.55, 0.82).dx, pt(0.55, 0.82).dy, pt(0.45, 0.88).dx, pt(0.45, 0.88).dy, pt(0.5, 0.95).dx, pt(0.5, 0.95).dy);
    canvas.drawPath(string, Paint()..color = const Color(0xFF757575)..strokeWidth = 2.5..style = PaintingStyle.stroke);
    // 광택
    canvas.drawOval(Rect.fromCenter(center: pt(0.36, 0.32), width: 20, height: 12), Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  void _drawGeneric(Canvas canvas) {
    final path = Path();
    final pts = puzzle.points;
    if (pts.isEmpty) return;
    path.moveTo(pt(pts[0].dx, pts[0].dy).dx, pt(pts[0].dx, pts[0].dy).dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pt(pts[i].dx, pts[i].dy).dx, pt(pts[i].dx, pts[i].dy).dy);
    }
    if (puzzle.isClosed) path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(covariant PuzzleCompletedArtPainter oldDelegate) {
    return oldDelegate.puzzle != puzzle;
  }
}

