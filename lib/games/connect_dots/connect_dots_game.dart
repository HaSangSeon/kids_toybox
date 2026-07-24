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
  
  // 성공 애니메이션 용
  late AnimationController _successAnimController;
  late Animation<double> _successScaleAnim;

  @override
  void initState() {
    super.initState();
    _currentPuzzle = _puzzles[0]; // dummy init
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScaleAnim = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _successAnimController.dispose();
    super.dispose();
  }

  void _generateLevel(Size size) {
    _screenSize = size;
    _dots.clear();
    _completedPoints.clear();
    _currentDotIndex = 1;
    _isLevelClear = false;
    _currentDragPos = null;
    _successAnimController.reset();

    // 랜덤 퍼즐 선택
    _currentPuzzle = _puzzles[_random.nextInt(_puzzles.length)];

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
    AudioManager.instance.playDotSuccess();
    HapticFeedback.heavyImpact();
    setState(() {
      _isLevelClear = true;
      _score += 10;
    });
    
    _successAnimController.forward();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _level++;
          _generateLevel(_screenSize);
        });
      }
    });
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: 80, left: 20, child: Text('☁️', style: TextStyle(fontSize: 50, color: Colors.white.withValues(alpha: 0.7)))),
          Positioned(top: 160, right: 30, child: Text('☁️', style: TextStyle(fontSize: 70, color: Colors.white.withValues(alpha: 0.6)))),
          Positioned(bottom: 120, left: 50, child: Text('☁️', style: TextStyle(fontSize: 60, color: Colors.white.withValues(alpha: 0.5)))),
          Positioned(bottom: 220, right: 40, child: Text('☁️', style: TextStyle(fontSize: 45, color: Colors.white.withValues(alpha: 0.6)))),
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

                    // 상단 헤더 UI
                    Positioned(
                      top: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              AudioManager.instance.playClick();
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: KidsTheme.blue.withValues(alpha: 0.4), width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: const Icon(Icons.close_rounded, color: KidsTheme.textDark, size: 24),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Text(
                              '점 잇기 🖍️',
                              style: GoogleFonts.jua(fontSize: 26, color: KidsTheme.blue),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: KidsTheme.orange.withValues(alpha: 0.5), width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Text(
                              '🎯 $_score',
                              style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 클리어 시 나타나는 이모지와 축하 문구
                    if (_isLevelClear)
                      Positioned.fill(
                        child: Center(
                          child: ScaleTransition(
                            scale: _successScaleAnim,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentPuzzle.emoji,
                                  style: const TextStyle(fontSize: 160, shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                                  ]),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: KidsTheme.yellow,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 5))
                                    ],
                                  ),
                                  child: Text(
                                    '짜잔! ${_currentPuzzle.name} 완성! 🎉',
                                    style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark),
                                  ),
                                ),
                              ],
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
