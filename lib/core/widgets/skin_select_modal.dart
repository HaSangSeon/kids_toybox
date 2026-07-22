import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/kids_theme.dart';
import '../audio/audio_manager.dart';
import '../data/player_data_manager.dart';
import 'pacman_icon.dart';

class SkinSelectModal extends StatefulWidget {
  final String gameTitle;
  final String defaultSkin;
  final List<String> gameSkins;
  final ValueChanged<String> onStart;

  const SkinSelectModal({
    super.key,
    required this.gameTitle,
    required this.defaultSkin,
    required this.gameSkins,
    required this.onStart,
  });

  static Future<void> show(
    BuildContext context, {
    required String gameTitle,
    required String defaultSkin,
    required List<String> gameSkins,
    required ValueChanged<String> onStart,
  }) {
    AudioManager.instance.playClick();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: SkinSelectModal(
              gameTitle: gameTitle,
              defaultSkin: defaultSkin,
              gameSkins: gameSkins,
              onStart: onStart,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  @override
  State<SkinSelectModal> createState() => _SkinSelectModalState();
}

class _SkinSelectModalState extends State<SkinSelectModal>
    with SingleTickerProviderStateMixin {
  late String _selectedSkin;
  late AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _selectedSkin = widget.defaultSkin;
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: KidsTheme.blue, width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.gameTitle,
            style: GoogleFonts.jua(fontSize: 28, color: KidsTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            '어떤 모습으로 시작할까요?',
            style: GoogleFonts.jua(fontSize: 18, color: KidsTheme.textLight),
          ),
          const SizedBox(height: 24),
          
          ValueListenableBuilder<List<String>>(
            valueListenable: PlayerDataManager.instance.unlockedToysNotifier,
            builder: (context, unlockedToys, child) {
              final availableSkins = {widget.defaultSkin, ...widget.gameSkins}.toList();
              
              return AnimatedBuilder(
                animation: _floatCtrl,
                builder: (context, child) {
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: availableSkins.map((skin) {
                      final isUnlocked = skin == widget.defaultSkin || unlockedToys.contains(skin);
                      final isSelected = skin == _selectedSkin;
                      
                      final floatOffset = isSelected ? sin(_floatCtrl.value * pi) * 6.0 : 0.0;
                      final floatScale = isSelected ? 1.05 + sin(_floatCtrl.value * pi) * 0.05 : 1.0;

                      return GestureDetector(
                        onTap: () {
                          if (isUnlocked) {
                            AudioManager.instance.playClick();
                            setState(() {
                              _selectedSkin = skin;
                            });
                          }
                        },
                        child: Transform.translate(
                          offset: Offset(0, -floatOffset),
                          child: Transform.scale(
                            scale: floatScale,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isSelected ? KidsTheme.yellow : (isUnlocked ? Colors.white : Colors.grey.shade200),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? KidsTheme.orange : (isUnlocked ? Colors.grey.shade300 : Colors.grey.shade400),
                                      width: isSelected ? 4 : 2,
                                    ),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: KidsTheme.orange.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ] : null,
                                  ),
                                  child: Center(
                                    child: isUnlocked
                                        ? (skin == '🟡'
                                            ? const PacmanIcon(size: 40)
                                            : Text(
                                                skin,
                                                style: const TextStyle(fontSize: 40),
                                              ))
                                        : Text(
                                            '🔒',
                                            style: TextStyle(
                                              fontSize: 28,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                  ),
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: -6,
                                    right: -6,
                                    child: Text('✨', style: TextStyle(fontSize: 22)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            }
          ),
          
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '취소',
                      style: GoogleFonts.jua(fontSize: 20, color: Colors.black54),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AudioManager.instance.playClick();
                    Navigator.of(context).pop();
                    widget.onStart(_selectedSkin);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: KidsTheme.green,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade700, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '출발!',
                      style: GoogleFonts.jua(fontSize: 22, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
