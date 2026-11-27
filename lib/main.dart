import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/kids_theme.dart';
import 'core/data/player_data_manager.dart';
import 'lobby/splash_screen.dart';
import 'package:flutter/services.dart';



import 'dart:async';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('fonts.gstatic.com')) {
        return;
      }
      FlutterError.presentError(details);
    };
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await Hive.initFlutter();
    await Hive.openBox('high_scores_box');
    await PlayerDataManager.instance.init();
    runApp(const KidsToyBoxApp());
  }, (error, stack) {
    if (error.toString().contains('fonts.gstatic.com')) {
      return; // Silently swallow offline font fetching errors
    }
  });
}

class KidsToyBoxApp extends StatelessWidget {
  const KidsToyBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kids Toy Box',
      debugShowCheckedModeBanner: false,
      theme: KidsTheme.lightTheme,
      // 안드로이드 기기별 시스템 글자 크기(폰트 배율) 설정으로 인한 UI 깨짐/오버플로우 원천 방지
      builder: (context, child) {
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.0,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: SplashScreen(),
    );
  }
}
