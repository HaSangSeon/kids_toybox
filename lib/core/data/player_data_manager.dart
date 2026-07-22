import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PlayerDataManager {
  static final PlayerDataManager instance = PlayerDataManager._internal();
  
  PlayerDataManager._internal();

  late Box _playerDataBox;
  
  // Real-time notifier for UI to listen to
  final ValueNotifier<int> starCoinsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<List<String>> unlockedToysNotifier = ValueNotifier<List<String>>([]);
  final ValueNotifier<String> equippedToyNotifier = ValueNotifier<String>('🐱'); // Default cat

  Future<void> init() async {
    _playerDataBox = await Hive.openBox('player_data_box');
    
    // Load initial star coins
    final int initialCoins = _playerDataBox.get('starCoins', defaultValue: 0);
    starCoinsNotifier.value = initialCoins;

    // Load initial unlocked toys
    final List<dynamic> savedToys = _playerDataBox.get('unlockedToys', defaultValue: <String>[]);
    unlockedToysNotifier.value = savedToys.cast<String>();

    // Load initial equipped toy
    final String savedEquipped = _playerDataBox.get('equippedToy', defaultValue: '🐱');
    equippedToyNotifier.value = savedEquipped;
  }

  int get starCoins => starCoinsNotifier.value;
  List<String> get unlockedToys => unlockedToysNotifier.value;
  String get equippedToy => equippedToyNotifier.value;

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
}
