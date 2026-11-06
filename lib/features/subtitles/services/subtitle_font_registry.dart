import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font asset metadata definition.
class SubtitleFontMetadata {
  const SubtitleFontMetadata({
    required this.family,
    required this.displayName,
    required this.category,
    this.assetPath = '',
    this.filePath,
    this.isEmbedded = false,
    this.isDynamicallyLoaded = false,
    this.fallbackFamily = 'sans-serif',
    this.availableWeights = const [FontWeight.w400, FontWeight.w700],
  });

  final String family;
  final String displayName;
  final String category; // 'bold', 'serif', 'comic', 'clean', 'editorial', 'kinetic', 'imported'
  final String assetPath;
  final String? filePath;
  final bool isEmbedded;
  final bool isDynamicallyLoaded;
  final String fallbackFamily;
  final List<FontWeight> availableWeights;

  SubtitleFontMetadata copyWith({
    String? family,
    String? displayName,
    String? category,
    String? assetPath,
    String? filePath,
    bool? isEmbedded,
    bool? isDynamicallyLoaded,
    String? fallbackFamily,
    List<FontWeight>? availableWeights,
  }) {
    return SubtitleFontMetadata(
      family: family ?? this.family,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      assetPath: assetPath ?? this.assetPath,
      filePath: filePath ?? this.filePath,
      isEmbedded: isEmbedded ?? this.isEmbedded,
      isDynamicallyLoaded: isDynamicallyLoaded ?? this.isDynamicallyLoaded,
      fallbackFamily: fallbackFamily ?? this.fallbackFamily,
      availableWeights: availableWeights ?? this.availableWeights,
    );
  }
}

/// Registry of curated subtitle typography assets for ClipIt.
///
/// Dynamically scans and registers fonts from user input and asset directories,
/// while providing curated kinetic typography fonts and native system fallbacks.
class SubtitleFontRegistry {
  SubtitleFontRegistry._();

  static const String subtitleFontsAssetDirectory = 'assets/fonts/subtitles/';

  /// Cached disk file paths for FFmpeg and ASS subtitle rendering.
  static final Map<String, String> _fontFilePaths = {};

  /// Set of font family names registered in the Flutter engine via FontLoader.
  static final Set<String> _loadedFontFamilies = {};

  /// Flag indicating whether discovery has run.
  static bool _hasDiscovered = false;

