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
  final AudioPlayer _munchPlayer = AudioPlayer();
  final AudioPlayer _animalPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _bgmEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get bgmEnabled => _bgmEnabled;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    if (!_soundEnabled) {
      _effectPlayer.stop();
      _voicePlayer.stop();
      _munchPlayer.stop();
      _animalPlayer.stop();
      _successPlayer.stop();
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

  /// Play a completion/fanfare sound on dedicated player so drag sounds won't cut it off
  Future<void> playSuccessSound(String path, {double rate = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      await _successPlayer.stop();
      await _successPlayer.setPlaybackRate(rate);
      await _successPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Success audio play failed: $path. Error: $e");
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
  Future<void> playPaintDrop() => playEffect('audio/bubble_pop.wav'); // 귀여운 물방울 소리
  Future<void> playDamage() => playEffect('audio/damage.wav');
  Future<void> playGameOver() => playEffect('audio/game_over.wav');

  // Game-specific sounds
  Future<void> playJump() => playEffect('audio/jump.wav');
  Future<void> playEngine() => playEffect('audio/car_engine_drive.wav');
  Future<void> playThud() => playEffect('audio/thud.wav');
  Future<void> playCrash() => playEffect('audio/car_crash_metal.wav');
  Future<void> playSplash() => playEffect('audio/splash.wav');
  Future<void> playReel() => playEffect('audio/reel.wav');
  Future<void> playScribble() => playEffect('audio/scribble.wav');
  Future<void> playSnap() => playEffect('audio/snap.wav');
  Future<void> playSqueak() => playEffect('audio/squeak.wav');
  Future<void> playBrush() => playEffect('audio/brush_stroke.wav');
  Future<void> playMunch() => playEffect('audio/munch.wav');
  Future<void> playBoing() => playEffect('audio/boing.wav');
  Future<void> playChime() => playEffect('audio/chime.wav');

  // 🐛 지렁이 게임 전용 사운드
  /// 일반 먹이를 먹을 때: 귀엽고 촉촉한 냠냠 소리
  Future<void> playSnakeEat() => playEffect('audio/munch.wav', rate: 1.2);

  /// 스타 아이템을 먹을 때: 냠냠 + 반짝이는 chime 콤보
  Future<void> playSnakeEatStar() async {
    if (!_soundEnabled) return;
    playEffect('audio/munch.wav', rate: 1.4);
    Future.delayed(const Duration(milliseconds: 80), () {
      playEffect('audio/chime.wav', rate: 1.55);
    });
  }

  /// 방향 전환할 때: 아이들이 좋아하는 통통 튀는 삑~ 소리
  Future<void> playSnakeTurn() => playEffect('audio/squeak.wav', rate: 1.5);

  // 요리조리 자동차 아이템별 전용 사운드
  Future<void> playRacingItemStar() => playEffect('audio/item_star.wav');
  Future<void> playRacingItemDiamond() => playEffect('audio/item_diamond.wav');
  Future<void> playRacingItemHeart() => playEffect('audio/item_heart.wav');
  Future<void> playRacingItemShield() => playEffect('audio/item_shield.wav');
  Future<void> playRacingItemBanana() => playEffect('audio/item_banana.wav');
  Future<void> playCardFlip() => playEffect('audio/jigsaw_pickup.wav');
  Future<void> playCardMatch() => playEffect('audio/jigsaw_snap_correct.wav');
  Future<void> playCardMismatch() => playEffect('audio/boing.wav');
  Future<void> playLevelComplete() => playEffect('audio/jigsaw_success.wav');
  Future<void> playSwordSlice({double rate = 1.0}) => playEffect('audio/sword_slice.wav', rate: rate);

  // 동물 맘마 전용 신나고 아기자기한 클리어 팡파레
  Future<void> playFeedAnimalsSuccess() async {
    if (!_soundEnabled) return;
    await playEffect('audio/jigsaw_success.wav');
    Future.delayed(const Duration(milliseconds: 250), () {
      playEffect('audio/chime.wav', rate: 1.3);
    });
  }

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
  Future<void> playTraceSuccess() => playSuccessSound('audio/trace_success.wav');

  /// 브러시 도구별 전용 드로잉 사운드 (무지개, 별, 방울, 크레파스, 은하수)
  Future<void> playTraceBrush(String brushName, {double rate = 1.0}) {
    switch (brushName) {
      case 'sparkle':
        // 반짝이 별: 맑고 영롱한 별 사운드 ✨
        return playEffect('audio/item_star.wav', rate: (rate * 1.15).clamp(0.8, 2.0));
      case 'bubble':
        // 마법 방울: 퐁퐁 터지는 귀여운 방울 소리 🫧
        return playEffect('audio/bubble_pop.wav', rate: (rate * 1.1).clamp(0.8, 2.0));
      case 'crayon':
        // 크레파스: 사각사각 질감 넘치는 스케치 소리 🖍️
        return playEffect('audio/scribble.wav', rate: (rate * 1.05).clamp(0.8, 2.0));
      case 'comet':
        // 네온 은하수: 샤샤샥 빠르고 신비로운 은하수 소리 🔥
        return playEffect('audio/item_diamond.wav', rate: (rate * 1.2).clamp(0.8, 2.0));
      case 'rainbow':
      default:
        // 무지개: 뾰로롱 마법 음계 소리 🌈
        return playEffect('audio/trace_draw.wav', rate: rate.clamp(0.8, 2.0));
    }
  }

  // 직소 퍼즐 전용 사운드
  Future<void> playJigsawPickup() => playEffect('audio/jigsaw_pickup.wav');
  Future<void> playJigsawSnapCorrect() => playEffect('audio/jigsaw_snap_correct.wav');
  Future<void> playJigsawSnapIncorrect() => playEffect('audio/jigsaw_snap_incorrect.wav');
  Future<void> playJigsawSuccess() => playEffect('audio/jigsaw_success.wav');

  // 데칼코마니 마법 & 드로잉 전용 사운드
  /// 일반 물감 드로잉: 퐁! 퐁! 터지는 귀엽고 상쾌한 물방울 물감 사운드 🫧
  Future<void> playDecalPaintDraw({double rate = 1.15}) {
    return playEffect('audio/bubble_pop.wav', rate: rate.clamp(0.8, 2.0));
  }

  /// 무지개/글리터 드로잉: 맑고 영롱하게 반짝이는 별빛 마법 사운드 ✨
  Future<void> playDecalRainbowDraw({double rate = 1.25}) {
    return playEffect('audio/item_star.wav', rate: rate.clamp(0.8, 2.0));
  }

  /// 스탬프 콕 찍기: 통통 튀는 사랑스러운 뽁! 사운드 💖
  Future<void> playDecalStamp({double rate = 1.2}) {
    return playEffect('audio/item_heart.wav', rate: rate.clamp(0.8, 2.0));
  }

  /// 지우개 슥삭: 부드럽고 귀여운 삑삑 사운드 🧽
  Future<void> playDecalEraser({double rate = 1.3}) {
    return playEffect('audio/squeak.wav', rate: rate.clamp(0.8, 2.0));
  }

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

  // 요리사 놀이 전용 사운드
  Future<void> playCookDrop({String? ingredientKey}) async {
    if (!_soundEnabled) return;
    // 냄비에 재료를 쏙 넣을 때의 톡! 퐁당~ 보글보글 요리 사운드
    playEffect('audio/bubble_pop.wav', rate: 1.2);
    Future.delayed(const Duration(milliseconds: 60), () {
      playEffect('audio/bubble_boguel.wav', rate: 1.35);
    });
  }

  Future<void> playCookStir() async {
    if (!_soundEnabled) return;
    // 냄비 주걱으로 슥삭슥삭 저으며 보글보글 끓는 맛있는 소리
    playEffect('audio/bubble_boguel.wav', rate: 1.25);
    Future.delayed(const Duration(milliseconds: 40), () {
      playEffect('audio/trace_draw.wav', rate: 1.4);
    });
  }

  Future<void> playCookComplete() async {
    if (!_soundEnabled) return;
    // 요리 완성! 짠! 하고 화려하게 펼쳐지는 신나는 완성음
    playEffect('audio/success.wav', rate: 1.1);
    Future.delayed(const Duration(milliseconds: 180), () {
      playEffect('audio/chime.wav', rate: 1.2);
    });
  }

  // 🚗 세차장 게임 전용 차량별 10종 고유 사운드 🔊
  Future<void> playVehicleSound(String vehicleId) async {
    switch (vehicleId) {
      case 'police':
        await playEffect('audio/sound_police.wav');
        break;
      case 'fire':
        await playEffect('audio/sound_fire.wav');
        break;
      case 'ambulance':
        await playEffect('audio/sound_ambulance.wav');
        break;
      case 'bus':
        await playEffect('audio/sound_bus.wav');
        break;
      case 'racing':
        await playEffect('audio/sound_racing.wav');
        break;
      case 'monster':
        await playEffect('audio/sound_monster.wav');
        break;
      case 'taxi':
        await playEffect('audio/sound_taxi.wav');
        break;
      case 'tractor':
        await playEffect('audio/sound_tractor.wav');
        break;
      case 'suv':
        await playEffect('audio/sound_suv.wav');
        break;
      case 'car':
      default:
        await playEffect('audio/sound_car.wav');
        break;
    }
  }

  Future<void> playCarWashWaterSpray() => playEffect('audio/bubble_boguel.wav');
  Future<void> playCarWashSoapScrub() => playEffect('audio/bubble_pop.wav');
  Future<void> playCarWashRinse() => playEffect('audio/bubble_boguel.wav', rate: 1.25);
  Future<void> playCarWashDry() => playEffect('audio/squeak.wav');
  Future<void> playCarWashSticker() => playEffect('audio/snap.wav');

  Future<void> _playAnimalSound(String path, {double rate = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      await _animalPlayer.stop();
      await _animalPlayer.setPlaybackRate(rate);
      await _animalPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Animal sound play failed: $path. Error: $e");
    }
  }

  // 동물 맘마먹기 전용 실감나는 동물 울음소리 및 맘마 사운드
  Future<void> playAnimalFeedingSound(String animalName) async {
    if (!_soundEnabled) return;

    // 1. 오물오물 맘마먹는 냠냠 소리를 독립 플레이어로 선명하게 재생
    try {
      await _munchPlayer.stop();
      await _munchPlayer.play(AssetSource('audio/munch.wav'));
    } catch (_) {}

    // 2. 20종 동물 전용 음성 울음소리(animal_*.wav) 재생
    await _playAnimalSound('audio/animal_$animalName.wav');
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

  // Maze sounds (테마별 귀여운 동물/캐릭터 맞춤 사운드)
  Future<void> playMazeMove() => playEffect('audio/maze_move.wav');
  
  Future<void> playMazeThemeMove(int themeIdx, {String? emoji}) async {
    if (!_soundEnabled) return;

    // 이모지가 전달된 경우 이모지 우선 매칭, 없으면 themeIdx 매칭
    final char = emoji ?? '';
    
    if (char == '🐭' || char.contains('쥐')) {
      playEffect('audio/animal_mouse.wav', rate: 1.4);
    } else if (char == '🐠' || char == '🐟' || char.contains('물고기')) {
      playEffect('audio/bubble_boguel.wav', rate: 1.2);
    } else if (char == '🐝' || char.contains('벌')) {
      playEffect('audio/boing.wav', rate: 1.8);
    } else if (char == '🚀' || char.contains('로켓')) {
      playEffect('audio/miss_woosh.wav', rate: 1.5);
    } else if (char == '🦕' || char == '🦖' || char.contains('공룡')) {
      playEffect('audio/thud.wav', rate: 1.35);
    } else if (char == '🐧' || char.contains('펭귄')) {
      playEffect('audio/animal_penguin.wav', rate: 1.35);
    } else if (char == '🦄' || char.contains('유니콘')) {
      playEffect('audio/chime.wav', rate: 1.7);
    } else if (char == '🐶' || char.contains('강아지') || char.contains('개')) {
      playEffect('audio/animal_dog.wav', rate: 1.35);
    } else if (char == '🐱' || char.contains('고양이')) {
      playEffect('audio/animal_cat.wav', rate: 1.3);
    } else if (char == '🐰' || char.contains('토끼')) {
      playEffect('audio/animal_rabbit.wav', rate: 1.35);
    } else if (char == '🐸' || char.contains('개구리')) {
      playEffect('audio/animal_frog.wav', rate: 1.35);
    } else if (char == '🐥' || char == '🐤' || char.contains('병아리')) {
      playEffect('audio/animal_chick.wav', rate: 1.35);
    } else if (char == '🐘' || char.contains('코끼리')) {
      playEffect('audio/animal_elephant.wav', rate: 1.3);
    } else if (char == '🐷' || char.contains('돼지')) {
      playEffect('audio/animal_pig.wav', rate: 1.3);
    } else if (char == '🐻' || char.contains('곰')) {
      playEffect('audio/animal_bear.wav', rate: 1.35);
    } else if (char == '🐵' || char.contains('원숭이')) {
      playEffect('audio/animal_monkey.wav', rate: 1.35);
    } else {
      // themeIdx 기반 폴백 매칭
      switch (themeIdx % 14) {
        case 0: // 🐭 생쥐
          playEffect('audio/animal_mouse.wav', rate: 1.4);
          break;
        case 1: // 🐠 물고기
          playEffect('audio/bubble_boguel.wav', rate: 1.2);
          break;
        case 2: // 🐝 꿀벌
          playEffect('audio/boing.wav', rate: 1.8);
          break;
        case 3: // 🚀 로켓
          playEffect('audio/miss_woosh.wav', rate: 1.5);
          break;
        case 4: // 🦕 공룡
          playEffect('audio/thud.wav', rate: 1.35);
          break;
        case 5: // 🐧 펭귄
          playEffect('audio/animal_penguin.wav', rate: 1.35);
          break;
        case 6: // 🦄 유니콘
          playEffect('audio/chime.wav', rate: 1.7);
          break;
        case 7: // 🐶 강아지
          playEffect('audio/animal_dog.wav', rate: 1.35);
          break;
        case 8: // 🐱 고양이
          playEffect('audio/animal_cat.wav', rate: 1.3);
          break;
        case 9: // 🐰 토끼
          playEffect('audio/animal_rabbit.wav', rate: 1.35);
          break;
        case 10: // 🐸 개구리
          playEffect('audio/animal_frog.wav', rate: 1.35);
          break;
        case 11: // 🐥 병아리
          playEffect('audio/animal_chick.wav', rate: 1.35);
          break;
        case 12: // 🐘 코끼리
          playEffect('audio/animal_elephant.wav', rate: 1.3);
          break;
        case 13: // 🐷 아기돼지
          playEffect('audio/animal_pig.wav', rate: 1.3);
          break;
        default:
          playEffect('audio/maze_move.wav', rate: 1.2);
          break;
      }
    }
  }

  Future<void> playMazeBump() => playEffect('audio/maze_bump.wav');
  
  Future<void> playMazeClear({String? emoji, int? themeIdx}) async {
    if (!_soundEnabled) return;
    // 1. 미로 클리어 팡파레
    await playEffect('audio/maze_clear.wav');
    
    // 2. 잠시 후 동물의 신나는 축하 울음소리 재생
    Future.delayed(const Duration(milliseconds: 280), () {
      if (emoji != null) {
        playEmojiSound(emoji);
      } else if (themeIdx != null) {
        playMazeThemeMove(themeIdx);
      }
    });
  }

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
    _munchPlayer.dispose();
    _animalPlayer.dispose();
  }
}
