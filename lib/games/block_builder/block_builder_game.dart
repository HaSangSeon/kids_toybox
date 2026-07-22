import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

const double _kSnap = 46.0;

// ─────────────────────────────────────────────
// Model – 중심점(center) 기반 위치 시스템
// ─────────────────────────────────────────────
class _Piece {
  final int id;
  final double w, h;
  final Color color;
  final Color shade;
  final Offset rel;  // assemblyCenter 기준 CENTER 오프셋
  final double r;    // 모서리 반경
  final double rot;  // 시각적 회전 (라디안)

  bool snapped = false;
  Offset pos = Offset.zero; // 현재 CENTER 위치

  _Piece({
    required this.id,
    required this.w,
    required this.h,
    required this.color,
    required this.shade,
    required this.rel,
    this.r = 12.0,
    this.rot = 0.0,
  });

  _Piece fresh() => _Piece(
        id: id, w: w, h: h, color: color,
        shade: shade, rel: rel, r: r, rot: rot);

  Offset target(Offset center) => center + rel;
  bool nearTarget(Offset center) =>
      (pos - target(center)).distance < _kSnap;

  /// 타원형 히트 테스트 (손가락 판정)
  bool hits(Offset point) {
    final dx = pos.dx - point.dx;
    final dy = pos.dy - point.dy;
    final hw = w / 2 + 12;
    final hh = h / 2 + 12;
    return dx * dx / (hw * hw) + dy * dy / (hh * hh) <= 1.0;
  }
}

// ─────────────────────────────────────────────
// Level Definition
// ─────────────────────────────────────────────
class _Level {
  final String name, emoji;
  final Color bg1, bg2;
  final List<_Piece> pieces;
  _Level({
    required this.name,
    required this.emoji,
    required this.bg1,
    required this.bg2,
    required this.pieces,
  });
}

