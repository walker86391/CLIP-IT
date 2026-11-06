import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/services/cookie_settings_service.dart';
import '../../../core/services/model_manager.dart';
import '../../../core/services/whisper_service.dart';

/// Professional 2-Pane Settings Screen for ClipIt.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _selectedCategoryIndex = 0;

  bool _gpuAcceleration = true;
  bool _autoSave = true;
  bool _highBitrateExport = false;
  bool _reduceMotion = false;
  final String _exportResolution = '1080p (FHD)';

  // Cookies management state
  final TextEditingController _instagramCookiesController =
      TextEditingController();
  final TextEditingController _youtubeCookiesController =
      TextEditingController();

  String _instagramStatus = 'Loading status...';
  String _youtubeStatus = 'Loading status...';
  bool _isSavingInstagram = false;
  bool _isSavingYoutube = false;

  // AI & Models state
  List<ModelInfo> _models = ClipItModelManager.availableModels;
  String _activeModelId = ClipItModelManager.defaultActiveModelId;
  final Map<String, double> _downloadProgress = {};
  final Map<String, ModelVerificationResult> _verificationResults = {};
  final Map<String, bool> _isChecking = {};
  bool _hasWhisperCli = false;

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'General', 'icon': Icons.tune_rounded},
    {'title': 'Video & Export', 'icon': Icons.video_settings_rounded},
    {'title': 'Downloader & Cookies', 'icon': Icons.cookie_outlined},
    {'title': 'AI & Models', 'icon': Icons.psychology_outlined},
    {'title': 'Appearance', 'icon': Icons.palette_outlined},
    {'title': 'Storage & Cache', 'icon': Icons.storage_rounded},
    {'title': 'Shortcuts', 'icon': Icons.keyboard_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadCookieSettings();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final activeId = await ClipItModelManager.instance.getActiveModelId();
    final models = await ClipItModelManager.instance.listModels();
    final cliPath = await WhisperService.instance.getWhisperCliPath();
    if (mounted) {
      setState(() {
        _activeModelId = activeId;
        _models = models;
        _hasWhisperCli = cliPath != null;
      });
    }
  }

  @override
  void dispose() {
    _instagramCookiesController.dispose();
    _youtubeCookiesController.dispose();
    super.dispose();
  }

  Future<void> _loadCookieSettings() async {
    final instaText = await CookieSettingsService.instance
        .getRawCookieText(CookiePlatform.instagram);
    final ytText = await CookieSettingsService.instance
        .getRawCookieText(CookiePlatform.youtube);

    final instaStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.instagram);
    final ytStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.youtube);

    if (mounted) {
      setState(() {
        _instagramCookiesController.text = instaText;
        _youtubeCookiesController.text = ytText;
        _instagramStatus = instaStatus;
        _youtubeStatus = ytStatus;
      });
    }
  }

  Future<void> _saveInstagramCookies() async {
    setState(() => _isSavingInstagram = true);
    await CookieSettingsService.instance.saveCookies(
      platform: CookiePlatform.instagram,
      rawInput: _instagramCookiesController.text,
    );
    final newStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.instagram);

    if (mounted) {
      setState(() {
        _isSavingInstagram = false;
        _instagramStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instagram authentication cookies saved successfully!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _clearInstagramCookies() async {
    _instagramCookiesController.clear();
    await CookieSettingsService.instance.saveCookies(
      platform: CookiePlatform.instagram,
      rawInput: '',
    );
    final newStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.instagram);
    if (mounted) {
      setState(() {
        _instagramStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Instagram cookies cleared.'),
          backgroundColor: Color(0xFF4B5563),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveYoutubeCookies() async {
    setState(() => _isSavingYoutube = true);
    await CookieSettingsService.instance.saveCookies(
      platform: CookiePlatform.youtube,
      rawInput: _youtubeCookiesController.text,
    );
    final newStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.youtube);

    if (mounted) {
      setState(() {
        _isSavingYoutube = false;
        _youtubeStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube authentication cookies saved successfully!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _clearYoutubeCookies() async {
    _youtubeCookiesController.clear();
    await CookieSettingsService.instance.saveCookies(
      platform: CookiePlatform.youtube,
      rawInput: '',
    );
    final newStatus = await CookieSettingsService.instance
        .getCookieStatusSummary(CookiePlatform.youtube);
    if (mounted) {
      setState(() {
        _youtubeStatus = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube cookies cleared.'),
          backgroundColor: Color(0xFF4B5563),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to external category index requests (e.g. from Download Monitor)
    final requestedCatIndex = ref.watch(settingsCategoryIndexProvider);
    if (requestedCatIndex != _selectedCategoryIndex &&
        requestedCatIndex >= 0 &&
        requestedCatIndex < _categories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedCategoryIndex != requestedCatIndex) {
          setState(() => _selectedCategoryIndex = requestedCatIndex);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1016),
      body: Row(
        children: [
          // Left Pane: Categories (~240px)
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: Color(0xFF13141E),
              border: Border(
                right: BorderSide(color: Color(0xFF222432), width: 1.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFFF3F4F8),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;

                      return _CategoryListItem(
                        title: cat['title'] as String,
                        icon: cat['icon'] as IconData,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedCategoryIndex = index);
                          ref
                              .read(settingsCategoryIndexProvider.notifier)
                              .setIndex(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Right Pane: Active Category Settings with smooth crossfade
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.012, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedCategoryIndex),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 26,
                  ),
                  child: _selectedCategoryIndex == 2
                      ? _buildCookiesSettingsPane()
                      : (_selectedCategoryIndex == 3
                          ? _buildAiModelsSettingsPane()
                          : _buildGeneralSettingsPane()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Default Performance and General Pane
  Widget _buildGeneralSettingsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _categories[_selectedCategoryIndex]['title'] as String,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Color(0xFFF3F4F8),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure performance, rendering engine, and defaults for your projects.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF8E92A6),
          ),
        ),
        const SizedBox(height: 24),

        // Settings Card 1
        _SettingsCard(
          title: 'PERFORMANCE & HARDWARE',
          children: [
            _SettingToggleRow(
              title: 'Hardware GPU Acceleration',
              subtitle:
                  'Utilize NVENC / Intel QuickSync / AMD AMF for faster video decode and rendering.',
              value: _gpuAcceleration,
              onChanged: (val) => setState(() => _gpuAcceleration = val),
            ),
            const Divider(color: Color(0xFF1E202C), height: 16),
            _SettingToggleRow(
              title: 'Auto-save projects in background',
              subtitle:
                  'Saves clip changes automatically without interrupting rendering.',
              value: _autoSave,
              onChanged: (val) => setState(() => _autoSave = val),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Settings Card 2
        _SettingsCard(
          title: 'RENDER & EXPORT DEFAULTS',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Default Export Resolution',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF3F4F8),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Preferred resolution for vertical shorts and reels.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7E8299),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13141E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF262838),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    _exportResolution,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE2E4ED),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Color(0xFF1E202C), height: 16),
            _SettingToggleRow(
              title: 'High Bitrate (ProRes / 50 Mbps H.264)',
              subtitle:
                  'Maximizes visual fidelity for high-resolution video displays.',
              value: _highBitrateExport,
              onChanged: (val) => setState(() => _highBitrateExport = val),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Settings Card 3
        _SettingsCard(
          title: 'ACCESSIBILITY & MOTION',
          children: [
            _SettingToggleRow(
              title: 'Reduce Motion',
              subtitle:
                  'Disables non-essential animated transitions across the app interface.',
              value: _reduceMotion,
              onChanged: (val) => setState(() => _reduceMotion = val),
            ),
          ],
        ),
      ],
    );
  }

  /// Downloader & Cookies Pane
  Widget _buildCookiesSettingsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cookie_rounded, color: Color(0xFF8B5CF6), size: 24),
            const SizedBox(width: 10),
            const Text(
              'Downloader & Cookies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Color(0xFFF3F4F8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Provide authentication session cookies so yt-dlp can download private, restricted, or rate-limited Instagram Reels and YouTube videos.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF8E92A6),
          ),
        ),
        const SizedBox(height: 22),

        // ── 1. INSTAGRAM COOKIES ───────────────────────────────────────────────
        _SettingsCard(
          title: 'INSTAGRAM AUTHENTICATION COOKIES',
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _instagramStatus.contains('Configured')
                        ? const Color(0x2610B981)
                        : const Color(0x26EF4444),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _instagramStatus.contains('Configured')
                          ? const Color(0x6610B981)
                          : const Color(0x66EF4444),
                    ),
                  ),
                  child: Text(
                    _instagramStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _instagramStatus.contains('Configured')
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _instagramCookiesController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFE2E4ED),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF10111A),
                hintText:
                    'Paste Instagram cookies here (Netscape format, Cookie-Editor JSON, or sessionid=... key-value pairs)...',
                hintStyle:
                    const TextStyle(fontSize: 11, color: Color(0xFF555972)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF262838)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF262838)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingInstagram ? null : _saveInstagramCookies,
                  icon: _isSavingInstagram
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 15),
                  label: const Text('Save Instagram Cookies',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9EA1B5),
                    side: const BorderSide(color: Color(0xFF262838)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _clearInstagramCookies,
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 2. YOUTUBE COOKIES ─────────────────────────────────────────────────
        _SettingsCard(
          title: 'YOUTUBE AUTHENTICATION COOKIES',
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _youtubeStatus.contains('Configured')
                        ? const Color(0x2610B981)
                        : const Color(0x26EF4444),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _youtubeStatus.contains('Configured')
                          ? const Color(0x6610B981)
                          : const Color(0x66EF4444),
                    ),
                  ),
                  child: Text(
                    _youtubeStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _youtubeStatus.contains('Configured')
                          ? const Color(0xFF34D399)
                          : const Color(0xFFF87171),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _youtubeCookiesController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFE2E4ED),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF10111A),
                hintText:
                    'Paste YouTube cookies here (Netscape format, Cookie-Editor JSON, or SID=... key-value pairs)...',
                hintStyle:
                    const TextStyle(fontSize: 11, color: Color(0xFF555972)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF262838)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF262838)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSavingYoutube ? null : _saveYoutubeCookies,
                  icon: _isSavingYoutube
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 15),
                  label: const Text('Save YouTube Cookies',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9EA1B5),
                    side: const BorderSide(color: Color(0xFF262838)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _clearYoutubeCookies,
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── 3. DETAILED STEP-BY-STEP GUIDE ─────────────────────────────────────
        _SettingsCard(
          title: '📖 HOW TO COPY & PASTE YOUR COOKIES (EASY 1-MINUTE SETUP)',
          children: [
            _buildGuideStep(
              stepNumber: '1',
              title: 'Install the "Cookie-Editor" Extension in your Browser',
              description:
                  'Install the free "Cookie-Editor" extension on Google Chrome, Microsoft Edge, Brave, or Firefox. (Search for "Cookie-Editor" in the Chrome Web Store or Firefox Add-ons).',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              stepNumber: '2',
              title: 'Log Into Your Account',
              description:
                  'Open instagram.com (or youtube.com) in your browser and ensure you are logged in to your account.',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              stepNumber: '3',
              title: 'Click Cookie-Editor & Export',
              description:
                  'Click the Cookie-Editor icon in your browser toolbar. At the bottom right of the popup, click "Export" and choose "Export as Netscape" (or "Export as JSON" — ClipIt automatically detects both!).',
            ),
            const SizedBox(height: 12),
            _buildGuideStep(
              stepNumber: '4',
              title: 'Paste Into ClipIt & Click Save',
              description:
                  'Paste the copied content into the respective box above and click "Save Cookies". yt-dlp will now authenticate using your session.',
            ),
            const Divider(color: Color(0xFF262838), height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10111A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF262838)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '🔍 WHAT COOKIES ARE REQUIRED?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC7EEF9),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Instagram requires: sessionid, ds_user_id, and csrftoken (Cookie-Editor exports all of them automatically).\n'
                    '• YouTube requires: SID, HSID, SSID, and LOGIN_INFO.\n'
                    '• Privacy Guarantee: Cookies are stored locally on your machine in %LOCALAPPDATA%\\ClipItV1\\cookies and are only provided to local yt-dlp execution to download your requested media. They are never transmitted to any third-party servers.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E92A6),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuideStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF221F33),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8B5CF6)),
          ),
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
        const SizedBox(width: 12),
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
                  fontSize: 11.5,
                  color: Color(0xFF8E92A6),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAiModelsSettingsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI & SPEECH RECOGNITION MODELS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: Color(0xFFF3F4F8),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Local offline speech-to-text models for Roman Hindi / Hinglish and multilingual transcription.',
          style: TextStyle(
            fontSize: 12.5,
            color: Color(0xFF8E92A6),
          ),
        ),
        const SizedBox(height: 24),

        // Runtime status card
        _SettingsCard(
          title: 'OFFLINE SPEECH ENGINE (WHISPER.CPP)',
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (_hasWhisperCli
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _hasWhisperCli
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _hasWhisperCli
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasWhisperCli
                            ? 'Whisper C++ Binary Active'
                            : 'Whisper Binary in Project Bundle',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Fast C++ CPU/GPU inference via whisper-cli.exe — runs offline with 0 cloud dependencies.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8E92A6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Models list card
        _SettingsCard(
          title: 'AVAILABLE SPEECH MODELS (%LOCALAPPDATA%\\clipit\\models)',
          children: [
            for (final model in _models) ...[
              _buildModelRow(model),
              if (model != _models.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildModelRow(ModelInfo model) {
    final isDownloading = _downloadProgress.containsKey(model.id);
    final progress = _downloadProgress[model.id] ?? 0.0;
    final isActive = _activeModelId == model.id;
    final isChecking = _isChecking[model.id] ?? false;
    final verification = _verificationResults[model.id];

    return _InteractiveModelCard(
      isActive: isActive,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF3F4F8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262838),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF383A4E),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          model.tier,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Installed status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: model.installed
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFF262838),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: model.installed
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFF383A4E),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          model.installed ? 'DOWNLOADED' : model.formattedSize,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: model.installed
                                ? const Color(0xFF10B981)
                                : const Color(0xFF8E92A6),
                          ),
                        ),
                      ),
                      if (isActive && model.installed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFF8B5CF6), width: 0.8),
                          ),
                          child: const Text(
                            'LIVE MODEL',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC4B5FD),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    model.description,
                    style:
                        const TextStyle(fontSize: 11.5, color: Color(0xFF8E92A6)),
                  ),
                  if (verification != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: verification.isValid
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: verification.isValid
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : const Color(0xFFEF4444).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            verification.isValid
                                ? Icons.verified_rounded
                                : Icons.error_outline_rounded,
                            size: 13,
                            color: verification.isValid
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            verification.message,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: verification.isValid
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Action buttons
            if (isDownloading)
              Row(
                children: [
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      ClipItModelManager.instance.cancelDownload(model.id);
                      setState(() => _downloadProgress.remove(model.id));
                    },
                    icon: const Icon(Icons.cancel_outlined,
                        size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Cancel download',
                  ),
                ],
              )
            else if (model.installed)
              Row(
                children: [
                  // Select / Selected indicator button
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 5),
                          Text(
                            'SELECTED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _activeModelId = model.id);
                        await ClipItModelManager.instance.setActiveModelId(model.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${model.name} selected as active live model.'),
                              backgroundColor: const Color(0xFF10B981),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.radio_button_unchecked_rounded, size: 14),
                      label: const Text('Select'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF221F33),
                        foregroundColor: const Color(0xFFC4B5FD),
                        side: const BorderSide(color: Color(0xFF4C3E75)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // File Check button
                  ElevatedButton.icon(
                    onPressed: isChecking
                        ? null
                        : () async {
                            setState(() => _isChecking[model.id] = true);
                            final res = await ClipItModelManager.instance
                                .checkModelFiles(model.id);
                            if (mounted) {
                              setState(() {
                                _isChecking[model.id] = false;
                                _verificationResults[model.id] = res;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        res.isValid
                                            ? Icons.check_circle_rounded
                                            : Icons.error_outline_rounded,
                                        color: res.isValid
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${model.name}: ${res.message}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF161722),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                    icon: isChecking
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF60A5FA),
                            ),
                          )
                        : const Icon(Icons.fact_check_outlined,
                            size: 14, color: Color(0xFF60A5FA)),
                    label: const Text(
                      'Check',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF93C5FD),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF152238),
                      foregroundColor: const Color(0xFF93C5FD),
                      side: const BorderSide(color: Color(0xFF1E3A8A)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete button
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF161722),
                          title: const Text('Delete Model?',
                              style: TextStyle(
                                  color: Color(0xFFF3F4F8),
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                            'Are you sure you want to delete ${model.name}? This will free ${model.formattedSize} of storage.',
                            style: const TextStyle(color: Color(0xFF8E92A6)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel',
                                  style: TextStyle(color: Color(0xFF8E92A6))),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Delete Model'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ClipItModelManager.instance.deleteModel(model.id);
                        _verificationResults.remove(model.id);
                        await _loadModels();
                        if (_activeModelId == model.id) {
                          setState(() => _activeModelId =
                              ClipItModelManager.defaultActiveModelId);
                          await ClipItModelManager.instance.setActiveModelId(
                              ClipItModelManager.defaultActiveModelId);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${model.name} deleted successfully.'),
                              backgroundColor: const Color(0xFF161722),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 15, color: Color(0xFFEF4444)),
                    label: const Text('Delete',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF261820),
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFF4A2530)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _downloadProgress[model.id] = 0.0);
                  try {
                    await ClipItModelManager.instance.downloadModel(
                      model.id,
                      onProgress: (received, total, fraction) {
                        if (mounted) {
                          setState(() => _downloadProgress[model.id] = fraction);
                        }
                      },
                    );
                    await _loadModels();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${model.name} downloaded successfully!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Download failed: $e'),
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _downloadProgress.remove(model.id));
                    }
                  }
                },
                icon: const Icon(Icons.download_rounded, size: 14),
                label: Text('Download (${model.formattedSize})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, animVal, _) {
                return LinearProgressIndicator(
                  value: animVal,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF1E202C),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                );
              },
            ),
          ),
        ],
      ],
    ),
  );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF7E8299),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  const _SettingToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
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
                subtitle,
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


