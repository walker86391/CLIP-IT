import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../projects/providers/project_workflow_provider.dart';

/// Model representing each of the 10 content genres.
class GenreChoice {
  const GenreChoice({
    required this.indexString,
    required this.icon,
    required this.title,
    required this.line1,
    required this.line2,
  });

  final String indexString;
  final IconData icon;
  final String title;
  final String line1;
  final String line2;
}

/// GenreSelectionPage — Step 1: Select the Genre for your content.
///
/// Matches the provided design picture:
/// - Top: 01 / 10 progress indicator, "SELECT THE GENRE FOR YOUR CONTENT" title,
///   slogan "BETTER CLIPS. BIGGER REACH."
/// - 10 Genre cards (01 to 10 in 2 columns):
///   - Hover effect: purple outline
///   - Click effect: rich purple tint, solid purple border, glow, and circular purple check badge
/// - Bottom left: Beta features disclosure notice
/// - Bottom right: Continue button (grayed out until any choice is pressed, then vibrant blue)
class GenreSelectionPage extends ConsumerStatefulWidget {
  const GenreSelectionPage({
    this.onContinue,
    this.initialSelectedIndex,
    super.key,
  });

  final ValueChanged<int>? onContinue;
  final int? initialSelectedIndex;

  @override
  ConsumerState<GenreSelectionPage> createState() => _GenreSelectionPageState();
}

class _GenreSelectionPageState extends ConsumerState<GenreSelectionPage> {
  int? _selectedIndex;

  static const List<GenreChoice> _leftColumnChoices = [
    GenreChoice(
      indexString: '01',
      icon: Icons.mic_none_rounded,
      title: 'PODCASTS / INTERVIEWS',
      line1: 'Long-form conversations, interviews and Q&As.',
      line2: 'Find the moments worth turning into clips.',
    ),
    GenreChoice(
      indexString: '02',
      icon: Icons.mic_external_on_outlined,
      title: 'STAND-UP',
      line1: 'Sets, specials and live comedy.',
      line2: 'Pull out the strongest bits and crowd moments.',
    ),
    GenreChoice(
      indexString: '03',
      icon: Icons.chat_bubble_outline_rounded,
      title: 'STORYTIME',
      line1: 'Stories, twists and personal moments.',
      line2: 'Keep the context; cut the dead space.',
    ),
    GenreChoice(
      indexString: '04',
      icon: Icons.laptop_chromebook_rounded,
      title: '** TECH / HOW-TO **',
      line1: 'Tutorials, builds and useful explanations.',
      line2: 'Find the clearest, most valuable moments.',
    ),
    GenreChoice(
      indexString: '05',
      icon: Icons.sensors_rounded,
      title: '** LIVE STREAMS **',
      line1: 'Streams, gameplay and spontaneous moments.',
      line2: 'Find what deserves to leave the stream.',
    ),
  ];

