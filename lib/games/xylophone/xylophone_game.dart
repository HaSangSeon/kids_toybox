import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/kids_theme.dart';
import '../../core/audio/audio_manager.dart';

// ──────────────────────────────────────────────
//  데이터 모델
// ──────────────────────────────────────────────
class _NoteData {
  final String id;
  final String label;
  final String solfege; // 도,레,미...
  final Color color;
  final Color lightColor;
  final String audioFile;
  final double barHeight;
  final String emoji;

  const _NoteData({
    required this.id,
    required this.label,
    required this.solfege,
    required this.color,
    required this.lightColor,
    required this.audioFile,
    required this.barHeight,
    required this.emoji,
  });
}

// 동요 악보
class _SongNote {
  final String noteId;
  final int durationMs;
  const _SongNote(this.noteId, this.durationMs);
}

class _SongData {
  final String title;
  final String emoji;
  final List<_SongNote> notes;
  const _SongData({
    required this.title,
    required this.emoji,
    required this.notes,
  });
}

// 반짝이 파티클
class _Sparkle {
  double x, y;
  double vx, vy;
  double size;
  Color color;
  double life;
  _Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.life = 1.0,
  });
}

// ──────────────────────────────────────────────
//  메인 위젯 (유아/어린이 전용 간결한 무지개 실로폰)
// ──────────────────────────────────────────────
class XylophoneGame extends StatefulWidget {
  const XylophoneGame({super.key});

  @override
  State<XylophoneGame> createState() => _XylophoneGameState();
}

