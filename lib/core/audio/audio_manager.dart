import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  
  factory AudioManager() {
    return instance;
  }

  AudioManager._internal();

  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _bgmEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get bgmEnabled => _bgmEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    if (!_soundEnabled) {
      _effectPlayer.stop();
      _voicePlayer.stop();
    }
  }

  void toggleBgm() {
    _bgmEnabled = !_bgmEnabled;
    if (_bgmEnabled) {
      // Resume or play BGM
    } else {
      _bgmPlayer.stop();
    }
  }

  /// Play a sound effect from asset path (e.g. 'audio/pop.mp3')
  Future<void> playEffect(String path, {double rate = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      // Release current source to play quickly in succession
      await _effectPlayer.stop();
      await _effectPlayer.setPlaybackRate(rate);
      await _effectPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Audio play failed: $path. Error: $e");
    }
  }

  /// Play a voice effect on the secondary player so it can overlap with sound effects
  Future<void> playVoice(String path) async {
    if (!_soundEnabled) return;
    try {
      await _voicePlayer.stop();
      await _voicePlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Voice play failed: $path. Error: $e");
    }
  }

  // Pre-configured sounds for convenience
  Future<void> playPop() => playEffect('audio/balloon_pop.wav', rate: 1.0);
  Future<void> playLightningPop() => playEffect('audio/balloon_pop.wav', rate: 1.35); // 1.35x speed/pitch for lightning pop!
  Future<void> playSuccess() => playEffect('audio/success.wav');
  Future<void> playClick() => playEffect('audio/click.wav');
  Future<void> playColorSelect() => playEffect('audio/click.wav');
  Future<void> playDamage() => playEffect('audio/damage.wav');
  Future<void> playGameOver() => playEffect('audio/game_over.wav');

  // Game-specific sounds
  Future<void> playJump() => playEffect('audio/jump.wav');
  Future<void> playEngine() => playEffect('audio/engine.wav');
  Future<void> playThud() => playEffect('audio/thud.wav');
  Future<void> playCrash() => playEffect('audio/crash.wav');
  Future<void> playSplash() => playEffect('audio/splash.wav');
  Future<void> playReel() => playEffect('audio/reel.wav');
  Future<void> playScribble() => playEffect('audio/scribble.wav');
  Future<void> playSnap() => playEffect('audio/snap.wav');
  Future<void> playSqueak() => playEffect('audio/squeak.wav');
  Future<void> playBrush() => playEffect('audio/brush_stroke.wav');
  Future<void> playMunch() => playEffect('audio/munch.wav');
  Future<void> playBoing() => playEffect('audio/boing.wav');
  Future<void> playChime() => playEffect('audio/chime.wav');
  Future<void> playCardFlip() => playEffect('audio/jigsaw_pickup.wav');
  Future<void> playCardMatch() => playEffect('audio/jigsaw_snap_correct.wav');
  Future<void> playCardMismatch() => playEffect('audio/boing.wav');
  Future<void> playLevelComplete() => playEffect('audio/jigsaw_success.wav');
  Future<void> playSwordSlice({double rate = 1.0}) => playEffect('audio/sword_slice.wav', rate: rate);

  // 낚시 전용 사운드
  Future<void> playFishPlunge() => playEffect('audio/fish_plunge.wav');   // 찌가 물속으로 첨벙!
  Future<void> playFishReel() => playEffect('audio/fish_reel.wav');        // 릴 감기 찰칵찰칵
  Future<void> playFishBite() => playEffect('audio/fish_bite.wav');        // 물고기 입질 뽀글
  Future<void> playFishCatch() => playEffect('audio/fish_catch.wav');      // 낚아올림 성공 물보라
  Future<void> playFishOhNo() => playEffect('audio/fish_ohno.wav');        // 상어/쓰레기 낚임 실망음


  // 점 잇기 전용 사운드
  Future<void> playDotStart() => playEffect('audio/dot_start.wav');
  Future<void> playDotConnect({double rate = 1.0}) => playEffect('audio/dot_connect.wav', rate: rate);
  Future<void> playDotSuccess() => playEffect('audio/dot_success.wav');

  // 따라 쓰기 전용 사운드
  Future<void> playTraceStart() => playEffect('audio/trace_start.wav');
  Future<void> playTraceDraw({double rate = 1.0}) => playEffect('audio/trace_draw.wav', rate: rate);
  Future<void> playTraceSuccess() => playEffect('audio/trace_success.wav');

  // 직소 퍼즐 전용 사운드
  Future<void> playJigsawPickup() => playEffect('audio/jigsaw_pickup.wav');
  Future<void> playJigsawSnapCorrect() => playEffect('audio/jigsaw_snap_correct.wav');
  Future<void> playJigsawSnapIncorrect() => playEffect('audio/jigsaw_snap_incorrect.wav');
  Future<void> playJigsawSuccess() => playEffect('audio/jigsaw_success.wav');

  // 데칼코마니 마법 전용 사운드
  Future<void> playMagicFold() async {
    if (!_soundEnabled) return;
    // 아기자기한 마법 접기 소리 (샤라랑~✨)
    playEffect('audio/chime.wav', rate: 1.2);
  }

  Future<void> playMagicUnfoldSuccess() async {
    if (!_soundEnabled) return;
    // 마법이 완성되어 짠! 하고 펼쳐지는 아기자기 뾰로롱 소리
    playEffect('audio/trace_success.wav', rate: 1.15);
    Future.delayed(const Duration(milliseconds: 150), () {
      playEffect('audio/chime.wav', rate: 1.5);
    });
  }

  // 각 조각의 이모지 매칭 사운드 재생
  Future<void> playEmojiSound(String emoji) {
    String filename;
    switch (emoji) {
      case '🐶': filename = 'jigsaw_sound_dog.wav'; break;
      case '🐱': filename = 'jigsaw_sound_cat.wav'; break;
      case '🐰': filename = 'jigsaw_sound_rabbit.wav'; break;
      case '🐻': filename = 'jigsaw_sound_bear.wav'; break;
      case '🐳': filename = 'jigsaw_sound_whale.wav'; break;
      case '🐙': filename = 'jigsaw_sound_octopus.wav'; break;
      case '🦀': filename = 'jigsaw_sound_crab.wav'; break;
      case '🐢': filename = 'jigsaw_sound_turtle.wav'; break;
      case '🍎': filename = 'jigsaw_sound_apple.wav'; break;
      case '🍌': filename = 'jigsaw_sound_banana.wav'; break;
      case '🍇': filename = 'jigsaw_sound_grape.wav'; break;
      case '🍓': filename = 'jigsaw_sound_strawberry.wav'; break;
      case '🚗': filename = 'jigsaw_sound_car.wav'; break;
      case '✈️': filename = 'jigsaw_sound_plane.wav'; break;
      case '🚢': filename = 'jigsaw_sound_ship.wav'; break;
      case '🚂': filename = 'jigsaw_sound_train.wav'; break;
      default: return Future.value();
    }
    return playVoice('audio/$filename');
  }

  // 두더지잡기 전용 사운드
  Future<void> playHammerWhack() => playEffect('audio/hammer_whack.wav');
  Future<void> playMissWoosh() => playEffect('audio/miss_woosh.wav');

  // 🟡 원조 팩맨(Pac-Man) 전용 클래식 8-Bit 사운드
  bool _pacmanWakaPitchHigh = false;
  Future<void> playPacmanWaka() async {
    if (!_soundEnabled) return;
    _pacmanWakaPitchHigh = !_pacmanWakaPitchHigh;
    final double pitchRate = _pacmanWakaPitchHigh ? 1.65 : 1.25;
    playEffect('audio/munch.wav', rate: pitchRate);
  }

  Future<void> playPacmanPowerPellet() async {
    if (!_soundEnabled) return;
    playEffect('audio/chime.wav', rate: 1.6);
  }

  Future<void> playPacmanEatGhost() async {
    if (!_soundEnabled) return;
    playEffect('audio/jigsaw_snap_correct.wav', rate: 1.5);
  }

  Future<void> playPacmanFruit() async {
    if (!_soundEnabled) return;
    playEffect('audio/trace_success.wav', rate: 1.4);
  }

  Future<void> playPacmanDeath() async {
    if (!_soundEnabled) return;
    // 팩맨 특유의 피치가 차례로 쪼르르 내려가는 8-bit 데스 연출
    playEffect('audio/damage.wav', rate: 1.2);
    Future.delayed(const Duration(milliseconds: 180), () {
      playEffect('audio/damage.wav', rate: 0.85);
    });
    Future.delayed(const Duration(milliseconds: 360), () {
      playEffect('audio/thud.wav', rate: 0.6);
    });
  }

  // Maze sounds
  Future<void> playMazeMove() => playEffect('audio/maze_move.wav');
  Future<void> playMazeBump() => playEffect('audio/maze_bump.wav');
  Future<void> playMazeClear() => playEffect('audio/maze_clear.wav');

  // 🏰 탑쌓기 전용 실감나는 건축 & 콤보 사운드
  Future<void> playTowerBlockDrop({double pitch = 1.0}) async {
    if (!_soundEnabled) return;
    playEffect('audio/snap.wav', rate: 0.95 * pitch);
    Future.delayed(const Duration(milliseconds: 40), () {
      playEffect('audio/thud.wav', rate: 1.2 * pitch);
    });
  }

  Future<void> playTowerPerfect({int combo = 1}) async {
    if (!_soundEnabled) return;
    final double pitch = (1.2 + (combo * 0.08)).clamp(1.2, 2.0);
    playEffect('audio/chime.wav', rate: pitch);
  }

  // Dispose players
  void dispose() {
    _effectPlayer.dispose();
    _voicePlayer.dispose();
    _bgmPlayer.dispose();
  }
}
