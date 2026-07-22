import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_toybox/lobby/lobby_screen.dart';

void main() {
  testWidgets('LobbyScreen displays title and game cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    // 1. Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: LobbyScreen(),
      ),
    );

    // 2. Verify initial state (title)
    expect(find.text('🎈 KIDS TOY BOX'), findsOneWidget);
    expect(find.text('안녕! 반가워 친구들! 😊'), findsOneWidget);

    // 3. Verify game cards exist
    expect(find.text('풍선 터뜨리기 🎈', skipOffstage: false), findsOneWidget);
    expect(find.text('모양 색칠하기 🎨', skipOffstage: false), findsOneWidget);
    
    // 4. Test sound toggle interaction
    final soundButtonFinder = find.byIcon(Icons.volume_up);
    expect(soundButtonFinder, findsOneWidget);

    await tester.tap(soundButtonFinder);
    await tester.pump(); // trigger frame
    await tester.pump(const Duration(milliseconds: 500)); // wait for modal animation
    
    // Parental Gate modal should appear
    expect(find.textContaining('부모님 확인'), findsOneWidget);
  });
}
