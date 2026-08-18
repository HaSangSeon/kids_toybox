import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PlayerDataManager {
  static final PlayerDataManager instance = PlayerDataManager._internal();
  
  PlayerDataManager._internal();

  late Box _playerDataBox;
  
  // Real-time notifier for UI to listen to
  final ValueNotifier<int> starCoinsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<String>> unlockedToysNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> equippedToyNotifier = ValueNotifier<String>('🐱'); // Default cat
  final ValueNotifier<bool> isPremiumUnlockedNotifier = ValueNotifier<bool>(false);
  bool _isEmulator = false;

  bool get isEmulator => _isEmulator;

  Future<void> init() async {
    _playerDataBox = await Hive.openBox('player_data_box');
    
    // Check if running on an emulator/simulator
    // ⚠️ Release 빌드에서는 에뮬레이터 자동 해금을 완전히 비활성화:
    // 루팅/커스텀 ROM 기기에서 isPhysicalDevice가 false를 반환하는 경우를 방지.
    if (!kReleaseMode) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _isEmulator = !androidInfo.isPhysicalDevice;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _isEmulator = !iosInfo.isPhysicalDevice;
        }
      } catch (e) {
        debugPrint('Error checking device info: $e');
      }
    }

    // Load initial star coins
    final int initialCoins = _playerDataBox.get('starCoins', defaultValue: 0);
    starCoinsNotifier.value = initialCoins;

    // Load initial unlocked toys
    final List<dynamic> savedToys = _playerDataBox.get('unlockedToys', defaultValue: <String>[]);
    unlockedToysNotifier.value = savedToys.cast<String>();

    // Load initial equipped toy
    final String savedEquipped = _playerDataBox.get('equippedToy', defaultValue: '🐱');
    equippedToyNotifier.value = savedEquipped;

    // Load premium status (에뮬레이터 환경에서는 테스트 편의를 위해 항상 자동 잠금 해제)
    if (_isEmulator) {
      isPremiumUnlockedNotifier.value = true;
    } else {
      final bool savedPremium = _playerDataBox.get('isPremiumUnlocked', defaultValue: false);
      isPremiumUnlockedNotifier.value = savedPremium;
    }
  }

  int get starCoins => starCoinsNotifier.value;
  List<String> get unlockedToys => unlockedToysNotifier.value;
  String get equippedToy => equippedToyNotifier.value;
  bool get isPremiumUnlocked => _isEmulator || isPremiumUnlockedNotifier.value;

  void addStarCoin([int amount = 1]) {
    final int newAmount = starCoins + amount;
    starCoinsNotifier.value = newAmount;
    _playerDataBox.put('starCoins', newAmount);
  }

  void spendStarCoins(int amount) {
    if (starCoins >= amount) {
      final int newAmount = starCoins - amount;
      starCoinsNotifier.value = newAmount;
      _playerDataBox.put('starCoins', newAmount);
    }
  }

  void unlockToy(String toyEmoji) {
    if (!unlockedToys.contains(toyEmoji)) {
      final newList = List<String>.from(unlockedToys)..add(toyEmoji);
      unlockedToysNotifier.value = newList;
      _playerDataBox.put('unlockedToys', newList);
    }
  }

  void equipToy(String toyEmoji) {
    if (unlockedToys.contains(toyEmoji) || toyEmoji == '🐱') {
      equippedToyNotifier.value = toyEmoji;
      _playerDataBox.put('equippedToy', toyEmoji);
    }
  }

  void unlockPremium() {
    isPremiumUnlockedNotifier.value = true;
    _playerDataBox.put('isPremiumUnlocked', true);
  }

  bool togglePremium() {
    final bool nextState = !isPremiumUnlocked;
    isPremiumUnlockedNotifier.value = nextState;
    _playerDataBox.put('isPremiumUnlocked', nextState);
    return nextState;
  }
}
