import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// /ok — Post-authentication continuation choice screen.
///
/// Prompts the user: "How would you like to continue?"
/// Option 1: "Continue to app" → navigates directly to the main dashboard.
/// Option 2: "Watch tutorial" → currently a placeholder awaiting video link.
class OkPage extends StatelessWidget {
  const OkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12111A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            width: 440,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF181524),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF2C273E),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badge Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF241F36),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3F355E),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x338B5CF6),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 28,
                      color: Color(0xFFC084FC),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Title
                const Text(
                  'How would you like to continue?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Color(0xFFF1EFF8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'You are all set! Choose how you would like to proceed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E88A3),
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Button 1: Continue to app
                _ChoiceActionButton(
                  label: 'Continue to app',
                  icon: Icons.arrow_forward_rounded,
                  isPrimary: true,
                  onTap: () => context.go(Routes.home),
                ),
                const SizedBox(height: 12),

                // Button 2: Watch tutorial
                _ChoiceActionButton(
                  label: 'Watch tutorial',
                  icon: Icons.play_circle_outline_rounded,
                  isPrimary: false,
                  onTap: () {
                    // Placeholder for future YouTube tutorial integration.
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive button with smooth desktop hover and click feedback.
class _ChoiceActionButton extends StatefulWidget {
  const _ChoiceActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  State<_ChoiceActionButton> createState() => _ChoiceActionButtonState();
}

class _ChoiceActionButtonState extends State<_ChoiceActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: _hovered
                        ? [const Color(0xFF9868F8), const Color(0xFF7E38ED)]
                        : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                  )
                : null,
            color: isPrimary
                ? null
                : (_hovered
                    ? const Color(0xFF272338)
                    : const Color(0xFF1E1B2C)),
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(
                    color: _hovered
                        ? const Color(0xFF4C4468)
                        : const Color(0xFF322C46),
                    width: 1.2,
                  ),
            boxShadow: isPrimary && _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x558B5CF6),
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPrimary) ...[
                Icon(
                  widget.icon,
                  size: 19,
                  color: _hovered
                      ? const Color(0xFFF1EFF8)
                      : const Color(0xFFB8B3CB),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w600,
                  color: isPrimary
                      ? Colors.white
                      : (_hovered
                          ? const Color(0xFFF1EFF8)
                          : const Color(0xFFD6D1E6)),
                  letterSpacing: 0.2,
                ),
              ),
              if (isPrimary) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