class _XylophoneGameState extends State<XylophoneGame>
    with TickerProviderStateMixin {
  // ── 8개 무지개 건반 정의 ──
  static const _notes = [
    _NoteData(
      id: 'C4', label: '도', solfege: 'Do',
      color: Color(0xFFFF5252), lightColor: Color(0xFFFF8A80),
      audioFile: 'audio/note_c4.wav', barHeight: 290, emoji: '🍎',
    ),
    _NoteData(
      id: 'D4', label: '레', solfege: 'Re',
      color: Color(0xFFFF6D00), lightColor: Color(0xFFFFAB40),
      audioFile: 'audio/note_d4.wav', barHeight: 262, emoji: '🍊',
    ),
    _NoteData(
      id: 'E4', label: '미', solfege: 'Mi',
      color: Color(0xFFFFD600), lightColor: Color(0xFFFFEA00),
      audioFile: 'audio/note_e4.wav', barHeight: 234, emoji: '🌟',
    ),
    _NoteData(
      id: 'F4', label: '파', solfege: 'Fa',
      color: Color(0xFF00C853), lightColor: Color(0xFF69F0AE),
      audioFile: 'audio/note_f4.wav', barHeight: 206, emoji: '🍀',
    ),
    _NoteData(
      id: 'G4', label: '솔', solfege: 'Sol',
      color: Color(0xFF0091EA), lightColor: Color(0xFF40C4FF),
      audioFile: 'audio/note_g4.wav', barHeight: 178, emoji: '💙',
    ),
    _NoteData(
      id: 'A4', label: '라', solfege: 'La',
      color: Color(0xFF3D5AFE), lightColor: Color(0xFF82B1FF),
      audioFile: 'audio/note_a4.wav', barHeight: 150, emoji: '🫐',
    ),
    _NoteData(
      id: 'B4', label: '시', solfege: 'Si',
      color: Color(0xFFAA00FF), lightColor: Color(0xFFEA80FC),
      audioFile: 'audio/note_b4.wav', barHeight: 122, emoji: '🍇',
    ),
    _NoteData(
      id: 'C5', label: '도', solfege: 'Do\'',
      color: Color(0xFFFF4081), lightColor: Color(0xFFFF80AB),
      audioFile: 'audio/note_c5.wav', barHeight: 94, emoji: '🌸',
    ),
  ];

  // 인기 동요 목록
  static const _songs = [
    _SongData(
      title: '작은별',
      emoji: '⭐',
      notes: [
        _SongNote('C4', 500), _SongNote('C4', 500),
        _SongNote('G4', 500), _SongNote('G4', 500),
        _SongNote('A4', 500), _SongNote('A4', 500),
        _SongNote('G4', 800),
        _SongNote('F4', 500), _SongNote('F4', 500),
        _SongNote('E4', 500), _SongNote('E4', 500),
        _SongNote('D4', 500), _SongNote('D4', 500),
        _SongNote('C4', 800),
      ],
    ),
    _SongData(
      title: '나비야',
      emoji: '🦋',
      notes: [
        _SongNote('G4', 400), _SongNote('E4', 400), _SongNote('E4', 600),
        _SongNote('F4', 400), _SongNote('D4', 400), _SongNote('D4', 600),
        _SongNote('C4', 400), _SongNote('D4', 400), _SongNote('E4', 400), _SongNote('F4', 400),
        _SongNote('G4', 400), _SongNote('G4', 400), _SongNote('G4', 600),
      ],
    ),
    _SongData(
      title: '곰 세마리',
      emoji: '🐻',
      notes: [
        _SongNote('C4', 400), _SongNote('C4', 400), _SongNote('C4', 400), _SongNote('C4', 400), _SongNote('C4', 600),
        _SongNote('E4', 400), _SongNote('G4', 400), _SongNote('G4', 400), _SongNote('E4', 400), _SongNote('C4', 600),
        _SongNote('G4', 400), _SongNote('G4', 400), _SongNote('E4', 400), _SongNote('C4', 400),
        _SongNote('D4', 400), _SongNote('D4', 400), _SongNote('C4', 800),
      ],
    ),
    _SongData(
      title: '비행기',
      emoji: '✈️',
      notes: [
        _SongNote('E4', 400), _SongNote('D4', 400), _SongNote('C4', 400), _SongNote('D4', 400),
        _SongNote('E4', 400), _SongNote('E4', 400), _SongNote('E4', 600),
        _SongNote('D4', 400), _SongNote('D4', 400), _SongNote('D4', 600),
        _SongNote('E4', 400), _SongNote('G4', 400), _SongNote('G4', 600),
      ],
    ),
  ];

  // ── 상태 ──
  late final List<AudioPlayer> _players;
  late final List<AnimationController> _animControllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<AnimationController> _glowControllers;
  late final AnimationController _bgController;
  late final AnimationController _titleController;

  bool _isSongPlaying = false;
  int _currentMode = 0; // 0=자유연주, 1=동요연주
  int _songModeState = 0; // 0=idle, 1=auto-listening, 2=guided-play

  int _activeSongIndex = 0;
  int _songStep = 0; // 동요 가이드 현재 스텝
  List<int> _highlightedKeys = []; // 현재 가이드 키 인덱스들

  final List<_Sparkle> _sparkles = [];
  late Timer _sparkleTimer;
  final Random _rand = Random();

  String _lastNoteName = '';
  Timer? _noteNameTimer;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _players = List.generate(_notes.length, (_) => AudioPlayer());
    _animControllers = List.generate(
      _notes.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
      ),
    );
    _scaleAnims = _animControllers
        .map((c) => Tween<double>(begin: 1.0, end: 0.85).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    _glowControllers = List.generate(
      _notes.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    for (final p in _players) {
      p.setVolume(1.0);
    }

    // 반짝이 파티클 타이머
    _sparkleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_sparkles.isEmpty) return;
      setState(() {
        for (final s in _sparkles) {
          s.x += s.vx;
          s.y += s.vy;
          s.vy += 0.3;
          s.life -= 0.06;
        }
        _sparkles.removeWhere((s) => s.life <= 0);
      });
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _titleController.dispose();
    for (final c in _animControllers) {
      c.dispose();
    }
    for (final c in _glowControllers) {
      c.dispose();
    }
    for (final p in _players) {
      p.dispose();
    }
    _sparkleTimer.cancel();
    _noteNameTimer?.cancel();
    super.dispose();
  }

  // ── 반짝이 생성 ──
  void _spawnSparkles(double x, double y, Color color) {
    for (int i = 0; i < 12; i++) {
      final angle = _rand.nextDouble() * pi * 2;
      final speed = _rand.nextDouble() * 6 + 2;
      _sparkles.add(_Sparkle(
        x: x, y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 3,
        size: _rand.nextDouble() * 8 + 4,
        color: color,
      ));
    }
  }

  // ── 건반 연주 ──
  Future<void> _playNote(int index, {bool fromSong = false}) async {
    if (!AudioManager.instance.soundEnabled) return;

    try {
      await _players[index].stop();
      await _players[index].play(AssetSource(_notes[index].audioFile));
    } catch (e) {
      debugPrint('Play error[$index]: $e');
    }

    HapticFeedback.lightImpact();
    _animControllers[index].forward().then((_) => _animControllers[index].reverse());
    _glowControllers[index].forward().then((_) => _glowControllers[index].reverse());

    setState(() {
      _lastNoteName = '${_notes[index].label} (${_notes[index].solfege})';
    });
    _noteNameTimer?.cancel();
    _noteNameTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _lastNoteName = '');
    });

    if (fromSong) {
      return;
    }

    // 동요 따라치기 모드에서 탭했을 때 다음 노트로 진행
    if (_currentMode == 1 && _songModeState == 2 && _highlightedKeys.contains(index)) {
      _onSongKeyTapped(index);
    }
  }

  void _onSongKeyTapped(int index) {
    final song = _songs[_activeSongIndex];
    setState(() {
      _highlightedKeys = [];
      _songStep++;
    });
    if (_songStep >= song.notes.length) {
      _finishSong();
    } else {
      _showNextSongNote();
    }
  }

  void _showNextSongNote() {
    final song = _songs[_activeSongIndex];
    if (_songStep >= song.notes.length) return;
    final noteId = song.notes[_songStep].noteId;
    final idx = _notes.indexWhere((n) => n.id == noteId);
    if (idx >= 0) {
      setState(() => _highlightedKeys = [idx]);
    }
  }

  void _startSong() {
    _stopSong();
    setState(() {
      _songModeState = 2;
      _isSongPlaying = true;
      _songStep = 0;
      _highlightedKeys = [];
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _songModeState == 2) _showNextSongNote();
    });
  }

  void _finishSong() {
    setState(() {
      _songModeState = 0;
      _isSongPlaying = false;
      _highlightedKeys = [];
    });
    _showCompletionEffect();
  }

  void _showCompletionEffect() {
    final size = MediaQuery.of(context).size;
    setState(() {
      for (int i = 0; i < 35; i++) {
        _sparkles.add(_Sparkle(
          x: _rand.nextDouble() * size.width,
          y: _rand.nextDouble() * size.height * 0.5,
          vx: (_rand.nextDouble() - 0.5) * 8,
          vy: _rand.nextDouble() * -5 - 2,
          size: _rand.nextDouble() * 10 + 5,
          color: [
            Colors.yellow, Colors.pink, Colors.cyan,
            Colors.orange, Colors.purple,
          ][_rand.nextInt(5)],
        ));
      }
    });
  }

  void _stopSong() {
    setState(() {
      _songModeState = 0;
      _isSongPlaying = false;
      _highlightedKeys = [];
      _songStep = 0;
    });
  }

  // 동요 자동으로 들어보기 (AI가 연주)
  void _autoPlaySong() async {
    _stopSong();
    final song = _songs[_activeSongIndex];
    setState(() {
      _songModeState = 1;
      _isSongPlaying = true;
      _songStep = 0;
    });

    for (int i = 0; i < song.notes.length; i++) {
      if (!mounted || _songModeState != 1) break;
      final noteIdx = _notes.indexWhere((n) => n.id == song.notes[i].noteId);
      if (noteIdx >= 0) {
        if (mounted) {
          setState(() {
            _highlightedKeys = [noteIdx];
            _songStep = i;
          });
        }
        await _playNote(noteIdx, fromSong: true);
        await Future.delayed(Duration(milliseconds: song.notes[i].durationMs));
      }
    }
    if (mounted && _songModeState == 1) {
      setState(() {
        _songModeState = 0;
        _isSongPlaying = false;
        _highlightedKeys = [];
      });
      _showCompletionEffect();
    }
  }

  // ── 배경 음표 ──
  static const _bgDecos = [
    {'emoji': '🎵', 'left': 0.04, 'top': 0.08, 'size': 34.0, 'speed': 1.0},
    {'emoji': '🎶', 'left': 0.55, 'top': 0.06, 'size': 48.0, 'speed': 0.65},
    {'emoji': '⭐', 'right': 0.05, 'top': 0.12, 'size': 36.0, 'speed': 1.2},
    {'emoji': '🌈', 'left': 0.01, 'top': 0.40, 'size': 40.0, 'speed': 0.85},
    {'emoji': '🎵', 'right': 0.04, 'top': 0.55, 'size': 30.0, 'speed': 1.1},
    {'emoji': '💫', 'left': 0.07, 'top': 0.68, 'size': 32.0, 'speed': 0.75},
    {'emoji': '♪', 'right': 0.06, 'top': 0.22, 'size': 28.0, 'speed': 0.95},
    {'emoji': '🌟', 'left': 0.45, 'top': 0.02, 'size': 26.0, 'speed': 1.3},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // ── 파스텔 무지개 배경 ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB3C6),
                  Color(0xFFFFD3A5),
                  Color(0xFFFFF6A5),
                  Color(0xFFB8F0B8),
                  Color(0xFFB3DEFF),
                  Color(0xFFD9B3FF),
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.20)),

          // ── 배경 음표 애니메이션 ──
          ..._bgDecos.map((n) {
            return AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final offset = (n['speed'] as double) * _bgController.value;
                final dy = 14 * sin(offset * pi * 2);
                final dx = 6 * cos(offset * pi * 2);
                return Positioned(
                  top: n.containsKey('top')
                      ? size.height * (n['top'] as double) + dy
                      : null,
                  left: n.containsKey('left')
                      ? size.width * (n['left'] as double) + dx
                      : null,
                  right: n.containsKey('right')
                      ? size.width * (n['right'] as double)
                      : null,
                  child: Opacity(
                    opacity: 0.55,
                    child: Text(
                      n['emoji'] as String,
                      style: TextStyle(
                        fontSize: n['size'] as double,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // ── 반짝이 파티클 ──
          ..._sparkles.map((s) => Positioned(
                left: s.x - s.size / 2,
                top: s.y - s.size / 2,
                child: Opacity(
                  opacity: s.life.clamp(0.0, 1.0),
                  child: Container(
                    width: s.size,
                    height: s.size,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: s.color.withValues(alpha: 0.6), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              )),

          // ── 메인 UI (어린이 맞춤 직관적 레이아웃) ──
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 2),
                _buildModeTabs(),
                const SizedBox(height: 4),

                if (_currentMode == 0) _buildFreePlayHint(),
                if (_currentMode == 1) _buildSongModePanel(),

                // 연주 중인 음 이름 표시 (위쪽 마진 여유 있게 추가)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _lastNoteName.isEmpty
                      ? const SizedBox(height: 38)
                      : Container(
                          key: ValueKey(_lastNoteName),
                          margin: const EdgeInsets.only(top: 14, bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '🎵 $_lastNoteName',
                            style: GoogleFonts.jua(
                              fontSize: 17,
                              color: KidsTheme.textDark,
                            ),
                          ),
                        ),
                ),

                // 실로폰 건반 (반응형 자동 확장)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildXylophone(size),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 상단 헤더 (음소거 버튼 제거 및 타이틀 정렬) ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _buildCircleBtn(
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            color: Colors.pink.shade300,
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
          ),
          const Expanded(child: SizedBox()),

          AnimatedBuilder(
            animation: _titleController,
            builder: (_, __) {
              final scale = 1.0 + _titleController.value * 0.04;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53), Color(0xFFFFD93D)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎹', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 6),
                      Text(
                        '무지개 실로폰',
                        style: GoogleFonts.jua(
                          fontSize: 22,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('🎵', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              );
            },
          ),

          const Expanded(child: SizedBox()),

          // 대칭을 맞추기 위한 빈 공간 (음소거 버튼 제거)
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Widget _buildCircleBtn({
    required Widget child,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  // ── 2단 간결 모드 탭 (자유연주 / 동요연주) ──
  Widget _buildModeTabs() {
    final tabs = [
      {'icon': '🎹', 'label': '자유 연주'},
      {'icon': '🎶', 'label': '동요 연주'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final selected = _currentMode == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentMode == i) return;
                  AudioManager.instance.playClick();
                  _stopSong();
                  setState(() {
                    _currentMode = i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: i == 0
                                ? [const Color(0xFFFF6B9D), const Color(0xFFFF8E53)]
                                : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: (i == 0 ? Colors.orange : Colors.indigo).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tabs[i]['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        tabs[i]['label']!,
                        style: GoogleFonts.jua(
                          fontSize: 15,
                          color: selected ? Colors.white : KidsTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── 자유 연주 안내 ──
  Widget _buildFreePlayHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '건반을 톡톡 눌러서 예쁜 멜로디를 만들어봐요!',
              style: GoogleFonts.jua(fontSize: 14, color: KidsTheme.textDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── 동요 연주 패널 (유아 맞춤 직관적 카드) ──
  Widget _buildSongModePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 동요 선택 가로 칩 카드
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _songs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _songs[i];
                  final sel = _activeSongIndex == i;
                  return GestureDetector(
                    onTap: () {
                      if (_isSongPlaying) _stopSong();
                      setState(() => _activeSongIndex = i);
                      AudioManager.instance.playClick();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              )
                            : null,
                        color: sel ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: sel
                            ? Border.all(color: Colors.yellowAccent, width: 2)
                            : Border.all(color: Colors.grey.shade300),
                        boxShadow: sel
                            ? [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 6)]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 17)),
                          const SizedBox(width: 6),
                          Text(
                            s.title,
                            style: GoogleFonts.jua(
                              fontSize: 14,
                              color: sel ? Colors.white : KidsTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 들어보기 vs 직접 쳐보기 2개의 직관적 액션 버튼
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    emoji: _songModeState == 1 ? '⏹️' : '▶️',
                    label: _songModeState == 1 ? '중지하기' : '들어보기',
                    gradient: _songModeState == 1
                        ? [const Color(0xFFFF5252), const Color(0xFFFF7961)]
                        : [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
                    onTap: _songModeState == 1 ? _stopSong : _autoPlaySong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionBtn(
                    emoji: _songModeState == 2 ? '⏹️' : '✨',
                    label: _songModeState == 2 ? '그만하기' : '직접 쳐보기',
                    gradient: _songModeState == 2
                        ? [const Color(0xFFFF5252), const Color(0xFFFF7961)]
                        : [const Color(0xFFFF758C), const Color(0xFFFF7EB3)],
                    onTap: _songModeState == 2 ? _stopSong : _startSong,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 고정 높이의 안정적인 상태 안내 문구 (깜빡임 완벽 차단)
            Container(
              height: 22,
              alignment: Alignment.center,
              child: Text(
                _songModeState == 1
                    ? '🎶 동요를 감상하는 중이에요...'
                    : (_songModeState == 2 && _highlightedKeys.isNotEmpty
                        ? '💡 반짝이는 건반을 톡톡! (${_songStep + 1}/${_songs[_activeSongIndex].notes.length})'
                        : '🎵 동요를 선택하고 들어보거나 연주해봐요!'),
                style: GoogleFonts.jua(
                  fontSize: 13,
                  color: _songModeState == 1
                      ? Colors.blue.shade700
                      : (_songModeState == 2 ? Colors.purple.shade700 : KidsTheme.textDark),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String emoji,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.jua(fontSize: 15, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── 실로폰 건반 (반응형 동적 높이) ──
  Widget _buildXylophone(Size size) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = (constraints.maxHeight - 36).clamp(100.0, 400.0);
        const maxBarH = 290.0;
        final scaleFactor = (availableH / maxBarH).clamp(0.40, 1.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 상단 볼트 바
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8860B), Color(0xFFDAA520), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.4),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // 건반 목록
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(_notes.length, (i) {
                  final note = _notes[i];
                  final isHighlighted = _highlightedKeys.contains(i);
                  final barH = note.barHeight * scaleFactor;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5),
                      child: AnimatedBuilder(
                        animation: _glowControllers[i],
                        builder: (_, __) {
                          final glow = _glowControllers[i].value;
                          return ScaleTransition(
                            scale: _scaleAnims[i],
                            child: GestureDetector(
                              onTapDown: (details) {
                                _playNote(i);
                                final box = context.findRenderObject() as RenderBox?;
                                if (box != null) {
                                  final pos = box.localToGlobal(Offset.zero);
                                  _spawnSparkles(
                                    details.globalPosition.dx - pos.dx,
                                    details.globalPosition.dy - pos.dy,
                                    note.color,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                height: barH,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isHighlighted
                                        ? [
                                            Colors.white,
                                            note.lightColor,
                                            note.color,
                                          ]
                                        : [
                                            note.lightColor,
                                            note.color,
                                            note.color.withValues(alpha: 0.8),
                                          ],
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                    bottom: Radius.circular(9),
                                  ),
                                  border: Border.all(
                                    color: isHighlighted
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.6),
                                    width: isHighlighted ? 3.5 : 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: note.color.withValues(
                                          alpha: isHighlighted ? 0.8 : 0.4 + glow * 0.4),
                                      blurRadius: isHighlighted ? 18 : 6 + glow * 10,
                                      spreadRadius: isHighlighted ? 3 : glow * 2,
                                      offset: const Offset(0, 3),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 3,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isHighlighted)
                                      AnimatedOpacity(
                                        opacity: isHighlighted ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),

                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            note.emoji,
                                            style: TextStyle(
                                              fontSize: barH > 160 ? 15 : 11,
                                            ),
                                          ),
                                        ),

                                        Column(
                                          children: [
                                            Text(
                                              note.label,
                                              style: GoogleFonts.jua(
                                                fontSize: barH > 160 ? 20 : 15,
                                                color: Colors.white,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black38,
                                                    offset: Offset(1, 1),
                                                    blurRadius: 3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              note.solfege,
                                              style: GoogleFonts.jua(
                                                fontSize: barH > 160 ? 10 : 8,
                                                color: Colors.white.withValues(alpha: 0.85),
                                              ),
                                            ),
                                          ],
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.9),
                                                  Colors.white.withValues(alpha: 0.3),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (isHighlighted)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(milliseconds: 500),
                                        builder: (_, v, __) => Container(
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(14),
                                              bottom: Radius.circular(7),
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: v),
                                              width: 3,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 3),

              // 하단 볼트 바
              Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB8860B), Color(0xFFDAA520), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withValues(alpha: 0.4),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
