// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive/rive.dart';

void main() {
  test('inspect rive assets', () async {
    try {
      await RiveFile.initialize();
    } catch (_) {}
    for (final path in ['assets/rive/dog.riv', 'assets/rive/rewards.riv', 'assets/rive/rating.riv']) {
      print('=== File: $path ===');
      final bytes = await File(path).readAsBytes();
      final riveFile = RiveFile.import(ByteData.view(bytes.buffer));
      print('Main artboard: ${riveFile.mainArtboard.name}');
      for (final a in riveFile.artboards) {
        print(' Artboard: ${a.name}');
        for (final anim in a.animations) {
          print('  - anim: ${anim.name}');
        }
        for (final sm in a.stateMachines) {
          print('  - stateMachine: ${sm.name}');
          for (final input in sm.inputs) {
            print('    - input: ${input.name} (${input.runtimeType})');
          }
        }
      }
    }
  });
}