// ─────────────────────────────────────────────
// Shape Data (rel = CENTER offset from assemblyCenter)
// ─────────────────────────────────────────────
final _levels = <_Level>[
  // ── Level 1: 꽃게 (실제 꽃게처럼 9조각) ──────
  //
  //        [눈L][눈R]
  //    [팔L] [몸통] [팔R]
  //  [집게L]        [집게R]
  //   [다리L]    [다리R]
  //
  _Level(
    name: '꽃게', emoji: '🦀',
    bg1: const Color(0xFFFFF3E0), bg2: const Color(0xFFFFCDD2),
    pieces: [
      // 몸통 (넓은 타원형 – 가장 큰 조각)
      _Piece(id: 0, w: 132, h: 70, color: const Color(0xFFFF5722), shade: const Color(0xFFBF360C),
          rel: const Offset(0, 0), r: 35),
      // 왼쪽 팔 (몸통~집게 연결, 살짝 각도)
      _Piece(id: 1, w: 60, h: 24, color: const Color(0xFFFF7043), shade: const Color(0xFFBF360C),
          rel: const Offset(-93, -6), r: 8, rot: -0.18),
      // 오른쪽 팔
      _Piece(id: 2, w: 60, h: 24, color: const Color(0xFFFF7043), shade: const Color(0xFFBF360C),
          rel: const Offset(93, -6), r: 8, rot: 0.18),
      // 왼쪽 집게 (더 크고 진한 빨강)
      _Piece(id: 3, w: 66, h: 64, color: const Color(0xFFB71C1C), shade: const Color(0xFF7F0000),
          rel: const Offset(-148, -14), r: 20),
      // 오른쪽 집게
      _Piece(id: 4, w: 66, h: 64, color: const Color(0xFFB71C1C), shade: const Color(0xFF7F0000),
          rel: const Offset(148, -14), r: 20),
      // 왼쪽 눈 (짙은 파란 원)
      _Piece(id: 5, w: 24, h: 24, color: const Color(0xFF0D47A1), shade: const Color(0xFF000000),
          rel: const Offset(-22, -46), r: 12),
      // 오른쪽 눈
      _Piece(id: 6, w: 24, h: 24, color: const Color(0xFF0D47A1), shade: const Color(0xFF000000),
          rel: const Offset(22, -46), r: 12),
      // 왼쪽 다리 묶음 (가늘고 길게, 뒤로 뻗는 각도)
      _Piece(id: 7, w: 22, h: 90, color: const Color(0xFFFF8A65), shade: const Color(0xFFBF360C),
          rel: const Offset(-75, 58), r: 7, rot: -0.24),
      // 오른쪽 다리 묶음
      _Piece(id: 8, w: 22, h: 90, color: const Color(0xFFFF8A65), shade: const Color(0xFFBF360C),
          rel: const Offset(75, 58), r: 7, rot: 0.24),
    ],
  ),

  // ── Level 2: 강아지 ─────────────────────────
  _Level(
    name: '강아지', emoji: '🐶',
    bg1: const Color(0xFFFFF8E1), bg2: const Color(0xFFFBE9E7),
    pieces: [
      _Piece(id: 0, w: 108, h: 108, color: const Color(0xFFD7A87E), shade: const Color(0xFFA1622A),
          rel: const Offset(0, -46), r: 54), // 머리
      _Piece(id: 1, w: 118, h: 86, color: const Color(0xFFC49A6C), shade: const Color(0xFFA1622A),
          rel: const Offset(0, 60), r: 14), // 몸통
      _Piece(id: 2, w: 40, h: 60, color: const Color(0xFFA1622A), shade: const Color(0xFF6D3B1A),
          rel: const Offset(-58, -86), r: 16, rot: 0.15), // 왼쪽 귀
      _Piece(id: 3, w: 40, h: 60, color: const Color(0xFFA1622A), shade: const Color(0xFF6D3B1A),
          rel: const Offset(58, -86), r: 16, rot: -0.15), // 오른쪽 귀
      _Piece(id: 4, w: 30, h: 68, color: const Color(0xFFD7A87E), shade: const Color(0xFFA1622A),
          rel: const Offset(78, 44), r: 18, rot: 0.45), // 꼬리
      _Piece(id: 5, w: 54, h: 34, color: const Color(0xFFD4A574), shade: const Color(0xFFA1622A),
          rel: const Offset(0, -18), r: 14), // 주둥이
    ],
  ),

  // ── Level 3: 우주 로켓 ──────────────────────
  _Level(
    name: '우주 로켓', emoji: '🚀',
    bg1: const Color(0xFFE3F2FD), bg2: const Color(0xFFBBDEFB),
    pieces: [
      _Piece(id: 0, w: 70, h: 92, color: const Color(0xFF7986CB), shade: const Color(0xFF3F51B5),
          rel: const Offset(0, -132), r: 35), // 머리
      _Piece(id: 1, w: 90, h: 114, color: const Color(0xFF90CAF9), shade: const Color(0xFF1565C0),
          rel: const Offset(0, -16), r: 10), // 몸통
      _Piece(id: 2, w: 44, h: 62, color: const Color(0xFF3F51B5), shade: const Color(0xFF283593),
          rel: const Offset(-67, 36), r: 8, rot: -0.28), // 왼쪽 날개
      _Piece(id: 3, w: 44, h: 62, color: const Color(0xFF3F51B5), shade: const Color(0xFF283593),
          rel: const Offset(67, 36), r: 8, rot: 0.28), // 오른쪽 날개
      _Piece(id: 4, w: 68, h: 54, color: const Color(0xFFFF7043), shade: const Color(0xFFE64A19),
          rel: const Offset(0, 98), r: 20), // 불꽃
    ],
  ),

  // ── Level 4: 나비 ───────────────────────────
  _Level(
    name: '나비', emoji: '🦋',
    bg1: const Color(0xFFF3E5F5), bg2: const Color(0xFFE1BEE7),
    pieces: [
      _Piece(id: 0, w: 26, h: 108, color: const Color(0xFF6A1B9A), shade: const Color(0xFF4A148C),
          rel: const Offset(0, 0), r: 13), // 몸통
      _Piece(id: 1, w: 94, h: 80, color: const Color(0xFFCE93D8), shade: const Color(0xFF8E24AA),
          rel: const Offset(-60, -36), r: 24, rot: 0.13), // 왼쪽 위 날개
      _Piece(id: 2, w: 94, h: 80, color: const Color(0xFFCE93D8), shade: const Color(0xFF8E24AA),
          rel: const Offset(60, -36), r: 24, rot: -0.13), // 오른쪽 위 날개
      _Piece(id: 3, w: 70, h: 58, color: const Color(0xFFBA68C8), shade: const Color(0xFF7B1FA2),
          rel: const Offset(-46, 44), r: 18, rot: 0.22), // 왼쪽 아래 날개
      _Piece(id: 4, w: 70, h: 58, color: const Color(0xFFBA68C8), shade: const Color(0xFF7B1FA2),
          rel: const Offset(46, 44), r: 18, rot: -0.22), // 오른쪽 아래 날개
    ],
  ),

  // ── Level 5: 공룡 (티라노사우루스) 🦖 ────────
  //
  //         [머리]
  //      [목]
  //   [몸통 큰것]
  //   [앞발L] [앞발R]
  //  [뒷다리L][뒷다리R]
  //      [꼬리 긴것]
  //
  _Level(
    name: '공룡', emoji: '🦖',
    bg1: const Color(0xFFE8F5E9), bg2: const Color(0xFFC8E6C9),
    pieces: [
      // 몸통
      _Piece(id: 0, w: 120, h: 80, color: const Color(0xFF66BB6A), shade: const Color(0xFF2E7D32),
          rel: const Offset(0, 10), r: 20),
      // 머리 (약간 위쪽 오른쪽)
      _Piece(id: 1, w: 80, h: 56, color: const Color(0xFF81C784), shade: const Color(0xFF388E3C),
          rel: const Offset(52, -70), r: 18, rot: 0.10),
      // 목
      _Piece(id: 2, w: 30, h: 50, color: const Color(0xFF66BB6A), shade: const Color(0xFF2E7D32),
          rel: const Offset(28, -32), r: 10, rot: 0.15),
      // 앞발 (짧은 팔)
      _Piece(id: 3, w: 28, h: 42, color: const Color(0xFF4CAF50), shade: const Color(0xFF1B5E20),
          rel: const Offset(-42, -14), r: 10, rot: 0.3),
      // 뒷 다리 왼쪽
      _Piece(id: 4, w: 32, h: 70, color: const Color(0xFF4CAF50), shade: const Color(0xFF1B5E20),
          rel: const Offset(-38, 72), r: 12),
      // 뒷 다리 오른쪽
      _Piece(id: 5, w: 32, h: 70, color: const Color(0xFF4CAF50), shade: const Color(0xFF1B5E20),
          rel: const Offset(10, 72), r: 12),
      // 꼬리 (길고 뾰족하게)
      _Piece(id: 6, w: 90, h: 26, color: const Color(0xFF81C784), shade: const Color(0xFF388E3C),
          rel: const Offset(-96, 26), r: 10, rot: 0.20),
      // 눈
      _Piece(id: 7, w: 18, h: 18, color: const Color(0xFF1A237E), shade: const Color(0xFF000051),
          rel: const Offset(68, -78), r: 9),
    ],
  ),

  // ── Level 6: 집 🏠 ───────────────────────────
  //
  //       [지붕 삼각]
  //   [굴뚝]
  //   [벽 왼쪽][벽 오른쪽]
  //   [문][창문L][창문R]
  //
  _Level(
    name: '집', emoji: '🏠',
    bg1: const Color(0xFFFFF8E1), bg2: const Color(0xFFFFF3E0),
    pieces: [
      // 지붕 (넓고 납작한 삼각형 모양)
      _Piece(id: 0, w: 170, h: 62, color: const Color(0xFFEF5350), shade: const Color(0xFFB71C1C),
          rel: const Offset(0, -84), r: 10),
      // 벽 (넓은 직사각형)
      _Piece(id: 1, w: 160, h: 90, color: const Color(0xFFFFF9C4), shade: const Color(0xFFF9A825),
          rel: const Offset(0, 16), r: 6),
      // 문
      _Piece(id: 2, w: 36, h: 52, color: const Color(0xFF8D6E63), shade: const Color(0xFF4E342E),
          rel: const Offset(0, 34), r: 10),
      // 왼쪽 창문
      _Piece(id: 3, w: 34, h: 34, color: const Color(0xFF81D4FA), shade: const Color(0xFF0288D1),
          rel: const Offset(-52, 6), r: 6),
      // 오른쪽 창문
      _Piece(id: 4, w: 34, h: 34, color: const Color(0xFF81D4FA), shade: const Color(0xFF0288D1),
          rel: const Offset(52, 6), r: 6),
      // 굴뚝
      _Piece(id: 5, w: 26, h: 44, color: const Color(0xFF78909C), shade: const Color(0xFF37474F),
          rel: const Offset(-56, -110), r: 6),
    ],
  ),

  // ── Level 7: 물고기 🐠 ───────────────────────
  _Level(
    name: '물고기', emoji: '🐠',
    bg1: const Color(0xFFE3F2FD), bg2: const Color(0xFFB3E5FC),
    pieces: [
      // 몸통
      _Piece(id: 0, w: 130, h: 80, color: const Color(0xFFFF8F00), shade: const Color(0xFFE65100),
          rel: const Offset(0, 0), r: 40),
      // 꼬리지느러미
      _Piece(id: 1, w: 60, h: 70, color: const Color(0xFFFFB300), shade: const Color(0xFFFF6F00),
          rel: const Offset(-100, 0), r: 8, rot: 0.3),
      // 등지느러미
      _Piece(id: 2, w: 50, h: 32, color: const Color(0xFFFF6F00), shade: const Color(0xFFBF360C),
          rel: const Offset(10, -54), r: 8, rot: -0.15),
      // 배지느러미
      _Piece(id: 3, w: 40, h: 24, color: const Color(0xFFFF6F00), shade: const Color(0xFFBF360C),
          rel: const Offset(10, 50), r: 8, rot: 0.15),
      // 눈
      _Piece(id: 4, w: 22, h: 22, color: const Color(0xFF1A237E), shade: const Color(0xFF000051),
          rel: const Offset(46, -12), r: 11),
      // 입술
      _Piece(id: 5, w: 16, h: 10, color: const Color(0xFFBF360C), shade: const Color(0xFF7F0000),
          rel: const Offset(68, 4), r: 5),
    ],
  ),

  // ── Level 8: 기차 🚂 ─────────────────────────
  //
  //  [굴뚝] [지붕]
  //  [앞칸 큰] [뒷칸]
  //  [바퀴L][바퀴M][바퀴R]
  //
  _Level(
    name: '기차', emoji: '🚂',
    bg1: const Color(0xFFFCE4EC), bg2: const Color(0xFFF8BBD9),
    pieces: [
      // 앞 칸 (기관차 본체)
      _Piece(id: 0, w: 100, h: 72, color: const Color(0xFFE53935), shade: const Color(0xFFB71C1C),
          rel: const Offset(-48, -10), r: 12),
      // 뒤 칸 (객차)
      _Piece(id: 1, w: 88, h: 60, color: const Color(0xFFEF9A9A), shade: const Color(0xFFE57373),
          rel: const Offset(68, -4), r: 10),
      // 지붕
      _Piece(id: 2, w: 96, h: 22, color: const Color(0xFF424242), shade: const Color(0xFF212121),
          rel: const Offset(-50, -50), r: 8),
      // 굴뚝
      _Piece(id: 3, w: 20, h: 36, color: const Color(0xFF424242), shade: const Color(0xFF212121),
          rel: const Offset(-86, -72), r: 6),
      // 왼쪽 큰 바퀴
      _Piece(id: 4, w: 44, h: 44, color: const Color(0xFF37474F), shade: const Color(0xFF102027),
          rel: const Offset(-74, 44), r: 22),
      // 가운데 바퀴
      _Piece(id: 5, w: 36, h: 36, color: const Color(0xFF37474F), shade: const Color(0xFF102027),
          rel: const Offset(-18, 48), r: 18),
      // 오른쪽 바퀴
      _Piece(id: 6, w: 36, h: 36, color: const Color(0xFF37474F), shade: const Color(0xFF102027),
          rel: const Offset(70, 48), r: 18),
      // 연결 고리
      _Piece(id: 7, w: 28, h: 12, color: const Color(0xFF78909C), shade: const Color(0xFF37474F),
          rel: const Offset(20, 20), r: 6),
      // 창문
      _Piece(id: 8, w: 26, h: 22, color: const Color(0xFF81D4FA), shade: const Color(0xFF0288D1),
          rel: const Offset(66, -18), r: 6),
    ],
  ),

  // ── Level 9: 눈사람 ⛄ ───────────────────────
  _Level(
    name: '눈사람', emoji: '⛄',
    bg1: const Color(0xFFE0F7FA), bg2: const Color(0xFFB3E5FC),
    pieces: [
      // 몸통 (큰 원)
      _Piece(id: 0, w: 120, h: 120, color: const Color(0xFFECEFF1), shade: const Color(0xFF90A4AE),
          rel: const Offset(0, 52), r: 60),
      // 머리 (작은 원)
      _Piece(id: 1, w: 84, h: 84, color: const Color(0xFFF5F5F5), shade: const Color(0xFF9E9E9E),
          rel: const Offset(0, -56), r: 42),
      // 모자
      _Piece(id: 2, w: 72, h: 30, color: const Color(0xFF212121), shade: const Color(0xFF000000),
          rel: const Offset(0, -108), r: 6),
      // 모자 테두리
      _Piece(id: 3, w: 90, h: 14, color: const Color(0xFF212121), shade: const Color(0xFF000000),
          rel: const Offset(0, -90), r: 7),
      // 왼쪽 눈
      _Piece(id: 4, w: 16, h: 16, color: const Color(0xFF1A237E), shade: const Color(0xFF000051),
          rel: const Offset(-18, -62), r: 8),
      // 오른쪽 눈
      _Piece(id: 5, w: 16, h: 16, color: const Color(0xFF1A237E), shade: const Color(0xFF000051),
          rel: const Offset(18, -62), r: 8),
      // 당근 코
      _Piece(id: 6, w: 10, h: 24, color: const Color(0xFFFF6F00), shade: const Color(0xFFBF360C),
          rel: const Offset(0, -44), r: 5, rot: 0.2),
      // 왼쪽 팔 (나뭇가지)
      _Piece(id: 7, w: 70, h: 14, color: const Color(0xFF795548), shade: const Color(0xFF3E2723),
          rel: const Offset(-88, 32), r: 5, rot: -0.35),
      // 오른쪽 팔
      _Piece(id: 8, w: 70, h: 14, color: const Color(0xFF795548), shade: const Color(0xFF3E2723),
          rel: const Offset(88, 32), r: 5, rot: 0.35),
    ],
  ),

  // ── Level 10: 하트 왕관 👑 ──────────────────
  //
  //   [왼 뾰족][가운데 뾰족][오른 뾰족]
  //       [왕관 띠 큰것]
  //  [보석L]  [보석M]  [보석R]
  //
  _Level(
    name: '왕관', emoji: '👑',
    bg1: const Color(0xFFFFF8E1), bg2: const Color(0xFFFFECB3),
    pieces: [
      // 왕관 본체 띠
      _Piece(id: 0, w: 180, h: 46, color: const Color(0xFFFFD700), shade: const Color(0xFFF9A825),
          rel: const Offset(0, 24), r: 8),
      // 왼쪽 뾰족
      _Piece(id: 1, w: 30, h: 80, color: const Color(0xFFFFD700), shade: const Color(0xFFF9A825),
          rel: const Offset(-72, -42), r: 8, rot: -0.12),
      // 가운데 뾰족 (가장 높이)
      _Piece(id: 2, w: 34, h: 96, color: const Color(0xFFFFD700), shade: const Color(0xFFF9A825),
          rel: const Offset(0, -52), r: 8),
      // 오른쪽 뾰족
      _Piece(id: 3, w: 30, h: 80, color: const Color(0xFFFFD700), shade: const Color(0xFFF9A825),
          rel: const Offset(72, -42), r: 8, rot: 0.12),
      // 왼쪽 보석 (루비)
      _Piece(id: 4, w: 26, h: 26, color: const Color(0xFFE53935), shade: const Color(0xFFB71C1C),
          rel: const Offset(-60, 26), r: 8),
      // 가운데 보석 (사파이어)
      _Piece(id: 5, w: 30, h: 30, color: const Color(0xFF1565C0), shade: const Color(0xFF0D47A1),
          rel: const Offset(0, 24), r: 10),
      // 오른쪽 보석 (에메랄드)
      _Piece(id: 6, w: 26, h: 26, color: const Color(0xFF2E7D32), shade: const Color(0xFF1B5E20),
          rel: const Offset(60, 26), r: 8),
    ],
  ),
];

