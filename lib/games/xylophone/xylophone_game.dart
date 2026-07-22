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

class _RecordedNote {
  final int millis;
  final String noteId;
  const _RecordedNote(this.millis, this.noteId);
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
  double life; // 0~1
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
//  메인 위젯
// ──────────────────────────────────────────────
class XylophoneGame extends StatefulWidget {
  const XylophoneGame({super.key});

  @override
  State<XylophoneGame> createState() => _XylophoneGameState();
}

class _XylophoneGameState extends State<XylophoneGame>
    with TickerProviderStateMixin {
  // ── 8개 건반 정의 ──
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

  // 동요 목록
  static const _songs = [
    _SongData(
      title: '반짝반짝 작은별',
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
        _SongNote('C4', 400), _SongNote('E4', 400), _SongNote('G4', 400),
        _SongNote('E4', 400), _SongNote('C4', 400),
        _SongNote('D4', 400), _SongNote('F4', 400), _SongNote('A4', 400),
        _SongNote('F4', 400), _SongNote('D4', 400),
        _SongNote('E4', 400), _SongNote('G4', 400), _SongNote('B4', 400),
        _SongNote('G4', 400), _SongNote('E4', 400),
        _SongNote('C4', 800),
      ],
    ),
    _SongData(
      title: '곰 세마리',
      emoji: '🐻',
      notes: [
        _SongNote('C4', 400), _SongNote('D4', 400), _SongNote('E4', 400), _SongNote('C4', 400),
        _SongNote('C4', 400), _SongNote('D4', 400), _SongNote('E4', 400), _SongNote('C4', 400),
        _SongNote('E4', 400), _SongNote('F4', 400), _SongNote('G4', 800),
        _SongNote('E4', 400), _SongNote('F4', 400), _SongNote('G4', 800),
      ],
    ),
    _SongData(
      title: '비행기',
      emoji: '✈️',
      notes: [
        _SongNote('G4', 400), _SongNote('E4', 400), _SongNote('E4', 400), _SongNote('E4', 600),
        _SongNote('G4', 400), _SongNote('E4', 400), _SongNote('E4', 400), _SongNote('E4', 600),
        _SongNote('A4', 400), _SongNote('A4', 400), _SongNote('G4', 400), _SongNote('G4', 600),
        _SongNote('E4', 400), _SongNote('E4', 400), _SongNote('D4', 400), _SongNote('C4', 800),
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

  bool _isRecording = false;
  bool _isPlayingBack = false;
  bool _isSongMode = false;
  bool _isSongPlaying = false;
  int _currentMode = 0; // 0=자유연주, 1=동요모드, 2=녹음모드
  final List<_RecordedNote> _recorded = [];
  int? _recordingStartMs;
  Timer? _playbackTimer;

  int _activeSongIndex = 0;
  int _songStep = 0; // 동요 가이드 현재 스텝
  List<int> _highlightedKeys = []; // 현재 눌러야 할 키 인덱스들

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

    // 반짝이 파티클 업데이트
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
    for (final c in _animControllers) c.dispose();
    for (final c in _glowControllers) c.dispose();
    for (final p in _players) p.dispose();
    _playbackTimer?.cancel();
    _sparkleTimer.cancel();
    _noteNameTimer?.cancel();
    super.dispose();
  }

  // ── 반짝이 파티클 생성 ──
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
  Future<void> _playNote(int index, {bool record = true, bool fromSong = false}) async {
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

    if (record && _isRecording) {
      final now = DateTime.now().millisecondsSinceEpoch;
      _recordingStartMs ??= now;
      setState(() {
        _recorded.add(_RecordedNote(now - _recordingStartMs!, _notes[index].id));
      });
    }

    // 동요 모드: 다음 스텝으로
    if (fromSong) {
      setState(() => _highlightedKeys = []);
      return;
    }

    // 동요 가이드 모드에서 건반 눌렀을 때 체크
    if (_isSongMode && _isSongPlaying && _highlightedKeys.contains(index)) {
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
      // 곡 완주!
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
    setState(() {
      _isSongPlaying = true;
      _songStep = 0;
      _highlightedKeys = [];
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showNextSongNote();
    });
  }

  void _finishSong() {
    setState(() {
      _isSongPlaying = false;
      _highlightedKeys = [];
    });
    AudioManager.instance.playSuccess();
    _showCompletionEffect();
  }

  void _showCompletionEffect() {
    // 다 쳤을 때 화면 전체 반짝이
    final size = MediaQuery.of(context).size;
    setState(() {
      for (int i = 0; i < 30; i++) {
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
      _isSongPlaying = false;
      _highlightedKeys = [];
      _songStep = 0;
    });
    _playbackTimer?.cancel();
  }

  // 동요 자동재생 (AI가 쳐줌)
  void _autoPlaySong() async {
    if (_isSongPlaying) return;
    final song = _songs[_activeSongIndex];
    setState(() { _isSongPlaying = true; _songStep = 0; });

    for (int i = 0; i < song.notes.length; i++) {
      if (!mounted || !_isSongPlaying) break;
      final noteIdx = _notes.indexWhere((n) => n.id == song.notes[i].noteId);
      if (noteIdx >= 0) {
        setState(() => _highlightedKeys = [noteIdx]);
        await _playNote(noteIdx, record: false, fromSong: true);
        await Future.delayed(Duration(milliseconds: song.notes[i].durationMs));
        if (mounted) setState(() => _highlightedKeys = []);
        await Future.delayed(const Duration(milliseconds: 60));
      }
    }
    if (mounted) {
      setState(() { _isSongPlaying = false; _highlightedKeys = []; });
      AudioManager.instance.playSuccess();
    }
  }

  // ── 녹음 ──
  void _toggleRecording() {
    if (_isPlayingBack) return;
    setState(() {
      if (_isRecording) {
        _isRecording = false;
        AudioManager.instance.playChime();
      } else {
        _isRecording = true;
        _recorded.clear();
        _recordingStartMs = null;
        AudioManager.instance.playClick();
      }
    });
  }

  void _playback() {
    if (_recorded.isEmpty || _isRecording || _isPlayingBack) return;
    setState(() => _isPlayingBack = true);
    int idx = 0;
    final notes = List<_RecordedNote>.from(_recorded);
    void scheduleNext() {
      if (idx >= notes.length) {
        if (mounted) setState(() => _isPlayingBack = false);
        return;
      }
      final delay = idx == 0 ? 0 : notes[idx].millis - notes[idx - 1].millis;
      _playbackTimer = Timer(Duration(milliseconds: delay), () {
        if (!mounted || !_isPlayingBack) return;
        final noteIdx = _notes.indexWhere((n) => n.id == notes[idx].noteId);
        if (noteIdx >= 0) _playNote(noteIdx, record: false);
        idx++;
        scheduleNext();
      });
    }
    scheduleNext();
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    if (mounted) setState(() => _isPlayingBack = false);
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
          // ── 배경 그라데이션 (파스텔 무지개) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB3C6), // 핑크
                  Color(0xFFFFD3A5), // 오렌지
                  Color(0xFFFFF6A5), // 노랑
                  Color(0xFFB8F0B8), // 연두
                  Color(0xFFB3DEFF), // 하늘
                  Color(0xFFD9B3FF), // 보라
                ],
                stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
            ),
          ),

          // ── 반투명 흰색 오버레이 ──
          Container(color: Colors.white.withValues(alpha: 0.20)),

          // ── 배경 떠다니는 이모지 ──
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

          // ── 메인 UI ──
          SafeArea(
            child: Column(
              children: [
                // 헤더
                _buildHeader(),

                const SizedBox(height: 6),

                // 모드 탭
                _buildModeTabs(),

                const SizedBox(height: 8),

                // 모드별 컨텐츠
                if (_currentMode == 0) _buildFreePlayHint(),
                if (_currentMode == 1) _buildSongModePanel(),
                if (_currentMode == 2) _buildRecordPanel(),

                // 연주 중인 음 이름 표시
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _lastNoteName.isEmpty
                      ? const SizedBox(height: 40)
                      : Container(
                          key: ValueKey(_lastNoteName),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Text(
                            '🎵 $_lastNoteName',
                            style: GoogleFonts.jua(
                              fontSize: 20,
                              color: KidsTheme.textDark,
                            ),
                          ),
                        ),
                ),

                const Spacer(),

                // 실로폰 건반
                _buildXylophone(size),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 헤더 ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // 뒤로가기 버튼
          _buildCircleBtn(
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            color: Colors.pink.shade300,
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
          ),

          const Expanded(child: SizedBox()),

          // 타이틀
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
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
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

          // 사운드 버튼
          _buildCircleBtn(
            child: Icon(
              AudioManager.instance.soundEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            color: Colors.purple.shade300,
            onTap: () {
              AudioManager.instance.toggleSound();
              setState(() {});
            },
          ),
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

  // ── 모드 탭 ──
  Widget _buildModeTabs() {
    final tabs = [
      {'icon': '🎸', 'label': '자유연주'},
      {'icon': '🎼', 'label': '동요연주'},
      {'icon': '🔴', 'label': '녹음하기'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
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
                  _stopPlayback();
                  _stopSong();
                  setState(() {
                    _currentMode = i;
                    if (_isRecording) {
                      _isRecording = false;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              [Colors.pink.shade400, Colors.deepOrange.shade300],
                              [Colors.blue.shade400, Colors.purple.shade300],
                              [Colors.red.shade400, Colors.pink.shade300],
                            ][i],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: [Colors.pink, Colors.blue, Colors.red][i]
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tabs[i]['icon']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 1),
                      Text(
                        tabs[i]['label']!,
                        style: GoogleFonts.jua(
                          fontSize: 12,
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

  // ── 자유 연주 힌트 ──
  Widget _buildFreePlayHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👆', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '건반을 눌러 소리를 내봐요!',
              style: GoogleFonts.jua(fontSize: 16, color: KidsTheme.textDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── 동요 모드 패널 ──
  Widget _buildSongModePanel() {
    final song = _songs[_activeSongIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            // 동요 선택 스크롤
            SizedBox(
              height: 48,
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
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            s.title,
                            style: GoogleFonts.jua(
                              fontSize: 13,
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
            const SizedBox(height: 10),

            // 연주 / 따라치기 버튼
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    emoji: '▶️',
                    label: _isSongPlaying ? '중지' : '들어보기',
                    gradient: [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
                    onTap: _isSongPlaying ? _stopSong : _autoPlaySong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionBtn(
                    emoji: '🎹',
                    label: _isSongPlaying ? '그만하기' : '따라치기',
                    gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                    onTap: () {
                      if (_isSongPlaying) {
                        _stopSong();
                      } else {
                        _startSong();
                      }
                    },
                  ),
                ),
              ],
            ),

            if (_isSongPlaying && _highlightedKeys.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '💡 반짝이는 건반을 눌러봐요! (${_songStep + 1}/${_songs[_activeSongIndex].notes.length})',
                  style: GoogleFonts.jua(fontSize: 13, color: Colors.deepPurple),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.4),
              blurRadius: 8,
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

  // ── 녹음 패널 ──
  Widget _buildRecordPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 녹음 버튼
            _buildCtrlBtn(
              emoji: _isRecording ? '⏹️' : '🔴',
              label: _isRecording ? '녹음중지' : '녹음시작',
              gradient: _isRecording
                  ? [Colors.red.shade400, Colors.red.shade700]
                  : [Colors.grey.shade400, Colors.grey.shade600],
              onTap: _toggleRecording,
              pulse: _isRecording,
            ),

            if (_recorded.isNotEmpty && !_isRecording) ...[
              const SizedBox(width: 10),
              _buildCtrlBtn(
                emoji: _isPlayingBack ? '⏹️' : '▶️',
                label: _isPlayingBack ? '중지' : '재생',
                gradient: _isPlayingBack
                    ? [Colors.orange.shade400, Colors.deepOrange]
                    : [Colors.green.shade400, Colors.teal],
                onTap: _isPlayingBack ? _stopPlayback : _playback,
              ),
              const SizedBox(width: 10),
              _buildCtrlBtn(
                emoji: '🗑️',
                label: '삭제',
                gradient: [Colors.blueGrey.shade300, Colors.blueGrey.shade500],
                onTap: () {
                  setState(() => _recorded.clear());
                  AudioManager.instance.playClick();
                },
              ),
            ],

            if (_recorded.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '🎵 ${_recorded.length}음',
                  style: GoogleFonts.jua(fontSize: 14, color: Colors.purple.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCtrlBtn({
    required String emoji,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool pulse = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: pulse ? 0.6 : 0.3),
              blurRadius: pulse ? 14 : 6,
              spreadRadius: pulse ? 2 : 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.jua(fontSize: 13, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── 실로폰 건반 ──
  Widget _buildXylophone(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // 상단 볼트 (실로폰 연결 바)
          Container(
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFDAA520), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 건반
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_notes.length, (i) {
              final note = _notes[i];
              final isHighlighted = _highlightedKeys.contains(i);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedBuilder(
                    animation: _glowControllers[i],
                    builder: (_, __) {
                      final glow = _glowControllers[i].value;
                      return ScaleTransition(
                        scale: _scaleAnims[i],
                        child: GestureDetector(
                          onTapDown: (details) {
                            _playNote(i);
                            // 반짝이 파티클 생성
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
                            height: note.barHeight.toDouble(),
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
                                top: Radius.circular(18),
                                bottom: Radius.circular(10),
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
                                  blurRadius: isHighlighted ? 20 : 8 + glow * 12,
                                  spreadRadius: isHighlighted ? 4 : glow * 3,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 3,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 반짝이 효과 (하이라이트 시)
                                if (isHighlighted)
                                  AnimatedOpacity(
                                    opacity: isHighlighted ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),

                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 상단 이모지
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        note.emoji,
                                        style: TextStyle(
                                          fontSize: note.barHeight > 200 ? 16 : 12,
                                        ),
                                      ),
                                    ),

                                    // 음 이름
                                    Column(
                                      children: [
                                        Text(
                                          note.label,
                                          style: GoogleFonts.jua(
                                            fontSize: note.barHeight > 200 ? 22 : 18,
                                            color: Colors.white,
                                            shadows: [
                                              const Shadow(
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
                                            fontSize: note.barHeight > 200 ? 11 : 9,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // 하단 볼트
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        width: 12,
                                        height: 12,
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
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // 하이라이트 깜빡이는 테두리
                                if (isHighlighted)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (_, v, __) => Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                          bottom: Radius.circular(8),
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

          const SizedBox(height: 4),

          // 하단 볼트 바
          Container(
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB8860B), Color(0xFFDAA520), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
