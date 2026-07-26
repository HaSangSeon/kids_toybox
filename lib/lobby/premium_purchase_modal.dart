import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/kids_theme.dart';
import '../core/audio/audio_manager.dart';
import '../core/data/player_data_manager.dart';

class PremiumPurchaseModal extends StatefulWidget {
  const PremiumPurchaseModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => const PremiumPurchaseModal(),
    );
  }

  @override
  State<PremiumPurchaseModal> createState() => _PremiumPurchaseModalState();
}

class _PremiumPurchaseModalState extends State<PremiumPurchaseModal> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  bool _showParentalGate = false;
  int _num1 = 0;
  int _num2 = 0;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    
    AudioManager.instance.playClick();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _generateMathProblem() {
    final rand = Random();
    _num1 = rand.nextInt(5) + 3; // 3 to 7
    _num2 = rand.nextInt(5) + 3; // 3 to 7
    setState(() {
      _showParentalGate = true;
    });
  }

  void _verifyAnswer() {
    final ans = int.tryParse(_answerController.text.trim());
    if (ans == (_num1 * _num2)) {
      // Success!
      AudioManager.instance.playSuccess();
      PlayerDataManager.instance.unlockPremium();
      Navigator.of(context).pop();
    } else {
      // Wrong
      AudioManager.instance.playClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('다시 계산해보세요!', style: GoogleFonts.jua(fontSize: 16)),
          backgroundColor: Colors.red,
        ),
      );
      _answerController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: KidsTheme.toyDecoration(
            color: Colors.white,
            borderRadius: 36,
          ),
          child: SingleChildScrollView(
            child: _showParentalGate ? _buildParentalGate() : _buildPurchasePitch(),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasePitch() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎁', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text(
          '앗! 마법 상자가 잠겨있어요!',
          style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          '마법 열쇠를 구매하면 모든 20개 이상의 미니게임을 자유롭게 즐길 수 있어요!\n부모님께 마법 열쇠를 열어달라고 부탁해볼까요?',
          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                _generateMathProblem();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '부모님 부르기 🗝️', 
                    style: GoogleFonts.jua(
                      fontSize: 24, 
                      color: Colors.white,
                      shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Text(
                  '나중에 할래요', 
                  style: GoogleFonts.nunito(
                    fontSize: 18, 
                    fontWeight: FontWeight.w800, 
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentalGate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '부모님 확인',
          style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          '계속하려면 아래 문제의 정답을 입력해주세요.',
          style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          '$_num1 x $_num2 = ?',
          style: GoogleFonts.jua(fontSize: 40, color: KidsTheme.blue),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _answerController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.jua(fontSize: 32, color: KidsTheme.textDark),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            hintText: '정답',
          ),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _verifyAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: KidsTheme.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 6,
                shadowColor: KidsTheme.green.withValues(alpha: 0.5),
              ),
              child: Text('정답 확인!', style: GoogleFonts.jua(fontSize: 24)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                AudioManager.instance.playClick();
                setState(() {
                  _showParentalGate = false;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.grey.shade500,
              ),
              child: Text(
                '뒤로 가기', 
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
