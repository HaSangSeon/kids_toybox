import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/kids_theme.dart';
import 'core/data/player_data_manager.dart';
import 'lobby/lobby_screen.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();
  await Hive.openBox('high_scores_box');
  await PlayerDataManager.instance.init();
  runApp(const KidsToyBoxApp());
}

class KidsToyBoxApp extends StatelessWidget {
  const KidsToyBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Toy Box',
      debugShowCheckedModeBanner: false,
      theme: KidsTheme.lightTheme,
      home: const LobbyScreen(),
    );
  }
}
