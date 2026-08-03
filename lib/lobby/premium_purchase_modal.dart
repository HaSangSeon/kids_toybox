import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/audio/audio_manager.dart';
import '../core/services/revenuecat_service.dart';

class PremiumPurchaseModal extends StatefulWidget {
  const PremiumPurchaseModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
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
  bool _isLoading = false;
  final TextEditingController _answerController = TextEditingController();

  String _questionText = '';
  int _expectedAnswer = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
    
    AudioManager.instance.playClick();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _generateProblem() {
    final rand = Random();
    final type = rand.nextInt(2);
    if (type == 0) {
      final n1 = rand.nextInt(25) + 20; // 20~44
      final n2 = rand.nextInt(25) + 15; // 15~39
      _expectedAnswer = n1 + n2;
      _questionText = '${_toKoreanNum(n1)} 더하기 ${_toKoreanNum(n2)}';
    } else {
      final n2 = rand.nextInt(30) + 18; // 18~47
      final ans = rand.nextInt(30) + 15; // 15~44
      final n1 = n2 + ans;
      _expectedAnswer = ans;
      _questionText = '$n1 - $n2';
    }
    _answerController.clear();
    setState(() {
      _showParentalGate = true;
    });
  }

  String _toKoreanNum(int n) {
    const tens = ['', '십', '이십', '삼십', '사십', '오십', '육십', '칠십', '팔십', '구십'];
    const ones = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];
    final t = n ~/ 10;
    final o = n % 10;
    return '${tens[t]}${ones[o]}';
  }

  Future<void> _verifyAnswerAndPurchase() async {
    final ans = int.tryParse(_answerController.text.trim());
    if (ans != null && ans == _expectedAnswer) {
      setState(() => _isLoading = true);
      final success = await RevenueCatService.instance.purchasePremium();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 결제가 완료되었습니다! 모든 미니게임이 평생 해금되었습니다.', style: GoogleFonts.jua(fontSize: 16)),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('결제가 취소되었거나 처리되지 않았습니다.', style: GoogleFonts.jua(fontSize: 15)),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } else {
      AudioManager.instance.playClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('정답이 아닙니다. 다시 계산해보세요!', style: GoogleFonts.jua(fontSize: 15)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      _answerController.clear();
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    final restored = await RevenueCatService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (restored) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 이전 구매 내역이 성공적으로 복원되었습니다!', style: GoogleFonts.jua(fontSize: 16)),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('복원 가능한 구매 내역을 찾을 수 없습니다.', style: GoogleFonts.jua(fontSize: 15)),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
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
        // ── 🎁 Icon Header ──
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFCC80), width: 2),
          ),
          alignment: Alignment.center,
          child: const Text('🎁', style: TextStyle(fontSize: 38)),
        ),
        const SizedBox(height: 14),

        // ── Title & Subtitle ──
        Text(
          '프리미엄 11종 게임 해금 🗝️',
          style: GoogleFonts.jua(fontSize: 23, color: const Color(0xFF2C3E50)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '커피 한 잔 값으로 11가지 인기 게임을\n평생 무제한으로 즐겨보세요!',
          style: GoogleFonts.jua(fontSize: 13.5, color: Colors.grey.shade600, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // ── 🏷️ Clean Pricing Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '7,900원',
                    style: GoogleFonts.jua(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '4,900원',
                    style: GoogleFonts.jua(
                      fontSize: 25,
                      color: const Color(0xFFE65100),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(평생 패키지)',
                    style: GoogleFonts.jua(fontSize: 13, color: const Color(0xFFFB8C00)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── 📌 Single Line Notice Box (Short & Spacious) ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📌 ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  '본 결제(4,900원)로 현재 잠겨있는 11가지 미니게임이 평생 해금됩니다.',
                  style: GoogleFonts.jua(fontSize: 12.5, color: const Color(0xFF455A64), height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── 🔘 Primary Action Button ──
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AudioManager.instance.playClick();
              _generateProblem();
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFB8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFB8C00).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '부모님 확인 후 해금하기 (4,900원) 🗝️',
                style: GoogleFonts.jua(
                  fontSize: 17.5,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Secondary Links Row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                AudioManager.instance.playClick();
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '나중에 할래요',
                  style: GoogleFonts.jua(fontSize: 13.5, color: Colors.grey.shade500),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('•', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
            ),
            GestureDetector(
              onTap: _isLoading ? null : _restorePurchases,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '구매 내역 복원',
                  style: GoogleFonts.jua(
                    fontSize: 13.5,
                    color: const Color(0xFF1976D2),
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
        // ── 🔒 Quiz Header ──
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF90CAF9), width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text('🔒', style: TextStyle(fontSize: 34)),
        ),
        const SizedBox(height: 14),

        Text(
          '부모님 확인 (어린이 결제 방지)',
          style: GoogleFonts.jua(fontSize: 21, color: const Color(0xFF2C3E50)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          '어린이 무단 결제를 방지하기 위해\n아래 퀴즈의 정답을 입력해 주세요.',
          style: GoogleFonts.jua(fontSize: 13, color: Colors.grey.shade600, height: 1.35),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // ── Quiz Box ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF5FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFAED6F1), width: 1.5),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$_questionText = ?',
              style: GoogleFonts.jua(fontSize: 25, color: const Color(0xFF2980B9)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Answer Input Field ──
        TextField(
          controller: _answerController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: GoogleFonts.jua(fontSize: 26, color: const Color(0xFF2C3E50)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            hintText: '정답 입력',
            hintStyle: GoogleFonts.jua(fontSize: 19, color: Colors.grey.shade400),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF2980B9), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Submit Button ──
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _verifyAnswerAndPurchase,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43A047).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      '정답 확인 및 4,900원 결제 💳',
                      style: GoogleFonts.jua(
                        fontSize: 17.5,
                        color: Colors.white,
                        shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3)],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        GestureDetector(
          onTap: () {
            AudioManager.instance.playClick();
            setState(() {
              _showParentalGate = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '뒤로 가기',
              style: GoogleFonts.jua(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }
}
