import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kids_toybox/main.dart';

void main() {
  // Disable runtime fetching of fonts in tests to avoid network calls
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Kids Toy Box lobby screen rendering smoke test', (WidgetTester tester) async {
    // Set a larger viewport size so both cards render on screen without scrolling
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const KidsToyBoxApp());
    // Since lobby_screen has an infinite repeat animation, do not use pumpAndSettle.
    // Instead, pump a single frame (or a short duration) to render the layout.
    await tester.pump(); 

    // Verify that our app main title is rendered
    expect(find.textContaining('KIDS TOY BOX'), findsOneWidget);
    expect(find.textContaining('키즈 미니 게임 천국'), findsOneWidget);

    // Verify that the game cards exist
    expect(find.textContaining('풍선 터뜨리기'), findsOneWidget);
    expect(find.textContaining('모양 색칠하기'), findsOneWidget);
  });
}
