import 'package:flutter/material.dart';

/// Professional Projects Management Screen for ClipIt.
class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    this.isFromHomeUpload = false,
    this.uploadedFileName,
    this.onBackToProjects,
    super.key,
  });

  final bool isFromHomeUpload;
  final String? uploadedFileName;
  final VoidCallback? onBackToProjects;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _allProjects = [
    {
      'title': 'AI & Creative Tools Podcast #42',
      'duration': '52:18',
      'clipsCount': 12,
      'status': 'Ready',
      'statusColor': Color(0xFF10B981),
      'lastModified': '2 hours ago',
      'resolution': '1080p60',
    },
    {
      'title': 'Weekly Tech Review: Vision Pro & Spatial Computing',
      'duration': '19:45',
      'clipsCount': 6,
      'status': 'Processing 74%',
      'statusColor': Color(0xFFF59E0B),
      'lastModified': 'Yesterday',
      'resolution': '4K30',
    },
    {
      'title': 'Startup Masterclass: Scaling from 0 to 1M Users',
      'duration': '1:14:02',
      'clipsCount': 18,
      'status': 'Ready',
      'statusColor': Color(0xFF10B981),
      'lastModified': '3 days ago',
      'resolution': '1080p30',
    },
    {
      'title': 'Livestream Highlights & Viral Moments',
      'duration': '2:40:11',
      'clipsCount': 24,
      'status': 'Ready',
      'statusColor': Color(0xFF10B981),
      'lastModified': '5 days ago',
      'resolution': '1080p60',
    },
    {
      'title': 'Deep Dive: Autonomous Agents & LLM Architectures',
      'duration': '44:10',
      'clipsCount': 9,
      'status': 'Draft',
      'statusColor': Color(0xFF8E92A6),
      'lastModified': '1 week ago',
      'resolution': '1080p60',
    },
    {
      'title': 'Creative Direction & Modern Video Editing Workflows',
      'duration': '31:22',
      'clipsCount': 8,
      'status': 'Ready',
      'statusColor': Color(0xFF10B981),
      'lastModified': '2 weeks ago',
      'resolution': '4K60',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _allProjects.where((p) {
      final matchesSearch = p['title']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Ready' && p['status'] == 'Ready') return true;
      if (_selectedFilter == 'Processing' &&
          p['status'].toString().startsWith('Processing')) {
        return true;
      }
      if (_selectedFilter == 'Draft' && p['status'] == 'Draft') return true;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: widget.isFromHomeUpload
            ? _buildUploadWorkflowView(context)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'PROJECTS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFFF3F4F8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your ClipIt projects in one workspace.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E92A6),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _ActionButton(
                      label: 'Import Video',
                      icon: Icons.file_upload_outlined,
                      isPrimary: false,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _ActionButton(
                      label: '+ New Project',
                      isPrimary: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls Row: Search + Filter Pills + Sort
            Row(
              children: [
                // Search Input
                Container(
                  width: 260,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161722),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF262838),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF72758A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF3F4F8),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search projects...',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF72758A),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Filter Pills
                _FilterPill(
                  label: 'All (6)',
                  isSelected: _selectedFilter == 'All',
                  onTap: () => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Ready',
                  isSelected: _selectedFilter == 'Ready',
                  onTap: () => setState(() => _selectedFilter = 'Ready'),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Processing',
                  isSelected: _selectedFilter == 'Processing',
                  onTap: () => setState(() => _selectedFilter = 'Processing'),
                ),
                const SizedBox(width: 6),
                _FilterPill(
                  label: 'Draft',
                  isSelected: _selectedFilter == 'Draft',
                  onTap: () => setState(() => _selectedFilter = 'Draft'),
                ),

                const Spacer(),

                // Sort Dropdown
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161722),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF262838),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.sort_rounded,
                        size: 14,
                        color: Color(0xFF8E92A6),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Last modified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E92A6),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: Color(0xFF8E92A6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Projects Grid (3 columns on desktop)
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 1100 ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    mainAxisExtent: 210,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final project = filtered[index];
                    return _ProjectCard(project: project);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadWorkflowView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top breadcrumb / navigation bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (widget.onBackToProjects != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onBackToProjects,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF191A26),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF2B2E42),
                            width: 1.0,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 14,
                              color: Color(0xFF8E92A6),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Back to Projects',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF8E92A6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x268B5CF6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0x668B5CF6),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'UPLOAD WORKFLOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Color(0xFFA78BFA),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0x2610B981),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0x6610B981),
                  width: 0.8,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Video Imported & Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Imported video summary banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF161722),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF262838), width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF201D33),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8B5CF6), width: 1.0),
                ),
                child: const Icon(
                  Icons.smart_display_rounded,
                  size: 24,
                  color: Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.uploadedFileName ?? 'Imported Video File',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF3F4F8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Source video active • Next step: Zone Selection & Clip Segmentation',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7E8299),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Waiting for next prompt placeholder container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
          decoration: BoxDecoration(
            color: const Color(0xFF13141E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            children: const [
              Icon(
                Icons.grid_view_rounded,
                size: 38,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(height: 14),
              Text(
                'SELECT THIS ZONE FOR YOUR CONTENT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Color(0xFFF3F4F8),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Upload workflow connected. Ready to build the 10 zone buttons and interactive layout in the next prompt.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7E8299),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatefulWidget {
  const _ProjectCard({required this.project});

  final Map<String, dynamic> project;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.project;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF1D1F2D) : const Color(0xFF161722),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                : const Color(0xFF262838),
            width: 1.0,
          ),
          boxShadow: _hovered
              ? const [
                  BoxShadow(
                    color: Color(0x228B5CF6),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Preview Area
            Container(
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xFF101118),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF202230),
                  width: 0.8,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 34,
                      color: _hovered
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF3F4256),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xCC000000),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p['duration'] as String,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1C28),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF2A2D40),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        p['resolution'] as String,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9194A8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Project Title + Context Menu
            Row(
              children: [
                Expanded(
                  child: Text(
                    p['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF3F4F8),
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: Color(0xFF8E92A6),
                  ),
                  color: const Color(0xFF1C1E2B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFF2C2F42)),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Open')),
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Metadata Row: Status + Clips Count + Last Modified
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (p['statusColor'] as Color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p['status'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: p['statusColor'] as Color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${p['clipsCount']} clips',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8E92A6),
                  ),
                ),
                const Spacer(),
                Text(
                  p['lastModified'] as String,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF6B6E82),
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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF221F33) : const Color(0xFF161722),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : const Color(0xFF262838),
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF8E92A6),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? (_hovered ? const Color(0xFF986DF8) : const Color(0xFF8B5CF6))
                : (_hovered ? const Color(0xFF222432) : const Color(0xFF161722)),
            borderRadius: BorderRadius.circular(8),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: _hovered
                        ? const Color(0xFF383B4E)
                        : const Color(0xFF262838),
                    width: 1.0,
                  ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.isPrimary
                      ? Colors.white
                      : const Color(0xFFE2E4ED),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary
                      ? Colors.white
                      : const Color(0xFFE2E4ED),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
