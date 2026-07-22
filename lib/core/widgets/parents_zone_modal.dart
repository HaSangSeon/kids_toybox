import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import '../audio/audio_manager.dart';
import '../theme/kids_theme.dart';

class ParentsZoneModal extends StatefulWidget {
  const ParentsZoneModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ParentsZoneModal(),
    );
  }

  @override
  State<ParentsZoneModal> createState() => _ParentsZoneModalState();
}

class _ParentsZoneModalState extends State<ParentsZoneModal> {
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = AudioManager.instance.soundEnabled;
  }

  void _toggleSound() {
    AudioManager.instance.playClick();
    setState(() {
      AudioManager.instance.toggleSound();
      _soundEnabled = AudioManager.instance.soundEnabled;
    });
  }

  Future<void> _resetData() async {
    AudioManager.instance.playClick();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ 정말 모두 지울까요?'),
        content: const Text(
          '아이가 지금까지 색칠한 모양들과 예쁘게 꾸며둔 스티커판 배치가 처음으로 되돌아갑니다. 지우시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop(false);
            },
            child: const Text('취소', style: TextStyle(color: KidsTheme.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KidsTheme.red),
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop(true);
            },
            child: const Text('네, 지울래요', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final box = Hive.box('high_scores_box');
      await box.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 진행 데이터가 모두 초기화되었습니다!'),
          backgroundColor: KidsTheme.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showPrivacyPolicy() {
    AudioManager.instance.playClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛡️ 개인정보 처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '본 앱은 유아동을 위해 안전하게 설계되었습니다.\n\n'
            '1. 사용자 데이터를 외부 서버로 일절 전송하지 않으며, 모든 그림 및 스티커 데이터는 오직 현재 기기(로컬)에만 안전하게 저장됩니다.\n'
            '2. 외부 광고 네트워크를 포함하지 않습니다. (단, 일부 신규 게임 콘텐츠는 부모 확인 절차를 거쳐야만 접근할 수 있는 안전한 인앱 결제로 제공될 수 있습니다.)\n'
            '3. 구글 플레이 가족 정책(Designed for Families) 가이드라인을 철저히 준수합니다.\n\n'
            '안심하고 아이와 함께 즐거운 놀이를 경험하세요!',
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KidsTheme.blue),
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.of(context).pop();
            },
            child: const Text('확인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: KidsTheme.toyDecoration(
          color: Colors.white,
          borderRadius: 28,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text(
                    '⚙️ 부모님 공간 (Parents Zone)',
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
                    Navigator.of(context).pop();
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
            const SizedBox(height: 24),

            // Sound Toggle Option
            _buildSettingRow(
              icon: _soundEnabled ? '🔊' : '🔇',
              title: '효과음 및 사운드',
              subtitle: '앱 내 모든 소리를 켜거나 끕니다.',
              color: KidsTheme.blue,
              action: Switch(
                value: _soundEnabled,
                activeColor: KidsTheme.green,
                onChanged: (val) => _toggleSound(),
              ),
              onTap: _toggleSound,
            ),
            const SizedBox(height: 16),

            // Data Reset Option
            _buildSettingRow(
              icon: '🗑️',
              title: '게임 진행 데이터 초기화',
              subtitle: '색칠한 그림과 스티커 배치를 모두 지웁니다.',
              color: KidsTheme.orange,
              action: const Icon(Icons.chevron_right, color: KidsTheme.textLight),
              onTap: _resetData,
            ),
            const SizedBox(height: 16),

            // Privacy Policy Option
            _buildSettingRow(
              icon: '🛡️',
              title: '개인정보 처리방침 보기',
              subtitle: '안전한 데이터 오프라인 저장 정책 안내.',
              color: KidsTheme.purple,
              action: const Icon(Icons.chevron_right, color: KidsTheme.textLight),
              onTap: _showPrivacyPolicy,
            ),
            const SizedBox(height: 16),

            // App Version Info
            Text(
              'Kids Toybox App v1.0.1\nDesigned with ❤️ for Families',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow({
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required Widget action,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: KidsTheme.borderDark, width: 2),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: KidsTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: KidsTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            action,
          ],
        ),
      ),
    );
  }
}
