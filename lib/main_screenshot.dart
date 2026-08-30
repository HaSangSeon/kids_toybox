import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/kids_theme.dart';
import 'lobby/lobby_screen.dart';
import 'games/car_wash/car_wash_game.dart';
import 'games/firefighter/firefighter_game.dart';
import 'games/feed_animals/feed_animals_game.dart';
import 'games/slide_puzzle/slide_puzzle_game.dart';
import 'games/hidden_object/hidden_object_game.dart';
import 'games/pet_hospital/pet_hospital_game.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const AutoScreenshotApp());
}

class AutoScreenshotApp extends StatefulWidget {
  const AutoScreenshotApp({super.key});

  @override
  State<AutoScreenshotApp> createState() => _AutoScreenshotAppState();
}

class _AutoScreenshotAppState extends State<AutoScreenshotApp> {
  int _currentIndex = 0;
  Timer? _timer;

  final List<String> screenNames = [
    'lobby',
    'car_wash',
    'firefighter',
    'feed_animals',
    'slide_puzzle',
    'hidden_object',
    'pet_hospital',
  ];

  final List<Widget> _screens = [
    const LobbyScreen(),
    const CarWashGame(),
    const FirefighterGame(),
    const FeedAnimalsGame(),
    const SlidePuzzleGame(),
    const HiddenObjectGame(),
    const PetHospitalGame(),
  ];

  @override
  void initState() {
    super.initState();
    // Advance screen every 6 seconds
    _timer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _screens.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: KidsTheme.lightTheme,
      home: Scaffold(
        body: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
    );
  }
}
