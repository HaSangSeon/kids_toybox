import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_toybox/core/theme/kids_theme.dart';
import 'package:kids_toybox/lobby/lobby_screen.dart';
import 'package:kids_toybox/games/car_wash/car_wash_game.dart';
import 'package:kids_toybox/games/firefighter/firefighter_game.dart';
import 'package:kids_toybox/games/feed_animals/feed_animals_game.dart';
import 'package:kids_toybox/games/slide_puzzle/slide_puzzle_game.dart';
import 'package:kids_toybox/games/hidden_object/hidden_object_game.dart';

import 'package:kids_toybox/games/pet_hospital/pet_hospital_game.dart';
import 'package:kids_toybox/games/car_builder/car_builder_game.dart';
import 'package:kids_toybox/games/balloon_pop/balloon_pop_game.dart';
import 'package:kids_toybox/games/color_mixing/color_mixing_game.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final screenMap = <String, Widget>{
    'lobby': const LobbyScreen(),
    'car_wash': const CarWashGame(),
    'firefighter': const FirefighterGame(),
    'feed_animals': const FeedAnimalsGame(),
    'slide_puzzle': const SlidePuzzleGame(),
    'hidden_object': const HiddenObjectGame(),
    'pet_hospital': const PetHospitalGame(),
    'car_builder': const CarBuilderGame(),
    'balloon_pop': const BalloonPopGame(),
    'color_mixing': const ColorMixingGame(),
  };

  for (final entry in screenMap.entries) {
    testWidgets('Capture ${entry.key}', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: KidsTheme.lightTheme,
          home: RepaintBoundary(
            key: boundaryKey,
            child: Scaffold(
              body: entry.value,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final pngBytes = byteData.buffer.asUint8List();
            final dir = Directory('build/captured_screens');
            if (!dir.existsSync()) {
              dir.createSync(recursive: true);
            }
            File('build/captured_screens/${entry.key}.png').writeAsBytesSync(pngBytes);
            print('Saved build/captured_screens/${entry.key}.png (${pngBytes.length} bytes)');
          }
        }
      });
    });
  }
}
