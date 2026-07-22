import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/audio_manager.dart';
import '../theme/kids_theme.dart';

class ParentalGateModal extends StatefulWidget {
  const ParentalGateModal({super.key});

  /// Static helper to display the modal and return if authenticated or not
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Must answer or cancel explicitly
      builder: (context) => const ParentalGateModal(),
    );
    return result ?? false;
  }

  @override
  State<ParentalGateModal> createState() => _ParentalGateModalState();
}

class _ParentalGateModalState extends State<ParentalGateModal> {
  late int _num1;
  late int _num2;
  late int _correctAnswer;
  String _inputAnswer = '';
  final Random _random = Random();
  bool _isWrong = false;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    // Generate multiplication of 2~9
    _num1 = _random.nextInt(8) + 2; // 2 to 9
    _num2 = _random.nextInt(8) + 2; // 2 to 9
    _correctAnswer = _num1 * _num2;
    _inputAnswer = '';
    _isWrong = false;
  }

  void _onKeypadTap(String val) {
    AudioManager.instance.playClick();
    setState(() {
      _isWrong = false;
      if (val == 'C') {
        _inputAnswer = '';
      } else if (val == 'OK') {
        _verifyAnswer();
      } else {
        if (_inputAnswer.length < 2) {
          _inputAnswer += val;
        }
      }
    });
  }

  void _verifyAnswer() {
    final parsed = int.tryParse(_inputAnswer);
    if (parsed == _correctAnswer) {
      AudioManager.instance.playSuccess();
      Navigator.of(context).pop(true);
    } else {
      // Wrong answer
      setState(() {
        _isWrong = true;
        _inputAnswer = ''; // Reset
      });
      // Play brief fail sound or error effect (represented by standard click for now, or just flash red)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isWrong = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: KidsTheme.toyDecoration(
          color: Colors.white,
          borderRadius: 28,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Cancel Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text(
                    '🛡️ 부모님 확인 (Parental Gate)',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: KidsTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    Navigator.of(context).pop(false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: KidsTheme.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: KidsTheme.borderDark, width: 2),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Subtitle instructions
            Text(
              '설정 변경이나 외부 링크로 가기 위해\n아래 수학 문제를 풀어주세요!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: KidsTheme.textLight,
              ),
            ),
            const SizedBox(height: 20),

            // Question Display Box
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: _isWrong ? KidsTheme.red.withValues(alpha: 0.2) : const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isWrong ? KidsTheme.red : KidsTheme.borderDark,
                  width: 3,
                ),
              ),
              child: FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Text(
                    '$_num1  ×  $_num2  = ',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: KidsTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 70,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: KidsTheme.borderDark, width: 2),
                    ),
                    child: Text(
                      _inputAnswer,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _isWrong ? KidsTheme.red : KidsTheme.purple,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
            if (_isWrong) ...[
              const SizedBox(height: 8),
              Text(
                '틀렸어요! 다시 풀어보세요. 🚫',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: KidsTheme.red,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Keypad grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                for (var i = 1; i <= 9; i++) _buildKeypadButton(i.toString()),
                _buildKeypadButton('C', color: KidsTheme.orange),
                _buildKeypadButton('0'),
                _buildKeypadButton('OK', color: KidsTheme.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String label, {Color? color}) {
    final bgColor = color ?? const Color(0xFFF0F4F8);
    final fgColor = color != null ? Colors.white : KidsTheme.textDark;

    return GestureDetector(
      onTap: () => _onKeypadTap(label),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: KidsTheme.borderDark, width: 2.5),
          boxShadow: [
            const BoxShadow(
              color: KidsTheme.borderDark,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: label == 'OK' ? 18 : 22,
              fontWeight: FontWeight.w900,
              color: fgColor,
            ),
          ),
        ),
      ),
    );
  }
}