  static const List<GenreChoice> _rightColumnChoices = [
    GenreChoice(
      indexString: '06',
      icon: Icons.sentiment_very_satisfied_outlined,
      title: 'COMEDY / ROASTS',
      line1: 'Punchlines, comebacks and reactions.',
      line2: 'Catch the moments people will replay.',
    ),
    GenreChoice(
      indexString: '07',
      icon: Icons.emoji_emotions_outlined,
      title: 'FUNNY / MEMES',
      line1: 'Chaotic, unexpected and absurd moments.',
      line2: 'Built for quick, shareable clips.',
    ),
    GenreChoice(
      indexString: '08',
      icon: Icons.lightbulb_outline_rounded,
      title: 'LIFE / ADVICE',
      line1: 'Real stories, advice and perspective.',
      line2: 'Surface moments that actually say something.',
    ),
    GenreChoice(
      indexString: '09',
      icon: Icons.photo_camera_outlined,
      title: '** VLOGS **',
      line1: 'Everyday life, travel and personality-led content.',
      line2: 'Capture the moments with character.',
    ),
    GenreChoice(
      indexString: '10',
      icon: Icons.sports_esports_outlined,
      title: '** GAMING **',
      line1: 'Gameplay, reactions and highlights.',
      line2: 'Catch the moments with energy, skill or personality.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex ??
        ref.read(projectWorkflowProvider).selectedGenreIndex;
  }

  void _selectChoice(int globalIndex) {
    setState(() {
      _selectedIndex = globalIndex;
    });

    final choice = globalIndex < 5
        ? _leftColumnChoices[globalIndex]
        : _rightColumnChoices[globalIndex - 5];
    ref
        .read(projectWorkflowProvider.notifier)
        .selectGenre(globalIndex, choice.title);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedIndex != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Row ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Step progress + Title + Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Title: "SELECT THE GENRE FOR YOUR CONTENT"
                    Text.rich(
                      TextSpan(
                        children: const [
                          TextSpan(
                            text: 'SELECT THE GENRE ',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                          TextSpan(
                            text: 'FOR YOUR CONTENT',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Color(0xFFA855F7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtitle
                    const Text(
                      '(THE CRUCIAL PART DECIDING HOW YOUR CONTENT WILL BE CLIPPED)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                // Right: Tagline
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'BETTER CLIPS.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF7E8299),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'BIGGER REACH.',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: Color(0xFF7E8299),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── 10 Genre Selection Cards (2 Columns x 5 Rows) ──────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: 01 - 05
                Expanded(
                  child: Column(
                    children: List.generate(_leftColumnChoices.length, (i) {
                      final choice = _leftColumnChoices[i];
                      final isSelected = _selectedIndex == i;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GenreCard(
                          choice: choice,
                          isSelected: isSelected,
                          onTap: () => _selectChoice(i),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 20),

                // Right Column: 06 - 10
                Expanded(
                  child: Column(
                    children: List.generate(_rightColumnChoices.length, (i) {
                      final choice = _rightColumnChoices[i];
                      final globalIndex = i + 5;
                      final isSelected = _selectedIndex == globalIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GenreCard(
                          choice: choice,
                          isSelected: isSelected,
                          onTap: () => _selectChoice(globalIndex),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Bottom Area: Beta notice on left, Blue button on right ────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Beta disclaimer
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '** BETA FEATURES!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Color(0xFF8E92A6),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "**OUR APP CAN'T SE WHATS IN THE VIDEOS, IT ONLY HEARS IT OUT AND TAKES THE HINTS YOU WILL BE GIVING ABOUT THE VIDEO LATER AND FIGURE OUT THE CONTEXT.\nAND PAUSES AND EFFECTS TO REALLY IMAGINE WHAT'S GOING ON IN THE SCREEN",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                          letterSpacing: 0.4,
                          color: Color(0xFF55586D),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Right: Blue continue button (grayed out until chosen)
                _ContinueButton(
                  hasSelection: hasSelection,
                  onTap: hasSelection
                      ? () {
                          if (widget.onContinue != null) {
                            widget.onContinue!(_selectedIndex!);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single Genre Card with hover purple outline and selection purple styling.
class _GenreCard extends StatefulWidget {
  const _GenreCard({
    required this.choice,
    required this.isSelected,
    required this.onTap,
  });

  final GenreChoice choice;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    // Visual styling matching user screenshot
    final backgroundColor = isSelected
        ? const Color(0xFF1D1833) // Rich purple effect
        : _hovered
            ? const Color(0xFF171826)
            : const Color(0xFF13141F);

    final borderColor = isSelected
        ? const Color(0xFF8B5CF6) // Bright purple border
        : _hovered
            ? const Color(0xFF8B5CF6).withValues(alpha: 0.7) // Hover purple outline
            : const Color(0xFF222434);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: Key('genre_card_${widget.choice.indexString}'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovered ? 1.015 : 1.0),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x388B5CF6),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ]
                : _hovered
                    ? const [
                        BoxShadow(
                          color: Color(0x1F8B5CF6),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: Row(
            children: [
              // Index number: 01 to 10
              SizedBox(
                width: 26,
                child: Text(
                  widget.choice.indexString,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isSelected
                        ? const Color(0xFFA78BFA)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Rounded Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF262042)
                      : const Color(0xFF181A28),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF262838),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  widget.choice.icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFFC4B5FD)
                      : const Color(0xFFA78BFA),
                ),
              ),

              const SizedBox(width: 14),

              // Title and 2-line Subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.choice.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Color(0xFFF3F4F8),
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.choice.line1}\n${widget.choice.line2}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7E8299),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Trailing Checkmark or Chevron
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _hovered
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF4B5563),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

/// The bottom right Continue button.
///
/// Grayed out when hasSelection is false; vibrant blue when hasSelection is true.
class _ContinueButton extends StatefulWidget {
  const _ContinueButton({
    required this.hasSelection,
    required this.onTap,
  });

  final bool hasSelection;
  final VoidCallback? onTap;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasSelection = widget.hasSelection;

    return MouseRegion(
      cursor: hasSelection
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: const Key('genre_continue_button'),
        onTapDown: hasSelection ? (_) => setState(() => _pressed = true) : null,
        onTapUp: hasSelection ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: hasSelection ? () => setState(() => _pressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: hasSelection
              ? (_pressed ? 0.90 : (_hovered ? 1.08 : 1.0))
              : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasSelection
                  ? const Color(0xFF2563EB) // Royal blue
                  : const Color(0xFF1B1C28), // Grayed out
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasSelection
                    ? (_hovered ? Colors.white : const Color(0xFF3B82F6))
                    : const Color(0xFF262838),
                width: 1.0,
              ),
              boxShadow: hasSelection
                  ? [
                      BoxShadow(
                        color: _hovered
                            ? const Color(0x882563EB)
                            : const Color(0x552563EB),
                        blurRadius: _hovered ? 16 : 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.check_rounded,
              size: 24,
              color: hasSelection
                  ? Colors.white
                  : const Color(0xFF3E4155),
            ),
          ),
        ),
      ),
    );
  }
}