// ─────────────────────────────────────────────
// Game Widget
// ─────────────────────────────────────────────
class BlockBuilderGame extends StatefulWidget {
  const BlockBuilderGame({super.key});
  @override
  State<BlockBuilderGame> createState() => _BlockBuilderGameState();
}

class _BlockBuilderGameState extends State<BlockBuilderGame>
    with TickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _fallAnim;
  late AnimationController _bgAnim;

  int _levelIdx = 0;
  List<_Piece> _pieces = [];
  int? _draggingId;
  bool _isCelebrating = false;

  double _safeW = 390;
  double _safeH = 780;
  Offset _center = const Offset(195, 290);
  bool _initialized = false;

  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _fallAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fallAnim.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fallAnim.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  // LayoutBuilder 에서 실제 안전 영역 크기를 받아 초기화
  void _initLayout(BoxConstraints c) {
    if (_initialized) return;
    _initialized = true;
    _safeW = c.maxWidth;
    _safeH = c.maxHeight;
    _center = Offset(_safeW / 2, _safeH * 0.37);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _loadLevel());
    });
  }

  void _loadLevel() {
    final tpl = _levels[_levelIdx % _levels.length];
    _pieces = tpl.pieces.map((p) => p.fresh()).toList();
    _isCelebrating = false;
    _draggingId = null;

    // 하단 영역에 조각 흩뿌리기 (격자 기반 + 약간의 무작위)
    final n = _pieces.length;
    final cols = n <= 5 ? n : (n + 1) ~/ 2;
    for (int i = 0; i < n; i++) {
      final p = _pieces[i];
      final col = i % cols;
      final row = i ~/ cols;
      final cellW = _safeW / cols;
      final cx = col * cellW + cellW / 2 + (_rnd.nextDouble() - 0.5) * cellW * 0.25;
      final cy = _safeH * 0.66 + row * 110 + _rnd.nextDouble() * 30;
      p.pos = Offset(
        cx.clamp(p.w / 2 + 8, _safeW - p.w / 2 - 8),
        cy.clamp(_safeH * 0.62, _safeH - p.h / 2 - 12),
      );
    }
    _fallAnim.forward(from: 0);
  }

  void _snap(_Piece p) {
    if (!p.nearTarget(_center)) return;
    setState(() {
      p.snapped = true;
      p.pos = p.target(_center);
    });
    HapticFeedback.mediumImpact();
    AudioManager.instance.playJigsawSnapCorrect();
    _checkWin();
  }

  void _checkWin() {
    if (!_pieces.every((p) => p.snapped)) return;
    setState(() => _isCelebrating = true);
    _confetti.play();
    AudioManager.instance.playJigsawSuccess();
    HapticFeedback.heavyImpact();
    final emoji = _levels[_levelIdx % _levels.length].emoji;
    Future.delayed(const Duration(milliseconds: 700),
        () => AudioManager.instance.playEmojiSound(emoji));
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() { _levelIdx++; _loadLevel(); });
    });
  }

  // ── 블럭 시각 렌더링 ─────────────────────────
  Widget _pieceVisual(_Piece p, {bool dragging = false, double scale = 1.0}) {
    return Container(
      width: p.w * scale,
      height: p.h * scale,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(p.color, Colors.white, 0.25)!,
            Color.lerp(p.color, p.shade, 0.60)!,
          ],
        ),
        borderRadius: BorderRadius.circular(p.r * scale),
        border: p.snapped
            ? Border.all(color: Colors.amber.shade400, width: 2.6 * scale)
            : Border.all(color: p.shade.withValues(alpha: 0.42), width: 1.8 * scale),
        boxShadow: dragging
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 22, offset: const Offset(0, 12))]
            : p.snapped
                ? [BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.55),
                    blurRadius: 12, spreadRadius: 2)]
                : [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 5, offset: const Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(p.r * scale),
        child: Stack(
          children: [
            // Jelly gloss top highlight
            Positioned(
              top: 2 * scale,
              left: 4 * scale,
              right: 4 * scale,
              height: p.h * scale * 0.45,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular((p.r - 2) * scale),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom rim light
            Positioned(
              bottom: 2 * scale,
              left: 8 * scale,
              right: 8 * scale,
              height: p.h * scale * 0.15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular((p.r - 2) * scale),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 우측 상단 미리보기 ───────────────────────
  Widget _buildPreview() {
    const scale = 0.26;
    const bw = 122.0;
    const bh = 122.0;
    const pc = Offset(bw / 2, bh / 2 + 8);
    final level = _levels[_levelIdx % _levels.length];

    return Container(
      width: bw, height: bh,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidsTheme.orange, width: 3),
        boxShadow: [BoxShadow(
            color: KidsTheme.orange.withValues(alpha: 0.3),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(top: 3, left: 0, right: 0,
          child: Text('완성 🎯',
            textAlign: TextAlign.center,
            style: GoogleFonts.jua(fontSize: 11, color: KidsTheme.orange))),
        ...level.pieces.map((p) {
          final pp = pc + p.rel * scale;
          return Positioned(
            left: pp.dx - p.w * scale / 2,
            top: pp.dy - p.h * scale / 2,
            child: Transform.rotate(
              angle: p.rot,
              child: _pieceVisual(p, scale: scale),
            ),
          );
        }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = _levels[_levelIdx % _levels.length];
    final placedCount = _pieces.where((p) => p.snapped).length;

    // 드래그 중인 조각을 Z 맨 위로 (시각적으로)
    final sorted = [..._pieces];
    if (_draggingId != null) {
      final idx = sorted.indexWhere((p) => p.id == _draggingId);
      if (idx != -1) { final x = sorted.removeAt(idx); sorted.add(x); }
    }

    final double t = _fallAnim.isAnimating
        ? Curves.bounceOut.transform(_fallAnim.value)
        : 1.0;

    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (context, _) {
        final bg1 = Color.lerp(level.bg1, level.bg2, _bgAnim.value)!;
        final bg2 = Color.lerp(level.bg2, level.bg1, _bgAnim.value)!;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(builder: (ctx, constraints) {
                _initLayout(constraints);

                // ─── 단일 GestureDetector: 드래그 완전 제어 ───
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,

                  onPanStart: (d) {
                    if (_isCelebrating) return;
                    // 화면 앞쪽 조각부터 역순으로 히트 테스트
                    for (int i = sorted.length - 1; i >= 0; i--) {
                      final p = sorted[i];
                      if (p.snapped) continue;
                      // 낙하 중이면 실제 표시 위치로 판정
                      final dispY = _fallAnim.isAnimating
                          ? -280.0 + (p.pos.dy + 280.0) * t
                          : p.pos.dy;
                      final dispCenter = Offset(p.pos.dx, dispY);
                      final dx = d.localPosition.dx - dispCenter.dx;
                      final dy = d.localPosition.dy - dispCenter.dy;
                      final hw = p.w / 2 + 14;
                      final hh = p.h / 2 + 14;
                      if (dx * dx / (hw * hw) + dy * dy / (hh * hh) <= 1.0) {
                        setState(() {
                          _draggingId = p.id;
                          // 현재 표시 위치로 pos 동기화 (낙하 중 잡아도 튀지 않음)
                          p.pos = dispCenter;
                        });
                        HapticFeedback.selectionClick();
                        AudioManager.instance.playJigsawPickup();
                        break;
                      }
                    }
                  },

                  onPanUpdate: (d) {
                    if (_draggingId == null) return;
                    final p = _pieces.firstWhere((x) => x.id == _draggingId);
                    setState(() => p.pos += d.delta);
                  },

                  onPanEnd: (_) {
                    if (_draggingId == null) return;
                    final p = _pieces.firstWhere((x) => x.id == _draggingId);
                    final id = _draggingId;
                    setState(() => _draggingId = null);
                    if (_pieces.firstWhere((x) => x.id == id).id == p.id) {
                      _snap(p);
                    }
                  },

                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [

                      // ── 둥둥 떠다니는 귀여운 배경 ──
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BackgroundPainter(
                            animationValue: _bgAnim.value,
                            baseColor: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      ),

                      // ── 헤더 ──────────────────────────────
                      Positioned(
                        top: 10, left: 16, right: 150,
                        child: Row(children: [
                          GestureDetector(
                            onTap: () {
                              AudioManager.instance.playClick();
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: KidsTheme.toyDecoration(color: KidsTheme.red),
                              child: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: KidsTheme.toyDecoration(color: Colors.white),
                            child: Text(
                              '${level.emoji} ${level.name} 조립',
                              style: GoogleFonts.jua(fontSize: 20,
                                  color: KidsTheme.textDark, height: 1.1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                        ]),
                      ),

                      // ── 진행도 (별모양 아이콘 추가) ───────────────
                      Positioned(
                        top: 70, left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: KidsTheme.orange.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: KidsTheme.orange, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$placedCount / ${_pieces.length}',
                                style: GoogleFonts.jua(
                                    fontSize: 16, color: KidsTheme.orange),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── 미리보기 ──────────────────────────
                      Positioned(top: 10, right: 16,
                          child: _buildPreview()),

                      // ── 정답 위치 유령 실루엣 ────────────
                      ..._pieces.where((p) => !p.snapped).map((p) {
                        final tp = p.target(_center);
                        return Positioned(
                          left: tp.dx - p.w / 2,
                          top: tp.dy - p.h / 2,
                          child: Transform.rotate(
                            angle: p.rot,
                            child: Container(
                              width: p.w,
                              height: p.h,
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(p.r),
                                border: Border.all(
                                    color: p.color.withValues(alpha: 0.22),
                                    width: 2),
                              ),
                            ),
                          ),
                        );
                      }),

                      // ── 조각 렌더링 (인터랙션 없음 – GestureDetector가 루트에 있음) ──
                      ...sorted.map((p) {
                        final bool isDragging = _draggingId == p.id;
                        final double dispY = (p.snapped || isDragging)
                            ? p.pos.dy
                            : -280.0 + (p.pos.dy + 280.0) * t;
                        final dispPos = Offset(p.pos.dx, dispY);

                        return Positioned(
                          key: ValueKey('bb_${p.id}'),
                          left: dispPos.dx - p.w / 2,
                          top: dispPos.dy - p.h / 2,
                          child: Transform.rotate(
                            angle: p.rot,
                            child: Transform.scale(
                              scale: isDragging ? 1.12 : 1.0,
                              child: _pieceVisual(p, dragging: isDragging),
                            ),
                          ),
                        );
                      }),

                      // ── 컨페티 ────────────────────────────
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confetti,
                          blastDirectionality: BlastDirectionality.explosive,
                          emissionFrequency: 0.06,
                          numberOfParticles: 30,
                          gravity: 0.20,
                          colors: const [
                            Colors.red, Colors.blue, Colors.green,
                            Colors.yellow, Colors.purple, Colors.orange, Colors.pink,
                          ],
                        ),
                      ),

                      // ── 완성 배너 ─────────────────────────
                      if (_isCelebrating)
                        Center(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (ctx2, v, child2) => Transform.scale(
                              scale: v,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 24),
                                decoration: KidsTheme.toyDecoration(
                                    color: KidsTheme.green, borderRadius: 32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('완성! 🎉',
                                        style: GoogleFonts.jua(
                                            fontSize: 52, color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Text('다음 모양으로!',
                                        style: GoogleFonts.jua(
                                            fontSize: 20,
                                            color: Colors.white70,
                                            height: 1.1)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ── 귀여운 배경 패인터 (별, 구름, 동그라미) ──
class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  _BackgroundPainter({required this.animationValue, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    final strokePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // 일관된 무작위 배치를 위한 시드 고정
    final rnd = Random(42);
    
    // 여러 개의 떠다니는 도형 그리기
    for (int i = 0; i < 15; i++) {
      final isStroke = rnd.nextBool();
      final type = rnd.nextInt(3); // 0: circle, 1: star, 2: cloud
      final sizeScale = rnd.nextDouble() * 20 + 10; // 10 ~ 30
      
      // 애니메이션에 따른 y 이동 (위로 천천히 떠오름)
      final startX = rnd.nextDouble() * size.width;
      final startY = rnd.nextDouble() * size.height;
      final speed = rnd.nextDouble() * 100 + 50;
      
      final currentY = (startY - animationValue * speed * (i % 2 == 0 ? 1 : -1)) % size.height;
      final currentX = startX + sin(animationValue * pi * 2 + i) * 20;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(animationValue * pi * 2 * (i % 2 == 0 ? 0.2 : -0.2));
      
      final activePaint = isStroke ? strokePaint : paint;

      if (type == 0) {
        // 동그라미
        canvas.drawCircle(Offset.zero, sizeScale / 2, activePaint);
      } else if (type == 1) {
        // 별 (십자 반짝이 모양)
        final path = Path();
        final r = sizeScale / 2;
        path.moveTo(0, -r);
        path.quadraticBezierTo(0, 0, r, 0);
        path.quadraticBezierTo(0, 0, 0, r);
        path.quadraticBezierTo(0, 0, -r, 0);
        path.quadraticBezierTo(0, 0, 0, -r);
        canvas.drawPath(path, activePaint);
      } else {
        // 작은 구름
        final r = sizeScale / 3;
        canvas.drawCircle(Offset(-r*1.2, r*0.5), r*0.8, activePaint);
        canvas.drawCircle(Offset(r*1.2, r*0.5), r*0.8, activePaint);
        canvas.drawCircle(Offset(0, 0), r*1.2, activePaint);
        canvas.drawRect(Rect.fromLTRB(-r*1.2, r*0.5, r*1.2, r*1.3), activePaint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) {
    return old.animationValue != animationValue;
  }
}
