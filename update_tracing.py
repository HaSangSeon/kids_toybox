import os

code = """import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

class TracingGame extends StatefulWidget {
  const TracingGame({super.key});

  @override
  State<TracingGame> createState() => _TracingGameState();
}

class ShapeDef {
  final String name;
  final List<Offset> points;
  ShapeDef(this.name, this.points);
}

class _TracingGameState extends State<TracingGame> {
  int _score = 0;
  int _level = 0;
  bool _isLevelClear = false;
  
  final List<Offset> _userPath = [];
  int _targetPointIndex = 0;
  bool _isReversed = false;

  late List<ShapeDef> _shapes;

  @override
  void initState() {
    super.initState();
    // 0~100 좌표계 기준
    _shapes = [
      ShapeDef('직선 긋기', const [Offset(10, 50), Offset(90, 50)]),
      ShapeDef('지그재그', const [Offset(10, 80), Offset(30, 20), Offset(50, 80), Offset(70, 20), Offset(90, 80)]),
      ShapeDef('삼각형', const [Offset(50, 10), Offset(90, 90), Offset(10, 90), Offset(50, 10)]),
      ShapeDef('사각형', const [Offset(20, 20), Offset(80, 20), Offset(80, 80), Offset(20, 80), Offset(20, 20)]),
      ShapeDef('글자 A', const [Offset(10, 90), Offset(50, 10), Offset(90, 90)]), // 간단한 A
      ShapeDef('별 그리기', const [Offset(50, 10), Offset(75, 90), Offset(10, 40), Offset(90, 40), Offset(25, 90), Offset(50, 10)]),
    ];
  }

  void _nextLevel() {
    setState(() {
      _userPath.clear();
      _targetPointIndex = 0;
      _isReversed = false;
      _isLevelClear = false;
    });
  }

  List<Offset> _getScaledPoints(Size size) {
    if (_shapes.isEmpty) return [];
    final shape = _shapes[_level % _shapes.length];
    
    final scaleX = size.width / 130;
    final scaleY = size.height / 130;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    final offsetX = (size.width - 100 * scale) / 2;
    final offsetY = (size.height - 100 * scale) / 2 + 30;

    return shape.points.map((p) => Offset(p.dx * scale + offsetX, p.dy * scale + offsetY)).toList();
  }

  void _onPanStart(DragStartDetails details, Size size) {
    if (_isLevelClear) return;
    
    final points = _getScaledPoints(size);
    if (points.isEmpty) return;

    if (_targetPointIndex == 0) {
      double distToFirst = (details.localPosition - points.first).distance;
      double distToLast = (details.localPosition - points.last).distance;

      if (distToFirst < 60) {
        _isReversed = false;
        _userPath.add(points.first);
        _targetPointIndex = 1;
        AudioManager.instance.playPop(); // 좀 더 귀여운 소리
        setState(() {});
      } else if (distToLast < 60) {
        _isReversed = true;
        _userPath.add(points.last);
        _targetPointIndex = 1;
        AudioManager.instance.playPop();
        setState(() {});
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_isLevelClear || _userPath.isEmpty) return;
    
    final points = _getScaledPoints(size);
    if (points.isEmpty) return;
    
    _userPath.add(details.localPosition);
    
    if (_targetPointIndex < points.length) {
      int actualTargetIndex = _isReversed ? (points.length - 1 - _targetPointIndex) : _targetPointIndex;
      
      if ((details.localPosition - points[actualTargetIndex]).distance < 60) {
        _targetPointIndex++;
        AudioManager.instance.playChime(); // 점에 닿을 때 예쁜 소리
        HapticFeedback.selectionClick();
        
        if (_targetPointIndex >= points.length) {
          AudioManager.instance.playSuccess();
          HapticFeedback.heavyImpact();
          setState(() {
            _isLevelClear = true;
            _score += 10;
          });
          
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _level++;
                _nextLevel();
              });
            }
          });
        }
      }
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isLevelClear) {
      // 놓치면 다시 처음부터
      _userPath.clear();
      _targetPointIndex = 0;
      _isReversed = false;
      setState(() {});
    }
  }

  Widget _buildNotebookBackground() {
    return Container(
      color: const Color(0xFFFFFDE7), // 매우 연한 노란색 (종이 느낌)
      child: CustomPaint(
        painter: NotebookBackgroundPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentShapeName = _shapes[_level % _shapes.length].name;

    return Scaffold(
      body: Stack(
        children: [
          // 공책 배경
          _buildNotebookBackground(),
          
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final points = _getScaledPoints(size);
                
                bool isClosedShape = false;
                if (points.isNotEmpty) {
                  isClosedShape = (points.first - points.last).distance < 10;
                }

                return Stack(
                  children: [
                    // 회색 가이드 선
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TracingOutlinePainter(points: points),
                      ),
                    ),

                    // 유저가 그리는 선
                    Positioned.fill(
                      child: GestureDetector(
                        onPanStart: (d) => _onPanStart(d, size),
                        onPanUpdate: (d) => _onPanUpdate(d, size),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: TracingPathPainter(pathPoints: _userPath),
                        ),
                      ),
                    ),

                    // 시작점 표시 (양쪽 끝 모두 표시, 닫힌 도형이면 하나만)
                    if (!_isLevelClear && _targetPointIndex == 0 && points.isNotEmpty) ...[
                      // 첫번째 점
                      Positioned(
                        left: points.first.dx - 25,
                        top: points.first.dy - 25,
                        child: const IgnorePointer(
                          child: Icon(Icons.star, color: KidsTheme.orange, size: 50),
                        ),
                      ),
                      // 마지막 점 (닫힌 도형이 아닐 때만)
                      if (!isClosedShape)
                        Positioned(
                          left: points.last.dx - 25,
                          top: points.last.dy - 25,
                          child: const IgnorePointer(
                            child: Icon(Icons.star, color: KidsTheme.orange, size: 50),
                          ),
                        ),
                    ],

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
                                border: Border.all(color: KidsTheme.blue.withOpacity(0.4), width: 2),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                              ),
                              child: const Icon(Icons.close_rounded, color: KidsTheme.textDark, size: 24),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: KidsTheme.red, width: 2),
                            ),
                            child: Text(
                              '따라 쓰기: $currentShapeName 🖍️',
                              style: GoogleFonts.jua(fontSize: 24, color: KidsTheme.red),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: KidsTheme.orange.withOpacity(0.5), width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Text(
                              '⭐ $_score',
                              style: GoogleFonts.jua(fontSize: 20, color: KidsTheme.orange),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 클리어 시 문구
                    if (_isLevelClear)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          decoration: KidsTheme.toyDecoration(
                            color: KidsTheme.green,
                            borderRadius: 32,
                          ),
                          child: Text(
                            '참 잘했어요! 🌟',
                            style: GoogleFonts.jua(fontSize: 48, color: Colors.white),
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

class NotebookBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB3E5FC) // 연한 파란색 줄무늬
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 가로줄 긋기 (공책 느낌)
    double step = 40.0;
    for (double y = 80; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // 왼쪽 빨간 마진선
    final redPaint = Paint()
      ..color = const Color(0xFFFFCDD2) // 연한 빨간색
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(40, 0), Offset(40, size.height), redPaint);
    canvas.drawLine(Offset(44, 0), Offset(44, size.height), redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TracingOutlinePainter extends CustomPainter {
  final List<Offset> points;
  TracingOutlinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawPath(path, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TracingPathPainter extends CustomPainter {
  final List<Offset> pathPoints;
  TracingPathPainter({required this.pathPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (pathPoints.isEmpty) return;

    final paint = Paint()
      ..color = KidsTheme.pink
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
    for (int i = 1; i < pathPoints.length; i++) {
      path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
"""

with open("lib/games/tracing/tracing_game.dart", "w", encoding="utf-8") as f:
    f.write(code)
print("Updated tracing_game.dart")
