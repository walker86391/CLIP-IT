import 'package:flutter/material.dart';

/// Professional Workflow Repurposing Screen for ClipIt.
class RepurposePage extends StatefulWidget {
  const RepurposePage({super.key});

  @override
  State<RepurposePage> createState() => _RepurposePageState();
}

class _RepurposePageState extends State<RepurposePage> {
  bool _autoFaceTrack = true;
  bool _highlightDetection = true;
  bool _autoSubtitles = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'REPURPOSE STUDIO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFFF3F4F8),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Transform 1 long-form video into multiple optimized short formats simultaneously.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E92A6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Source Content Selector
            _SectionContainer(
              stepNumber: '1',
              stepTitle: 'SOURCE CONTENT',
              subtitle: 'Select or drop the long video to repurpose',
              child: Container(
                height: 110,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF13141E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF262838),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E202C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2D3042),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.video_library_rounded,
                        size: 26,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'AI & Creative Tools Podcast #42.mp4',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF3F4F8),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Duration: 52:18  •  Resolution: 1080p60  •  Size: 1.84 GB',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF7E8299),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E202C),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF2D3042),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Change Source',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E4ED),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Step 2: Target Formats & Aspect Ratios
            _SectionContainer(
              stepNumber: '2',
              stepTitle: 'TARGET FORMATS & PLATFORMS',
              subtitle: 'Select output dimensions and multi-platform presets',
              child: Row(
                children: const [
                  Expanded(
                    child: _FormatOptionCard(
                      ratio: '9:16',
                      title: 'Vertical Shorts / Reels',
                      platforms: 'TikTok, IG Reels, YouTube Shorts',
                      isSelected: true,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _FormatOptionCard(
                      ratio: '1:1',
                      title: 'Square Feed',
                      platforms: 'Instagram Post, LinkedIn, Twitter',
                      isSelected: true,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: _FormatOptionCard(
                      ratio: '16:9',
                      title: 'Landscape Clips',
                      platforms: 'YouTube, Facebook, Twitter Video',
                      isSelected: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Step 3: AI Enhancement Settings
            _SectionContainer(
              stepNumber: '3',
              stepTitle: 'AI ENHANCEMENT & STYLING',
              subtitle: 'Configure automated speaker framing and animated captions',
              child: Column(
                children: [
                  _ToggleRow(
                    title: 'Auto Face Tracking & Active Speaker Framing',
                    description:
                        'Automatically crops 16:9 into 9:16 keeping the speaker centered.',
                    value: _autoFaceTrack,
                    onChanged: (val) => setState(() => _autoFaceTrack = val),
                  ),
                  const Divider(color: Color(0xFF1E202C), height: 16),
                  _ToggleRow(
                    title: 'AI Highlight & Viral Moment Detection',
                    description:
                        'Identifies hooks, jokes, insights and high-energy segments.',
                    value: _highlightDetection,
                    onChanged: (val) => setState(() => _highlightDetection = val),
                  ),
                  const Divider(color: Color(0xFF1E202C), height: 16),
                  _ToggleRow(
                    title: 'Auto Subtitles & Emoji Syncing',
                    description:
                        'Generates animated, high-retention karaoke style word captions.',
                    value: _autoSubtitles,
                    onChanged: (val) => setState(() => _autoSubtitles = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x338B5CF6),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Generate Repurposed Clips',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.stepNumber,
    required this.stepTitle,
    required this.subtitle,
    required this.child,
  });

  final String stepNumber;
  final String stepTitle;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161722),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF262838),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC4B5FD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                stepTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Color(0xFFF3F4F8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF8E92A6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FormatOptionCard extends StatelessWidget {
  const _FormatOptionCard({
    required this.ratio,
    required this.title,
    required this.platforms,
    required this.isSelected,
  });

  final String ratio;
  final String title;
  final String platforms;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF201D30) : const Color(0xFF12131A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF262838),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B5CF6)
                      : const Color(0xFF222432),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  ratio,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF8E92A6),
                  ),
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : const Color(0xFF55586D),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF3F4F8),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            platforms,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF7E8299),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF3F4F8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7E8299),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF8B5CF6),
          activeTrackColor: const Color(0xFF382F56),
          inactiveTrackColor: const Color(0xFF1E202C),
          inactiveThumbColor: const Color(0xFF5C6078),
        ),
      ],
    );
  }
}
