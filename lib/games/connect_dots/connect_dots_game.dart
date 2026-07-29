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

class _ConnectDotsGameState extends State<ConnectDotsGame> with TickerProviderStateMixin {
  int _score = 0;
  int _level = 1;
  bool _isLevelClear = false;

  List<Dot> _dots = [];
  int _currentDotIndex = 1;

  List<Offset> _completedPoints = [];
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
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF0F7FF)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4D96FF).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🖍️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  '점 잇기 놀이',
                  style: GoogleFonts.jua(
                    fontSize: 19,
                    color: const Color(0xFF2B3A4A),
                  ),
                ),
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
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 우측 균형을 위한 여백 (별 점수 뱃지 제거)
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
                    // 선 그리기 레이어
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: DotsPainter(
                            completedPoints: _completedPoints,
                            currentDragPos: _currentDragPos,
                          ),
                        ),
                      ),
                    ),

                    // 점 레이어
                    if (!_isLevelClear)
                      ..._dots.map((dot) {
                        final target = _targetDot;
                        final isNext = (target == dot);
                        final isCompleted = !isNext && _completedPoints.contains(dot.position);
                        
                        return Positioned(
                          left: dot.position.dx - 28,
                          top: dot.position.dy - 28,
                          child: IgnorePointer(
                            child: AnimatedScale(
                              scale: isNext ? 1.2 : (isCompleted ? 0.8 : 1.0),
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted ? KidsTheme.green : (isNext ? KidsTheme.orange : Colors.white),
                                  border: Border.all(color: isNext ? Colors.white : KidsTheme.borderDark, width: 4),
                                  boxShadow: [
                                    if (isNext)
                                      BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 4),
                                    if (!isNext)
                                      const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    "${dot.number}",
                                    style: GoogleFonts.jua(
                                      fontSize: 26, 
                                      color: isCompleted ? Colors.white : KidsTheme.textDark
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

                    // 클리어 시: 완성된 그림은 100% 뚜렷하게 가림없이 감상하고, 하단에 왕 왕 커다란 [다음 단계 ➡️] 버튼 배치
                    if (_isLevelClear) ...[
                      // 1. 완성된 퍼즐 이모지 (그림 중앙에서 앙증맞게 퐁퐁 바운스)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: ScaleTransition(
                              scale: _successScaleAnim,
                              child: Text(
                                _currentPuzzle.emoji,
                                style: const TextStyle(
                                  fontSize: 120,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                                    Shadow(color: Colors.white, blurRadius: 30),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. 하단 플로팅 완성 카드 및 왕 왕 커다란 [다음 단계로 ➡️] 버튼
                      Positioned(
                        bottom: 20,
                        left: 16,
                        right: 16,
                        child: ScaleTransition(
                          scale: _successScaleAnim,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFFFD700), width: 3.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF9F1C).withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 타이틀 텍스트
                                Text(
                                  '🎉 ${_currentPuzzle.name} 완~성! 🎉',
                                  style: GoogleFonts.jua(
                                    fontSize: 22,
                                    color: const Color(0xFF2B3A4A),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // 왕 왕 크고 신나는 [다음 단계로 ➡️] 버튼
                                GestureDetector(
                                  onTap: () {
                                    AudioManager.instance.playClick();
                                    _nextLevel();
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF4ADE80), Color(0xFF16A34A)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '다음 단계로 넘어 가기! ➡️',
                                            style: GoogleFonts.jua(
                                              fontSize: 22,
                                              color: Colors.white,
                                              shadows: const [
                                                Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                              ],
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
                      ),
                    ],
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
  final Offset? currentDragPos;

  DotsPainter({
    required this.completedPoints,
    required this.currentDragPos,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KidsTheme.blue
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
      
    final shadowPaint = Paint()
      ..color = KidsTheme.blue.withValues(alpha: 0.3)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed lines
    if (completedPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(completedPoints[0].dx, completedPoints[0].dy);
      for (int i = 1; i < completedPoints.length; i++) {
        path.lineTo(completedPoints[i].dx, completedPoints[i].dy);
      }
      
      // Draw dragging line
      if (currentDragPos != null) {
        path.lineTo(currentDragPos!.dx, currentDragPos!.dy);
      }
      
      canvas.drawPath(path, shadowPaint);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotsPainter oldDelegate) {
    return true; // Simplified for game loop
  }
}