  /// Curated base fonts (system fonts, viral creator fonts, and Google Fonts).
  static final List<SubtitleFontMetadata> _curatedBaseFonts = [
    const SubtitleFontMetadata(
      family: 'Impact',
      displayName: 'Impact (Viral & Bold)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/impact.ttf',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w700, FontWeight.w800, FontWeight.w900],
    ),
    const SubtitleFontMetadata(
      family: 'Arial Black',
      displayName: 'Arial Black (Heavy)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/arial_black.ttf',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w800, FontWeight.w900],
    ),
    const SubtitleFontMetadata(
      family: 'Comic Sans MS',
      displayName: 'Comic Sans (Meme & Fun)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/comic_sans.ttf',
      fallbackFamily: 'cursive',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Georgia',
      displayName: 'Georgia (Cinematic Serif)',
      category: 'serif',
      assetPath: 'assets/fonts/subtitles/georgia.ttf',
      fallbackFamily: 'serif',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Segoe UI',
      displayName: 'Segoe UI (Modern Clean)',
      category: 'clean',
      assetPath: 'assets/fonts/subtitles/segoe_ui.ttf',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w600, FontWeight.w700, FontWeight.w800],
    ),
    const SubtitleFontMetadata(
      family: 'Trebuchet MS',
      displayName: 'Trebuchet MS (Dynamic)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/trebuchet_ms.ttf',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Courier New',
      displayName: 'Courier New (Typewriter)',
      category: 'clean',
      assetPath: 'assets/fonts/subtitles/courier_new.ttf',
      fallbackFamily: 'monospace',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Verdana',
      displayName: 'Verdana (Legible Wide)',
      category: 'clean',
      assetPath: 'assets/fonts/subtitles/verdana.ttf',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    // Curated short-form video & kinetic typography fonts
    const SubtitleFontMetadata(
      family: 'Montserrat',
      displayName: 'Montserrat (Ultra Bold & Clean)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w600, FontWeight.w700, FontWeight.w800, FontWeight.w900],
    ),
    const SubtitleFontMetadata(
      family: 'Anton',
      displayName: 'Anton (Impactful Headline)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w800],
    ),
    const SubtitleFontMetadata(
      family: 'Bebas Neue',
      displayName: 'Bebas Neue (Tall Condensed)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Oswald',
      displayName: 'Oswald (Strong Editorial)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w500, FontWeight.w600, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Poppins',
      displayName: 'Poppins (Geometric Modern)',
      category: 'clean',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w600, FontWeight.w700, FontWeight.w800],
    ),
    const SubtitleFontMetadata(
      family: 'Archivo Black',
      displayName: 'Archivo Black (Punch Heavy)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w900],
    ),
    const SubtitleFontMetadata(
      family: 'League Spartan',
      displayName: 'League Spartan (Dynamic Block)',
      category: 'bold',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w700, FontWeight.w800, FontWeight.w900],
    ),
    const SubtitleFontMetadata(
      family: 'Roboto Condensed',
      displayName: 'Roboto Condensed (Streamlined)',
      category: 'clean',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w400, FontWeight.w700],
    ),
    const SubtitleFontMetadata(
      family: 'Inter',
      displayName: 'Inter (High Readability)',
      category: 'clean',
      fallbackFamily: 'sans-serif',
      availableWeights: [FontWeight.w600, FontWeight.w700, FontWeight.w800],
    ),
    // ── 48 Custom Subtitle & Creator Fonts Bundled in assets/fonts/subtitles/ ──
    const SubtitleFontMetadata(
      family: 'Adorable Minty',
      displayName: 'Adorable Minty (Fun & Cute)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Adorable Minty.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Aeruno',
      displayName: 'Aeruno (Futuristic Kinetic)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/AERUNO-Trial.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Aesthetic Relations',
      displayName: 'Aesthetic Relations (Editorial Chic)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Aesthetic Relations Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Black Spiral',
      displayName: 'Black Spiral (Urban Street)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/black spiral.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'BlackWidow',
      displayName: 'BlackWidow (Heavy Punch)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/BlackWidow.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Bunster',
      displayName: 'Bunster (Playful Meme)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Bunster.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'ButleyHead',
      displayName: 'ButleyHead (Bold Headline)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/ButleyHead-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Chopwood',
      displayName: 'Chopwood (Vintage Woodcut)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Chopwood.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'CuteLovers',
      displayName: 'CuteLovers (Romantic Script)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/CuteLovers-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Deroka',
      displayName: 'Deroka (Impact Geometry)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/Deroka.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Duttary',
      displayName: 'Duttary (Modern Brush)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/Duttary-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Escger',
      displayName: 'Escger (Heavy Glitch / Brutal)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/escger.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'FunSized',
      displayName: 'FunSized (Chunky Cartoon)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/FunSized.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Glamhoure',
      displayName: 'Glamhoure (Luxury Fashion)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Glamhoure-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'GLF Cikutra',
      displayName: 'GLF Cikutra (Clean Grotesk)',
      category: 'clean',
      assetPath: 'assets/fonts/subtitles/GLF-Cikutra-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Hanana',
      displayName: 'Hanana (Expressive Calligraphy)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/Hanana.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'HealingSunshine',
      displayName: 'Healing Sunshine (Warm Casual)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/HealingSunshine-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Hello Moms',
      displayName: 'Hello Moms (Cute Handwritten)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Hello Moms.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'HexenGates',
      displayName: 'HexenGates (Cyberpunk Edge)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/HexenGates-Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Historical Aesthetic',
      displayName: 'Historical Aesthetic (Vintage Serif)',
      category: 'serif',
      assetPath: 'assets/fonts/subtitles/Historical Aesthetic Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Historical Conditions',
      displayName: 'Historical Conditions (Classic Roman)',
      category: 'serif',
      assetPath: 'assets/fonts/subtitles/Historical Conditions Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Honey Dathi',
      displayName: 'Honey Dathi (Sweet Marker)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Honey Dathi Demo.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'JonkieGoblin',
      displayName: 'JonkieGoblin (Dynamic Punch)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/JonkieGoblin-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'KaysteveScript',
      displayName: 'Kaysteve Script (Signature)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/KaysteveScript-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Keythal',
      displayName: 'Keythal (Modern Minimal Serif)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Keythal-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Khoo Mice',
      displayName: 'Khoo Mice (Animated Cartoon)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Khoo-Mice-Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Konja',
      displayName: 'Konja (Heavy Block Sans)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/Konja.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'KrayolaSketch',
      displayName: 'Krayola Sketch (Crayon Texture)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/KrayolaSketch-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'LiminalWraith',
      displayName: 'Liminal Wraith (Horror Grunge)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/LiminalWraith-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'LovelyAngelicia',
      displayName: 'Lovely Angelicia (Calligraphy)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/LovelyAngelicia-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Luchados',
      displayName: 'Luchados (Vintage Poster)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/Luchados.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Mollumi',
      displayName: 'Mollumi (Elegant Modernist)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Mollumi.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Montaplay',
      displayName: 'Montaplay (Athletic Sport)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/Montaplay Demo.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Monthela',
      displayName: 'Monthela (Luxury Script)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Monthela-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Monzed',
      displayName: 'Monzed (Futuristic Inline)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/Monzed-PersonalUseOnly-Inline.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Muneban',
      displayName: 'Muneban (Clean Minimal Sans)',
      category: 'clean',
      assetPath: 'assets/fonts/subtitles/Muneban-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Necessary Language',
      displayName: 'Necessary Language (Caps Punch)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/NECESSARY LANGUAGE DEMO.otf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Noctelle Rouge',
      displayName: 'Noctelle Rouge (Neo-Gothic)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Noctelle Rouge.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'PalmerasSherffy',
      displayName: 'Palmeras Sherffy (Boutique Chic)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/PalmerasSherffy-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'RoamersScream',
      displayName: 'Roamers Scream (Distorted)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/RoamersScreamDEMO-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Roken',
      displayName: 'Roken (Distressed Brush)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/Roken-Regular.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'Rubik Vinyl',
      displayName: 'Rubik Vinyl (Retro Y2K Street)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/RubikVinyl-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Saneora',
      displayName: 'Saneora (Art Deco Luxury)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/Saneora.otf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'Super Flower',
      displayName: 'Super Flower (Groovy Floral)',
      category: 'comic',
      assetPath: 'assets/fonts/subtitles/Super Flower.otf',
      isEmbedded: true,
      fallbackFamily: 'cursive',
    ),
    const SubtitleFontMetadata(
      family: 'UrbanLabels',
      displayName: 'Urban Labels (Streetwear Tag)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/UrbanLabels.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'VeloriaQueen',
      displayName: 'Veloria Queen (Regal Display)',
      category: 'editorial',
      assetPath: 'assets/fonts/subtitles/VeloriaQueen-Regular.ttf',
      isEmbedded: true,
      fallbackFamily: 'serif',
    ),
    const SubtitleFontMetadata(
      family: 'WesternRacing',
      displayName: 'Western Racing (Speed & Drift)',
      category: 'kinetic',
      assetPath: 'assets/fonts/subtitles/WesternRacing.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
    const SubtitleFontMetadata(
      family: 'Witch Blade',
      displayName: 'Witch Blade (Sharp Cyberpunk)',
      category: 'bold',
      assetPath: 'assets/fonts/subtitles/Witch Blade.ttf',
      isEmbedded: true,
      fallbackFamily: 'sans-serif',
    ),
  ];

  /// Mutable list holding all curated and dynamically discovered font families.
  static final List<SubtitleFontMetadata> _allRegisteredFonts = List.from(_curatedBaseFonts);

  /// Public getter maintaining backward compatibility with all existing callers and tests.
  static List<SubtitleFontMetadata> get registeredFonts {
    if (!_hasDiscovered) {
      _discoverFontsSynchronously();
    }
    return List.unmodifiable(_allRegisteredFonts);
  }

  /// Discovers and registers fonts synchronously on first access.
  static void _discoverFontsSynchronously() {
    _hasDiscovered = true;

    // Scan candidate directories for .otf and .ttf font files
    final candidateDirs = <Directory>[
      Directory(subtitleFontsAssetDirectory),
      Directory('windows/fonts/'),
      Directory('user input/'),
      Directory('assets/fonts/subtitles/'),
      Directory('C:\\Users\\Dell\\Desktop\\CLIP-IT\\assets\\fonts\\subtitles'),
      Directory('C:\\Users\\Dell\\Desktop\\CLIP-IT\\user input'),
    ];

    try {
      final desktopUserInput = Directory('C:\\Users\\Dell\\Desktop\\CLIP-IT\\user input');
      if (desktopUserInput.existsSync()) {
        candidateDirs.add(desktopUserInput);
      }
    } catch (_) {}

    final discoveredKeys = <String>{};
    for (final f in _allRegisteredFonts) {
      discoveredKeys.add(f.family.toLowerCase());
    }

    for (final dir in candidateDirs) {
      if (!dir.existsSync()) continue;
      try {
        final entries = dir.listSync(recursive: true);
        for (final entry in entries) {
          if (entry is! File) continue;
          final pathLower = entry.path.toLowerCase();
          if (!pathLower.endsWith('.otf') && !pathLower.endsWith('.ttf')) {
            continue;
          }

          final filename = entry.uri.pathSegments.last;
          final parsed = _parseFontFilename(filename, entry.path);
          final key = parsed.family.toLowerCase();

          // Save path for FFmpeg rendering
          _fontFilePaths[parsed.family] = entry.path;
          _fontFilePaths[parsed.displayName] = entry.path;

          if (!discoveredKeys.contains(key)) {
            discoveredKeys.add(key);
            _allRegisteredFonts.add(parsed);
          }
        }
      } catch (_) {}
    }

    // Trigger asynchronous engine registration of discovered fonts in the background
    _loadDiscoveredFontsIntoEngine();
  }

  /// Discovers and imports all font files recursively into the active font library.
  static Future<void> discoverAndRegisterFonts() async {
    _discoverFontsSynchronously();
    await _loadDiscoveredFontsIntoEngine();
  }

  /// Parses filename into clean font family name, display name, and detected weight.
  static SubtitleFontMetadata _parseFontFilename(String filename, String filePath) {
    // Strip extension
    var clean = filename;
    if (clean.toLowerCase().endsWith('.otf') || clean.toLowerCase().endsWith('.ttf')) {
      clean = clean.substring(0, clean.length - 4);
    }

    var weight = FontWeight.w700;
    var weightLabel = '';

    if (clean.contains('-')) {
      final parts = clean.split('-');
      final familyPart = parts.first.replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ').trim();
      final stylePart = parts.sublist(1).join(' ').trim();

      if (stylePart.toLowerCase().contains('black') || stylePart.toLowerCase().contains('ultrabold')) {
        weight = FontWeight.w900;
        weightLabel = 'Black';
      } else if (stylePart.toLowerCase().contains('extrabold')) {
        weight = FontWeight.w800;
        weightLabel = 'Extra Bold';
      } else if (stylePart.toLowerCase().contains('bold')) {
        weight = FontWeight.w700;
        weightLabel = 'Bold';
      } else if (stylePart.toLowerCase().contains('semibold')) {
        weight = FontWeight.w600;
        weightLabel = 'SemiBold';
      } else if (stylePart.toLowerCase().contains('medium')) {
        weight = FontWeight.w500;
        weightLabel = 'Medium';
      } else if (stylePart.toLowerCase().contains('light')) {
        weight = FontWeight.w300;
        weightLabel = 'Light';
      } else if (stylePart.toLowerCase().contains('regular')) {
        weight = FontWeight.w400;
        weightLabel = 'Regular';
      }

      final display = weightLabel.isNotEmpty ? '$familyPart $weightLabel' : familyPart;
      return SubtitleFontMetadata(
        family: familyPart,
        displayName: display,
        category: 'imported',
        filePath: filePath,
        isDynamicallyLoaded: true,
        availableWeights: [weight],
      );
    } else {
      final familyName = clean
          .replaceAll(RegExp(r'(?<=[a-z])(?=[A-Z])'), ' ')
          .replaceAll('_', ' ')
          .trim();
      return SubtitleFontMetadata(
        family: familyName,
        displayName: familyName,
        category: 'imported',
        filePath: filePath,
        isDynamicallyLoaded: true,
        availableWeights: [FontWeight.w400, FontWeight.w700],
      );
    }
  }

  /// Loads discovered and embedded fonts into Flutter's FontLoader runtime.
  static Future<void> _loadDiscoveredFontsIntoEngine() async {
    for (final metadata in _allRegisteredFonts) {
      if (_loadedFontFamilies.contains(metadata.family)) continue;

      // 1. Try loading from bundled asset via rootBundle
      if (metadata.assetPath.isNotEmpty) {
        try {
          final byteData = await rootBundle.load(metadata.assetPath);
          final fontLoader = FontLoader(metadata.family);
          fontLoader.addFont(Future.value(byteData));
          await fontLoader.load();
          _loadedFontFamilies.add(metadata.family);
          continue;
        } catch (_) {}
      }

      // 2. Try loading from disk via File
      final path = metadata.filePath ?? getFontFilePath(metadata.family);
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fontLoader = FontLoader(metadata.family);
            fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
            await fontLoader.load();
            _loadedFontFamilies.add(metadata.family);
          }
        } catch (e) {
          debugPrint('SubtitleFontRegistry: Notice - skipping font ${metadata.family}: $e');
        }
      }
    }
  }

  /// Resolves the absolute disk path of a font file for FFmpeg and ASS rendering.
  static String? getFontFilePath(String family) {
    if (_fontFilePaths.containsKey(family)) {
      return _fontFilePaths[family];
    }
    for (final font in _allRegisteredFonts) {
      if (font.family.toLowerCase() == family.toLowerCase()) {
        if (font.filePath != null && font.filePath!.isNotEmpty) {
          _fontFilePaths[family] = font.filePath!;
          return font.filePath;
        }
        if (font.assetPath.isNotEmpty) {
          final candidatePaths = [
            font.assetPath,
            'C:\\Users\\Dell\\Desktop\\CLIP-IT\\${font.assetPath.replaceAll('/', '\\')}',
            'windows\\fonts\\${font.assetPath.split('/').last}',
          ];
          for (final p in candidatePaths) {
            if (File(p).existsSync()) {
              _fontFilePaths[family] = p;
              return p;
            }
          }
        }
      }
    }
    // Check inside assets/fonts/subtitles
    try {
      final dir = Directory(subtitleFontsAssetDirectory);
      if (dir.existsSync()) {
        final matches = dir.listSync().whereType<File>().where((f) {
          final name = f.uri.pathSegments.last.toLowerCase();
          return name.contains(family.toLowerCase().replaceAll(' ', ''));
        });
        if (matches.isNotEmpty) {
          final p = matches.first.path;
          _fontFilePaths[family] = p;
          return p;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Resolves TextStyle for the given font family with direct platform rendering.
  static TextStyle getTextStyle({
    required String family,
    required double fontSize,
    FontWeight fontWeight = FontWeight.w800,
    FontStyle fontStyle = FontStyle.normal,
    Color? color = Colors.white,
    double? letterSpacing,
    double? height,
  }) {
    // 1. Check if dynamically loaded via FontLoader or defined in pubspec fonts
    final isRegistered = _loadedFontFamilies.contains(family) ||
        _allRegisteredFonts.any((f) => f.family.toLowerCase() == family.toLowerCase());

    if (isRegistered) {
      return TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    // 2. Native Windows system desktop fonts that render instantly
    const nativeFonts = {
      'Impact',
      'Arial Black',
      'Comic Sans MS',
      'Georgia',
      'Segoe UI',
      'Trebuchet MS',
      'Courier New',
      'Verdana',
      'Arial',
      'Calibri',
      'Consolas',
      'Tahoma',
      'Times New Roman',
    };

    if (nativeFonts.contains(family)) {
      return TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }

    // 3. Google Fonts resolution
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      // 4. Safe fallback
      return TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }
}