/// Interactive Model Card with smooth hover and active borders.
class _InteractiveModelCard extends StatefulWidget {
  const _InteractiveModelCard({
    required this.isActive,
    required this.child,
  });

  final bool isActive;
  final Widget child;

  @override
  State<_InteractiveModelCard> createState() => _InteractiveModelCardState();
}

class _InteractiveModelCardState extends State<_InteractiveModelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isActive
              ? const Color(0xFF191827)
              : (_isHovered ? const Color(0xFF161724) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isActive
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : (_isHovered
                    ? const Color(0xFF383A52)
                    : Colors.transparent),
            width: 1.0,
          ),
          boxShadow: widget.isActive || _isHovered
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(
                      alpha: widget.isActive ? 0.12 : 0.06,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Category list item with hover and active states.
class _CategoryListItem extends StatefulWidget {
  const _CategoryListItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<_CategoryListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF221F33)
                : (_hovered ? const Color(0xFF191A26) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF383254)
                  : (_hovered ? const Color(0xFF262838) : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: isSelected
                    ? const Color(0xFF8B5CF6)
                    : (_hovered
                        ? const Color(0xFFE2E4ED)
                        : const Color(0xFF7E8299)),
              ),
              const SizedBox(width: 10),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (_hovered
                          ? const Color(0xFFE2E4ED)
                          : const Color(0xFF9EA1B5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
